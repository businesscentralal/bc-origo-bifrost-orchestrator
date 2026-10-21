namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>
/// Issue #109: Orchestrator.Playbook.Run and the enabling of a schedule verify first and refuse with
/// PreconditionFailed, naming the findings: an error always, a warning unless ignoreWarnings is true. The refusals are
/// tested in en-US (1033) and is-IS (1039). A finding about a disabled step does not block, a scheduled playbook with
/// errors is reported, and a run started by the Job Queue is not gated.
/// </summary>
codeunit 96437 "Playbook Gate Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Lib: Codeunit "Playbook Test Library ori";
        PlaybookCodeTok: Label 'GATE-109', Locked = true;
        TemplateCodeTok: Label 'GATE-109-TPL', Locked = true;
        RefusedStartTxt: Label 'Playbook GATE-109 was not started: errors on enabled steps: 1, warnings: 0.', Locked = true;
        RefusedStartIsTxt: Label 'Keðjan GATE-109 var ekki ræst: villur í virkum skrefum: 1, viðvaranir: 0.', Locked = true;
        RefusedWarningStartTxt: Label 'Playbook GATE-109 was not started: errors on enabled steps: 0, warnings: 1.', Locked = true;
        RefusedWarningStartIsTxt: Label 'Keðjan GATE-109 var ekki ræst: villur í virkum skrefum: 0, viðvaranir: 1.', Locked = true;
        NextStepStartTxt: Label 'Call Orchestrator.Playbook.Verify with the same playbookCode, fix the findings, then call again.', Locked = true;
        NextStepStartIsTxt: Label 'Kallaðu á Orchestrator.Playbook.Verify með sama playbookCode, lagaðu niðurstöðurnar og kallaðu svo aftur.', Locked = true;

    [Test]
    procedure Run_RefusesAnError()
    begin
        VerifyRunRefusesError(1033, RefusedStartTxt, NextStepStartTxt);
    end;

    [Test]
    procedure Run_RefusesAnError_Icelandic()
    begin
        VerifyRunRefusesError(1039, RefusedStartIsTxt, NextStepStartIsTxt);
    end;

    [Test]
    procedure Run_RefusesAWarning_UnlessIgnoreWarnings()
    begin
        VerifyRunWarning(1033, RefusedWarningStartTxt);
    end;

    [Test]
    procedure Run_RefusesAWarning_UnlessIgnoreWarnings_Icelandic()
    begin
        VerifyRunWarning(1039, RefusedWarningStartIsTxt);
    end;

    [Test]
    procedure Run_IgnoreWarnings_NeverWaivesAnError()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Playbook Msg Handler ori";
        ResponseJson: JsonObject;
        Findings: JsonArray;
        Token: JsonToken;
    begin
        // [SCENARIO] A playbook with an error and a warning: ignoreWarnings waives the warning, never the error
        BuildErrorPlaybook();
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Action, "Message Type ori"::"Help.Implementation.Get", HelpRequest(), 0, '', 0);
        Commit();
        CreateArgument(TempArgument, StrSubstNo('{"playbookCode":"%1","ignoreWarnings":true}', PlaybookCodeTok));

        Handler.ExecuteRun(TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        Assert.AreEqual('PreconditionFailed', TextOf(ResponseJson, 'code'), 'Refused');
        ResponseJson.Get('findings', Token);
        Findings := Token.AsArray();
        Assert.AreEqual(1, Findings.Count(), 'Only the error blocks');
        Findings.Get(0, Token);
        Assert.AreEqual('error', TextOf(Token.AsObject(), 'severity'), 'The blocking finding is the error');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure Run_ErrorOnDisabledStep_DoesNotBlock()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Playbook Msg Handler ori";
        ResponseJson: JsonObject;
    begin
        // [SCENARIO] Rule 15 of the help: a disabled step is how a step is switched off; its mistakes do not stop the rest
        BuildCleanPlaybook();
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Check, "Message Type ori"::"Help.Implementation.Get", HelpRequest(), 0, '', 0);
        Lib.SetStepDisabled(PlaybookCodeTok, 20, true);
        Commit();
        CreateArgument(TempArgument, StrSubstNo('{"playbookCode":"%1"}', PlaybookCodeTok));

        Handler.ExecuteRun(TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        Assert.AreEqual('Success', TextOf(ResponseJson, 'status'), 'The run was started');
        Assert.IsTrue(ResponseJson.Contains('instanceId'), 'An instance was written');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure Run_CleanPlaybook_Runs()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Playbook Msg Handler ori";
        ResponseJson: JsonObject;
    begin
        BuildCleanPlaybook();
        Commit();
        CreateArgument(TempArgument, StrSubstNo('{"playbookCode":"%1"}', PlaybookCodeTok));

        Handler.ExecuteRun(TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        Assert.AreEqual('Success', TextOf(ResponseJson, 'status'), 'A clean playbook runs');
        Assert.IsTrue(ResponseJson.Contains('playbookStatus'), 'The run answered its status');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure Schedule_RefusesAnError_AndCreatesNoEntry()
    begin
        VerifyScheduleRefusesError(1033, RefusedStartTxt);
    end;

    [Test]
    procedure Schedule_RefusesAnError_AndCreatesNoEntry_Icelandic()
    begin
        VerifyScheduleRefusesError(1039, RefusedStartIsTxt);
    end;

    [Test]
    procedure Schedule_CleanPlaybook_IsScheduled()
    var
        Playbook: Record "Playbook ori";
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Playbook Msg Handler ori";
        ResponseJson: JsonObject;
    begin
        BuildCleanPlaybook();
        CreateTemplate();
        CreateArgument(TempArgument, StrSubstNo('{"playbookCode":"%1","recurringTemplateCode":"%2"}', PlaybookCodeTok, TemplateCodeTok));

        Handler.ExecuteSchedule(TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        Assert.AreEqual('Success', TextOf(ResponseJson, 'status'), 'Scheduled');
        Playbook.Get(PlaybookCodeTok);
        Assert.IsFalse(IsNullGuid(Playbook."Orchestrator Entry ID"), 'The entry id is on the playbook');
        CleanupAll();
    end;

    [Test]
    procedure Schedule_RefusesAWarning_UnlessIgnoreWarnings()
    var
        Playbook: Record "Playbook ori";
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Playbook Msg Handler ori";
        ResponseJson: JsonObject;
    begin
        // [SCENARIO] An Action without a Success condition is a warning: it refuses the schedule until ignoreWarnings says it is meant
        BuildWarningPlaybook();
        CreateTemplate();
        CreateArgument(TempArgument, StrSubstNo('{"playbookCode":"%1","recurringTemplateCode":"%2"}', PlaybookCodeTok, TemplateCodeTok));
        Handler.ExecuteSchedule(TempArgument);
        ResponseJson := TempArgument.GetResponseJson();
        Assert.AreEqual('PreconditionFailed', TextOf(ResponseJson, 'code'), 'A warning refuses the schedule');

        CreateArgument(TempArgument, StrSubstNo('{"playbookCode":"%1","recurringTemplateCode":"%2","ignoreWarnings":true}', PlaybookCodeTok, TemplateCodeTok));
        Handler.ExecuteSchedule(TempArgument);
        ResponseJson := TempArgument.GetResponseJson();
        Assert.AreEqual('Success', TextOf(ResponseJson, 'status'), 'ignoreWarnings accepts the warning');
        Playbook.Get(PlaybookCodeTok);
        Assert.IsFalse(IsNullGuid(Playbook."Orchestrator Entry ID"), 'Scheduled');
        CleanupAll();
    end;

    [Test]
    procedure CreateOrchestratorEntry_RefusesAnError()
    var
        Playbook: Record "Playbook ori";
        EntryPkId: Guid;
    begin
        // [SCENARIO] The table procedure, used by the Schedule action of the card, verifies too
        BuildErrorPlaybook();
        CreateTemplate();
        Playbook.Get(PlaybookCodeTok);

        asserterror Playbook.CreateOrchestratorEntry(TemplateCodeTok, "Notif. Type ori"::None, '', '', false, "Retry Policy ori"::Always, true, EntryPkId);

        Assert.ExpectedError('was not started');
        Assert.ExpectedError('CheckWithoutSuccessCondition');
        CleanupAll();
    end;

    [Test]
    procedure CreateOrchestratorEntry_WarningNeedsIgnoreWarnings()
    var
        Playbook: Record "Playbook ori";
        EntryPkId: Guid;
    begin
        BuildWarningPlaybook();
        CreateTemplate();
        Commit();
        Playbook.Get(PlaybookCodeTok);

        asserterror Playbook.CreateOrchestratorEntry(TemplateCodeTok, "Notif. Type ori"::None, '', '', false, "Retry Policy ori"::Always, false, EntryPkId);
        Assert.ExpectedError('was not started');
        Assert.ExpectedError('ActionWithoutSuccessCondition');

        // The old signature keeps accepting warnings, so existing callers are not refused for them
        Playbook.CreateOrchestratorEntry(TemplateCodeTok, "Notif. Type ori"::None, '', '', false, "Retry Policy ori"::Always, EntryPkId);
        Assert.IsFalse(IsNullGuid(EntryPkId), 'The old signature accepts the warning');
        CleanupAll();
    end;

    [Test]
    procedure ScheduledPlaybookWithErrors_IsReported()
    var
        Playbook: Record "Playbook ori";
        Verify: Codeunit "Playbook Verify ori";
        Findings: JsonArray;
        EntryPkId: Guid;
    begin
        // [SCENARIO] A playbook that was scheduled while clean and has an error since says so
        BuildCleanPlaybook();
        CreateTemplate();
        Playbook.Get(PlaybookCodeTok);
        Playbook.CreateOrchestratorEntry(TemplateCodeTok, "Notif. Type ori"::None, '', '', false, "Retry Policy ori"::Always, EntryPkId);
        Verify.GetFindings(PlaybookCodeTok, Findings);
        Assert.AreEqual(0, Findings.Count(), 'Scheduled and clean: nothing to report');

        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Check, "Message Type ori"::"Help.Implementation.Get", HelpRequest(), 0, '', 0);
        Verify.GetFindings(PlaybookCodeTok, Findings);

        Assert.AreEqual(2, Findings.Count(), 'The error and the schedule finding');
        Assert.AreEqual(1, CountFindings(Findings, 'CheckWithoutSuccessCondition', 20), 'The error');
        Assert.AreEqual(1, CountFindings(Findings, 'ScheduledWithErrors', 0), 'The schedule finding is about the playbook as a whole');
        CleanupAll();
    end;

    [Test]
    procedure UnscheduledPlaybookWithErrors_HasNoScheduleFinding()
    var
        Verify: Codeunit "Playbook Verify ori";
        Findings: JsonArray;
    begin
        BuildErrorPlaybook();
        Verify.GetFindings(PlaybookCodeTok, Findings);
        Assert.AreEqual(1, Findings.Count(), 'Only the error');
        Assert.AreEqual(0, CountFindings(Findings, 'ScheduledWithErrors', -1), 'Not scheduled, so nothing to say about a schedule');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure VerifyMessageType_ReportsValidAndCounts()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Playbook Verify ori";
        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] The answer of Orchestrator.Playbook.Verify: valid, errorCount, warningCount and findings
        BuildErrorPlaybook();
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Action, "Message Type ori"::"Help.Implementation.Get", HelpRequest(), 0, '', 0);
        CreateArgument(TempArgument, StrSubstNo('{"playbookCode":"%1"}', PlaybookCodeTok));

        Handler.ExecuteVerify(TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        Assert.AreEqual('Success', TextOf(ResponseJson, 'status'), 'status');
        ResponseJson.Get('valid', Token);
        Assert.IsFalse(Token.AsValue().AsBoolean(), 'valid is false with an error');
        ResponseJson.Get('errorCount', Token);
        Assert.AreEqual(1, Token.AsValue().AsInteger(), 'errorCount');
        ResponseJson.Get('warningCount', Token);
        Assert.AreEqual(1, Token.AsValue().AsInteger(), 'warningCount');
        ResponseJson.Get('findings', Token);
        Assert.AreEqual(2, Token.AsArray().Count(), 'findings');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure VerifyMessageType_CleanPlaybook_IsValid()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Playbook Verify ori";
        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        BuildCleanPlaybook();
        CreateArgument(TempArgument, StrSubstNo('{"playbookCode":"%1"}', PlaybookCodeTok));

        Handler.ExecuteVerify(TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('valid', Token);
        Assert.IsTrue(Token.AsValue().AsBoolean(), 'valid');
        ResponseJson.Get('findings', Token);
        Assert.AreEqual(0, Token.AsArray().Count(), 'No findings');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    local procedure VerifyRunRefusesError(LanguageId: Integer; ExpectedStart: Text; ExpectedNextStepStart: Text)
    var
        TempArgument: Record "Message Argument ori" temporary;
        Instance: Record "Playbook Instance ori";
        Handler: Codeunit "Playbook Msg Handler ori";
        ResponseJson: JsonObject;
        Findings: JsonArray;
        Token: JsonToken;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] Run refuses a playbook with an error: PreconditionFailed on playbookCode, the findings in the answer, nothing runs
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        BuildErrorPlaybook();
        Commit();
        CreateArgument(TempArgument, StrSubstNo('{"playbookCode":"%1"}', PlaybookCodeTok));

        Handler.ExecuteRun(TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        Assert.AreEqual('Error', TextOf(ResponseJson, 'status'), 'status');
        Assert.AreEqual('PreconditionFailed', TextOf(ResponseJson, 'code'), 'code');
        Assert.AreEqual('playbookCode', TextOf(ResponseJson, 'parameter'), 'parameter');
        Assert.AreEqual(CodeText(), TextOf(ResponseJson, 'received'), 'received');
        Assert.IsTrue(TextOf(ResponseJson, 'error').StartsWith(ExpectedStart), 'Localized start expected: ' + ExpectedStart + ' got: ' + TextOf(ResponseJson, 'error'));
        Assert.IsTrue(TextOf(ResponseJson, 'error').Contains('CheckWithoutSuccessCondition'), 'The text names the finding');
        Assert.IsTrue(TextOf(ResponseJson, 'nextStep').StartsWith(ExpectedNextStepStart), 'Localized next step expected: ' + ExpectedNextStepStart + ' got: ' + TextOf(ResponseJson, 'nextStep'));
        ResponseJson.Get('findings', Token);
        Findings := Token.AsArray();
        Assert.AreEqual(1, Findings.Count(), 'The blocking finding is listed');
        Findings.Get(0, Token);
        Assert.AreEqual('CheckWithoutSuccessCondition', TextOf(Token.AsObject(), 'code'), 'finding code');
        Instance.SetRange("Playbook Code", PlaybookCodeTok);
        Assert.IsTrue(Instance.IsEmpty(), 'Nothing ran: no instance was written');
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyRunWarning(LanguageId: Integer; ExpectedStart: Text)
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Playbook Msg Handler ori";
        ResponseJson: JsonObject;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] A warning refuses the run too, until ignoreWarnings says the caller means it
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        BuildWarningPlaybook();
        Commit();
        CreateArgument(TempArgument, StrSubstNo('{"playbookCode":"%1"}', PlaybookCodeTok));
        Handler.ExecuteRun(TempArgument);
        ResponseJson := TempArgument.GetResponseJson();
        Assert.AreEqual('PreconditionFailed', TextOf(ResponseJson, 'code'), 'A warning refuses the run');
        Assert.IsTrue(TextOf(ResponseJson, 'error').StartsWith(ExpectedStart), 'Localized start expected: ' + ExpectedStart + ' got: ' + TextOf(ResponseJson, 'error'));

        CreateArgument(TempArgument, StrSubstNo('{"playbookCode":"%1","ignoreWarnings":true}', PlaybookCodeTok));
        Handler.ExecuteRun(TempArgument);
        ResponseJson := TempArgument.GetResponseJson();
        Assert.AreEqual('Success', TextOf(ResponseJson, 'status'), 'ignoreWarnings accepts the warning');
        Assert.IsTrue(ResponseJson.Contains('instanceId'), 'The run happened');
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyScheduleRefusesError(LanguageId: Integer; ExpectedStart: Text)
    var
        Playbook: Record "Playbook ori";
        Entry: Record "Scheduled Entry ori";
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Playbook Msg Handler ori";
        ResponseJson: JsonObject;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] Enabling a schedule runs the same verification: PreconditionFailed, and no Scheduled Entry ori
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        BuildErrorPlaybook();
        CreateTemplate();
        CreateArgument(TempArgument, StrSubstNo('{"playbookCode":"%1","recurringTemplateCode":"%2"}', PlaybookCodeTok, TemplateCodeTok));

        Handler.ExecuteSchedule(TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        Assert.AreEqual('PreconditionFailed', TextOf(ResponseJson, 'code'), 'code');
        Assert.IsTrue(TextOf(ResponseJson, 'error').StartsWith(ExpectedStart), 'Localized start expected: ' + ExpectedStart + ' got: ' + TextOf(ResponseJson, 'error'));
        Assert.IsTrue(ResponseJson.Contains('findings'), 'The findings are in the answer');
        Playbook.Get(PlaybookCodeTok);
        Assert.IsTrue(IsNullGuid(Playbook."Orchestrator Entry ID"), 'No entry id on the playbook');
        Entry.SetRange("Related Record System Id", Playbook.SystemId);
        Assert.IsTrue(Entry.IsEmpty(), 'No Scheduled Entry ori was created');
        CleanupAll();
        GlobalLanguage(PreviousLanguage);
    end;

    /// <summary>Step 10 is an Action with its Success condition: nothing to find.</summary>
    local procedure BuildCleanPlaybook()
    begin
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Help.Implementation.Get", HelpRequest(), 0, '', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 10);
    end;

    /// <summary>Step 10 is an Action without a Success condition: one warning.</summary>
    local procedure BuildWarningPlaybook()
    begin
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Help.Implementation.Get", HelpRequest(), 0, '', 0);
    end;

    /// <summary>Step 10 is a Check without a Success condition: one error.</summary>
    local procedure BuildErrorPlaybook()
    begin
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Check, "Message Type ori"::"Help.Implementation.Get", HelpRequest(), 0, '', 0);
    end;

    local procedure CreateTemplate()
    var
        RecurringTemplate: Record "Recurring Template ori";
    begin
        if RecurringTemplate.Get(TemplateCodeTok) then
            exit;
        RecurringTemplate.Init();
        RecurringTemplate.Code := TemplateCodeTok;
        RecurringTemplate.Description := 'Gate test template';
        RecurringTemplate."Run on Mondays" := true;
        RecurringTemplate."No. of Minutes between Runs" := 60;
        RecurringTemplate.Insert(true);
    end;

    local procedure CleanupAll()
    var
        Playbook: Record "Playbook ori";
        Entry: Record "Scheduled Entry ori";
        RecurringTemplate: Record "Recurring Template ori";
    begin
        if Playbook.Get(PlaybookCodeTok) then
            if not IsNullGuid(Playbook."Orchestrator Entry ID") then
                if Entry.Get(Playbook."Orchestrator Entry ID") then
                    Entry.Delete(true);
        Lib.Cleanup(PlaybookCodeTok);
        if RecurringTemplate.Get(TemplateCodeTok) then
            RecurringTemplate.Delete(true);
        Commit();
    end;

    local procedure CodeText(): Text
    begin
        exit(PlaybookCodeTok);
    end;

    local procedure HelpRequest(): Text
    begin
        exit('{"messageTypes":["Orchestrator.Playbook.Schedule"],"chapters":["parameters"]}');
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
}
