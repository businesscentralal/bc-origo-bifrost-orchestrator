/// <summary>
/// Interface for Job Queue Orchestrator notification implementations.
/// </summary>
namespace Origo.Bifrost.Nornir;

using System.Threading;

interface "Notification ori"
{
    /// <summary>
    /// Returns whether a notification recipient is mandatory for this implementation.
    /// </summary>
    /// <returns>True if a recipient is required.</returns>
    procedure IsNotificationReceipientMandatory() IsMandatory: Boolean

    /// <summary>
    /// Sends a notification after a Job Queue Entry completes execution.
    /// </summary>
    /// <param name="Scheduled Entry ori">The orchestrator entry that was executed.</param>
    /// <param name="JobQueueEntry">The Job Queue Entry with execution results.</param>
    procedure SendExecutionCompletedNotification("Scheduled Entry ori": Record "Scheduled Entry ori"; JobQueueEntry: Record "Job Queue Entry");
    /// <summary>
    /// Sends a heartbeat notification for the orchestrator entry.
    /// </summary>
    /// <param name="Scheduled Entry ori">The orchestrator entry to report on.</param>
    procedure SendHeartbeatNotification("Scheduled Entry ori": Record "Scheduled Entry ori");
    /// <summary>
    /// Sends a notification when a Job Queue Entry is restarted.
    /// </summary>
    /// <param name="Scheduled Entry ori">The orchestrator entry being restarted.</param>
    /// <param name="JobQueueEntry">The Job Queue Entry being restarted.</param>
    procedure SendRestartNotification("Scheduled Entry ori": Record "Scheduled Entry ori"; JobQueueEntry: Record "Job Queue Entry");
    /// <summary>
    /// Sends a test notification for validating the notification setup.
    /// </summary>
    /// <param name="Scheduled Entry ori">The orchestrator entry to test.</param>
    procedure SendTestNotification("Scheduled Entry ori": Record "Scheduled Entry ori");
    /// <summary>
    /// Validates the notification recipient configuration.
    /// </summary>
    /// <param name="Scheduled Entry ori">The orchestrator entry to validate.</param>
    procedure ValidateNotificationReceipient("Scheduled Entry ori": Record "Scheduled Entry ori");
}
