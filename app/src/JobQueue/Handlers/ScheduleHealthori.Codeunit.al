namespace Origo.Bifrost.Orchestrator;

using System.Threading;

/// <summary>Read-only schedule diagnostics and durable accounting of due slots skipped by the dispatcher.</summary>
codeunit 10035620 "Schedule Health ori"
{
    Access = Internal;
    Permissions = tabledata "Scheduled Entry ori" = RM,
                  tabledata "Job Queue Entry" = R,
                  tabledata "Job Queue Log Entry" = R;

    /// <summary>Appends actionable health flags without changing the entry or its job.</summary>
    internal procedure AddAttention(Entry: Record "Scheduled Entry ori"; var Attention: JsonArray; NowDateTime: DateTime)
    var
        Job: Record "Job Queue Entry";
        LogEntry: Record "Job Queue Log Entry";
        Interval: Duration;
    begin
        if Entry.Blocked then
            exit;
        if Job.Get(Entry.ID) then begin
            if (Job."Starting Time" <> 0T) and (Job."Reference Starting Time" = 0DT) then
                AddFlag(Entry, Attention, 'ReferenceStartingTimeBlank', ReferenceNextStepTxt);
        end else
            AddFlag(Entry, Attention, 'NoJobQueueEntry', MissingJobNextStepTxt);

        if Entry."Skips Since Last Run" > 0 then
            AddFlag(Entry, Attention, 'SilentlySkipped', SkippedNextStepTxt);
        if Entry.SystemCreatedAt = 0DT then
            exit;
        Interval := Entry."No. of Minutes between Runs";
        Interval := Interval * 60000;
        if Entry.IsNextRunDateFormulaSet() then
            Interval := CreateDateTime(CalcDate(Entry."Next Run Date Formula", DT2Date(Entry.SystemCreatedAt)), DT2Time(Entry.SystemCreatedAt)) - Entry.SystemCreatedAt;
        if Interval <= 0 then
            exit;
        // Allow a fifteen-minute scheduler grace period after the first interval.
        if NowDateTime <= Entry.SystemCreatedAt + Interval + 900000 then
            exit;
        LogEntry.SetRange(ID, Entry.ID);
        LogEntry.SetRange(Status, LogEntry.Status::Success);
        if LogEntry.IsEmpty() then
            AddFlag(Entry, Attention, 'OverdueNoRun', OverdueNextStepTxt);
    end;

    /// <summary>Records one skipped due slot after the dispatcher has safely re-enqueued its job.</summary>
    internal procedure RecordSkip(Job: Record "Job Queue Entry"; PlannedAt: DateTime; NewRunAt: DateTime; NowDateTime: DateTime)
    var
        Entry: Record "Scheduled Entry ori";
        Sender: Codeunit "Skipped Notification Send ori";
        Dimensions: Dictionary of [Text, Text];
        Reason: Text;
        IsHandled: Boolean;
    begin
        if not Entry.Get(Job.ID) then
            exit;
        Reason := 'NextSlotInFuture';
        if not IsAllowedSlot(Entry, NowDateTime) then
            Reason := 'OutsideWindow';
        Dimensions.Add('EntryId', Format(Entry.ID, 0, 4));
        Dimensions.Add('PlannedAt', Format(PlannedAt, 0, 9));
        Dimensions.Add('NewRunAt', Format(NewRunAt, 0, 9));
        Dimensions.Add('Reason', Reason);
        Session.LogMessage('O4NJQS-0010', 'Recurring job skipped before execution', Verbosity::Warning,
            DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);

        // Future dispatches and normal re-arms before a window opens are not missed due runs.
        if (PlannedAt = 0DT) or (PlannedAt > NowDateTime) or (NewRunAt <= PlannedAt) then
            exit;
        if not IsAllowedSlot(Entry, PlannedAt) then
            exit;
        Entry.LockTable();
        Entry.Get(Job.ID);
        if Entry."Last Skipped Slot" = PlannedAt then
            exit;
        Entry."Skips Since Last Run" += 1;
        Entry."Last Skipped At" := NowDateTime;
        Entry."Last Skipped Slot" := PlannedAt;
        Entry.Modify();
        if (DT2Date(NewRunAt) <= DT2Date(PlannedAt)) and (Entry."Skips Since Last Run" < 3) then
            exit;
        if Entry."Notification Type" = Entry."Notification Type"::None then
            exit;
        // Persist the de-duplication marker and the completed re-enqueue before external I/O.
        Commit();
        OnBeforeSendSkippedNotification(Entry, PlannedAt, NewRunAt, IsHandled);
        if IsHandled then
            exit;
        Sender.SetTimes(PlannedAt, NewRunAt);
        if not Sender.Run(Entry) then
            Session.LogMessage('O4NJQS-0011', 'Skipped-run notification failed', Verbosity::Warning,
                DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
    end;

    /// <summary>Clears consecutive-skip diagnostics only after a successful job execution.</summary>
    internal procedure ResetAfterSuccess(EntryId: Guid)
    var
        Entry: Record "Scheduled Entry ori";
    begin
        if not Entry.Get(EntryId) then
            exit;
        if Entry."Skips Since Last Run" = 0 then
            exit;
        Entry."Skips Since Last Run" := 0;
        Entry."Last Skipped At" := 0DT;
        Entry."Last Skipped Slot" := 0DT;
        Entry.Modify();
    end;

    local procedure IsAllowedSlot(Entry: Record "Scheduled Entry ori"; Slot: DateTime): Boolean
    var
        Days: array[7] of Boolean;
    begin
        if Slot = 0DT then
            exit(false);
        if (Entry."Starting Time" <> 0T) and (DT2Time(Slot) < Entry."Starting Time") then
            exit(false);
        if (Entry."Ending Time" <> 0T) and (DT2Time(Slot) > Entry."Ending Time") then
            exit(false);
        if Entry.IsNextRunDateFormulaSet() then
            exit(true);
        Days[1] := Entry."Run on Mondays";
        Days[2] := Entry."Run on Tuesdays";
        Days[3] := Entry."Run on Wednesdays";
        Days[4] := Entry."Run on Thursdays";
        Days[5] := Entry."Run on Fridays";
        Days[6] := Entry."Run on Saturdays";
        Days[7] := Entry."Run on Sundays";
        exit(Days[Date2DWY(DT2Date(Slot), 1)]);
    end;

    local procedure AddFlag(Entry: Record "Scheduled Entry ori"; var Attention: JsonArray; FlagCode: Text; NextStep: Text)
    var
        Flag: JsonObject;
    begin
        Flag.Add('entryId', Format(Entry.ID, 0, 4));
        Flag.Add('description', Entry.Description);
        Flag.Add('code', FlagCode);
        Flag.Add('nextStep', NextStep);
        Attention.Add(Flag);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendSkippedNotification(Entry: Record "Scheduled Entry ori"; PlannedAt: DateTime; NewRunAt: DateTime; var IsHandled: Boolean)
    begin
    end;

    var
        ReferenceNextStepTxt: Label 'Validate Starting Time on the Scheduled Entry or rebuild its Job Queue Entry with Orchestrator.Entry.Schedule. Status does not repair it.', Comment = 'is-IS=Staðfestu upphafstíma tímasettu færslunnar eða endurskapaðu vinnsluraðafærslu hennar með Orchestrator.Entry.Schedule. Stöðuskoðun lagar hana ekki.';
        MissingJobNextStepTxt: Label 'Check that the orchestrator is running, then schedule the entry with Orchestrator.Entry.Schedule.', Comment = 'is-IS=Athugaðu að vinnsluraðarinn sé í gangi og tímasettu síðan færsluna með Orchestrator.Entry.Schedule.';
        SkippedNextStepTxt: Label 'Inspect the schedule window and skipped-run telemetry before rescheduling the entry.', Comment = 'is-IS=Skoðaðu tímaglugga og fjarmælingar yfir keyrslur sem var sleppt áður en færslan er tímasett aftur.';
        OverdueNextStepTxt: Label 'No successful run was recorded after one interval plus 15 minutes. Check the Job Queue Entry and its schedule.', Comment = 'is-IS=Engin heppnuð keyrsla var skráð eftir eitt keyrslubil og 15 mínútur. Athugaðu vinnsluraðafærsluna og tímasetningu hennar.';
}
