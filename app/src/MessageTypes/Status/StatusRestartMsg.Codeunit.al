/// <summary>
/// Implements the Orchestrator.Status.Restart message type: unconditionally restarts the
/// orchestrator management Job Queue Entry.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035560 "Status Restart Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
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
        DescriptionLbl: Label 'Unconditionally restart the orchestrator.', Comment = 'is-IS=EndurrÃ¦sa Ã¡Ã¦tlara skilyrÃ°islaust.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'restart orchestrator, restart scheduler, restart management job queue, force restart', Comment = 'is-IS=endurræsa áætlara, endurræsa stjóra, endurræsa stjórnun vinnsluraðar, þvinga endurræsingu';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Restart the orchestrator management Job Queue Entry unconditionally. Write operation. Use Orchestrator.Status.RestartIfNeeded when an already running orchestrator must be preserved.', Comment = 'is-IS=Endurræstu stjórnunarfærslu áætlunara skilyrðislaust. Skrifaðgerð. Notaðu Orchestrator.Status.RestartIfNeeded þegar halda á gangandi áætlunara.';
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
        Parts.AddResponseField(Fields, 'message', 'string', 'Orchestrator restarted. (translated).');
        Parts.AddResponseField(Fields, 'orchestratorStatus', 'string', 'State after scheduling, as a sentence in the session language: Job Queue is running, Job Queue execution has expired, please restart, Job Queue execution has failed, please restart, or Job Queue has not been configured.');
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.AddRuntimeError(Errors, 'The scheduler cannot be restarted.', 'Check scheduler setup and Job Queue permissions.');
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Preconditions: JsonArray;
    begin
        Effect := Parts.Effect('write', 'Cancels and schedules the orchestrator management Job Queue Entry.', false, '', Preconditions);
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
        Parts.Related(Related, 'Orchestrator.Status.RestartIfNeeded', 'Use this when a running orchestrator should not be interrupted.');
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
        Parts.Example(Examples, 'Restart orchestrator', '{"type":"Orchestrator.Status.Restart"}', '{"status":"Success","message":"Orchestrator restarted.","orchestratorStatus":"Job Queue is running"}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Cancels and schedules the orchestrator management Job Queue Entry.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'This operation is unconditional and can interrupt a currently running management job.';
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
        Handler.ExecuteRestart(Argument);
    end;

    var
        Handler: Codeunit "Status Msg Handler ori";
}
