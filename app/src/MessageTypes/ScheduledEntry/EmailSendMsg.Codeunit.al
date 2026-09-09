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

    procedure IsEnabled(): Boolean
    begin
        exit(true);
    end;

    procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    procedure GetDescription(): Text[250]
    var
        DescriptionLbl: Label 'Send an email draft created by Email.Draft.Set.', Comment = 'is-IS=Senda drög tölvupósts stofnuð af Email.Draft.Set.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Inbound);
    end;

    procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Help ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp('Orchestrator.Email.Send'));
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
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

        // KNOWN GAP: there is no ownership check here. This codeunit elevates itself with
        // Permissions = tabledata "Email Outbox" = RIMD, so a caller who learns another user's
        // outbox SystemId can make this message type send that user's draft. The System
        // Application does not expose the owner: "Email Outbox"."User Security Id" is
        // Access = Internal, the only accessors are GetMessageId/GetAccountId/GetConnector, and
        // query "Outbox Emails" is Access = Internal too. Closing this needs a design decision -
        // see the PR gateway report of 2026-09-07.
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
