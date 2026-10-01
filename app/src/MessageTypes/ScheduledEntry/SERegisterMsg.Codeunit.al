/// <summary>
/// Implements the Orchestrator.Entry.Register message type: registers a Job Queue Entry
/// as a new orchestrator entry.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035579 "SE Register Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
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
        DescriptionLbl: Label 'Register a Job Queue Entry as an orchestrator entry.', Comment = 'is-IS=SkrÃ¡ vinnsluraÃ°arfÃ¦rslu sem Ã¡Ã¦tlunarfÃ¦rslu.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'register job queue entry, adopt job queue entry, orchestrator entry, supervise job', Comment = 'is-IS=skrá vinnsluröðarfærslu, taka vinnsluröðarfærslu yfir, áætlunarfærsla, hafa umsjón með vinnslu';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Register an existing Job Queue Entry under Bifrost Orchestrator control. Irreversible. Use Orchestrator.Entry.Schedule after changing its recurring settings.', Comment = 'is-IS=Skráðu núverandi vinnsluröðarfærslu undir stjórn Bifröst stjórnanda. Óafturkræft. Notaðu Orchestrator.Entry.Schedule eftir breytingu á endurteknum stillingum.';
    begin
        exit(SelectionLbl);
    end;

    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Forms: List of [Text];
    begin
        Forms.Add('guid');
        Envelope := Parts.Envelope(Forms, 'The ID (primary key) of the Job Queue Entry, in data.jobQueueEntryId or as subject.', false);
        exit(true);
    end;

    procedure GetTarget(var Target: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Target.Add(ContractMgt.TargetEntry('data.jobQueueEntryId', 'guid', 'Read first: the ID (primary key) of the Job Queue Entry, not its SystemId.'));
        Target.Add(ContractMgt.TargetEntry('subject', 'guid', 'Used only when data.jobQueueEntryId is missing or not a GUID: the ID of the Job Queue Entry.'));
        exit(true);
    end;

    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('jobQueueEntryId', 'string', false, 'ID (primary key) of the Job Queue Entry to register. Required unless subject carries it.'));
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Fields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'status', 'string', 'Success.');
        Parts.AddResponseField(Fields, 'id', 'string', 'SystemId of the Scheduled Entry ori; its ID equals the Job Queue Entry ID.');
        Parts.AddResponseField(Fields, 'blocked', 'boolean', 'Always false: a registered entry starts unblocked.');
        Parts.AddResponseField(Fields, 'message', 'string', 'Job Queue Entry registered with orchestrator. (translated).');
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.AddError(Errors, 'Request must include "jobQueueEntryId" (GUID) in the data payload or the Job Queue Entry ID as the subject.', 'data.jobQueueEntryId is missing or not a GUID, and subject is not a GUID.', 'Send the ID of the Job Queue Entry.');
        Parts.AddRuntimeError(Errors, 'No Job Queue Entry has that ID (Business Central''s record-not-found text).', 'Send the ID of the Job Queue Entry, not its SystemId.');
        Parts.AddError(Errors, 'The Job Queue Orchestrator Management Job Queue Entry cannot be one of the Job Queue Orchestrator Entries.', 'The ID is the orchestrator''s own management Job Queue Entry.', 'Register a different Job Queue Entry.');
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Effect := Parts.CommittingEffect('Creates the Scheduled Entry ori from the Job Queue Entry, replacing an existing one, and commits it.', false);
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
        Parts.Related(Related, 'Orchestrator.Entry.Schedule', 'Use this after registering when the entry must be scheduled immediately.');
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
        Parts.Example(Examples, 'Register a Job Queue Entry', '{"type":"Orchestrator.Entry.Register","data":{"jobQueueEntryId":"<guid>"}}', '{"status":"Success","id":"<systemId>","blocked":false,"message":"Job Queue Entry registered with orchestrator."}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Brings an existing Job Queue Entry under orchestrator scheduling, monitoring and notification control.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'The identifier is the ID (primary key) of the Job Queue Entry, not its SystemId. Registering an entry that is already registered deletes the Scheduled Entry ori and copies it again from the Job Queue Entry, so changes made on the orchestrator entry are lost. The new entry copies the object to run, the record to process, the category, the description and the recurrence fields, takes the calling user''s time zone, and is not blocked.';
        exit(true);
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Outbound);
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteRegister(Argument);
    end;

    var
        Handler: Codeunit "SE Msg Handler ori";
}
