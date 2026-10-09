/// <summary>
/// Implements the Help.Orchestrator.Get message type, returning an AI-friendly overview of all
/// Job Queue and Playbook Workflow message types. Delegates the document to codeunit "Help ori".
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035570 "Help Get Impl ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
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
        DescriptionLbl: Label 'AI-friendly overview of all Job Queue + Playbook Workflow message types with setup guide via Data.Records.Set/Get.', Comment = 'is-IS=Yfirlit fyrir gervigreind yfir allar vinnsluraða- og keðjuvinnsluskilaboðategundir með uppsetningarleiðbeiningum um Data.Records.Set/Get.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'orchestrator help, message type help, playbook help, setup guide, API overview', Comment = 'is-IS=áætlara hjálp, hjálp skilaboðategundar, keðjuhjálp, uppsetningarleiðbeiningar, API-yfirlit';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Read the Bifrost Orchestrator message type overview and setup guidance. Read-only. Use Help.Implementation.Get for a single type contract.', Comment = 'is-IS=Lestu yfirlit yfir skilaboðategundir Bifröst stjórnanda og uppsetningarleiðbeiningar. Lesaðgerð. Notaðu Help.Implementation.Get fyrir samning einnar tegundar.';
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
        ResultFields: JsonArray;
    begin
        Parts.AddResponseField(ResultFields, 'messageType', 'string', 'Always Help.Orchestrator.Get.');
        Parts.AddResponseField(ResultFields, 'format', 'string', 'Always markdown.');
        Parts.AddResponseField(ResultFields, 'markdown', 'string', 'The overview document: decision tree, message type table, run reporting, playbook concepts, building playbooks with Data.Records.Set, scheduling, LLM patterns and agent rules.');
        Parts.AddResponseField(Fields, 'status', 'string', 'Success.');
        Parts.AddResponseField(Fields, 'result', 'object', 'The overview.', ResultFields);
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.AddError(Errors, 'Unsupported specification version <version>. Expected version 1.0.', 'The request version is not 1.0.', 'Send version 1.0.');
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Preconditions: JsonArray;
    begin
        Effect := Parts.Effect('read', 'Reads the Orchestrator help overview.', true, '', Preconditions);
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
        Parts.Related(Related, 'Help.Implementation.Get', 'Use this for the contract of one message type.');
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
        Parts.Example(Examples, 'Read orchestrator help', '{"type":"Help.Orchestrator.Get"}', '{"status":"Success","result":{"messageType":"Help.Orchestrator.Get","format":"markdown","markdown":"# Job Queue Orchestrator & Playbook Workflow Engine ..."}}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Returns the compatibility overview for Job Queue and Playbook Workflow message types.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'For machine-readable per-type chapters use Help.Implementation.Get.';
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
    /// Executes the message type, returning the overview document as a JSON result.
    /// </summary>
    /// <param name="Argument">Message argument carrying the request and receiving the response.</param>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Help ori";
        ResponseJson: JsonObject;
        ResultJson: JsonObject;
    begin
        Argument.AssertVersion1();

        ResultJson.Add('messageType', 'Help.Orchestrator.Get');
        ResultJson.Add('format', 'markdown');
        ResultJson.Add('markdown', Help.GetOverview());

        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('result', ResultJson);
        Argument.SetResponseJson(ResponseJson);
        Argument."Content Type" := 'text/json';
    end;
}
