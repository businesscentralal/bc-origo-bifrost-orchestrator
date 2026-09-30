namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035594 "Report Get Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;
    Permissions =
        tabledata "Report Request Preset ori" = R;

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
        DescriptionLbl: Label 'Returns report metadata, available layouts, and saved request page preset.', Comment = 'is-IS=Skilar lÃ½sigÃ¶gnum skÃ½rslu, tiltÃ¦kum Ãºtlitum og vistuÃ°um forsendum beiÃ°nisÃ­Ã°u.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'get report, report details, report layouts, request page preset, report metadata', Comment = 'is-IS=sækja skýrslu, upplýsingar skýrslu, útlit skýrslu, forstilling beiðnisíðu, lýsigögn skýrslu';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Read one report''s metadata, layouts and current user request preset. Read-only. Use Orchestrator.Report.SaveAs or Orchestrator.Report.Run to execute it.', Comment = 'is-IS=Lestu lýsigögn, útlit og beiðniforstillingu núverandi notanda fyrir eina skýrslu. Lesaðgerð. Notaðu Orchestrator.Report.SaveAs eða Orchestrator.Report.Run til að keyra hana.';
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
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Fields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'id', 'integer', 'Report ID.');
        Parts.AddResponseField(Fields, 'name', 'string', 'Report object name.');
        Parts.AddResponseField(Fields, 'caption', 'string', 'Report caption.');
        Parts.AddResponseField(Fields, 'processingOnly', 'boolean', 'Whether the report is processing-only.');
        Parts.AddResponseField(Fields, 'defaultLayout', 'string', 'Default layout.');
        Parts.AddResponseField(Fields, 'layouts', 'array', 'Available report layouts.');
        Parts.AddResponseField(Fields, 'preset', 'object', 'Current user request preset.');
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.AddRecordErrors(Errors, 'Report');
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Preconditions: JsonArray;
    begin
        Effect := Parts.Effect('read', 'Reads report metadata, layouts and the current user preset.', true, '', Preconditions);
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
        Parts.Related(Related, 'Orchestrator.Report.SaveAs', 'Use this to render a non-processing-only report.');
        Parts.Related(Related, 'Orchestrator.Report.Run', 'Use this to run a processing-only report.');
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
        Parts.Example(Examples, 'Get report metadata', '{"type":"Orchestrator.Report.Get","data":{"reportId":50100}}', '{"id":50100,"name":"Customer List","layouts":[],"preset":{"hasRequestPageXml":false}}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Returns one report''s metadata, layouts and the current user''s saved request page preset.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'When no preset exists, an empty preset row is created so the response can provide the capture page URL.';
        exit(true);
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Both);
    end;

    procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Help ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp('Orchestrator.Report.Get'));
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteGet(Argument);
    end;

    var
        Handler: Codeunit "Report Msg Handler ori";
}
