namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035584 "Playbook Enqueue Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
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
        DescriptionLbl: Label 'Enqueue a Bifrost Playbook for one-time execution via Job Queue with custom request data.', Comment = 'is-IS=Setja BifrÃ¶st keÃ°ju Ã­ biÃ°rÃ¶Ã° til einskiptiskeyrslu meÃ° sÃ©rsniÃ°num gÃ¶gnum.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'enqueue playbook, queue playbook, background playbook, delayed workflow', Comment = 'is-IS=setja keðju í biðröð, raða keðju, keðja í bakgrunni, seinkað verkflæði';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Enqueue a Bifrost Playbook for one-time background execution. Write operation. Use Orchestrator.Playbook.Run for immediate foreground execution.', Comment = 'is-IS=Settu Bifröst-keðju í biðröð fyrir einskiptis bakgrunnsvinnslu. Skrifaðgerð. Notaðu Orchestrator.Playbook.Run fyrir tafarlausa keyrslu í forgrunni.';
    begin
        exit(SelectionLbl);
    end;

    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Forms: List of [Text];
    begin
        Forms.Add('playbook code');
        Envelope := Parts.Envelope(Forms, 'The playbook code in data.playbookCode or as subject.', true);
        exit(true);
    end;

    procedure GetTarget(var Target: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Target := Parts.Target('data.playbookCode, subject', 'code', 'The Playbook code.');
        exit(true);
    end;

    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('playbookCode', 'string', false, 'Code of the playbook to enqueue.'));
        Parameters.Add(ContractMgt.Parameter('initialRequest', 'object', false, 'JSON payload stored for the first step.'));
        Parameters.Add(ContractMgt.Parameter('jobQueueCategory', 'string', false, 'Job Queue category code.'));
        Parameters.Add(ContractMgt.Parameter('delaySeconds', 'integer', false, 'Delay before execution; values below 60 become 60.'));
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Fields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'status', 'string', 'Success.');
        Parts.AddResponseField(Fields, 'playbookCode', 'string', 'Enqueued playbook code.');
        Parts.AddResponseField(Fields, 'jobQueueEntryId', 'string', 'Created Job Queue Entry SystemId.');
        Parts.AddResponseField(Fields, 'delaySeconds', 'integer', 'Effective delay.');
        Parts.AddResponseField(Fields, 'jobQueueCategory', 'string', 'Category when supplied.');
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.AddRecordErrors(Errors, 'Playbook');
        Parts.AddRuntimeError(Errors, 'The playbook could not be enqueued.', 'Check the playbook and Job Queue setup.');
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Preconditions: JsonArray;
    begin
        Effect := Parts.Effect('write', 'Creates a one-time Job Queue Entry and stores the initial request.', true, '', Preconditions);
        exit(true);
    end;

    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    procedure GetRelated(var Related: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.Related(Related, 'Orchestrator.Playbook.Run', 'Use this when the playbook should run immediately in the caller session.');
        exit(true);
    end;

    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        exit(false);
    end;

    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.Example(Examples, 'Enqueue a playbook', '{"type":"Orchestrator.Playbook.Enqueue","data":{"playbookCode":"MYPLAYBOOK","delaySeconds":60}}', '{"status":"Success","playbookCode":"MYPLAYBOOK","delaySeconds":60,"jobQueueEntryId":"<systemId>"}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Queues a Bifröst Playbook for one-time background execution through the Job Queue.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'The effective delay is at least 60 seconds; initialRequest is stored for the first step.';
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
        Argument.SetResponseMarkdown(Help.GetHelp('Orchestrator.Playbook.Enqueue'));
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteEnqueue(Argument);
    end;

    var
        Handler: Codeunit "Playbook Msg Handler ori";
}
