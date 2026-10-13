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
        DescriptionLbl: Label 'Reschedule an orchestrator entry for immediate execution.', Comment = 'is-IS=Enduráætla áætlunarfærslu til tafarlausrar keyrslu.';
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
        SelectionLbl: Label 'Reschedule an orchestrator entry for immediate execution. Irreversible. Use Orchestrator.Entry.Run for a foreground run that leaves the schedule intact.', Comment = 'is-IS=Enduráætlun áætlunarfærslu fyrir tafarlausa keyrslu. Óafturkræft. Notaðu Orchestrator.Entry.Run fyrir forgrunn keyrslu sem skilur áætlunina eftir.';
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
        Parameters.Add(ContractMgt.Parameter('id', 'string', false, 'SystemId, or ID, of the Scheduled Entry ori. Required unless subject carries it.'));
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Fields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'status', 'string', 'Success.');
        Parts.AddResponseField(Fields, 'id', 'string', 'Scheduled Entry SystemId.');
        Parts.AddResponseField(Fields, 'blocked', 'boolean', 'Whether the entry is blocked.');
        Parts.AddResponseField(Fields, 'message', 'string', 'Scheduling result.');
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
    begin
        exit(false);
    end;

    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.Example(Examples, 'Schedule an entry', '{"type":"Orchestrator.Entry.Schedule","data":{"id":"<systemId>"}}', '{"status":"Success","id":"<systemId>","message":"Orchestrator entry scheduled."}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Rebuilds the Job Queue Entry of an existing orchestrator entry from its current recurrence settings.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'Blocked entries are refused. With client credentials the update goes through the scheduling API. Without them the Job Queue Entry is deleted and created again from the entry''s recurrence when its earliest start has passed; when it lies in the future the Job Queue Entry is only deleted and the orchestrator management job creates it later.';
        exit(true);
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Outbound);
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteSchedule(Argument);
    end;

    var
        Handler: Codeunit "SE Msg Handler ori";
}
