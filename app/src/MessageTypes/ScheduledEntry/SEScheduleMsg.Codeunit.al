/// <summary>
/// Implements the Orchestrator.Entry.Schedule message type: schedules an
/// orchestrator entry for immediate execution.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035581 "SE Schedule Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;

    procedure IsEnabled(): Boolean
    begin
        exit(true);
    end;

    procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    procedure GetDescription(): Text[250]
    var
        DescriptionLbl: Label 'Rebuild the Job Queue schedule of an orchestrator entry.', Comment = 'is-IS=Endurbyggja vinnsluraðaráætlun áætlunarfærslu.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'schedule entry, reschedule entry, rebuild job queue schedule, run entry now', Comment = 'is-IS=áætlun færslu, enduráætlun færslu, endurbyggja vinnsluraðaráætlun, keyra færslu núna';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Rebuild the Job Queue schedule of an orchestrator entry from its recurrence settings. Irreversible. A blocked entry is refused. Use Orchestrator.Entry.Run for a foreground run that leaves the schedule intact.', Comment = 'is-IS=Endurbyggðu vinnsluraðaráætlun áætlunarfærslu út frá endurtekningarstillingum hennar. Óafturkræft. Læstri færslu er hafnað. Notaðu Orchestrator.Entry.Run fyrir keyrslu í forgrunni sem skilur áætlunina eftir.';
    begin
        exit(SelectionLbl);
    end;

    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Forms: List of [Text];
    begin
        Forms.Add('guid');
        Envelope := Parts.Envelope(Forms, 'The Scheduled Entry SystemId in data.id or as subject.', false);
        exit(true);
    end;

    procedure GetTarget(var Target: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Target := Parts.ScheduledEntryTarget();
        exit(true);
    end;

    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('id', 'string', false, 'SystemId, or ID, of the orchestrator entry (Job Queue Orchestrator Entry). Required unless subject carries it.'));
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Fields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'status', 'string', 'Success.');
        Parts.AddResponseField(Fields, 'id', 'string', 'SystemId of the orchestrator entry.');
        Parts.AddResponseField(Fields, 'blocked', 'boolean', 'Whether the entry is blocked.');
        Parts.AddResponseField(Fields, 'message', 'string', 'Orchestrator entry scheduled. (translated).');
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.AddScheduledEntryErrors(Errors);
        Parts.AddRuntimeError(Errors, 'The entry is blocked (Business Central''s TestField error on Blocked).', 'Unblock the entry first.');
        Parts.AddRuntimeError(Errors, 'The scheduling API call or the local scheduling fails.', 'Check the entry''s client credentials and the scheduler setup.');
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Effect := Parts.CommittingEffect('Rebuilds the Job Queue schedule of the orchestrator entry. With client credentials the scheduling API commits the change in its own session; otherwise the Job Queue Entry is deleted and created again.', false);
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
        Parts.Related(Related, 'Orchestrator.Entry.Run', 'Use this for an immediate foreground execution without rebuilding the recurring schedule.');
        exit(true);
    end;

    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Steps: JsonArray;
    begin
        Steps.Add(ContractMgt.WorkflowStep('Orchestrator.Entry.Register', 'Bring a Job Queue Entry under orchestrator control, or skip this when the orchestrator entry already exists.'));
        Steps.Add(ContractMgt.WorkflowStep('Orchestrator.Entry.Schedule', 'Rebuild its Job Queue schedule from the recurrence settings, with data.id from the Register answer.'));
        Steps.Add(ContractMgt.WorkflowStep('Orchestrator.Status.Get', 'Check that the orchestrator itself is running.'));
        Workflow.Add('steps', Steps);
        exit(true);
    end;

    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.Example(Examples, 'Schedule an entry', '{"type":"Orchestrator.Entry.Schedule","data":{"id":"<systemId>"}}', '{"status":"Success","id":"<systemId>","blocked":false,"message":"Orchestrator entry scheduled."}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Rebuilds the Job Queue Entry of an existing orchestrator entry from its current recurrence settings. Use it after the recurrence settings of the entry changed. A blocked entry is refused. Irreversible: the call commits.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'Blocked entries are refused. With client credentials the update goes through the scheduling API. Without them the Job Queue Entry is deleted and created again from the entry''s recurrence when its earliest start has passed; when it lies in the future the Job Queue Entry is only deleted and the orchestrator management job creates it later.';
        exit(true);
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Inbound);
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteSchedule(Argument);
    end;

    var
        Handler: Codeunit "SE Msg Handler ori";
}
