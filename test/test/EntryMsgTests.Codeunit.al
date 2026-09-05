namespace Origo.Bifrost.Nornir.Test;

using Origo.Bifrost;
using Origo.Bifrost.Nornir;
using System.Threading;

codeunit 96320 "Entry Msg Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure RestartSetsEntryToReady()
    var
        TempArgument: Record "Message Argument ori" temporary;
        JQEntry: Record "Job Queue Entry";
        Handler: Codeunit "Entry Msg Handler ori";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] Restart sets an Error JQ entry to Ready
        CreateTestJQEntry(JQEntry, JQEntry.Status::Error);

        CreateArgument(TempArgument, '{"id": "' + Format(JQEntry.SystemId, 0, 4) + '"}');

        LibraryOrchestrator.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryOrchestrator);
        Handler.ExecuteRestart(TempArgument);
        UnbindSubscription(LibraryOrchestrator);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('status', Token);
        Assert.AreEqual('Success', Token.AsValue().AsText(), 'Status should be Success');
        Assert.IsTrue(ResponseJson.Contains('message'), 'Missing message');

        JQEntry.Get(JQEntry.ID);
        Assert.AreEqual(JQEntry.Status::Ready, JQEntry.Status, 'Entry should be Ready');

        CleanupJQEntry(JQEntry);
    end;

    [Test]
    procedure RestartSetsOnHoldEntryToReady()
    var
        TempArgument: Record "Message Argument ori" temporary;
        JQEntry: Record "Job Queue Entry";
        Handler: Codeunit "Entry Msg Handler ori";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
    begin
        // [SCENARIO] Restart sets an On Hold JQ entry to Ready
        CreateTestJQEntry(JQEntry, JQEntry.Status::"On Hold");

        CreateArgument(TempArgument, '{"id": "' + Format(JQEntry.SystemId, 0, 4) + '"}');

        LibraryOrchestrator.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryOrchestrator);
        Handler.ExecuteRestart(TempArgument);
        UnbindSubscription(LibraryOrchestrator);

        JQEntry.Get(JQEntry.ID);
        Assert.AreEqual(JQEntry.Status::Ready, JQEntry.Status, 'Entry should be Ready');

        CleanupJQEntry(JQEntry);
    end;

    [Test]
    procedure RestartErrorsForMissingId()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Entry Msg Handler ori";
    begin
        // [SCENARIO] Restart errors when id is missing from request
        CreateArgument(TempArgument, '{}');

        asserterror Handler.ExecuteRestart(TempArgument);
        Assert.ExpectedError('id');
    end;

    [Test]
    procedure RestartIfNeededRestartsErrorEntry()
    var
        TempArgument: Record "Message Argument ori" temporary;
        JQEntry: Record "Job Queue Entry";
        Handler: Codeunit "Entry Msg Handler ori";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] RestartIfNeeded restarts a JQ entry in Error state
        CreateTestJQEntry(JQEntry, JQEntry.Status::Error);

        CreateArgument(TempArgument, '{"id": "' + Format(JQEntry.SystemId, 0, 4) + '"}');

        LibraryOrchestrator.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryOrchestrator);
        Handler.ExecuteRestartIfNeeded(TempArgument);
        UnbindSubscription(LibraryOrchestrator);

        JQEntry.Get(JQEntry.ID);
        Assert.AreEqual(JQEntry.Status::Ready, JQEntry.Status, 'Error entry should be restarted');

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('message', Token);
        Assert.AreNotEqual('No restart needed.', Token.AsValue().AsText(), 'Should have restarted');

        CleanupJQEntry(JQEntry);
    end;

    [Test]
    procedure RestartIfNeededSkipsReadyEntry()
    var
        TempArgument: Record "Message Argument ori" temporary;
        JQEntry: Record "Job Queue Entry";
        Handler: Codeunit "Entry Msg Handler ori";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] RestartIfNeeded is a no-op for a Ready JQ entry
        CreateTestJQEntry(JQEntry, JQEntry.Status::Ready);

        CreateArgument(TempArgument, '{"id": "' + Format(JQEntry.SystemId, 0, 4) + '"}');

        LibraryOrchestrator.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryOrchestrator);
        Handler.ExecuteRestartIfNeeded(TempArgument);
        UnbindSubscription(LibraryOrchestrator);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('message', Token);
        Assert.AreEqual('No restart needed.', Token.AsValue().AsText(), 'Should not restart a Ready entry');

        CleanupJQEntry(JQEntry);
    end;

    [Test]
    procedure RestartIfNeededRestartsOnHoldEntry()
    var
        TempArgument: Record "Message Argument ori" temporary;
        JQEntry: Record "Job Queue Entry";
        Handler: Codeunit "Entry Msg Handler ori";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
    begin
        // [SCENARIO] RestartIfNeeded restarts a JQ entry in On Hold state
        CreateTestJQEntry(JQEntry, JQEntry.Status::"On Hold");

        CreateArgument(TempArgument, '{"id": "' + Format(JQEntry.SystemId, 0, 4) + '"}');

        LibraryOrchestrator.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryOrchestrator);
        Handler.ExecuteRestartIfNeeded(TempArgument);
        UnbindSubscription(LibraryOrchestrator);

        JQEntry.Get(JQEntry.ID);
        Assert.AreEqual(JQEntry.Status::Ready, JQEntry.Status, 'On Hold entry should be restarted');

        CleanupJQEntry(JQEntry);
    end;

    [Test]
    procedure RestartResponseIncludesEntryDetails()
    var
        TempArgument: Record "Message Argument ori" temporary;
        JQEntry: Record "Job Queue Entry";
        Handler: Codeunit "Entry Msg Handler ori";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        ResponseJson: JsonObject;
    begin
        // [SCENARIO] Response includes id, entryStatus, description, and message
        CreateTestJQEntry(JQEntry, JQEntry.Status::Error);

        CreateArgument(TempArgument, '{"id": "' + Format(JQEntry.SystemId, 0, 4) + '"}');

        LibraryOrchestrator.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryOrchestrator);
        Handler.ExecuteRestart(TempArgument);
        UnbindSubscription(LibraryOrchestrator);

        ResponseJson := TempArgument.GetResponseJson();
        Assert.IsTrue(ResponseJson.Contains('id'), 'Missing id');
        Assert.IsTrue(ResponseJson.Contains('entryStatus'), 'Missing entryStatus');
        Assert.IsTrue(ResponseJson.Contains('description'), 'Missing description');
        Assert.IsTrue(ResponseJson.Contains('message'), 'Missing message');

        CleanupJQEntry(JQEntry);
    end;

    [Test]
    procedure RestartAcceptsIdInSubject()
    var
        TempArgument: Record "Message Argument ori" temporary;
        JQEntry: Record "Job Queue Entry";
        Handler: Codeunit "Entry Msg Handler ori";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        RequestJson: JsonObject;
    begin
        // [SCENARIO] Restart accepts the entry ID via Subject when not in JSON data
        CreateTestJQEntry(JQEntry, JQEntry.Status::Error);

        TempArgument.Init();
        TempArgument.Subject := Format(JQEntry.SystemId, 0, 4);
        TempArgument.Insert();
        RequestJson.ReadFrom('{}');
        TempArgument.SetRequestJson(RequestJson);

        LibraryOrchestrator.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryOrchestrator);
        Handler.ExecuteRestart(TempArgument);
        UnbindSubscription(LibraryOrchestrator);

        JQEntry.Get(JQEntry.ID);
        Assert.AreEqual(JQEntry.Status::Ready, JQEntry.Status, 'Entry should be restarted via Subject');

        CleanupJQEntry(JQEntry);
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

    // Job Queue Entry."Status" is an Option, not an Enum - there is no "Job Queue Entry
    // Status" type to declare. Callers pass JQEntry.Status::Error and friends, which
    // convert to their ordinal.
    local procedure CreateTestJQEntry(var JQEntry: Record "Job Queue Entry"; InitialStatus: Integer)
    var
        LibraryOrchestrator: Codeunit "Library Orchestrator";
    begin
        BindSubscription(LibraryOrchestrator);
        JQEntry.Init();
        JQEntry.ID := CreateGuid();
        JQEntry.Status := JQEntry.Status::"On Hold";
        JQEntry."Object Type to Run" := JQEntry."Object Type to Run"::Codeunit;
        JQEntry."Object ID to Run" := Codeunit::"Scheduler Mgt ori";
        JQEntry.Description := 'Test entry for Bifrost Entry Msg Tests';
        JQEntry.Insert(true);
        UnbindSubscription(LibraryOrchestrator);

        if InitialStatus <> JQEntry.Status::"On Hold" then begin
            JQEntry.Status := InitialStatus;
            JQEntry.Modify(false);
        end;
    end;

    local procedure CleanupJQEntry(var JQEntry: Record "Job Queue Entry")
    begin
        if JQEntry.Get(JQEntry.ID) then begin
            JQEntry.Status := JQEntry.Status::"On Hold";
            JQEntry.Modify(false);
            JQEntry.Delete(false);
        end;
    end;
}
