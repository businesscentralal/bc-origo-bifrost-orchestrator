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
        SelectionLbl: Label 'Register an existing Job Queue Entry under Bifrost Orchestrator control. Write operation. Use Orchestrator.Entry.Schedule after changing its recurring settings.', Comment = 'is-IS=Skráðu núverandi vinnsluröðarfærslu undir stjórn Bifröst stjórnanda. Skrifaðgerð. Notaðu Orchestrator.Entry.Schedule eftir breytingu á endurteknum stillingum.';
    begin
        exit(SelectionLbl);
    end;

    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Forms: List of [Text];
    begin
        Forms.Add('guid');
        Envelope := Parts.Envelope(Forms, 'The Job Queue Entry SystemId in data.jobQueueEntryId or as subject.', false);
        exit(true);
    end;

    procedure GetTarget(var Target: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Target := Parts.Target('data.jobQueueEntryId, subject', 'guid', 'The Job Queue Entry SystemId to register.');
        exit(true);
    end;

    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('jobQueueEntryId', 'string', false, 'Job Queue Entry SystemId.'));
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Fields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'status', 'string', 'Success.');
        Parts.AddResponseField(Fields, 'id', 'string', 'Registered Scheduled Entry SystemId.');
        Parts.AddResponseField(Fields, 'blocked', 'boolean', 'Whether the new entry is blocked.');
        Parts.AddResponseField(Fields, 'message', 'string', 'Registration result.');
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.AddRecordErrors(Errors, 'Job Queue Entry');
        Parts.AddRuntimeError(Errors, 'The Job Queue Entry cannot be registered.', 'Check that it exists and is not already registered.');
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Preconditions: JsonArray;
    begin
        Effect := Parts.Effect('write', 'Creates a Scheduled Entry linked to the existing Job Queue Entry.', false, '', Preconditions);
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
        Parts.Example(Examples, 'Register a Job Queue Entry', '{"type":"Orchestrator.Entry.Register","data":{"jobQueueEntryId":"<systemId>"}}', '{"status":"Success","id":"<systemId>","message":"Job Queue Entry registered with orchestrator."}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Brings an existing Job Queue Entry under orchestrator scheduling, monitoring and notification control.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'The supplied identifier is the Job Queue Entry SystemId, not the Scheduled Entry primary key.';
        exit(true);
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Outbound);
    end;

    procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Help ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp('Orchestrator.Entry.Register'));
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteRegister(Argument);
    end;

    var
        Handler: Codeunit "SE Msg Handler ori";
}
