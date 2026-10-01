/// <summary>
/// Implements the Orchestrator.JobQueueEntry.RestartIfNeeded message type: restarts a Job Queue Entry
/// only when it is in Error or a held state.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035568 "Entry RestartIf Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
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
        DescriptionLbl: Label 'Restart a Job Queue Entry only if in Error or On Hold.', Comment = 'is-IS=EndurrÃ¦sa vinnslurÃ¶Ã°arfÃ¦rslu aÃ°eins ef hÃºn er Ã­ villu eÃ°a Ã­ biÃ°.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'restart if needed, restart failed entry, restart held entry, conditional job queue restart', Comment = 'is-IS=endurræsa ef þarf, endurræsa bilaða færslu, endurræsa stöðvaða færslu, skilyrt endurræsing vinnsluraðar';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Restart a Job Queue Entry only when it is in Error or On Hold. Write operation. Use Orchestrator.JobQueueEntry.Restart for an unconditional restart.', Comment = 'is-IS=Endurræstu vinnsluröðarfærslu aðeins þegar hún er í villu eða í bið. Skrifaðgerð. Notaðu Orchestrator.JobQueueEntry.Restart fyrir skilyrðislausa endurræsingu.';
    begin
        exit(SelectionLbl);
    end;

    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Forms: List of [Text];
    begin
        Forms.Add('guid');
        Envelope := Parts.Envelope(Forms, 'The Job Queue Entry SystemId, supplied in data.id or as subject.', false);
        exit(true);
    end;

    procedure GetTarget(var Target: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Target := Parts.JobQueueEntryTarget();
        exit(true);
    end;

    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('id', 'string', false, 'SystemId of the Job Queue Entry. Required unless subject carries it.'));
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Fields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'status', 'string', 'Success.');
        Parts.AddResponseField(Fields, 'id', 'string', 'SystemId of the Job Queue Entry.');
        Parts.AddResponseField(Fields, 'entryStatus', 'string', 'Status after the call as its caption in the session language, e.g. Ready.');
        Parts.AddResponseField(Fields, 'description', 'string', 'Description of the Job Queue Entry.');
        Parts.AddResponseField(Fields, 'message', 'string', 'Job Queue Entry restarted. or No restart needed. (translated to the session language).');
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.AddJobQueueEntryErrors(Errors);
        Parts.AddRuntimeError(Errors, 'Business Central refuses to set the Job Queue Entry to Ready.', 'Read the text and fix the Job Queue Entry.');
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Preconditions: JsonArray;
    begin
        Effect := Parts.Effect('write', 'Sets the Job Queue Entry status to Ready only when it is Error or On Hold.', true, '', Preconditions);
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
        Parts.Related(Related, 'Orchestrator.JobQueueEntry.Restart', 'Use this when the entry must be restarted regardless of its current status.');
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
        Parts.Example(Examples, 'Restart only when needed', '{"type":"Orchestrator.JobQueueEntry.RestartIfNeeded","data":{"id":"<systemId>"}}', '{"status":"Success","id":"<systemId>","entryStatus":"Ready","description":"Post inventory cost","message":"No restart needed."}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Restarts the selected Job Queue Entry only when its status is Error or a held state.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'Only Error, On Hold and On Hold with Inactivity Timeout are set to Ready (message Job Queue Entry restarted.). Every other status, Ready and In Process included, is returned unchanged with message No restart needed.';
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
        Handler: Codeunit "Entry Msg Handler ori";
}
