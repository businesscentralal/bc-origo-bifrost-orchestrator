namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;

/// <summary>A deterministic, dependency-free Ask-shaped response dispatched through the real message loop.</summary>
codeunit 96445 "Ask Fixture Msg ori" implements "Msg Interface ori", "Msg Contract ori"
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
        exit('Deterministic Ask response fixture');
    end;

    /// <summary>The fixture receives a test request.</summary>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Inbound);
    end;

    /// <summary>Returns a trace plus fields whose preservation is asserted by the persistence tests.</summary>
    /// <param name="Argument">Test request and response.</param>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        Scrub: Codeunit "Playbook Response Scrub ori";
    begin
        // Register only this test fixture in the dispatch session, including owned UI/MCP checks.
        Scrub.AddTestType('Test.Orchestrator.Ask');
        Argument.SetResponseText('{"status":"Success","trace":{"secret":"XASK-PRIVATE-TRACE"},"answer":"audit complete","data":{"verdict":"pass","findings":[],"trace":"nested-kept"},"schemaValid":true,"toolCalls":2,"noOfRecords":2,"result":[{"value":"owned-fixture"}]}');
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

    /// <summary>Declares the pagination keys added by the real paged runner.</summary>
    /// <param name="Parameters">Receives the fixture parameters.</param>
    /// <returns>True; no other request parameters are accepted.</returns>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('includeTrace', 'boolean', false, 'Fixture trace warning input.'));
        Parameters.Add(ContractMgt.Parameter('skip', 'integer', false, 'Fixture page offset.'));
        Parameters.Add(ContractMgt.Parameter('take', 'integer', false, 'Fixture page size.'));
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
}
