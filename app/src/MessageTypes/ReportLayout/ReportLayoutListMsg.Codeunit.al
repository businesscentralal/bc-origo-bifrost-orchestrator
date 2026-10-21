namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

/// <summary>Exposes read-only report layout list through Bifrost.</summary>
codeunit 10035612 "Report Layout List Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;

    /// <summary>Provides the IsEnabled part of the report layout list message.</summary>
    procedure IsEnabled(): Boolean
    begin
        exit(true);
    end;

    /// <summary>Provides the GetFilterTableNo part of the report layout list message.</summary>
    procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    /// <summary>Provides the GetDescription part of the report layout list message.</summary>
    procedure GetDescription(): Text[250]
    var
        DescriptionLbl: Label 'Lists extension and user-defined layouts for a report.', Comment = 'is-IS=Sýnir útlit skýrslu úr viðbótum og notandaskilgreind útlit.';
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>Provides the GetKeywords part of the report layout list message.</summary>
    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'list report layouts, report formats, extension layouts, user layouts', Comment = 'is-IS=sýna skýrsluútlit, skýrslusnið, útlit viðbóta, notandaútlit';
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>Provides the GetSelectionDescription part of the report layout list message.</summary>
    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'List the layouts of one report, extension and user-defined, with name, format, appId and whether each is the default. Read-only. Use Orchestrator.ReportLayout.Get to export the bytes of one layout.', Comment = 'is-IS=Listaðu útlit einnar skýrslu, úr viðbótum og notandaskilgreind, með heiti, sniði, appId og hvort hvert þeirra er sjálfgefið. Lesaðgerð. Notaðu Orchestrator.ReportLayout.Get til að flytja út gögn eins útlits.';
    begin
        exit(SelectionLbl);
    end;

    /// <summary>Provides the GetEnvelope part of the report layout list message.</summary>
    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Envelope := Parts.NoSubjectEnvelope(true, 'text/json');
        exit(true);
    end;

    /// <summary>Provides the GetTarget part of the report layout list message.</summary>
    procedure GetTarget(var Target: JsonArray): Boolean
    begin
        exit(false);
    end;

    /// <summary>Provides the GetParameters part of the report layout list message.</summary>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('reportId', 'integer', true, 'Report object ID.'));
        Parameters.Add(ContractMgt.Parameter('includeExtensionLayouts', 'boolean', false, 'Include extension layouts; default true.'));
        exit(true);
    end;

    /// <summary>Provides the GetResponse part of the report layout list message.</summary>
    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Fields: JsonArray;
        LayoutFields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'status', 'string', 'Success.');
        Parts.AddResponseField(Fields, 'reportId', 'integer', 'Report ID.');
        Parts.AddResponseField(LayoutFields, 'name', 'string', 'Layout name; send it as name to Orchestrator.ReportLayout.Get or as layoutName to Orchestrator.Report.SaveAs.');
        Parts.AddResponseField(LayoutFields, 'caption', 'string', 'Layout caption.');
        Parts.AddResponseField(LayoutFields, 'format', 'string', 'RDLC, Word, Excel or Custom.');
        Parts.AddResponseField(LayoutFields, 'userDefined', 'boolean', 'Whether a user created the layout.');
        Parts.AddResponseField(LayoutFields, 'source', 'string', 'UserDefined or Extension.');
        Parts.AddResponseField(LayoutFields, 'appId', 'string', 'Application GUID of the extension that ships the layout; all zeros for a user-defined layout.');
        Parts.AddResponseField(LayoutFields, 'description', 'string', 'Layout description.');
        Parts.AddResponseField(LayoutFields, 'layoutStatus', 'string', 'Status of the layout as the Business Central enum name.');
        Parts.AddResponseField(LayoutFields, 'isDefault', 'boolean', 'Whether the layout is the report''s default in the current company.');
        Parts.AddResponseField(Fields, 'layouts', 'array', 'One entry per layout of the report.', LayoutFields);
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    /// <summary>Provides the GetErrors part of the report layout list message.</summary>
    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.AddContractError(Errors, 'Report <reportId> not found.', 'The report does not exist.', 'Use Orchestrator.Report.List.');
        Parts.AddContractError(Errors, 'Request must include "<key>".', 'A required key is missing.', 'Supply the documented required fields.');

        exit(true);
    end;

    /// <summary>Provides the GetEffect part of the report layout list message.</summary>
    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Preconditions: JsonArray;
    begin
        Effect := Parts.Effect('read', 'Reads the layout list of the report; does not change layouts or defaults.', true, '', Preconditions);
        exit(true);
    end;

    /// <summary>Provides the GetMetering part of the report layout list message.</summary>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>Provides the GetRelated part of the report layout list message.</summary>
    procedure GetRelated(var Related: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.Related(Related, 'Orchestrator.ReportLayout.Get', 'Use this to export the bytes of one listed layout.');
        Parts.Related(Related, 'Orchestrator.ReportLayout.Set', 'Use this to import or replace a user-defined layout.');
        Parts.Related(Related, 'Orchestrator.Report.Get', 'Use this to inspect report metadata and existing layouts.');
        exit(true);
    end;

    /// <summary>Provides the GetWorkflow part of the report layout list message.</summary>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Steps: JsonArray;
    begin
        Steps.Add(ContractMgt.WorkflowStep('Orchestrator.ReportLayout.List', 'Find the layouts of the report and the one to use.'));
        Steps.Add(ContractMgt.WorkflowStep('Orchestrator.Report.SaveAs', 'Render the report with layoutName (and appId for an extension layout) from the list.'));
        Workflow.Add('steps', Steps);
        exit(true);
    end;

    /// <summary>Provides the GetExamples part of the report layout list message.</summary>
    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.Example(Examples, 'List the layouts of a report', '{"type":"Orchestrator.ReportLayout.List","data":{"reportId":206}}', '{"status":"Success","reportId":206,"layouts":[{"name":"StandardSalesInvoice.docx","caption":"Standard Sales Invoice","format":"Word","userDefined":false,"source":"Extension","appId":"<guid>","description":"Standard Sales Invoice","layoutStatus":"<status name>","isDefault":true}]}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Lists the layouts of one report, extension and user-defined, with name, format, appId, status and whether each is the default in the current company; includeExtensionLayouts false limits the list to user-defined layouts. Nothing is changed.';
        exit(true);
    end;

    /// <summary>Provides the GetNotes part of the report layout list message.</summary>
    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'Read-only. No layout import, default-selection change or update-on-export is performed. Layout names and app IDs are returned by Orchestrator.ReportLayout.List.';
        exit(true);
    end;

    /// <summary>Provides the GetMessageDirection part of the report layout list message.</summary>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Outbound);
    end;

    /// <summary>Provides the ExecuteBifrostTask part of the report layout list message.</summary>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteList(Argument);
    end;

    var
        Handler: Codeunit "Report Layout Read Handler ori";
}
