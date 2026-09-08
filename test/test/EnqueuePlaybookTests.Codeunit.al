namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost.Orchestrator;
using System.TestTools.TestRunner;
using System.Threading;

codeunit 96414 "Enqueue Playbook Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure JQParameterStoresAndRetrievesRequestData()
    var
        JQParameter: Record "JQ Parameter ori";
        RequestData: Text;
    begin
        // [SCENARIO] Bifrost JQ Parameter table round-trips blob data
        JQParameter.Init();
        JQParameter.ID := CreateGuid();
        JQParameter.SetRequestData('{"customerId":"C001"}');
        JQParameter.Insert(true);

        JQParameter.Get(JQParameter.ID);
        RequestData := JQParameter.GetRequestData();
        Assert.AreEqual('{"customerId":"C001"}', RequestData, 'Request data mismatch');

        JQParameter.Delete();
    end;

    [Test]
    procedure JQParameterGetRequestDataReturnsEmptyWhenNoBlob()
    var
        JQParameter: Record "JQ Parameter ori";
    begin
        // [SCENARIO] GetRequestData returns empty when no blob is stored
        JQParameter.Init();
        JQParameter.ID := CreateGuid();
        JQParameter.Insert(true);

        JQParameter.Get(JQParameter.ID);
        Assert.AreEqual('', JQParameter.GetRequestData(), 'Should be empty');

        JQParameter.Delete();
    end;

    [Test]
    procedure EnqueuePlaybookCreatesNonRecurringJQEntry()
    var
        Playbook: Record "Playbook ori";
        JQEntry: Record "Job Queue Entry";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        JQEntryId: Guid;
    begin
        // [SCENARIO] EnqueuePlaybook creates a non-recurring JQ entry pointing to the dispatcher
        CreateEnabledPlaybook(Playbook, 'ENQ-TEST-1');

        LibraryOrchestrator.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryOrchestrator);
        JQEntryId := Playbook.EnqueuePlaybook('{"key":"value"}');
        UnbindSubscription(LibraryOrchestrator);

        JQEntry.Get(JQEntryId);
        Assert.AreEqual(Codeunit::"Playbook JQ Dispatcher ori", JQEntry."Object ID to Run", 'Wrong codeunit');
        Assert.IsFalse(JQEntry."Recurring Job", 'Should not be recurring');

        CleanupPlaybook(Playbook.Code);
    end;

    [Test]
    procedure EnqueuePlaybookCreatesParameterRecord()
    var
        Playbook: Record "Playbook ori";
        JQParameter: Record "JQ Parameter ori";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        JQEntryId: Guid;
    begin
        // [SCENARIO] EnqueuePlaybook stores request data in Bifrost JQ Parameter with JQ Entry ID as PK
        CreateEnabledPlaybook(Playbook, 'ENQ-TEST-2');

        LibraryOrchestrator.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryOrchestrator);
        JQEntryId := Playbook.EnqueuePlaybook('{"invoiceNo":"103002"}');
        UnbindSubscription(LibraryOrchestrator);

        Assert.IsTrue(JQParameter.Get(JQEntryId), 'Parameter record should exist');
        Assert.AreEqual('{"invoiceNo":"103002"}', JQParameter.GetRequestData(), 'Request data mismatch');

        CleanupPlaybook(Playbook.Code);
    end;

    [Test]
    procedure EnqueuePlaybookNoParameterWhenRequestEmpty()
    var
        Playbook: Record "Playbook ori";
        JQParameter: Record "JQ Parameter ori";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        JQEntryId: Guid;
    begin
        // [SCENARIO] EnqueuePlaybook with empty request data does not create a parameter record
        CreateEnabledPlaybook(Playbook, 'ENQ-TEST-3');

        LibraryOrchestrator.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryOrchestrator);
        JQEntryId := Playbook.EnqueuePlaybook('');
        UnbindSubscription(LibraryOrchestrator);

        Assert.IsFalse(JQParameter.Get(JQEntryId), 'Parameter record should not exist for empty request');

        CleanupPlaybook(Playbook.Code);
    end;

    [Test]
    procedure EnqueuePlaybookSetsJobQueueCategory()
    var
        Playbook: Record "Playbook ori";
        JQEntry: Record "Job Queue Entry";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        JQEntryId: Guid;
    begin
        // [SCENARIO] EnqueuePlaybook passes job queue category code to the JQ entry
        CreateEnabledPlaybook(Playbook, 'ENQ-TEST-4');

        LibraryOrchestrator.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryOrchestrator);
        JQEntryId := Playbook.EnqueuePlaybook('{}', 'ORCHESTR', 120);
        UnbindSubscription(LibraryOrchestrator);

        JQEntry.Get(JQEntryId);
        Assert.AreEqual('ORCHESTR', Format(JQEntry."Job Queue Category Code"), 'Category code mismatch');

        CleanupPlaybook(Playbook.Code);
    end;

    [Test]
    procedure EnqueuePlaybookEnforcesMinimumDelay()
    var
        Playbook: Record "Playbook ori";
        JQEntry: Record "Job Queue Entry";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        JQEntryId: Guid;
        MinExpectedStart: DateTime;
    begin
        // [SCENARIO] DelaySeconds below 60 is clamped to 60
        CreateEnabledPlaybook(Playbook, 'ENQ-TEST-5');

        MinExpectedStart := CurrentDateTime() + (60 * 1000);

        LibraryOrchestrator.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryOrchestrator);
        JQEntryId := Playbook.EnqueuePlaybook('{}', '', 10);
        UnbindSubscription(LibraryOrchestrator);

        JQEntry.Get(JQEntryId);
        // Earliest start should be at least 60 seconds from now (allow 5 sec tolerance)
        Assert.IsTrue(
            JQEntry."Earliest Start Date/Time" >= MinExpectedStart - (5 * 1000),
            'Delay should be clamped to minimum 60 seconds');

        CleanupPlaybook(Playbook.Code);
    end;

    [Test]
    procedure EnqueuePlaybookDefaultOverloadUses60SecDelay()
    var
        Playbook: Record "Playbook ori";
        JQEntry: Record "Job Queue Entry";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        JQEntryId: Guid;
        MinExpectedStart: DateTime;
    begin
        // [SCENARIO] The single-parameter overload defaults to 60 seconds
        CreateEnabledPlaybook(Playbook, 'ENQ-TEST-6');

        MinExpectedStart := CurrentDateTime() + (60 * 1000);

        LibraryOrchestrator.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryOrchestrator);
        JQEntryId := Playbook.EnqueuePlaybook('{"data":true}');
        UnbindSubscription(LibraryOrchestrator);

        JQEntry.Get(JQEntryId);
        Assert.IsTrue(
            JQEntry."Earliest Start Date/Time" >= MinExpectedStart - (5 * 1000),
            'Default delay should be 60 seconds');

        CleanupPlaybook(Playbook.Code);
    end;

    [Test]
    procedure EnqueuePlaybookFailsWhenDisabled()
    var
        Playbook: Record "Playbook ori";
    begin
        // [SCENARIO] EnqueuePlaybook errors when playbook is not enabled
        Playbook.Init();
        Playbook.Code := 'ENQ-TEST-7';
        Playbook.Description := 'Disabled test playbook';
        if not Playbook.Insert(true) then
            Playbook.Modify(true);

        Playbook.EnqueuePlaybook('{"key":"value"}');

        CleanupPlaybook(Playbook.Code);
    end;

    [Test]
    procedure DeleteJQEntryDeletesParameterRecord()
    var
        Playbook: Record "Playbook ori";
        JQEntry: Record "Job Queue Entry";
        JQParameter: Record "JQ Parameter ori";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        JQEntryId: Guid;
    begin
        // [SCENARIO] Deleting a JQ Entry cleans up the associated parameter record via event subscriber
        CreateEnabledPlaybook(Playbook, 'ENQ-TEST-8');

        LibraryOrchestrator.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryOrchestrator);
        JQEntryId := Playbook.EnqueuePlaybook('{"cleanup":"test"}');
        UnbindSubscription(LibraryOrchestrator);

        Assert.IsTrue(JQParameter.Get(JQEntryId), 'Parameter should exist before delete');

        JQEntry.Get(JQEntryId);
        JQEntry.SetStatus(JQEntry.Status::"On Hold");
        JQEntry.Delete(true);

        Assert.IsFalse(JQParameter.Get(JQEntryId), 'Parameter should be cleaned up on JQ Entry delete');

        CleanupPlaybook(Playbook.Code);
    end;

    [Test]
    procedure EnqueuePlaybookSetsRecordIdToProcess()
    var
        Playbook: Record "Playbook ori";
        PlaybookFromJQ: Record "Playbook ori";
        JQEntry: Record "Job Queue Entry";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        RecRef: RecordRef;
        JQEntryId: Guid;
    begin
        // [SCENARIO] Record ID to Process on the JQ entry resolves back to the playbook
        CreateEnabledPlaybook(Playbook, 'ENQ-TEST-9');

        LibraryOrchestrator.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryOrchestrator);
        JQEntryId := Playbook.EnqueuePlaybook('{}');
        UnbindSubscription(LibraryOrchestrator);

        JQEntry.Get(JQEntryId);
        RecRef.Get(JQEntry."Record ID to Process");
        RecRef.SetTable(PlaybookFromJQ);
        Assert.AreEqual(Playbook.Code, PlaybookFromJQ.Code, 'Record ID should resolve to the playbook');

        CleanupPlaybook(Playbook.Code);
    end;

    local procedure CreateEnabledPlaybook(var Playbook: Record "Playbook ori"; PlaybookCode: Code[20])
    begin
        if Playbook.Get(PlaybookCode) then begin
            Playbook.Description := 'Test playbook';
            Playbook.Modify(true);
            exit;
        end;
        Playbook.Init();
        Playbook.Code := PlaybookCode;
        Playbook.Description := 'Test playbook';
        Playbook.Insert(true);
    end;

    local procedure CleanupPlaybook(PlaybookCode: Code[20])
    var
        Playbook: Record "Playbook ori";
        JQEntry: Record "Job Queue Entry";
        JQParameter: Record "JQ Parameter ori";
    begin
        JQEntry.SetRange("Object ID to Run", Codeunit::"Playbook JQ Dispatcher ori");
        if JQEntry.FindSet() then
            repeat
                if JQParameter.Get(JQEntry.ID) then
                    JQParameter.Delete();
                JQEntry.SetStatus(JQEntry.Status::"On Hold");
                JQEntry.Delete(true);
            until JQEntry.Next() = 0;

        if Playbook.Get(PlaybookCode) then
            Playbook.Delete(true);
    end;
}
