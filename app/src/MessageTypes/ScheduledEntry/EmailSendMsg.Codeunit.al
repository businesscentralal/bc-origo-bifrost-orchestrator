/// <summary>
/// Implements the Orchestrator.Email.Send message type: sends an email that was
/// previously created as a draft by Email.Draft.Set. Requires the outboxSystemId
/// from the draft response.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.EMail;

codeunit 10035582 "Email Send Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
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

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'send email, send draft, email outbox, deliver email, email message', Comment = 'is-IS=senda tölvupóst, senda drög, úthólf tölvupósts, afhenda tölvupóst, tölvupóstskilaboð';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Send an email draft identified by its outbox SystemId. Irreversible. Use Email.Draft.Set to create the draft first.', Comment = 'is-IS=Sendu tölvupóstsdrög sem auðkennd eru með SystemId úthólfs. Óafturkræft. Notaðu Email.Draft.Set til að búa til drögin fyrst.';
    begin
        exit(SelectionLbl);
    end;

    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Forms: List of [Text];
    begin
        Forms.Add('guid');
        Envelope := Parts.Envelope(Forms, 'The Email Outbox SystemId in data.outboxSystemId or as subject.', true);
        exit(true);
    end;

    procedure GetTarget(var Target: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Target := Parts.Target('data.outboxSystemId, subject', 'guid', 'The Email Outbox SystemId.');
        exit(true);
    end;

    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('outboxSystemId', 'string', false, 'Email Outbox SystemId returned by Email.Draft.Set.'));
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Fields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'status', 'string', 'Success.');
        Parts.AddResponseField(Fields, 'messageId', 'string', 'Sent email message identifier.');
        Parts.AddResponseField(Fields, 'outboxSystemId', 'string', 'Source outbox SystemId.');
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.AddRecordErrors(Errors, 'Email Outbox');
        Parts.AddRuntimeError(Errors, 'The outboxSystemId is missing or the email cannot be sent.', 'Send the GUID of a draft and check the email setup.');
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Preconditions: JsonArray;
    begin
        Effect := Parts.Effect('irreversible', 'Sends the email draft and creates a sent email.', false, '', Preconditions);
        exit(true);
    end;

    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    procedure GetRelated(var Related: JsonArray): Boolean
    begin
        exit(false);
    end;

    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        exit(false);
    end;

    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.Example(Examples, 'Send a draft', '{"type":"Orchestrator.Email.Send","data":{"outboxSystemId":"<systemId>"}}', '{"status":"Success","outboxSystemId":"<systemId>"}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Sends an existing Email Outbox draft and returns its message identifiers.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'The message can send a draft when the caller has its SystemId; ownership is not checked by the current implementation.';
        exit(true);
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
