namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>
/// Issue #113: Verify keeps all findings and its published totals, while additive blocking counts
/// agree with the Run/Schedule gate in both supported languages. All playbooks are self-created.
/// </summary>
codeunit 96442 "Verify Summary Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Lib: Codeunit "Playbook Test Library ori";
        PlaybookCodeTok: Label 'SUMMARY-113', Locked = true;

    [Test]
    procedure Scenario_AC01_DisabledErrors_DoNotBlock()
    begin
        VerifySummary(1033, 0, 2, 1, 0, 0);
    end;

    [Test]
    procedure Scenario_AC01_DisabledErrors_DoNotBlock_IsIS()
    begin
        VerifySummary(1039, 0, 2, 1, 0, 0);
    end;

    [Test]
    procedure Scenario_AC01_MixedFindings_OnlyEnabledWarningBlocks()
    begin
        VerifySummary(1033, 1, 2, 2, 0, 1);
    end;

    [Test]
    procedure Scenario_AC01_MixedFindings_OnlyEnabledWarningBlocks_IsIS()
    begin
        VerifySummary(1039, 1, 2, 2, 0, 1);
    end;

    [Test]
    procedure Scenario_AC01_EnabledError_StillBlocks()
    begin
        VerifySummary(1033, 2, 3, 1, 1, 0);
    end;

    [Test]
    procedure Scenario_AC01_EnabledError_StillBlocks_IsIS()
    begin
        VerifySummary(1039, 2, 3, 1, 1, 0);
    end;

    [Test]
    procedure Scenario_AC01_CleanPlaybook_HasZeroCounts()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Playbook Verify ori";
        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] Existing clean summaries stay valid and both new counts are present and zero.
        // [GIVEN] An empty, self-created playbook.
        Lib.CreatePlaybook(PlaybookCodeTok);
        CreateArgument(TempArgument);
        // [WHEN] Verify answers.
        Handler.ExecuteVerify(TempArgument);
        // [THEN] All summary counts are zero and no findings are lost or invented.
        ResponseJson := TempArgument.GetResponseJson();
        AssertCounts(ResponseJson, 0, 0, 0, 0);
        ResponseJson.Get('valid', Token);
        Assert.IsTrue(Token.AsValue().AsBoolean(), 'The clean playbook is valid');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure Scenario_AC02_Help_ExplainsBlockingCounts()
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Contract: JsonObject;
        Response: JsonToken;
        Fields: JsonToken;
        Field: JsonToken;
        Name: JsonToken;
        Description: JsonToken;
        Notes: JsonToken;
        BlockingFields: Integer;
    begin
        // [SCENARIO] Callers discover which pair to read without changing the old summary contract.
        // [GIVEN] The published Verify message contract.
        Assert.IsTrue(ContractMgt.GetContract("Message Type ori"::"Orchestrator.Playbook.Verify", Contract), 'Verify has a contract');
        // [WHEN] The response fields and notes are read.
        Contract.Get('response', Response);
        Response.AsObject().Get('fields', Fields);
        foreach Field in Fields.AsArray() do begin
            Field.AsObject().Get('name', Name);
            if Name.AsValue().AsText() in ['blockingErrorCount', 'blockingWarningCount'] then begin
                Field.AsObject().Get('description', Description);
                Assert.IsTrue(Description.AsValue().AsText().Contains('disabled steps'), 'The blocking field explains informational findings');
                BlockingFields += 1;
            end;
        end;
        // [THEN] Both additive fields are documented and the informational distinction is explicit.
        Assert.AreEqual(2, BlockingFields, 'Both blocking counts are documented');
        Contract.Get('notes', Notes);
        Assert.IsTrue(Notes.AsValue().AsText().Contains('Findings on disabled steps are informational.'), 'Disabled findings are informational');
        Assert.IsTrue(Notes.AsValue().AsText().Contains('read blockingErrorCount and blockingWarningCount'), 'Notes name the readiness counts');
    end;

    local procedure VerifySummary(LanguageId: Integer; EnabledShape: Integer; Errors: Integer; Warnings: Integer; BlockingErrors: Integer; BlockingWarnings: Integer)
    var
        TempArgument: Record "Message Argument ori" temporary;
        Step: Record "Playbook Step ori";
        Handler: Codeunit "Playbook Verify ori";
        ResponseJson: JsonObject;
        Token: JsonToken;
        Finding: JsonToken;
        Value: JsonToken;
        Blocking: JsonArray;
        Summary: Text;
        PreviousLanguage: Integer;
        DisabledFindings: Integer;
    begin
        // [SCENARIO] Disabled errors stay visible, but only enabled findings affect readiness.
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        // [GIVEN] A self-created disabled Action with two errors and a warning, optionally mixed with an enabled finding.
        Lib.CreatePlaybook(PlaybookCodeTok);
        if EnabledShape = 1 then
            Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Help.Implementation.Get", '{}', 0, '', 0);
        if EnabledShape = 2 then
            Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Check, "Message Type ori"::"Help.Implementation.Get", '{}', 0, '', 0);
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Action, "Message Type ori"::"Help.Implementation.Get", 'not JSON', 0, '', 0);
        Lib.SetStepDisabled(PlaybookCodeTok, 20, true);
        Step.SetLoadFields("Next Step No. (Success)");
        Step.Get(PlaybookCodeTok, 20);
        Step."Next Step No. (Success)" := 999;
        Step.Modify(true);
        CreateArgument(TempArgument);
        // [WHEN] The message type returns the summary.
        Handler.ExecuteVerify(TempArgument);
        // [THEN] Old totals and validity keep their meaning; blocking counts exclude exactly the disabled findings.
        ResponseJson := TempArgument.GetResponseJson();
        AssertCounts(ResponseJson, Errors, Warnings, BlockingErrors, BlockingWarnings);
        ResponseJson.Get('valid', Token);
        Assert.IsFalse(Token.AsValue().AsBoolean(), 'Published validity still includes disabled errors');
        ResponseJson.Get('findings', Token);
        foreach Finding in Token.AsArray() do begin
            Finding.AsObject().Get('stepNo', Value);
            if Value.AsValue().AsInteger() = 20 then begin
                Assert.IsTrue(Finding.AsObject().Get('stepDisabled', Value), 'Disabled finding retains its flag');
                Assert.IsTrue(Value.AsValue().AsBoolean(), 'stepDisabled is true');
                DisabledFindings += 1;
            end else
                Assert.IsFalse(Finding.AsObject().Contains('stepDisabled'), 'Enabled finding has no disabled flag');
            Finding.AsObject().Get('message', Value);
            Assert.AreNotEqual('', Value.AsValue().AsText(), 'Per-step message is retained');
            Finding.AsObject().Get('nextStep', Value);
            Assert.AreNotEqual('', Value.AsValue().AsText(), 'Per-step fix is retained');
        end;
        Assert.AreEqual(3, DisabledFindings, 'All three informational findings remain visible');
        Assert.AreEqual(BlockingErrors + BlockingWarnings > 0, Handler.GetBlockingFindings(PlaybookCodeTok, false, Blocking, Summary), 'Normal Run/Schedule gate agrees');
        Assert.AreEqual(BlockingErrors + BlockingWarnings, Blocking.Count(), 'Normal gate finding count');
        Assert.AreEqual(BlockingErrors > 0, Handler.GetBlockingFindings(PlaybookCodeTok, true, Blocking, Summary), 'ignoreWarnings never waives an error');
        Assert.AreEqual(BlockingErrors, Blocking.Count(), 'Warning acceptance excludes only warnings');
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure AssertCounts(ResponseJson: JsonObject; Errors: Integer; Warnings: Integer; BlockingErrors: Integer; BlockingWarnings: Integer)
    var
        Token: JsonToken;
    begin
        ResponseJson.Get('errorCount', Token);
        Assert.AreEqual(Errors, Token.AsValue().AsInteger(), 'errorCount retains all errors');
        ResponseJson.Get('warningCount', Token);
        Assert.AreEqual(Warnings, Token.AsValue().AsInteger(), 'warningCount retains all warnings');
        ResponseJson.Get('blockingErrorCount', Token);
        Assert.AreEqual(BlockingErrors, Token.AsValue().AsInteger(), 'blockingErrorCount');
        ResponseJson.Get('blockingWarningCount', Token);
        Assert.AreEqual(BlockingWarnings, Token.AsValue().AsInteger(), 'blockingWarningCount');
        ResponseJson.Get('findings', Token);
        Assert.AreEqual(Errors + Warnings, Token.AsArray().Count(), 'Every original finding is retained');
    end;

    local procedure CreateArgument(var TempArgument: Record "Message Argument ori" temporary)
    var
        RequestJson: JsonObject;
    begin
        TempArgument.Init();
        TempArgument.Insert();
        RequestJson.Add('playbookCode', PlaybookCodeTok);
        TempArgument.SetRequestJson(RequestJson);
    end;
}
