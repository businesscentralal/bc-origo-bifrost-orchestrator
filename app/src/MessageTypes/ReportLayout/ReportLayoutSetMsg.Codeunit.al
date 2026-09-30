namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035599 "Report Layout Set Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
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
        DescriptionLbl: Label 'Creates or replaces a user-defined report layout via the BC layout import path.', Comment = 'is-IS=Býr til eða skiptir út notandaskilgreindu skýrsluútliti um innflutningsleið BC.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'set report layout, import report layout, replace report layout, base64 layout, Word layout, Excel layout, RDLC layout', Comment = 'is-IS=stilla skýrsluútlit, flytja inn skýrsluútlit, skipta út skýrsluútliti, base64 útlit, Word útlit, Excel útlit, RDLC útlit';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Create or replace a user-defined tenant report layout from base64. Write operation. Use Orchestrator.Report.Get to inspect existing layouts.', Comment = 'is-IS=Búðu til eða skiptu út notandaskilgreindu útliti leigjanda úr base64. Skrifaðgerð. Notaðu Orchestrator.Report.Get til að skoða núverandi útlit.';
    begin
        exit(SelectionLbl);
    end;

    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Forms: List of [Text];
    begin
        Forms.Add('integer and name');
        Envelope := Parts.Envelope(Forms, 'The reportId and layout name are supplied in data.', true);
        exit(true);
    end;

    procedure GetTarget(var Target: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Target := Parts.Target('data.reportId, data.name', 'integer and name', 'The report and user-defined layout name.');
        exit(true);
    end;

    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('reportId', 'integer', true, 'Report Metadata ID.'));
        Parameters.Add(ContractMgt.Parameter('name', 'string', true, 'User-defined layout name.'));
        Parameters.Add(ContractMgt.Parameter('layoutFormat', 'string', true, 'Word, Excel, RDLC or RDL.'));
        Parameters.Add(ContractMgt.Parameter('layoutBase64', 'string', true, 'Non-empty base64 layout content.'));
        Parameters.Add(ContractMgt.Parameter('description', 'string', false, 'Layout description; defaults to name.'));
        Parameters.Add(ContractMgt.Parameter('companyName', 'string', false, 'Optional company name for the layout.'));
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Fields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'status', 'string', 'Success.');
        Parts.AddResponseField(Fields, 'reportId', 'integer', 'Report ID.');
        Parts.AddResponseField(Fields, 'name', 'string', 'Layout name.');
        Parts.AddResponseField(Fields, 'layoutFormat', 'string', 'Stored layout format.');
        Parts.AddResponseField(Fields, 'action', 'string', 'Created or Replaced.');
        Parts.AddResponseField(Fields, 'isDefault', 'boolean', 'Always false; default selection is deferred.');
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.AddRecordErrors(Errors, 'Report');
        Parts.AddRuntimeError(Errors, 'A required field is missing, layoutBase64 is empty, or layoutFormat is invalid.', 'Send all required keys and a supported Word, Excel or RDLC layout.');
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Preconditions: JsonArray;
    begin
        Effect := Parts.Effect('write', 'Imports a user-defined layout and creates or replaces the tenant layout row.', false, '', Preconditions);
        exit(true);
    end;

    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    procedure GetRelated(var Related: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.Related(Related, 'Orchestrator.Report.Get', 'Use this to inspect report metadata and existing layouts.');
        exit(true);
    end;

    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        exit(false);
    end;

    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.Example(Examples, 'Create a Word layout', '{"type":"Orchestrator.ReportLayout.Set","data":{"reportId":50100,"name":"custom","layoutFormat":"Word","layoutBase64":"<base64>"}}', '{"status":"Success","reportId":50100,"name":"custom","layoutFormat":"Word","action":"Created","isDefault":false}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Creates or replaces a user-defined tenant report layout through the supported layout media import path.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'setAsDefault is intentionally not implemented; isDefault is returned as false. The operation does not use Data.Records.Set.';
        exit(true);
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Inbound);
    end;

    procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    begin
        Argument.SetResponseMarkdown(
            '# Orchestrator.ReportLayout.Set\n\n' +
            'Creates or replaces a **user-defined** tenant report layout from base64.\n\n' +
            'Uses the platform layout Media import path (`Tenant Report Layout`.Layout.ImportStream). ' +
            'Does **not** use Bifrost `Data.Records.Set` on tables 2000000232 / 2000000233.\n\n' +
            '## Request\n\n' +
            '```json\n' +
            '{\n' +
            '  "reportId": 1316,\n' +
            '  "name": "origo test",\n' +
            '  "layoutFormat": "Word",\n' +
            '  "layoutBase64": "...",\n' +
            '  "description": "optional",\n' +
            '  "companyName": ""\n' +
            '}\n' +
            '```\n\n' +
            '`setAsDefault` is deferred to `Orchestrator.ReportLayout.SetDefault` ' +
            '(codeunit *Report Layouts Impl.* SetDefault is Access=Internal).');
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteSet(Argument);
    end;

    var
        Handler: Codeunit "Report Layout Handler ori";
}
