namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost.Orchestrator;
using System.Threading;

/// <summary>Regression coverage for the first recurring dispatch and its starting-time anchor.</summary>
codeunit 96443 "First Schedule Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    /// <summary>A newly due daily job keeps its due slot.</summary>
    [Test]
    procedure Scenario_AC01_NeverRunDailyKeepsDueSlot()
    begin
        // #130 AC01 | Time: fixed clock, WorkDate ignored | Risk: None
        AssertFirstSlot(1440, 103000T, 110000T, 103001T, 20260105D, 103000T);
    end;

    /// <summary>A daily job without an ending time runs on first dispatch.</summary>
    [Test]
    procedure Scenario_AC02_NoEndingTimeKeepsDueSlot()
    begin
        // #130 AC02 | Time: fixed clock | Risk: None
        AssertFirstSlot(1440, 103000T, 0T, 104500T, 20260105D, 103000T);
    end;

    /// <summary>An hourly job runs at the latest due slot.</summary>
    [Test]
    procedure Scenario_AC02_HourlyKeepsLatestDueSlot()
    begin
        // #130 AC02 | Time: fixed clock | Risk: None
        AssertFirstSlot(60, 080000T, 170000T, 103001T, 20260105D, 100000T);
    end;

    /// <summary>A future window does not run early.</summary>
    [Test]
    procedure Scenario_AC02_FutureWindowWaits()
    begin
        // #130 AC02 | Time: fixed clock | Risk: None
        AssertFirstSlot(1440, 103000T, 110000T, 100000T, 20260105D, 103000T);
    end;

    /// <summary>An elapsed daily window moves to tomorrow.</summary>
    [Test]
    procedure Scenario_AC07_ElapsedDailyWindowWaits()
    begin
        // #130 AC07 | Time: fixed clock | Risk: None
        AssertFirstSlot(1440, 103000T, 110000T, 110001T, 20260106D, 103000T);
    end;

    /// <summary>An elapsed hourly window moves to tomorrow's start.</summary>
    [Test]
    procedure Scenario_AC07_ElapsedHourlyWindowWaits()
    begin
        // #130 AC07 | Time: fixed clock | Risk: None
        AssertFirstSlot(60, 080000T, 170000T, 170001T, 20260106D, 080000T);
    end;

    /// <summary>A previously successful run advances one interval.</summary>
    [Test]
    procedure Scenario_AC03_SuccessAdvancesDaily()
    var
        Entry: Record "Scheduled Entry ori";
        Calc: Codeunit "Schedule Calc ori";
        Slot: DateTime;
    begin
        // #130 AC03 | Time: fixed clock | Risk: None
        InitializeEntry(Entry, 1440, 103000T, 110000T);
        Slot := CreateDateTime(20260105D, 103000T);
        Assert.AreEqual(CreateDateTime(20260106D, 103000T),
            Calc.CalcNextRunTimeForRecurringSchedule(Entry, Slot, Slot, Slot + 1000), 'A successful slot must not run twice');
    end;

    /// <summary>A late successful daily run does not shift the next day's starting time.</summary>
    [Test]
    procedure Scenario_AC01_LateDailyRunKeepsNextDayAnchor()
    var
        Entry: Record "Scheduled Entry ori";
        Calc: Codeunit "Schedule Calc ori";
        ActualRun: DateTime;
    begin
        // #130 AC01/03 | Time: fixed clock | Risk: None
        InitializeEntry(Entry, 1440, 103000T, 110000T);
        ActualRun := CreateDateTime(20260105D, 103201T);
        Assert.AreEqual(CreateDateTime(20260106D, 103000T),
            Calc.CalcNextRunTimeForRecurringSchedule(Entry, ActualRun, ActualRun, ActualRun),
            'Delayed execution must not move the daily anchor');
    end;

    /// <summary>A daily execution delayed past midnight retains the upcoming evening slot.</summary>
    [Test]
    procedure Scenario_AC01_MidnightDelayKeepsSameDayAnchor()
    var
        Entry: Record "Scheduled Entry ori";
        Calc: Codeunit "Schedule Calc ori";
        ActualRun: DateTime;
    begin
        // #130 AC01/03 | Time: fixed clock | Risk: None
        // Given Monday's 23:30 dispatch succeeds just after midnight on Tuesday.
        InitializeEntry(Entry, 1440, 233000T, 0T);
        ActualRun := CreateDateTime(20260106D, 000500T);
        // When calculating recurrence, then Tuesday evening must not be skipped.
        Assert.AreEqual(CreateDateTime(20260106D, 233000T),
            Calc.CalcNextRunTimeForRecurringSchedule(Entry, ActualRun, ActualRun, ActualRun),
            'A midnight-delayed success must retain the next configured start on the same date');
    end;

    /// <summary>A never-run schedule created inside its window retains its first due slot.</summary>
    [Test]
    procedure Scenario_AC01_CreatedInsideWindowRunsFirstSlot()
    var
        Entry: Record "Scheduled Entry ori";
        Calc: Codeunit "Schedule Calc ori";
        CreatedAt: DateTime;
    begin
        // #130 AC01 | Time: fixed clock | Risk: None
        // Given a daily entry created after its configured start, inside the window.
        InitializeEntry(Entry, 1440, 103000T, 110000T);
        CreatedAt := CreateDateTime(20260105D, 104500T);
        // When first dispatched, then its due creation slot remains eligible.
        Assert.AreEqual(CreatedAt,
            Calc.CalcNextRunTimeForRecurringSchedule(Entry, 0DT, CreatedAt, CreatedAt + 1000),
            'Creating an entry inside its window must not postpone its first dispatch');
    end;

    /// <summary>Changing and clearing a recurring starting time updates its reference.</summary>
    [Test]
    procedure Scenario_AC05_StartChangeAndClearSyncReference()
    var
        Entry: Record "Scheduled Entry ori";
        Job: Record "Job Queue Entry";
    begin
        // #130 AC05 | Time: BC reference date 2000-01-01 | Risk: None
        Entry.ID := CreateGuid();
        Entry.Insert();
        Job.ID := Entry.ID;
        Job."Recurring Job" := true;
        Job.Insert();
        Entry.Validate("Starting Time", 103000T);
        Job.Get(Entry.ID);
        Assert.AreEqual(CreateDateTime(20000101D, 103000T), Job."Reference Starting Time", 'Anchor must follow validation');
        Entry.Validate("Starting Time", 0T);
        Job.Get(Entry.ID);
        Assert.AreEqual(0DT, Job."Reference Starting Time", 'Cleared starting time must clear the anchor');
        Job.Delete();
        Entry.Delete();
    end;

    /// <summary>The production scheduling and dispatcher path creates an instance and a successful log.</summary>
    [Test]
    procedure Scenario_AC01_AC04_AC06_FirstDispatchRunsPlaybook()
    var
        Entry: Record "Scheduled Entry ori";
        Job: Record "Job Queue Entry";
        LogEntry: Record "Job Queue Log Entry";
        Playbook: Record "Playbook ori";
        RecurringTemplate: Record "Recurring Template ori";
        Instance: Record "Playbook Instance ori";
        Handler: Codeunit "Scheduler Handler ori";
        LibraryQueue: Codeunit "Library Orchestrator";
        EntryId: Guid;
        StartTime: Time;
    begin
        // #130 AC01/04/06 | Time: current clock, start of today's minute | Risk: tasks intercepted
        Playbook.Code := CopyStr(DelChr(Format(CreateGuid(), 0, 4), '=', '-'), 1, 20);
        Playbook.Description := 'Owned first-dispatch regression';
        Playbook.Insert();
        RecurringTemplate.Code := Playbook.Code;
        RecurringTemplate."Run on Mondays" := true;
        RecurringTemplate."Run on Tuesdays" := true;
        RecurringTemplate."Run on Wednesdays" := true;
        RecurringTemplate."Run on Thursdays" := true;
        RecurringTemplate."Run on Fridays" := true;
        RecurringTemplate."Run on Saturdays" := true;
        RecurringTemplate."Run on Sundays" := true;
        StartTime := DT2Time(CurrentDateTime - 1000);
        RecurringTemplate."Starting Time" := StartTime;
        RecurringTemplate."No. of Minutes between Runs" := 1440;
        RecurringTemplate.Insert();
        Playbook.CreateOrchestratorEntry(RecurringTemplate.Code, "Notif. Type ori"::None, '', '', false, "Retry Policy ori"::Always, EntryId);
        Entry.Get(EntryId);
        BindSubscription(LibraryQueue);
        Handler.ScheduleTask(Entry);
        Job.Get(EntryId);
        Assert.AreEqual(CreateDateTime(20000101D, StartTime), Job."Reference Starting Time", 'Created job reference');
        // Legacy jobs may have either a blank or administrative Last Ready State, neither is execution.
        Job."Earliest Start Date/Time" := CurrentDateTime - 1000;
        Job."Last Ready State" := CurrentDateTime - 1000;
        Job.Status := Job.Status::Ready;
        Job.Modify();
        Commit();
        LibraryQueue.RunJobQueueDispatcher(Job);
        Playbook.Get(Playbook.Code);
        Assert.IsFalse(IsNullGuid(Playbook."Last Run Instance ID"), 'First dispatch must create a playbook instance');
        LogEntry.SetRange(ID, EntryId);
        LogEntry.SetRange(Status, LogEntry.Status::Success);
        Assert.IsFalse(LogEntry.IsEmpty(), 'First dispatch must write a successful Job Queue log');
        Job.Get(EntryId);
        Assert.AreEqual(CreateDateTime(Today() + 1, StartTime), Job."Earliest Start Date/Time", 'Next daily dispatch must keep the configured starting time tomorrow');
        // Reset the library's insertion collector before recreating the same job ID.
        UnbindSubscription(LibraryQueue);
        Clear(LibraryQueue);
        BindSubscription(LibraryQueue);
        // Rebuild using the same production scheduling path.
        Job.Delete();
        Entry."Earliest Start Date/Time" := CreateDateTime(Today() + 1, StartTime);
        Entry.Modify();
        Handler.ScheduleTask(Entry, true);
        Job.Get(EntryId);
        Assert.AreEqual(CreateDateTime(20000101D, StartTime), Job."Reference Starting Time", 'Rebuilt job reference');
        Assert.AreEqual(Today() + 1, DT2Date(Job."Earliest Start Date/Time"), 'Explicit rebuild must retain the future run time');
        UnbindSubscription(LibraryQueue);
        Job.Delete();
        LogEntry.DeleteAll();
        Instance.SetRange("Playbook Code", Playbook.Code);
        Instance.DeleteAll();
        Entry.Delete();
        Playbook.Delete();
        RecurringTemplate.Delete();
    end;

    /// <summary>Applying a template updates the existing job and its starting-time reference.</summary>
    [Test]
    procedure Scenario_AC05_TemplateKeepsJobAndSyncsReference()
    var
        Entry: Record "Scheduled Entry ori";
        Job: Record "Job Queue Entry";
        RecurringTemplate: Record "Recurring Template ori";
        JobSystemId: Guid;
    begin
        // #130 AC05 | Time: fixed times | Risk: no task scheduled
        RecurringTemplate.Code := CopyStr(DelChr(Format(CreateGuid(), 0, 4), '=', '-'), 1, 20);
        RecurringTemplate."Run on Mondays" := true;
        RecurringTemplate."Starting Time" := 103000T;
        RecurringTemplate."Ending Time" := 110000T;
        RecurringTemplate."No. of Minutes between Runs" := 1440;
        RecurringTemplate.Insert();
        Entry.ID := CreateGuid();
        Entry.Insert();
        Job.ID := Entry.ID;
        Job."Recurring Job" := true;
        Job.Insert();
        JobSystemId := Job.SystemId;
        Entry.Validate("Recurring Template Code", RecurringTemplate.Code);
        Entry.Modify();
        Job.Get(Entry.ID);
        Assert.AreEqual(JobSystemId, Job.SystemId, 'Template application must retain the linked job');
        Assert.AreEqual(103000T, Job."Starting Time", 'Template starting time must synchronize');
        Assert.AreEqual(CreateDateTime(20000101D, 103000T), Job."Reference Starting Time", 'Template reference must synchronize');
        Assert.AreEqual(110000T, Job."Ending Time", 'Template ending time must synchronize');
        Assert.AreEqual(1440, Job."No. of Minutes between Runs", 'Template interval must synchronize');
        Assert.IsTrue(Job."Run on Mondays", 'Template weekdays must synchronize');
        Job.Delete();
        Entry.Delete();
        RecurringTemplate.Delete();
    end;

    local procedure AssertFirstSlot(Minutes: Integer; StartTime: Time; EndTime: Time; NowTime: Time; ExpectedDate: Date; ExpectedTime: Time)
    var
        Entry: Record "Scheduled Entry ori";
        Calc: Codeunit "Schedule Calc ori";
    begin
        // [GIVEN] A recurring entry that has never run, with all weekdays enabled.
        InitializeEntry(Entry, Minutes, StartTime, EndTime);
        // [WHEN] The dispatcher calculates its first due slot.
        // [THEN] A due slot is retained only while the window permits running.
        Assert.AreEqual(CreateDateTime(ExpectedDate, ExpectedTime),
            Calc.CalcNextRunTimeForRecurringSchedule(Entry, 0DT, CreateDateTime(20260105D, StartTime), CreateDateTime(20260105D, NowTime)),
            'The first dispatch must not advance past a runnable due slot');
    end;

    local procedure InitializeEntry(var Entry: Record "Scheduled Entry ori"; Minutes: Integer; StartTime: Time; EndTime: Time)
    begin
        Entry.Init();
        Entry."Run on Mondays" := true;
        Entry."Run on Tuesdays" := true;
        Entry."Run on Wednesdays" := true;
        Entry."Run on Thursdays" := true;
        Entry."Run on Fridays" := true;
        Entry."Run on Saturdays" := true;
        Entry."Run on Sundays" := true;
        Entry."Starting Time" := StartTime;
        Entry."Ending Time" := EndTime;
        Entry."No. of Minutes between Runs" := Minutes;
    end;
}
