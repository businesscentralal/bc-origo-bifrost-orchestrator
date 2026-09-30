/// <summary>
/// Implements the Orchestrator.Playbook.Run message type: executes a Bifrost Playbook immediately and
/// returns the execution result.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035562 "Playbook Run Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
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
        DescriptionLbl: Label 'Execute a Bifrost Playbook immediately and return results.', Comment = 'is-IS=Keyra BifrÃ¶st keÃ°ju strax og skila niÃ°urstÃ¶Ã°um.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'run playbook, execute playbook, playbook now, run workflow, execute workflow', Comment = 'is-IS=keyra keðju, framkvæma keðju, keðja núna, keyra verkflæði, framkvæma verkflæði';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Execute a Bifrost Playbook immediately and return its results. Write operation. Use Orchestrator.Playbook.Enqueue for background execution.', Comment = 'is-IS=Keyrðu Bifröst-keðju strax og skilaðu niðurstöðum. Skrifaðgerð. Notaðu Orchestrator.Playbook.Enqueue fyrir bakgrunnsvinnslu.';
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
        Parameters.Add(ContractMgt.Parameter('playbookCode', 'string', false, 'Code of the playbook to execute.'));
        Parameters.Add(ContractMgt.Parameter('initialRequest', 'object', false, 'JSON payload passed to the first step.'));
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Fields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'status', 'string', 'Success.');
        Parts.AddResponseField(Fields, 'instanceId', 'string', 'Playbook Instance SystemId.');
        Parts.AddResponseField(Fields, 'playbookCode', 'string', 'Executed playbook code.');
        Parts.AddResponseField(Fields, 'playbookStatus', 'string', 'Final playbook status.');
        Parts.AddResponseField(Fields, 'stepsExecuted', 'integer', 'Number of executed steps.');
        Parts.AddResponseField(Fields, 'stepsFailed', 'integer', 'Number of failed steps.');
        Parts.AddResponseField(Fields, 'itemsProcessed', 'integer', 'Total forEach items processed.');
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.AddRecordErrors(Errors, 'Playbook');
        Parts.AddRuntimeError(Errors, 'A playbook step failed.', 'Inspect the Playbook Step Log for the failed step.');
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Preconditions: JsonArray;
    begin
        Effect := Parts.Effect('write', 'Runs the playbook and writes its instance and step log.', false, '', Preconditions);
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
        Parts.Related(Related, 'Orchestrator.Playbook.Enqueue', 'Use this for a background run that should not depend on the caller session.');
        exit(true);
    end;

    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.Workflow(Workflow, 'Orchestrator.Playbook.Run', 'Execute the playbook steps in the configured order.');
        exit(true);
    end;

    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.Example(Examples, 'Run a playbook', '{"type":"Orchestrator.Playbook.Run","data":{"playbookCode":"MYPLAYBOOK","initialRequest":{}}}', '{"status":"Success","playbookCode":"MYPLAYBOOK","stepsExecuted":3,"stepsFailed":0}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Runs a configured Bifröst Playbook inline and returns its completed instance counters.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'Long-running or model-heavy playbooks should use Enqueue instead so the caller session is not abandoned.';
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
        Argument.SetResponseMarkdown(Help.GetHelp('Orchestrator.Playbook.Run'));
    end;

    /// <summary>
    /// Executes the message type.
    /// </summary>
    /// <param name="Argument">Message argument carrying the request and receiving the response.</param>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteRun(Argument);
    end;

    var
        Handler: Codeunit "Playbook Msg Handler ori";
}
