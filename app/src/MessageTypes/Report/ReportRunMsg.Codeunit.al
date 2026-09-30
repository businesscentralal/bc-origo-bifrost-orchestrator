namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035597 "Report Run Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
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
        DescriptionLbl: Label 'Runs a processing-only report (batch job) using saved preset or provided parameters.', Comment = 'is-IS=Keyrir vinnsluskÃ½rslu (runuvinnslu) Ãºt frÃ¡ vistuÃ°um forsendum eÃ°a uppgefnum breytum.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'run report, processing-only report, batch report, processing report, report job', Comment = 'is-IS=keyra skýrslu, vinnsluskýrsla, runuvinnsla skýrslu, vinnsluskýrsla, skýrsluverk';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Run a processing-only report as a batch job and return its result. Write operation. Use Orchestrator.Report.SaveAs for reports that produce output.', Comment = 'is-IS=Keyrðu vinnsluskýrslu sem runuvinnslu og skilaðu niðurstöðu. Skrifaðgerð. Notaðu Orchestrator.Report.SaveAs fyrir skýrslur sem skila úttaki.';
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
        Parameters.Add(ContractMgt.Parameter('tableView', 'string', false, 'Optional view applied to the report data item.'));
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Fields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'status', 'string', 'Success or Error.');
        Parts.AddResponseField(Fields, 'reportId', 'integer', 'Report ID.');
        Parts.AddResponseField(Fields, 'reportName', 'string', 'Report object name.');
        Parts.AddResponseField(Fields, 'caption', 'string', 'Report caption.');
        Parts.AddResponseField(Fields, 'usedPreset', 'boolean', 'Whether saved request XML was used.');
        Parts.AddResponseField(Fields, 'tableView', 'string', 'Effective table view.');
        Parts.AddResponseField(Fields, 'startedAt', 'string', 'Start timestamp.');
        Parts.AddResponseField(Fields, 'durationMs', 'integer', 'Execution duration in milliseconds.');
        Parts.AddResponseField(Fields, 'error', 'string', 'Error text when status is Error.');
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.AddRecordErrors(Errors, 'Report');
        Parts.AddRuntimeError(Errors, 'The report is not processing-only.', 'Use Orchestrator.Report.SaveAs for reports that produce output.');
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Preconditions: JsonArray;
    begin
        Effect := Parts.Effect('write', 'Runs the processing-only report; the report may commit its own changes.', false, '', Preconditions);
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
        Parts.Related(Related, 'Orchestrator.Report.SaveAs', 'Use this for a report that produces a document.');
        Parts.Related(Related, 'Orchestrator.Report.Get', 'Use this to inspect metadata and the saved preset.');
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
        Parts.Example(Examples, 'Run a processing-only report', '{"type":"Orchestrator.Report.Run","data":{"reportId":50100}}', '{"status":"Success","reportId":50100,"usedPreset":false,"durationMs":42}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Runs a processing-only report through the report batch-job path and returns execution details.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'A report failure is returned as status Error; request debug mode controls whether its callstack is included.';
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
        Argument.SetResponseMarkdown(Help.GetHelp('Orchestrator.Report.Run'));
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteRun(Argument);
    end;

    var
        Handler: Codeunit "Report Msg Handler ori";
}
