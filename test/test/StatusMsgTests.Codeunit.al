namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.Threading;

codeunit 96419 "Status Msg Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        PreviewPlaybookTok: Label 'XST-257', Locked = true;

    [Test]
    procedure GetReturnsSuccessWithEntryCounts()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Status Msg Handler ori";
        ResponseJson: JsonObject;
        Token: JsonToken;
        EntriesToken: JsonToken;
        EntriesObj: JsonObject;
    begin
        // [SCENARIO] Status.Get returns orchestrator health and entry counts
        CreateArgument(TempArgument, '{}');

        Handler.ExecuteGet(TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('status', Token);
        Assert.AreEqual('Success', Token.AsValue().AsText(), 'Status should be Success');
        Assert.IsTrue(ResponseJson.Contains('orchestratorStatus'), 'Missing orchestratorStatus');
        Assert.IsTrue(ResponseJson.Contains('jobQueueCategoryCode'), 'Missing jobQueueCategoryCode');

        ResponseJson.Get('entries', EntriesToken);
        EntriesObj := EntriesToken.AsObject();
        Assert.IsTrue(EntriesObj.Contains('total'), 'Missing entries.total');
        Assert.IsTrue(EntriesObj.Contains('blocked'), 'Missing entries.blocked');
        Assert.IsTrue(EntriesObj.Contains('active'), 'Missing entries.active');
    end;

    [Test]
    procedure GetEntryCountsAreConsistent()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Status Msg Handler ori";
        ResponseJson: JsonObject;
        EntriesToken: JsonToken;
        EntriesObj: JsonObject;
        Total: Integer;
        Blocked: Integer;
        Active: Integer;
    begin
        // [SCENARIO] blocked + active = total
        CreateArgument(TempArgument, '{}');

        Handler.ExecuteGet(TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('entries', EntriesToken);
        EntriesObj := EntriesToken.AsObject();
        Total := GetJsonInt(EntriesObj, 'total');
        Blocked := GetJsonInt(EntriesObj, 'blocked');
        Active := GetJsonInt(EntriesObj, 'active');

        Assert.AreEqual(Total, Blocked + Active, 'blocked + active should equal total');
    end;

    [Test]
    procedure RestartReturnsSuccessWithMessage()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Status Msg Handler ori";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] Status.Restart unconditionally restarts and returns success
        CreateArgument(TempArgument, '{}');

        BindSubscription(LibraryOrchestrator);
        Handler.ExecuteRestart(TempArgument);
        UnbindSubscription(LibraryOrchestrator);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('status', Token);
        Assert.AreEqual('Success', Token.AsValue().AsText(), 'Status should be Success');
        Assert.IsTrue(ResponseJson.Contains('message'), 'Missing message');
        Assert.IsTrue(ResponseJson.Contains('orchestratorStatus'), 'Missing orchestratorStatus');
    end;

    [Test]
    procedure RestartIfNeededRestartsWhenNoJQEntry()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Status Msg Handler ori";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] RestartIfNeeded restarts when management JQ entry does not exist
        CleanupManagementJQEntry();
        CreateArgument(TempArgument, '{}');

        BindSubscription(LibraryOrchestrator);
        Handler.ExecuteRestartIfNeeded(TempArgument);
        UnbindSubscription(LibraryOrchestrator);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('status', Token);
        Assert.AreEqual('Success', Token.AsValue().AsText(), 'Status should be Success');
        ResponseJson.Get('restarted', Token);
        Assert.IsTrue(Token.AsValue().AsBoolean(), 'Should have restarted');
    end;

    [Test]
    procedure RestartIfNeededSkipsWhenAlreadyRunning()
    var
        TempArgument: Record "Message Argument ori" temporary;
        JQEntry: Record "Job Queue Entry";
        JQEntryBefore: Record "Job Queue Entry";
        Handler: Codeunit "Status Msg Handler ori";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] RestartIfNeeded leaves a Ready management JQ entry unchanged
        CleanupManagementJQEntry();
        JQEntry.Init();
        JQEntry.Status := JQEntry.Status::Ready;
        InsertManagementJQEntry(JQEntry);
        JQEntryBefore := JQEntry;

        CreateArgument(TempArgument, '{}');

        BindSubscription(LibraryOrchestrator);
        Handler.ExecuteRestartIfNeeded(TempArgument);
        UnbindSubscription(LibraryOrchestrator);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('restarted', Token);
        Assert.IsFalse(Token.AsValue().AsBoolean(), 'Should not have restarted');
        AssertManagementJQEntryUnchanged(JQEntryBefore);

        CleanupManagementJQEntry();
    end;

    [Test]
    procedure RestartIfNeededSkipsWhenInProcess()
    var
        TempArgument: Record "Message Argument ori" temporary;
        JQEntry: Record "Job Queue Entry";
        JQEntryBefore: Record "Job Queue Entry";
        Handler: Codeunit "Status Msg Handler ori";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] RestartIfNeeded leaves an In Process management JQ entry unchanged
        CleanupManagementJQEntry();
        JQEntry.Init();
        JQEntry.Status := JQEntry.Status::"In Process";
        InsertManagementJQEntry(JQEntry);
        JQEntryBefore := JQEntry;

        CreateArgument(TempArgument, '{}');

        BindSubscription(LibraryOrchestrator);
        Handler.ExecuteRestartIfNeeded(TempArgument);
        UnbindSubscription(LibraryOrchestrator);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('restarted', Token);
        Assert.IsFalse(Token.AsValue().AsBoolean(), 'Should not have restarted');
        AssertManagementJQEntryUnchanged(JQEntryBefore);

        CleanupManagementJQEntry();
    end;

    [Test]
    procedure RestartIfNeededRestartsWhenInError()
    var
        TempArgument: Record "Message Argument ori" temporary;
        JQEntry: Record "Job Queue Entry";
        JQEntryBefore: Record "Job Queue Entry";
        Handler: Codeunit "Status Msg Handler ori";
        Mgt: Codeunit "Scheduler Mgt ori";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] RestartIfNeeded reschedules a management JQ entry that is in Error
        CleanupManagementJQEntry();
        JQEntry.Init();
        JQEntry.Status := JQEntry.Status::Error;
        InsertManagementJQEntry(JQEntry);
        JQEntryBefore := JQEntry;

        CreateArgument(TempArgument, '{}');

        BindSubscription(LibraryOrchestrator);
        Handler.ExecuteRestartIfNeeded(TempArgument);
        UnbindSubscription(LibraryOrchestrator);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('restarted', Token);
        Assert.IsTrue(Token.AsValue().AsBoolean(), 'Should have restarted when in Error');

        JQEntry.SetLoadFields(SystemId, Status);
        Assert.IsTrue(JQEntry.Get(Mgt.GetManagementJobQueueId()), 'Management entry should exist after restart');
        Assert.AreNotEqual(JQEntryBefore.SystemId, JQEntry.SystemId, 'SystemId should change when the entry is rescheduled');
        Assert.AreNotEqual(JQEntry.Status::Error, JQEntry.Status, 'Status should no longer be Error');

        CleanupManagementJQEntry();
    end;

    [Test]
    procedure RestartIfNeededExpectedCountIgnoredWhenRunning()
    var
        TempArgument: Record "Message Argument ori" temporary;
        JQEntry: Record "Job Queue Entry";
        JQEntryBefore: Record "Job Queue Entry";
        Handler: Codeunit "Status Msg Handler ori";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] Issue #257 AC02: the type writes and never posts, so any expectedCount is accepted and ignored
        // [GIVEN] a running orchestrator and expectedCount 999
        CleanupManagementJQEntry();
        JQEntry.Init();
        JQEntry.Status := JQEntry.Status::Ready;
        InsertManagementJQEntry(JQEntry);
        JQEntryBefore := JQEntry;
        CreateArgument(TempArgument, '{"expectedCount":999}');

        // [WHEN] RestartIfNeeded runs
        BindSubscription(LibraryOrchestrator);
        Handler.ExecuteRestartIfNeeded(TempArgument);
        UnbindSubscription(LibraryOrchestrator);

        // [THEN] it succeeds as the no-op it would be without expectedCount
        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('status', Token);
        Assert.AreEqual('Success', Token.AsValue().AsText(), 'Status should be Success');
        ResponseJson.Get('restarted', Token);
        Assert.IsFalse(Token.AsValue().AsBoolean(), 'Should not have restarted');
        AssertManagementJQEntryUnchanged(JQEntryBefore);
        CleanupManagementJQEntry();
    end;

    [Test]
    procedure RestartIfNeededExpectedCountIgnoredWhenRestartNeeded()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Status Msg Handler ori";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] Issue #257 AC02 edge: expectedCount 0 no longer blocks a needed restart
        CleanupManagementJQEntry();
        CreateArgument(TempArgument, '{"expectedCount":0}');

        BindSubscription(LibraryOrchestrator);
        Handler.ExecuteRestartIfNeeded(TempArgument);
        UnbindSubscription(LibraryOrchestrator);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('restarted', Token);
        Assert.IsTrue(Token.AsValue().AsBoolean(), 'Should have restarted');
        CleanupManagementJQEntry();
    end;

    [Test]
    procedure RestartExpectedCountIgnoredThroughDispatcherWithConfirmationRequired()
    var
        TempArgument: Record "Message Argument ori" temporary;
        DispatchHelper: Codeunit "Orch Dispatch Helper ori";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        PreviousRequired: Boolean;
        ResponseText: Text;
    begin
        // [SCENARIO] Issue #257 AC02: Orchestrator.Status.Restart with a wrong expectedCount, through Foundation's dispatcher,
        // while Require Confirmation for Irreversible Messages is on: accepted, ignored, no ConfirmationRequired/Mismatch
        CleanupManagementJQEntry();
        PreviousRequired := SetConfirmationRequired(true);
        CreateArgument(TempArgument, '{"expectedCount":5}');

        BindSubscription(LibraryOrchestrator);
        DispatchHelper.ExecuteOnce("Message Type ori"::"Orchestrator.Status.Restart", TempArgument);
        UnbindSubscription(LibraryOrchestrator);
        SetConfirmationRequired(PreviousRequired);
        TempArgument.GetResponseJson().WriteTo(ResponseText);

        Assert.IsFalse(ResponseText.Contains('ConfirmationRequired'), 'No confirmation is asked: ' + ResponseText);
        Assert.IsFalse(ResponseText.Contains('ConfirmationMismatch'), 'The count is not checked: ' + ResponseText);
        Assert.IsFalse(ResponseText.Contains('UnknownParameter'), 'expectedCount stays a declared key: ' + ResponseText);
        Assert.IsTrue(ResponseText.Contains('"status":"Success"'), 'The restart runs: ' + ResponseText);
        CleanupManagementJQEntry();
    end;

    [Test]
    procedure RestartIfNeededPreviewMarkerInPlaybookRunsOnce()
    var
        JQEntry: Record "Job Queue Entry";
        JQEntryBefore: Record "Job Queue Entry";
        Step: Record "Playbook Step ori";
        StepLog: Record "Playbook Step Log ori";
        Lib: Codeunit "Playbook Test Library ori";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        InstanceId: Guid;
        PreviousRequired: Boolean;
    begin
        // [SCENARIO] Issue #257 AC02: "expectedCount": "@preview" with a Max Count on a former irreversible type does not fail;
        // the type asks for no confirmation, so the single call is the run
        // [GIVEN] a running orchestrator, confirmation required, and a playbook step RestartIfNeeded with @preview and Max Count 1
        CleanupManagementJQEntry();
        JQEntry.Init();
        JQEntry.Status := JQEntry.Status::Ready;
        InsertManagementJQEntry(JQEntry);
        JQEntryBefore := JQEntry;
        PreviousRequired := SetConfirmationRequired(true);
        Lib.Cleanup(PreviewPlaybookTok);
        Lib.CreatePlaybook(PreviewPlaybookTok);
        Lib.AddStep(PreviewPlaybookTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Orchestrator.Status.RestartIfNeeded", '{"expectedCount":"@preview"}', 0, '', 0);
        Step.Get(PreviewPlaybookTok, 10);
        Step."Max Count" := 1;
        Step.Modify(true);

        // [WHEN] the playbook runs
        BindSubscription(LibraryOrchestrator);
        Lib.RunPlaybook(PreviewPlaybookTok, InstanceId);
        UnbindSubscription(LibraryOrchestrator);
        SetConfirmationRequired(PreviousRequired);

        // [THEN] the step completes once and the log says the type asked for no confirmation
        StepLog.Get(InstanceId, 10, 0);
        Assert.AreEqual(StepLog.Status::Completed, StepLog.Status, 'The @preview step completes: ' + StepLog."Error Text");
        Assert.IsTrue(StepLog."Confirmation Note".Contains('ran once'), StepLog."Confirmation Note");
        AssertManagementJQEntryUnchanged(JQEntryBefore);
        Lib.Cleanup(PreviewPlaybookTok);
        CleanupManagementJQEntry();
    end;

    local procedure SetConfirmationRequired(Value: Boolean) Previous: Boolean
    var
        SetupRef: RecordRef;
        RequiredField: FieldRef;
    begin
        // Bifrost Setup field 36, Require Confirmation for Irreversible Messages (Foundation public table).
        SetupRef.Open(Database::"Setup ori");
        if not SetupRef.FindFirst() then begin
            SetupRef.Init();
            SetupRef.Insert();
        end;
        RequiredField := SetupRef.Field(36);
        Previous := RequiredField.Value();
        RequiredField.Value := Value;
        SetupRef.Modify();
    end;

    local procedure InsertManagementJQEntry(var JQEntry: Record "Job Queue Entry")
    var
        Mgt: Codeunit "Scheduler Mgt ori";
    begin
        JQEntry.ID := Mgt.GetManagementJobQueueId();
        JQEntry."Earliest Start Date/Time" := CreateDateTime(DMY2Date(15, 6, 2026), 093000T);
        JQEntry."Object Type to Run" := JQEntry."Object Type to Run"::Codeunit;
        JQEntry."Object ID to Run" := Codeunit::"Scheduler Mgt ori";
        if not JQEntry.Insert(false) then
            JQEntry.Modify(false);

        JQEntry.SetLoadFields(SystemId, Status, "Earliest Start Date/Time");
        JQEntry.Get(Mgt.GetManagementJobQueueId());
    end;

    local procedure AssertManagementJQEntryUnchanged(JQEntryBefore: Record "Job Queue Entry")
    var
        JQEntry: Record "Job Queue Entry";
        Mgt: Codeunit "Scheduler Mgt ori";
    begin
        JQEntry.SetLoadFields(SystemId, Status, "Earliest Start Date/Time");
        Assert.IsTrue(JQEntry.Get(Mgt.GetManagementJobQueueId()), 'Management entry should still exist');
        Assert.AreEqual(JQEntryBefore.SystemId, JQEntry.SystemId, 'SystemId should be unchanged');
        Assert.AreEqual(JQEntryBefore.Status, JQEntry.Status, 'Status should be unchanged');
        Assert.AreEqual(JQEntryBefore."Earliest Start Date/Time", JQEntry."Earliest Start Date/Time", 'Earliest Start Date/Time should be unchanged');
    end;

    local procedure CreateArgument(var TempArgument: Record "Message Argument ori" temporary; RequestJsonText: Text)
    var
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        RequestJson: JsonObject;
    begin
        // The handlers read the setup row; an earlier test or a fresh tenant may have none.
        LibraryOrchestrator.EnsureSchedulerSetup();
        TempArgument.Init();
        TempArgument.Insert();
        RequestJson.ReadFrom(RequestJsonText);
        TempArgument.SetRequestJson(RequestJson);
    end;

    local procedure CleanupManagementJQEntry()
    var
        JQEntry: Record "Job Queue Entry";
        Mgt: Codeunit "Scheduler Mgt ori";
    begin
        if JQEntry.Get(Mgt.GetManagementJobQueueId()) then begin
            JQEntry.Status := JQEntry.Status::"On Hold";
            JQEntry.Modify(false);
            JQEntry.Delete(false);
        end;
    end;

    local procedure GetJsonInt(Obj: JsonObject; KeyName: Text): Integer
    var
        Token: JsonToken;
    begin
        Obj.Get(KeyName, Token);
        exit(Token.AsValue().AsInteger());
    end;
}
