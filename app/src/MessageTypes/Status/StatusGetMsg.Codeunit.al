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
        DescriptionLbl: Label 'Get orchestrator health status and entry counts.', Comment = 'is-IS=Sækja heilsustöðu áætlara og fjölda færslna.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'orchestrator status, scheduler status, health, entry counts, job queue status', Comment = 'is-IS=staða áætlunar, staða vinnsluraðar, heilsa, fjöldi færslna, staða raðar';
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
    begin
        Envelope := Parts.NoSubjectEnvelope(false, 'text/json');
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
        AttentionFields: JsonArray;
    begin
        Parts.AddResponseField(EntryFields, 'total', 'integer', 'All orchestrator entries.');
        Parts.AddResponseField(EntryFields, 'blocked', 'integer', 'Blocked entries.');
        Parts.AddResponseField(EntryFields, 'active', 'integer', 'Entries that are not blocked.');
        Parts.AddResponseField(Fields, 'status', 'string', 'Success.');
        Parts.AddResponseField(Fields, 'orchestratorStatus', 'string', 'State of the management Job Queue Entry as a sentence in the session language: Job Queue is running, Job Queue execution has expired, please restart, Job Queue execution has failed, please restart, or Job Queue has not been configured.');
        Parts.AddResponseField(Fields, 'jobQueueCategoryCode', 'string', 'Job Queue Category Code of the scheduler setup, e.g. JOBSSCHDLR.');
        Parts.AddResponseField(Fields, 'logJobQueueActivity', 'boolean', 'Whether Job Queue activity is logged.');
        Parts.AddResponseField(Fields, 'entries', 'object', 'Counts of orchestrator entries.', EntryFields);
        Parts.AddResponseField(AttentionFields, 'entryId', 'string', 'Scheduled Entry primary-key GUID.');
        Parts.AddResponseField(AttentionFields, 'description', 'string', 'Scheduled Entry description.');
        Parts.AddResponseField(AttentionFields, 'code', 'string', 'ReferenceStartingTimeBlank, OverdueNoRun, SilentlySkipped or NoJobQueueEntry.');
        Parts.AddResponseField(AttentionFields, 'nextStep', 'string', 'Actionable guidance in the session language.');
        Parts.AddResponseField(Fields, 'attention', 'array', AttentionDescriptionTxt, AttentionFields);
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
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Steps: JsonArray;
    begin
        Steps.Add(ContractMgt.WorkflowStep('Orchestrator.Status.Get', 'Read orchestratorStatus and the entry counts.'));
        Steps.Add(ContractMgt.WorkflowStep('Orchestrator.Status.RestartIfNeeded', 'When the management job has expired or failed, schedule it again without disturbing a running one.'));
        Steps.Add(ContractMgt.WorkflowStep('Orchestrator.Status.Get', 'Read the status again to confirm.'));
        Workflow.Add('steps', Steps);
        exit(true);
    end;

    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.Example(Examples, 'Read status', '{"type":"Orchestrator.Status.Get"}', '{"status":"Success","orchestratorStatus":"Job Queue is running","jobQueueCategoryCode":"JOBSSCHDLR","logJobQueueActivity":true,"entries":{"total":10,"blocked":1,"active":9},"attention":[]}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Returns the health of the orchestrator''s management Job Queue Entry as a sentence for a person, the scheduler setup values and the counts of orchestrator entries (total, blocked, active). Read-only. Use it to check that scheduling is alive before relying on it.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'orchestratorStatus is meant for a person, not for a comparison: it is translated. Expired means the management Job Queue Entry has expired, or it is ready to start but its earliest start lies more than a minute in the past; any other state of an existing entry is reported as failed. Orchestrator.Status.Restart fixes both; Orchestrator.Status.RestartIfNeeded leaves a Ready or In Process entry alone even when it has expired. The active count is the entries that are not blocked.' + ' ' + AttentionNotesTxt;
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
        AttentionDescriptionTxt: Label 'Read-only schedule warnings for non-blocked entries; empty for a healthy setup.', Comment = 'is-IS=Viðvaranir um tímasetningar ólokaðra færslna, aðeins til lestrar; tómt þegar uppsetning er heilbrigð.';
        AttentionNotesTxt: Label 'attention lists entryId, description, code and nextStep. ReferenceStartingTimeBlank means Starting Time is set but its reference is blank. OverdueNoRun means no successful log exists after one configured interval plus a 15-minute grace period from entry creation. SilentlySkipped means at least one due slot was skipped. NoJobQueueEntry means the active entry has no job. These checks never repair records. A due slot moved to a later day, or a third consecutive skipped slot, sends a warning using the configured notification type. Repeated handling of the same slot does not send again; normal waiting before the window opens does not notify. Successful execution resets the skip diagnostics.', Comment = 'is-IS=attention sýnir entryId, description, code og nextStep. ReferenceStartingTimeBlank merkir að upphafstími sé tilgreindur en viðmiðun hans vanti. OverdueNoRun merkir að engin heppnuð keyrsla hafi verið skráð eftir eitt stillt keyrslubil og 15 mínútna svigrúm frá stofnun færslu. SilentlySkipped merkir að að minnsta kosti einni áætlaðri keyrslu hafi verið sleppt. NoJobQueueEntry merkir að virka færslan hafi enga vinnsluraðafærslu. Þessar athuganir laga aldrei færslur. Keyrsla sem er færð á síðari dag, eða þriðja keyrsla í röð sem er sleppt, sendir viðvörun með stilltri tilkynningartegund. Sama keyrslubil sendir ekki aftur; venjuleg bið eftir tímaglugga sendir enga tilkynningu. Heppnuð keyrsla núllstillir greiningu á slepptum keyrslum.';
}
