/// <summary>
/// Implements the Orchestrator.Playbook.Schedule message type: creates an Orchestrator Entry
/// for a Bifrost Playbook using a recurring template and optional notification settings.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035574 "Playbook Schedule Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;

    /// <summary>
    /// Determines whether this message type is enabled.
    /// </summary>
    /// <returns>True; this message type is always enabled.</returns>
    procedure IsEnabled(): Boolean
    begin
        exit(true);
    end;

    /// <summary>
    /// Returns the table ID used to filter records for this message type.
    /// </summary>
    /// <returns>Zero; this message type is not bound to a table.</returns>
    procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    /// <summary>
    /// Returns a human-readable description of this message type.
    /// </summary>
    /// <returns>Description text.</returns>
    procedure GetDescription(): Text[250]
    var
        DescriptionLbl: Label 'Schedule a Bifrost Playbook as an Orchestrator Entry with a recurring template.', Comment = 'is-IS=ÃÃ¦tla BifrÃ¶st keÃ°ju sem vinnsluraÃ°arstjÃ³rafÃ¦rslu meÃ° endurtekningarsniÃ°mÃ¡ti.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'schedule playbook, recurring playbook, recurring template, schedule workflow', Comment = 'is-IS=áætlun keðju, endurtekin keðja, endurtekningarsniðmát, áætlun verkflæðis';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Schedule a Bifrost Playbook as an orchestrator entry using a recurring template. Write operation. Use Orchestrator.Playbook.Enqueue for a one-time run.', Comment = 'is-IS=Áætlun Bifröst-keðju sem áætlunarfærslu með endurtekningarsniðmáti. Skrifaðgerð. Notaðu Orchestrator.Playbook.Enqueue fyrir einskiptiskeyrslu.';
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
        Parameters.Add(ContractMgt.Parameter('playbookCode', 'string', false, 'Code of the playbook to schedule.'));
        Parameters.Add(ContractMgt.Parameter('recurringTemplateCode', 'string', true, 'Recurring template code.'));
        Parameters.Add(ContractMgt.Parameter('notificationType', 'string', false, 'None, EMail or Telegram.'));
        Parameters.Add(ContractMgt.Parameter('notificationRecipient', 'string', false, 'Notification recipient.'));
        Parameters.Add(ContractMgt.Parameter('jobQueueCategoryCode', 'string', false, 'Job Queue category code.'));
        Parameters.Add(ContractMgt.Parameter('emitTelemetry', 'boolean', false, 'Whether to emit telemetry.'));
        Parameters.Add(ContractMgt.Parameter('retryPolicy', 'string', false, 'Never, ThreeTimes or Always.'));
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Fields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'status', 'string', 'Success.');
        Parts.AddResponseField(Fields, 'playbookCode', 'string', 'Scheduled playbook code.');
        Parts.AddResponseField(Fields, 'scheduled', 'boolean', 'True when the entry was created.');
        Parts.AddResponseField(Fields, 'orchestratorEntryId', 'string', 'Scheduled Entry SystemId.');
        Parts.AddResponseField(Fields, 'orchestratorEntryPkId', 'string', 'Scheduled Entry primary key SystemId.');
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.AddRecordErrors(Errors, 'Playbook');
        Parts.AddRuntimeError(Errors, 'The recurring template or notification settings are invalid.', 'Check the template and notification values.');
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Preconditions: JsonArray;
    begin
        Effect := Parts.Effect('write', 'Creates an orchestrator entry and its Job Queue schedule.', true, '', Preconditions);
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
        Parts.Related(Related, 'Orchestrator.Playbook.Enqueue', 'Use this for a one-time delayed execution.');
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
        Parts.Example(Examples, 'Schedule a playbook', '{"type":"Orchestrator.Playbook.Schedule","data":{"playbookCode":"MYPLAYBOOK","recurringTemplateCode":"DAILY"}}', '{"status":"Success","scheduled":true,"playbookCode":"MYPLAYBOOK"}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Creates a recurring orchestrator entry for a configured Bifröst Playbook.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'Notification recipient requirements depend on notificationType; omitted values default to None and Always.';
        exit(true);
    end;

    /// <summary>
    /// Returns the message direction for this message type.
    /// </summary>
    /// <returns>Outbound direction.</returns>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Outbound);
    end;

    /// <summary>
    /// Returns Markdown help documentation for this message type.
    /// </summary>
    /// <param name="Argument">Message argument that receives the help text as response.</param>
    procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Help ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp('Orchestrator.Playbook.Schedule'));
    end;

    /// <summary>
    /// Executes the message type.
    /// </summary>
    /// <param name="Argument">Message argument carrying the request and receiving the response.</param>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteSchedule(Argument);
    end;

    var
        Handler: Codeunit "Playbook Msg Handler ori";
}
