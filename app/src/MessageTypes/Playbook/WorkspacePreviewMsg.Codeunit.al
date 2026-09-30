namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035596 "Workspace Preview Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
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
        DescriptionLbl: Label 'Returns the seeded workspace (_sys dates, _who user context) without running any steps.', Comment = 'is-IS=Skilar forsendum vinnusvÃ¦Ã°is (_sys dagsetningar, _who notandaupplÃ½singar) Ã¡n Ã¾ess aÃ° keyra skref.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'workspace preview, preview workspace, seed workspace, sys dates, user context', Comment = 'is-IS=forskoða vinnusvæði, forskoðun vinnusvæðis, upphafsstilla vinnusvæði, kerfisdagsetningar, notandasamhengi';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Read the seeded Playbook workspace without running steps. Read-only. Use Orchestrator.Playbook.Run to execute a playbook.', Comment = 'is-IS=Lestu forsendu vinnusvæði keðju án þess að keyra skref. Lesaðgerð. Notaðu Orchestrator.Playbook.Run til að keyra keðju.';
    begin
        exit(SelectionLbl);
    end;

    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Forms: List of [Text];
    begin
        Envelope := Parts.Envelope(Forms, 'No subject is used.', false);
        exit(true);
    end;

    procedure GetTarget(var Target: JsonArray): Boolean
    begin
        exit(false);
    end;

    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('initialRequest', 'object', false, 'Optional initial workspace payload.'));
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Fields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'status', 'string', 'Success.');
        Parts.AddResponseField(Fields, '_sys', 'object', 'Seeded system date and time context.');
        Parts.AddResponseField(Fields, '_who', 'object', 'Current user context.');
        Parts.AddResponseField(Fields, '_initial', 'object', 'Initial request when supplied.');
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.AddRuntimeError(Errors, 'The initialRequest is not a JSON object.', 'Send an object or omit initialRequest.');
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Preconditions: JsonArray;
    begin
        Effect := Parts.Effect('read', 'Builds and returns a temporary seeded workspace.', true, '', Preconditions);
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
        Parts.Related(Related, 'Orchestrator.Playbook.Run', 'Use this when workspace preview should be followed by playbook execution.');
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
        Parts.Example(Examples, 'Preview the workspace', '{"type":"Orchestrator.Workspace.Preview","data":{"initialRequest":{}}}', '{"status":"Success","_sys":{},"_who":{}}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Returns the seeded workspace context that a Playbook Runner would provide without executing any step.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'The workspace is temporary; this message does not create a Playbook Instance or log.';
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
        Argument.SetResponseMarkdown(Help.GetHelp('Orchestrator.Workspace.Preview'));
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        Workspace: Codeunit "Playbook Workspace ori";
        InitialToken: JsonToken;
        InitialJson: JsonObject;
        ResponseJson: JsonObject;
    begin
        Workspace.Reset();

        if Argument.GetRequestJson().Get('initialRequest', InitialToken) then
            if InitialToken.IsObject() then
                Workspace.SetToken('_initial', InitialToken)
            else
                if InitialJson.ReadFrom(InitialToken.AsValue().AsText()) then
                    Workspace.SetToken('_initial', InitialJson.AsToken());

        ResponseJson := Workspace.GetData();
        ResponseJson.Add('status', 'Success');
        Argument.SetResponseJson(ResponseJson);
    end;
}
