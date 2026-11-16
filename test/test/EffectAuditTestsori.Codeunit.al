namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>
/// Issue #191 (core#1365 D1/D2): every irreversible Orchestrator type declares its real effect and names what
/// expectedCount counts, in effect.changes, on the expectedCount parameter and (en-US and is-IS) in its selection help.
/// </summary>
codeunit 96490 "Effect Audit Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure IrreversibleTypes_NameTheCountUnitInEffectAndParameter()
    begin
        // [SCENARIO] AC01 / AC02 / AC03: each type stays irreversible and says what its count counts and how to read it.
        AssertCounted("Message Type ori"::"Orchestrator.Entry.Run", 'Orchestrator.Entry.Run', 'orchestrator entry that is run');
        AssertCounted("Message Type ori"::"Orchestrator.Entry.Restart", 'Orchestrator.Entry.Restart', 'orchestrator entry that is restarted');
        AssertCounted("Message Type ori"::"Orchestrator.Status.Restart", 'Orchestrator.Status.Restart', 'management Job Queue Entry');
        AssertCounted("Message Type ori"::"Orchestrator.Status.RestartIfNeeded", 'Orchestrator.Status.RestartIfNeeded', 'management Job Queue Entry');
        AssertCounted("Message Type ori"::"Orchestrator.Playbook.Run", 'Orchestrator.Playbook.Run', 'not its steps');
        AssertCounted("Message Type ori"::"Orchestrator.Entry.Register", 'Orchestrator.Entry.Register', 'Job Queue Entry that is registered');
        AssertCounted("Message Type ori"::"Orchestrator.Entry.Schedule", 'Orchestrator.Entry.Schedule', 'schedule is rebuilt');
        AssertCounted("Message Type ori"::"Orchestrator.Email.Send", 'Orchestrator.Email.Send', 'e-mail draft');
        AssertCounted("Message Type ori"::"Orchestrator.Telegram.Message", 'Orchestrator.Telegram.Message', 'Telegram message');
        AssertCounted("Message Type ori"::"Orchestrator.Report.Run", 'Orchestrator.Report.Run', 'not the records');
        AssertCounted("Message Type ori"::"Purchase.Order.Send", 'Purchase.Order.Send', 'purchase order that is sent');
        AssertCounted("Message Type ori"::"Sales.Quote.Send", 'Sales.Quote.Send', 'sales quote that is sent');
        AssertCounted("Message Type ori"::"Sales.OrderConfirmation.Send", 'Sales.OrderConfirmation.Send', 'sales order confirmation that is sent');
        AssertCounted("Message Type ori"::"Orchestrator.Workspace.Preview", 'Orchestrator.Workspace.Preview', 'preview call');
    end;

    [Test]
    procedure IrreversibleTypes_SelectionHelpNamesTheUnitInBothLanguages()
    begin
        // [SCENARIO] AC02: the unit sentence is a translated label.
        AssertSelection("Message Type ori"::"Orchestrator.Entry.Run", 1033, 'expectedCount counts');
        AssertSelection("Message Type ori"::"Orchestrator.Entry.Run", 1039, 'expectedCount telur');
        AssertSelection("Message Type ori"::"Orchestrator.Entry.Restart", 1039, 'expectedCount telur');
        AssertSelection("Message Type ori"::"Orchestrator.Status.Restart", 1039, 'expectedCount telur');
        AssertSelection("Message Type ori"::"Orchestrator.Status.RestartIfNeeded", 1039, 'expectedCount telur');
        AssertSelection("Message Type ori"::"Orchestrator.Playbook.Run", 1039, 'expectedCount telur');
        AssertSelection("Message Type ori"::"Orchestrator.Entry.Register", 1039, 'expectedCount telur');
        AssertSelection("Message Type ori"::"Orchestrator.Entry.Schedule", 1039, 'expectedCount telur');
        AssertSelection("Message Type ori"::"Orchestrator.Email.Send", 1039, 'expectedCount telur');
        AssertSelection("Message Type ori"::"Orchestrator.Telegram.Message", 1039, 'expectedCount telur');
        AssertSelection("Message Type ori"::"Orchestrator.Report.Run", 1039, 'expectedCount telur');
        AssertSelection("Message Type ori"::"Purchase.Order.Send", 1039, 'expectedCount telur');
        AssertSelection("Message Type ori"::"Sales.Quote.Send", 1039, 'expectedCount telur');
        AssertSelection("Message Type ori"::"Sales.OrderConfirmation.Send", 1039, 'expectedCount telur');
        AssertSelection("Message Type ori"::"Orchestrator.Workspace.Preview", 1039, 'expectedCount telur');
        AssertSelection("Message Type ori"::"Orchestrator.Workspace.Preview", 1033, 'expectedCount counts');
    end;

    [Test]
    procedure WriteAndReadTypes_AreNotMadeIrreversible()
    begin
        // [SCENARIO] AC01 edge: types that only write or read keep their weaker effect and declare no count unit.
        AssertEffectKind("Message Type ori"::"Orchestrator.JobQueueEntry.Restart", 'write');
        AssertEffectKind("Message Type ori"::"Orchestrator.JobQueueEntry.RestartIfNeeded", 'write');
        AssertEffectKind("Message Type ori"::"Orchestrator.Playbook.Verify", 'read');
        AssertEffectKind("Message Type ori"::"Orchestrator.Report.List", 'read');
    end;

    local procedure AssertCounted(MessageType: Enum "Message Type ori"; Name: Text; UnitPart: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Contract: JsonObject;
        Token: JsonToken;
        Entry: JsonToken;
        ParamName: JsonToken;
        Params: JsonToken;
        Changes: Text;
        Found: Integer;
    begin
        Assert.IsTrue(ContractMgt.GetContract(MessageType, Contract), Name + ' contract');
        Contract.Get('effect', Token);
        Token.AsObject().Get('effect', Entry);
        Assert.AreEqual('irreversible', Entry.AsValue().AsText(), Name + ' effect');
        Token.AsObject().Get('changes', Entry);
        Changes := Entry.AsValue().AsText();
        Assert.IsTrue(Changes.Contains('expectedCount counts '), Name + ' changes names the count');
        Assert.IsTrue(Changes.Contains(UnitPart), Name + ' changes names the unit ' + UnitPart);
        Assert.IsTrue(Changes.Contains('without expectedCount and read expected'), Name + ' changes says how to read the count');
        Assert.IsTrue(Changes.Contains('@preview'), Name + ' changes names @preview');
        Contract.Get('parameters', Params);
        foreach Entry in Params.AsArray() do
            if Entry.AsObject().Get('name', ParamName) then
                if ParamName.AsValue().AsText() = 'expectedCount' then begin
                    Found += 1;
                    Entry.AsObject().Get('description', Token);
                    Assert.IsTrue(Token.AsValue().AsText().Contains(UnitPart), Name + ' parameter names the unit');
                end;
        Assert.AreEqual(1, Found, Name + ' declares expectedCount exactly once');
    end;

    local procedure AssertSelection(MessageType: Enum "Message Type ori"; LanguageId: Integer; Expected: Text)
    var
        Discovery: Interface "Msg Discovery ori";
        PreviousLanguage: Integer;
        Selection: Text;
    begin
        Discovery := MessageType;
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Selection := Discovery.GetSelectionDescription();
        GlobalLanguage(PreviousLanguage);
        Assert.IsTrue(Selection.Contains(Expected), 'Selection help in ' + Format(LanguageId) + ' says: ' + Expected);
    end;

    local procedure AssertEffectKind(MessageType: Enum "Message Type ori"; Expected: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Contract: JsonObject;
        Token: JsonToken;
        Kind: JsonToken;
    begin
        Assert.IsTrue(ContractMgt.GetContract(MessageType, Contract), 'contract');
        Contract.Get('effect', Token);
        Token.AsObject().Get('effect', Kind);
        Assert.AreEqual(Expected, Kind.AsValue().AsText(), 'effect kind');
        Assert.IsFalse(Token.AsObject().Get('changes', Kind) and Kind.AsValue().AsText().Contains('expectedCount counts'), 'no count unit on a non-irreversible type');
    end;
}
