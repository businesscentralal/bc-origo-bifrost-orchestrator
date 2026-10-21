namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035593 "Report List Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
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
        DescriptionLbl: Label 'Lists available reports with metadata, excluding obsolete reports.', Comment = 'is-IS=Listar tiltækar skýrslur með lýsigögnum, útilokar úreltar skýrslur.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'list reports, report metadata, available reports, processing-only reports, report catalog', Comment = 'is-IS=lista skýrslur, lýsigögn skýrslu, tiltækar skýrslur, vinnsluskýrslur, skýrsluskrá';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'List reports visible to the current user, optionally filtered by processing-only status. Read-only. Use Orchestrator.Report.Get for one report.', Comment = 'is-IS=Lista skýrslur sem núverandi notandi sér, mögulega síaðar eftir því hvort þær séu vinnsluskýrslur. Lesaðgerð. Notaðu Orchestrator.Report.Get fyrir eina skýrslu.';
    begin
        exit(SelectionLbl);
    end;

    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Envelope := Parts.NoSubjectEnvelope(false, 'text/json');
        exit(true);
    end;

    procedure GetTarget(var Target: JsonArray): Boolean
    begin
        exit(false);
    end;

    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('processingOnly', 'boolean', false, 'When supplied, limits results to processing-only or output reports.'));
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Fields: JsonArray;
        ReportFields: JsonArray;
    begin
        Parts.AddResponseField(ReportFields, 'id', 'integer', 'Report object ID.');
        Parts.AddResponseField(ReportFields, 'name', 'string', 'Report object name.');
        Parts.AddResponseField(ReportFields, 'caption', 'string', 'Report caption.');
        Parts.AddResponseField(ReportFields, 'processingOnly', 'boolean', 'True for a batch job that produces no document.');
        Parts.AddResponseField(ReportFields, 'defaultLayout', 'string', 'Default layout type, e.g. RDLC or Word.');
        Parts.AddResponseField(ReportFields, 'firstDataItemTableId', 'integer', 'Table of the first data item; 0 when there is none.');
        Parts.AddResponseField(ReportFields, 'useRequestPage', 'boolean', 'Whether the report has a request page.');
        Parts.AddResponseField(Fields, 'reports', 'array', 'One entry per report.', ReportFields);
        Parts.AddResponseField(Fields, 'count', 'integer', 'Number of returned reports.');
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.AddRuntimeError(Errors, 'processingOnly is not a boolean.', 'Send true, false, or omit processingOnly.');
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Preconditions: JsonArray;
    begin
        Effect := Parts.Effect('read', 'Reads report metadata visible to the current user.', true, '', Preconditions);
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
        Parts.Related(Related, 'Orchestrator.Report.Get', 'Use this to inspect one report and its layouts.');
        exit(true);
    end;

    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Steps: JsonArray;
    begin
        Steps.Add(ContractMgt.WorkflowStep('Orchestrator.Report.List', 'Find the reportId, optionally with processingOnly.'));
        Steps.Add(ContractMgt.WorkflowStep('Orchestrator.Report.Get', 'Confirm what the report is and read its layouts and saved preset.'));
        Steps.Add(ContractMgt.WorkflowStep('Orchestrator.Report.SaveAs', 'Render a report that produces a document; use Orchestrator.Report.Run for a processing-only report.'));
        Workflow.Add('steps', Steps);
        exit(true);
    end;

    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.Example(Examples, 'List processing-only reports', '{"type":"Orchestrator.Report.List","data":{"processingOnly":true}}', '{"reports":[{"id":795,"name":"Adjust Cost - Item Entries","caption":"Adjust Cost - Item Entries","processingOnly":true,"defaultLayout":"RDLC","firstDataItemTableId":27,"useRequestPage":true}],"count":1}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Lists the reports available to the current user with their id, name, caption, whether they are processing-only, default layout, first data item table and request page, optionally only the processing-only ones. Use it to find a reportId for Orchestrator.Report.Get, Orchestrator.Report.SaveAs or Orchestrator.Report.Run.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'Obsolete reports are excluded by the Report Metadata source. The answer has no status key. processingOnly is the only filter: destructive batch jobs such as Date Compress G/L Entries and Delete Invoiced Sales Orders are listed next to harmless ones, so confirm a report with Orchestrator.Report.Get before running it.';
        exit(true);
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Outbound);
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteList(Argument);
    end;

    var
        Handler: Codeunit "Report Msg Handler ori";
}
