/// <summary>
/// Implements the Orchestrator.Status.Get message type: returns the orchestrator health status
/// and entry counts.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035559 "Status Get Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
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
        DescriptionLbl: Label 'Get orchestrator health status and entry counts.', Comment = 'is-IS=SÃ¦kja heilsustÃ¶Ã°u Ã¡Ã¦tlara og fjÃ¶lda fÃ¦rslna.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'orchestrator status, scheduler status, health, entry counts, job queue status', Comment = 'is-IS=staða áætlunara, staða vinnsluraðar, heilsa, fjöldi færslna, staða vinnsluraðar, viðbót1';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Read the orchestrator health status and scheduled entry counts. Read-only. Use Orchestrator.Status.Restart to restart the orchestrator.', Comment = 'is-IS=Lestu heilsustöðu áætlunara og fjölda áætlaðra færslna. Lesaðgerð. Notaðu Orchestrator.Status.Restart til að endurræsa áætlunara.';
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
        EntryFields: JsonArray;
    begin
        Parts.AddResponseField(EntryFields, 'total', 'integer', 'All Scheduled Entry ori records.');
        Parts.AddResponseField(EntryFields, 'blocked', 'integer', 'Blocked entries.');
        Parts.AddResponseField(EntryFields, 'active', 'integer', 'Entries that are not blocked.');
        Parts.AddResponseField(Fields, 'status', 'string', 'Success.');
        Parts.AddResponseField(Fields, 'orchestratorStatus', 'string', 'State of the management Job Queue Entry as a sentence in the session language: Job Queue is running, Job Queue execution has expired, please restart, Job Queue execution has failed, please restart, or Job Queue has not been configured.');
        Parts.AddResponseField(Fields, 'jobQueueCategoryCode', 'string', 'Job Queue Category Code of the scheduler setup, e.g. JOBSSCHDLR.');
        Parts.AddResponseField(Fields, 'logJobQueueActivity', 'boolean', 'Whether Job Queue activity is logged.');
        Parts.AddResponseField(Fields, 'entries', 'object', 'Counts of orchestrator entries.', EntryFields);
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.AddRuntimeError(Errors, 'The scheduler setup cannot be read.', 'Check the orchestrator setup.');
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Preconditions: JsonArray;
    begin
        Effect := Parts.Effect('read', 'Reads scheduler setup and scheduled entry counts.', true, '', Preconditions);
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
        Parts.Related(Related, 'Orchestrator.Status.Restart', 'Use this when the orchestrator must be restarted.');
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
        Parts.Example(Examples, 'Read status', '{"type":"Orchestrator.Status.Get"}', '{"status":"Success","orchestratorStatus":"Job Queue is running","jobQueueCategoryCode":"JOBSSCHDLR","logJobQueueActivity":true,"entries":{"total":10,"blocked":1,"active":9}}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Returns the current orchestrator health, setup values and scheduled entry counts.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'orchestratorStatus is meant for a person, not for a comparison: it is translated. Expired means the management Job Queue Entry has expired, or it is ready to start but its earliest start lies more than a minute in the past; any other state of an existing entry is reported as failed. Orchestrator.Status.Restart fixes both; Orchestrator.Status.RestartIfNeeded leaves a Ready or In Process entry alone even when it has expired. The active count is the entries that are not blocked.';
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
        Handler.ExecuteGet(Argument);
    end;

    var
        Handler: Codeunit "Status Msg Handler ori";
}
