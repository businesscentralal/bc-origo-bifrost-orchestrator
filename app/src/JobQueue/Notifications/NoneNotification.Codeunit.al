/// <summary>
/// No-op notification implementation for the Job Queue Orchestrator when notifications are disabled.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using System.Threading;

codeunit 10035540 "None Notification ori" implements "Notification ori"
{
    /// <summary>
    /// Returns that a notification recipient is not mandatory when notifications are disabled.
    /// </summary>
    /// <returns>False.</returns>
    procedure IsNotificationReceipientMandatory() IsMandatory: Boolean
    begin
        IsMandatory := false;

        OnAfterIsNotificationReceipientMandatory(IsMandatory);
    end;

    /// <summary>
    /// No-op: does not send an execution completed notification.
    /// </summary>
    /// <param name="Scheduled Entry ori">The orchestrator entry that was executed.</param>
    /// <param name="JobQueueEntry">The Job Queue Entry with execution results.</param>
    procedure SendExecutionCompletedNotification("Scheduled Entry ori": Record "Scheduled Entry ori"; JobQueueEntry: Record "Job Queue Entry")
    begin
        OnAfterSendExecutionCompletedNotification("Scheduled Entry ori", JobQueueEntry);
    end;

    /// <summary>
    /// No-op: does not send a heartbeat notification.
    /// </summary>
    /// <param name="Scheduled Entry ori">The orchestrator entry to report on.</param>
    procedure SendHeartbeatNotification("Scheduled Entry ori": Record "Scheduled Entry ori")
    begin
        OnAfterSendHeartbeatNotification("Scheduled Entry ori");
    end;

    /// <summary>
    /// No-op: does not send a restart notification.
    /// </summary>
    /// <param name="Scheduled Entry ori">The orchestrator entry being restarted.</param>
    /// <param name="JobQueueEntry">The restarted Job Queue Entry.</param>
    procedure SendRestartNotification("Scheduled Entry ori": Record "Scheduled Entry ori"; JobQueueEntry: Record "Job Queue Entry")
    begin
        OnAfterSendRestartNotification("Scheduled Entry ori", JobQueueEntry);
    end;

    /// <summary>
    /// No-op: does not send a test notification.
    /// </summary>
    /// <param name="Scheduled Entry ori">The orchestrator entry to test.</param>
    procedure SendTestNotification("Scheduled Entry ori": Record "Scheduled Entry ori")
    begin
    end;

    /// <summary>
    /// Validates the notification recipient; errors if a recipient is set when notifications are disabled.
    /// </summary>
    /// <param name="Scheduled Entry ori">The orchestrator entry to validate.</param>
    procedure ValidateNotificationReceipient("Scheduled Entry ori": Record "Scheduled Entry ori")
    var
        IsHandled: Boolean;
        NoNotificationErr: Label '%3 is not supported for %1 %2', Comment = '%1 = Notification Type Caption, %2 = Notification Type, %3 = Notification Recipient Caption, is-IS=%3 er ekki stutt fyrir %1 %2';
    begin
        OnBeforeValidateNotificationReceipient("Scheduled Entry ori", IsHandled);
        if IsHandled then
            exit;

        if "Scheduled Entry ori"."Notification Recipient" = '' then exit;
        Error(NoNotificationErr, "Scheduled Entry ori".FieldCaption("Notification Type"), "Scheduled Entry ori"."Notification Type", "Scheduled Entry ori".FieldCaption("Notification Recipient"));

    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsNotificationReceipientMandatory(var IsMandatory: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSendExecutionCompletedNotification("Scheduled Entry ori": Record "Scheduled Entry ori"; JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSendHeartbeatNotification("Scheduled Entry ori": Record "Scheduled Entry ori")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSendRestartNotification("Scheduled Entry ori": Record "Scheduled Entry ori"; JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateNotificationReceipient("Scheduled Entry ori": Record "Scheduled Entry ori"; var IsHandled: Boolean)
    begin
    end;
}
