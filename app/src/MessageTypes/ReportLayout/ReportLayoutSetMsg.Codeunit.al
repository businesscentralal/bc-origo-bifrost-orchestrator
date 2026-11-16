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
        DescriptionLbl: Label 'Creates or replaces a user-defined report layout via the BC layout import path, and sets or clears the default layout.', Comment = 'is-IS=Býr til eða skiptir út notandaskilgreindu skýrsluútliti um innflutningsleið BC og stillir eða hreinsar sjálfgefið útlit.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'set report layout, import report layout, replace report layout, base64 layout, Word layout, Excel layout, RDLC layout, default report layout, clear default layout', Comment = 'is-IS=stilla skýrsluútlit, flytja inn skýrsluútlit, skipta út skýrsluútliti, base64 útlit, Word útlit, Excel útlit, RDLC útlit, sjálfgefið skýrsluútlit, hreinsa sjálfgefið útlit';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Create or replace a user-defined tenant report layout from base64 or from a staging row, and optionally make it the default; or make an existing layout the default, or clear the default, in the current company. Write operation. Use Orchestrator.ReportLayout.List to inspect existing layouts.', Comment = 'is-IS=Búðu til eða skiptu út notandaskilgreindu útliti leigjanda úr base64 eða milligeymslufærslu og gerðu það sjálfgefið ef þú vilt; eða gerðu útlit sem er til sjálfgefið, eða hreinsaðu sjálfgefna útlitið, í núverandi fyrirtæki. Skrifaðgerð. Notaðu Orchestrator.ReportLayout.List til að skoða núverandi útlit.';
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
        Parameters.Add(ContractMgt.Parameter('setAsDefault', 'boolean', false, 'true makes the layout the default of the report in the current company. With layoutBase64 or stagingId the imported layout becomes the default. Without a layout file, name (and appId when the name is not unique) selects an existing built-in, extension or user-defined layout; layoutFormat is then not needed. Default false.'));
        Parameters.Add(ContractMgt.Parameter('clearDefault', 'boolean', false, 'true removes the current company''s default layout selection, so the all-companies selection applies, or the report''s built-in default when there is none. Send it with reportId only: name and layoutFormat are not needed, and layoutBase64, stagingId and setAsDefault are refused. Default false.'));
        Parameters.Add(ContractMgt.Parameter('appId', 'string', false, 'App ID (GUID) of the layout to make the default, as Orchestrator.ReportLayout.List returns it; the empty GUID is a user-defined layout. Only with setAsDefault and no layout file. Needed when more than one layout on the report has that name.'));
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
        Parts.AddResponseField(Fields, 'action', 'string', 'Created or Replaced when a layout file is imported; DefaultSet when setAsDefault selects an existing layout; DefaultCleared when clearDefault removed the selection, NoChange when there was none.');
        Parts.AddResponseField(Fields, 'isDefault', 'boolean', 'true when the named layout is the default of the report in the current company after the call.');
        Parts.AddResponseField(Fields, 'appId', 'string', 'App ID of the layout that is now the default. Only with setAsDefault and no layout file, or with clearDefault (the default that applies after the call).');
        Parts.AddResponseField(Fields, 'previousDefault', 'string', 'Name of the layout that was the default before the call. Only with setAsDefault or clearDefault; send it back with previousDefaultAppId as name and appId to restore it.');
        Parts.AddResponseField(Fields, 'previousDefaultAppId', 'string', 'App ID of the previous default layout. Only with setAsDefault or clearDefault.');
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
        Parts.AddContractError(Errors, 'Send either "setAsDefault" or "clearDefault", not both.', 'Both setAsDefault and clearDefault are true.', 'Send one of them. Nothing is changed.');
        Parts.AddContractError(Errors, 'Send "clearDefault" without "layoutBase64" or "stagingId".', 'clearDefault is true and a layout file is in the request.', 'Clear the default in its own call. Nothing is changed or taken.');
        Parts.AddContractError(Errors, 'Send "appId" only with "setAsDefault" and no layout file.', 'appId is in a request that imports a layout file.', 'Leave out appId: an imported layout is always user-defined.');
        Parts.AddContractError(Errors, '"appId" <appId> is not a valid GUID.', 'appId is not a GUID.', 'Send the appId Orchestrator.ReportLayout.List returns.');
        Parts.AddContractError(Errors, 'Layout <name> not found on report <reportId>.', 'setAsDefault without a layout file names a layout (and appId) the report does not have.', 'Find the name and appId with Orchestrator.ReportLayout.List. Nothing is changed.');
        Parts.AddContractError(Errors, 'More than one layout named <name> exists on report <reportId>. Send "appId".', 'setAsDefault without a layout file and without appId matches layouts from more than one app.', 'Send the appId of the layout from Orchestrator.ReportLayout.List.');
        Parts.AddContractError(Errors, 'Layout <name> is a header, footer or theme part and cannot be the default layout of report <reportId>.', 'The selected layout is a header/footer or theme part, not a report layout.', 'Choose a report layout from Orchestrator.ReportLayout.List.');
        Parts.AddContractError(Errors, 'Layout <name> belongs to company <companyName> and cannot be the default in company <current company>.', 'The user-defined layout is limited to another company.', 'Make it the default in that company, or import it for all companies (no companyName).');
        Parts.AddContractError(Errors, '"<key>" must be true or false.', 'setAsDefault or clearDefault is an object or array.', 'Send true or false.');
        Parts.AddRuntimeError(Errors, 'layoutBase64 is not valid base64, or the layout import fails. A failed import of a staged layout leaves the staging row in place.', 'Send the file content base64-encoded, in the format named by layoutFormat.');
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Preconditions: JsonArray;
    begin
        Effect := Parts.Effect('write', ChangesLbl, false, '', Preconditions);
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
        Steps.Add(ContractMgt.WorkflowStep('Orchestrator.ReportLayout.Set', 'Send setAsDefault true to make the layout the default in the current company; keep previousDefault and previousDefaultAppId from the answer. To restore, send setAsDefault with name and appId set to them, or clearDefault to fall back to the built-in default.'));
        Workflow.Add('steps', Steps);
        exit(true);
    end;

    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.Example(Examples, 'Create a Word layout', '{"type":"Orchestrator.ReportLayout.Set","data":{"reportId":50100,"name":"custom","layoutFormat":"Word","layoutBase64":"<base64>"}}', '{"status":"Success","reportId":50100,"name":"custom","layoutFormat":"Word","action":"Created","isDefault":false}');
        Parts.Example(Examples, 'Import a Word layout and make it the default', '{"type":"Orchestrator.ReportLayout.Set","data":{"reportId":1306,"name":"Christmas","layoutFormat":"Word","stagingId":"<staging row id>","setAsDefault":true}}', '{"status":"Success","reportId":1306,"name":"Christmas","layoutFormat":"Word","action":"Created","previousDefault":"StandardSalesInvoice.docx","previousDefaultAppId":"<app id>","isDefault":true}');
        Parts.Example(Examples, 'Make an existing layout the default', '{"type":"Orchestrator.ReportLayout.Set","data":{"reportId":1306,"name":"StandardSalesInvoice.docx","appId":"<app id>","setAsDefault":true}}', '{"status":"Success","reportId":1306,"name":"StandardSalesInvoice.docx","layoutFormat":"Word","appId":"<app id>","action":"DefaultSet","previousDefault":"Christmas","previousDefaultAppId":"00000000-0000-0000-0000-000000000000","isDefault":true}');
        Parts.Example(Examples, 'Clear the company default', '{"type":"Orchestrator.ReportLayout.Set","data":{"reportId":1306,"clearDefault":true}}', '{"status":"Success","reportId":1306,"name":"StandardSalesInvoice.docx","layoutFormat":"Word","appId":"<app id>","previousDefault":"Christmas","previousDefaultAppId":"00000000-0000-0000-0000-000000000000","action":"DefaultCleared","isDefault":true}');
        Parts.Example(Examples, 'Create a Word layout from a staging row', '{"type":"Orchestrator.ReportLayout.Set","data":{"reportId":50100,"name":"custom","layoutFormat":"Word","stagingId":"<staging row id>"}}', '{"status":"Success","reportId":50100,"name":"custom","layoutFormat":"Word","action":"Created","isDefault":false}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Creates or replaces a user-defined tenant report layout from a base64 Word, Excel or RDLC file, or from a staging row holding the file (for example from a chunked upload), through the same import path the Report Layouts page uses. It never changes a layout that an extension ships. With setAsDefault the imported layout, or without a file an existing built-in, extension or user-defined layout, becomes the default of the report in the current company; clearDefault removes that company default so the all-companies selection, or else the built-in default, applies again. Send at most one of layoutBase64 or stagingId. A staging row is read and deleted in the same transaction as the import, so a failed import leaves it in place.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'Only user-defined layouts (no App ID) are created or replaced; a layout an extension ships is never changed. The file is imported through the Tenant Report Layout media field, the path the Report Layouts page uses. Do not write the layout with Data.Records.Set on Tenant Report Layout (2000000232) or Tenant Report Layout Selection (2000000233).' +
            ' setAsDefault and clearDefault make the same writes as the Set Default action of the Report Layouts page, for the current company only: the company-wide Tenant Report Layout Selection row (no per-user selection) and the type in Report Layout Selection. Other companies and users'' own layout choices are not changed. Deleting a layout is not available as a message type; use the Report Layouts page.';
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
        ChangesLbl: Label 'Imports a user-defined layout and creates or replaces the tenant layout row. With setAsDefault, the layout becomes the default of the report in the current company (Tenant Report Layout Selection and Report Layout Selection); with clearDefault, that company default is removed and the all-companies or built-in default applies. Both can be set back with another call.', Comment = 'is-IS=Flytur inn notandaskilgreint útlit og býr til eða skiptir út útlitsfærslu leigjanda. Með setAsDefault verður útlitið sjálfgefið útlit skýrslunnar í núverandi fyrirtæki (Tenant Report Layout Selection og Report Layout Selection); með clearDefault er sjálfgefna útlitið fjarlægt og sjálfgefið útlit allra fyrirtækja eða innbyggða sjálfgefna útlitið gildir. Hvort tveggja má setja til baka með öðru kalli.';
}
