namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
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
        EntrySystemId: Guid;
        EntryPkId: Guid;
    begin
        // [SCENARIO] CreateOrchestratorEntry inserts an orchestrator entry for the playbook
        CreatePlaybook(Playbook, 'SCHED-01');
        CreateRecurringTemplate(RecurringTemplate, 'SCHED-TPL1');

        EntrySystemId := Playbook.CreateOrchestratorEntry(
            RecurringTemplate.Code,
            "Notif. Type ori"::None, '', '', false,
            "Retry Policy ori"::Always, EntryPkId);

        Assert.IsTrue(Entry.Get(EntryPkId), 'Orchestrator entry should exist by PK');
        Assert.AreEqual(EntrySystemId, Entry.SystemId, 'Return value should be SystemId');
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
        EntrySystemId: Guid;
        EntryPkId: Guid;
    begin
        // [SCENARIO] The orchestrator entry primary-key ID is stored on the playbook record
        CreatePlaybook(Playbook, 'SCHED-02');
        CreateRecurringTemplate(RecurringTemplate, 'SCHED-TPL2');

        EntrySystemId := Playbook.CreateOrchestratorEntry(
            RecurringTemplate.Code,
            "Notif. Type ori"::None, '', '', false,
            "Retry Policy ori"::Always, EntryPkId);

        Playbook.Get(Playbook.Code);
        Assert.AreEqual(EntryPkId, Playbook."Orchestrator Entry ID", 'Playbook should store the entry PK');
        Assert.AreNotEqual(EntrySystemId, EntryPkId, 'SystemId and PK should differ');

        Cleanup(Playbook.Code);
    end;

    [Test]
    procedure ScheduledFlowFieldReflectsOrchestratorEntry()
    var
        Playbook: Record "Playbook ori";
        RecurringTemplate: Record "Recurring Template ori";
        EntryPkId: Guid;
    begin
        // [SCENARIO] Scheduled FlowField returns true when orchestrator entry exists
        CreatePlaybook(Playbook, 'SCHED-03');
        CreateRecurringTemplate(RecurringTemplate, 'SCHED-TPL3');

        Playbook.CalcFields(Scheduled);
        Assert.IsFalse(Playbook.Scheduled, 'Should not be scheduled before creating entry');

        Playbook.CreateOrchestratorEntry(
            RecurringTemplate.Code,
            "Notif. Type ori"::None, '', '', false,
            "Retry Policy ori"::Always, EntryPkId);

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
        EntrySystemId: Guid;
        EntryPkId: Guid;
    begin
        // [SCENARIO] Schedule fields are copied from the recurring template
        CreatePlaybook(Playbook, 'SCHED-04');
        CreateRecurringTemplate(RecurringTemplate, 'SCHED-TPL4');

        EntrySystemId := Playbook.CreateOrchestratorEntry(
            RecurringTemplate.Code,
            "Notif. Type ori"::None, '', '', false,
            "Retry Policy ori"::Always, EntryPkId);

        Entry.Get(EntryPkId);
        Assert.AreEqual(EntrySystemId, Entry.SystemId, 'Return value should be SystemId');
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
        EntryPkId: Guid;
    begin
        // [SCENARIO] Notification type and recipient are set on the entry
        CreatePlaybook(Playbook, 'SCHED-05');
        CreateRecurringTemplate(RecurringTemplate, 'SCHED-TPL5');

        Playbook.CreateOrchestratorEntry(
            RecurringTemplate.Code,
            "Notif. Type ori"::EMail, 'test@example.com', '', false,
            "Retry Policy ori"::Always, EntryPkId);

        Entry.Get(EntryPkId);
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
        EntryPkId: Guid;
    begin
        // [SCENARIO] Retry policy is forwarded to the entry
        CreatePlaybook(Playbook, 'SCHED-06');
        CreateRecurringTemplate(RecurringTemplate, 'SCHED-TPL6');

        Playbook.CreateOrchestratorEntry(
            RecurringTemplate.Code,
            "Notif. Type ori"::None, '', '', false,
            "Retry Policy ori"::Never, EntryPkId);

        Entry.Get(EntryPkId);
        Assert.AreEqual("Retry Policy ori"::Never, Entry."Retry Policy", 'Retry policy mismatch');

        Cleanup(Playbook.Code);
    end;

    [Test]
    procedure CreateOrchestratorEntrySetsEmitTelemetry()
    var
        Playbook: Record "Playbook ori";
        Entry: Record "Scheduled Entry ori";
        RecurringTemplate: Record "Recurring Template ori";
        EntryPkId: Guid;
    begin
        // [SCENARIO] Emit Telemetry flag is forwarded to the entry
        CreatePlaybook(Playbook, 'SCHED-07');
        CreateRecurringTemplate(RecurringTemplate, 'SCHED-TPL7');

        Playbook.CreateOrchestratorEntry(
            RecurringTemplate.Code,
            "Notif. Type ori"::None, '', '', true,
            "Retry Policy ori"::Always, EntryPkId);

        Entry.Get(EntryPkId);
        Assert.IsTrue(Entry."Emit Telemetry", 'Emit Telemetry should be true');

        Cleanup(Playbook.Code);
    end;

    [Test]
    procedure CreateOrchestratorEntrySetsJobQueueCategory()
    var
        Playbook: Record "Playbook ori";
        Entry: Record "Scheduled Entry ori";
        RecurringTemplate: Record "Recurring Template ori";
        EntryPkId: Guid;
    begin
        // [SCENARIO] Job Queue Category Code is forwarded to the entry
        CreatePlaybook(Playbook, 'SCHED-08');
        CreateRecurringTemplate(RecurringTemplate, 'SCHED-TPL8');

        Playbook.CreateOrchestratorEntry(
            RecurringTemplate.Code,
            "Notif. Type ori"::None, '', 'NRN-ORCH', false,
            "Retry Policy ori"::Always, EntryPkId);

        Entry.Get(EntryPkId);
        Assert.AreEqual('NRN-ORCH', Format(Entry."Job Queue Category Code"), 'Category mismatch');

        Cleanup(Playbook.Code);
    end;

    [Test]
    procedure CreateOrchestratorEntryBlocksDoubleSchedule()
    var
        Playbook: Record "Playbook ori";
        RecurringTemplate: Record "Recurring Template ori";
        EntryPkId: Guid;
    begin
        // [SCENARIO] Scheduling a playbook that is already scheduled errors
        CreatePlaybook(Playbook, 'SCHED-09');
        CreateRecurringTemplate(RecurringTemplate, 'SCHED-TPL9');

        Playbook.CreateOrchestratorEntry(
            RecurringTemplate.Code,
            "Notif. Type ori"::None, '', '', false,
            "Retry Policy ori"::Always, EntryPkId);

        Playbook.Get(Playbook.Code);
        asserterror Playbook.CreateOrchestratorEntry(
            RecurringTemplate.Code,
            "Notif. Type ori"::None, '', '', false,
            "Retry Policy ori"::Always, EntryPkId);
        Assert.ExpectedErrorCode('Dialog');

        Cleanup(Playbook.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    procedure CreateOrchestratorEntrySetsRecordIdAndSystemId()
    var
        Playbook: Record "Playbook ori";
        PlaybookFromEntry: Record "Playbook ori";
        Entry: Record "Scheduled Entry ori";
        RecurringTemplate: Record "Recurring Template ori";
        TempArgument: Record "Message Argument ori" temporary;
        TempArgumentByPk: Record "Message Argument ori" temporary;
        TempArgumentUnknown: Record "Message Argument ori" temporary;
        Handler: Codeunit "SE Msg Handler ori";
        RecRef: RecordRef;
        ResponseJson: JsonObject;
        Token: JsonToken;
        EntrySystemId: Guid;
        EntryPkId: Guid;
        UnknownId: Guid;
    begin
        // [SCENARIO] Record ID / SystemId are set; both IDs round-trip through Entry.Run; unknown GUID errors
        CreatePlaybook(Playbook, 'SCHED-10');
        CreateRecurringTemplate(RecurringTemplate, 'SCHED-TP10');

        EntrySystemId := Playbook.CreateOrchestratorEntry(
            RecurringTemplate.Code,
            "Notif. Type ori"::None, '', '', false,
            "Retry Policy ori"::Always, EntryPkId);

        Entry.Get(EntryPkId);
        Assert.AreEqual(EntrySystemId, Entry.SystemId, 'Return value should be SystemId');
        Assert.AreEqual(EntryPkId, Entry.ID, 'Out-param should be primary key');
        Assert.AreNotEqual(EntrySystemId, EntryPkId, 'SystemId and PK must both be present and distinct');

        RecRef.Get(Entry."Record ID to Process");
        RecRef.SetTable(PlaybookFromEntry);
        Assert.AreEqual(Playbook.Code, PlaybookFromEntry.Code, 'Record ID should resolve to the playbook');
        Assert.AreEqual(Playbook.SystemId, Entry."Related Record System Id", 'System ID should match');

        // TC001: Entry.Run with SystemId (orchestratorEntryId) succeeds
        CreateArgument(TempArgument, '{"id": "' + Format(EntrySystemId, 0, 4) + '"}');
        Handler.ExecuteRun(TempArgument);
        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('status', Token);
        Assert.AreEqual('Success', Token.AsValue().AsText(), 'Entry.Run with SystemId should succeed');
        ResponseJson.Get('id', Token);
        Assert.AreEqual(Format(EntrySystemId, 0, 4), Token.AsValue().AsText(), 'Response id should be SystemId');

        // TC002: Entry.Run with PK (orchestratorEntryPkId) succeeds via FindEntry fallback
        CreateArgument(TempArgumentByPk, '{"id": "' + Format(EntryPkId, 0, 4) + '"}');
        Handler.ExecuteRun(TempArgumentByPk);
        ResponseJson := TempArgumentByPk.GetResponseJson();
        ResponseJson.Get('status', Token);
        Assert.AreEqual('Success', Token.AsValue().AsText(), 'Entry.Run with PK should succeed via fallback');
        ResponseJson.Get('id', Token);
        Assert.AreEqual(Format(EntrySystemId, 0, 4), Token.AsValue().AsText(), 'Response id should still be SystemId');

        // TC003: unknown GUID still errors
        UnknownId := CreateGuid();
        CreateArgument(TempArgumentUnknown, '{"id": "' + Format(UnknownId, 0, 4) + '"}');
        asserterror Handler.ExecuteRun(TempArgumentUnknown);
        Assert.ExpectedError('does not exist');

        Cleanup(Playbook.Code);
    end;

    [Test]
    procedure CreateOrchestratorEntryAllowsRescheduleAfterOrphan()
    var
        Playbook: Record "Playbook ori";
        Entry: Record "Scheduled Entry ori";
        RecurringTemplate: Record "Recurring Template ori";
        FirstEntrySystemId: Guid;
        FirstEntryPkId: Guid;
        SecondEntrySystemId: Guid;
        SecondEntryPkId: Guid;
    begin
        // [SCENARIO] If the orchestrator entry was deleted externally, scheduling again succeeds
        CreatePlaybook(Playbook, 'SCHED-11');
        CreateRecurringTemplate(RecurringTemplate, 'SCHED-TP11');

        FirstEntrySystemId := Playbook.CreateOrchestratorEntry(
            RecurringTemplate.Code,
            "Notif. Type ori"::None, '', '', false,
            "Retry Policy ori"::Always, FirstEntryPkId);

        // Simulate external deletion of the orchestrator entry
        Entry.Get(FirstEntryPkId);
        Entry.Delete(true);

        // Should succeed because the entry no longer exists
        Playbook.Get(Playbook.Code);
        SecondEntrySystemId := Playbook.CreateOrchestratorEntry(
            RecurringTemplate.Code,
            "Notif. Type ori"::None, '', '', false,
            "Retry Policy ori"::Always, SecondEntryPkId);

        Assert.AreNotEqual(FirstEntryPkId, SecondEntryPkId, 'Should create a new entry PK');
        Assert.AreNotEqual(FirstEntrySystemId, SecondEntrySystemId, 'Should create a new SystemId');
        Assert.IsTrue(Entry.Get(SecondEntryPkId), 'New entry should exist');

        Cleanup(Playbook.Code);
    end;

    [Test]
    procedure ScheduleResponseEmitsSystemIdAndPkId()
    var
        Playbook: Record "Playbook ori";
        Entry: Record "Scheduled Entry ori";
        RecurringTemplate: Record "Recurring Template ori";
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Playbook Msg Handler ori";
        ResponseJson: JsonObject;
        Token: JsonToken;
        ResponseSystemId: Guid;
        ResponsePkId: Guid;
    begin
        // [SCENARIO] Playbook.Schedule returns orchestratorEntryId=SystemId and orchestratorEntryPkId=PK
        CreatePlaybook(Playbook, 'SCHED-12');
        CreateRecurringTemplate(RecurringTemplate, 'SCHED-TP12');

        CreateArgument(
            TempArgument,
            '{"playbookCode": "' + Playbook.Code + '", "recurringTemplateCode": "' + RecurringTemplate.Code + '"}');
        Handler.ExecuteSchedule(TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('status', Token);
        Assert.AreEqual('Success', Token.AsValue().AsText(), 'Schedule should succeed');
        Assert.IsTrue(ResponseJson.Contains('orchestratorEntryId'), 'Missing orchestratorEntryId');
        Assert.IsTrue(ResponseJson.Contains('orchestratorEntryPkId'), 'Missing orchestratorEntryPkId');

        ResponseJson.Get('orchestratorEntryId', Token);
        Evaluate(ResponseSystemId, Token.AsValue().AsText());
        ResponseJson.Get('orchestratorEntryPkId', Token);
        Evaluate(ResponsePkId, Token.AsValue().AsText());

        Entry.Get(ResponsePkId);
        Assert.AreEqual(Entry.SystemId, ResponseSystemId, 'orchestratorEntryId must be SystemId');
        Assert.AreEqual(Entry.ID, ResponsePkId, 'orchestratorEntryPkId must be PK');
        Assert.AreNotEqual(ResponseSystemId, ResponsePkId, 'Both IDs must be consistent and distinct');

        Cleanup(Playbook.Code);
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    local procedure CreateArgument(var TempArgument: Record "Message Argument ori" temporary; RequestJsonText: Text)
    var
        RequestJson: JsonObject;
    begin
        TempArgument.Init();
        TempArgument.Insert();
        RequestJson.ReadFrom(RequestJsonText);
        TempArgument.SetRequestJson(RequestJson);
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
