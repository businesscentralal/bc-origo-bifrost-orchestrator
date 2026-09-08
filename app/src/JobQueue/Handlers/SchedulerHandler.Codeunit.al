/// <summary>
/// Main handler codeunit for the Job Queue Orchestrator that processes and reschedules entries.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Microsoft.Utilities;
using System.Threading;

codeunit 10035535 "Scheduler Handler ori"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        if JobQueueGeneralSetup.Get() then
            ScheduleJobs(JobQueueGeneralSetup."Emit Telemetry");
    end;

    var
        ActivityLog: Record "Activity Log";
        JobQueueGeneralSetup: Record "Scheduler Setup ori";
        ContextTok: Label 'Job Queue Orchestrator', MaxLength = 30, Comment = 'is-IS=Vinnsluraðari';
        TaskScheduledMsg: Label 'Task Scheduled', Comment = 'is-IS=Verk tímasett';

    /// <summary>
    /// Schedules or restarts the Job Queue Entry for the given orchestrator entry.
    /// </summary>
    /// <param name="Scheduled Entry ori">The orchestrator entry to process.</param>
    internal procedure ScheduleTask("Scheduled Entry ori": Record "Scheduled Entry ori")
    var
        JobQueueEntry: Record "Job Queue Entry";
        ApiClient: Codeunit "Scheduler API Client ori";
        CustomDimensions: Dictionary of [Text, Text];
        NotificationInterface: Interface "Notification ori";
        RestartJobQueueEntryTok: Label 'Restart Job Queue Entry', Locked = true;
    begin
        "Scheduled Entry ori".TestField(ID);
        "Scheduled Entry ori".TestField("Object ID to Run");
        SendHartbeatViaInterface("Scheduled Entry ori", NotificationInterface);
        if JobQueueEntryFound("Scheduled Entry ori", JobQueueEntry) then begin
            "Scheduled Entry ori".CopyToCustomDimensions(CustomDimensions);
            "Scheduled Entry ori".CopyLastExecutionInformationToCustomDimensions(CustomDimensions);
            case JobQueueEntry.Status of
                JobQueueEntry.Status::Error:
                    begin
                        NotificationInterface.SendRestartNotification("Scheduled Entry ori", JobQueueEntry);
                        ActivityLog.LogActivity("Scheduled Entry ori", ActivityLog.Status::Failed, ContextTok, Format(JobQueueEntry.Status), JobQueueEntry."Error Message");
                        if not ShouldSkipRestartByPolicy("Scheduled Entry ori") then
                            RestartJobQueueEntryWithCounter("Scheduled Entry ori", JobQueueEntry, ApiClient)
                        else
                            LogRestartSuppressed("Scheduled Entry ori", CustomDimensions);
                        CustomDimensions.Add(DelChr(JobQueueEntry.FieldName("Error Message"), '=', ' '), JobQueueEntry."Error Message");
                        Log('O4NJQS-0002', RestartJobQueueEntryTok, Verbosity::Warning, CustomDimensions);
                    end;
                JobQueueEntry.Status::"On Hold":
                    begin
                        if JobQueueGeneralSetup."Log Job Queue Activity" then
                            ActivityLog.LogActivity("Scheduled Entry ori", ActivityLog.Status::Success, ContextTok, TaskScheduledMsg, '');
                        OnBeforeSetStatusReady("Scheduled Entry ori", JobQueueEntry);
                        if ApiClient.Initialize("Scheduled Entry ori") then
                            ApiClient.CallSetStatusToReady("Scheduled Entry ori")
                        else
                            JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);
                        Log('O4NJQS-0003', RestartJobQueueEntryTok, Verbosity::Warning, CustomDimensions);
                    end;
                else begin
                    ResetErrorCounterOnSuccess("Scheduled Entry ori", CustomDimensions);
                    exit;
                end;
            end
        end else
            if "Scheduled Entry ori"."Earliest Start Date/Time" <= CurrentDateTime then
                ScheduleNextJobQueueEntry("Scheduled Entry ori");
    end;

    /// <summary>
    /// Looks up the Job Queue Entry for the given orchestrator entry with UpdLock isolation.
    /// </summary>
    /// <param name="Scheduled Entry ori">The orchestrator entry whose ID identifies the Job Queue Entry.</param>
    /// <param name="JobQueueEntry">Return: the Job Queue Entry record if found.</param>
    /// <returns>True if the Job Queue Entry exists.</returns>
    local procedure JobQueueEntryFound("Scheduled Entry ori": Record "Scheduled Entry ori"; var JobQueueEntry: Record "Job Queue Entry") Found: Boolean
    var
        IsHandled: Boolean;
    begin
        OnBeforeJobQueueEntryFound("Scheduled Entry ori", JobQueueEntry, Found, IsHandled);
        if IsHandled then
            exit;

        JobQueueEntry.ReadIsolation := IsolationLevel::UpdLock;
        Found := JobQueueEntry.Get("Scheduled Entry ori".ID);

        OnAfterJobQueueEntryFound("Scheduled Entry ori", JobQueueEntry, Found);
    end;

    /// <summary>
    /// Emits a telemetry message via Session.LogMessage.
    /// </summary>
    local procedure Log(EventId: Text; Message: Text; Verbosity: Verbosity; CustomDimensions: Dictionary of [Text, Text])
    begin
        Session.LogMessage(EventId, Message, Verbosity, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
    end;

    /// <summary>
    /// Iterates over all non-blocked orchestrator entries and schedules or restarts each one.
    /// </summary>
    /// <param name="EmitTelemetry">When true, a heartbeat telemetry event is logged.</param>
    local procedure ScheduleJobs(EmitTelemetry: Boolean)
    var
        "Scheduled Entry ori": Record "Scheduled Entry ori";
        JobQueueEntry: Record "Job Queue Entry";
        ApiClient: Codeunit "Scheduler API Client ori";
        IsHandled: Boolean;
        CustomDimensions: Dictionary of [Text, Text];
        SendOrchestratorHeartbeatNotificationTok: Label 'Orchestrator Executed', Locked = true;
    begin
        OnBeforeScheduleJobs("Scheduled Entry ori", IsHandled);
        if IsHandled then
            exit;

        if EmitTelemetry then
            Log('O4NJQS-0004', SendOrchestratorHeartbeatNotificationTok, Verbosity::Normal, CustomDimensions);

        "Scheduled Entry ori".ReadIsolation := IsolationLevel::ReadCommitted;
        "Scheduled Entry ori".SetRange(Blocked, false);
        if "Scheduled Entry ori".FindSet() then
            repeat
                if JobQueueEntryFound("Scheduled Entry ori", JobQueueEntry) or (not ApiClient.Initialize("Scheduled Entry ori")) then
                    ScheduleTask("Scheduled Entry ori")
                else
                    ApiClient.CallUpdateJobQueueEntry("Scheduled Entry ori");
                Commit();
            until "Scheduled Entry ori".Next() = 0;
    end;

    /// <summary>
    /// Creates and enqueues a new Job Queue Entry when no existing entry is found for the orchestrator entry.
    /// </summary>
    /// <param name="Scheduled Entry ori">The orchestrator entry to create a Job Queue Entry for.</param>
    local procedure ScheduleNextJobQueueEntry("Scheduled Entry ori": Record "Scheduled Entry ori")
    var
        JobQueueEntry: Record "Job Queue Entry";
        CustomDimensions: Dictionary of [Text, Text];
        ScheduleNextJobQueueEntryTok: Label 'Schedule Next Job Queue Entry', Locked = true;
    begin
        JobQueueEntry.InitRecurringJob("Scheduled Entry ori"."No. of Minutes between Runs");
        "Scheduled Entry ori".CalcNextRunTimeForRecurringJob("Scheduled Entry ori", "Scheduled Entry ori"."Earliest Start Date/Time");
        JobQueueEntry."Earliest Start Date/Time" := "Scheduled Entry ori"."Earliest Start Date/Time";
        JobQueueEntry.ID := "Scheduled Entry ori".ID;
        JobQueueEntry."Object Type to Run" := "Scheduled Entry ori"."Object Type to Run";
        JobQueueEntry."Object ID to Run" := "Scheduled Entry ori"."Object ID to Run";
        JobQueueEntry."Record ID to Process" := "Scheduled Entry ori"."Record ID to Process";
        JobQueueEntry."Report Output Type" := "Scheduled Entry ori"."Report Output Type";
        JobQueueEntry."Job Queue Category Code" := "Scheduled Entry ori"."Job Queue Category Code";

        // Copy recurring schedule fields
        JobQueueEntry."Run on Mondays" := "Scheduled Entry ori"."Run on Mondays";
        JobQueueEntry."Run on Tuesdays" := "Scheduled Entry ori"."Run on Tuesdays";
        JobQueueEntry."Run on Wednesdays" := "Scheduled Entry ori"."Run on Wednesdays";
        JobQueueEntry."Run on Thursdays" := "Scheduled Entry ori"."Run on Thursdays";
        JobQueueEntry."Run on Fridays" := "Scheduled Entry ori"."Run on Fridays";
        JobQueueEntry."Run on Saturdays" := "Scheduled Entry ori"."Run on Saturdays";
        JobQueueEntry."Run on Sundays" := "Scheduled Entry ori"."Run on Sundays";
        JobQueueEntry."Starting Time" := "Scheduled Entry ori"."Starting Time";
        JobQueueEntry."Ending Time" := "Scheduled Entry ori"."Ending Time";
        JobQueueEntry."Next Run Date Formula" := "Scheduled Entry ori"."Next Run Date Formula";
        JobQueueEntry."Recurring Job" := true;

        JobQueueEntry."Maximum No. of Attempts to Run" := 3;
        JobQueueEntry.Description := CopyStr("Scheduled Entry ori".Description, 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry.Insert();
        OnAfterInitJobQueueEntryBeforeEnqueueTask("Scheduled Entry ori", JobQueueEntry);
        Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);

        OnAfterScheduleNextJobQueueEntry("Scheduled Entry ori", JobQueueEntry);

        if JobQueueGeneralSetup."Log Job Queue Activity" then
            ActivityLog.LogActivity("Scheduled Entry ori", ActivityLog.Status::Success, ContextTok, TaskScheduledMsg, '');

        "Scheduled Entry ori".CopyToCustomDimensions(CustomDimensions);
        Log('O4NJQS-0001', ScheduleNextJobQueueEntryTok, Verbosity::Normal, CustomDimensions);
    end;

    /// <summary>
    /// Resolves the notification interface from the orchestrator entry and sends a heartbeat notification.
    /// </summary>
    local procedure SendHartbeatViaInterface(var "Scheduled Entry ori": Record "Scheduled Entry ori"; var NotificationInterface: Interface "Notification ori")
    begin
        NotificationInterface := "Scheduled Entry ori"."Notification Type";
        NotificationInterface.SendHeartbeatNotification("Scheduled Entry ori");

        OnAfterSendHartbeatViaInterface("Scheduled Entry ori");
    end;

    /// <summary>
    /// Evaluates the retry policy to determine whether the restart should be skipped.
    /// </summary>
    /// <returns>True if the restart should be suppressed based on the policy and error counter.</returns>
    local procedure ShouldSkipRestartByPolicy("Scheduled Entry ori": Record "Scheduled Entry ori"): Boolean
    begin
        case "Scheduled Entry ori"."Retry Policy" of
            "Scheduled Entry ori"."Retry Policy"::Never:
                exit(true);
            "Scheduled Entry ori"."Retry Policy"::"Three Times":
                exit("Scheduled Entry ori"."Errors Since Last Success" >= 3);
            "Scheduled Entry ori"."Retry Policy"::Always:
                exit(false);
        end;
    end;

    /// <summary>
    /// Increments the error counter and restarts the Job Queue Entry via API or directly.
    /// </summary>
    local procedure RestartJobQueueEntryWithCounter("Scheduled Entry ori": Record "Scheduled Entry ori"; var JobQueueEntry: Record "Job Queue Entry"; ApiClient: Codeunit "Scheduler API Client ori")
    begin
        OnBeforeRestartJobQueueEntry("Scheduled Entry ori", JobQueueEntry);
        "Scheduled Entry ori"."Errors Since Last Success" += 1;
        "Scheduled Entry ori".Modify();
        if ApiClient.Initialize("Scheduled Entry ori") then
            ApiClient.CallRestartJobQueueEntry("Scheduled Entry ori")
        else
            JobQueueEntry.Restart();
    end;

    /// <summary>
    /// Resets the error counter to zero when the last Job Queue Log Entry shows a successful execution.
    /// </summary>
    local procedure ResetErrorCounterOnSuccess("Scheduled Entry ori": Record "Scheduled Entry ori"; var CustomDimensions: Dictionary of [Text, Text])
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        JobQueueLogEntry.SetRange(ID, "Scheduled Entry ori".ID);
        JobQueueLogEntry.SetLoadFields(Status);
        JobQueueLogEntry.ReadIsolation := IsolationLevel::ReadCommitted;
        if JobQueueLogEntry.FindLast() then
            if JobQueueLogEntry.Status = JobQueueLogEntry.Status::Success then
                if "Scheduled Entry ori"."Errors Since Last Success" <> 0 then begin
                    "Scheduled Entry ori"."Errors Since Last Success" := 0;
                    "Scheduled Entry ori".Modify();
                    LogErrorCounterReset(CustomDimensions);
                end;
    end;

    /// <summary>
    /// Logs a telemetry warning when a restart is suppressed by the retry policy.
    /// </summary>
    local procedure LogRestartSuppressed("Scheduled Entry ori": Record "Scheduled Entry ori"; var CustomDimensions: Dictionary of [Text, Text])
    var
        SuppressedMsg: Label 'Restart Suppressed by Retry Policy', Locked = true;
    begin
        CustomDimensions.Add('RetryPolicy', Format("Scheduled Entry ori"."Retry Policy".AsInteger()));
        CustomDimensions.Add('ErrorsSinceLastSuccess', Format("Scheduled Entry ori"."Errors Since Last Success"));
        Log('O4NJQS-0005', SuppressedMsg, Verbosity::Warning, CustomDimensions);
    end;

    /// <summary>
    /// Logs a telemetry event when the error counter is reset after a successful execution.
    /// </summary>
    local procedure LogErrorCounterReset(var CustomDimensions: Dictionary of [Text, Text])
    var
        CounterResetMsg: Label 'Error Counter Reset on Success', Locked = true;
    begin
        if not JobQueueGeneralSetup."Emit Telemetry" then
            exit;

        Log('O4NJQS-0006', CounterResetMsg, Verbosity::Normal, CustomDimensions);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitJobQueueEntryBeforeEnqueueTask("Scheduled Entry ori": Record "Scheduled Entry ori"; var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterJobQueueEntryFound("Scheduled Entry ori": Record "Scheduled Entry ori"; var JobQueueEntry: Record "Job Queue Entry"; var Found: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterScheduleNextJobQueueEntry("Scheduled Entry ori": Record "Scheduled Entry ori"; var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSendHartbeatViaInterface(var "Scheduled Entry ori": Record "Scheduled Entry ori")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobQueueEntryFound("Scheduled Entry ori": Record "Scheduled Entry ori"; var JobQueueEntry: Record "Job Queue Entry"; var Found: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRestartJobQueueEntry("Scheduled Entry ori": Record "Scheduled Entry ori"; var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeScheduleJobs("Scheduled Entry ori": Record "Scheduled Entry ori"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetStatusReady("Scheduled Entry ori": Record "Scheduled Entry ori"; JobQueueEntry: Record "Job Queue Entry")
    begin
    end;
}
