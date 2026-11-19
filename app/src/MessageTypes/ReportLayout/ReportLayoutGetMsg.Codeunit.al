namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

/// <summary>Exposes read-only report layout get through Bifrost.</summary>
codeunit 10035613 "Report Layout Get Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;

    /// <summary>Provides the IsEnabled part of the report layout get message.</summary>
    procedure IsEnabled(): Boolean
    begin
        exit(true);
    end;

    /// <summary>Provides the GetFilterTableNo part of the report layout get message.</summary>
    procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    /// <summary>Provides the GetDescription part of the report layout get message.</summary>
    procedure GetDescription(): Text[250]
    var
        DescriptionLbl: Label 'Exports the bytes of an extension or user-defined report layout.', Comment = 'is-IS=Flytur út gögn skýrsluútlits úr viðbót eða notandaskilgreindu útliti.';
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>Provides the GetKeywords part of the report layout get message.</summary>
    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'export report layout, download layout, layout bytes, base64 layout', Comment = 'is-IS=flytja út skýrsluútlit, sækja útlit, útlitsgögn, base64 útlit';
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>Provides the GetSelectionDescription part of the report layout get message.</summary>
    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Export the bytes of one report layout, extension or user-defined, as base64. Read-only. Use Orchestrator.ReportLayout.List first to find the layout name and appId, or Orchestrator.ReportLayout.Set to import a layout.', Comment = 'is-IS=Fluttu út gögn eins skýrsluútlits, úr viðbót eða notandaskilgreind, sem base64. Lesaðgerð. Notaðu Orchestrator.ReportLayout.List fyrst til að finna heiti útlitsins og appId, eða Orchestrator.ReportLayout.Set til að flytja inn útlit.';
    begin
        exit(SelectionLbl);
    end;

    /// <summary>Provides the GetEnvelope part of the report layout get message.</summary>
    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Envelope := Parts.NoSubjectEnvelope(true, 'text/json');
        exit(true);
    end;

    /// <summary>Provides the GetTarget part of the report layout get message.</summary>
    procedure GetTarget(var Target: JsonArray): Boolean
    begin
        exit(false);
    end;

    /// <summary>Provides the GetParameters part of the report layout get message.</summary>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('reportId', 'integer', true, 'Report object ID.'));
        Parameters.Add(ContractMgt.Parameter('name', 'string', true, 'Exact layout name from ReportLayout.List.'));
        Parameters.Add(ContractMgt.Parameter('appId', 'string', false, 'Layout app GUID from ReportLayout.List; omitted means a user-defined layout.'));
        exit(true);
    end;

    /// <summary>Provides the GetResponse part of the report layout get message.</summary>
    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Fields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'status', 'string', 'Success.');
        Parts.AddResponseField(Fields, 'reportId', 'integer', 'Report ID.');
        Parts.AddResponseField(Fields, 'name', 'string', 'Layout name.');
        Parts.AddResponseField(Fields, 'appId', 'string', 'Layout app GUID.');
        Parts.AddResponseField(Fields, 'format', 'string', 'Word, RDLC, Excel or Custom.');
        Parts.AddResponseField(Fields, 'mimeType', 'string', MimeHelpLbl);
        Parts.AddResponseField(Fields, 'layoutBase64', 'string', 'Unmodified exported layout bytes encoded as base64.');
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    /// <summary>Provides the GetErrors part of the report layout get message.</summary>
    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.AddContractError(Errors, 'Report <reportId> not found.', 'The report does not exist.', 'Use Orchestrator.Report.List.');
        Parts.AddContractError(Errors, 'Request must include "reportId".', 'reportId is missing.', 'Send reportId.');
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::MissingParameter, MissingNameLbl, NameNextStepLbl));
        Parts.AddContractError(Errors, 'appId must be a valid GUID.', 'The supplied appId is not a GUID.', 'Use the appId returned by ReportLayout.List.');
        Parts.AddContractError(Errors, 'Layout <name> not found on report <reportId>.', 'No layout matches the name and appId.', 'Use ReportLayout.List and send the returned name and appId.');

        exit(true);
    end;

    /// <summary>Provides the GetEffect part of the report layout get message.</summary>
    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Preconditions: JsonArray;
    begin
        Effect := Parts.Effect('read', 'Exports the layout bytes; does not change layouts or defaults.', true, '', Preconditions);
        exit(true);
    end;

    /// <summary>Provides the GetMetering part of the report layout get message.</summary>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>Provides the GetRelated part of the report layout get message.</summary>
    procedure GetRelated(var Related: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.Related(Related, 'Orchestrator.ReportLayout.List', 'Use this first to find the layout name and appId.');
        Parts.Related(Related, 'Orchestrator.ReportLayout.Set', 'Use this to import or replace a user-defined layout.');
        Parts.Related(Related, 'Orchestrator.Report.Get', 'Use this to inspect report metadata and existing layouts.');
        exit(true);
    end;

    /// <summary>Provides the GetWorkflow part of the report layout get message.</summary>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Steps: JsonArray;
    begin
        Steps.Add(ContractMgt.WorkflowStep('Orchestrator.ReportLayout.List', 'Find the layout name and appId of the layout to export.'));
        Steps.Add(ContractMgt.WorkflowStep('Orchestrator.ReportLayout.Get', 'Export it as base64 with data.name and data.appId from the list.'));
        Workflow.Add('steps', Steps);
        Workflow.Add('text', 'Send appId only for an extension layout; a user-defined layout has none.');
        exit(true);
    end;

    /// <summary>Provides the GetExamples part of the report layout get message.</summary>
    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.Example(Examples, 'Export a user-defined layout', '{"type":"Orchestrator.ReportLayout.Get","data":{"reportId":206,"name":"custom"}}', '{"status":"Success","reportId":206,"name":"custom","appId":"00000000-0000-0000-0000-000000000000","format":"Word","mimeType":"application/vnd.openxmlformats-officedocument.wordprocessingml.document","layoutBase64":"<base64>"}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Exports the bytes of one report layout, extension or user-defined, as base64 together with its format and MIME type. Find the name and appId with Orchestrator.ReportLayout.List. Nothing is changed.';
        exit(true);
    end;

    /// <summary>Provides the GetNotes part of the report layout get message.</summary>
    procedure GetNotes(var Notes: Text): Boolean
    var
        Builder: TextBuilder;
    begin
        Notes := 'Read-only. No layout import, default-selection change or update-on-export is performed. Layout names and app IDs are returned by Orchestrator.ReportLayout.List.';
        Builder.AppendLine(Notes);
        Builder.AppendLine(DeletePolicyLbl);
        Notes := Builder.ToText();
        exit(true);
    end;

    /// <summary>Provides the GetMessageDirection part of the report layout get message.</summary>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Outbound);
    end;

    /// <summary>Provides the ExecuteBifrostTask part of the report layout get message.</summary>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Argument.AssertVersion1();
        Argument.AssertIsLicensed();
        Handler.ExecuteGet(Argument);
    end;

    var
        MissingNameLbl: Label 'name is missing. parameter: name.', Comment = 'is-IS=name vantar. parameter: name.';
        NameNextStepLbl: Label 'Send name from Orchestrator.ReportLayout.List.', Comment = 'is-IS=Sendu name úr Orchestrator.ReportLayout.List.';
        MimeHelpLbl: Label 'MIME type: Word = application/vnd.openxmlformats-officedocument.wordprocessingml.document; RDLC = application/xml; Excel = application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.', Comment = 'is-IS=MIME-gerð: Word = application/vnd.openxmlformats-officedocument.wordprocessingml.document; RDLC = application/xml; Excel = application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.';
        DeletePolicyLbl: Label 'No layout delete message type exists by design: message types must not delete data. Remove a test layout in BC on the Report Layouts page.', Comment = 'is-IS=Engin skilaboðategund til að eyða útliti er til samkvæmt hönnun: skilaboðategundir mega ekki eyða gögnum. Fjarlægðu prófunarútlit í BC á síðunni Skýrsluútlit.';
        Handler: Codeunit "Report Layout Read Handler ori";
}
