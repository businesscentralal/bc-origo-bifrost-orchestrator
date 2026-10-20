namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>
/// Contract and discovery conformance tests for Batch 1 message types.
/// </summary>
codeunit 96452 "Orch B1 Contract Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure Batch1MessagesHaveContractChaptersAndDiscovery()
    begin
        AssertContract("Message Type ori"::"Orchestrator.Entry.Run", 'Orchestrator.Entry.Run');
        AssertContract("Message Type ori"::"Orchestrator.Entry.Restart", 'Orchestrator.Entry.Restart');
        AssertContract("Message Type ori"::"Orchestrator.Entry.Register", 'Orchestrator.Entry.Register');
        AssertContract("Message Type ori"::"Orchestrator.Entry.Schedule", 'Orchestrator.Entry.Schedule');
        AssertContract("Message Type ori"::"Orchestrator.Status.Get", 'Orchestrator.Status.Get');
        AssertContract("Message Type ori"::"Orchestrator.Status.Restart", 'Orchestrator.Status.Restart');
        AssertContract("Message Type ori"::"Orchestrator.Status.RestartIfNeeded", 'Orchestrator.Status.RestartIfNeeded');
        AssertContract("Message Type ori"::"Orchestrator.Playbook.Run", 'Orchestrator.Playbook.Run');
        AssertContract("Message Type ori"::"Orchestrator.Playbook.Schedule", 'Orchestrator.Playbook.Schedule');
        AssertContract("Message Type ori"::"Orchestrator.Playbook.Enqueue", 'Orchestrator.Playbook.Enqueue');
        AssertContract("Message Type ori"::"Orchestrator.Playbook.Verify", 'Orchestrator.Playbook.Verify');
        AssertContract("Message Type ori"::"Orchestrator.JobQueueEntry.Restart", 'Orchestrator.JobQueueEntry.Restart');
        AssertContract("Message Type ori"::"Orchestrator.JobQueueEntry.RestartIfNeeded", 'Orchestrator.JobQueueEntry.RestartIfNeeded');
        AssertContract("Message Type ori"::"Help.Orchestrator.Get", 'Help.Orchestrator.Get');
        AssertContract("Message Type ori"::"Orchestrator.Email.Send", 'Orchestrator.Email.Send');
        AssertContract("Message Type ori"::"Orchestrator.Telegram.Message", 'Orchestrator.Telegram.Message');
    end;

    [Test]
    procedure CommittingTypesDeclareIrreversible()
    begin
        // [SCENARIO #60] Types that commit on their execute path declare effect irreversible
        AssertEffect("Message Type ori"::"Orchestrator.Playbook.Run", 'Orchestrator.Playbook.Run', 'irreversible', true);
        AssertEffect("Message Type ori"::"Orchestrator.Entry.Run", 'Orchestrator.Entry.Run', 'irreversible', true);
        AssertEffect("Message Type ori"::"Orchestrator.Entry.Register", 'Orchestrator.Entry.Register', 'irreversible', true);
        AssertEffect("Message Type ori"::"Orchestrator.Status.Restart", 'Orchestrator.Status.Restart', 'irreversible', true);
        AssertEffect("Message Type ori"::"Orchestrator.Status.RestartIfNeeded", 'Orchestrator.Status.RestartIfNeeded', 'irreversible', true);
        AssertEffect("Message Type ori"::"Orchestrator.Entry.Restart", 'Orchestrator.Entry.Restart', 'irreversible', true);
        AssertEffect("Message Type ori"::"Orchestrator.Entry.Schedule", 'Orchestrator.Entry.Schedule', 'irreversible', true);
    end;

    [Test]
    procedure NonCommittingTypesKeepTheirEffect()
    begin
        // [SCENARIO #60] Types without a commit on their execute path keep write or read; external writes stay irreversible
        AssertEffect("Message Type ori"::"Orchestrator.Playbook.Schedule", 'Orchestrator.Playbook.Schedule', 'write', false);
        AssertEffect("Message Type ori"::"Orchestrator.Playbook.Enqueue", 'Orchestrator.Playbook.Enqueue', 'write', false);
        AssertEffect("Message Type ori"::"Orchestrator.JobQueueEntry.Restart", 'Orchestrator.JobQueueEntry.Restart', 'write', false);
        AssertEffect("Message Type ori"::"Orchestrator.JobQueueEntry.RestartIfNeeded", 'Orchestrator.JobQueueEntry.RestartIfNeeded', 'write', false);
        AssertEffect("Message Type ori"::"Orchestrator.Email.Send", 'Orchestrator.Email.Send', 'irreversible', false);
        AssertEffect("Message Type ori"::"Orchestrator.Telegram.Message", 'Orchestrator.Telegram.Message', 'irreversible', false);
        AssertEffect("Message Type ori"::"Orchestrator.Status.Get", 'Orchestrator.Status.Get', 'read', false);
        AssertEffect("Message Type ori"::"Help.Orchestrator.Get", 'Help.Orchestrator.Get', 'read', false);
        AssertEffect("Message Type ori"::"Orchestrator.Playbook.Verify", 'Orchestrator.Playbook.Verify', 'read', false);
    end;

    /// <summary>Preserves every field and position of the main choice entry.</summary>
    [Test]
    procedure Scenario_AC05_NotificationType_KeepsMainContract()
    begin
        // Story #68, AC05 | Time: independent of Today/WorkDate | Risk: #71 shared Parts helper.
        // [GIVEN] The choice entry captured from main 6413d705.
        // [WHEN] Its message contract is generated.
        // [THEN] Every entry field, its position and the chapter size remain unchanged.
        AssertChoiceParameter("Message Type ori"::"Orchestrator.Playbook.Schedule", 2, 8,
            '{"name":"notificationType","type":"string","required":false,"description":"How the entry notifies. Case-insensitive; any other value means None.","default":"None","allowed":["None","EMail","Telegram"]}');
    end;

    /// <summary>Preserves every field and position of the main choice entry.</summary>
    [Test]
    procedure Scenario_AC05_RetryPolicy_KeepsMainContract()
    begin
        // Story #68, AC05 | Time: independent of Today/WorkDate | Risk: #71 shared Parts helper.
        // [GIVEN] The choice entry captured from main 6413d705.
        // [WHEN] Its message contract is generated.
        // [THEN] Every entry field, its position and the chapter size remain unchanged.
        AssertChoiceParameter("Message Type ori"::"Orchestrator.Playbook.Schedule", 6, 8,
            '{"name":"retryPolicy","type":"string","required":false,"description":"Whether a failed run is restarted: Never, ThreeTimes (until three errors since the last success) or Always. Case-insensitive; any other value means Always.","default":"Always","allowed":["Never","ThreeTimes","Always"]}');
    end;

    local procedure AssertChoiceParameter(MessageType: Enum "Message Type ori"; Index: Integer; Count: Integer; ExpectedJson: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Contract: JsonObject;
        Chapter: JsonToken;
        Entry: JsonToken;
        Expected: JsonToken;
        ActualText: Text;
        ExpectedText: Text;
    begin
        Assert.IsTrue(ContractMgt.GetContract(MessageType, Contract), 'Contract exists');
        Assert.IsTrue(Contract.Get('parameters', Chapter), 'Parameters chapter exists');
        Assert.AreEqual(Count, Chapter.AsArray().Count(), 'Parameter count matches main');
        Assert.IsTrue(Chapter.AsArray().Get(Index, Entry), 'Entry position matches main');
        Assert.IsTrue(Expected.ReadFrom(ExpectedJson), 'Valid captured main fixture');
        Entry.WriteTo(ActualText);
        Expected.WriteTo(ExpectedText);
        Assert.AreEqual(ExpectedText, ActualText, 'Choice entry matches main byte for byte');
    end;

    /// <summary>Preserves the main errors chapter for Orchestrator.JobQueueEntry.RestartIfNeeded.</summary>
    [Test]
    procedure Scenario_AC04_JobQueueEntryRestartIfNeeded_KeepsMainErrors()
    begin
        // Story #71, AC04 | Time: independent of Today/WorkDate | Risk: shared contract helpers.
        // [GIVEN] The errors chapter captured from main 6413d705.
        // [WHEN] The current contract is generated.
        // [THEN] All entries, their order, codes and text are identical.
        AssertMainErrors("Message Type ori"::"Orchestrator.JobQueueEntry.RestartIfNeeded",
            '[{"code":"BusinessCentralError","error":"Request must include \"id\" (GUID) in the data payload or as the subject.","when":"data.id is missing or not a GUID, and subject is not a GUID.","fix":"Send the SystemId of the Job Queue Entry in data.id or as subject."},{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"No Job Queue Entry has that SystemId (Business Central''s record-not-found text).","fix":"Send the SystemId of the Job Queue Entry; its ID is not accepted."},{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"Business Central refuses to set the Job Queue Entry to Ready.","fix":"Read the text and fix the Job Queue Entry."}]');
    end;

    /// <summary>Preserves the main errors chapter for Orchestrator.JobQueueEntry.Restart.</summary>
    [Test]
    procedure Scenario_AC04_JobQueueEntryRestart_KeepsMainErrors()
    begin
        // Story #71, AC04 | Time: independent of Today/WorkDate | Risk: shared contract helpers.
        // [GIVEN] The errors chapter captured from main 6413d705.
        // [WHEN] The current contract is generated.
        // [THEN] All entries, their order, codes and text are identical.
        AssertMainErrors("Message Type ori"::"Orchestrator.JobQueueEntry.Restart",
            '[{"code":"BusinessCentralError","error":"Request must include \"id\" (GUID) in the data payload or as the subject.","when":"data.id is missing or not a GUID, and subject is not a GUID.","fix":"Send the SystemId of the Job Queue Entry in data.id or as subject."},{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"No Job Queue Entry has that SystemId (Business Central''s record-not-found text).","fix":"Send the SystemId of the Job Queue Entry; its ID is not accepted."},{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"Business Central refuses to set the Job Queue Entry to Ready.","fix":"Read the text and fix the Job Queue Entry."}]');
    end;

    /// <summary>Preserves the main errors chapter for Help.Orchestrator.Get.</summary>
    [Test]
    procedure Scenario_AC04_OrchestratorGet_KeepsMainErrors()
    begin
        // Story #71, AC04 | Time: independent of Today/WorkDate | Risk: shared contract helpers.
        // [GIVEN] The errors chapter captured from main 6413d705.
        // [WHEN] The current contract is generated.
        // [THEN] All entries, their order, codes and text are identical.
        AssertMainErrors("Message Type ori"::"Help.Orchestrator.Get",
            '[{"code":"BusinessCentralError","error":"Unsupported specification version <version>. Expected version 1.0.","when":"The request version is not 1.0.","fix":"Send version 1.0."}]');
    end;

    /// <summary>Preserves the main errors chapter for Orchestrator.Playbook.Enqueue.</summary>
    [Test]
    procedure Scenario_AC04_PlaybookEnqueue_KeepsMainErrors()
    begin
        // Story #71, AC04 | Time: independent of Today/WorkDate | Risk: shared contract helpers.
        // [GIVEN] The errors chapter captured from main 6413d705.
        // [WHEN] The current contract is generated.
        // [THEN] All entries, their order, codes and text are identical.
        AssertMainErrors("Message Type ori"::"Orchestrator.Playbook.Enqueue",
            '[{"code":"BusinessCentralError","error":"Request must include \"playbookCode\" in the data payload or as the subject.","when":"Neither data.playbookCode nor subject was sent.","fix":"Send the playbook code in data.playbookCode or as subject."},{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"No Playbook ori exists with that code (Business Central''s record-not-found text).","fix":"Check the code with Data.Records.Get on table Playbook ori."},{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"delaySeconds is not a whole number, or Job Queue - Enqueue refuses the entry.","fix":"Send delaySeconds as an integer and check the Job Queue setup."}]');
    end;

    /// <summary>Preserves the main errors chapter for Orchestrator.Playbook.Run and ends with the PreconditionFailed entry of #109 (verify before start).</summary>
    [Test]
    procedure Scenario_AC04_PlaybookRun_KeepsMainErrors()
    begin
        // Story #71, AC04 | Time: independent of Today/WorkDate | Risk: shared contract helpers.
        // [GIVEN] The errors chapter captured from main 6413d705.
        // [WHEN] The current contract is generated.
        // [THEN] All entries, their order, codes and text are identical.
        AssertMainErrors("Message Type ori"::"Orchestrator.Playbook.Run",
            '[{"code":"BusinessCentralError","error":"Request must include \"playbookCode\" in the data payload or as the subject.","when":"Neither data.playbookCode nor subject was sent.","fix":"Send the playbook code in data.playbookCode or as subject."},{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"No Playbook ori exists with that code (Business Central''s record-not-found text).","fix":"Check the code with Data.Records.Get on table Playbook ori."},{"code":"BusinessCentralError","error":"Step <stepNo> not found in playbook <playbookCode>.","when":"A Next Step No. of a step that ran points to a step that does not exist.","fix":"Fix the step chain of the playbook."},{"code":"PreconditionFailed","error":"Playbook <playbookCode> was not started: errors on enabled steps: <n>, warnings: <m>. <findings>","when":"The playbook does not verify: an enabled step has an error, or a warning while ignoreWarnings is not true. The answer names the findings in findings[] and the summary lists them.","fix":"Call Orchestrator.Playbook.Verify with the same playbookCode, fix the findings, then call again. A warning can be accepted on purpose with ignoreWarnings true; an error cannot."}]');
    end;

    /// <summary>Preserves the main errors chapter for Orchestrator.Playbook.Schedule and ends with the PreconditionFailed entry of #109 (verify before start).</summary>
    [Test]
    procedure Scenario_AC04_PlaybookSchedule_KeepsMainErrors()
    begin
        // Story #71, AC04 | Time: independent of Today/WorkDate | Risk: shared contract helpers.
        // [GIVEN] The errors chapter captured from main 6413d705.
        // [WHEN] The current contract is generated.
        // [THEN] All entries, their order, codes and text are identical.
        AssertMainErrors("Message Type ori"::"Orchestrator.Playbook.Schedule",
            '[{"code":"BusinessCentralError","error":"Request must include \"playbookCode\" in the data payload or as the subject.","when":"Neither data.playbookCode nor subject was sent.","fix":"Send the playbook code in data.playbookCode or as subject."},{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"No Playbook ori exists with that code (Business Central''s record-not-found text).","fix":"Check the code with Data.Records.Get on table Playbook ori."},{"code":"BusinessCentralError","error":"Request must include \"recurringTemplateCode\".","when":"data.recurringTemplateCode is missing or empty.","fix":"Send the code of a Recurring Template ori."},{"code":"BusinessCentralError","error":"Playbook <playbookCode> is already scheduled. Remove the existing orchestrator entry first.","when":"The playbook already has an orchestrator entry.","fix":"Delete that Scheduled Entry ori first, or keep the schedule it has."},{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"No Recurring Template ori has that code (Business Central''s table relation error).","fix":"Check the code with Data.Records.Get on table Recurring Template ori."},{"code":"PreconditionFailed","error":"Playbook <playbookCode> was not started: errors on enabled steps: <n>, warnings: <m>. <findings>","when":"The playbook does not verify: an enabled step has an error, or a warning while ignoreWarnings is not true. The answer names the findings in findings[] and the summary lists them.","fix":"Call Orchestrator.Playbook.Verify with the same playbookCode, fix the findings, then call again. A warning can be accepted on purpose with ignoreWarnings true; an error cannot."}]');
    end;

    /// <summary>Preserves the main errors chapter for Orchestrator.Email.Send.</summary>
    [Test]
    procedure Scenario_AC04_EmailSend_KeepsMainErrors()
    begin
        // Story #71, AC04 | Time: independent of Today/WorkDate | Risk: shared contract helpers.
        // [GIVEN] The errors chapter captured from main 6413d705.
        // [WHEN] The current contract is generated.
        // [THEN] All entries, their order, codes and text are identical.
        AssertMainErrors("Message Type ori"::"Orchestrator.Email.Send",
            '[{"code":"BusinessCentralError","error":"\"outboxSystemId\" (GUID from Email.Draft.Set response) is required in data or as subject.","when":"data.outboxSystemId is missing or not a GUID, and subject is not a GUID.","fix":"Send the outboxSystemId of the draft."},{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"No Email Outbox entry has that SystemId (Business Central''s record-not-found text).","fix":"Send the outboxSystemId from the Email.Draft.Set answer."},{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"The email account or its connector refuses to send.","fix":"Check the email account of the draft."}]');
    end;

    /// <summary>Preserves the main errors chapter for Orchestrator.Entry.Register.</summary>
    [Test]
    procedure Scenario_AC04_EntryRegister_KeepsMainErrors()
    begin
        // Story #71, AC04 | Time: independent of Today/WorkDate | Risk: shared contract helpers.
        // [GIVEN] The errors chapter captured from main 6413d705.
        // [WHEN] The current contract is generated.
        // [THEN] All entries, their order, codes and text are identical.
        AssertMainErrors("Message Type ori"::"Orchestrator.Entry.Register",
            '[{"code":"BusinessCentralError","error":"Request must include \"jobQueueEntryId\" (GUID) in the data payload or the Job Queue Entry ID as the subject.","when":"data.jobQueueEntryId is missing or not a GUID, and subject is not a GUID.","fix":"Send the ID of the Job Queue Entry."},{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"No Job Queue Entry has that ID (Business Central''s record-not-found text).","fix":"Send the ID of the Job Queue Entry, not its SystemId."},{"code":"BusinessCentralError","error":"The Job Queue Orchestrator Management Job Queue Entry cannot be one of the Job Queue Orchestrator Entries.","when":"The ID is the orchestrator''s own management Job Queue Entry.","fix":"Register a different Job Queue Entry."}]');
    end;

    /// <summary>Preserves the main errors chapter for Orchestrator.Entry.Restart.</summary>
    [Test]
    procedure Scenario_AC04_EntryRestart_KeepsMainErrors()
    begin
        // Story #71, AC04 | Time: independent of Today/WorkDate | Risk: shared contract helpers.
        // [GIVEN] The errors chapter captured from main 6413d705.
        // [WHEN] The current contract is generated.
        // [THEN] All entries, their order, codes and text are identical.
        AssertMainErrors("Message Type ori"::"Orchestrator.Entry.Restart",
            '[{"code":"BusinessCentralError","error":"Request must include \"id\" (GUID) in the data payload or as the subject.","when":"data.id is missing or not a GUID, and subject is not a GUID.","fix":"Send the SystemId of the Scheduled Entry ori in data.id or as subject."},{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"No Scheduled Entry ori has that SystemId or ID (Business Central''s record-not-found text).","fix":"Check the identifier with Data.Records.Get on table Scheduled Entry ori."},{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"The Job Queue Entry cannot be restarted or created.","fix":"Check the entry''s object to run, its client credentials and the scheduler setup."}]');
    end;

    /// <summary>Preserves the main errors chapter for Orchestrator.Entry.Run.</summary>
    [Test]
    procedure Scenario_AC04_EntryRun_KeepsMainErrors()
    begin
        // Story #71, AC04 | Time: independent of Today/WorkDate | Risk: shared contract helpers.
        // [GIVEN] The errors chapter captured from main 6413d705.
        // [WHEN] The current contract is generated.
        // [THEN] All entries, their order, codes and text are identical.
        AssertMainErrors("Message Type ori"::"Orchestrator.Entry.Run",
            '[{"code":"BusinessCentralError","error":"Request must include \"id\" (GUID) in the data payload or as the subject.","when":"data.id is missing or not a GUID, and subject is not a GUID.","fix":"Send the SystemId of the Scheduled Entry ori in data.id or as subject."},{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"No Scheduled Entry ori has that SystemId or ID (Business Central''s record-not-found text).","fix":"Check the identifier with Data.Records.Get on table Scheduled Entry ori."}]');
    end;

    /// <summary>Preserves the main errors chapter for Orchestrator.Entry.Schedule.</summary>
    [Test]
    procedure Scenario_AC04_EntrySchedule_KeepsMainErrors()
    begin
        // Story #71, AC04 | Time: independent of Today/WorkDate | Risk: shared contract helpers.
        // [GIVEN] The errors chapter captured from main 6413d705.
        // [WHEN] The current contract is generated.
        // [THEN] All entries, their order, codes and text are identical.
        AssertMainErrors("Message Type ori"::"Orchestrator.Entry.Schedule",
            '[{"code":"BusinessCentralError","error":"Request must include \"id\" (GUID) in the data payload or as the subject.","when":"data.id is missing or not a GUID, and subject is not a GUID.","fix":"Send the SystemId of the Scheduled Entry ori in data.id or as subject."},{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"No Scheduled Entry ori has that SystemId or ID (Business Central''s record-not-found text).","fix":"Check the identifier with Data.Records.Get on table Scheduled Entry ori."},{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"The entry is blocked (Business Central''s TestField error on Blocked).","fix":"Unblock the entry first."},{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"The scheduling API call or the local scheduling fails.","fix":"Check the entry''s client credentials and the scheduler setup."}]');
    end;

    /// <summary>Preserves the main errors chapter for Orchestrator.Status.Get.</summary>
    [Test]
    procedure Scenario_AC04_StatusGet_KeepsMainErrors()
    begin
        // Story #71, AC04 | Time: independent of Today/WorkDate | Risk: shared contract helpers.
        // [GIVEN] The errors chapter captured from main 6413d705.
        // [WHEN] The current contract is generated.
        // [THEN] All entries, their order, codes and text are identical.
        AssertMainErrors("Message Type ori"::"Orchestrator.Status.Get",
            '[{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"The scheduler setup cannot be read.","fix":"Check the orchestrator setup."}]');
    end;

    /// <summary>Preserves the main errors chapter for Orchestrator.Status.RestartIfNeeded.</summary>
    [Test]
    procedure Scenario_AC04_StatusRestartIfNeeded_KeepsMainErrors()
    begin
        // Story #71, AC04 | Time: independent of Today/WorkDate | Risk: shared contract helpers.
        // [GIVEN] The errors chapter captured from main 6413d705.
        // [WHEN] The current contract is generated.
        // [THEN] All entries, their order, codes and text are identical.
        AssertMainErrors("Message Type ori"::"Orchestrator.Status.RestartIfNeeded",
            '[{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"The scheduler cannot be inspected or restarted.","fix":"Check scheduler setup and Job Queue permissions."}]');
    end;

    /// <summary>Preserves the main errors chapter for Orchestrator.Status.Restart.</summary>
    [Test]
    procedure Scenario_AC04_StatusRestart_KeepsMainErrors()
    begin
        // Story #71, AC04 | Time: independent of Today/WorkDate | Risk: shared contract helpers.
        // [GIVEN] The errors chapter captured from main 6413d705.
        // [WHEN] The current contract is generated.
        // [THEN] All entries, their order, codes and text are identical.
        AssertMainErrors("Message Type ori"::"Orchestrator.Status.Restart",
            '[{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"The scheduler cannot be restarted.","fix":"Check scheduler setup and Job Queue permissions."}]');
    end;

    /// <summary>Preserves the main errors chapter for Orchestrator.Telegram.Message.</summary>
    [Test]
    procedure Scenario_AC04_TelegramMessage_KeepsMainErrors()
    begin
        // Story #71, AC04 | Time: independent of Today/WorkDate | Risk: shared contract helpers.
        // [GIVEN] The errors chapter captured from main 6413d705.
        // [WHEN] The current contract is generated.
        // [THEN] All entries, their order, codes and text are identical.
        AssertMainErrors("Message Type ori"::"Orchestrator.Telegram.Message",
            '[{"code":"BusinessCentralError","error":"HTTP client requests are not enabled for this extension. Enable Allow HttpClient Requests in Extension Settings before sending Telegram messages.","when":"Allow HttpClient Requests is off for Bifrost Orchestrator.","fix":"Enable it in Extension Settings (page 2500)."},{"code":"BusinessCentralError","error":"Telegram Bot Token is not configured in Orchestrator Setup.","when":"No bot token is stored.","fix":"Set the Telegram Bot Token in the Orchestrator setup."},{"code":"BusinessCentralError","error":"Business Central''s own error text","when":"The calling user has no User Setup ori record (Business Central''s record-not-found text).","fix":"Create the user''s Bifrost User Setup with a Telegram Chat ID."},{"code":"BusinessCentralError","error":"No Telegram Chat ID configured for the current user. Set it in Bifrost User Setup.","when":"The calling user''s Telegram Chat ID is empty.","fix":"Set the Telegram Chat ID in Bifrost User Setup."},{"code":"BusinessCentralError","error":"\"message\" is required in the request data.","when":"data.message is missing.","fix":"Send the text in data.message."},{"code":"BusinessCentralError","error":"Failed to send Telegram message to Chat ID <chatId>. Response: <Telegram response>","when":"Telegram rejected the request.","fix":"Read the Telegram response and correct the message or the configuration."}]');
    end;

    local procedure AssertMainErrors(MessageType: Enum "Message Type ori"; ExpectedJson: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Contract: JsonObject;
        Actual: JsonToken;
        Expected: JsonToken;
        ActualText: Text;
        ExpectedText: Text;
    begin
        Assert.IsTrue(ContractMgt.GetContract(MessageType, Contract), 'Contract exists');
        Assert.IsTrue(Contract.Get('errors', Actual), 'Errors chapter exists');
        Assert.IsTrue(Expected.ReadFrom(ExpectedJson), 'Valid captured main fixture');
        Actual.WriteTo(ActualText);
        Expected.WriteTo(ExpectedText);
        Assert.AreEqual(ExpectedText, ActualText, 'Errors chapter matches main byte for byte');
    end;

    local procedure AssertContract(MessageType: Enum "Message Type ori"; Name: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Discovery: Interface "Msg Discovery ori";
        Contract: JsonObject;
        EffectToken: JsonToken;
    begin
        Assert.IsTrue(ContractMgt.GetContract(MessageType, Contract), Name + ' contract');
        Assert.IsTrue(Contract.Contains('envelope'), Name + ' envelope');
        Assert.IsTrue(Contract.Contains('response'), Name + ' response');
        Assert.IsTrue(Contract.Contains('errors'), Name + ' errors');
        Assert.IsTrue(Contract.Get('effect', EffectToken), Name + ' effect');
        Assert.IsTrue(EffectToken.AsObject().Contains('effect'), Name + ' effect kind');
        Discovery := MessageType;
        Assert.AreNotEqual('', Discovery.GetKeywords(), Name + ' keywords');
        Assert.AreNotEqual('', Discovery.GetSelectionDescription(), Name + ' selection');
    end;

    local procedure AssertEffect(MessageType: Enum "Message Type ori"; Name: Text; ExpectedEffect: Text; NamesCommit: Boolean)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Contract: JsonObject;
        EffectToken: JsonToken;
        ValueToken: JsonToken;
    begin
        Assert.IsTrue(ContractMgt.GetContract(MessageType, Contract), Name + ' contract');
        Contract.Get('effect', EffectToken);
        EffectToken.AsObject().Get('effect', ValueToken);
        Assert.AreEqual(ExpectedEffect, ValueToken.AsValue().AsText(), Name + ' effect');
        if NamesCommit then begin
            EffectToken.AsObject().Get('changes', ValueToken);
            Assert.IsTrue(ValueToken.AsValue().AsText().Contains('commit'), Name + ' changes names the commit');
            Assert.IsTrue(ValueToken.AsValue().AsText().Contains('Omit Commit guard'), Name + ' changes names the Omit Commit guard');
        end;
    end;
}
