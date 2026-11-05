namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;

/// <summary>
/// One deterministic stand-in for the four artifact-chain types (storage read, Ask, sanitize, email draft), chosen by the
/// request keys. It reads and writes nothing outside the session state and sends no email.
/// </summary>
codeunit 96462 "Artifact Mock Msg ori" implements "Msg Interface ori", "Msg Contract ori"
{

    /// <summary>The fixture is always available in the test app.</summary>
    procedure IsEnabled(): Boolean
    begin
        exit(true);
    end;

    /// <summary>No business table is bound to the fixture.</summary>
    procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    /// <summary>Describes the test fixture.</summary>
    procedure GetDescription(): Text[250]
    begin
        exit('Deterministic artifact chain stand-in');
    end;

    /// <summary>The fixture receives a test request.</summary>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Inbound);
    end;

    /// <summary>Answers as storage (asText), Ask (question), sanitize (html) or email draft (to), by request key.</summary>
    /// <param name="Argument">Test request and response.</param>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        State: Codeunit "Artifact Mock State ori";
        Scrub: Codeunit "Playbook Response Scrub ori";
        Request: JsonObject;
        Response: JsonObject;
        Token: JsonToken;
        Html: Text;
    begin
        Request := Argument.GetRequestJson();
        Response.Add('status', 'Success');
        case true of
            Request.Contains('asText'):
                begin
                    Response.Add('content', State.GetArtifactText());
                    Response.Add('contentType', 'text/html');
                    Response.Add('recipient', 'artifact-test@example.invalid');
                end;
            Request.Contains('question'):
                begin
                    Scrub.AddTestType('Test.Orchestrator.Artifact.Ask');
                    Request.Get('question', Token);
                    State.CountAsk(Token.AsValue().AsText());
                    Response.Add('html', CopyStr(Token.AsValue().AsText(), StrPos(Token.AsValue().AsText(), HtmlMarkerTok) + StrLen(HtmlMarkerTok)));
                    Response.Add('stopReason', 'answered');
                    Response.Add('trace', 'XARTIFACT-PRIVATE-TRACE');
                end;
            Request.Contains('html'):
                begin
                    Request.Get('html', Token);
                    Html := Token.AsValue().AsText();
                    State.CountSanitize();
                    if (State.GetSanitizeCap() > 0) and (StrLen(Html) > State.GetSanitizeCap()) then begin
                        Argument.SetResponseText(TooLargeResponseTok);
                        exit;
                    end;
                    if Html.ToLower().Contains('<script') then begin
                        Argument.SetResponseText(NotHtmlResponseTok);
                        exit;
                    end;
                    Response.Add('html', Html);
                end;
            Request.Contains('to'):
                begin
                    State.CountEmail(AttachmentTextOf(Request));
                    Response.Add('outboxSystemId', MockOutboxTok);
                end;
        end;
        Argument.SetResponseText(Format(Response));
    end;

    local procedure AttachmentTextOf(Request: JsonObject): Text
    var
        Token: JsonToken;
        Attachment: JsonToken;
    begin
        if not Request.Get('attachments', Token) then
            exit('');
        if not Token.IsArray() then
            exit('');
        if Token.AsArray().Count() = 0 then
            exit('');
        Token.AsArray().Get(0, Attachment);
        if not Attachment.AsObject().Get('contentText', Token) then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    /// <summary>Declares the test request envelope.</summary>
    /// <param name="Envelope">Receives the envelope.</param>
    /// <returns>True; the fixture has a contract.</returns>
    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Subject: JsonObject;
    begin
        Subject.Add('use', 'notUsed');
        Envelope.Add('subject', Subject);
        Envelope.Add('dataRequired', false);
        Envelope.Add('version', '1.0');
        Envelope.Add('contentType', 'text/json');
        exit(true);
    end;

    /// <summary>Declares the request keys the artifact templates send.</summary>
    /// <param name="Parameters">Receives the fixture parameters.</param>
    /// <returns>True; no other request parameters are accepted.</returns>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('question', 'string', false, 'Ask: the instruction with the artifact.'));
        Parameters.Add(ContractMgt.Parameter('asText', 'boolean', false, 'Storage: return text.'));
        Parameters.Add(ContractMgt.Parameter('html', 'string', false, 'Sanitize: the html.'));
        Parameters.Add(ContractMgt.Parameter('to', 'array', false, 'Email: recipients.'));
        Parameters.Add(ContractMgt.Parameter('attachments', 'array', false, 'Email: attachments.'));
        exit(true);
    end;

    /// <summary>The fixture returns constant data and changes no business records.</summary>
    /// <param name="Effect">Receives the effect.</param>
    /// <returns>True; the fixture is read-only.</returns>
    procedure GetEffect(var Effect: JsonObject): Boolean
    begin
        Effect.Add('effect', 'read');
        Effect.Add('changes', 'Returns deterministic test data; no business records change.');
        Effect.Add('idempotent', true);
        exit(true);
    end;

    /// <summary>No additional target chapter is required by the fixture.</summary>
    /// <param name="Target">Unused optional chapter.</param>
    /// <returns>False; this chapter is absent.</returns>
    procedure GetTarget(var Target: JsonArray): Boolean
    begin
        exit(false);
    end;

    /// <summary>No additional response chapter is required by the fixture.</summary>
    /// <param name="Response">Unused optional chapter.</param>
    /// <returns>False; this chapter is absent.</returns>
    procedure GetResponse(var Response: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>No additional errors chapter is required by the fixture.</summary>
    /// <param name="Errors">Unused optional chapter.</param>
    /// <returns>False; this chapter is absent.</returns>
    procedure GetErrors(var Errors: JsonArray): Boolean
    begin
        exit(false);
    end;

    /// <summary>No additional metering chapter is required by the fixture.</summary>
    /// <param name="Metering">Unused optional chapter.</param>
    /// <returns>False; this chapter is absent.</returns>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>No additional related chapter is required by the fixture.</summary>
    /// <param name="Related">Unused optional chapter.</param>
    /// <returns>False; this chapter is absent.</returns>
    procedure GetRelated(var Related: JsonArray): Boolean
    begin
        exit(false);
    end;

    /// <summary>No additional workflow chapter is required by the fixture.</summary>
    /// <param name="Workflow">Unused optional chapter.</param>
    /// <returns>False; this chapter is absent.</returns>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>No additional examples chapter is required by the fixture.</summary>
    /// <param name="Examples">Unused optional chapter.</param>
    /// <returns>False; this chapter is absent.</returns>
    procedure GetExamples(var Examples: JsonArray): Boolean
    begin
        exit(false);
    end;

    /// <summary>No additional overview chapter is required by the fixture.</summary>
    /// <param name="Overview">Unused optional chapter.</param>
    /// <returns>False; this chapter is absent.</returns>
    procedure GetOverview(var Overview: Text): Boolean
    begin
        Clear(Overview);
        exit(false);
    end;

    /// <summary>No additional notes chapter is required by the fixture.</summary>
    /// <param name="Notes">Unused optional chapter.</param>
    /// <returns>False; this chapter is absent.</returns>
    procedure GetNotes(var Notes: Text): Boolean
    begin
        Clear(Notes);
        exit(false);
    end;

    var
        HtmlMarkerTok: Label 'HTML: ', Locked = true;
        MockOutboxTok: Label 'MOCK-OUTBOX', Locked = true;
        TooLargeResponseTok: Label '{"status":"Error","code":"TooLarge","error":"The html is larger than the size cap."}', Locked = true;
        NotHtmlResponseTok: Label '{"status":"Error","code":"NotHtml","error":"The answer is not clean html."}', Locked = true;
}
