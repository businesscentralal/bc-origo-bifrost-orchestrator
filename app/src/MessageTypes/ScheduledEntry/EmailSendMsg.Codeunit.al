/// <summary>
/// Implements the Orchestrator.Email.Send message type: sends an email that was
/// previously created as a draft by Email.Draft.Set. Requires the outboxSystemId
/// from the draft response.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.EMail;

codeunit 10035582 "Email Send Msg ori" implements "Msg Interface ori"
{
    Access = Internal;
    Permissions = tabledata "Email Outbox" = RIMD,
                  tabledata "Sent Email" = R;

    internal procedure IsEnabled(): Boolean
    begin
        exit(true);
    end;

    internal procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    internal procedure GetDescription(): Text[250]
    var
        DescriptionLbl: Label 'Send an email draft created by Email.Draft.Set.', Comment = 'is-IS=Senda drög tölvupósts stofnuð af Email.Draft.Set.';
    begin
        exit(DescriptionLbl);
    end;

    internal procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Inbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Help ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp('Orchestrator.Email.Send'));
    end;

    internal procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        EmailOutbox: Record "Email Outbox";
        Email: Codeunit Email;
        EmailMessage: Codeunit "Email Message";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        OutboxSystemId: Guid;
    begin
        RequestJson := Argument.GetRequestJson();

        if not Argument.TryGetGuidFromJson(RequestJson, 'outboxSystemId', OutboxSystemId) then
            if Argument.SubjectIsGuid() then
                Evaluate(OutboxSystemId, Argument.Subject)
            else
                Error(MissingOutboxIdErr);

        EmailOutbox.GetBySystemId(OutboxSystemId);
        EmailMessage.Get(EmailOutbox.GetMessageId());
        Email.Send(EmailMessage);

        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('messageId', Format(EmailOutbox.GetMessageId(), 0, 4));
        ResponseJson.Add('outboxSystemId', Format(OutboxSystemId, 0, 4));
        Argument.SetResponseJson(ResponseJson);
    end;

    var
        MissingOutboxIdErr: Label '"outboxSystemId" (GUID from Email.Draft.Set response) is required in data or as subject.', Comment = 'is-IS="outboxSystemId" (GUID frá Email.Draft.Set svari) er nauðsynlegt í gögnum eða sem viðfang.';
}
