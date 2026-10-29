/// <summary>
/// Calculates the next run DateTime for recurring job queue orchestrator entries,
/// supporting both date formula-based and weekday/minutes-based scheduling.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Microsoft.Utilities;
using System.DateTime;
using System.Threading;

codeunit 10035544 "Schedule Calc ori"
{
    /// <summary>
    /// Calculates the next run DateTime for a recurring schedule based on the entry configuration.
    /// Supports Next Run Date Formula (e.g. weekly/monthly) or weekday selection with minutes between runs.
    /// </summary>
    /// <param name="Scheduled Entry ori">The orchestrator entry with recurring schedule configuration.</param>
    /// <param name="LastExecutionDateTime">The DateTime of the last execution, or 0DT if never executed.</param>
    /// <param name="StartingDateTime">The base DateTime to calculate from.</param>
    /// <returns>The next DateTime when the job should run.</returns>
    internal procedure CalcNextRunTimeForRecurringSchedule(var "Scheduled Entry ori": Record "Scheduled Entry ori"; LastExecutionDateTime: DateTime; StartingDateTime: DateTime): DateTime
    begin
        exit(CalcNextRunTimeForRecurringSchedule("Scheduled Entry ori", LastExecutionDateTime, StartingDateTime, CurrentDateTime));
    end;

    /// <summary>Calculates the next slot using one captured clock value for the whole calculation.</summary>
    internal procedure CalcNextRunTimeForRecurringSchedule(var "Scheduled Entry ori": Record "Scheduled Entry ori"; LastExecutionDateTime: DateTime; StartingDateTime: DateTime; NowDateTime: DateTime): DateTime
    var
        NewRunDate: Date;
        NewRunDateTime: DateTime;
        InvalidNexRunDateFormulaErr: Label '%1: %2 is invalid', Comment = '%1 = Field Caption, %2 = Field Value, is-IS=%1: %2 er ógilt';
    begin
        if StartingDateTime = 0DT then
            StartingDateTime := NowDateTime;
        NewRunDate := DT2Date(StartingDateTime);

        if "Scheduled Entry ori".IsNextRunDateFormulaSet() then begin
            if CalcDate("Scheduled Entry ori"."Next Run Date Formula", NewRunDate) <= NewRunDate then
                Error(InvalidNexRunDateFormulaErr, "Scheduled Entry ori".FieldCaption("Next Run Date Formula"), "Scheduled Entry ori"."Next Run Date Formula");
            while CreateDateTime(NewRunDate, "Scheduled Entry ori"."Starting Time") < NowDateTime do begin
                StartingDateTime := CreateDateTime(NewRunDate, "Scheduled Entry ori"."Starting Time");
                NewRunDate := CalcDate("Scheduled Entry ori"."Next Run Date Formula", NewRunDate);
            end;
            if IsInsideAllowedTimeRange("Scheduled Entry ori", NowDateTime) and (StartingDateTime > LastExecutionDateTime) then
                exit(StartingDateTime)
            else
                exit(CreateDateTime(NewRunDate, "Scheduled Entry ori"."Starting Time"));
        end;

        // A first dispatch has no successful execution to advance from. Keep the latest
        // due slot while inside today's allowed window, rather than advancing forever.
        if (LastExecutionDateTime = 0DT) and ("Scheduled Entry ori"."No. of Minutes between Runs" > 0) then
            exit(CalcFirstRunTime("Scheduled Entry ori", StartingDateTime, NowDateTime));

        // A delayed daily dispatch must not shift tomorrow's configured starting time.
        if (LastExecutionDateTime <> 0DT) and
           ("Scheduled Entry ori"."No. of Minutes between Runs" = 1440) and
           ("Scheduled Entry ori"."Starting Time" <> 0T) then
            exit(CalcRunTimeForRecurringSchedule("Scheduled Entry ori",
                CreateDateTime(DT2Date(LastExecutionDateTime) + 1, "Scheduled Entry ori"."Starting Time")));

        NewRunDateTime := StartingDateTime;

        if "Scheduled Entry ori"."No. of Minutes between Runs" > 0 then
            if LastExecutionDateTime > 0DT then begin
                StartingDateTime := CalcRunTimeForRecurringSchedule("Scheduled Entry ori", LastExecutionDateTime);
                NewRunDateTime := AddMinutesToDateTime(StartingDateTime, "Scheduled Entry ori"."No. of Minutes between Runs")
            end else
                while CalcRunTimeForRecurringSchedule("Scheduled Entry ori", NewRunDateTime) < NowDateTime do begin
                    StartingDateTime := CalcRunTimeForRecurringSchedule("Scheduled Entry ori", NewRunDateTime);
                    NewRunDateTime := AddMinutesToDateTime(NewRunDateTime, "Scheduled Entry ori"."No. of Minutes between Runs")
                end;

        if IsInsideAllowedTimeRange("Scheduled Entry ori", StartingDateTime) and (StartingDateTime > LastExecutionDateTime) and (LastExecutionDateTime > 0DT) then
            exit(StartingDateTime)
        else
            exit(CalcRunTimeForRecurringSchedule("Scheduled Entry ori", NewRunDateTime));
    end;

    local procedure CalcFirstRunTime(var ScheduledEntry: Record "Scheduled Entry ori"; StartingDateTime: DateTime; NowDateTime: DateTime): DateTime
    var
        DueSlot: DateTime;
        NextSlot: DateTime;
    begin
        NextSlot := CalcRunTimeForRecurringSchedule(ScheduledEntry, StartingDateTime);
        while NextSlot < NowDateTime do begin
            DueSlot := NextSlot;
            NextSlot := CalcRunTimeForRecurringSchedule(ScheduledEntry,
                AddMinutesToDateTime(NextSlot, ScheduledEntry."No. of Minutes between Runs"));
        end;
        if NextSlot = NowDateTime then
            exit(NextSlot);
        if (DueSlot <> 0DT) and
           (CalcRunTimeForRecurringSchedule(ScheduledEntry, NowDateTime) = NowDateTime) then
            exit(DueSlot);
        exit(NextSlot);
    end;

    local procedure CalcRunTimeForRecurringSchedule(var "Scheduled Entry ori": Record "Scheduled Entry ori"; StartingDateTime: DateTime) NewRunDateTime: DateTime
    var
        Found: Boolean;
        RunOnDate: array[7] of Boolean;
        NoOfDays: Integer;
        NoOfExtraDays: Integer;
        StartingWeekDay: Integer;
    begin
        RunOnDate[1] := "Scheduled Entry ori"."Run on Mondays";
        RunOnDate[2] := "Scheduled Entry ori"."Run on Tuesdays";
        RunOnDate[3] := "Scheduled Entry ori"."Run on Wednesdays";
        RunOnDate[4] := "Scheduled Entry ori"."Run on Thursdays";
        RunOnDate[5] := "Scheduled Entry ori"."Run on Fridays";
        RunOnDate[6] := "Scheduled Entry ori"."Run on Saturdays";
        RunOnDate[7] := "Scheduled Entry ori"."Run on Sundays";
        if StartingDateTime = 0DT then
            StartingDateTime := CurrentDateTime;
        NewRunDateTime := StartingDateTime;
        NoOfDays := 0;
        if ("Scheduled Entry ori"."Ending Time" <> 0T) and (NewRunDateTime > "Scheduled Entry ori".GetEndingDateTime(NewRunDateTime)) then begin
            NewRunDateTime := "Scheduled Entry ori".GetStartingDateTime(NewRunDateTime);
            NoOfDays := NoOfDays + 1;
        end;

        StartingWeekDay := Date2DWY(DT2Date(StartingDateTime), 1);
        Found := RunOnDate[(StartingWeekDay - 1 + NoOfDays) mod 7 + 1];
        NoOfExtraDays := 0;
        while not Found and (NoOfExtraDays < 7) do begin
            NoOfExtraDays := NoOfExtraDays + 1;
            NoOfDays := NoOfDays + 1;
            Found := RunOnDate[(StartingWeekDay - 1 + NoOfDays) mod 7 + 1];
        end;

        if ("Scheduled Entry ori"."Starting Time" <> 0T) and (NewRunDateTime < "Scheduled Entry ori".GetStartingDateTime(NewRunDateTime)) then
            NewRunDateTime := "Scheduled Entry ori".GetStartingDateTime(NewRunDateTime);

        if (NoOfDays > 0) and (NewRunDateTime > "Scheduled Entry ori".GetStartingDateTime(NewRunDateTime)) then
            NewRunDateTime := "Scheduled Entry ori".GetStartingDateTime(NewRunDateTime);

        if ("Scheduled Entry ori"."Starting Time" = 0T) and (NoOfExtraDays > 0) and ("Scheduled Entry ori"."No. of Minutes between Runs" <> 0) then
            NewRunDateTime := CreateDateTime(DT2Date(NewRunDateTime), 0T);

        if Found then
            NewRunDateTime := CreateDateTime(DT2Date(NewRunDateTime) + NoOfDays, DT2Time(NewRunDateTime));
    end;

    local procedure IsInsideAllowedTimeRange(var "Scheduled Entry ori": Record "Scheduled Entry ori"; DateTimeToCheck: DateTime) IsInside: Boolean
    begin
        IsInside := true;
        if "Scheduled Entry ori"."Starting Time" <> 0T then
            IsInside := IsInside and (DT2Time(DateTimeToCheck) >= "Scheduled Entry ori"."Starting Time");
        if "Scheduled Entry ori"."Ending Time" <> 0T then
            IsInside := IsInside and (DT2Time(DateTimeToCheck) <= "Scheduled Entry ori"."Ending Time");
    end;

    local procedure AddMinutesToDateTime(SourceDateTime: DateTime; NoOfMinutes: Integer) NewDateTime: DateTime
    var
        MillisecondsToAdd: BigInteger;
    begin
        MillisecondsToAdd := NoOfMinutes;
        MillisecondsToAdd := MillisecondsToAdd * 60000;
        NewDateTime := SourceDateTime + MillisecondsToAdd;
    end;

#pragma warning disable AA0228, AA0137
    local procedure ConvertFromEntryTimezoneToSystem(var "Scheduled Entry ori": Record "Scheduled Entry ori"; DateTimeInEntryTimezone: DateTime): DateTime
    var
        TimeZone: Record "Time Zone";
    begin
        // TODO: Implement timezone conversion
        // If "Scheduled Entry ori"."Time Zone Code" is blank, return as-is
        // Otherwise, convert from entry timezone to UTC, then to system timezone
        // For now, return unchanged until timezone conversion task is implemented
        exit(DateTimeInEntryTimezone);
    end;

    local procedure ConvertFromSystemToEntryTimezone(var "Scheduled Entry ori": Record "Scheduled Entry ori"; DateTimeInSystemTimezone: DateTime): DateTime
    var
        TimeZone: Record "Time Zone";
    begin
        // TODO: Implement timezone conversion
        // If "Scheduled Entry ori"."Time Zone Code" is blank, return as-is
        // Otherwise, convert from system timezone to UTC, then to entry timezone
        // For now, return unchanged until timezone conversion task is implemented
        exit(DateTimeInSystemTimezone);
    end;

    local procedure CreateDateTimeInSystemTimezone(var "Scheduled Entry ori": Record "Scheduled Entry ori"; DatePart: Date; TimePart: Time): DateTime
    var
        DateTimeInEntryTZ: DateTime;
    begin
        // Create DateTime from date + time (assumed to be in entry timezone)
        DateTimeInEntryTZ := CreateDateTime(DatePart, TimePart);
        // Convert to system timezone
        exit(ConvertFromEntryTimezoneToSystem("Scheduled Entry ori", DateTimeInEntryTZ));
    end;
#pragma warning restore AA0228, AA0137

    /// <summary>
    /// Handles the Job Queue Dispatcher event before calculating next run time for recurring jobs.
    /// Delegates scheduling logic to CalcNextRunTimeForRecurringSchedule and determines the next run DateTime
    /// based on the associated orchestrator entry's configuration (date formula, weekday, or minutes between runs).
    /// </summary>
    /// <param name="JobQueueEntry">The job queue entry being scheduled.</param>
    /// <param name="StartingDateTime">The base DateTime to calculate from.</param>
    /// <param name="NewRunDateTime">Output: The calculated next run DateTime.</param>
    /// <param name="IsHandled">Output: Set to true to indicate scheduling was handled by this subscriber.</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue Dispatcher", 'OnBeforeCalcNextRunTimeForRecurringJob', '', false, false)]
    local procedure JobQueueDispatcher_OnBeforeCalcNextRunTimeForRecurringJob(JobQueueEntry: Record "Job Queue Entry"; StartingDateTime: DateTime; var NewRunDateTime: DateTime; var IsHandled: Boolean)
    var
        NextRunContextTok: Label 'Next Recurring Start', MaxLength = 30, Comment = 'is-IS=Næsta endurtekna keyrsla';
        ActivityDescriptionTok: Label 'Last Run: %1, Next Run: %2, IsHandled: %3', Comment = '%1 = Last Run DateTime, %2 = New Run DateTime, %3 = IsHandled Boolean, is-IS=Síðasta keyrsla: %1, Næsta keyrsla: %2, Meðhöndlað: %3';
        LastRunDateTime: DateTime;
    begin
        FindLastRunTime(JobQueueEntry, LastRunDateTime);
        IsHandled := GetNewRunDateTime(JobQueueEntry, LastRunDateTime, StartingDateTime, NewRunDateTime);
        LogActivity(JobQueueEntry, NextRunContextTok, StrSubstNo(ActivityDescriptionTok, LastRunDateTime, NewRunDateTime, IsHandled));
    end;

    /// <summary>
    /// Computes the next run DateTime for a job queue entry based on its orchestrator configuration.
    /// </summary>
    /// <param name="JobQueueEntry">The job queue entry record.</param>
    /// <param name="LastRunDateTime">The DateTime of the last successful run, or 0DT when no run succeeded.</param>
    /// <param name="StartingDateTime">The base DateTime to calculate from. If 0DT, uses SystemModifiedAt.</param>
    /// <param name="NewRunDateTime">Output: The calculated next run DateTime.</param>
    /// <returns>True if calculation succeeded, false otherwise.</returns>
    internal procedure GetNewRunDateTime(var JobQueueEntry: Record "Job Queue Entry"; LastRunDateTime: DateTime; StartingDateTime: DateTime; var NewRunDateTime: DateTime): Boolean
    var
        "Scheduled Entry ori": Record "Scheduled Entry ori";
    begin
        // Find the associated orchestrator entry
        if not "Scheduled Entry ori".Get(JobQueueEntry.ID) then
            exit(false);

        // Initialize StartingDateTime if not provided
        if StartingDateTime = 0DT then
            StartingDateTime := JobQueueEntry.SystemModifiedAt;

        // Calculate the next run time using the schedule calculator
        NewRunDateTime := CalcNextRunTimeForRecurringSchedule("Scheduled Entry ori", LastRunDateTime, StartingDateTime);

        exit(true);
    end;

    /// <summary>
    /// Finds the last successful run time for a job queue entry from its log.
    /// </summary>
    /// <param name="JobQueueEntry">The job queue entry record.</param>
    /// <param name="LastRunDateTime">Output: The DateTime of the last successful run, or 0DT if never run.</param>
    local procedure FindLastRunTime(var JobQueueEntry: Record "Job Queue Entry"; var LastRunDateTime: DateTime)
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        LastRunDateTime := 0DT;
        JobQueueLogEntry.SetLoadFields(ID, Status, "Start Date/Time");
        JobQueueLogEntry.ReadIsolation := IsolationLevel::ReadCommitted;
        JobQueueLogEntry.SetRange(ID, JobQueueEntry.ID);
        JobQueueLogEntry.SetRange(Status, JobQueueLogEntry.Status::Success);
        if JobQueueLogEntry.FindLast() then
            LastRunDateTime := JobQueueLogEntry."Start Date/Time";
        // Last Ready State records queue administration, not a successful execution.
    end;

    /// <summary>
    /// Logs a orchestrator activity to the Activity Log if logging is enabled.
    /// </summary>
    /// <param name="JobQueueEntry">The job queue entry being processed.</param>
    /// <param name="Context">Short context label (max 30 chars) for the activity.</param>
    /// <param name="ActivityDescription">Detailed description of the activity.</param>
    local procedure LogActivity(var JobQueueEntry: Record "Job Queue Entry"; Context: Text[30]; ActivityDescription: Text)
    var
        ActivityLog: Record "Activity Log";
        JobQueueGeneralSetup: Record "Scheduler Setup ori";
    begin
        // Get setup configuration
        JobQueueGeneralSetup.GetRecordOnce();

        // Exit if logging is not enabled
        if not JobQueueGeneralSetup."Log Job Queue Activity" then
            exit;

        // Log the activity
        ActivityLog.LogActivity(JobQueueEntry, ActivityLog.Status::Success, Context, ActivityDescription, '');
    end;

    /// <summary>
    /// Handles the Job Queue Dispatcher event before running a scheduled job.
    /// Checks if the job should be skipped based on the next run time being outside the allowed time range.
    /// If skipped, sets the job to "On Hold" with the calculated next run DateTime.
    /// </summary>
    /// <param name="JobQueueEntry">The job queue entry about to be executed.</param>
    /// <param name="Skip">Output: Set to true to skip execution and reschedule the job.</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue Dispatcher", 'OnBeforeRun', '', false, false)]
    local procedure JobQueueDispatcher_OnBeforeRun(var JobQueueEntry: Record "Job Queue Entry"; var Skip: Boolean)
    var
        NextRunContextTok: Label 'Check for Next Run', MaxLength = 30, Comment = 'is-IS=Athuga næstu keyrslu';
        ActivityDescriptionTok: Label 'Last Run: %1, Next Run: %2, Skip: %3', Comment = '%1 = Last Run DateTime, %2 = New Run DateTime, %3 = Skip Boolean, is-IS=Síðasta keyrsla: %1, Næsta keyrsla: %2, Sleppa: %3';
        LastRunDateTime: DateTime;
        NewRunDateTime: DateTime;
    begin
        // Only process if this is a recurring orchestrator job
        if not JobQueueEntry."Recurring Job" then
            exit;

        // Find last run time
        FindLastRunTime(JobQueueEntry, LastRunDateTime);

        // Calculate the next run datetime
        if not GetNewRunDateTime(JobQueueEntry, LastRunDateTime, JobQueueEntry."Earliest Start Date/Time", NewRunDateTime) then
            exit;

        // Check if the new run is in the future (outside allowed time)
        Skip := NewRunDateTime > CurrentDateTime;

        // Log the activity
        LogActivity(JobQueueEntry, NextRunContextTok, StrSubstNo(ActivityDescriptionTok, LastRunDateTime, NewRunDateTime, Skip));

        // If we're skipping, reschedule the job
        if not Skip then
            exit;

        JobQueueEntry.SetStatus(JobQueueEntry.Status::"On Hold");
        JobQueueEntry."Earliest Start Date/Time" := NewRunDateTime;
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
    end;
}
