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
        Parameters.Add(ContractMgt.Parameter('reportId', 'integer', true, 'Report object ID; must be a processing-only report (processingOnly true in Orchestrator.Report.List).'));
        Parameters.Add(ContractMgt.Parameter('requestPageXml', 'string', false, 'Request page parameters as XML. When left out, the calling user''s saved preset is used, otherwise the report defaults.'));
        Parameters.Add(ContractMgt.Parameter('tableView', 'string', false, 'Table view applied to the report''s first data item. Ignored when the report has no data item table.'));
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Fields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'status', 'string', 'Success when the report raised no error, Error when it failed.');
        Parts.AddResponseField(Fields, 'reportId', 'integer', 'Report ID.');
        Parts.AddResponseField(Fields, 'reportName', 'string', 'Report object name (Success only).');
        Parts.AddResponseField(Fields, 'caption', 'string', 'Report caption (Success only).');
        Parts.AddResponseField(Fields, 'usedPreset', 'boolean', 'True when no requestPageXml was sent and the saved preset had XML (Success only).');
        Parts.AddResponseField(Fields, 'tableView', 'string', 'The view that was sent, or empty (Success only).');
        Parts.AddResponseField(Fields, 'startedAt', 'string', 'Start time, ISO 8601 (Success only).');
        Parts.AddResponseField(Fields, 'durationMs', 'integer', 'Execution duration in milliseconds (Success only).');
        Parts.AddResponseField(Fields, 'error', 'string', 'The report''s error text (Error only).');
        Parts.AddResponseField(Fields, 'callstack', 'string', 'The error call stack (Error only, and only when Request Debug Mode is on in the Bifröst setup).');
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.AddReportErrors(Errors);
        Parts.AddError(Errors, 'Report <reportId> produces output and cannot be run as a batch job. Use Orchestrator.Report.SaveAs instead.', 'The report is not processing-only.', 'Use Orchestrator.Report.SaveAs for reports that produce output.');
        Parts.AddRuntimeError(Errors, 'tableView is not a valid view for the report''s data item table.', 'Fix the view or leave it out.');
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
        Parts.Example(Examples, 'Run a processing-only report', '{"type":"Orchestrator.Report.Run","data":{"reportId":795}}', '{"status":"Success","reportId":795,"reportName":"Adjust Cost - Item Entries","caption":"Adjust Cost - Item Entries","usedPreset":true,"tableView":"","startedAt":"2026-09-30T08:00:00Z","durationMs":41230}');
        Parts.Example(Examples, 'A report that fails', '{"type":"Orchestrator.Report.Run","data":{"reportId":795}}', '{"status":"Error","reportId":795,"error":"<Business Central error text>"}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Runs a processing-only report through the report batch-job path and returns execution details.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'Read this before using it:' +
            ' **Success only means no error was raised.** The report returns no result: a run that matched no records looks the same as one that adjusted 50,000 entries. Check with a following Data.Records.Get on the register or ledger the report writes to.' +
            ' **Effects are partial on failure.** A failing report is caught and answered with status Error (and the callstack only in Request Debug Mode). Most batch reports commit as they go, and that work stays, so status Error does not mean nothing happened.' +
            ' **Do not auto-retry.** Set the retry policy of an orchestrator entry to Never for any chain that contains this step.' +
            ' **Check what you are calling first.** Orchestrator.Report.List with processingOnly true lists Date Compress G/L Entries and Delete Invoiced Sales Orders next to the harmless ones. Confirm a reportId with Orchestrator.Report.Get.' +
            ' **No request page is shown.** Parameters come only from requestPageXml or the saved preset; capture a preset through the URL from Orchestrator.Report.Get.' +
            ' **Long runs need the queue.** A batch job can outlive a synchronous request: run it from a playbook with Orchestrator.Playbook.Enqueue, or invoke this type asynchronously.';
        exit(true);
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Outbound);
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteRun(Argument);
    end;

    var
        Handler: Codeunit "Report Msg Handler ori";
}
