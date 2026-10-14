namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.Environment;
using System.Threading;

/// <summary>
/// Exercises the Foundation event path for scheduled field restrictions and hints (#62).
/// </summary>
codeunit 96405 "Sched Field Restrict Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    /// <summary>The three governed fields refuse ordinary generic writes.</summary>
    [Test]
    procedure Scenario_AC01_IdentityAndRecipientWritesAreRestricted()
    var
        TempArgument: Record "Message Argument ori" temporary;
        PreviousLanguage: Integer;
    begin
        // Story #62, AC01 | Time: independent of Today/WorkDate | Risk: Foundation restriction events.
        // [GIVEN] A fresh argument, with English hints for exact contract assertions.
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        TempArgument.Insert();
        // [WHEN] The public restriction/hint API raises the real subscribers.
        // [THEN] Only the three governed fields are closed for generic writes.
        Assert.IsTrue(IsFieldRestricted(Database::"Scheduled Entry ori", 140, false), 'Entry run-as must be restricted');
        Assert.IsTrue(IsFieldRestricted(Database::"Scheduled Entry ori", 110, false), 'Recipient must be restricted');
        Assert.IsTrue(IsFieldRestricted(Database::"Scheduler Setup ori", 40, false), 'Setup run-as must be restricted');
        GlobalLanguage(PreviousLanguage);
    end;

    /// <summary>The three governed fields remain readable.</summary>
    [Test]
    procedure Scenario_AC02_IdentityAndRecipientReadsStayOpen()
    var
        TempArgument: Record "Message Argument ori" temporary;
        PreviousLanguage: Integer;
    begin
        // Story #62, AC02 | Time: independent of Today/WorkDate | Risk: Foundation restriction events.
        // [GIVEN] A fresh argument, with English hints for exact contract assertions.
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        TempArgument.Insert();
        // [WHEN] The public restriction/hint API raises the real subscribers.
        // [THEN] Only the three governed fields are closed for generic writes.
        Assert.IsFalse(IsFieldRestricted(Database::"Scheduled Entry ori", 140, true), 'Entry run-as remains readable');
        Assert.IsFalse(IsFieldRestricted(Database::"Scheduled Entry ori", 110, true), 'Recipient remains readable');
        Assert.IsFalse(IsFieldRestricted(Database::"Scheduler Setup ori", 40, true), 'Setup run-as remains readable');
        GlobalLanguage(PreviousLanguage);
    end;

    /// <summary>Neighbour fields and Description retain generic write access.</summary>
    [Test]
    procedure Scenario_AC03_NeighbourFieldsStayWritable()
    var
        TempArgument: Record "Message Argument ori" temporary;
        PreviousLanguage: Integer;
    begin
        // Story #62, AC03 | Time: independent of Today/WorkDate | Risk: Foundation restriction events.
        // [GIVEN] A fresh argument, with English hints for exact contract assertions.
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        TempArgument.Insert();
        // [WHEN] The public restriction/hint API raises the real subscribers.
        // [THEN] Only the three governed fields are closed for generic writes.
        Assert.IsFalse(IsFieldRestricted(Database::"Scheduled Entry ori", 70, false), 'Blocked stays writable');
        Assert.IsFalse(IsFieldRestricted(Database::"Scheduled Entry ori", 90, false), 'Description stays writable');
        Assert.IsFalse(IsFieldRestricted(Database::"Scheduled Entry ori", 280, false), 'Client Credentials Code is outside this scope');
        Assert.IsFalse(IsFieldRestricted(Database::"Scheduler Setup ori", 20, false), 'Setup neighbour 20 stays writable');
        Assert.IsFalse(IsFieldRestricted(Database::"Scheduler Setup ori", 50, false), 'Setup neighbour 50 stays writable');
        GlobalLanguage(PreviousLanguage);
    end;

    /// <summary>Field restrictions do not restrict either whole table.</summary>
    [Test]
    procedure Scenario_AC04_TablesStayReadableAndWritable()
    var
        TempArgument: Record "Message Argument ori" temporary;
        PreviousLanguage: Integer;
    begin
        // Story #62, AC04 | Time: independent of Today/WorkDate | Risk: Foundation restriction events.
        // [GIVEN] A fresh argument, with English hints for exact contract assertions.
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        TempArgument.Insert();
        // [WHEN] The public restriction/hint API raises the real subscribers.
        // [THEN] Only the three governed fields are closed for generic writes.
        Assert.IsFalse(TempArgument.IsTableWriteRestrictedForDataRecords(Database::"Scheduled Entry ori", false), 'Entry table stays writable');
        Assert.IsFalse(TempArgument.IsTableWriteRestrictedForDataRecords(Database::"Scheduler Setup ori", false), 'Setup table stays writable');
        Assert.IsFalse(TempArgument.IsTableReadRestrictedForDataRecords(Database::"Scheduled Entry ori"), 'Entry table stays readable');
        Assert.IsFalse(TempArgument.IsTableReadRestrictedForDataRecords(Database::"Scheduler Setup ori"), 'Setup table stays readable');
        GlobalLanguage(PreviousLanguage);
    end;

    /// <summary>Each restricted field has its documented supported editing path.</summary>
    [Test]
    procedure Scenario_AC05_HintsNameSupportedPagesAndSchedule()
    var
        TempArgument: Record "Message Argument ori" temporary;
        PreviousLanguage: Integer;
    begin
        // Story #62, AC05 | Time: independent of Today/WorkDate | Risk: Foundation restriction events.
        // [GIVEN] A fresh argument, with English hints for exact contract assertions.
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        TempArgument.Insert();
        // [WHEN] The public restriction/hint API raises the real subscribers.
        // [THEN] Only the three governed fields are closed for generic writes.
        Assert.AreEqual('the Scheduled Entry card (Job Queue User ID)', TempArgument.GetDedicatedMessageTypeHintForField(Database::"Scheduled Entry ori", 140), 'Entry run-as hint');
        Assert.AreEqual('the Scheduler Setup page (Job Queue User ID)', TempArgument.GetDedicatedMessageTypeHintForField(Database::"Scheduler Setup ori", 40), 'Setup run-as hint');
        Assert.AreEqual('Orchestrator.Playbook.Schedule (notificationRecipient) or the Scheduled Entry card (Notification Recipient)', TempArgument.GetDedicatedMessageTypeHintForField(Database::"Scheduled Entry ori", 110), 'Recipient hint names only the type that accepts it');
        GlobalLanguage(PreviousLanguage);
    end;

    /// <summary>Unrelated fields do not acquire a scheduling restriction hint.</summary>
    [Test]
    procedure Scenario_AC05_NeighboursHaveNoNewHints()
    var
        TempArgument: Record "Message Argument ori" temporary;
        PreviousLanguage: Integer;
    begin
        // Story #62, AC05 | Time: independent of Today/WorkDate | Risk: Foundation restriction events.
        // [GIVEN] A fresh argument, with English hints for exact contract assertions.
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        TempArgument.Insert();
        // [WHEN] The public restriction/hint API raises the real subscribers.
        // [THEN] Only the three governed fields are closed for generic writes.
        Assert.AreEqual('', TempArgument.GetDedicatedMessageTypeHintForField(Database::"Scheduled Entry ori", 90), 'No description hint');
        Assert.AreEqual('', TempArgument.GetDedicatedMessageTypeHintForField(Database::"Scheduled Entry ori", 280), 'No credentials code hint');
        Assert.AreEqual('', TempArgument.GetDedicatedMessageTypeHintForField(Database::"Scheduler Setup ori", 20), 'No setup neighbour hint');
        GlobalLanguage(PreviousLanguage);
    end;

    /// <summary>The existing table and field companion hints retain their exact values.</summary>
    [Test]
    procedure Scenario_AC05_ExistingCompanionHintsArePreserved()
    var
        TempArgument: Record "Message Argument ori" temporary;
        PreviousLanguage: Integer;
    begin
        // Story #62, AC05 | Time: independent of Today/WorkDate | Risk: Foundation restriction events.
        // [GIVEN] A fresh argument, with English hints for exact contract assertions.
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        TempArgument.Insert();
        // [WHEN] The public restriction/hint API raises the real subscribers.
        // [THEN] Only the three governed fields are closed for generic writes.
        Assert.AreEqual('Orchestrator.Entry.Register / Orchestrator.Entry.Schedule / Orchestrator.JobQueueEntry.Restart', TempArgument.GetDedicatedMessageTypeHintForField(Database::"Job Queue Entry", 1), 'Job Queue Entry field hint');
        Assert.AreEqual('Orchestrator.Status.Restart', TempArgument.GetDedicatedMessageTypeHintForField(Database::"Scheduled Task", 1), 'Scheduled Task field hint');
        Assert.AreEqual('Orchestrator.Report.Get / Orchestrator.Report.Run / Orchestrator.Report.SaveAs', TempArgument.GetDedicatedMessageTypeHintForField(Database::"Report Request Preset ori", 1), 'Report preset field hint');
        Assert.AreEqual('Orchestrator.Entry.Register / Orchestrator.Entry.Schedule / Orchestrator.JobQueueEntry.Restart', TempArgument.GetDedicatedMessageTypeHintForWrite(Database::"Job Queue Entry"), 'Job Queue Entry table hint');
        Assert.AreEqual('Orchestrator.Status.Restart', TempArgument.GetDedicatedMessageTypeHintForWrite(Database::"Scheduled Task"), 'Scheduled Task table hint');
        Assert.AreEqual('Orchestrator.Report.Get / Orchestrator.Report.Run / Orchestrator.Report.SaveAs', TempArgument.GetDedicatedMessageTypeHintForWrite(Database::"Report Request Preset ori"), 'Report preset table hint');
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure IsFieldRestricted(TableNo: Integer; FieldNo: Integer; ForRead: Boolean): Boolean
    var
        TempArgument: Record "Message Argument ori" temporary;
        MessageType: Enum "Message Type ori";
        MessageImpl: Interface "Msg Interface ori";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        FieldNumbers: JsonArray;
        Token: JsonToken;
        FieldJson: JsonObject;
    begin
        // Help.Fields.Get calls Foundation's same internal restriction decision as Data.Records.
        // The public enum/interface avoids access to internal Foundation methods or friend apps.
        TempArgument.Insert();
        TempArgument.Subject := Format(TableNo, 0, 9);
        FieldNumbers.Add(FieldNo);
        RequestJson.Add('fieldNumbers', FieldNumbers);
        TempArgument.SetRequestJson(RequestJson);
        MessageType := MessageType::"Help.Fields.Get";
        MessageImpl := MessageType;
        MessageImpl.ExecuteBifrostTask(TempArgument);
        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('status', Token);
        Assert.AreEqual('Success', Token.AsValue().AsText(), 'Field discovery must succeed');
        ResponseJson.Get('result', Token);
        Assert.AreEqual(1, Token.AsArray().Count(), 'The requested field must exist');
        Token.AsArray().Get(0, Token);
        FieldJson := Token.AsObject();
        FieldJson.Get('id', Token);
        Assert.AreEqual(FieldNo, Token.AsValue().AsInteger(), 'Discovery must return the requested field');
        if ForRead then
            FieldJson.Get('readRestricted', Token)
        else
            FieldJson.Get('writeRestricted', Token);
        exit(Token.AsValue().AsBoolean());
    end;
}
