namespace Origo.Bifrost.Orchestrator;

/// <summary>Optional additive notification contract for due runs skipped without execution.</summary>
interface "Skipped Notification ori"
{
    /// <summary>Sends a skipped-run warning with the planned and replacement times.</summary>
    procedure SendSkippedNotification(Entry: Record "Scheduled Entry ori"; PlannedAt: DateTime; NewRunAt: DateTime)
}
