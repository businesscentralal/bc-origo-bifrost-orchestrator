namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>
/// Contract and discovery conformance tests for Batch 2 message types.
/// </summary>
codeunit 96453 "Orch B2 Contract Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure Batch2MessagesHaveContractChaptersAndDiscovery()
    begin
        AssertContract("Message Type ori"::"Orchestrator.Report.List", 'Orchestrator.Report.List');
        AssertContract("Message Type ori"::"Orchestrator.Report.Get", 'Orchestrator.Report.Get');
        AssertContract("Message Type ori"::"Orchestrator.Report.SaveAs", 'Orchestrator.Report.SaveAs');
        AssertContract("Message Type ori"::"Orchestrator.Report.Run", 'Orchestrator.Report.Run');
        AssertContract("Message Type ori"::"Orchestrator.Workspace.Preview", 'Orchestrator.Workspace.Preview');
        AssertContract("Message Type ori"::"Orchestrator.ReportLayout.Set", 'Orchestrator.ReportLayout.Set');
    end;

    [Test]
    procedure CommittingTypesDeclareIrreversible()
    begin
        // [SCENARIO #60] Report.Run runs caller-named batch reports that commit, so it declares irreversible
        AssertEffect("Message Type ori"::"Orchestrator.Report.Run", 'Orchestrator.Report.Run', 'irreversible', true);
    end;

    [Test]
    procedure NonCommittingTypesKeepTheirEffect()
    begin
        // [SCENARIO #60] ReportLayout.Set stays write; the reads stay read
        AssertEffect("Message Type ori"::"Orchestrator.ReportLayout.Set", 'Orchestrator.ReportLayout.Set', 'write', false);
        AssertEffect("Message Type ori"::"Orchestrator.Report.List", 'Orchestrator.Report.List', 'read', false);
        AssertEffect("Message Type ori"::"Orchestrator.Report.Get", 'Orchestrator.Report.Get', 'read', false);
        AssertEffect("Message Type ori"::"Orchestrator.Report.SaveAs", 'Orchestrator.Report.SaveAs', 'read', false);
        AssertEffect("Message Type ori"::"Orchestrator.Workspace.Preview", 'Orchestrator.Workspace.Preview', 'read', false);
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
