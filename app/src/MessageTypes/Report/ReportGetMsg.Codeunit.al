namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035594 "Report Get Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;
    Permissions =
        tabledata "Report Request Preset ori" = R;

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
        DescriptionLbl: Label 'Returns report metadata, available layouts, and saved request page preset.', Comment = 'is-IS=Skilar lýsigögnum skýrslu, tiltækum útlitum og vistuðum forsendum beiðnisíðu.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'get report, report details, report layouts, request page preset, report metadata', Comment = 'is-IS=sækja skýrslu, upplýsingar skýrslu, útlit skýrslu, forstilling beiðnisíðu, lýsigögn skýrslu';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Read one report''s metadata, layouts and current user request preset. Read-only. Use Orchestrator.Report.SaveAs or Orchestrator.Report.Run to execute it.', Comment = 'is-IS=Lestu lýsigögn, útlit og beiðniforstillingu núverandi notanda fyrir eina skýrslu. Lesaðgerð. Notaðu Orchestrator.Report.SaveAs eða Orchestrator.Report.Run til að keyra hana.';
    begin
        exit(SelectionLbl);
    end;

    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Forms: List of [Text];
    begin
        Forms.Add('integer');
        Envelope := Parts.Envelope(Forms, 'The report ID in data.reportId.', true);
        exit(true);
    end;

    procedure GetTarget(var Target: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Target := Parts.Target('data.reportId', 'integer', 'The Report Metadata ID.');
        exit(true);
    end;

    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('reportId', 'integer', true, 'Report Metadata ID.'));
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Fields: JsonArray;
        LayoutFields: JsonArray;
        PresetFields: JsonArray;
    begin
        Parts.AddResponseField(LayoutFields, 'name', 'string', 'Layout name.');
        Parts.AddResponseField(LayoutFields, 'caption', 'string', 'Layout caption.');
        Parts.AddResponseField(LayoutFields, 'format', 'string', 'Layout format, e.g. RDLC, Word or Excel.');
        Parts.AddResponseField(LayoutFields, 'userDefined', 'boolean', 'Whether a user created the layout.');
        Parts.AddResponseField(PresetFields, 'description', 'string', 'Preset description; the report caption for a new preset.');
        Parts.AddResponseField(PresetFields, 'requestPageXml', 'string', 'Saved request page XML; empty text when none is saved.');
        Parts.AddResponseField(PresetFields, 'hasRequestPageXml', 'boolean', 'Whether request page XML is saved.');
        Parts.AddResponseField(Fields, 'id', 'integer', 'Report ID.');
        Parts.AddResponseField(Fields, 'name', 'string', 'Report object name.');
        Parts.AddResponseField(Fields, 'caption', 'string', 'Report caption.');
        Parts.AddResponseField(Fields, 'processingOnly', 'boolean', 'Whether the report is processing-only.');
        Parts.AddResponseField(Fields, 'defaultLayout', 'string', 'Default layout type.');
        Parts.AddResponseField(Fields, 'firstDataItemTableId', 'integer', 'Table of the first data item; 0 when there is none.');
        Parts.AddResponseField(Fields, 'firstDataItemTableName', 'string', 'Caption of that table; empty when there is none.');
        Parts.AddResponseField(Fields, 'useRequestPage', 'boolean', 'Whether the report has a request page.');
        Parts.AddResponseField(Fields, 'requestPageUrl', 'string', 'Web client URL that opens the report in this company.');
        Parts.AddResponseField(Fields, 'layouts', 'array', 'Available report layouts.', LayoutFields);
        Parts.AddResponseField(Fields, 'preset', 'object', 'The calling user''s request preset for the report.', PresetFields);
        Parts.AddResponseField(Fields, 'presetCapturePageUrl', 'string', 'Web client URL of the Report Preset Card ori where the request page XML is captured.');
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.AddReportErrors(Errors);
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Preconditions: JsonArray;
    begin
        Effect := Parts.Effect('read', 'Reads report metadata, layouts and the calling user''s preset. When the user has no preset for the report, inserts an empty one for that user in this company.', true, '', Preconditions);
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
        Parts.Related(Related, 'Orchestrator.Report.SaveAs', 'Use this to render a non-processing-only report.');
        Parts.Related(Related, 'Orchestrator.Report.Run', 'Use this to run a processing-only report.');
        exit(true);
    end;

    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Steps: JsonArray;
    begin
        Steps.Add(ContractMgt.WorkflowStep('Orchestrator.Report.Get', 'Get presetCapturePageUrl, and confirm what the report is.'));
        Steps.Add(ContractMgt.WorkflowStep('Orchestrator.Report.Get', 'After the user has opened that URL in the web client and captured the request page, read preset.requestPageXml back.'));
        Steps.Add(ContractMgt.WorkflowStep('Orchestrator.Report.SaveAs', 'Render the report; with no requestPageXml in the request the saved preset is used.'));
        Workflow.Add('steps', Steps);
        Workflow.Add('text', 'For a processing-only report the last step is Orchestrator.Report.Run, which uses the saved preset the same way.');
        exit(true);
    end;

    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.Example(Examples, 'Get report metadata', '{"type":"Orchestrator.Report.Get","data":{"reportId":206}}', '{"id":206,"name":"Sales - Invoice","caption":"Sales - Invoice","processingOnly":false,"defaultLayout":"RDLC","firstDataItemTableId":112,"firstDataItemTableName":"Sales Invoice Header","useRequestPage":true,"requestPageUrl":"<url>","layouts":[{"name":"StandardSalesInvoice.rdlc","caption":"Standard Sales Invoice","format":"RDLC","userDefined":false}],"preset":{"description":"Sales - Invoice","requestPageXml":"","hasRequestPageXml":false},"presetCapturePageUrl":"<url>"}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Returns one report''s metadata, layouts and the current user''s saved request page preset.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'When the calling user has no preset for the report, an empty preset row is created for that user in this company, so the response can always give the capture page URL. The answer has no status key.';
        exit(true);
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Both);
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteGet(Argument);
    end;

    var
        Handler: Codeunit "Report Msg Handler ori";
}
