/// <summary>
/// Implements the Orchestrator.Status.RestartIfNeeded message type: restarts the orchestrator only
/// when it is not already running.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035561 "Status RestartIf Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;

    /// <summary>
    /// Determines whether this message type is enabled.
    /// </summary>
    /// <returns>True; this message type is always enabled.</returns>
    procedure IsEnabled(): Boolean
    begin
        exit(true);
    end;

    /// <summary>
    /// Returns the table ID used to filter records for this message type.
    /// </summary>
    /// <returns>Zero; this message type is not bound to a table.</returns>
    procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    /// <summary>
    /// Returns a human-readable description of this message type.
    /// </summary>
    /// <returns>Description text.</returns>
    procedure GetDescription(): Text[250]
    var
        DescriptionLbl: Label 'Restart the orchestrator only if not already running.', Comment = 'is-IS=Endurræsa áætlara aðeins ef hann er ekki þegar í gangi.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'restart orchestrator if needed, conditional scheduler restart, ensure orchestrator running', Comment = 'is-IS=endurræsa áætlara ef þarf, skilyrt endurræsing stjóra, tryggja að áætlari sé í gangi';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Restart the orchestrator only when its management Job Queue Entry is not Ready or In Process. Irreversible. Use Orchestrator.Status.Restart for an unconditional restart.', Comment = 'is-IS=Endurræstu áætlara aðeins þegar stjórnunarfærsla hans er ekki Tilbúin eða Í vinnslu. Óafturkræft. Notaðu Orchestrator.Status.Restart fyrir skilyrðislausa endurræsingu.';
    begin
        exit(SelectionLbl);
    end;

    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Forms: List of [Text];
    begin
        Envelope := Parts.Envelope(Forms, 'No subject is used.', false);
        exit(true);
    end;

    procedure GetTarget(var Target: JsonArray): Boolean
    begin
        exit(false);
    end;

    procedure GetParameters(var Parameters: JsonArray): Boolean
    begin
        exit(false);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Fields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'status', 'string', 'Success.');
        Parts.AddResponseField(Fields, 'message', 'string', 'Orchestrator is already running. or Orchestrator restarted. (translated).');
        Parts.AddResponseField(Fields, 'restarted', 'boolean', 'Whether a restart was performed.');
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.AddRuntimeError(Errors, 'The scheduler cannot be inspected or restarted.', 'Check scheduler setup and Job Queue permissions.');
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Effect := Parts.CommittingEffect('Restarts the orchestrator only when its management entry is not Ready or In Process; the restart cancels and schedules the management Job Queue Entry and commits.', true);
        exit(true);
    end;

    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    procedure GetRelated(var Related: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.Related(Related, 'Orchestrator.Status.Restart', 'Use this when the orchestrator must be restarted regardless of status.');
        exit(true);
    end;

    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        exit(false);
    end;

    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.Example(Examples, 'Ensure running', '{"type":"Orchestrator.Status.RestartIfNeeded"}', '{"status":"Success","message":"Orchestrator is already running.","restarted":false}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Ensures that the orchestrator management Job Queue Entry is scheduled without interrupting a running entry.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'When the management Job Queue Entry exists and is Ready or In Process nothing changes and the answer is restarted false. In every other case (no entry, Error, On Hold, ...) it is cancelled and scheduled again as Orchestrator.Status.Restart does, and the answer is restarted true.';
        exit(true);
    end;

    /// <summary>
    /// Returns the message direction for this message type.
    /// </summary>
    /// <returns>Outbound direction.</returns>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Outbound);
    end;

    /// <summary>
    /// Executes the message type.
    /// </summary>
    /// <param name="Argument">Message argument carrying the request and receiving the response.</param>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteRestartIfNeeded(Argument);
    end;

    var
        Handler: Codeunit "Status Msg Handler ori";
}
