/// <summary>
/// Implements the Orchestrator.Playbook.Verify message type: reads a playbook and returns the errors and
/// warnings the engine would accept silently, without running anything.
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
        DescriptionLbl: Label 'Check a Bifrost Playbook for errors and unsafe configuration without running it.', Comment = 'is-IS=Athuga hvort Bifröst keðja sé með villur eða óörugga uppsetningu án þess að keyra hana.';
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>
    /// Returns the search keywords of this message type.
    /// </summary>
    /// <returns>Comma-separated keywords.</returns>
    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'verify playbook, validate playbook, check playbook, playbook errors, playbook warnings, lint playbook', Comment = 'is-IS=sannreyna keðju, staðfesta keðju, athuga keðju, villur í keðju, viðvaranir keðju, rýna keðju';
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>
    /// Returns the description shown when the message types are listed for selection.
    /// </summary>
    /// <returns>Selection description text.</returns>
    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Verify a Bifrost Playbook and return its findings (errors and warnings), for example an unknown message type, a missing language model role or a per-item write that no Skip If Step Failed gates. Read-only for playbook data; a language model role check leaves a Foundation message log row. Run it before Orchestrator.Playbook.Run: Run and Schedule refuse a playbook that does not verify.', Comment = 'is-IS=Sannreyndu Bifröst-keðju og fáðu niðurstöður hennar (villur og viðvaranir), til dæmis óþekkta skilaboðategund, mállíkanshlutverk sem vantar eða skrif fyrir hvert atriði sem ekkert Sleppa ef skref mistókst stýrir. Les eingöngu keðjugögn; athugun á mállíkanshlutverki skilur eftir færslu í skilaboðaskrá Foundation. Keyrðu þetta áður en Orchestrator.Playbook.Run er notað: Run og Schedule hafna keðju sem sannreynist ekki.';
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
        FindingFields: JsonArray;
    begin
        Parts.AddResponseField(FindingFields, 'severity', 'string', 'error or warning. An error always stops Orchestrator.Playbook.Run and the enabling of a schedule; a warning does too unless the caller sets ignoreWarnings.');
        Parts.AddResponseField(FindingFields, 'stepNo', 'integer', 'The step the finding is about; 0 for a finding about the playbook as a whole.');
        Parts.AddResponseField(FindingFields, 'code', 'string', 'Stable code of the finding, for example UnsafeForEachWrite. The codes are listed in the notes.');
        Parts.AddResponseField(FindingFields, 'message', 'string', 'What is wrong, in the language of the calling session (en-US or is-IS).');
        Parts.AddResponseField(FindingFields, 'nextStep', 'string', 'What to do about it, in the language of the calling session.');
        Parts.AddResponseField(FindingFields, 'checkStepNo', 'integer', 'Only for UnsafeForEachWrite: the forEach Check step the step should be gated on.');
        Parts.AddResponseField(FindingFields, 'stepDisabled', 'boolean', 'Only present, and true, when the step is disabled. A finding about a disabled step never blocks a run or a schedule.');
        Parts.AddResponseField(Fields, 'status', 'string', 'Success, also when findings were returned.');
        Parts.AddResponseField(Fields, 'playbookCode', 'string', 'The verified playbook code.');
        Parts.AddResponseField(Fields, 'valid', 'boolean', 'True when there is no finding with severity error.');
        Parts.AddResponseField(Fields, 'errorCount', 'integer', 'Number of findings with severity error.');
        Parts.AddResponseField(Fields, 'warningCount', 'integer', 'Number of findings with severity warning.');
        Parts.AddResponseField(Fields, 'findings', 'array', 'One entry per finding, in step order; empty when the playbook is clean.', FindingFields);
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
        Effect := Parts.Effect('read', 'Reads the playbook, its steps and conditions, and looks up whether a language model role and the fields of a table exist; changes no playbook data and runs no step. A language model role check reads through Data.Records.Get and leaves a Foundation message log row, and is skipped inside a transaction that has already written.', true, '', Preconditions);
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
        Parts.Related(Related, 'Orchestrator.Playbook.Run', 'Use this to execute the playbook once it verifies without errors and warnings. Run verifies again and refuses a playbook that does not verify.');
        Parts.Related(Related, 'Orchestrator.Playbook.Schedule', 'Use this to put the playbook on a schedule once it verifies. It verifies again and refuses a playbook that does not verify.');
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
        Parts.Example(Examples, 'Verify a playbook with an ungated write', '{"type":"Orchestrator.Playbook.Verify","data":{"playbookCode":"CUST-CREDIT-CTRL"}}', '{"status":"Success","playbookCode":"CUST-CREDIT-CTRL","valid":true,"errorCount":0,"warningCount":1,"findings":[{"severity":"warning","stepNo":40,"code":"UnsafeForEachWrite","message":"Step 40 (Data.Records.Set) writes for every item ...","nextStep":"Set Skip If Step Failed to 30 on step 40.","checkStepNo":30}]}');
        Parts.Example(Examples, 'Verify a playbook with errors', '{"type":"Orchestrator.Playbook.Verify","subject":"CUST-CREDIT-CTRL"}', '{"status":"Success","playbookCode":"CUST-CREDIT-CTRL","valid":false,"errorCount":2,"warningCount":0,"findings":[{"severity":"error","stepNo":30,"code":"LanguageModelRoleNotFound","message":"Step 30 calls LLM.Prompt.Complete with roleCode HAIKU, but this company has no language model with that code. ...","nextStep":"List the codes with Data.Records.Get on table ..."},{"severity":"error","stepNo":50,"code":"StepReferenceNotFound","message":"Step 50 refers to step 45 (@45...), which does not exist in this playbook. ...","nextStep":"Correct the step number in the reference, or add the missing step."}]}');
        Parts.Example(Examples, 'A clean playbook', '{"type":"Orchestrator.Playbook.Verify","data":{"playbookCode":"OVERDUE-REPORT"}}', '{"status":"Success","playbookCode":"OVERDUE-REPORT","valid":true,"errorCount":0,"warningCount":0,"findings":[]}');
        exit(true);
    end;

    /// <summary>
    /// Returns the overview chapter of the contract.
    /// </summary>
    /// <param name="Overview">Receives the overview text.</param>
    /// <returns>True; the chapter exists.</returns>
    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Reads a Bifröst Playbook and returns errors and warnings for configurations the engine accepts silently, without running a step.';
        exit(true);
    end;

    /// <summary>
    /// Returns the notes chapter of the contract.
    /// </summary>
    /// <param name="Notes">Receives the notes text.</param>
    /// <returns>True; the chapter exists.</returns>
    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'Every finding has severity, stepNo, code, message and nextStep; the text is in the language of the calling session (en-US and is-IS). valid is true when no finding has severity error. A playbook with no findings answers valid true and an empty findings array.' +
            ' Every step is checked, enabled or not, so a playbook built with all steps disabled can be verified before anything is switched on. A finding about a disabled step carries stepDisabled true and never blocks a run or a schedule. UnsafeForEachWrite is judged on enabled steps only.' +
            ' Errors: MessageTypeUnavailable (the step calls a message type that does not exist in this deployment or is not enabled for this user in this company; a type that exists but is not enabled is not reported on a step that has a Start condition, because the author has decided when it runs, as the reporting tail does with _who.telegramChatId Exists), TemplateNotJson (the request template is not a JSON object; the engine would send an empty request), CheckWithoutSuccessCondition (a Check step with no Success condition answers yes every time), NextStepNotFound (a Next Step edge points to a step that does not exist), IterateSourceInvalid (the forEach source step is missing or does not come first), InvalidSkipGate (Skip If Step Failed names a step that is missing, does not come first or does not iterate, so every item would be skipped), StepReferenceNotFound and StepReferenceNotEarlier (an @stepNo reference to a step that is missing or does not run before), LanguageModelRoleNotFound (the roleCode of a LLM.* step is not a language model of this company), ScheduledWithErrors (the playbook is scheduled and has errors on enabled steps).' +
            ' Warnings: UnsafeForEachWrite (an enabled forEach step with a write-type message type iterates the same array as an earlier enabled forEach Check step and has Skip If Step Failed = 0; Next Step No. edges apply once per forEach step, never per item, so only Skip If Step Failed = <check step> gates the write per item), ActionWithoutSuccessCondition (an Action with no Success condition counts as successful whenever the type does not raise, also when it answers status Error), ForEachSourceUnguarded (a record reader that feeds a forEach has no Success condition on noOfRecords, so an empty answer still succeeds and the forEach does nothing), UnknownFieldReference (@_current.fields.X names a field the source table does not have, or @N.field and @N.@_iter.field name a field step N does not store in its Result Log Paths).' +
            ' A write-type message type is one whose last name segment is Set, Post, Delete, Create, Update, Insert, Modify, Cancel, Correct, Send, MakeOrder, Release, Reopen, Approve, Reject, Register, Schedule or Enqueue. A record reader is a Data.* type ending in Get, Find, Search or List.' +
            ' The roleCode of a LLM.* step is looked up with Data.Records.Get on table Bifrost Language Model ori, because the language models belong to Bifrost Bragi, which Bifrost Orchestrator does not depend on. When the table cannot be read (Bragi is not installed, or the caller may not read it) the check says nothing. Fields are looked up in the table metadata; a table that cannot be resolved is not judged. An operator that is not an AL name cannot be stored (Operator is an enum), so it is not a finding.' +
            ' Orchestrator.Playbook.Run and Orchestrator.Playbook.Schedule (and the Schedule action of the playbook card) verify first. They refuse with PreconditionFailed, naming the findings in the answer, when an enabled step has an error, or a warning unless the request sets ignoreWarnings to true; ignoreWarnings never waives an error. A run started by the Job Queue is not verified again.';
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
