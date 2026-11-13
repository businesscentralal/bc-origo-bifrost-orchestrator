namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost.Orchestrator;

/// <summary>Records the playbook context the card passed to the chat FactBox.</summary>
codeunit 96478 "Playbook Chat Host Sub ori"
{
    EventSubscriberInstance = Manual;
    SingleInstance = true;

    var
        AppliedCount: Integer;
        LastTableId: Integer;
        LastSystemId: Guid;
        LastCaption: Text;

    /// <summary>Clears recorded context before a scenario.</summary>
    procedure Reset()
    begin
        AppliedCount := 0;
        LastTableId := 0;
        Clear(LastSystemId);
        LastCaption := '';
    end;

    /// <summary>How many times the card applied a context during this bind.</summary>
    procedure GetAppliedCount(): Integer
    begin
        exit(AppliedCount);
    end;

    /// <summary>The last context arguments passed to SetRecordContext.</summary>
    procedure GetLast(var TableId: Integer; var RecordSystemId: Guid; var DataCaption: Text)
    begin
        TableId := LastTableId;
        RecordSystemId := LastSystemId;
        DataCaption := LastCaption;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Playbook Card ori", 'OnChatRecordContextApplied', '', false, false)]
    local procedure OnChatRecordContextApplied(TableId: Integer; RecordSystemId: Guid; DataCaption: Text)
    begin
        AppliedCount += 1;
        LastTableId := TableId;
        LastSystemId := RecordSystemId;
        LastCaption := DataCaption;
    end;
}
