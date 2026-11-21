namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>
/// Issue #191 (core#1365 D1/D2) and issue #257 (Gunnar 21.11.2026: only posting is irreversible): the two types that
/// run a caller-named job or report can post and stay irreversible, naming what expectedCount counts; every other
/// Orchestrator type that changes data declares write, still accepts expectedCount and ignores it.
/// </summary>
codeunit 96492 "Effect Audit Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure EveryAppType_OnlyPostingCapableTypesAreIrreversible()
    var
        MessageType: Enum "Message Type ori";
        Ordinal: Integer;
        Index: Integer;
        Irreversible: Text;
        Walked: Integer;
    begin
        // [SCENARIO] #257 AC01: walk every message type of this app (its enum range); only Entry.Run and Report.Run are irreversible.
        // [WHEN] the declared effect of each type is read
        foreach Ordinal in MessageType.Ordinals() do
            if (Ordinal >= 10035535) and (Ordinal <= 10035634) then begin
                Walked += 1;
                MessageType := "Message Type ori".FromInteger(Ordinal);
                if DeclaredEffect(MessageType) = 'irreversible' then begin
                    Index := MessageType.Ordinals().IndexOf(Ordinal);
                    Irreversible += MessageType.Names().Get(Index) + ';';
                end;
            end;
        // [THEN] exactly the two posting-capable types remain
        Assert.IsTrue(Walked >= 30, 'the walk covers every type of the app');
        Assert.AreEqual('Orchestrator.Entry.Run;Orchestrator.Report.Run;', SortedPair(Irreversible), 'irreversible types of the app');
    end;

    [Test]
    procedure PostingCapableTypes_NameTheCountUnitInEffectAndParameter()
    begin
        // [SCENARIO] #191 AC01-AC03, kept by #257: the two irreversible types say what their count counts and how to read it.
        AssertCounted("Message Type ori"::"Orchestrator.Entry.Run", 'Orchestrator.Entry.Run', 'orchestrator entry that is run');
        AssertCounted("Message Type ori"::"Orchestrator.Report.Run", 'Orchestrator.Report.Run', 'not the records');
    end;

    [Test]
    procedure PostingCapableTypes_SelectionHelpNamesTheUnitInBothLanguages()
    begin
        // [SCENARIO] #191 AC02: the unit sentence is a translated label.
        AssertSelection("Message Type ori"::"Orchestrator.Entry.Run", 1033, 'expectedCount counts');
        AssertSelection("Message Type ori"::"Orchestrator.Entry.Run", 1039, 'expectedCount telur');
        AssertSelection("Message Type ori"::"Orchestrator.Report.Run", 1033, 'Irreversible.');
        AssertSelection("Message Type ori"::"Orchestrator.Report.Run", 1039, 'expectedCount telur');
    end;

    [Test]
    procedure ReclassifiedTypes_AreWriteAndIgnoreExpectedCount()
    begin
        // [SCENARIO] #257 AC01/AC02: the twelve committing or sending types declare write and keep an ignored expectedCount.
        AssertWriteIgnored("Message Type ori"::"Orchestrator.Email.Send");
        AssertWriteIgnored("Message Type ori"::"Orchestrator.Telegram.Message");
        AssertWriteIgnored("Message Type ori"::"Purchase.Order.Send");
        AssertWriteIgnored("Message Type ori"::"Sales.Quote.Send");
        AssertWriteIgnored("Message Type ori"::"Sales.OrderConfirmation.Send");
        AssertWriteIgnored("Message Type ori"::"Orchestrator.Playbook.Run");
        AssertWriteIgnored("Message Type ori"::"Orchestrator.Workspace.Preview");
        AssertWriteIgnored("Message Type ori"::"Orchestrator.Entry.Register");
        AssertWriteIgnored("Message Type ori"::"Orchestrator.Entry.Restart");
        AssertWriteIgnored("Message Type ori"::"Orchestrator.Entry.Schedule");
        AssertWriteIgnored("Message Type ori"::"Orchestrator.Status.Restart");
        AssertWriteIgnored("Message Type ori"::"Orchestrator.Status.RestartIfNeeded");
    end;

    [Test]
    procedure ReclassifiedTypes_SelectionHelpSaysWritesInBothLanguages()
    begin
        // [SCENARIO] #257 AC04: "Writes."/"Skrifar." and no Irreversible/Óafturkræft on a type that never posts.
        AssertWritesHelp("Message Type ori"::"Orchestrator.Email.Send");
        AssertWritesHelp("Message Type ori"::"Orchestrator.Telegram.Message");
        AssertWritesHelp("Message Type ori"::"Purchase.Order.Send");
        AssertWritesHelp("Message Type ori"::"Sales.Quote.Send");
        AssertWritesHelp("Message Type ori"::"Sales.OrderConfirmation.Send");
        AssertWritesHelp("Message Type ori"::"Orchestrator.Playbook.Run");
        AssertWritesHelp("Message Type ori"::"Orchestrator.Workspace.Preview");
        AssertWritesHelp("Message Type ori"::"Orchestrator.Entry.Register");
        AssertWritesHelp("Message Type ori"::"Orchestrator.Entry.Restart");
        AssertWritesHelp("Message Type ori"::"Orchestrator.Entry.Schedule");
        AssertWritesHelp("Message Type ori"::"Orchestrator.Status.Restart");
        AssertWritesHelp("Message Type ori"::"Orchestrator.Status.RestartIfNeeded");
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

    local procedure DeclaredEffect(MessageType: Enum "Message Type ori"): Text
    var
        Contract: Interface "Msg Contract ori";
        Effect: JsonObject;
        Token: JsonToken;
    begin
        Contract := MessageType;
        if not Contract.GetEffect(Effect) then
            exit('');
        if not Effect.Get('effect', Token) then
            exit('');
        if not Token.IsValue() then
            exit('');
        if Token.AsValue().IsNull() then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    local procedure SortedPair(Names: Text): Text
    begin
        // Enum order is not alphabetical; normalise the two expected names, keep anything else visible.
        if Names = 'Orchestrator.Report.Run;Orchestrator.Entry.Run;' then
            exit('Orchestrator.Entry.Run;Orchestrator.Report.Run;');
        exit(Names);
    end;

    local procedure AssertWriteIgnored(MessageType: Enum "Message Type ori")
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Contract: JsonObject;
        Token: JsonToken;
        Entry: JsonToken;
        ParamName: JsonToken;
        Params: JsonToken;
        Name: Text;
        Found: Integer;
    begin
        Name := MessageType.Names().Get(MessageType.Ordinals().IndexOf(MessageType.AsInteger()));
        Assert.AreEqual('write', DeclaredEffect(MessageType), Name + ' effect');
        Assert.IsTrue(ContractMgt.GetContract(MessageType, Contract), Name + ' contract');
        Contract.Get('effect', Token);
        Token.AsObject().Get('changes', Entry);
        Assert.IsFalse(Entry.AsValue().AsText().Contains('expectedCount counts'), Name + ' changes names no count');
        Assert.IsTrue(Entry.AsValue().AsText().Contains('Omit Commit guard refuses it'), Name + ' changes says the guard refuses it');
        Contract.Get('parameters', Params);
        foreach Entry in Params.AsArray() do
            if Entry.AsObject().Get('name', ParamName) then
                if ParamName.AsValue().AsText() = 'expectedCount' then begin
                    Found += 1;
                    Entry.AsObject().Get('description', Token);
                    Assert.IsTrue(Token.AsValue().AsText().StartsWith('Accepted and ignored.'), Name + ' expectedCount is ignored');
                end;
        Assert.AreEqual(1, Found, Name + ' still declares expectedCount exactly once');
    end;

    local procedure AssertWritesHelp(MessageType: Enum "Message Type ori")
    begin
        AssertSelection(MessageType, 1033, 'Writes.');
        AssertSelection(MessageType, 1039, 'Skrifar.');
        AssertSelectionLacks(MessageType, 1033, 'Irreversible');
        AssertSelectionLacks(MessageType, 1039, 'Óafturkræft');
        AssertSelectionLacks(MessageType, 1033, 'expectedCount');
        AssertSelectionLacks(MessageType, 1039, 'expectedCount');
    end;

    local procedure AssertSelectionLacks(MessageType: Enum "Message Type ori"; LanguageId: Integer; Unexpected: Text)
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
        Assert.IsFalse(Selection.Contains(Unexpected), 'Selection help in ' + Format(LanguageId) + ' does not say: ' + Unexpected);
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
