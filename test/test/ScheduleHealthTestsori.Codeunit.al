namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.Threading;

/// <summary>Issue 131: read-only diagnostics, skip accounting and non-blocking playbook warnings.</summary>
codeunit 96444 "Schedule Health Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit Assert;
        NotificationCount: Integer;
        ExpectedEntryId: Guid;
        LastPlannedAt: DateTime;
        LastNewRunAt: DateTime;

    /// <summary>A skipped due daily slot is counted once and emits one notification.</summary>
    [Test]
    procedure Scenario_AC01_AC02_AC03_DueSkipDeduplicates()
    var
        Entry: Record "Scheduled Entry ori";
        Job: Record "Job Queue Entry";
        Health: Codeunit "Schedule Health ori";
        Observer: Codeunit "Schedule Health Tests ori";
        PlannedAt: DateTime;
        NewRunAt: DateTime;
    begin
        // #131 AC01-03 | Time: fixed clock | Risk: no external notification is sent
        CreateEntry(Entry, Job);
        Entry."Notification Type" := Entry."Notification Type"::Telegram;
        Entry.Modify();
        PlannedAt := CreateDateTime(20260105D, 103000T);
        NewRunAt := CreateDateTime(20260106D, 103000T);
        Observer.Watch(Entry.ID);
        BindSubscription(Observer);
        Health.RecordSkip(Job, PlannedAt, NewRunAt, PlannedAt + 1000);
        Health.RecordSkip(Job, PlannedAt, NewRunAt, PlannedAt + 2000);
        Entry.Get(Entry.ID);
        Assert.AreEqual(1, Entry."Skips Since Last Run", 'Repeated dispatch must count one due slot');
        Observer.AssertNotification(1, PlannedAt, NewRunAt);
        UnbindSubscription(Observer);
        Cleanup(Entry, Job);
    end;

    /// <summary>A future window and an early dispatcher tick are ordinary waits.</summary>
    [Test]
    procedure Scenario_AC03_WaitingDoesNotNotifyOrCount()
    var
        Entry: Record "Scheduled Entry ori";
        Job: Record "Job Queue Entry";
        Health: Codeunit "Schedule Health ori";
    begin
        // #131 AC03 | Time: fixed clock | Risk: None
        CreateEntry(Entry, Job);
        Health.RecordSkip(Job, CreateDateTime(20260105D, 080000T), CreateDateTime(20260105D, 103000T), CreateDateTime(20260105D, 080001T));
        Health.RecordSkip(Job, CreateDateTime(20260105D, 103000T), CreateDateTime(20260105D, 103000T), CreateDateTime(20260105D, 100000T));
        Entry.Get(Entry.ID);
        Assert.AreEqual(0, Entry."Skips Since Last Run", 'Normal waiting is not a missed run');
        Cleanup(Entry, Job);
    end;

    /// <summary>None still records the missed run without calling a notification provider.</summary>
    [Test]
    procedure Scenario_AC02_NoneDoesNotNotify()
    var
        Entry: Record "Scheduled Entry ori";
        Job: Record "Job Queue Entry";
        Health: Codeunit "Schedule Health ori";
        Observer: Codeunit "Schedule Health Tests ori";
        PlannedAt: DateTime;
    begin
        // #131 AC02 | Time: fixed clock | Risk: None
        CreateEntry(Entry, Job);
        Observer.Watch(Entry.ID);
        BindSubscription(Observer);
        PlannedAt := CreateDateTime(20260105D, 103000T);
        Health.RecordSkip(Job, PlannedAt, PlannedAt + 86400000, PlannedAt + 1000);
        Observer.AssertNotification(0, 0DT, 0DT);
        Entry.Get(Entry.ID);
        Assert.AreEqual(1, Entry."Skips Since Last Run", 'None must not hide skipped-run diagnostics');
        UnbindSubscription(Observer);
        Cleanup(Entry, Job);
    end;

    /// <summary>A successful execution clears consecutive skip diagnostics.</summary>
    [Test]
    procedure Scenario_AC04_SuccessResetsSkips()
    var
        Entry: Record "Scheduled Entry ori";
        Job: Record "Job Queue Entry";
        Health: Codeunit "Schedule Health ori";
    begin
        // #131 AC04 | Time: current clock only stamps metadata | Risk: None
        CreateEntry(Entry, Job);
        Entry."Skips Since Last Run" := 3;
        Entry."Last Skipped At" := CurrentDateTime;
        Entry."Last Skipped Slot" := CurrentDateTime;
        Entry.Modify();
        Health.ResetAfterSuccess(Entry.ID);
        Entry.Get(Entry.ID);
        Assert.AreEqual(0, Entry."Skips Since Last Run", 'Successful execution resets the consecutive count');
        Assert.AreEqual(0DT, Entry."Last Skipped At", 'Successful execution clears stale diagnostic time');
        Cleanup(Entry, Job);
    end;

    /// <summary>A blank reference is reported without changing the JQE.</summary>
    [Test]
    procedure Scenario_AC05_BlankReferenceReadOnly()
    var
        Entry: Record "Scheduled Entry ori";
        Job: Record "Job Queue Entry";
        Health: Codeunit "Schedule Health ori";
        Attention: JsonArray;
    begin
        // #131 AC05 | Time: current clock within grace period | Risk: None
        CreateEntry(Entry, Job);
        Job."Reference Starting Time" := 0DT;
        Job.Modify();
        Health.AddAttention(Entry, Attention, CurrentDateTime);
        AssertFlag(Attention, 'ReferenceStartingTimeBlank');
        Job.Get(Job.ID);
        Assert.AreEqual(0DT, Job."Reference Starting Time", 'Status must never repair the job');
        Cleanup(Entry, Job);
    end;

    /// <summary>New healthy entries are not marked overdue; past grace entries without success are.</summary>
    [Test]
    procedure Scenario_AC05_GraceAndSuccessControlOverdue()
    var
        Entry: Record "Scheduled Entry ori";
        Job: Record "Job Queue Entry";
        LogEntry: Record "Job Queue Log Entry";
        Health: Codeunit "Schedule Health ori";
        Attention: JsonArray;
        AfterGrace: DateTime;
    begin
        // #131 AC05 | Time: SystemCreatedAt + interval + 15 minutes | Risk: None
        CreateEntry(Entry, Job);
        Entry.Get(Entry.ID);
        Health.AddAttention(Entry, Attention, Entry.SystemCreatedAt + 86400000);
        Assert.AreEqual(0, Attention.Count(), 'Healthy new entry must have no attention flags');
        AfterGrace := Entry.SystemCreatedAt + 86400000 + 900001;
        Health.AddAttention(Entry, Attention, AfterGrace);
        AssertFlag(Attention, 'OverdueNoRun');
        LogEntry.ID := Job.ID;
        LogEntry.Status := LogEntry.Status::Success;
        LogEntry."Start Date/Time" := Entry.SystemCreatedAt + 1000;
        LogEntry.Insert();
        Clear(Attention);
        Health.AddAttention(Entry, Attention, AfterGrace);
        Assert.AreEqual(0, Attention.Count(), 'A successful log excludes never-run warning');
        LogEntry.Delete();
        Cleanup(Entry, Job);
    end;

    /// <summary>Blocked entries are excluded and missing jobs are actionable.</summary>
    [Test]
    procedure Scenario_AC05_MissingAndBlockedEntries()
    var
        Entry: Record "Scheduled Entry ori";
        Job: Record "Job Queue Entry";
        Health: Codeunit "Schedule Health ori";
        Attention: JsonArray;
    begin
        // #131 AC05 | Time: current clock | Risk: None
        CreateEntry(Entry, Job);
        Job.Delete();
        Health.AddAttention(Entry, Attention, CurrentDateTime);
        AssertFlag(Attention, 'NoJobQueueEntry');
        Clear(Attention);
        Entry.Blocked := true;
        Health.AddAttention(Entry, Attention, CurrentDateTime);
        Assert.AreEqual(0, Attention.Count(), 'Blocked entries are excluded');
        Entry.Delete();
    end;

    /// <summary>Schedule health findings are visible but do not join the execution refusal gate.</summary>
    [Test]
    procedure Scenario_AC06_VerifyScheduleWarningDoesNotBlock()
    var
        Entry: Record "Scheduled Entry ori";
        Job: Record "Job Queue Entry";
        Playbook: Record "Playbook ori";
        Verify: Codeunit "Playbook Verify ori";
        Findings: JsonArray;
        Blocking: JsonArray;
        Summary: Text;
    begin
        // #131 AC06 | Time: current clock within grace | Risk: None
        CreateEntry(Entry, Job);
        Job."Reference Starting Time" := 0DT;
        Job.Modify();
        Playbook.Code := CopyStr(DelChr(Format(CreateGuid(), 0, 4), '=', '-'), 1, 20);
        Playbook."Orchestrator Entry ID" := Entry.ID;
        Playbook.Insert();
        Verify.GetFindings(Playbook.Code, Findings);
        AssertFlag(Findings, 'ScheduleNotRunning');
        Assert.IsFalse(Verify.GetBlockingFindings(Playbook.Code, false, Blocking, Summary), 'Health warning must not block Run even without ignoreWarnings');
        Playbook.Delete();
        Cleanup(Entry, Job);
    end;

    /// <summary>Configures the notification observer for one owned fixture.</summary>
    internal procedure Watch(EntryId: Guid)
    begin
        ExpectedEntryId := EntryId;
        NotificationCount := 0;
        LastPlannedAt := 0DT;
        LastNewRunAt := 0DT;
    end;

    /// <summary>Checks notification count and both slot timestamps.</summary>
    internal procedure AssertNotification(ExpectedCount: Integer; PlannedAt: DateTime; NewRunAt: DateTime)
    begin
        Assert.AreEqual(ExpectedCount, NotificationCount, 'Notification count');
        Assert.AreEqual(PlannedAt, LastPlannedAt, 'Notification planned slot');
        Assert.AreEqual(NewRunAt, LastNewRunAt, 'Notification replacement slot');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Schedule Health ori", 'OnBeforeSendSkippedNotification', '', false, false)]
    local procedure CaptureNotification(Entry: Record "Scheduled Entry ori"; PlannedAt: DateTime; NewRunAt: DateTime; var IsHandled: Boolean)
    begin
        Assert.AreEqual(ExpectedEntryId, Entry.ID, 'Only the owned fixture may notify');
        NotificationCount += 1;
        LastPlannedAt := PlannedAt;
        LastNewRunAt := NewRunAt;
        IsHandled := true;
    end;

    local procedure CreateEntry(var Entry: Record "Scheduled Entry ori"; var Job: Record "Job Queue Entry")
    begin
        Entry.Init();
        Entry.ID := CreateGuid();
        Entry.Description := 'Owned schedule health test';
        Entry.Blocked := false;
        Entry."Run on Mondays" := true;
        Entry."Run on Tuesdays" := true;
        Entry."Run on Wednesdays" := true;
        Entry."Run on Thursdays" := true;
        Entry."Run on Fridays" := true;
        Entry."Run on Saturdays" := true;
        Entry."Run on Sundays" := true;
        Entry."Starting Time" := 103000T;
        Entry."Ending Time" := 110000T;
        Entry."No. of Minutes between Runs" := 1440;
        Entry.Insert();
        Job.Init();
        Job.ID := Entry.ID;
        Job."Recurring Job" := true;
        Job.Validate("Starting Time", Entry."Starting Time");
        Job.Insert();
    end;

    local procedure AssertFlag(Flags: JsonArray; ExpectedCode: Text)
    var
        Token: JsonToken;
        Value: JsonToken;
        Flag: JsonObject;
        Found: Boolean;
    begin
        foreach Token in Flags do begin
            Flag := Token.AsObject();
            Flag.Get('code', Value);
            if Value.AsValue().AsText() = ExpectedCode then begin
                Found := true;
                Flag.Get('nextStep', Value);
                Assert.AreNotEqual('', Value.AsValue().AsText(), 'Flag must include an actionable next step');
            end;
        end;
        Assert.IsTrue(Found, 'Expected attention flag: ' + ExpectedCode);
    end;

    local procedure Cleanup(var Entry: Record "Scheduled Entry ori"; var Job: Record "Job Queue Entry")
    begin
        Job.Delete();
        Entry.Delete();
    end;
}
