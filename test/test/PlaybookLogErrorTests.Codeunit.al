namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>
/// Issue #218: playbook logs. Every Failed step and instance has an Error Text (error answer, raised error and
/// Success condition not met alike), Response Received is always JSON, and a Check that answers no is an
/// outcome in Outcome Note, never an Error Text. Scenarios run in en-US (1033) and is-IS (1039).
/// </summary>
codeunit 96495 "Playbook Log Error Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Lib: Codeunit "Playbook Test Library ori";
        PlaybookCodeTok: Label 'LOG-218', Locked = true;
        RequestFormat1Tok: Label '{"reportId":%1,"expectedCount":1}', Locked = true;
        AnsweredNoTxt: Label 'Check answered no.', Locked = true;

    [Test]
    procedure RaisedError_StepAndInstanceHaveErrorText_ResponseIsJson()
    begin
        VerifyRaisedError(1033);
    end;

    [Test]
    procedure RaisedError_StepAndInstanceHaveErrorText_ResponseIsJson_Icelandic()
    begin
        VerifyRaisedError(1039);
    end;

    [Test]
    procedure ErrorAnswer_StepAndInstanceHaveErrorText()
    begin
        VerifyErrorAnswer(1033);
    end;

    [Test]
    procedure ErrorAnswer_StepAndInstanceHaveErrorText_Icelandic()
    begin
        VerifyErrorAnswer(1039);
    end;

    [Test]
    procedure ConditionNotMet_StepAndInstanceHaveErrorText()
    begin
        VerifyConditionNotMet(1033);
    end;

    [Test]
    procedure ConditionNotMet_StepAndInstanceHaveErrorText_Icelandic()
    begin
        VerifyConditionNotMet(1039);
    end;

    [Test]
    procedure ForEachFailure_StepSummaryHasErrorText()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        InstanceId: Guid;
        Result: Text;
    begin
        // [SCENARIO] A forEach step with failed items names the first failure in its step summary, not an empty error
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddLayoutSourceStep(PlaybookCodeTok, 10);
        Lib.AddStep(PlaybookCodeTok, 30, "Playbook Step Type ori"::Action, "Message Type ori"::"Help.Implementation.Get", HelpRequest(), 10, 'layouts', 0);
        Lib.AddSuccessCondition(PlaybookCodeTok, 30, 'isReady', 'true');
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        Assert.IsTrue(Workspace.GetValue('_steps.30.error', Result), 'the step summary has an error');
        Assert.AreNotEqual('', Result, 'the step error is not empty');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure CheckNo_IsANoteNotAnError_InLogAndSummary()
    var
        StepLog: Record "Playbook Step Log ori";
        Instance: Record "Playbook Instance ori";
        Workspace: Codeunit "Playbook Workspace ori";
        InstanceId: Guid;
        Result: Text;
    begin
        // [SCENARIO] A Check that answers no keeps Error Text empty and shows the outcome in Outcome Note
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddLayoutSourceStep(PlaybookCodeTok, 10);
        Lib.AddStep(PlaybookCodeTok, 30, "Playbook Step Type ori"::Check, "Message Type ori"::"Help.Implementation.Get", HelpRequest(), 10, 'layouts', 0);
        Lib.AddSuccessCondition(PlaybookCodeTok, 30, 'status', 'NoSuchStatus');
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        Instance.Get(InstanceId);
        Assert.AreEqual('', Instance."Error Text", 'The instance has no error');
        StepLog.SetRange("Instance ID", InstanceId);
        StepLog.SetRange("Step No.", 30);
        StepLog.SetRange("Outcome Note", AnsweredNoTxt);
        Assert.IsTrue(StepLog.FindFirst(), 'The no is in Outcome Note');
        Assert.AreEqual('', StepLog."Error Text", 'Error Text stays empty');
        Assert.IsFalse(Workspace.GetValue('_steps.30.failures[0].error', Result), 'The summary has no error for a no');
        Assert.IsTrue(Workspace.GetValue('_steps.30.failures[0].note', Result), 'The summary has the note');
        Assert.AreEqual(AnsweredNoTxt, Result, 'note text');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    local procedure VerifyRaisedError(LanguageId: Integer)
    var
        Instance: Record "Playbook Instance ori";
        StepLog: Record "Playbook Step Log ori";
        Response: JsonObject;
        Token: JsonToken;
        InstanceId: Guid;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] A message type that raises a plain-text error: step and instance carry it, the response is JSON
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Orchestrator.Report.Run", '{"reportId":999999999,"expectedCount":1}', 0, '', 0);
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        Instance.Get(InstanceId);
        Assert.AreEqual(Instance.Status::Failed, Instance.Status, 'The run fails');
        Assert.AreNotEqual('', Instance."Error Text", 'The instance has an error text');
        StepLog.Get(InstanceId, 10, 0);
        Assert.AreEqual(StepLog.Status::Failed, StepLog.Status, 'Step Failed');
        Assert.AreNotEqual('', StepLog."Error Text", 'The step has an error text');
        Assert.IsTrue(Response.ReadFrom(StepLog.GetResponseReceived()), 'Response Received is JSON: ' + StepLog.GetResponseReceived());
        Assert.IsTrue(Response.Get('status', Token), 'status present');
        Assert.AreEqual('Error', Token.AsValue().AsText(), 'status Error');
        Assert.IsTrue(Response.Get('error', Token), 'error present');
        Assert.AreNotEqual('', Token.AsValue().AsText(), 'error text present');
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyErrorAnswer(LanguageId: Integer)
    var
        Instance: Record "Playbook Instance ori";
        StepLog: Record "Playbook Step Log ori";
        Response: JsonObject;
        InstanceId: Guid;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] A message type that answers status Error: step and instance carry the error, the response is JSON
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Orchestrator.Report.Run", StrSubstNo(RequestFormat1Tok, Report::"Test Failing Report"), 0, '', 0);
        Lib.AddSuccessCondition(PlaybookCodeTok, 10, 'status', 'Success');
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        Instance.Get(InstanceId);
        Assert.AreNotEqual('', Instance."Error Text", 'The instance has an error text');
        StepLog.Get(InstanceId, 10, 0);
        Assert.AreNotEqual('', StepLog."Error Text", 'The step has an error text');
        Assert.IsTrue(Response.ReadFrom(StepLog.GetResponseReceived()), 'Response Received is JSON');
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyConditionNotMet(LanguageId: Integer)
    var
        Instance: Record "Playbook Instance ori";
        StepLog: Record "Playbook Step Log ori";
        InstanceId: Guid;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] A successful answer whose Success condition does not hold: Failed with the condition named
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Help.Implementation.Get", HelpRequest(), 0, '', 0);
        Lib.AddSuccessCondition(PlaybookCodeTok, 10, 'isReady', 'true');
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        Instance.Get(InstanceId);
        Assert.AreEqual(Instance.Status::Failed, Instance.Status, 'The run fails');
        Assert.IsTrue(Instance."Error Text".Contains('isReady'), 'The instance names the condition: ' + Instance."Error Text");
        StepLog.Get(InstanceId, 10, 0);
        Assert.IsTrue(StepLog."Error Text".Contains('isReady'), 'The step names the condition: ' + StepLog."Error Text");
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure HelpRequest(): Text
    begin
        exit('{"messageTypes":["Orchestrator.Playbook.Schedule"],"chapters":["parameters"]}');
    end;
}
