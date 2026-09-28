/// <summary>
/// Isolated write codeunit that prepares and sends the Job Queue restart notification email.
/// Running it via Codeunit.Run() keeps the scheduler alive if the setup lookup, body build or send fails.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using System.Threading;

codeunit 10035543 "Email Restart Send ori"
{
    Access = Internal;
    TableNo = "Scheduled Entry ori";

    trigger OnRun()
    var
        EmailNotification: Codeunit "Email Notification ori";
    begin
        EmailNotification.PrepareAndSendRestartNotification(Rec, JobQueueEntry);
    end;

    var
        JobQueueEntry: Record "Job Queue Entry";

    /// <summary>
    /// Sets the restarted Job Queue Entry used to build the notification body.
    /// </summary>
    /// <param name="NewJobQueueEntry">The restarted Job Queue Entry.</param>
    internal procedure SetJobQueueEntry(NewJobQueueEntry: Record "Job Queue Entry")
    begin
        JobQueueEntry := NewJobQueueEntry;
    end;
}
