namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035595 "Report SaveAs Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
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
        DescriptionLbl: Label 'Generates report output (PDF, Excel, Word, XML) using saved preset or provided parameters.', Comment = 'is-IS=Býr til skýrsluúttak (PDF, Excel, Word, XML) út frá vistuðum forsendum eða uppgefnum breytum.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'save report, render report, report PDF, report Excel, report Word, report XML, report output', Comment = 'is-IS=vista skýrslu, birta skýrslu, PDF skýrslu, Excel skýrslu, Word skýrslu, XML skýrslu, úttak skýrslu';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Render a non-processing-only report as PDF, Excel, Word or XML. Read-only with binary output. Use Orchestrator.Report.Run for processing-only reports.', Comment = 'is-IS=Birttu skýrslu sem er ekki eingöngu vinnsluskýrsla sem PDF, Excel, Word eða XML. Lesaðgerð með tvíundarúttaki. Notaðu Orchestrator.Report.Run fyrir vinnsluskýrslur.';
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
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Formats: List of [Text];
    begin
        Formats.Add('PDF');
        Formats.Add('Excel');
        Formats.Add('Word');
        Formats.Add('XML');
        Parameters.Add(ContractMgt.Parameter('reportId', 'integer', true, 'Report object ID; must not be a processing-only report.'));
        Parts.AddChoiceParameter(Parameters, 'format', false, 'Output format. Case-insensitive.', Formats, 'PDF');
        Parameters.Add(ContractMgt.Parameter('requestPageXml', 'string', false, 'Request page parameters as XML. When left out, the calling user''s saved preset is used, otherwise the report defaults.'));
        Parameters.Add(ContractMgt.Parameter('tableView', 'string', false, 'Table view applied to the report''s first data item, e.g. WHERE(Sell-to Customer No.=CONST(10000)). Ignored when the report has no data item table.'));
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Fields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'binary', 'binary', 'The rendered document in the requested format.');
        Response := Parts.Response(Fields, 'application/pdf');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.AddReportErrors(Errors);
        Parts.AddError(Errors, 'Report <reportId> is processing-only and cannot be saved.', 'The report is a batch job that produces no document.', 'Use Orchestrator.Report.Run for it.');
        Parts.AddError(Errors, 'Unsupported format "<FORMAT>". Use PDF, Excel, Word, or XML.', 'data.format is not one of the four formats.', 'Send PDF, Excel, Word or XML, or leave format out.');
        Parts.AddRuntimeError(Errors, 'The report fails while rendering, or tableView is not a valid view.', 'Read the text; check the request page XML and the view.');
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Preconditions: JsonArray;
    begin
        Effect := Parts.Effect('read', 'Renders report output without changing the report definition.', true, '', Preconditions);
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
        Parts.Related(Related, 'Orchestrator.Report.Get', 'Use this to inspect metadata and layouts first.');
        Parts.Related(Related, 'Orchestrator.Report.Run', 'Use this instead for a processing-only report.');
        exit(true);
    end;

    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Steps: JsonArray;
    begin
        Steps.Add(ContractMgt.WorkflowStep('Data.Records.Get', 'Read the customers to send to.'));
        Steps.Add(ContractMgt.WorkflowStep('Orchestrator.Report.SaveAs', 'forEach customer: {"reportId":206,"format":"PDF","tableView":"WHERE(Sell-to Customer No.=CONST(@_current.no))"}.'));
        Steps.Add(ContractMgt.WorkflowStep('Email.Draft.Set', 'forEach: create the draft with the rendered document as attachment.'));
        Steps.Add(ContractMgt.WorkflowStep('Orchestrator.Email.Send', 'forEach: send the draft.'));
        Workflow.Add('steps', Steps);
        Workflow.Add('text', 'A playbook that sends a report to each customer by email.');
        exit(true);
    end;

    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.Example(Examples, 'Render a PDF', '{"type":"Orchestrator.Report.SaveAs","data":{"reportId":50100,"format":"PDF"}}', '{"contentType":"application/pdf","size":1024,"base64":"<base64>"}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Renders a report into a binary PDF, Excel, Word or XML response using request data or the saved preset.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'Processing-only reports do not produce a document and must be run with Orchestrator.Report.Run. There is no layout parameter: the report renders with its default layout. The answer is marked application/pdf for every format; the bytes are in the format that was asked for.';
        exit(true);
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Outbound);
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteSaveAs(Argument);
    end;

    var
        Handler: Codeunit "Report Msg Handler ori";
}
