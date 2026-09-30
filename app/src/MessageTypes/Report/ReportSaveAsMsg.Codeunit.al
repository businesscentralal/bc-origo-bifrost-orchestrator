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
        DescriptionLbl: Label 'Generates report output (PDF, Excel, Word, XML) using saved preset or provided parameters.', Comment = 'is-IS=BÃ½r til skÃ½rsluÃºtttak (PDF, Excel, Word, XML) Ãºt frÃ¡ vistuÃ°um forsendum eÃ°a uppgefnum breytum.';
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
    begin
        Parameters.Add(ContractMgt.Parameter('reportId', 'integer', true, 'Report Metadata ID.'));
        Parameters.Add(ContractMgt.Parameter('requestPageXml', 'string', false, 'Request page XML; otherwise the saved preset is used.'));
        Parameters.Add(ContractMgt.Parameter('format', 'string', false, 'PDF, Excel, Word or XML; defaults to PDF.'));
        Parameters.Add(ContractMgt.Parameter('tableView', 'string', false, 'Optional view applied to the report data item.'));
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Fields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'binary', 'binary', 'Rendered report payload.');
        Response := Parts.Response(Fields, 'application/octet-stream');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.AddRecordErrors(Errors, 'Report');
        Parts.AddRuntimeError(Errors, 'The report is processing-only or the format is unsupported.', 'Use Report.Run for processing-only reports and send PDF, Excel, Word or XML.');
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
    begin
        exit(false);
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
        Notes := 'Processing-only reports do not produce a document and must be run with Orchestrator.Report.Run.';
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
        Argument.SetResponseMarkdown(Help.GetHelp('Orchestrator.Report.SaveAs'));
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteSaveAs(Argument);
    end;

    var
        Handler: Codeunit "Report Msg Handler ori";
}
