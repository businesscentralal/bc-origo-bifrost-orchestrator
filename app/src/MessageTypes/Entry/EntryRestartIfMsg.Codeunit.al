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
        Target := Parts.Target('data.id, subject', 'guid', 'The Job Queue Entry SystemId.');
        exit(true);
    end;

    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('id', 'string', false, 'Job Queue Entry SystemId.'));
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Fields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'status', 'string', 'Success.');
        Parts.AddResponseField(Fields, 'id', 'string', 'Job Queue Entry SystemId.');
        Parts.AddResponseField(Fields, 'entryStatus', 'string', 'The resulting Job Queue status.');
        Parts.AddResponseField(Fields, 'description', 'string', 'Entry description.');
        Parts.AddResponseField(Fields, 'message', 'string', 'Result message.');
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.AddRecordErrors(Errors, 'Job Queue Entry');
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
        Parts.Example(Examples, 'Restart only when needed', '{"type":"Orchestrator.JobQueueEntry.RestartIfNeeded","data":{"id":"<systemId>"}}', '{"status":"Success","message":"No restart needed."}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Restarts the selected Job Queue Entry only when its status is Error or a held state.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'Ready and In Process entries are returned without changing them.';
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
    /// Returns Markdown help documentation for this message type.
    /// </summary>
    /// <param name="Argument">Message argument that receives the help text as response.</param>
    procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Help ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp('Orchestrator.JobQueueEntry.RestartIfNeeded'));
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
