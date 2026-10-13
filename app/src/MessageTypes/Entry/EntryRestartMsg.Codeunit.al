/// <summary>
/// Implements the Orchestrator.JobQueueEntry.Restart message type: restarts a Job Queue Entry by
/// setting its status to Ready.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035567 "Entry Restart Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
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
        DescriptionLbl: Label 'Restart a Job Queue Entry by setting status to Ready.', Comment = 'is-IS=Endurræsa vinnsluröðarfærslu með því að setja stöðu á Tilbúið.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'restart job queue entry, restart entry, set ready, retry job queue', Comment = 'is-IS=endurræsa vinnsluröðarfærslu, endurræsa færslu, setja tilbúið, reyna vinnsluröð aftur';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Restart a Job Queue Entry unconditionally by setting it to Ready. Write operation. Use Orchestrator.JobQueueEntry.RestartIfNeeded to restart only failed or held entries.', Comment = 'is-IS=Endurræstu vinnsluröðarfærslu skilyrðislaust með því að setja hana í Tilbúið. Skrifaðgerð. Notaðu Orchestrator.JobQueueEntry.RestartIfNeeded til að endurræsa aðeins bilaðar eða stöðvaðar færslur.';
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
        Parts.AddResponseField(Fields, 'message', 'string', 'Job Queue Entry restarted. (translated to the session language).');
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
        Effect := Parts.Effect('write', 'Sets the Job Queue Entry status to Ready.', true, '', Preconditions);
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
        Parts.Related(Related, 'Orchestrator.JobQueueEntry.RestartIfNeeded', 'Use this when restart should happen only for Error or On Hold entries.');
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
        Parts.Example(Examples, 'Restart an entry', '{"type":"Orchestrator.JobQueueEntry.Restart","data":{"id":"<systemId>"}}', '{"status":"Success","id":"<systemId>","entryStatus":"Ready","description":"Post inventory cost","message":"Job Queue Entry restarted."}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Sets the selected Job Queue Entry to Ready regardless of its current state.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'The status is set to Ready whatever it was, In Process included. Use Orchestrator.JobQueueEntry.RestartIfNeeded when a Ready or running entry must not be disturbed, and Orchestrator.Entry.Restart for an entry the orchestrator manages, so its retry policy and notifications apply.';
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
        Handler: Codeunit "Entry Msg Handler ori";
}
