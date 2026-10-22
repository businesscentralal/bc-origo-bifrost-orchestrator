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
        DescriptionLbl: Label 'Returns the seeded workspace (_sys dates, _who user context) without running any steps.', Comment = 'is-IS=Skilar forsendum vinnusvæðis (_sys dagsetningar, _who notandaupplýsingar) án þess að keyra skref.';
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
        SelectionLbl: Label 'Preview the seeded Playbook workspace without running steps. Seeding _who dispatches Help.WhoAmI.Get, which commits its own queue entry. Use Orchestrator.Playbook.Run to execute a playbook.', Comment = 'is-IS=Forskoðaðu upphafsstillt vinnusvæði keðju án þess að keyra skref. Upphafsstilling _who sendir Help.WhoAmI.Get, sem staðfestir eigin biðraðarfærslu. Notaðu Orchestrator.Playbook.Run til að keyra keðju.';
    begin
        exit(SelectionLbl);
    end;

    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Envelope := Parts.NoSubjectEnvelope(false, 'text/json');
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
        Parameters.Add(ContractMgt.Parameter('initialRequest', 'object', false, 'Simulates a run''s initial request: stored at _initial. A JSON string that holds an object is accepted too; any other string, number or boolean is ignored.'));
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Fields: JsonArray;
        SysFields: JsonArray;
    begin
        Parts.AddResponseField(SysFields, 'today', 'string', 'Today''s date.');
        Parts.AddResponseField(SysFields, 'workDate', 'string', 'The work date.');
        Parts.AddResponseField(SysFields, 'now', 'string', 'The current date and time.');
        Parts.AddResponseField(SysFields, 'year', 'integer', 'The current year.');
        Parts.AddResponseField(SysFields, 'lastMonthStart', 'string', 'First day of the previous month.');
        Parts.AddResponseField(SysFields, 'lastMonthEnd', 'string', 'Last day of the previous month.');
        Parts.AddResponseField(SysFields, 'thisMonthStart', 'string', 'First day of this month.');
        Parts.AddResponseField(SysFields, 'thisQuarterStart', 'string', 'First day of this quarter.');
        Parts.AddResponseField(SysFields, 'thisYearStart', 'string', 'First day of this year.');
        Parts.AddResponseField(SysFields, 'companyName', 'string', 'The company.');
        Parts.AddResponseField(SysFields, 'userId', 'string', 'The calling user.');
        Parts.AddResponseField(Fields, 'status', 'string', 'Success.');
        Parts.AddResponseField(Fields, '_sys', 'object', 'System constants, as @_sys.<key>. Dates are ISO 8601.', SysFields);
        Parts.AddResponseField(Fields, '_who', 'object', 'The Help.WhoAmI.Get answer without its status (user, salesperson, companyInfo, telegramChatId and more), as @_who.<path>. Left out when Help.WhoAmI.Get fails.');
        Parts.AddResponseField(Fields, '_initial', 'object', 'The initialRequest, when one was sent.');
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.AddRuntimeError(Errors, 'initialRequest is a JSON array.', 'Send an object, a string that holds one, or leave initialRequest out.');
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Effect := Parts.CommittingEffect('Builds a temporary workspace, but seeds _who through a nested Help.WhoAmI.Get dispatch that writes and commits its queue entry and may create the caller''s Bifrost user setup.', true);
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
        Parts.Related(Related, 'Orchestrator.Playbook.Run', 'Use this to execute the playbook once its templates are written.');
        Parts.Related(Related, 'Help.WhoAmI.Get', 'Use this for the user context alone.');
        exit(true);
    end;

    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Steps: JsonArray;
    begin
        Steps.Add(ContractMgt.WorkflowStep('Orchestrator.Workspace.Preview', 'Read the _sys and _who paths, optionally with a sample initialRequest.'));
        Steps.Add(ContractMgt.WorkflowStep('Orchestrator.Playbook.Verify', 'Check the request templates that use those paths.'));
        Steps.Add(ContractMgt.WorkflowStep('Orchestrator.Playbook.Run', 'Run the playbook once it verifies.'));
        Workflow.Add('steps', Steps);
        exit(true);
    end;

    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.Example(Examples, 'Preview the workspace', '{"type":"Orchestrator.Workspace.Preview","data":{"initialRequest":{"invoiceNo":"103002"}}}', '{"status":"Success","_sys":{"today":"2026-09-30","lastMonthStart":"2026-08-01","lastMonthEnd":"2026-08-31","companyName":"CRONUS"},"_who":{"salesperson":{"email":"<email>"},"telegramChatId":"<chatId>"},"_initial":{"invoiceNo":"103002"}}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Returns the seeded workspace context that the playbook runner would provide without executing any step: the _sys dates and company, the _who user context and, when sent, the _initial request. Use it to find the paths a request template can reference before building a playbook.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'The workspace is temporary; this message does not create a playbook instance or step log.' +
            ' Seeding _who dispatches Help.WhoAmI.Get in its own committed scope. Its queue entry and a possible first-use user setup cannot roll back with an outer transaction, so the effect is irreversible and the type cannot run inside an open write transaction. It changes no business data, so its direction stays Outbound.' +
            ' Call it before building a playbook to find the paths the request templates can use, such as @_sys.lastMonthStart and @_sys.lastMonthEnd for monthly filters, @_who.companyInfo.registrationNo, @_who.salesperson.email for recipients and @_who.telegramChatId. When debugging, compare it with the workspace snapshot of a failed step in the Bifrost Playbook Step Log.';
        exit(true);
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Outbound);
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
