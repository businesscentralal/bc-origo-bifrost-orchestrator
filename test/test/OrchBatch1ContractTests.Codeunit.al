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
        AssertContract("Message Type ori"::"Orchestrator.JobQueueEntry.Restart", 'Orchestrator.JobQueueEntry.Restart');
        AssertContract("Message Type ori"::"Orchestrator.JobQueueEntry.RestartIfNeeded", 'Orchestrator.JobQueueEntry.RestartIfNeeded');
        AssertContract("Message Type ori"::"Help.Orchestrator.Get", 'Help.Orchestrator.Get');
        AssertContract("Message Type ori"::"Orchestrator.Email.Send", 'Orchestrator.Email.Send');
        AssertContract("Message Type ori"::"Orchestrator.Telegram.Message", 'Orchestrator.Telegram.Message');
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
}
