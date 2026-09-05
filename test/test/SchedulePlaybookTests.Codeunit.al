namespace Origo.Bifrost.Nornir.Test;

using Origo.Bifrost.Nornir;
using System.Threading;

codeunit 96415 "Schedule Playbook Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure CreateOrchestratorEntryCreatesEntry()
    var
        Playbook: Record "Playbook ori";
        Entry: Record "Scheduled Entry ori";
        RecurringTemplate: Record "Recurring Template ori";
        EntryId: Guid;
    begin
        // [SCENARIO] CreateOrchestratorEntry inserts an orchestrator entry for the playbook
        CreatePlaybook(Playbook, 'SCHED-01');
        CreateRecurringTemplate(RecurringTemplate, 'SCHED-TPL1');

        EntryId := Playbook.CreateOrchestratorEntry(
            RecurringTemplate.Code,
            "Notif. Type ori"::None, '', '', false,
            "Retry Policy ori"::Always);

        Assert.IsTrue(Entry.Get(EntryId), 'Orchestrator entry should exist');
        Assert.AreEqual(
            Codeunit::"Playbook JQ Dispatcher ori",
            Entry."Object ID to Run",
            'Should run the playbook dispatcher');
        Assert.IsFalse(Entry.Blocked, 'Entry should not be blocked');

        Cleanup(Playbook.Code);
    end;

    [Test]
    procedure CreateOrchestratorEntryStoresIdOnPlaybook()
    var
        Playbook: Record "Playbook ori";
        RecurringTemplate: Record "Recurring Template ori";
        EntryId: Guid;
    begin
        // [SCENARIO] The orchestrator entry ID is stored on the playbook record
        CreatePlaybook(Playbook, 'SCHED-02');
        CreateRecurringTemplate(RecurringTemplate, 'SCHED-TPL2');

        EntryId := Playbook.CreateOrchestratorEntry(
            RecurringTemplate.Code,
            "Notif. Type ori"::None, '', '', false,
            "Retry Policy ori"::Always);

        Playbook.Get(Playbook.Code);
        Assert.AreEqual(EntryId, Playbook."Orchestrator Entry ID", 'Playbook should store the entry ID');

        Cleanup(Playbook.Code);
    end;

    [Test]
    procedure ScheduledFlowFieldReflectsOrchestratorEntry()
    var
        Playbook: Record "Playbook ori";
        RecurringTemplate: Record "Recurring Template ori";
    begin
        // [SCENARIO] Scheduled FlowField returns true when orchestrator entry exists
        CreatePlaybook(Playbook, 'SCHED-03');
        CreateRecurringTemplate(RecurringTemplate, 'SCHED-TPL3');

        Playbook.CalcFields(Scheduled);
        Assert.IsFalse(Playbook.Scheduled, 'Should not be scheduled before creating entry');

        Playbook.CreateOrchestratorEntry(
            RecurringTemplate.Code,
            "Notif. Type ori"::None, '', '', false,
            "Retry Policy ori"::Always);

        Playbook.Get(Playbook.Code);
        Playbook.CalcFields(Scheduled);
        Assert.IsTrue(Playbook.Scheduled, 'Should be scheduled after creating entry');

        Cleanup(Playbook.Code);
    end;

    [Test]
    procedure CreateOrchestratorEntryCopiesRecurringTemplate()
    var
        Playbook: Record "Playbook ori";
        Entry: Record "Scheduled Entry ori";
        RecurringTemplate: Record "Recurring Template ori";
        EntryId: Guid;
    begin
        // [SCENARIO] Schedule fields are copied from the recurring template
        CreatePlaybook(Playbook, 'SCHED-04');
        CreateRecurringTemplate(RecurringTemplate, 'SCHED-TPL4');

        EntryId := Playbook.CreateOrchestratorEntry(
            RecurringTemplate.Code,
            "Notif. Type ori"::None, '', '', false,
            "Retry Policy ori"::Always);

        Entry.Get(EntryId);
        Assert.IsTrue(Entry."Run on Mondays", 'Run on Mondays should be copied from template');
        Assert.AreEqual(60, Entry."No. of Minutes between Runs", 'Minutes between runs should be copied');
        Assert.AreEqual(RecurringTemplate.Code, Entry."Recurring Template Code", 'Template code should match');

        Cleanup(Playbook.Code);
    end;

    [Test]
    procedure CreateOrchestratorEntrySetsNotification()
    var
        Playbook: Record "Playbook ori";
        Entry: Record "Scheduled Entry ori";
        RecurringTemplate: Record "Recurring Template ori";
        EntryId: Guid;
    begin
        // [SCENARIO] Notification type and recipient are set on the entry
        CreatePlaybook(Playbook, 'SCHED-05');
        CreateRecurringTemplate(RecurringTemplate, 'SCHED-TPL5');

        EntryId := Playbook.CreateOrchestratorEntry(
            RecurringTemplate.Code,
            "Notif. Type ori"::EMail, 'test@example.com', '', false,
            "Retry Policy ori"::Always);

        Entry.Get(EntryId);
        Assert.AreEqual("Notif. Type ori"::EMail, Entry."Notification Type", 'Notification type mismatch');
        Assert.AreEqual('test@example.com', Entry."Notification Recipient", 'Recipient mismatch');

        Cleanup(Playbook.Code);
    end;

    [Test]
    procedure CreateOrchestratorEntrySetsRetryPolicy()
    var
        Playbook: Record "Playbook ori";
        Entry: Record "Scheduled Entry ori";
        RecurringTemplate: Record "Recurring Template ori";
        EntryId: Guid;
    begin
        // [SCENARIO] Retry policy is forwarded to the entry
        CreatePlaybook(Playbook, 'SCHED-06');
        CreateRecurringTemplate(RecurringTemplate, 'SCHED-TPL6');

        EntryId := Playbook.CreateOrchestratorEntry(
            RecurringTemplate.Code,
            "Notif. Type ori"::None, '', '', false,
            "Retry Policy ori"::Never);

        Entry.Get(EntryId);
        Assert.AreEqual("Retry Policy ori"::Never, Entry."Retry Policy", 'Retry policy mismatch');

        Cleanup(Playbook.Code);
    end;

    [Test]
    procedure CreateOrchestratorEntrySetsEmitTelemetry()
    var
        Playbook: Record "Playbook ori";
        Entry: Record "Scheduled Entry ori";
        RecurringTemplate: Record "Recurring Template ori";
        EntryId: Guid;
    begin
        // [SCENARIO] Emit Telemetry flag is forwarded to the entry
        CreatePlaybook(Playbook, 'SCHED-07');
        CreateRecurringTemplate(RecurringTemplate, 'SCHED-TPL7');

        EntryId := Playbook.CreateOrchestratorEntry(
            RecurringTemplate.Code,
            "Notif. Type ori"::None, '', '', true,
            "Retry Policy ori"::Always);

        Entry.Get(EntryId);
        Assert.IsTrue(Entry."Emit Telemetry", 'Emit Telemetry should be true');

        Cleanup(Playbook.Code);
    end;

    [Test]
    procedure CreateOrchestratorEntrySetsJobQueueCategory()
    var
        Playbook: Record "Playbook ori";
        Entry: Record "Scheduled Entry ori";
        RecurringTemplate: Record "Recurring Template ori";
        EntryId: Guid;
    begin
        // [SCENARIO] Job Queue Category Code is forwarded to the entry
        CreatePlaybook(Playbook, 'SCHED-08');
        CreateRecurringTemplate(RecurringTemplate, 'SCHED-TPL8');

        EntryId := Playbook.CreateOrchestratorEntry(
            RecurringTemplate.Code,
            "Notif. Type ori"::None, '', 'NRN-ORCH', false,
            "Retry Policy ori"::Always);

        Entry.Get(EntryId);
        Assert.AreEqual('NRN-ORCH', Format(Entry."Job Queue Category Code"), 'Category mismatch');

        Cleanup(Playbook.Code);
    end;

    [Test]
    procedure CreateOrchestratorEntryBlocksDoubleSchedule()
    var
        Playbook: Record "Playbook ori";
        RecurringTemplate: Record "Recurring Template ori";
    begin
        // [SCENARIO] Scheduling a playbook that is already scheduled errors
        CreatePlaybook(Playbook, 'SCHED-09');
        CreateRecurringTemplate(RecurringTemplate, 'SCHED-TPL9');

        Playbook.CreateOrchestratorEntry(
            RecurringTemplate.Code,
            "Notif. Type ori"::None, '', '', false,
            "Retry Policy ori"::Always);

        Playbook.Get(Playbook.Code);
        asserterror Playbook.CreateOrchestratorEntry(
            RecurringTemplate.Code,
            "Notif. Type ori"::None, '', '', false,
            "Retry Policy ori"::Always);
        Assert.ExpectedErrorCode('Dialog');

        Cleanup(Playbook.Code);
    end;

    [Test]
    procedure CreateOrchestratorEntrySetsRecordIdAndSystemId()
    var
        Playbook: Record "Playbook ori";
        PlaybookFromEntry: Record "Playbook ori";
        Entry: Record "Scheduled Entry ori";
        RecurringTemplate: Record "Recurring Template ori";
        RecRef: RecordRef;
        EntryId: Guid;
    begin
        // [SCENARIO] Record ID to Process and Related Record System Id resolve back to the playbook
        CreatePlaybook(Playbook, 'SCHED-10');
        CreateRecurringTemplate(RecurringTemplate, 'SCHED-TP10');

        EntryId := Playbook.CreateOrchestratorEntry(
            RecurringTemplate.Code,
            "Notif. Type ori"::None, '', '', false,
            "Retry Policy ori"::Always);

        Entry.Get(EntryId);
        RecRef.Get(Entry."Record ID to Process");
        RecRef.SetTable(PlaybookFromEntry);
        Assert.AreEqual(Playbook.Code, PlaybookFromEntry.Code, 'Record ID should resolve to the playbook');
        Assert.AreEqual(Playbook.SystemId, Entry."Related Record System Id", 'System ID should match');

        Cleanup(Playbook.Code);
    end;

    [Test]
    procedure CreateOrchestratorEntryAllowsRescheduleAfterOrphan()
    var
        Playbook: Record "Playbook ori";
        Entry: Record "Scheduled Entry ori";
        RecurringTemplate: Record "Recurring Template ori";
        FirstEntryId: Guid;
        SecondEntryId: Guid;
    begin
        // [SCENARIO] If the orchestrator entry was deleted externally, scheduling again succeeds
        CreatePlaybook(Playbook, 'SCHED-11');
        CreateRecurringTemplate(RecurringTemplate, 'SCHED-TP11');

        FirstEntryId := Playbook.CreateOrchestratorEntry(
            RecurringTemplate.Code,
            "Notif. Type ori"::None, '', '', false,
            "Retry Policy ori"::Always);

        // Simulate external deletion of the orchestrator entry
        Entry.Get(FirstEntryId);
        Entry.Delete(true);

        // Should succeed because the entry no longer exists
        Playbook.Get(Playbook.Code);
        SecondEntryId := Playbook.CreateOrchestratorEntry(
            RecurringTemplate.Code,
            "Notif. Type ori"::None, '', '', false,
            "Retry Policy ori"::Always);

        Assert.AreNotEqual(FirstEntryId, SecondEntryId, 'Should create a new entry');
        Assert.IsTrue(Entry.Get(SecondEntryId), 'New entry should exist');

        Cleanup(Playbook.Code);
    end;

    local procedure CreatePlaybook(var Playbook: Record "Playbook ori"; PlaybookCode: Code[20])
    begin
        if Playbook.Get(PlaybookCode) then begin
            Playbook.Description := 'Schedule test playbook';
            Playbook.Modify(true);
            exit;
        end;
        Playbook.Init();
        Playbook.Code := PlaybookCode;
        Playbook.Description := 'Schedule test playbook';
        Playbook.Insert(true);
    end;

    local procedure CreateRecurringTemplate(var RecurringTemplate: Record "Recurring Template ori"; TemplateCode: Code[20])
    begin
        if RecurringTemplate.Get(TemplateCode) then
            exit;
        RecurringTemplate.Init();
        RecurringTemplate.Code := TemplateCode;
        RecurringTemplate.Description := 'Test template';
        RecurringTemplate."Run on Mondays" := true;
        RecurringTemplate."No. of Minutes between Runs" := 60;
        RecurringTemplate.Insert(true);
    end;

    local procedure Cleanup(PlaybookCode: Code[20])
    var
        Playbook: Record "Playbook ori";
        Entry: Record "Scheduled Entry ori";
    begin
        if Playbook.Get(PlaybookCode) then begin
            if not IsNullGuid(Playbook."Orchestrator Entry ID") then
                if Entry.Get(Playbook."Orchestrator Entry ID") then
                    Entry.Delete(true);
            Playbook.Delete(true);
        end;
        CleanupTemplates();
    end;

    local procedure CleanupTemplates()
    var
        RecurringTemplate: Record "Recurring Template ori";
    begin
        RecurringTemplate.SetFilter(Code, 'SCHED-*');
        RecurringTemplate.DeleteAll(true);
    end;
}
