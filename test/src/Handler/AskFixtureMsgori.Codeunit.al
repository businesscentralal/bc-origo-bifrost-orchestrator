namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;

/// <summary>A deterministic, dependency-free Ask-shaped response dispatched through the real message loop.</summary>
codeunit 96445 "Ask Fixture Msg ori" implements "Msg Interface ori"
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
    begin
        Argument.SetResponseText('{"status":"Success","trace":{"secret":"XASK-PRIVATE-TRACE"},"answer":"audit complete","data":{"verdict":"pass","findings":[],"trace":"nested-kept"},"schemaValid":true,"toolCalls":2,"noOfRecords":2,"result":[{"value":"owned-fixture"}]}');
    end;
}
