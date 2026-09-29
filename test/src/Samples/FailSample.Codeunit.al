namespace Origo.Bifrost.Orchestrator.Test;

using System.Threading;

/// <summary>
/// Sample codeunit that fails when the job queue runs it, and can fail the job queue error handler.
/// </summary>
codeunit 96429 "Fail Sample"
{
    Access = Internal;
    TableNo = "Job Queue Entry";
    EventSubscriberInstance = Manual;

    var
        FailErrorHandler: Boolean;
        ModifyCount: Integer;
        DeliberateErr: Label 'Deliberate failure from the test codeunit.', Locked = true;
        ErrorHandlerFailedErr: Label 'Deliberate failure saving the job queue error.', Locked = true;

    trigger OnRun()
    begin
        Error(DeliberateErr);
    end;

    procedure SetFailErrorHandler(NewFailErrorHandler: Boolean)
    begin
        FailErrorHandler := NewFailErrorHandler;
        ModifyCount := 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnBeforeModifyEvent', '', false, false)]
#pragma warning disable AA0137
    local procedure OnBeforeModifyJobQueueEntry(var Rec: Record "Job Queue Entry"; var xRec: Record "Job Queue Entry"; RunTrigger: Boolean)
#pragma warning restore AA0137
    begin
        if not FailErrorHandler then
            exit;
        if Rec."Object ID to Run" <> Codeunit::"Fail Sample" then
            exit;
        if Rec.Status <> Rec.Status::Error then
            exit;

        // First save of Status = Error is the error handler. Failing it makes Codeunit.Run of the
        // error handler return false after the failing codeunit already failed the dispatcher.
        ModifyCount += 1;
        if ModifyCount = 1 then
            Error(ErrorHandlerFailedErr);
    end;
}
