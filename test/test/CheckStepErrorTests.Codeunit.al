namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>
/// Issue #106: a technical error inside a Check step (the message type raising an error or answering
/// status Error) is a failure of the step and of the run, never the answer "no". An answer of no and
/// an answer of yes keep their meaning. Every scenario runs in en-US (1033) and is-IS (1039).
/// </summary>
codeunit 96430 "Check Step Error Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Lib: Codeunit "Playbook Test Library ori";
        PlaybookCodeTok: Label 'CHK-106', Locked = true;
        FailingReportErrTxt: Label 'Deliberate failure from the test report.', Locked = true;
        ReportNotFoundTxt: Label 'not found', Locked = true;
        ReportNotFoundIsTxt: Label 'finnst ekki', Locked = true;
        AnsweredNoTxt: Label 'Check answered no.', Locked = true;
        AnsweredNoIsTxt: Label 'Athugun svaraði nei.', Locked = true;

    // ---- the error classifier --------------------------------------------------------------

    /// <summary>A refusal with a code and an Icelandic error text keeps both.</summary>
    [Test]
    procedure ErrorResponseKeepsCodeAndError()
    var
        JsonHelper: Codeunit "Playbook JSON Helper ori";
        ErrorText: Text;
    begin
        // [GIVEN] A refusal shaped like the one in issue 106
        // [WHEN] It is classified
        // [THEN] It is an error and its text names the code and the error
        Assert.IsTrue(JsonHelper.IsErrorResponse('{"status":"Error","code":"RecordNotFound","error":"Bifröst mállíkanið \"HAIKU\" fannst ekki.","parameter":"roleCode"}', ErrorText), 'refusal is an error');
        Assert.AreEqual('RecordNotFound: Bifröst mállíkanið "HAIKU" fannst ekki.', ErrorText, 'code and error kept');
    end;

    /// <summary>A plain Error answer without a code gives just the error text; message is the fallback key.</summary>
    [Test]
    procedure ErrorResponseWithoutCodeUsesErrorOrMessage()
    var
        JsonHelper: Codeunit "Playbook JSON Helper ori";
        ErrorText: Text;
    begin
        Assert.IsTrue(JsonHelper.IsErrorResponse('{"status":"Error","error":"Boom"}', ErrorText), 'error key');
        Assert.AreEqual('Boom', ErrorText, 'error text');
        Assert.IsTrue(JsonHelper.IsErrorResponse('{"status":"error","message":"Bang"}', ErrorText), 'message key, any case');
        Assert.AreEqual('Bang', ErrorText, 'message text');
        Assert.IsTrue(JsonHelper.IsErrorResponse('{"status":"Refused"}', ErrorText), 'status alone');
        Assert.AreEqual('Refused', ErrorText, 'status becomes the text');
    end;

    /// <summary>Success, other statuses without an error text, missing status and non-JSON are not errors.</summary>
    [Test]
    procedure NonErrorResponsesAreNotErrors()
    var
        JsonHelper: Codeunit "Playbook JSON Helper ori";
        ErrorText: Text;
    begin
        Assert.IsFalse(JsonHelper.IsErrorResponse('{"status":"Success","noOfRecords":0}', ErrorText), 'Success');
        Assert.AreEqual('', ErrorText, 'no text on Success');
        Assert.IsFalse(JsonHelper.IsErrorResponse('{"status":"Replaced","id":"x"}', ErrorText), 'Replaced is a success answer');
        Assert.IsFalse(JsonHelper.IsErrorResponse('{"result":[]}', ErrorText), 'no status');
        Assert.IsFalse(JsonHelper.IsErrorResponse('not json', ErrorText), 'not JSON');
        Assert.IsFalse(JsonHelper.IsErrorResponse('', ErrorText), 'empty');
        Assert.IsFalse(JsonHelper.IsErrorResponse('{"status":"Success","error":"ignored"}', ErrorText), 'Success wins');
    end;

    /// <summary>An errored iteration counts in failed and errored, never in checkFailed.</summary>
    [Test]
    procedure ErroredIterationsAreCountedApartFromNo()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        ItemObj: JsonObject;
        Result: Text;
    begin
        Workspace.Reset();
        Workspace.BeginRun('P', 'desc', CreateGuid());
        ItemObj.Add('no', '10000');

        Workspace.RecordIteration(30, 0, 'Completed', ItemObj.AsToken(), '', false);
        Workspace.RecordIteration(30, 1, 'CheckFailed', ItemObj.AsToken(), 'Check answered no.', false);
        Workspace.RecordIteration(30, 2, 'Errored', ItemObj.AsToken(), 'RecordNotFound: gone', false);

        Workspace.GetValue('_steps.30.items.total', Result);
        Assert.AreEqual('3', Result, 'items.total');
        Workspace.GetValue('_steps.30.items.checkFailed', Result);
        Assert.AreEqual('1', Result, 'checkFailed means only answered no');
        Workspace.GetValue('_steps.30.items.errored', Result);
        Assert.AreEqual('1', Result, 'items.errored');
        Workspace.GetValue('_steps.30.items.failed', Result);
        Assert.AreEqual('1', Result, 'an errored item is a failed item');
        Workspace.GetValue('_steps.30.failures[1].outcome', Result);
        Assert.AreEqual('Errored', Result, 'the failure list tells the two apart');
        Workspace.GetValue('_steps.30.failures[1].error', Result);
        Assert.AreEqual('RecordNotFound: gone', Result, 'error text carried');
    end;

    // ---- single Check step -----------------------------------------------------------------

    [Test]
    procedure SingleCheck_ErrorAnswer_FailsStepAndRun()
    begin
        VerifySingleCheckErrorAnswer(1033);
    end;

    [Test]
    procedure SingleCheck_ErrorAnswer_FailsStepAndRun_Icelandic()
    begin
        VerifySingleCheckErrorAnswer(1039);
    end;

    [Test]
    procedure SingleCheck_RaisedError_FailsStepAndRun()
    begin
        VerifySingleCheckRaisedError(1033, ReportNotFoundTxt);
    end;

    [Test]
    procedure SingleCheck_RaisedError_FailsStepAndRun_Icelandic()
    begin
        VerifySingleCheckRaisedError(1039, ReportNotFoundIsTxt);
    end;

    [Test]
    procedure SingleCheck_AnsweredNo_DoesNotFailTheRun()
    begin
        VerifySingleCheckAnswer(1033, 'NoSuchStatus', AnsweredNoTxt);
    end;

    [Test]
    procedure SingleCheck_AnsweredNo_DoesNotFailTheRun_Icelandic()
    begin
        VerifySingleCheckAnswer(1039, 'NoSuchStatus', AnsweredNoIsTxt);
    end;

    [Test]
    procedure SingleCheck_AnsweredYes_Completes()
    begin
        VerifySingleCheckAnswer(1033, 'Success', '');
    end;

    [Test]
    procedure SingleCheck_AnsweredYes_Completes_Icelandic()
    begin
        VerifySingleCheckAnswer(1039, 'Success', '');
    end;

    // ---- forEach Check step ----------------------------------------------------------------

    [Test]
    procedure ForEachCheck_ErrorAnswers_AreFailuresNotNo()
    begin
        VerifyForEachCheckErrors(1033);
    end;

    [Test]
    procedure ForEachCheck_ErrorAnswers_AreFailuresNotNo_Icelandic()
    begin
        VerifyForEachCheckErrors(1039);
    end;

    [Test]
    procedure ForEachCheck_RaisedErrors_AreFailuresNotNo()
    begin
        VerifyForEachCheckRaisedErrors(1033, ReportNotFoundTxt);
    end;

    [Test]
    procedure ForEachCheck_RaisedErrors_AreFailuresNotNo_Icelandic()
    begin
        VerifyForEachCheckRaisedErrors(1039, ReportNotFoundIsTxt);
    end;

    [Test]
    procedure ForEachCheck_AnsweredNo_IsCheckFailedAndDoesNotFailTheRun()
    begin
        VerifyForEachCheckAnswer(1033, 'NoSuchStatus', AnsweredNoTxt);
    end;

    [Test]
    procedure ForEachCheck_AnsweredNo_IsCheckFailedAndDoesNotFailTheRun_Icelandic()
    begin
        VerifyForEachCheckAnswer(1039, 'NoSuchStatus', AnsweredNoIsTxt);
    end;

    [Test]
    procedure ForEachCheck_AnsweredYes_Succeeds()
    begin
        VerifyForEachCheckAnswer(1033, 'Success', '');
    end;

    [Test]
    procedure ForEachCheck_AnsweredYes_Succeeds_Icelandic()
    begin
        VerifyForEachCheckAnswer(1039, 'Success', '');
    end;

    /// <summary>An Action step keeps its rule: an error answer without a Success condition is not changed by #106.</summary>
    [Test]
    procedure ActionStep_ErrorAnswerWithSuccessCondition_StillFails()
    var
        Instance: Record "Playbook Instance ori";
        InstanceId: Guid;
    begin
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Orchestrator.Report.Run", FailingReportRequest(), 0, '', 0);
        Lib.AddSuccessCondition(PlaybookCodeTok, 10, 'status', 'Success');

        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);

        Instance.Get(InstanceId);
        Assert.AreEqual(Instance.Status::Failed, Instance.Status, 'An Action with a false Success condition fails the run');
        Assert.AreEqual(1, Instance."Steps Failed", 'One step failed');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    local procedure VerifySingleCheckErrorAnswer(LanguageId: Integer)
    var
        Instance: Record "Playbook Instance ori";
        StepLog: Record "Playbook Step Log ori";
        Workspace: Codeunit "Playbook Workspace ori";
        InstanceId: Guid;
        PreviousLanguage: Integer;
        Result: Text;
    begin
        // [SCENARIO] A Check step whose message type answers status Error is Failed and fails the run
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        // [GIVEN] A Check step with a Success condition, calling a report that always fails
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Check, "Message Type ori"::"Orchestrator.Report.Run", FailingReportRequest(), 0, '', 0);
        Lib.AddSuccessCondition(PlaybookCodeTok, 10, 'status', 'Success');
        // [WHEN] The playbook runs
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        // [THEN] The run and the step failed, and the error text is on the step log
        Instance.Get(InstanceId);
        Assert.AreEqual(Instance.Status::Failed, Instance.Status, 'The run fails');
        Assert.AreEqual(1, Instance."Steps Failed", 'StepsFailed counts the Check');
        StepLog.Get(InstanceId, 10, 0);
        Assert.AreEqual(StepLog.Status::Failed, StepLog.Status, 'Step log status is Failed, not Cancelled');
        Assert.IsTrue(StepLog."Error Text".Contains(FailingReportErrTxt), 'The error text is on the step log: ' + StepLog."Error Text");
        Assert.IsFalse(StepLog."Error Text".Contains(AnsweredNoTxt), 'It is not recorded as an answer of no');
        Workspace.GetValue('_steps.10.status', Result);
        Assert.AreEqual('Failed', Result, '_steps status');
        Workspace.GetValue('_run.stepsFailed', Result);
        Assert.AreEqual('1', Result, '_run.stepsFailed');
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifySingleCheckRaisedError(LanguageId: Integer; ExpectedText: Text)
    var
        Instance: Record "Playbook Instance ori";
        StepLog: Record "Playbook Step Log ori";
        InstanceId: Guid;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] A Check step whose message type raises an error shows the localized error text
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Check, "Message Type ori"::"Orchestrator.Report.Run", '{"reportId":999999999}', 0, '', 0);
        Lib.AddSuccessCondition(PlaybookCodeTok, 10, 'status', 'Success');
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        Instance.Get(InstanceId);
        Assert.AreEqual(Instance.Status::Failed, Instance.Status, 'The run fails');
        Assert.AreEqual(1, Instance."Steps Failed", 'StepsFailed counts the Check');
        StepLog.Get(InstanceId, 10, 0);
        Assert.AreEqual(StepLog.Status::Failed, StepLog.Status, 'Step log status is Failed');
        Assert.IsTrue(HasReportNotFoundText(StepLog."Error Text", ExpectedText), 'Report-not-found text expected (' + ExpectedText + ') got: ' + StepLog."Error Text");
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifySingleCheckAnswer(LanguageId: Integer; ConditionValue: Text[250]; ExpectedLogText: Text)
    var
        Instance: Record "Playbook Instance ori";
        StepLog: Record "Playbook Step Log ori";
        InstanceId: Guid;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] A Check step that gets a Success answer evaluates its Success condition; no or yes, the run does not fail
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Check, "Message Type ori"::"Help.Implementation.Get", HelpRequest(), 0, '', 0);
        Lib.AddSuccessCondition(PlaybookCodeTok, 10, 'status', ConditionValue);
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        Instance.Get(InstanceId);
        Assert.AreEqual(Instance.Status::Completed, Instance.Status, 'An answer never fails the run');
        Assert.AreEqual(0, Instance."Steps Failed", 'No step failed');
        StepLog.Get(InstanceId, 10, 0);
        Assert.AreEqual(StepLog.Status::Completed, StepLog.Status, 'Step log status');
        Assert.AreEqual(ExpectedLogText, StepLog."Error Text", 'Step log tells no from yes');
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyForEachCheckErrors(LanguageId: Integer)
    var
        Instance: Record "Playbook Instance ori";
        StepLog: Record "Playbook Step Log ori";
        Workspace: Codeunit "Playbook Workspace ori";
        InstanceId: Guid;
        PreviousLanguage: Integer;
        Result: Text;
        Total: Integer;
    begin
        // [SCENARIO] Every iteration of a forEach Check whose type answers status Error is Failed and counted as errored
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        // [GIVEN] A forEach Check with a Success condition over the sample report layouts, calling a failing report
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddLayoutSourceStep(PlaybookCodeTok, 10);
        Lib.AddStep(PlaybookCodeTok, 30, "Playbook Step Type ori"::Check, "Message Type ori"::"Orchestrator.Report.Run", FailingReportRequest(), 10, 'layouts', 0);
        Lib.AddSuccessCondition(PlaybookCodeTok, 30, 'status', 'Success');
        // [WHEN] The playbook runs
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        // [THEN] The iterations failed, the error text is on the log and the run failed
        Instance.Get(InstanceId);
        Workspace.GetValue('_steps.30.items.total', Result);
        Evaluate(Total, Result);
        Assert.IsTrue(Total > 0, 'The check iterated');
        Assert.AreEqual(Instance.Status::Failed, Instance.Status, 'The run fails');
        Assert.AreEqual(Total, Instance."Steps Failed", 'Every iteration is a failed step');
        StepLog.Get(InstanceId, 30, 0);
        Assert.AreEqual(StepLog.Status::Failed, StepLog.Status, 'Iteration status is Failed, not Cancelled');
        Assert.IsTrue(StepLog."Error Text".Contains(FailingReportErrTxt), 'The error text is on the iteration log: ' + StepLog."Error Text");
        Workspace.GetValue('_steps.30.items.errored', Result);
        Assert.AreEqual(Format(Total), Result, 'items.errored');
        Assert.IsFalse(Workspace.GetValue('_steps.30.items.checkFailed', Result), 'checkFailed means only answered no');
        Workspace.GetValue('_steps.30.failures[0].error', Result);
        Assert.IsTrue(Result.Contains(FailingReportErrTxt), '_steps failure carries the error text');
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyForEachCheckRaisedErrors(LanguageId: Integer; ExpectedText: Text)
    var
        Instance: Record "Playbook Instance ori";
        StepLog: Record "Playbook Step Log ori";
        Workspace: Codeunit "Playbook Workspace ori";
        InstanceId: Guid;
        PreviousLanguage: Integer;
        Result: Text;
    begin
        // [SCENARIO] A forEach Check whose type raises an error carries the localized text on the log and in _steps
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddLayoutSourceStep(PlaybookCodeTok, 10);
        Lib.AddStep(PlaybookCodeTok, 30, "Playbook Step Type ori"::Check, "Message Type ori"::"Orchestrator.Report.Run", '{"reportId":999999999}', 10, 'layouts', 0);
        Lib.AddSuccessCondition(PlaybookCodeTok, 30, 'status', 'Success');
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        Instance.Get(InstanceId);
        Assert.AreEqual(Instance.Status::Failed, Instance.Status, 'The run fails');
        StepLog.Get(InstanceId, 30, 0);
        Assert.AreEqual(StepLog.Status::Failed, StepLog.Status, 'Iteration status is Failed');
        Assert.IsTrue(HasReportNotFoundText(StepLog."Error Text", ExpectedText), 'Report-not-found text expected (' + ExpectedText + ') got: ' + StepLog."Error Text");
        Workspace.GetValue('_steps.30.failures[0].error', Result);
        Assert.IsTrue(HasReportNotFoundText(Result, ExpectedText), '_steps failure carries the error text');
        Assert.IsTrue(Workspace.GetValue('_steps.30.items.errored', Result), 'items.errored present');
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyForEachCheckAnswer(LanguageId: Integer; ConditionValue: Text[250]; ExpectedLogText: Text)
    var
        Instance: Record "Playbook Instance ori";
        StepLog: Record "Playbook Step Log ori";
        Workspace: Codeunit "Playbook Workspace ori";
        InstanceId: Guid;
        PreviousLanguage: Integer;
        Result: Text;
        Total: Integer;
    begin
        // [SCENARIO] A forEach Check that gets Success answers is no or yes per its condition; the run does not fail
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddLayoutSourceStep(PlaybookCodeTok, 10);
        Lib.AddStep(PlaybookCodeTok, 30, "Playbook Step Type ori"::Check, "Message Type ori"::"Help.Implementation.Get", HelpRequest(), 10, 'layouts', 0);
        Lib.AddSuccessCondition(PlaybookCodeTok, 30, 'status', ConditionValue);
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        Instance.Get(InstanceId);
        Workspace.GetValue('_steps.30.items.total', Result);
        Evaluate(Total, Result);
        Assert.IsTrue(Total > 0, 'The check iterated');
        Assert.AreEqual(Instance.Status::Completed, Instance.Status, 'An answer never fails the run');
        Assert.AreEqual(0, Instance."Steps Failed", 'No step failed');
        StepLog.Get(InstanceId, 30, 0);
        Assert.AreEqual(ExpectedLogText, StepLog."Error Text", 'Step log tells no from yes');
        Assert.IsFalse(Workspace.GetValue('_steps.30.items.errored', Result), 'Nothing errored');
        if ExpectedLogText = '' then begin
            Assert.AreEqual(StepLog.Status::Completed, StepLog.Status, 'yes is Completed');
            Workspace.GetValue('_steps.30.items.succeeded', Result);
            Assert.AreEqual(Format(Total), Result, 'items.succeeded');
            Assert.IsFalse(Workspace.GetValue('_steps.30.items.checkFailed', Result), 'no checkFailed on yes');
        end else begin
            Assert.AreEqual(StepLog.Status::Cancelled, StepLog.Status, 'no is Cancelled');
            Workspace.GetValue('_steps.30.items.checkFailed', Result);
            Assert.AreEqual(Format(Total), Result, 'items.checkFailed');
        end;
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    /// <summary>
    /// The dispatcher answers a raised error in the language of the session it runs in, which is not always the
    /// test's GlobalLanguage, so the text is accepted in the language asked for or in en-US; what the assertion
    /// proves is that the raised error's own text reached the log instead of an empty ErrorText.
    /// </summary>
    local procedure HasReportNotFoundText(ErrorText: Text; ExpectedText: Text): Boolean
    begin
        exit(ErrorText.Contains(ExpectedText) or ErrorText.Contains(ReportNotFoundTxt));
    end;

    local procedure FailingReportRequest(): Text
    begin
        exit(StrSubstNo('{"reportId":%1}', Report::"Test Failing Report"));
    end;

    local procedure HelpRequest(): Text
    begin
        exit('{"messageTypes":["Orchestrator.Playbook.Schedule"],"chapters":["parameters"]}');
    end;
}
