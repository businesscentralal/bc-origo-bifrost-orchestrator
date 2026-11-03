namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;

/// <summary>
/// A canned Ask-shaped response for the posting-audit run test. One codeunit instance is shared with the
/// dispatcher so the test can switch every customer to pass after the mixed run.
/// </summary>
codeunit 96460 "Posting Audit Ask Msg ori" implements "Msg Interface ori", "Msg Contract ori"
{
    SingleInstance = true;

    var
        AllPass: Boolean;

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
        exit('Deterministic posting-audit Ask response');
    end;

    /// <summary>The fixture receives a test request.</summary>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Inbound);
    end;

    /// <summary>Answers pass, fail, unknown or Error from the customer number in the resolved question.</summary>
    /// <param name="Argument">Test request and response.</param>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        Question: Text;
    begin
        Question := QuestionOf(Argument.GetRequestJson());
        if AllPass or Question.Contains(PassNoTok) then begin
            Argument.SetResponseText(PassResponseTok);
            exit;
        end;
        if Question.Contains(FailNoTok) then begin
            Argument.SetResponseText(FailResponseTok);
            exit;
        end;
        if Question.Contains(UnknownNoTok) then begin
            Argument.SetResponseText(UnknownResponseTok);
            exit;
        end;
        if Question.Contains(ErrorNoTok) then begin
            Argument.SetResponseText(ErrorResponseTok);
            exit;
        end;
        Argument.SetResponseText(PassResponseTok);
    end;

    /// <summary>Makes every later call answer pass, including the customer that otherwise errors.</summary>
    /// <param name="Enabled">True to answer pass for every customer.</param>
    procedure SetAllPass(Enabled: Boolean)
    begin
        AllPass := Enabled;
    end;

    /// <summary>Clears the all-pass switch so the next test starts from the mixed answers.</summary>
    procedure Reset()
    begin
        AllPass := false;
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

    /// <summary>Declares the request keys the posting-audit template sends.</summary>
    /// <param name="Parameters">Receives the fixture parameters.</param>
    /// <returns>True; no other request parameters are accepted.</returns>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('question', 'string', true, 'The audit question, with the customer already filled in.'));
        Parameters.Add(ContractMgt.Parameter('record', 'string', true, 'The customer record id.'));
        Parameters.Add(ContractMgt.Parameter('limits', 'object', false, 'Explicit tool-call limit.'));
        Parameters.Add(ContractMgt.Parameter('responseSchema', 'object', true, 'Verdict and findings schema.'));
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

    local procedure QuestionOf(Request: JsonObject): Text
    var
        Token: JsonToken;
    begin
        if not Request.Get('question', Token) then
            exit('');
        if not Token.IsValue() then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    var
        PassNoTok: Label 'Z135A', Locked = true;
        FailNoTok: Label 'Z135B', Locked = true;
        UnknownNoTok: Label 'Z135C', Locked = true;
        ErrorNoTok: Label 'Z135D', Locked = true;
        PassResponseTok: Label '{"status":"Success","schemaValid":true,"stopReason":"answered","data":{"verdict":"pass","findings":[]}}', Locked = true;
        FailResponseTok: Label '{"status":"Success","schemaValid":true,"stopReason":"answered","data":{"verdict":"fail","findings":["Payment Terms Code"]}}', Locked = true;
        UnknownResponseTok: Label '{"status":"Success","schemaValid":true,"stopReason":"answered","data":{"verdict":"unknown","findings":["Gen. Bus. Posting Group"]}}', Locked = true;
        ErrorResponseTok: Label '{"status":"Error","code":"ModelError","error":"The model could not answer."}', Locked = true;
}
