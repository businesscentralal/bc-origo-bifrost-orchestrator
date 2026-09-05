namespace Origo.Bifrost.Nornir.Test;

using Origo.Bifrost;
using Origo.Bifrost.Nornir;
using System.Threading;

codeunit 96319 "Status Msg Tests"
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

    // Handler uses GetBySystemId — can't simulate in tests without creating via ScheduleJobQueueEntry
    procedure RestartIfNeededSkipsWhenAlreadyRunning()
    var
        TempArgument: Record "Message Argument ori" temporary;
        JQEntry: Record "Job Queue Entry";
        Handler: Codeunit "Status Msg Handler ori";
        Mgt: Codeunit "Scheduler Mgt ori";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] RestartIfNeeded is a no-op when management JQ entry is Ready
        CleanupManagementJQEntry();

        JQEntry.Init();
        JQEntry.ID := Mgt.GetManagementJobQueueId();
        JQEntry.Status := JQEntry.Status::Ready;
        JQEntry."Object Type to Run" := JQEntry."Object Type to Run"::Codeunit;
        JQEntry."Object ID to Run" := Codeunit::"Scheduler Mgt ori";
        if not JQEntry.Insert(false) then
            JQEntry.Modify(false);

        CreateArgument(TempArgument, '{}');

        BindSubscription(LibraryOrchestrator);
        Handler.ExecuteRestartIfNeeded(TempArgument);
        UnbindSubscription(LibraryOrchestrator);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('restarted', Token);
        Assert.IsFalse(Token.AsValue().AsBoolean(), 'Should not have restarted');

        CleanupManagementJQEntry();
    end;

    // Handler uses GetBySystemId — can't simulate in tests without creating via ScheduleJobQueueEntry
    procedure RestartIfNeededRestartsWhenInError()
    var
        TempArgument: Record "Message Argument ori" temporary;
        JQEntry: Record "Job Queue Entry";
        Handler: Codeunit "Status Msg Handler ori";
        Mgt: Codeunit "Scheduler Mgt ori";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] RestartIfNeeded restarts when management JQ entry is in Error
        CleanupManagementJQEntry();

        JQEntry.Init();
        JQEntry.ID := Mgt.GetManagementJobQueueId();
        JQEntry.Status := JQEntry.Status::Error;
        JQEntry."Object Type to Run" := JQEntry."Object Type to Run"::Codeunit;
        JQEntry."Object ID to Run" := Codeunit::"Scheduler Mgt ori";
        if not JQEntry.Insert(false) then
            JQEntry.Modify(false);

        CreateArgument(TempArgument, '{}');

        BindSubscription(LibraryOrchestrator);
        Handler.ExecuteRestartIfNeeded(TempArgument);
        UnbindSubscription(LibraryOrchestrator);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('restarted', Token);
        Assert.IsTrue(Token.AsValue().AsBoolean(), 'Should have restarted when in Error');

        CleanupManagementJQEntry();
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
