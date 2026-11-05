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
        SelectionLbl: Label 'Create or replace a user-defined tenant report layout from base64 or from a staging row. Write operation. Use Orchestrator.Report.Get to inspect existing layouts.', Comment = 'is-IS=Búðu til eða skiptu út notandaskilgreindu útliti leigjanda úr base64 eða milligeymslufærslu. Skrifaðgerð. Notaðu Orchestrator.Report.Get til að skoða núverandi útlit.';
    begin
        exit(SelectionLbl);
    end;

    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Envelope := Parts.NoSubjectEnvelope(true, 'text/json');
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
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Formats: List of [Text];
    begin
        Formats.Add('Word');
        Formats.Add('Excel');
        Formats.Add('RDLC');
        Formats.Add('RDL');
        Parameters.Add(ContractMgt.Parameter('reportId', 'integer', true, 'Report object ID.'));
        Parameters.Add(ContractMgt.Parameter('name', 'string', true, 'Name of the user-defined layout, cut to 250 characters. A user-defined layout with this name on the report is replaced.'));
        Parameters.Add(Parts.WithChoices(ContractMgt.Parameter('layoutFormat', 'string', true, 'Layout format. Case-insensitive; RDL is stored as RDLC.'), Formats, ''));
        Parameters.Add(ContractMgt.Parameter('layoutBase64', 'string', false, 'The layout file (.docx, .xlsx or .rdl) as non-empty base64. Required unless stagingId is sent; send exactly one of layoutBase64 or stagingId.'));
        Parameters.Add(ContractMgt.Parameter('description', 'string', false, 'Layout description, cut to 250 characters; defaults to name.'));
        Parameters.Add(ContractMgt.Parameter('companyName', 'string', false, 'Company the layout belongs to, cut to 30 characters; empty for all companies.'));
        Parameters.Add(ContractMgt.Parameter('stagingId', 'string', false, 'Id (GUID, with or without braces) of a staging row you created, holding the layout file. Required unless layoutBase64 is sent; send exactly one of layoutBase64 or stagingId. The row is read and deleted in the same transaction as the import, so a failed import leaves it in place and the call can be retried.'));
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
        Parts.AddContractError(Errors, 'Request must include "<key>".', 'reportId, name or layoutFormat is missing.', 'Send reportId, name, layoutFormat and one of layoutBase64 or stagingId.');
        Parts.AddContractError(Errors, 'Layout format <layoutFormat> is not valid for report <reportId>.', 'layoutFormat is not Word, Excel, RDLC or RDL.', 'Send one of those formats.');
        Parts.AddContractError(Errors, 'Report <reportId> not found.', 'No report with that ID exists in Report Metadata.', 'Find the ID with Orchestrator.Report.List.');
        Parts.AddContractError(Errors, 'Request must include non-empty "layoutBase64".', 'layoutBase64 is empty.', 'Send the layout file as base64.');
        Parts.AddContractError(Errors, 'Send either "layoutBase64" or "stagingId", not both.', 'Both layoutBase64 and stagingId are in the request.', 'Send exactly one of them. Nothing is imported or taken.');
        Parts.AddContractError(Errors, 'Request must include "layoutBase64" or "stagingId".', 'Neither layoutBase64 nor stagingId is in the request.', 'Send exactly one of them.');
        Parts.AddContractError(Errors, '"stagingId" <stagingId> is not a valid GUID.', 'stagingId is not a GUID.', 'Send the id of the staging row, with or without braces.');
        Parts.AddContractError(Errors, 'Staging row <stagingId> was not found or has already been taken.', 'No staging row with that id exists for the calling user in this company, or it was already taken.', 'Create a new staging row and send its id. Nothing is imported.');
        Parts.AddRuntimeError(Errors, 'layoutBase64 is not valid base64, or the layout import fails. A failed import of a staged layout leaves the staging row in place.', 'Send the file content base64-encoded, in the format named by layoutFormat.');
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
        Parts.Related(Related, 'Orchestrator.ReportLayout.List', 'Use this to see the existing layouts before importing one.');
        Parts.Related(Related, 'Orchestrator.ReportLayout.Get', 'Use this to export a layout, for example to edit it and import it again.');
        Parts.Related(Related, 'Orchestrator.Report.Get', 'Use this to inspect report metadata and existing layouts.');
        exit(true);
    end;

    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Steps: JsonArray;
    begin
        Steps.Add(ContractMgt.WorkflowStep('Orchestrator.ReportLayout.List', 'See which layouts the report has.'));
        Steps.Add(ContractMgt.WorkflowStep('Orchestrator.ReportLayout.Set', 'Import the layout file as base64; a user-defined layout with the same name is replaced. For a large layout, upload it to a staging row first (for example from a chunked upload) and send stagingId instead of layoutBase64.'));
        Steps.Add(ContractMgt.WorkflowStep('Orchestrator.Report.SaveAs', 'Render the report with layoutName set to the imported name to check the result.'));
        Workflow.Add('steps', Steps);
        exit(true);
    end;

    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.Example(Examples, 'Create a Word layout', '{"type":"Orchestrator.ReportLayout.Set","data":{"reportId":50100,"name":"custom","layoutFormat":"Word","layoutBase64":"<base64>"}}', '{"status":"Success","reportId":50100,"name":"custom","layoutFormat":"Word","action":"Created","isDefault":false}');
        Parts.Example(Examples, 'Create a Word layout from a staging row', '{"type":"Orchestrator.ReportLayout.Set","data":{"reportId":50100,"name":"custom","layoutFormat":"Word","stagingId":"<staging row id>"}}', '{"status":"Success","reportId":50100,"name":"custom","layoutFormat":"Word","action":"Created","isDefault":false}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Creates or replaces a user-defined tenant report layout from a base64 Word, Excel or RDLC file, or from a staging row holding the file (for example from a chunked upload), through the same import path the Report Layouts page uses. It never changes a layout that an extension ships and does not set the default layout. Send exactly one of layoutBase64 or stagingId. A staging row is read and deleted in the same transaction as the import, so a failed import leaves it in place.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'Only user-defined layouts (no App ID) are created or replaced; a layout an extension ships is never changed. The file is imported through the Tenant Report Layout media field, the path the Report Layouts page uses. Do not write the layout with Data.Records.Set on Tenant Report Layout (2000000232) or Tenant Report Layout Selection (2000000233).' +
            ' Setting the default layout is not implemented, so isDefault is always false; choose the default on the Report Layouts page.';
        exit(true);
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Inbound);
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Argument.AssertVersion1();
        Argument.AssertIsLicensed();
        Handler.ExecuteSet(Argument);
    end;

    var
        Handler: Codeunit "Report Layout Handler ori";
}
