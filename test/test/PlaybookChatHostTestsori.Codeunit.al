namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>
/// Host wiring for the Bifrost Chat FactBox on Playbook Card. The control add-in is not driven;
/// visibility follows ShowBifrostChat and the recorded context is the SetRecordContext arguments.
/// </summary>
codeunit 96475 "Playbook Chat Host Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    /// <summary>The chat part stays hidden when ShowBifrostChat is false, and no context is applied.</summary>
    [Test]
    procedure FactBoxHiddenWhenChatIsNotShown()
    var
        Playbook: Record "Playbook ori";
        Assert: Codeunit "Library Assert";
        Lib: Codeunit "Playbook Test Library ori";
        Subscriber: Codeunit "Playbook Chat Host Sub ori";
        Card: TestPage "Playbook Card ori";
        PlaybookCode: Code[20];
        PreviousProvider: Enum "Chat Provider Type ori";
    begin
        // [SCENARIO] #170 AC03: the part is hidden when ShowBifrostChat is false.
        PlaybookCode := NewCode('H');
        Lib.CreatePlaybook(PlaybookCode);
        PreviousProvider := UseChatVisibility(false);
        Subscriber.Reset();
        BindSubscription(Subscriber);
        Playbook.Get(PlaybookCode);
        Card.OpenEdit();
        Card.GoToRecord(Playbook);
        Assert.IsFalse(Card.BifrostChat.Visible(), 'Chat FactBox is hidden when ShowBifrostChat is false.');
        Assert.AreEqual(0, Subscriber.GetAppliedCount(), 'A hidden FactBox does not receive record context.');
        Card.Close();
        UnbindSubscription(Subscriber);
        RestoreChatProvider(PreviousProvider);
        Lib.Cleanup(PlaybookCode);
    end;

    /// <summary>The chat part shows the current playbook and updates when the record changes.</summary>
    [Test]
    procedure FactBoxFollowsCurrentPlaybookWhenChatIsShown()
    var
        FirstPlaybook: Record "Playbook ori";
        SecondPlaybook: Record "Playbook ori";
        Assert: Codeunit "Library Assert";
        Lib: Codeunit "Playbook Test Library ori";
        Subscriber: Codeunit "Playbook Chat Host Sub ori";
        Card: TestPage "Playbook Card ori";
        FirstCode: Code[20];
        SecondCode: Code[20];
        PreviousProvider: Enum "Chat Provider Type ori";
        TableId: Integer;
        RecordSystemId: Guid;
        DataCaption: Text;
    begin
        // [SCENARIO] #170 AC01 AC02 AC03: the part is visible and context follows the current playbook.
        FirstCode := NewCode('A');
        SecondCode := NewCode('B');
        Lib.CreatePlaybook(FirstCode);
        Lib.CreatePlaybook(SecondCode);
        FirstPlaybook.Get(FirstCode);
        FirstPlaybook.Description := 'Alpha playbook';
        FirstPlaybook.Modify(true);
        SecondPlaybook.Get(SecondCode);
        SecondPlaybook.Description := 'Beta playbook';
        SecondPlaybook.Modify(true);
        PreviousProvider := UseChatVisibility(true);
        Subscriber.Reset();
        BindSubscription(Subscriber);
        Card.OpenEdit();
        Card.GoToRecord(FirstPlaybook);
        Assert.IsTrue(Card.BifrostChat.Visible(), 'Chat FactBox is shown when ShowBifrostChat is true.');
        Subscriber.GetLast(TableId, RecordSystemId, DataCaption);
        Assert.AreEqual(Database::"Playbook ori", TableId, 'Context table is the playbook table.');
        Assert.AreEqual(FirstPlaybook.SystemId, RecordSystemId, 'Context is the current playbook.');
        Assert.AreEqual(StrSubstNo('%1 %2', FirstPlaybook.Code, FirstPlaybook.Description), DataCaption, 'Caption includes the playbook code.');
        Card.GoToRecord(SecondPlaybook);
        Subscriber.GetLast(TableId, RecordSystemId, DataCaption);
        Assert.AreEqual(SecondPlaybook.SystemId, RecordSystemId, 'Changing the record updates the context.');
        Assert.AreEqual(StrSubstNo('%1 %2', SecondPlaybook.Code, SecondPlaybook.Description), DataCaption, 'Updated caption includes the new playbook code.');
        Assert.IsTrue(Subscriber.GetAppliedCount() >= 2, 'Each current record applies its own context.');
        Card.Close();
        UnbindSubscription(Subscriber);
        RestoreChatProvider(PreviousProvider);
        Lib.Cleanup(FirstCode);
        Lib.Cleanup(SecondCode);
    end;

    local procedure NewCode(Prefix: Text[1]) PlaybookCode: Code[20]
    begin
        PlaybookCode := CopyStr(Prefix + DelChr(Format(CreateGuid(), 0, 4), '=', '{}-'), 1, MaxStrLen(PlaybookCode));
    end;

    local procedure UseChatVisibility(Shown: Boolean) PreviousProvider: Enum "Chat Provider Type ori"
    var
        BifrostSetup: Record "Setup ori";
        Provider: Codeunit "Chat Host Provider ori";
    begin
        if not BifrostSetup.Get() then begin
            BifrostSetup.Init();
            BifrostSetup.Insert(true);
        end;
        PreviousProvider := BifrostSetup."Chat Provider Type";
        if Shown then
            BifrostSetup."Chat Provider Type" := "Chat Provider Type ori"::"Orch Test Chat"
        else
            BifrostSetup."Chat Provider Type" := "Chat Provider Type ori"::None;
        BifrostSetup.Modify(true);
        Provider.SetConfigured(Shown);
    end;

    local procedure RestoreChatProvider(PreviousProvider: Enum "Chat Provider Type ori")
    var
        BifrostSetup: Record "Setup ori";
        Provider: Codeunit "Chat Host Provider ori";
    begin
        Provider.SetConfigured(false);
        if not BifrostSetup.Get() then
            exit;
        BifrostSetup."Chat Provider Type" := PreviousProvider;
        BifrostSetup.Modify(true);
    end;
}
