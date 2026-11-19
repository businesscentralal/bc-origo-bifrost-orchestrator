namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;
using System.Threading;

/// <summary>
/// Issue #215: a run whose step graph points at a step that does not exist leaves exactly one instance,
/// closed as Failed with the error text and CompletedAt, and the playbook header says Failed. Before the
/// fix the instance, committed by the Commit() ahead of step 10's message call, stayed Running forever.
/// </summary>
codeunit 96496 "Playbook Missing Step Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Lib: Codeunit "Playbook Test Library ori";
        PlaybookCodeTok: Label 'MISSSTEP-215', Locked = true;
        HelpRequestTok: Label '{"messageTypes":["Orchestrator.Playbook.Schedule"],"chapters":["parameters"]}', Locked = true;
        StepNotFoundEnTxt: Label 'Step 20 not found in playbook MISSSTEP-215.', Locked = true;
        StepNotFoundIsTxt: Label 'Skref 20 fannst ekki í keðju MISSSTEP-215.', Locked = true;

    [Test]
    procedure DirectRun_MissingNextStep_LeavesOneFailedInstance()
    begin
        VerifyMissingNextStep(1033, StepNotFoundEnTxt);
    end;

    [Test]
    procedure DirectRun_MissingNextStep_LeavesOneFailedInstance_Icelandic()
    begin
        VerifyMissingNextStep(1039, StepNotFoundIsTxt);
    end;

    [Test]
    procedure JobQueueRun_MissingNextStep_LeavesOneFailedInstance()
    var
        Playbook: Record "Playbook ori";
        Instance: Record "Playbook Instance ori";
        JQEntry: Record "Job Queue Entry";
    begin
        // [GIVEN] A playbook whose step 10 points to a step 20 that does not exist
        CreateBrokenPlaybook(10);
        Playbook.Get(PlaybookCodeTok);
        JQEntry.Init();
        JQEntry.ID := CreateGuid();
        JQEntry."Object Type to Run" := JQEntry."Object Type to Run"::Codeunit;
        JQEntry."Object ID to Run" := Codeunit::"Playbook JQ Dispatcher ori";
        JQEntry."Record ID to Process" := Playbook.RecordId();

        // [WHEN] The Job Queue runs the entry through its own dispatcher, as a scheduled run does
        JQEntry."Maximum No. of Attempts to Run" := 3;
        JQEntry.Insert();
        Commit();
        if Codeunit.Run(Codeunit::"Job Queue Dispatcher", JQEntry) then;

        // [THEN] The run fails and leaves exactly one instance, Failed
        Instance.SetRange("Playbook Code", PlaybookCodeTok);
        Assert.AreEqual(1, Instance.Count(), 'One instance per run attempt');
        Instance.FindFirst();
        Assert.AreEqual(Instance.Status::Failed, Instance.Status, 'Failed, not Running');
        if JQEntry.Find() then
            JQEntry.Delete();
        Lib.Cleanup(PlaybookCodeTok);
    end;

    /// <summary>The Failure branch pointing at a missing step is closed the same way (edge case).</summary>
    [Test]
    procedure DirectRun_MissingFailureStep_LeavesOneFailedInstance()
    var
        PlaybookStep: Record "Playbook Step ori";
        Instance: Record "Playbook Instance ori";
        InstanceId: Guid;
        ReportRequestTok: Label '{"reportId":%1}', Locked = true;
    begin
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Orchestrator.Report.Run",
            StrSubstNo(ReportRequestTok, Report::"Test Failing Report"), 0, '', 0);
        Lib.AddSuccessCondition(PlaybookCodeTok, 10, 'status', 'Success');
        PlaybookStep.Get(PlaybookCodeTok, 10);
        PlaybookStep."Next Step No. (Failure)" := 20;
        PlaybookStep.Modify();

        asserterror Lib.RunPlaybook(PlaybookCodeTok, InstanceId);

        Instance.SetRange("Playbook Code", PlaybookCodeTok);
        Assert.AreEqual(1, Instance.Count(), 'One instance');
        Instance.FindFirst();
        Assert.AreEqual(Instance.Status::Failed, Instance.Status, 'Failed');
        Assert.AreNotEqual(0DT, Instance."Completed At", 'CompletedAt is set');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    /// <summary>AC03: abandoned Running instances are closed as Failed, recent and finished ones are left alone, nothing is deleted.</summary>
    [Test]
    procedure CloseAbandoned_ClosesOnlyOldRunningInstances()
    var
        Playbook: Record "Playbook ori";
        Instance: Record "Playbook Instance ori";
        LogMgt: Codeunit "Playbook Log Mgt ori";
        OldId: Guid;
        RecentId: Guid;
        DoneId: Guid;
    begin
        Lib.CreatePlaybook(PlaybookCodeTok);
        OldId := InsertInstance("Playbook Inst. Status ori"::Running, CurrentDateTime() - 48 * 3600000L);
        RecentId := InsertInstance("Playbook Inst. Status ori"::Running, CurrentDateTime() - 1 * 3600000L);
        DoneId := InsertInstance("Playbook Inst. Status ori"::Completed, CurrentDateTime() - 48 * 3600000L);
        Playbook.Get(PlaybookCodeTok);
        Playbook."Last Run Instance ID" := OldId;
        Playbook."Last Run Status" := Playbook."Last Run Status"::Running;
        Playbook.Modify();

        Instance.SetRange("Playbook Code", PlaybookCodeTok);
        Assert.AreEqual(1, LogMgt.CloseAbandonedInstances(Instance, 24), 'One abandoned instance closed');

        Instance.Get(OldId);
        Assert.AreEqual(Instance.Status::Failed, Instance.Status, 'Old run is Failed');
        Assert.AreNotEqual('', Instance."Error Text", 'Error text explains it');
        Assert.AreNotEqual(0DT, Instance."Completed At", 'CompletedAt set');
        Instance.Get(RecentId);
        Assert.AreEqual(Instance.Status::Running, Instance.Status, 'A recent run is left alone');
        Instance.Get(DoneId);
        Assert.AreEqual(Instance.Status::Completed, Instance.Status, 'A completed run is left alone');
        Playbook.Get(PlaybookCodeTok);
        Assert.AreEqual(Playbook."Last Run Status"::Failed, Playbook."Last Run Status", 'Header corrected');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    /// <summary>AC02: the platform must not rerun a failed playbook run (4 instances per attempt); other entries keep 3 attempts.</summary>
    [Test]
    procedure ScheduledPlaybookEntry_JobQueueEntryHasNoPlatformRetries()
    var
        PlaybookEntry: Record "Scheduled Entry ori";
        OtherEntry: Record "Scheduled Entry ori";
        JobQueueEntry: Record "Job Queue Entry";
        SchedulerHandler: Codeunit "Scheduler Handler ori";
    begin
        // [GIVEN] A scheduled entry for the playbook dispatcher and one for another codeunit
        InsertScheduledEntry(PlaybookEntry, Codeunit::"Playbook JQ Dispatcher ori");
        InsertScheduledEntry(OtherEntry, Codeunit::"Scheduler Handler ori");

        // [WHEN] The scheduler creates the Job Queue Entries
        SchedulerHandler.ScheduleTask(PlaybookEntry, true);
        SchedulerHandler.ScheduleTask(OtherEntry, true);

        // [THEN] The playbook entry has no platform retries, the other keeps 3
        JobQueueEntry.Get(PlaybookEntry.ID);
        Assert.AreEqual(0, JobQueueEntry."Maximum No. of Attempts to Run", 'Playbook entry: the Retry Policy restarts, not the platform');
        JobQueueEntry.Delete();
        JobQueueEntry.Get(OtherEntry.ID);
        Assert.AreEqual(3, JobQueueEntry."Maximum No. of Attempts to Run", 'Other entries keep 3 attempts');
        JobQueueEntry.Delete();
        PlaybookEntry.Delete();
        OtherEntry.Delete();
    end;

    local procedure InsertScheduledEntry(var Entry: Record "Scheduled Entry ori"; ObjectId: Integer)
    begin
        Entry.Init();
        Entry.ID := CreateGuid();
        Entry."Object Type to Run" := Entry."Object Type to Run"::Codeunit;
        Entry."Object ID to Run" := ObjectId;
        Entry."Run on Mondays" := true;
        Entry."Run on Tuesdays" := true;
        Entry."Run on Wednesdays" := true;
        Entry."Run on Thursdays" := true;
        Entry."Run on Fridays" := true;
        Entry."Run on Saturdays" := true;
        Entry."Run on Sundays" := true;
        Entry."No. of Minutes between Runs" := 60;
        Entry."Earliest Start Date/Time" := CurrentDateTime();
        Entry.Insert();
    end;

    local procedure InsertInstance(NewStatus: Enum "Playbook Inst. Status ori"; StartedAt: DateTime): Guid
    var
        Instance: Record "Playbook Instance ori";
    begin
        Instance.Init();
        Instance.ID := CreateGuid();
        Instance."Playbook Code" := PlaybookCodeTok;
        Instance.Status := NewStatus;
        Instance."Started At" := StartedAt;
        Instance.Insert();
        exit(Instance.ID);
    end;

    local procedure VerifyMissingNextStep(LanguageId: Integer; ExpectedError: Text)
    var
        Playbook: Record "Playbook ori";
        Instance: Record "Playbook Instance ori";
        InstanceId: Guid;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] A step whose Next Step does not exist fails the run cleanly
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        CreateBrokenPlaybook(10);

        asserterror Lib.RunPlaybook(PlaybookCodeTok, InstanceId);

        Assert.ExpectedError(ExpectedError);
        Instance.SetRange("Playbook Code", PlaybookCodeTok);
        Assert.AreEqual(1, Instance.Count(), 'Exactly one instance');
        Instance.FindFirst();
        Assert.AreEqual(Instance.Status::Failed, Instance.Status, 'Failed, not Running');
        Assert.AreEqual(ExpectedError, Instance."Error Text", 'Error text is stored');
        Assert.AreNotEqual(0DT, Instance."Completed At", 'CompletedAt is set');
        Playbook.Get(PlaybookCodeTok);
        Assert.AreEqual(Instance.ID, Playbook."Last Run Instance ID", 'The header points at the instance');
        Assert.AreEqual(Playbook."Last Run Status"::Failed, Playbook."Last Run Status", 'The header says Failed');
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure CreateBrokenPlaybook(StepNo: Integer)
    var
        PlaybookStep: Record "Playbook Step ori";
    begin
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, StepNo, "Playbook Step Type ori"::Action, "Message Type ori"::"Help.Implementation.Get", HelpRequestTok, 0, '', 0);
        PlaybookStep.Get(PlaybookCodeTok, StepNo);
        PlaybookStep."Next Step No. (Success)" := 20;
        PlaybookStep.Modify();
    end;
}
