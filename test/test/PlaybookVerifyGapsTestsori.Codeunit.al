namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>
/// Issue #217: Orchestrator.Playbook.Verify names the declared request keys in their real casing, warns on unknown keys of
/// read types, reports @_current outside a forEach step (error), an iterate path the source does not declare and an Ask
/// step that never checks stopReason, gives an unknown @_current.fields name the severity its text claims (error), and
/// returns the findings sorted by step number. No dispatch: playbooks are verified, never run.
/// </summary>
codeunit 96497 "Playbook Verify Gaps Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Lib: Codeunit "Playbook Test Library ori";
        PlaybookCodeTok: Label 'XVER-217', Locked = true;
        AskFixtureTok: Label 'Test.Orchestrator.Ask', Locked = true;

    [Test]
    procedure UnknownKey_WriteType_NamesDeclaredKeysInRealCasing()
    var
        Findings: JsonArray;
        NextStep: Text;
    begin
        // [SCENARIO] AC01: the next step names tableName and tableNumber, not the lower-cased tablename and tablenumber.
        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 40, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Set", '{"table":"Currency","data":[]}', 0, '', 0);
        Verify(Findings);
        Assert.AreEqual(1, CountCode(Findings, 'UnknownRequestKey'), 'The key table is not declared');
        NextStep := GetField(Findings, 'UnknownRequestKey', 'nextStep');
        Assert.IsTrue(NextStep.Contains('tableName'), 'The declared key tableName keeps its casing: ' + NextStep);
        Assert.IsTrue(NextStep.Contains('tableNumber'), 'The declared key tableNumber keeps its casing: ' + NextStep);
        Assert.IsFalse(NextStep.Contains('tablename'), 'No lower-cased name: ' + NextStep);
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure UnknownKey_ReadType_WarnsAndAliasesAreAccepted()
    var
        Findings: JsonArray;
    begin
        // [SCENARIO] AC02: {"table":"Currency"} sent to Data.Records.Get warns; the declared key and its alias do not.
        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"table":"Currency"}', 0, '', 0);
        Verify(Findings);
        Assert.AreEqual(1, CountCode(Findings, 'UnknownRequestKey'), 'A read type warns on an unknown key');
        Assert.AreEqual('warning', GetField(Findings, 'UnknownRequestKey', 'severity'), 'Warning severity');
        Assert.IsTrue(GetField(Findings, 'UnknownRequestKey', 'message').Contains('table'), 'The key is named');
        Assert.IsTrue(GetField(Findings, 'UnknownRequestKey', 'nextStep').Contains('tableName'), 'The declared keys are named');

        ReplaceTemplate(10, '{"tableName":"Currency","take":5}');
        Verify(Findings);
        Assert.AreEqual(0, CountCode(Findings, 'UnknownRequestKey'), 'Declared keys are silent');
        ReplaceTemplate(10, '{"tableNo":4}');
        Verify(Findings);
        Assert.AreEqual(0, CountCode(Findings, 'UnknownRequestKey'), 'An alias the contract lists is silent');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure UnknownKey_ReadAndWrite_AreTranslated()
    begin
        VerifyKeyLanguage(1033, 'A read type ignores the key', 'Remove table or rename it');
        VerifyKeyLanguage(1039, 'Lestrartegund hunsar lykilinn', 'Fjarlægðu table');
    end;

    [Test]
    procedure Current_OutsideForEach_IsAnError_InsideItIsNot()
    var
        Findings: JsonArray;
    begin
        // [SCENARIO] AC02: @_current in a step that does not iterate is an error, once per step.
        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 50, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer","tableView":"WHERE(No.=CONST(@_current.fields.Bogus_)|No.=CONST(@_current.primaryKey.No_))"}', 0, '', 0);
        Verify(Findings);
        Assert.AreEqual(1, CountCode(Findings, 'CurrentOutsideForEach'), 'One finding per step');
        Assert.AreEqual('error', GetField(Findings, 'CurrentOutsideForEach', 'severity'), 'Error severity');
        Assert.IsTrue(GetField(Findings, 'CurrentOutsideForEach', 'message').Contains('@_current.fields.Bogus_'), 'The reference is named');

        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 0, '', 0);
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer","tableView":"WHERE(No.=CONST(@_current.primaryKey.No_))"}', 10, 'result', 0);
        Clear(Findings);
        Verify(Findings);
        Assert.AreEqual(0, CountCode(Findings, 'CurrentOutsideForEach'), 'A forEach step has a current item');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure Current_OutsideForEach_IsTranslated()
    var
        Findings: JsonArray;
        PreviousLanguage: Integer;
    begin
        PreviousLanguage := GlobalLanguage();
        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 50, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer","tableView":"@_current.fields.Bogus_"}', 0, '', 0);
        GlobalLanguage(1033);
        Verify(Findings);
        Assert.IsTrue(GetField(Findings, 'CurrentOutsideForEach', 'message').StartsWith('Step 50 reads @_current.fields.Bogus_, but the step does not iterate'), 'English text');
        Clear(Findings);
        GlobalLanguage(1039);
        Verify(Findings);
        Assert.IsTrue(GetField(Findings, 'CurrentOutsideForEach', 'message').StartsWith('Skref 50 les @_current.fields.Bogus_, en skrefið ítrar ekki'), 'Icelandic text');
        GlobalLanguage(PreviousLanguage);
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure IteratePath_NotInSourceResponse_Warns_DeclaredPathDoesNot()
    var
        Findings: JsonArray;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] AC02: Data.Records.Get answers under result; iterating records finds nothing.
        PreviousLanguage := GlobalLanguage();
        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Currency"}', 0, '', 0);
        Lib.AddStep(PlaybookCodeTok, 30, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Currency"}', 10, 'records', 0);
        GlobalLanguage(1033);
        Verify(Findings);
        Assert.AreEqual(1, CountCode(Findings, 'IteratePathNotInSourceResponse'), 'records is not declared');
        Assert.AreEqual('warning', GetField(Findings, 'IteratePathNotInSourceResponse', 'severity'), 'Warning severity');
        Assert.AreEqual('30', GetField(Findings, 'IteratePathNotInSourceResponse', 'stepNo'), 'The iterating step');
        Assert.IsTrue(GetField(Findings, 'IteratePathNotInSourceResponse', 'message').StartsWith('Step 30 iterates records from step 10'), 'English text');
        Clear(Findings);
        GlobalLanguage(1039);
        Verify(Findings);
        Assert.IsTrue(GetField(Findings, 'IteratePathNotInSourceResponse', 'message').StartsWith('Skref 30 ítrar records úr skrefi 10'), 'Icelandic text');
        GlobalLanguage(PreviousLanguage);

        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Currency"}', 0, '', 0);
        Lib.AddStep(PlaybookCodeTok, 30, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Currency"}', 10, 'result', 0);
        Clear(Findings);
        Verify(Findings);
        Assert.AreEqual(0, CountCode(Findings, 'IteratePathNotInSourceResponse'), 'result is declared');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure AskStopReason_UncheckedWarns_CheckedOrNoConditionDoesNot()
    var
        Verifier: Codeunit "Playbook Verify ori";
        Findings: JsonArray;
    begin
        // [SCENARIO] AC02: an Ask step whose only Success condition is status Equals Success passes truncated answers.
        Verifier.SetTestAskType(AskFixtureTok);
        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Test.Orchestrator.Ask", '{"prompt":"x"}', 0, '', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 10);
        Verify(Findings);
        Assert.AreEqual(1, CountCode(Findings, 'AskStopReasonUnchecked'), 'status only passes a truncated answer');
        Assert.AreEqual('warning', GetField(Findings, 'AskStopReasonUnchecked', 'severity'), 'Warning severity');

        Lib.AddCondition(PlaybookCodeTok, 10, "Playbook Cond. Type ori"::Success, 20000, 'stopReason', "Playbook Cond. Operator ori"::Equals, 'completed');
        Clear(Findings);
        Verify(Findings);
        Assert.AreEqual(0, CountCode(Findings, 'AskStopReasonUnchecked'), 'A stopReason condition is the documented pattern');

        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Test.Orchestrator.Ask", '{"prompt":"x"}', 0, '', 0);
        Clear(Findings);
        Verify(Findings);
        Assert.AreEqual(0, CountCode(Findings, 'AskStopReasonUnchecked'), 'No Success condition has its own finding');
        Verifier.SetTestAskType('');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure AskStopReason_IsTranslated()
    var
        Verifier: Codeunit "Playbook Verify ori";
        Findings: JsonArray;
        PreviousLanguage: Integer;
    begin
        PreviousLanguage := GlobalLanguage();
        Verifier.SetTestAskType(AskFixtureTok);
        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Test.Orchestrator.Ask", '{"prompt":"x"}', 0, '', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 10);
        GlobalLanguage(1033);
        Verify(Findings);
        Assert.IsTrue(GetField(Findings, 'AskStopReasonUnchecked', 'message').StartsWith('Ask step 10 has Success conditions but none on stopReason'), 'English text');
        Clear(Findings);
        GlobalLanguage(1039);
        Verify(Findings);
        Assert.IsTrue(GetField(Findings, 'AskStopReasonUnchecked', 'message').StartsWith('Ask-skref 10 hefur árangursskilyrði en ekkert á stopReason'), 'Icelandic text');
        GlobalLanguage(PreviousLanguage);
        Verifier.SetTestAskType('');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure CurrentField_Unknown_IsAnErrorAsItsTextSays_PrimaryKeyStaysAWarning()
    var
        Findings: JsonArray;
    begin
        // [SCENARIO] AC03: "The step fails before its message is sent" is an error, so it blocks even with ignoreWarnings.
        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 0, '', 0);
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer","tableView":"WHERE(Name=CONST(@_current.fields.Bogus_))"}', 10, 'result', 0);
        Verify(Findings);
        Assert.AreEqual('error', GetField(Findings, 'UnknownFieldReference', 'severity'), 'An unknown field fails the step: error');
        Assert.IsTrue(GetField(Findings, 'UnknownFieldReference', 'message').Contains('The step fails before its message is sent'), 'The text claims the failure');

        ReplaceTemplate(20, '{"tableName":"Customer","tableView":"WHERE(No.=CONST(@_current.fields.No_))"}');
        Clear(Findings);
        Verify(Findings);
        Assert.AreEqual('warning', GetField(Findings, 'UnknownFieldReference', 'severity'), 'A primary-key field stays a warning');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure Findings_AreSortedByStepThenSeverityThenCode()
    var
        Findings: JsonArray;
        Token: JsonToken;
        Finding: JsonObject;
        PreviousStep: Integer;
        PreviousRank: Integer;
        StepNo: Integer;
        Rank: Integer;
        Index: Integer;
        SourceIndex: Integer;
        Step20Index: Integer;
        StepToken: JsonToken;
    begin
        // [SCENARIO] AC04: step 10 feeds a forEach in step 20. ForEachSourceUnguarded names step 10 but is found while
        // checking step 20 and used to be listed after step 20's own findings.
        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 0, '', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 10);
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer","tableView":"@_current.fields.Bogus_"}', 10, 'result', 0);
        Lib.AddStep(PlaybookCodeTok, 30, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"table":"Currency"}', 0, '', 0);
        Verify(Findings);
        Assert.IsTrue(Findings.Count() >= 3, 'Findings on several steps');
        PreviousStep := 0;
        PreviousRank := 0;
        SourceIndex := -1;
        Step20Index := -1;
        for Index := 0 to Findings.Count() - 1 do begin
            Findings.Get(Index, Token);
            Finding := Token.AsObject();
            Finding.Get('stepNo', StepToken);
            StepNo := StepToken.AsValue().AsInteger();
            Rank := 1;
            Finding.Get('severity', StepToken);
            if StepToken.AsValue().AsText() = 'error' then
                Rank := 0;
            Assert.IsTrue(StepNo >= PreviousStep, 'Step numbers never decrease');
            if StepNo = PreviousStep then
                Assert.IsTrue(Rank >= PreviousRank, 'Within a step errors come before warnings');
            Finding.Get('code', StepToken);
            if (StepToken.AsValue().AsText() = 'ForEachSourceUnguarded') and (SourceIndex < 0) then
                SourceIndex := Index;
            if (StepNo = 20) and (Step20Index < 0) then
                Step20Index := Index;
            PreviousStep := StepNo;
            PreviousRank := Rank;
        end;
        Assert.IsTrue(SourceIndex >= 0, 'ForEachSourceUnguarded is reported');
        Assert.IsTrue(Step20Index >= 0, 'Step 20 has findings');
        Assert.IsTrue(SourceIndex < Step20Index, 'The finding about step 10 comes before the findings of step 20');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    local procedure VerifyKeyLanguage(LanguageId: Integer; MessageStart: Text; NextStart: Text)
    var
        Findings: JsonArray;
        PreviousLanguage: Integer;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"table":"Currency"}', 0, '', 0);
        Verify(Findings);
        Assert.IsTrue(GetField(Findings, 'UnknownRequestKey', 'message').Contains(MessageStart), 'Read message in ' + Format(LanguageId));
        Assert.IsTrue(GetField(Findings, 'UnknownRequestKey', 'nextStep').StartsWith(NextStart), 'Next step in ' + Format(LanguageId));
        GlobalLanguage(PreviousLanguage);
        Lib.Cleanup(PlaybookCodeTok);
    end;

    local procedure ReplaceTemplate(StepNo: Integer; Template: Text)
    var
        Step: Record "Playbook Step ori";
        MessageType: Enum "Message Type ori";
        IterateSource: Integer;
        IteratePath: Text[250];
    begin
        Step.Get(PlaybookCodeTok, StepNo);
        MessageType := Step."Message Type";
        IterateSource := Step."Iterate Source Step No.";
        IteratePath := Step."Iterate Array Path";
        Step.Delete();
        Lib.AddStep(PlaybookCodeTok, StepNo, "Playbook Step Type ori"::Action, MessageType, Template, IterateSource, IteratePath, 0);
    end;

    local procedure Verify(var Findings: JsonArray)
    var
        Verifier: Codeunit "Playbook Verify ori";
    begin
        Verifier.GetFindings(PlaybookCodeTok, Findings);
    end;

    local procedure CountCode(Findings: JsonArray; FindingCode: Text): Integer
    var
        Token: JsonToken;
        CodeToken: JsonToken;
        Total: Integer;
    begin
        foreach Token in Findings do
            if Token.AsObject().Get('code', CodeToken) then
                if CodeToken.AsValue().AsText() = FindingCode then
                    Total += 1;
        exit(Total);
    end;

    local procedure GetField(Findings: JsonArray; FindingCode: Text; FieldName: Text): Text
    var
        Token: JsonToken;
        CodeToken: JsonToken;
        FieldToken: JsonToken;
    begin
        foreach Token in Findings do
            if Token.AsObject().Get('code', CodeToken) then
                if CodeToken.AsValue().AsText() = FindingCode then begin
                    Token.AsObject().Get(FieldName, FieldToken);
                    exit(FieldToken.AsValue().AsText());
                end;
        exit('');
    end;
}
