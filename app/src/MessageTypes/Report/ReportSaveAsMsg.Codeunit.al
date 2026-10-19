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
        Parameters.Add(Parts.WithChoices(ContractMgt.Parameter('format', 'string', false, 'Output format. Case-insensitive.'), Formats, 'PDF'));
        Parameters.Add(ContractMgt.Parameter('parameters', 'object', false, 'Explicit scalar option values over caller requestPageXml or a registered template. Never reads or changes saved settings. Unknown names fail. Report 1316 has a built-in template; see notes.'));
        Parameters.Add(ContractMgt.Parameter('requestPageXml', 'string', false, 'Caller XML takes precedence over registered templates. parameters overlays its named options. Without parameters, existing raw XML / saved-preset behavior is retained.'));
        Parameters.Add(ContractMgt.Parameter('layoutName', 'string', false, 'Temporary layout override from Orchestrator.ReportLayout.List. The prior session selection and stored defaults are preserved.'));
        Parameters.Add(ContractMgt.Parameter('appId', 'string', false, 'Extension layout application GUID; omitted means a user-defined layout. Used with layoutName.'));
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
        Parts.AddContractError(Errors, 'Unknown request page parameter <name> on report <reportId>.', 'The option name is not in the selected base XML.', 'Use a known control name or register a report template.');
        Parts.AddContractError(Errors, 'No request page template is registered for report <reportId>. Provide requestPageXml.', 'Explicit parameters need a caller XML base or registered template.', 'Send requestPageXml containing the report options.');
        Parts.AddContractError(Errors, 'Report <reportId> is processing-only and cannot be saved.', 'The report is a batch job that produces no document.', 'Use Orchestrator.Report.Run for it.');
        Parts.AddContractError(Errors, 'Unsupported format "<FORMAT>". Use PDF, Excel, Word, or XML.', 'data.format is not one of the four formats.', 'Send PDF, Excel, Word or XML, or leave format out.');
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
        Notes := 'The report 1316 template accepts StartDate, EndDate (ISO dates), DateChoice (Due Date/Posting Date), PrintAging, AgingBandPeriodLength, PrintAllHavingBalance and StatementStyle (Balance/Open Item). PrintEntriesNotDue is not a BC 28.5 control and is rejected. Processing-only reports do not produce a document and must be run with Orchestrator.Report.Run. layoutName and appId temporarily select an installed layout for this call; stored defaults and the prior session selection are unchanged on success or rendering failure. Omit layoutName to retain the existing default selection. The answer is marked application/pdf for every format; the bytes are in the format that was asked for.';
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
