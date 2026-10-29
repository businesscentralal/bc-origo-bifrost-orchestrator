namespace Origo.Bifrost.Orchestrator;

/// <summary>Isolates notification errors from the completed scheduler re-enqueue transaction.</summary>
codeunit 10035621 "Skipped Notification Send ori"
{
    Access = Internal;
    TableNo = "Scheduled Entry ori";

    trigger OnRun()
    var
        Notification: Interface "Skipped Notification ori";
    begin
        Notification := Rec."Notification Type";
        Notification.SendSkippedNotification(Rec, PlannedAt, NewRunAt);
    end;

    var
        PlannedAt: DateTime;
        NewRunAt: DateTime;

    /// <summary>Sets the original and replacement slots before the isolated sender runs.</summary>
    internal procedure SetTimes(OriginalSlot: DateTime; ReplacementSlot: DateTime)
    begin
        PlannedAt := OriginalSlot;
        NewRunAt := ReplacementSlot;
    end;
}
