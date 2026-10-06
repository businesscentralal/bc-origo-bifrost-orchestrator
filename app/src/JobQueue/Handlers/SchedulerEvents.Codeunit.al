/// <summary>
/// Event subscriber codeunit handling Job Queue Entry lifecycle events for the orchestrator.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using System.Environment;
using System.Environment.Configuration;
using System.Security.AccessControl;
using System.Threading;

codeunit 10035539 "Scheduler Events ori"
{
    Permissions = tabledata "Scheduled Entry ori" = RMID;

    local procedure Log(EventId: Text; Message: Text; Verbosity: Verbosity; CustomDimensions: Dictionary of [Text, Text])
    begin
        Session.LogMessage(EventId, Message, Verbosity, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue - Enqueue", 'OnAfterEnqueueJobQueueEntry', '', false, false)]
    local procedure JobQueueEnqueueOnAfterEnqueueJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry")
    var
        "Scheduled Entry ori": Record "Scheduled Entry ori";
        ScheduledTask: Record "Scheduled Task";
        User: Record User;
        UserPersonalization: Record "User Personalization";
    begin
        if not JobQueueEntry."Recurring Job" then exit;

        "Scheduled Entry ori".SetLoadFields("Job Queue User ID");
        if not "Scheduled Entry ori".Get(JobQueueEntry.ID) then
            exit;
        if "Scheduled Entry ori"."Job Queue User ID" = '' then
            exit;

        JobQueueEntry."User ID" := "Scheduled Entry ori"."Job Queue User ID";
        if ScheduledTask.Get(JobQueueEntry."System Task ID") then begin
            User.SetLoadFields("User Security ID", "User Name");
            User.SetRange("User Name", "Scheduled Entry ori"."Job Queue User ID");
            if User.FindFirst() then begin
                ScheduledTask."User ID" := User."User Security ID";
                ScheduledTask."User Name" := User."User Name";

                UserPersonalization.SetLoadFields("Locale ID");
                if UserPersonalization.Get(User."User Security ID") then
                    if UserPersonalization."Locale ID" <> 0 then
                        ScheduledTask."User Format ID" := UserPersonalization."Locale ID";

                ScheduledTask.Modify();
            end;
        end;

        JobQueueEntry.Modify();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue Start Codeunit", 'OnAfterRun', '', false, false)]
    local procedure OnAfterRun(var JobQueueEntry: Record "Job Queue Entry");
    var
        "Scheduled Entry ori": Record "Scheduled Entry ori";
        CustomDimensions: Dictionary of [Text, Text];
        NotificationInterface: Interface "Notification ori";
        JobQueueEntryExecutedTok: Label 'Job Queue Entry Executed', Locked = true;
    begin
        if not "Scheduled Entry ori".Get(JobQueueEntry.ID) then
            exit;

        NotificationInterface := "Scheduled Entry ori"."Notification Type";
        NotificationInterface.SendExecutionCompletedNotification("Scheduled Entry ori", JobQueueEntry);
        if not "Scheduled Entry ori"."Emit Telemetry" then
            exit;
        "Scheduled Entry ori".CopyToCustomDimensions(CustomDimensions);
        Log('O4NJQS-0006', JobQueueEntryExecutedTok, Verbosity::Normal, CustomDimensions)
    end;
}
