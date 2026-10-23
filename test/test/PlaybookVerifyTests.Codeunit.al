namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>
/// Issue #108: Orchestrator.Playbook.Verify warns (UnsafeForEachWrite) when a forEach write step follows a forEach
/// Check over the same array without Skip If Step Failed pointing at the Check, and stays silent for the corrected
/// pattern. The findings are localized in en-US (1033) and is-IS (1039). The fixtures are deliberately bare, so these
/// tests look at the UnsafeForEachWrite finding only; the other checks have their own tests (#109).
/// </summary>
codeunit 96433 "Playbook Verify Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Lib: Codeunit "Playbook Test Library ori";
        PlaybookCodeTok: Label 'VERIFY-108', Locked = true;
        UnsafeStartTxt: Label 'Step 40 (Data.Records.Set) writes for every item of an array that an earlier forEach Check step 30 decides on', Locked = true;
        UnsafeStartIsTxt: Label 'Skref 40 (Data.Records.Set) skrifar fyrir öll atriði fylkis sem forEach-athugunarskref 30 á undan tekur ákvörðun um', Locked = true;
        UnsafeEndTxt: Label 'Set Skip If Step Failed to 30 on step 40.', Locked = true;
        UnsafeEndIsTxt: Label 'Stilltu Sleppa ef skref mistókst á 30 í skrefi 40.', Locked = true;

    [Test]
    procedure UnsafePattern_Warns()
    begin
        VerifyUnsafePatternWarns(1033, UnsafeStartTxt, UnsafeEndTxt);
    end;

    [Test]
    procedure UnsafePattern_Warns_Icelandic()
    begin
        VerifyUnsafePatternWarns(1039, UnsafeStartIsTxt, UnsafeEndIsTxt);
    end;

    [Test]
    procedure CorrectedPattern_DoesNotWarn()
    begin
        VerifyCorrectedPatternIsClean(1033);
    end;

    [Test]
    procedure CorrectedPattern_DoesNotWarn_Icelandic()
    begin
        VerifyCorrectedPatternIsClean(1039);
    end;

    /// <summary>Both write steps of the issue's example (blocking and unblocking) need their own gate.</summary>
    [Test]
    procedure TwoUnsafeWrites_WarnOncePerStep()
    var
        Verify: Codeunit "Playbook Verify ori";
        Warnings: JsonArray;
    begin
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddLayoutSourceStep(PlaybookCodeTok, 10);
        Lib.AddStep(PlaybookCodeTok, 30, "Playbook Step Type ori"::Check, "Message Type ori"::"Help.Implementation.Get", '{}', 10, 'layouts', 0);
        Lib.AddStep(PlaybookCodeTok, 40, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Set", '{}', 10, 'layouts', 0);
        Lib.AddStep(PlaybookCodeTok, 50, "Playbook Step Type ori"::Check, "Message Type ori"::"Help.Implementation.Get", '{}', 10, 'layouts', 0);
        Lib.AddStep(PlaybookCodeTok, 60, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Set", '{}', 10, 'layouts', 50);

        Verify.GetFindings(PlaybookCodeTok, Warnings);
        Warnings := OnlyUnsafeWrites(Warnings);

        // Step 40 is ungated; step 60 has Skip If Step Failed = 50, so it is clean.
        Assert.AreEqual(1, Warnings.Count(), 'Only the ungated write warns');
        Assert.AreEqual(40, WarningInt(Warnings, 0, 'stepNo'), 'Step 40 warns');
        Assert.AreEqual(30, WarningInt(Warnings, 0, 'checkStepNo'), 'The nearest earlier Check is named');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    /// <summary>A read step, a single (non-forEach) write, a disabled check and another array raise no warning.</summary>
    [Test]
    procedure SafeShapes_DoNotWarn()
    var
        PlaybookStep: Record "Playbook Step ori";
        Verify: Codeunit "Playbook Verify ori";
        Warnings: JsonArray;
    begin
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddLayoutSourceStep(PlaybookCodeTok, 10);
        Lib.AddStep(PlaybookCodeTok, 30, "Playbook Step Type ori"::Check, "Message Type ori"::"Help.Implementation.Get", '{}', 10, 'layouts', 0);
        // A forEach read after the Check is harmless
        Lib.AddStep(PlaybookCodeTok, 40, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{}', 10, 'layouts', 0);
        // A write that does not iterate the Check's array is a different decision
        Lib.AddStep(PlaybookCodeTok, 50, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Set", '{}', 10, 'other', 0);
        // A single write step is not per item
        Lib.AddStep(PlaybookCodeTok, 60, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Set", '{}', 0, '', 0);
        // A write that follows no Check at all (the Check is later)
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Set", '{}', 10, 'layouts', 0);

        Verify.GetFindings(PlaybookCodeTok, Warnings);
        Assert.AreEqual(0, OnlyUnsafeWrites(Warnings).Count(), 'No warnings for the safe shapes');

        // A disabled Check does not gate anything, so a write behind only a disabled Check is not warned about either
        PlaybookStep.Get(PlaybookCodeTok, 30);
        PlaybookStep.Validate(Disabled, true);
        PlaybookStep.Modify(true);
        Lib.AddStep(PlaybookCodeTok, 70, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Set", '{}', 10, 'layouts', 0);
        Verify.GetFindings(PlaybookCodeTok, Warnings);
        Assert.AreEqual(0, OnlyUnsafeWrites(Warnings).Count(), 'A disabled Check raises no warning');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    /// <summary>The write verbs are recognised by the last name segment; reads and unknown shapes are not writes.</summary>
    [Test]
    procedure WriteMessageTypesAreRecognisedByTheirVerb()
    var
        Verify: Codeunit "Playbook Verify ori";
    begin
        Assert.IsTrue(Verify.IsWriteMessageType('Data.Records.Set'), 'Set');
        Assert.IsTrue(Verify.IsWriteMessageType('Sales.Document.Post'), 'Post');
        Assert.IsTrue(Verify.IsWriteMessageType('Sales.Document.Delete'), 'Delete');
        Assert.IsTrue(Verify.IsWriteMessageType('Orchestrator.Email.Send'), 'Send');
        Assert.IsFalse(Verify.IsWriteMessageType('Data.Records.Get'), 'Get is a read');
        Assert.IsFalse(Verify.IsWriteMessageType('Orchestrator.ReportLayout.List'), 'List is a read');
        Assert.IsFalse(Verify.IsWriteMessageType('Set'), 'A bare word has no segments');
        Assert.IsFalse(Verify.IsWriteMessageType(''), 'Empty');
    end;

    /// <summary>The message type needs a playbook code and refuses an unknown playbook.</summary>
    [Test]
    procedure VerifyErrorsForMissingOrUnknownPlaybook()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Playbook Verify ori";
    begin
        CreateArgument(TempArgument, '{}');
        asserterror Handler.ExecuteVerify(TempArgument);
        Assert.ExpectedError('playbookCode');

        CreateArgument(TempArgument, '{"playbookCode":"DOES-NOT-EXIST"}');
        asserterror Handler.ExecuteVerify(TempArgument);
        Assert.ExpectedError('DOES-NOT-EXIST');
    end;

    local procedure VerifyUnsafePatternWarns(LanguageId: Integer; ExpectedStart: Text; ExpectedEnd: Text)
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Playbook Verify ori";
        ResponseJson: JsonObject;
        Token: JsonToken;
        Warning: JsonToken;
        Findings: JsonArray;
        PreviousLanguage: Integer;
        Message: Text;
    begin
        // [SCENARIO] A forEach write behind a forEach Check over the same array, with Skip If Step Failed = 0, warns
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        // [GIVEN] The issue's shape: check (30), then write (40) with no gate
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddLayoutSourceStep(PlaybookCodeTok, 10);
        Lib.AddStep(PlaybookCodeTok, 30, "Playbook Step Type ori"::Check, "Message Type ori"::"Help.Implementation.Get", '{}', 10, 'layouts', 0);
        Lib.AddStep(PlaybookCodeTok, 40, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Set", '{}', 10, 'layouts', 0);
        CreateArgument(TempArgument, StrSubstNo(Format1Tok, PlaybookCodeTok));
        // [WHEN] The playbook is verified through the message type handler
        Handler.ExecuteVerify(TempArgument);
        // [THEN] One localized warning names the write step and the check
        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('status', Token);
        Assert.AreEqual('Success', Token.AsValue().AsText(), 'status');
        ResponseJson.Get('findings', Token);
        Findings := OnlyUnsafeWrites(Token.AsArray());
        Assert.AreEqual(1, Findings.Count(), 'One UnsafeForEachWrite finding');
        Findings.Get(0, Warning);
        Warning.AsObject().Get('code', Token);
        Assert.AreEqual('UnsafeForEachWrite', Token.AsValue().AsText(), 'code');
        Warning.AsObject().Get('severity', Token);
        Assert.AreEqual('warning', Token.AsValue().AsText(), 'severity');
        Warning.AsObject().Get('nextStep', Token);
        Assert.IsTrue(Token.AsValue().AsText().Contains('30') and Token.AsValue().AsText().Contains('40'), 'nextStep names the gate and the step: ' + Token.AsValue().AsText());
        Warning.AsObject().Get('stepNo', Token);
        Assert.AreEqual(40, Token.AsValue().AsInteger(), 'stepNo');
        Warning.AsObject().Get('checkStepNo', Token);
        Assert.AreEqual(30, Token.AsValue().AsInteger(), 'checkStepNo');
        Warning.AsObject().Get('message', Token);
        Message := Token.AsValue().AsText();
        Assert.IsTrue(Message.StartsWith(ExpectedStart), 'Localized start expected: ' + ExpectedStart + ' got: ' + Message);
        Assert.IsTrue(Message.EndsWith(ExpectedEnd), 'Localized end expected: ' + ExpectedEnd + ' got: ' + Message);
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyCorrectedPatternIsClean(LanguageId: Integer)
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Playbook Verify ori";
        ResponseJson: JsonObject;
        Token: JsonToken;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] The same shape with Skip If Step Failed = the Check raises no warning
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddLayoutSourceStep(PlaybookCodeTok, 10);
        Lib.AddStep(PlaybookCodeTok, 30, "Playbook Step Type ori"::Check, "Message Type ori"::"Help.Implementation.Get", '{}', 10, 'layouts', 0);
        Lib.AddStep(PlaybookCodeTok, 40, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Set", '{}', 10, 'layouts', 30);
        CreateArgument(TempArgument, StrSubstNo(Format1Tok, PlaybookCodeTok));

        Handler.ExecuteVerify(TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('findings', Token);
        Assert.AreEqual(0, OnlyUnsafeWrites(Token.AsArray()).Count(), 'No UnsafeForEachWrite for the corrected pattern');
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    /// <summary>Keeps the UnsafeForEachWrite findings of a list of findings.</summary>
    local procedure OnlyUnsafeWrites(Findings: JsonArray) Kept: JsonArray
    var
        Token: JsonToken;
        CodeToken: JsonToken;
    begin
        foreach Token in Findings do
            if Token.AsObject().Get('code', CodeToken) then
                if CodeToken.AsValue().AsText() = 'UnsafeForEachWrite' then
                    Kept.Add(Token);
    end;

    local procedure WarningInt(Warnings: JsonArray; Index: Integer; PropertyName: Text): Integer
    var
        Warning: JsonToken;
        Value: JsonToken;
    begin
        Warnings.Get(Index, Warning);
        Warning.AsObject().Get(PropertyName, Value);
        exit(Value.AsValue().AsInteger());
    end;

    local procedure CreateArgument(var TempArgument: Record "Message Argument ori" temporary; RequestJsonText: Text)
    var
        RequestJson: JsonObject;
    begin
        TempArgument.Reset();
        TempArgument.DeleteAll();
        TempArgument.Init();
        TempArgument.Insert();
        RequestJson.ReadFrom(RequestJsonText);
        TempArgument.SetRequestJson(RequestJson);
    end;
    var
        Format1Tok: Label '{"playbookCode":"%1"}', Locked = true;
}
