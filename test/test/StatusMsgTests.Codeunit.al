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
        RequestJson: JsonObject;
    begin
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
