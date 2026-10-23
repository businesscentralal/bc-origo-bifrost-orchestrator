namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>
/// Issue #109: the step-level checks of Orchestrator.Playbook.Verify, each with a positive and a negative case:
/// unknown message type, Success condition, Next Step edges, forEach source, per-item gate, unguarded forEach source,
/// and the severity, step and disabled flag every finding carries.
/// </summary>
codeunit 96435 "Playbook Verify Step Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Lib: Codeunit "Playbook Test Library ori";
        PlaybookCodeTok: Label 'VERIFY-109', Locked = true;
        UnlistedOrdinalTok: Label '99999999', Locked = true;
        PlatformRefusedTxt: Label 'The platform refused to hold an ordinal that the enum does not list.', Locked = true;
        ErrorTok: Label 'error', Locked = true;
        WarningTok: Label 'warning', Locked = true;
        UnavailableStartTxt: Label 'Step 20 calls message type Unknown(99999999), which does not exist in this deployment', Locked = true;
        UnavailableStartIsTxt: Label 'Skref 20 kallar á skilaboðategundina Unknown(99999999), sem er ekki til í þessari uppsetningu', Locked = true;
        CheckNoConditionStartTxt: Label 'Check step 20 has no Success condition, so it answers yes every time', Locked = true;
        CheckNoConditionStartIsTxt: Label 'Athugunarskref 20 hefur ekkert árangursskilyrði, svo það svarar alltaf já', Locked = true;
        SourceUnguardedStartTxt: Label 'Step 10 (Data.Records.Get) feeds a forEach but has no Success condition on noOfRecords', Locked = true;
        SourceUnguardedStartIsTxt: Label 'Skref 10 (Data.Records.Get) fóðrar forEach en hefur ekkert árangursskilyrði á noOfRecords', Locked = true;

    [Test]
    procedure CleanPlaybook_HasNoFindings()
    var
        Findings: JsonArray;
    begin
        // [SCENARIO] A single read with its Success condition raises nothing
        BuildBase();
        GetFindings(Findings);
        Assert.AreEqual(0, Findings.Count(), 'No findings for the clean base playbook');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure EmptyPlaybook_HasNoFindings()
    var
        Findings: JsonArray;
    begin
        Lib.CreatePlaybook(PlaybookCodeTok);
        GetFindings(Findings);
        Assert.AreEqual(0, Findings.Count(), 'A playbook without steps has nothing to find');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure UnlistedMessageType_IsAnError()
    begin
        VerifyUnlistedMessageType(1033, UnavailableStartTxt);
    end;

    [Test]
    procedure UnlistedMessageType_IsAnError_Icelandic()
    begin
        VerifyUnlistedMessageType(1039, UnavailableStartIsTxt);
    end;

    [Test]
    procedure ListedEnabledMessageType_NoFinding()
    var
        Verify: Codeunit "Playbook Verify ori";
    begin
        Assert.IsTrue(Verify.IsTypeEnabled("Message Type ori"::"Data.Records.Get"), 'Data.Records.Get is enabled');
        Assert.AreEqual('Data.Records.Get', Verify.GetTypeName("Message Type ori"::"Data.Records.Get"), 'A listed type is named');
        Assert.AreEqual('Orchestrator.Playbook.Verify', Verify.GetTypeName("Message Type ori"::"Orchestrator.Playbook.Verify"), 'The type of this app is named');
    end;

    [Test]
    procedure UnlistedMessageType_NameAndEnabled()
    var
        Verify: Codeunit "Playbook Verify ori";
        Unlisted: Enum "Message Type ori";
    begin
        if not TryMakeUnlisted(Unlisted) then
            Assert.Fail(PlatformRefusedTxt);
        Assert.AreEqual('Unknown(99999999)', Verify.GetTypeName(Unlisted), 'An unlisted ordinal is named Unknown(ordinal)');
        Assert.IsFalse(Verify.IsTypeEnabled(Unlisted), 'An unlisted ordinal is not enabled');
    end;

    [Test]
    procedure KnownTypeThatIsNotEnabled_WithStartCondition_IsNotReported()
    var
        Verify: Codeunit "Playbook Verify ori";
        Findings: JsonArray;
        ExpectedWithoutStart: Integer;
    begin
        // [SCENARIO] Telegram is enabled only for a user with a bot token and a chat ID. The Start condition of the
        // reporting tail (_who.telegramChatId Exists) is how the author skips the step then, so it is not judged.
        BuildBase();
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Action, "Message Type ori"::"Orchestrator.Telegram.Message", '{"message":"x"}', 0, '', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 20);
        if not Verify.IsTypeEnabled("Message Type ori"::"Orchestrator.Telegram.Message") then
            ExpectedWithoutStart := 1;

        GetFindings(Findings);
        Assert.AreEqual(ExpectedWithoutStart, CountFindings(Findings, 'MessageTypeUnavailable', 20), 'Without a Start condition a type that is not enabled is an error');

        Lib.AddCondition(PlaybookCodeTok, 20, "Playbook Cond. Type ori"::Start, 10000, '_who.telegramChatId', "Playbook Cond. Operator ori"::Exists, '');
        GetFindings(Findings);
        Assert.AreEqual(0, CountFindings(Findings, 'MessageTypeUnavailable', -1), 'With a Start condition the author has decided when it runs');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure UnlistedType_WithStartCondition_IsStillAnError()
    var
        Findings: JsonArray;
        Unlisted: Enum "Message Type ori";
    begin
        if not TryMakeUnlisted(Unlisted) then
            Assert.Fail(PlatformRefusedTxt);
        BuildBase();
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Action, Unlisted, '{}', 0, '', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 20);
        Lib.AddCondition(PlaybookCodeTok, 20, "Playbook Cond. Type ori"::Start, 10000, '_who.telegramChatId', "Playbook Cond. Operator ori"::Exists, '');
        GetFindings(Findings);
        Assert.AreEqual(1, CountFindings(Findings, 'MessageTypeUnavailable', 20), 'An ordinal the enum does not list is never right');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure CheckWithoutSuccessCondition_IsAnError()
    begin
        VerifyCheckWithoutCondition(1033, CheckNoConditionStartTxt);
    end;

    [Test]
    procedure CheckWithoutSuccessCondition_IsAnError_Icelandic()
    begin
        VerifyCheckWithoutCondition(1039, CheckNoConditionStartIsTxt);
    end;

    [Test]
    procedure CheckWithSuccessCondition_NoFinding()
    var
        Findings: JsonArray;
    begin
        BuildBase();
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Check, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 0, '', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 20);
        GetFindings(Findings);
        Assert.AreEqual(0, Findings.Count(), 'A Check with a Success condition is clean');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure ActionWithoutSuccessCondition_IsAWarning()
    var
        Findings: JsonArray;
    begin
        BuildBase();
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 0, '', 0);
        GetFindings(Findings);
        Assert.AreEqual(1, Findings.Count(), 'One finding');
        AssertFinding(Findings, 'ActionWithoutSuccessCondition', 20, WarningTok);
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure ActionWithSuccessCondition_NoFinding()
    var
        Findings: JsonArray;
    begin
        BuildBase();
        GetFindings(Findings);
        Assert.AreEqual(0, CountFindings(Findings, 'ActionWithoutSuccessCondition', -1), 'Step 10 has its condition');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure NextStepNotFound_IsAnError()
    var
        Findings: JsonArray;
    begin
        BuildBase();
        Lib.SetNextSteps(PlaybookCodeTok, 10, 99, 98);
        GetFindings(Findings);
        Assert.AreEqual(2, CountFindings(Findings, 'NextStepNotFound', 10), 'Both edges point at steps that do not exist');
        AssertFinding(Findings, 'NextStepNotFound', 10, ErrorTok);
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure NextStepExistingOrZero_NoFinding()
    var
        Findings: JsonArray;
    begin
        BuildBase();
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 0, '', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 20);
        Lib.SetNextSteps(PlaybookCodeTok, 10, 20, 0);
        GetFindings(Findings);
        Assert.AreEqual(0, CountFindings(Findings, 'NextStepNotFound', -1), 'An existing step and 0 are both fine');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure IterateSource_Missing_IsAnError()
    var
        Findings: JsonArray;
    begin
        BuildBase();
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 0, 'result', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 20);
        GetFindings(Findings);
        AssertFinding(Findings, 'IterateSourceInvalid', 20, ErrorTok);
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure IterateSource_NotEarlier_IsAnError()
    var
        Findings: JsonArray;
    begin
        BuildBase();
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 30, 'result', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 20);
        Lib.AddStep(PlaybookCodeTok, 30, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 0, '', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 30);
        GetFindings(Findings);
        Assert.AreEqual(1, CountFindings(Findings, 'IterateSourceInvalid', 20), 'A source that comes later is refused');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure IterateSource_Earlier_NoFinding()
    var
        Findings: JsonArray;
    begin
        BuildGuardedForEach();
        GetFindings(Findings);
        Assert.AreEqual(0, CountFindings(Findings, 'IterateSourceInvalid', -1), 'An earlier source is fine');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure SkipGate_Missing_IsAnError()
    var
        Findings: JsonArray;
    begin
        BuildGuardedForEach();
        Lib.AddStep(PlaybookCodeTok, 50, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 10, 'result', 45);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 50);
        GetFindings(Findings);
        AssertFinding(Findings, 'InvalidSkipGate', 50, ErrorTok);
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure SkipGate_NotEarlier_IsAnError()
    var
        Findings: JsonArray;
    begin
        BuildGuardedForEach();
        Lib.AddStep(PlaybookCodeTok, 50, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 10, 'result', 60);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 50);
        Lib.AddStep(PlaybookCodeTok, 60, "Playbook Step Type ori"::Check, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 10, 'result', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 60);
        GetFindings(Findings);
        Assert.AreEqual(1, CountFindings(Findings, 'InvalidSkipGate', 50), 'A gate that comes later is refused');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure SkipGate_OnSingleStep_IsAnError()
    var
        Findings: JsonArray;
    begin
        // [SCENARIO] A single step records no per-item result, so a gate on it skips every item
        BuildGuardedForEach();
        Lib.AddStep(PlaybookCodeTok, 50, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 10, 'result', 10);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 50);
        GetFindings(Findings);
        AssertFinding(Findings, 'InvalidSkipGate', 50, ErrorTok);
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure SkipGate_OnForEachCheck_NoFinding()
    var
        Findings: JsonArray;
    begin
        BuildGuardedForEach();
        Lib.AddStep(PlaybookCodeTok, 50, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 10, 'result', 30);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 50);
        GetFindings(Findings);
        Assert.AreEqual(0, CountFindings(Findings, 'InvalidSkipGate', -1), 'A forEach Check that comes first is a valid gate');
        // A gate set on a step that does not iterate is never read, so it is not a finding
        Lib.AddStep(PlaybookCodeTok, 60, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 0, '', 5);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 60);
        GetFindings(Findings);
        Assert.AreEqual(0, CountFindings(Findings, 'InvalidSkipGate', 60), 'The gate of a single step does nothing and is not judged');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure ForEachSource_WithoutNoOfRecords_Warns()
    begin
        VerifyUnguardedSource(1033, SourceUnguardedStartTxt);
    end;

    [Test]
    procedure ForEachSource_WithoutNoOfRecords_Warns_Icelandic()
    begin
        VerifyUnguardedSource(1039, SourceUnguardedStartIsTxt);
    end;

    [Test]
    procedure ForEachSource_WithNoOfRecords_NoWarning()
    var
        Findings: JsonArray;
    begin
        BuildGuardedForEach();
        GetFindings(Findings);
        Assert.AreEqual(0, CountFindings(Findings, 'ForEachSourceUnguarded', -1), 'A reader guarded on noOfRecords is clean');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure ForEachSource_NotARecordReader_NoWarning()
    var
        Findings: JsonArray;
    begin
        // [SCENARIO] The layout list has no noOfRecords to guard on
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddLayoutSourceStep(PlaybookCodeTok, 10);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 10);
        Lib.AddStep(PlaybookCodeTok, 30, "Playbook Step Type ori"::Check, "Message Type ori"::"Help.Implementation.Get", '{}', 10, 'layouts', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 30);
        GetFindings(Findings);
        Assert.AreEqual(0, CountFindings(Findings, 'ForEachSourceUnguarded', -1), 'Only record readers are judged');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure ForEachSource_TwoConsumers_WarnsOnce()
    var
        Findings: JsonArray;
    begin
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 0, '', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 10);
        Lib.AddStep(PlaybookCodeTok, 30, "Playbook Step Type ori"::Check, "Message Type ori"::"Help.Implementation.Get", '{}', 10, 'result', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 30);
        Lib.AddStep(PlaybookCodeTok, 40, "Playbook Step Type ori"::Check, "Message Type ori"::"Help.Implementation.Get", '{}', 10, 'result', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 40);
        GetFindings(Findings);
        Assert.AreEqual(1, CountFindings(Findings, 'ForEachSourceUnguarded', 10), 'One warning, on the source step');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure UnsafeWrite_OnDisabledStep_IsNotReported()
    var
        Findings: JsonArray;
    begin
        // [SCENARIO] Only an enabled write is judged; the gate does not have to be right on a step that will not run
        BuildGuardedForEach();
        Lib.AddStep(PlaybookCodeTok, 50, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Set", '{"tableName":"Customer"}', 10, 'result', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 50);
        GetFindings(Findings);
        Assert.AreEqual(1, CountFindings(Findings, 'UnsafeForEachWrite', 50), 'The ungated write is reported while enabled');
        Lib.SetStepDisabled(PlaybookCodeTok, 50, true);
        GetFindings(Findings);
        Assert.AreEqual(0, CountFindings(Findings, 'UnsafeForEachWrite', -1), 'The same write is not reported once disabled');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure FindingOnDisabledStep_CarriesStepDisabled()
    var
        Findings: JsonArray;
        Token: JsonToken;
        Finding: JsonObject;
    begin
        // [SCENARIO] A playbook built with every step disabled can be verified; its findings say the step is disabled
        BuildBase();
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Check, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 0, '', 0);
        Lib.SetStepDisabled(PlaybookCodeTok, 20, true);
        GetFindings(Findings);
        Assert.AreEqual(1, CountFindings(Findings, 'CheckWithoutSuccessCondition', 20), 'A disabled step is still checked');
        Findings.Get(0, Token);
        Finding := Token.AsObject();
        Assert.IsTrue(Finding.Contains('stepDisabled'), 'The finding carries stepDisabled');
        Finding.Get('stepDisabled', Token);
        Assert.IsTrue(Token.AsValue().AsBoolean(), 'stepDisabled is true');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure FindingOnEnabledStep_HasNoStepDisabled()
    var
        Findings: JsonArray;
        Token: JsonToken;
    begin
        BuildBase();
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Check, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 0, '', 0);
        GetFindings(Findings);
        Findings.Get(0, Token);
        Assert.IsFalse(Token.AsObject().Contains('stepDisabled'), 'An enabled step has no stepDisabled');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure Findings_AreInStepOrder_WithAllFields()
    var
        Findings: JsonArray;
        Token: JsonToken;
        Finding: JsonObject;
        Fields: List of [Text];
        FieldName: Text;
    begin
        // [SCENARIO] Every finding has severity, stepNo, code, message and nextStep, in step order
        BuildBase();
        Lib.AddStep(PlaybookCodeTok, 30, "Playbook Step Type ori"::Check, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 0, '', 0);
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 0, '', 0);
        GetFindings(Findings);
        Assert.AreEqual(2, Findings.Count(), 'Two findings');
        Findings.Get(0, Token);
        Assert.AreEqual(20, IntOf(Token.AsObject(), 'stepNo'), 'The lower step comes first');
        Fields.AddRange('severity', 'stepNo', 'code', 'message', 'nextStep');
        foreach FieldName in Fields do begin
            Finding := Token.AsObject();
            Assert.IsTrue(Finding.Contains(FieldName), 'The finding has ' + FieldName);
        end;
        Lib.Cleanup(PlaybookCodeTok);
    end;

    local procedure VerifyUnlistedMessageType(LanguageId: Integer; ExpectedStart: Text)
    var
        Findings: JsonArray;
        Unlisted: Enum "Message Type ori";
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] A step whose message type the enum no longer lists is an error that names it
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        if not TryMakeUnlisted(Unlisted) then
            Assert.Fail(PlatformRefusedTxt);
        BuildBase();
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Action, Unlisted, '{}', 0, '', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 20);

        GetFindings(Findings);

        Assert.AreEqual(1, Findings.Count(), 'One finding');
        AssertFinding(Findings, 'MessageTypeUnavailable', 20, ErrorTok);
        AssertMessageStartsWith(Findings, 'MessageTypeUnavailable', ExpectedStart);
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyCheckWithoutCondition(LanguageId: Integer; ExpectedStart: Text)
    var
        Findings: JsonArray;
        PreviousLanguage: Integer;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        BuildBase();
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Check, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 0, '', 0);

        GetFindings(Findings);

        Assert.AreEqual(1, Findings.Count(), 'One finding');
        AssertFinding(Findings, 'CheckWithoutSuccessCondition', 20, ErrorTok);
        AssertMessageStartsWith(Findings, 'CheckWithoutSuccessCondition', ExpectedStart);
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyUnguardedSource(LanguageId: Integer; ExpectedStart: Text)
    var
        Findings: JsonArray;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] A record reader that feeds a forEach without a noOfRecords condition warns, on the source step
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 0, '', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 10);
        Lib.AddStep(PlaybookCodeTok, 30, "Playbook Step Type ori"::Check, "Message Type ori"::"Help.Implementation.Get", '{}', 10, 'result', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 30);

        GetFindings(Findings);

        Assert.AreEqual(1, Findings.Count(), 'One finding');
        AssertFinding(Findings, 'ForEachSourceUnguarded', 10, WarningTok);
        AssertMessageStartsWith(Findings, 'ForEachSourceUnguarded', ExpectedStart);
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    /// <summary>Step 10 reads (guarded), step 30 is a forEach Check over it. The base of the forEach tests.</summary>
    local procedure BuildGuardedForEach()
    begin
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 0, '', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 10);
        Lib.AddNoOfRecordsCondition(PlaybookCodeTok, 10);
        Lib.AddStep(PlaybookCodeTok, 30, "Playbook Step Type ori"::Check, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 10, 'result', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 30);
    end;

    local procedure BuildBase()
    begin
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 0, '', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 10);
    end;

    local procedure GetFindings(var Findings: JsonArray)
    var
        Verify: Codeunit "Playbook Verify ori";
    begin
        Verify.GetFindings(PlaybookCodeTok, Findings);
    end;

    /// <summary>Counts the findings with a code; a StepNo of -1 counts every step.</summary>
    local procedure CountFindings(Findings: JsonArray; FindingCode: Text; StepNo: Integer): Integer
    var
        Token: JsonToken;
        Count: Integer;
    begin
        foreach Token in Findings do
            if (TextOf(Token.AsObject(), 'code') = FindingCode) and ((StepNo = -1) or (IntOf(Token.AsObject(), 'stepNo') = StepNo)) then
                Count += 1;
        exit(Count);
    end;

    local procedure AssertFinding(Findings: JsonArray; FindingCode: Text; StepNo: Integer; Severity: Text)
    var
        Token: JsonToken;
    begin
        foreach Token in Findings do
            if (TextOf(Token.AsObject(), 'code') = FindingCode) and (IntOf(Token.AsObject(), 'stepNo') = StepNo) then begin
                Assert.AreEqual(Severity, TextOf(Token.AsObject(), 'severity'), FindingCode + ' severity');
                Assert.IsTrue(TextOf(Token.AsObject(), 'message') <> '', FindingCode + ' has a message');
                Assert.IsTrue(TextOf(Token.AsObject(), 'nextStep') <> '', FindingCode + ' has a nextStep');
                exit;
            end;
        Assert.Fail(StrSubstNo(Format1Tok, FindingCode, StepNo));
    end;

    local procedure AssertMessageStartsWith(Findings: JsonArray; FindingCode: Text; ExpectedStart: Text)
    var
        Token: JsonToken;
        MessageText: Text;
    begin
        foreach Token in Findings do
            if TextOf(Token.AsObject(), 'code') = FindingCode then begin
                MessageText := TextOf(Token.AsObject(), 'message');
                Assert.IsTrue(MessageText.StartsWith(ExpectedStart), 'Localized start expected: ' + ExpectedStart + ' got: ' + MessageText);
                exit;
            end;
        Assert.Fail('No finding ' + FindingCode);
    end;

    local procedure TextOf(Source: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        if Source.Get(PropertyName, Token) then
            exit(Token.AsValue().AsText());
    end;

    local procedure IntOf(Source: JsonObject; PropertyName: Text): Integer
    var
        Token: JsonToken;
    begin
        if Source.Get(PropertyName, Token) then
            exit(Token.AsValue().AsInteger());
    end;

    local procedure TryMakeUnlisted(var Unlisted: Enum "Message Type ori"): Boolean
    var
        Ordinal: Integer;
    begin
        Evaluate(Ordinal, UnlistedOrdinalTok);
        if Enum::"Message Type ori".Ordinals().Contains(Ordinal) then
            exit(false);
        exit(TryFromInteger(Ordinal, Unlisted));
    end;

    [TryFunction]
    local procedure TryFromInteger(Ordinal: Integer; var Unlisted: Enum "Message Type ori")
    begin
        Unlisted := Enum::"Message Type ori".FromInteger(Ordinal);
    end;
    var
        Format1Tok: Label 'No %1 finding on step %2', Locked = true;
}
