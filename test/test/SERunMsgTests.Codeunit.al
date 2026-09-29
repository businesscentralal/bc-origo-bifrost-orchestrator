namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.Threading;

codeunit 96427 "SE Run Msg Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        ConfirmWasShown: Boolean;
        MessageWasShown: Boolean;
        ShownMessage: Text;

    [Test]
    procedure ExecuteRunDispatchesCodeunitEntryHeadlessly()
    var
        Entry: Record "Scheduled Entry ori";
        LogEntry: Record "Job Queue Log Entry";
        TempJobQueueEntry: Record "Job Queue Entry" temporary;
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "SE Msg Handler ori";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] AC-1/AC-2 Entry.Run dispatches a codeunit entry with no confirm and reports Success
        CreateCodeunitEntry(Entry, Codeunit::"Ok Sample");
        CreateArgument(TempArgument, '{"id": "' + Format(Entry.SystemId, 0, 4) + '"}');

        LibraryOrchestrator.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryOrchestrator);
        Handler.ExecuteRun(TempArgument);
        UnbindSubscription(LibraryOrchestrator);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('status', Token);
        Assert.AreEqual('Success', Token.AsValue().AsText(), 'Status should be Success');
        ResponseJson.Get('message', Token);
        Assert.AreEqual('Job queue entry executed.', Token.AsValue().AsText(), 'Message should report execution');

        LibraryOrchestrator.GetCollectedJobQueueEntries(TempJobQueueEntry);
        TempJobQueueEntry.SetRange("Object Type to Run", TempJobQueueEntry."Object Type to Run"::Codeunit);
        TempJobQueueEntry.SetRange("Object ID to Run", Codeunit::"Ok Sample");
        Assert.IsTrue(TempJobQueueEntry.FindFirst(), 'A temporary job queue entry should be dispatched');

        LogEntry.SetRange(ID, TempJobQueueEntry.ID);
        Assert.IsTrue(LogEntry.FindFirst(), 'A job queue log entry should be created');
        Assert.AreEqual(LogEntry.Status::Success, LogEntry.Status, 'Log status should be Success');

        CleanupEntry(Entry, TempJobQueueEntry.ID);
    end;

    [Test]
    procedure ExecuteRunReturnsErrorWhenJobFails()
    var
        Entry: Record "Scheduled Entry ori";
        TempJobQueueEntry: Record "Job Queue Entry" temporary;
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "SE Msg Handler ori";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        ResponseJson: JsonObject;
        Token: JsonToken;
        JobQueueEntryId: Guid;
    begin
        // [SCENARIO] AC-2 A job that errors returns Error and the job's own error text
        CreateCodeunitEntry(Entry, Codeunit::"Fail Sample");
        CreateArgument(TempArgument, '{"id": "' + Format(Entry.SystemId, 0, 4) + '"}');

        LibraryOrchestrator.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryOrchestrator);
        Handler.ExecuteRun(TempArgument);
        UnbindSubscription(LibraryOrchestrator);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('status', Token);
        Assert.AreEqual('Error', Token.AsValue().AsText(), 'Status should be Error');
        ResponseJson.Get('message', Token);
        Assert.AreEqual('Deliberate failure from the test codeunit.', Token.AsValue().AsText(), 'Message should be the job error');

        LibraryOrchestrator.GetCollectedJobQueueEntries(TempJobQueueEntry);
        TempJobQueueEntry.SetRange("Object ID to Run", Codeunit::"Fail Sample");
        if TempJobQueueEntry.FindFirst() then
            JobQueueEntryId := TempJobQueueEntry.ID;
        CleanupEntry(Entry, JobQueueEntryId);
    end;

    [Test]
    procedure ExecuteRunReturnsErrorWhenDispatchFails()
    var
        Entry: Record "Scheduled Entry ori";
        TempJobQueueEntry: Record "Job Queue Entry" temporary;
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "SE Msg Handler ori";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        FailSample: Codeunit "Fail Sample";
        ResponseJson: JsonObject;
        Token: JsonToken;
        JobQueueEntryId: Guid;
    begin
        // [SCENARIO] AC-3 Entry.Run returns Error when the dispatcher and the error handler both fail
        CreateCodeunitEntry(Entry, Codeunit::"Fail Sample");
        CreateArgument(TempArgument, '{"id": "' + Format(Entry.SystemId, 0, 4) + '"}');

        FailSample.SetFailErrorHandler(true);
        BindSubscription(FailSample);
        LibraryOrchestrator.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryOrchestrator);
        Handler.ExecuteRun(TempArgument);
        UnbindSubscription(LibraryOrchestrator);
        UnbindSubscription(FailSample);
        FailSample.SetFailErrorHandler(false);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('status', Token);
        Assert.AreEqual('Error', Token.AsValue().AsText(), 'Status should be Error');
        ResponseJson.Get('message', Token);
        Assert.AreEqual('Deliberate failure from the test codeunit.', Token.AsValue().AsText(), 'Message should be the job error');

        LibraryOrchestrator.GetCollectedJobQueueEntries(TempJobQueueEntry);
        TempJobQueueEntry.SetRange("Object ID to Run", Codeunit::"Fail Sample");
        if TempJobQueueEntry.FindFirst() then
            JobQueueEntryId := TempJobQueueEntry.ID;
        CleanupEntry(Entry, JobQueueEntryId);
    end;

    [Test]
    procedure ExecuteRunUsesPlaybookRecordIdNotEntryRecordId()
    var
        Playbook: Record "Playbook ori";
        Entry: Record "Scheduled Entry ori";
        RecurringTemplate: Record "Recurring Template ori";
        Instance: Record "Playbook Instance ori";
        ResolvedPlaybook: Record "Playbook ori";
        TempJobQueueEntry: Record "Job Queue Entry" temporary;
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "SE Msg Handler ori";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        RecRef: RecordRef;
        ResponseJson: JsonObject;
        Token: JsonToken;
        EntrySystemId: Guid;
        EntryPkId: Guid;
    begin
        // [SCENARIO] AC-4 Entry.Run passes the playbook Record ID, not the scheduled entry Record ID
        CreatePlaybook(Playbook, 'SE-RUN-PB');
        CreateRecurringTemplate(RecurringTemplate, 'SE-RUN-TPL');
        EntrySystemId := Playbook.CreateOrchestratorEntry(
            RecurringTemplate.Code,
            "Notif. Type ori"::None, '', '', false,
            "Retry Policy ori"::Always, EntryPkId);
        Entry.Get(EntryPkId);

        CreateArgument(TempArgument, '{"id": "' + Format(EntrySystemId, 0, 4) + '"}');
        LibraryOrchestrator.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryOrchestrator);
        Handler.ExecuteRun(TempArgument);
        UnbindSubscription(LibraryOrchestrator);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('status', Token);
        Assert.AreEqual('Success', Token.AsValue().AsText(), 'Playbook entry should run');

        LibraryOrchestrator.GetCollectedJobQueueEntries(TempJobQueueEntry);
        TempJobQueueEntry.SetRange("Object ID to Run", Codeunit::"Playbook JQ Dispatcher ori");
        Assert.IsTrue(TempJobQueueEntry.FindFirst(), 'A temporary job queue entry should be built');
        Assert.AreEqual(Database::"Playbook ori", TempJobQueueEntry."Record ID to Process".TableNo(), 'Record ID to Process should be the playbook table');
        Assert.AreNotEqual(Entry.RecordId().TableNo(), TempJobQueueEntry."Record ID to Process".TableNo(), 'Record ID to Process should not be the scheduled entry');
        RecRef.Get(TempJobQueueEntry."Record ID to Process");
        RecRef.SetTable(ResolvedPlaybook);
        Assert.AreEqual(Playbook.Code, ResolvedPlaybook.Code, 'Record ID to Process should be this playbook');

        Instance.SetRange("Playbook Code", Playbook.Code);
        Assert.IsFalse(Instance.IsEmpty(), 'A playbook instance should be created for the playbook');

        CleanupPlaybook(Playbook.Code, TempJobQueueEntry.ID);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    procedure RunJobQueueEntryOnceStillConfirmsAndMessages()
    var
        Entry: Record "Scheduled Entry ori";
        LogEntry: Record "Job Queue Log Entry";
        TempJobQueueEntry: Record "Job Queue Entry" temporary;
        Mgt: Codeunit "Scheduler Mgt ori";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
    begin
        // [SCENARIO] AC-5 Run Now still confirms, runs, and shows the completion message
        ConfirmWasShown := false;
        MessageWasShown := false;
        ShownMessage := '';
        CreateCodeunitEntry(Entry, Codeunit::"Ok Sample");

        LibraryOrchestrator.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryOrchestrator);
        Mgt.RunJobQueueEntryOnce(Entry);
        UnbindSubscription(LibraryOrchestrator);

        Assert.IsTrue(ConfirmWasShown, 'Run Now should still ask for confirmation');
        Assert.IsTrue(MessageWasShown, 'Run Now should still show the completion message');
        Assert.IsTrue(StrPos(ShownMessage, 'Job finished executing') > 0, 'Completion message should be shown');

        LibraryOrchestrator.GetCollectedJobQueueEntries(TempJobQueueEntry);
        TempJobQueueEntry.SetRange("Object ID to Run", Codeunit::"Ok Sample");
        Assert.IsTrue(TempJobQueueEntry.FindFirst(), 'Run Now should still dispatch the entry');
        LogEntry.SetRange(ID, TempJobQueueEntry.ID);
        Assert.IsTrue(LogEntry.FindFirst(), 'Run Now should still write a job queue log entry');

        CleanupEntry(Entry, TempJobQueueEntry.ID);
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        ConfirmWasShown := true;
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        MessageWasShown := true;
        ShownMessage := Message;
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

    local procedure CreateCodeunitEntry(var Entry: Record "Scheduled Entry ori"; ObjectId: Integer)
    begin
        Entry.Init();
        Entry.ID := CreateGuid();
        Entry."Object Type to Run" := Entry."Object Type to Run"::Codeunit;
        Entry."Object ID to Run" := ObjectId;
        Entry.Description := 'SE Run Msg test';
        Entry.Blocked := false;
        Entry."Earliest Start Date/Time" := CurrentDateTime();
        Entry.Insert(true);
    end;

    local procedure CreatePlaybook(var Playbook: Record "Playbook ori"; PlaybookCode: Code[20])
    begin
        if Playbook.Get(PlaybookCode) then
            Playbook.Delete(true);
        Playbook.Init();
        Playbook.Code := PlaybookCode;
        Playbook.Description := 'SE Run test playbook';
        Playbook.Insert(true);
    end;

    local procedure CreateRecurringTemplate(var RecurringTemplate: Record "Recurring Template ori"; TemplateCode: Code[20])
    begin
        if RecurringTemplate.Get(TemplateCode) then
            RecurringTemplate.Delete(true);
        RecurringTemplate.Init();
        RecurringTemplate.Code := TemplateCode;
        RecurringTemplate.Description := 'SE Run test template';
        RecurringTemplate."Run on Mondays" := true;
        RecurringTemplate."No. of Minutes between Runs" := 60;
        RecurringTemplate.Insert(true);
    end;

    local procedure CleanupEntry(var Entry: Record "Scheduled Entry ori"; JobQueueEntryId: Guid)
    var
        JobQueueEntry: Record "Job Queue Entry";
        LogEntry: Record "Job Queue Log Entry";
    begin
        LogEntry.SetRange(ID, JobQueueEntryId);
        if not LogEntry.IsEmpty() then
            LogEntry.DeleteAll(false);
        if JobQueueEntry.Get(JobQueueEntryId) then begin
            JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
            JobQueueEntry.Modify(false);
            JobQueueEntry.Delete(false);
        end;
        if Entry.Get(Entry.ID) then
            Entry.Delete(true);
    end;

    local procedure CleanupPlaybook(PlaybookCode: Code[20]; JobQueueEntryId: Guid)
    var
        Playbook: Record "Playbook ori";
        Entry: Record "Scheduled Entry ori";
        Instance: Record "Playbook Instance ori";
        RecurringTemplate: Record "Recurring Template ori";
    begin
        Instance.SetRange("Playbook Code", PlaybookCode);
        if not Instance.IsEmpty() then
            Instance.DeleteAll(true);
        if Playbook.Get(PlaybookCode) then begin
            if not IsNullGuid(Playbook."Orchestrator Entry ID") then
                if Entry.Get(Playbook."Orchestrator Entry ID") then
                    CleanupEntry(Entry, JobQueueEntryId);
            Playbook.Delete(true);
        end;
        if RecurringTemplate.Get('SE-RUN-TPL') then
            RecurringTemplate.Delete(true);
    end;
}
