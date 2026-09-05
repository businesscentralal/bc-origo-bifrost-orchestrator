namespace Origo.Bifrost.Nornir.Test;

using Microsoft.Foundation.BatchProcessing;
using Origo.Bifrost.Nornir;
using System.Threading;

/// <summary>
/// Test library codeunit that intercepts Job Queue Entry creation and execution for testing.
/// </summary>
codeunit 96313 "Library Orchestrator"
{
    EventSubscriberInstance = Manual;
    Access = Internal;

    trigger OnRun()
    begin
    end;

    var
        TempJobQueueEntry: Record "Job Queue Entry" temporary;
        DoNotHandleCodeunitJobQueueEnqueueEvent: Boolean;
        DoNotHandleTableJobQueueEntryEvent: Boolean;
        DoNotHandleSendNotificationEvent: Boolean;
        TrackingJobQueueEntryID: Guid;
        MultipleTrackJobQueueEntryErr: Label 'Can''t track multiple job queue entries';
        DoNotSkipProcessBatchInBackground: Boolean;

    Internal procedure SetDoNotHandleCodeunitJobQueueEnqueueEvent(NewDoNotHandleCodeunitJobQueueEnqueueEvent: Boolean)
    begin
        DoNotHandleCodeunitJobQueueEnqueueEvent := NewDoNotHandleCodeunitJobQueueEnqueueEvent;
    end;

    Internal procedure SetDoNotHandleTableJobQueueEntryEvent(NewDoNotHandleTableJobQueueEntryEvent: Boolean)
    begin
        DoNotHandleTableJobQueueEntryEvent := NewDoNotHandleTableJobQueueEntryEvent;
    end;

    Internal procedure SetDoNotHandleSendNotificationEvent(NewDoNotHandleSendNotificationEvent: Boolean)
    begin
        DoNotHandleSendNotificationEvent := NewDoNotHandleSendNotificationEvent;
    end;

    Internal procedure SetTrackingJobQueueEntry(JobQueueEntry: Record "Job Queue Entry")
    begin
        if not IsNullGuid(TrackingJobQueueEntryID) then
            Error(MultipleTrackJobQueueEntryErr);

        TrackingJobQueueEntryID := JobQueueEntry.ID;
    end;

    Internal procedure GetCollectedJobQueueEntries(var TempJobQueueEntryDst: Record "Job Queue Entry" temporary)
    begin
        TempJobQueueEntryDst.Copy(TempJobQueueEntry, true);
    end;

    Internal procedure FindAndRunJobQueueEntryByRecordId(RecordIdToProcess: RecordId)
    begin
        FindAndRunJobQueueEntryByRecordId(RecordIdToProcess, false);
    end;

    Internal procedure FindAndRunJobQueueEntryByRecordId(RecordIdToProcess: RecordId; WithErrorHandler: Boolean)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
#pragma warning disable AA0210
        JobQueueEntry.SetRange("Record ID to Process", RecordIdToProcess);
#pragma warning restore AA0210
        JobQueueEntry.FindSet();
        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry.Modify();
        if WithErrorHandler then begin
#pragma warning disable PTE0007
#pragma warning disable AA0248
#pragma warning disable AA0161
            asserterror RunJobQueueDispatcher(JobQueueEntry);
#pragma warning restore AA0161
#pragma warning restore AA0248
#pragma warning restore PTE0007
            RunJobQueueErrorHandler(JobQueueEntry);
        end
        else
            RunJobQueueDispatcher(JobQueueEntry);
    end;

    Internal procedure RunJobQueueDispatcher(var JobQueueEntry: Record "Job Queue Entry")
    begin
        Codeunit.Run(Codeunit::"Job Queue Dispatcher", JobQueueEntry);
    end;

    Internal procedure RunJobQueueErrorHandler(var JobQueueEntry: Record "Job Queue Entry")
    begin
        Codeunit.Run(Codeunit::"Job Queue Error Handler", JobQueueEntry);
    end;

    Internal procedure RunSendNotification(JobQueueEntry: Record "Job Queue Entry")
    begin
        Codeunit.Run(Codeunit::"Job Queue - Send Notification", JobQueueEntry);
    end;

    Internal procedure SetDoNotSkipProcessBatchInBackground(NewDoNotSkipProcessBatchInBackground: Boolean)
    begin
        DoNotSkipProcessBatchInBackground := NewDoNotSkipProcessBatchInBackground;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue - Enqueue", 'OnBeforeJobQueueScheduleTask', '', false, false)]
    local procedure HandleCodeunitJobQueueEnqueueEventOnBeforeJobQueueScheduleTask(var JobQueueEntry: Record "Job Queue Entry"; var DoNotScheduleTask: Boolean)
    begin
        if DoNotHandleCodeunitJobQueueEnqueueEvent then
            exit;

        DoNotScheduleTask := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnBeforeScheduleTask', '', false, false)]
    local procedure HandleTableJobQueueEntryEventOnBeforeJobQueueScheduleTask(var JobQueueEntry: Record "Job Queue Entry"; var TaskGUID: Guid)
    begin
        if DoNotHandleTableJobQueueEntryEvent then
            exit;

        TaskGUID := CreateGuid();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure CollectJobQueueEntryOnAfterInsertEvent(var Rec: Record "Job Queue Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;

        if not IsNullGuid(TrackingJobQueueEntryID) then
            exit;

        TempJobQueueEntry.TransferFields(Rec);
        TempJobQueueEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnAfterModifyEvent', '', false, false)]
    local procedure CollectJobQueueEntryOnAfterModifyEvent(var Rec: Record "Job Queue Entry"; var xRec: Record "Job Queue Entry"; RunTrigger: Boolean)
    var
        IsRecRegistered: Boolean;
    begin
        if Rec.IsTemporary then
            exit;

        if not IsNullGuid(TrackingJobQueueEntryID) then
            exit;

        IsRecRegistered := TempJobQueueEntry.Get(Rec.ID);
        TempJobQueueEntry.TransferFields(Rec);
        if IsRecRegistered then
            TempJobQueueEntry.Modify()
        else
            TempJobQueueEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure CollectTrackingJobQueueEntryOnAfterInsertEvent(var Rec: Record "Job Queue Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;

        if IsNullGuid(TrackingJobQueueEntryID) then
            exit;

        if Rec.ID <> TrackingJobQueueEntryID then
            exit;

        TempJobQueueEntry.TransferFields(Rec);
        TempJobQueueEntry.ID := CreateGuid();
        TempJobQueueEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnAfterModifyEvent', '', false, false)]
    local procedure CollectTrackingJobQueueEntryOnAfterModifyEvent(var Rec: Record "Job Queue Entry"; var xRec: Record "Job Queue Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;

        if IsNullGuid(TrackingJobQueueEntryID) then
            exit;

        if Rec.ID <> TrackingJobQueueEntryID then
            exit;

        TempJobQueueEntry.TransferFields(Rec);
        TempJobQueueEntry.ID := CreateGuid();
        TempJobQueueEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Batch Processing Mgt.", 'OnBeforeBatchShouldBeProcessedInBackground', '', false, false)]
    local procedure OnBeforeBatchShouldBeProcessedInBackgroundHandler(var IsProcessed: Boolean)
    begin
        IsProcessed := not DoNotSkipProcessBatchInBackground;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnBeforeTryRunJobQueueSendNotification', '', false, false)]
    local procedure OnBeforeTryRunJobQueueSendNotification(var JobQueueEntry: Record "Job Queue Entry"; var IsHandled: Boolean)
    begin
        if DoNotHandleSendNotificationEvent then
            exit;

        IsHandled := true;
        RunSendNotification(JobQueueEntry);
    end;
}
