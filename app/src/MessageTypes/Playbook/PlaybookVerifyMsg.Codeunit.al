/// <summary>
/// Implements the Orchestrator.Playbook.Verify message type: reads a playbook and returns the
/// configuration warnings the engine would accept silently, without running anything.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035615 "Playbook Verify Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
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
        DescriptionLbl: Label 'Check a Bifrost Playbook for unsafe configuration without running it.', Comment = 'is-IS=Athuga hvort Bifröst keðja sé óörugglega uppsett án þess að keyra hana.';
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>
    /// Returns the search keywords of this message type.
    /// </summary>
    /// <returns>Comma-separated keywords.</returns>
    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'verify playbook, validate playbook, check playbook, playbook warnings, lint playbook', Comment = 'is-IS=sannreyna keðju, staðfesta keðju, athuga keðju, viðvaranir keðju, rýna keðju';
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>
    /// Returns the description shown when the message types are listed for selection.
    /// </summary>
    /// <returns>Selection description text.</returns>
    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Verify a Bifrost Playbook and return warnings, for example a per-item write that no Skip If Step Failed gates. Read-only. Run it before Orchestrator.Playbook.Run.', Comment = 'is-IS=Sannreyndu Bifröst-keðju og fáðu viðvaranir, til dæmis skrif fyrir hvert atriði sem ekkert Sleppa ef skref mistókst stýrir. Les eingöngu. Keyrðu þetta áður en Orchestrator.Playbook.Run er notað.';
    begin
        exit(SelectionLbl);
    end;

    /// <summary>
    /// Returns the envelope chapter of the contract.
    /// </summary>
    /// <param name="Envelope">Receives the envelope chapter.</param>
    /// <returns>True; the chapter exists.</returns>
    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Forms: List of [Text];
    begin
        Forms.Add('playbook code');
        Envelope := Parts.Envelope(Forms, 'The playbook code in data.playbookCode or as subject.', true);
        exit(true);
    end;

    /// <summary>
    /// Returns the target chapter of the contract.
    /// </summary>
    /// <param name="Target">Receives the target chapter.</param>
    /// <returns>True; the chapter exists.</returns>
    procedure GetTarget(var Target: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Target := Parts.PlaybookTarget();
        exit(true);
    end;

    /// <summary>
    /// Returns the parameters chapter of the contract.
    /// </summary>
    /// <param name="Parameters">Receives the parameters chapter.</param>
    /// <returns>True; the chapter exists.</returns>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('playbookCode', 'string', false, 'Code of the playbook to verify (Code[20]). Required unless subject carries the code.'));
        exit(true);
    end;

    /// <summary>
    /// Returns the response chapter of the contract.
    /// </summary>
    /// <param name="Response">Receives the response chapter.</param>
    /// <returns>True; the chapter exists.</returns>
    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Fields: JsonArray;
        WarningFields: JsonArray;
    begin
        Parts.AddResponseField(WarningFields, 'code', 'string', 'Warning code, for example UnsafeForEachWrite.');
        Parts.AddResponseField(WarningFields, 'stepNo', 'integer', 'The step the warning is about.');
        Parts.AddResponseField(WarningFields, 'checkStepNo', 'integer', 'The forEach Check step the step should be gated on.');
        Parts.AddResponseField(WarningFields, 'message', 'string', 'The warning in the language of the calling session (en-US or is-IS).');
        Parts.AddResponseField(Fields, 'status', 'string', 'Success, also when warnings were found.');
        Parts.AddResponseField(Fields, 'playbookCode', 'string', 'The verified playbook code.');
        Parts.AddResponseField(Fields, 'warningCount', 'integer', 'Number of warnings; 0 when the playbook is clean.');
        Parts.AddResponseField(Fields, 'warnings', 'array', 'One entry per warning.', WarningFields);
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    /// <summary>
    /// Returns the errors chapter of the contract.
    /// </summary>
    /// <param name="Errors">Receives the errors chapter.</param>
    /// <returns>True; the chapter exists.</returns>
    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.AddPlaybookErrors(Errors);
        exit(true);
    end;

    /// <summary>
    /// Returns the effect chapter of the contract.
    /// </summary>
    /// <param name="Effect">Receives the effect chapter.</param>
    /// <returns>True; the chapter exists.</returns>
    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Preconditions: JsonArray;
    begin
        Effect := Parts.Effect('read', 'Reads the playbook and its steps; changes nothing and runs no step.', true, '', Preconditions);
        exit(true);
    end;

    /// <summary>
    /// Returns the metering chapter of the contract.
    /// </summary>
    /// <param name="Metering">Receives the metering chapter.</param>
    /// <returns>False; the type is not metered.</returns>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>
    /// Returns the related message types of the contract.
    /// </summary>
    /// <param name="Related">Receives the related entries.</param>
    /// <returns>True; the chapter exists.</returns>
    procedure GetRelated(var Related: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.Related(Related, 'Orchestrator.Playbook.Run', 'Use this to execute the playbook once it verifies without warnings.');
        Parts.Related(Related, 'Orchestrator.Workspace.Preview', 'Use this to see the workspace paths a step template can reference.');
        exit(true);
    end;

    /// <summary>
    /// Returns the workflow chapter of the contract.
    /// </summary>
    /// <param name="Workflow">Receives the workflow chapter.</param>
    /// <returns>False; the type has no workflow chapter.</returns>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>
    /// Returns the examples chapter of the contract.
    /// </summary>
    /// <param name="Examples">Receives the examples.</param>
    /// <returns>True; the chapter exists.</returns>
    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.Example(Examples, 'Verify a playbook', '{"type":"Orchestrator.Playbook.Verify","data":{"playbookCode":"CUST-CREDIT-CTRL"}}', '{"status":"Success","playbookCode":"CUST-CREDIT-CTRL","warningCount":1,"warnings":[{"code":"UnsafeForEachWrite","stepNo":40,"checkStepNo":30,"message":"Step 40 (Data.Records.Set) writes for every item ..."}]}');
        exit(true);
    end;

    /// <summary>
    /// Returns the overview chapter of the contract.
    /// </summary>
    /// <param name="Overview">Receives the overview text.</param>
    /// <returns>True; the chapter exists.</returns>
    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Reads a Bifröst Playbook and returns warnings for configurations the engine accepts silently, without running a step.';
        exit(true);
    end;

    /// <summary>
    /// Returns the notes chapter of the contract.
    /// </summary>
    /// <param name="Notes">Receives the notes text.</param>
    /// <returns>True; the chapter exists.</returns>
    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'Warning UnsafeForEachWrite: an enabled forEach step with a write-type message type (its last name segment is Set, Post, Delete, Create, Update, Send and similar verbs) iterates the same array as an earlier enabled forEach Check step and has Skip If Step Failed = 0. Next Step No. edges apply once per forEach step, never per item, so only Skip If Step Failed = <check step> gates the write per item.' +
            ' The messages are returned in the language of the calling session (en-US and is-IS). A playbook with no warnings answers warningCount 0 and an empty warnings array.' +
            ' It does not look at roleCode values or operator spelling: an operator is an enum, so Data.Records.Set refuses a caption that is not an AL name, and the language model roles belong to Bifrost Bragi, which Bifrost Orchestrator does not depend on.';
        exit(true);
    end;

    /// <summary>
    /// Returns the message direction for this message type.
    /// </summary>
    /// <returns>Outbound direction; the type only reads.</returns>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Outbound);
    end;

    /// <summary>
    /// Executes the message type.
    /// </summary>
    /// <param name="Argument">Message argument carrying the request and receiving the response.</param>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteVerify(Argument);
    end;

    var
        Handler: Codeunit "Playbook Verify ori";
}
