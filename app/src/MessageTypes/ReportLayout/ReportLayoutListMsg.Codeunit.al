namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

/// <summary>Exposes read-only report layout list through Bifrost.</summary>
codeunit 10035612 "Report Layout List Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;

    /// <summary>Provides the IsEnabled part of the report layout list message.</summary>
    procedure IsEnabled(): Boolean
    begin
        exit(true);
    end;

    /// <summary>Provides the GetFilterTableNo part of the report layout list message.</summary>
    procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    /// <summary>Provides the GetDescription part of the report layout list message.</summary>
    procedure GetDescription(): Text[250]
    var
        DescriptionLbl: Label 'Lists extension and user-defined layouts for a report.', Comment = 'is-IS=Sýnir útlit skýrslu úr viðbótum og notandaskilgreind útlit.';
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>Provides the GetKeywords part of the report layout list message.</summary>
    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'list report layouts, report formats, extension layouts, user layouts', Comment = 'is-IS=sýna skýrsluútlit, skýrslusnið, útlit viðbóta, notandaútlit';
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>Provides the GetSelectionDescription part of the report layout list message.</summary>
    procedure GetSelectionDescription(): Text
    begin
        exit(GetDescription());
    end;

    /// <summary>Provides the GetEnvelope part of the report layout list message.</summary>
    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Forms: List of [Text];
    begin
        Envelope := Parts.Envelope(Forms, 'No subject is used; reportId is supplied in data.', true);
        exit(true);
    end;

    /// <summary>Provides the GetTarget part of the report layout list message.</summary>
    procedure GetTarget(var Target: JsonArray): Boolean
    begin
        exit(false);
    end;

    /// <summary>Provides the GetParameters part of the report layout list message.</summary>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('reportId', 'integer', true, 'Report object ID.'));
        Parameters.Add(ContractMgt.Parameter('includeExtensionLayouts', 'boolean', false, 'Include extension layouts; default true.'));
        exit(true);
    end;

    /// <summary>Provides the GetResponse part of the report layout list message.</summary>
    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Fields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'status', 'string', 'Success.');
        Parts.AddResponseField(Fields, 'reportId', 'integer', 'Report ID.');
        Parts.AddResponseField(Fields, 'layouts', 'array', 'Layouts with name, caption, format, userDefined, source, appId, description, layoutStatus and isDefault for the current company.');
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    /// <summary>Provides the GetErrors part of the report layout list message.</summary>
    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.AddError(Errors, 'Report <reportId> not found.', 'The report does not exist.', 'Use Orchestrator.Report.List.');
        Parts.AddError(Errors, 'Request must include "<key>".', 'A required key is missing.', 'Supply the documented required fields.');

        exit(true);
    end;

    /// <summary>Provides the GetEffect part of the report layout list message.</summary>
    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Preconditions: JsonArray;
    begin
        Effect := Parts.Effect('read', 'Reads report layout metadata or bytes; does not change layouts or defaults.', false, '', Preconditions);
        exit(true);
    end;

    /// <summary>Provides the GetMetering part of the report layout list message.</summary>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>Provides the GetRelated part of the report layout list message.</summary>
    procedure GetRelated(var Related: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.Related(Related, 'Orchestrator.Report.Get', 'Use this to inspect report metadata and existing layouts.');
        exit(true);
    end;

    /// <summary>Provides the GetWorkflow part of the report layout list message.</summary>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>Provides the GetExamples part of the report layout list message.</summary>
    procedure GetExamples(var Examples: JsonArray): Boolean
    begin
        exit(false);
    end;

    /// <summary>Provides the GetOverview part of the report layout list message.</summary>
    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Lists extension and user-defined layouts for a report.';
        exit(true);
    end;

    /// <summary>Provides the GetNotes part of the report layout list message.</summary>
    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'Read-only. No layout import, default-selection change or update-on-export is performed. Layout names and app IDs are returned by Orchestrator.ReportLayout.List.';
        exit(true);
    end;

    /// <summary>Provides the GetMessageDirection part of the report layout list message.</summary>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Outbound);
    end;

    /// <summary>Provides the ExecuteBifrostTask part of the report layout list message.</summary>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteList(Argument);
    end;

    var
        Handler: Codeunit "Report Layout Read Handler ori";
}
