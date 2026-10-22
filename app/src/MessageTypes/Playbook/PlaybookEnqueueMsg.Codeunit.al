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
        DescriptionLbl: Label 'Enqueue a Bifrost Playbook for one-time execution via Job Queue with custom request data.', Comment = 'is-IS=Setja Bifröst keðju í biðröð til einskiptiskeyrslu í gegnum vinnsluröð með sérsniðnum beiðnigögnum.';
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
        Target := Parts.PlaybookTarget();
        exit(true);
    end;

    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('playbookCode', 'string', false, 'Code of the playbook to enqueue (Code[20]). Required unless subject carries the code.'));
        Parameters.Add(ContractMgt.Parameter('initialRequest', 'object', false, 'JSON payload stored with the one-off Job Queue Entry and handed to the playbook as its initial request (_initial) when the job runs. When it is left out, the playbook''s own initial request template is used.'));
        Parameters.Add(ContractMgt.Parameter('jobQueueCategory', 'string', false, 'Job Queue Category Code (Code[10]) of the Job Queue Entry.'));
        Parameters.Add(ContractMgt.Parameter('delaySeconds', 'integer', false, 'Seconds before the run starts. Default 60; values below 60 are raised to 60.'));
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Fields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'status', 'string', 'Success.');
        Parts.AddResponseField(Fields, 'playbookCode', 'string', 'Enqueued playbook code.');
        Parts.AddResponseField(Fields, 'jobQueueEntryId', 'string', 'ID (primary key) of the one-off Job Queue Entry, not its SystemId.');
        Parts.AddResponseField(Fields, 'delaySeconds', 'integer', 'Effective delay, at least 60.');
        Parts.AddResponseField(Fields, 'jobQueueCategory', 'string', 'Present only when a category was sent.');
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.AddPlaybookErrors(Errors);
        Parts.AddRuntimeError(Errors, 'delaySeconds is not a whole number, or Job Queue - Enqueue refuses the entry.', 'Send delaySeconds as an integer and check the Job Queue setup.');
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Preconditions: JsonArray;
    begin
        Effect := Parts.Effect('write', 'Creates a one-time Job Queue Entry and stores the initial request. Every call queues one more run.', false, '', Preconditions);
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
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Steps: JsonArray;
    begin
        Steps.Add(ContractMgt.WorkflowStep('Orchestrator.Playbook.Verify', 'Check the playbook before it is queued; Enqueue does not verify it.'));
        Steps.Add(ContractMgt.WorkflowStep('Orchestrator.Playbook.Enqueue', 'Queue the one-time background run; keep jobQueueEntryId from the answer.'));
        Workflow.Add('steps', Steps);
        Workflow.Add('text', 'The answer comes before the run. Follow the run in the Bifrost Playbook Instance and Bifrost Playbook Step Log tables.');
        exit(true);
    end;

    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.Example(Examples, 'Enqueue a playbook', '{"type":"Orchestrator.Playbook.Enqueue","data":{"playbookCode":"MYPLAYBOOK","initialRequest":{"invoiceNo":"103002"},"delaySeconds":60}}', '{"status":"Success","playbookCode":"MYPLAYBOOK","jobQueueEntryId":"<guid>","delaySeconds":60}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Queues a Bifröst Playbook for one-time background execution through the Job Queue and returns the id of the one-off Job Queue Entry. The call answers before the playbook runs; use it for runs that are slow or must not depend on the caller session. Every call queues another run.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'The effective delay is at least 60 seconds. The call answers before the playbook runs: the one-off, non-recurring Job Queue Entry is handed to the Job Queue and runs at its earliest start in a background session, where it writes a playbook instance like Orchestrator.Playbook.Run. Follow it in the Bifrost Playbook Instance and Bifrost Playbook Step Log tables. The playbook is not verified when it is enqueued, and a run started by the Job Queue is not verified either: call Orchestrator.Playbook.Verify first.';
        exit(true);
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Inbound);
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteEnqueue(Argument);
    end;

    var
        Handler: Codeunit "Playbook Msg Handler ori";
}
