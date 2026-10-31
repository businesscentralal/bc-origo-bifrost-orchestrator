namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>
/// Issue #109: the template-level checks of Orchestrator.Playbook.Verify, each with a positive and a negative case:
/// request template that is not JSON, @stepNo references to a missing or later step, the roleCode of a language model
/// step, and field references (@_current.fields.X, @N.field, @N.@_iter.field), plus the lookups behind them.
/// </summary>
codeunit 96439 "Playbook Verify Template Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Lib: Codeunit "Playbook Test Library ori";
        RequestFormat1Tok: Label 'No %1 finding on step %2', Locked = true;
        PlaybookCodeTok: Label 'VERIFY-109', Locked = true;
        ErrorTok: Label 'error', Locked = true;
        WarningTok: Label 'warning', Locked = true;
        NotJsonStartTxt: Label 'The request template of step 20 is not a valid JSON object.', Locked = true;
        NotJsonStartIsTxt: Label 'Beiðnisniðmát skrefs 20 er ekki gildur JSON-hlutur.', Locked = true;
        NotFoundStartTxt: Label 'Step 20 refers to step 45 (@45...), which does not exist in this playbook.', Locked = true;
        NotFoundStartIsTxt: Label 'Skref 20 vísar í skref 45 (@45...), sem er ekki til í þessari keðju.', Locked = true;
        NotEarlierStartTxt: Label 'Step 20 refers to step 30 (@30...), which does not run before it', Locked = true;
        NotEarlierStartIsTxt: Label 'Skref 20 vísar í skref 30 (@30...), sem keyrir ekki á undan því', Locked = true;
        RoleStartTxt: Label 'Step 10 calls LLM.Prompt.Complete with roleCode HAIKU, but this company has no language model with that code.', Locked = true;
        RoleStartIsTxt: Label 'Skref 10 kallar á LLM.Prompt.Complete með roleCode HAIKU, en þetta fyrirtæki hefur ekkert mállíkan með þeim kóða.', Locked = true;
        StepFieldStartTxt: Label 'Step 40 reads @30.valdi, but step 30 stores no field valdi in the workspace (its Result Log Paths store: valid).', Locked = true;
        StepFieldStartIsTxt: Label 'Skref 40 les @30.valdi, en skref 30 geymir ekkert valdi í vinnusvæðinu (Niðurstöðuskráningarslóðir þess geyma: valid).', Locked = true;
        CurrentFieldStartTxt: Label 'Step 30 reads @_current.fields.Nmae, but table Customer has no field with that name.', Locked = true;
        CurrentFieldStartIsTxt: Label 'Skref 30 les @_current.fields.Nmae, en taflan Customer hefur engan reit með því nafni.', Locked = true;

    [Test]
    procedure AskSchema_ConditionAndPresenceBoundaries()
    begin
        // [SCENARIO] Success and Error data conditions require a schema; Start and unrelated paths do not.
        CheckAskSchemaCase("Playbook Cond. Type ori"::Success, 'data', '{}', 'LLM.Prompt.Ask', 1);
        CheckAskSchemaCase("Playbook Cond. Type ori"::Error, 'data.verdict', '{}', 'LLM.Prompt.Ask', 1);
        CheckAskSchemaCase("Playbook Cond. Type ori"::Start, 'data.verdict', '{}', 'LLM.Prompt.Ask', 0);
        CheckAskSchemaCase("Playbook Cond. Type ori"::Success, 'database', '{}', 'LLM.Prompt.Ask', 0);
        CheckAskSchemaCase("Playbook Cond. Type ori"::Success, 'data.verdict', '{"responseSchema":{}}', 'LLM.Prompt.Ask', 0);
        CheckAskSchemaCase("Playbook Cond. Type ori"::Success, 'data.verdict', '{"responseSchema":"schema"}', 'LLM.Prompt.Ask', 0);
        CheckAskSchemaCase("Playbook Cond. Type ori"::Success, 'data.verdict', '{"responseSchema":"@_initial.schema"}', 'LLM.Prompt.Ask', 0);
        CheckAskSchemaCase("Playbook Cond. Type ori"::Success, 'data.verdict', '{}', 'LLM.Prompt.Complete', 0);
    end;

    [Test]
    procedure AskTrace_LiteralTrueOnly()
    begin
        CheckAskTraceCase('{"includeTrace":true}', 'LLM.Prompt.Ask', 1);
        CheckAskTraceCase('{"includeTrace":"true"}', 'LLM.Prompt.Ask', 1);
        CheckAskTraceCase('{"includeTrace":false}', 'LLM.Prompt.Ask', 0);
        CheckAskTraceCase('{"includeTrace":"false"}', 'LLM.Prompt.Ask', 0);
        CheckAskTraceCase('{}', 'LLM.Prompt.Ask', 0);
        CheckAskTraceCase('{"includeTrace":"@_initial.trace"}', 'LLM.Prompt.Ask', 0);
        CheckAskTraceCase('{"includeTrace":null}', 'LLM.Prompt.Ask', 0);
        CheckAskTraceCase('{"includeTrace":{}}', 'LLM.Prompt.Ask', 0);
        CheckAskTraceCase('{"includeTrace":true}', 'LLM.Prompt.Complete', 0);
    end;

    [Test]
    procedure AskTemplate_TranslatedMessagesAndNextSteps()
    begin
        VerifyAskTemplateLanguage(1033, 'Ask step 10 has a Success or Error condition', 'Add responseSchema', 'Ask step 10 requests a trace', 'Remove includeTrace');
        VerifyAskTemplateLanguage(1039, 'Ask-skref 10 hefur árangurs- eða villuskilyrði', 'Bættu responseSchema', 'Ask-skref 10 biður um rakningu', 'Fjarlægðu includeTrace');
    end;

    local procedure CheckAskSchemaCase(ConditionType: Enum "Playbook Cond. Type ori"; ConditionPath: Text[250]; Template: Text; TypeName: Text; Expected: Integer)
    var
        Findings: JsonArray;
    begin
        BuildBase();
        Lib.AddCondition(PlaybookCodeTok, 10, ConditionType, 20000, ConditionPath, "Playbook Cond. Operator ori"::Equals, 'pass');
        RunAskTemplateCheck(TypeName, Template, Findings);
        Assert.AreEqual(Expected, Findings.Count(), 'Schema boundary: ' + ConditionPath + ' ' + Template);
        if Expected > 0 then
            AssertWarning(Findings, 'AskDataConditionWithoutSchema', 10);
        Lib.Cleanup(PlaybookCodeTok);
    end;

    local procedure CheckAskTraceCase(Template: Text; TypeName: Text; Expected: Integer)
    var
        Findings: JsonArray;
    begin
        BuildBase();
        RunAskTemplateCheck(TypeName, Template, Findings);
        Assert.AreEqual(Expected, Findings.Count(), 'Trace boundary: ' + Template);
        if Expected > 0 then
            AssertWarning(Findings, 'AskTraceDiscarded', 10);
        Lib.Cleanup(PlaybookCodeTok);
    end;

    local procedure VerifyAskTemplateLanguage(LanguageId: Integer; SchemaMessage: Text; SchemaNext: Text; TraceMessage: Text; TraceNext: Text)
    var
        Findings: JsonArray;
        Token: JsonToken;
        Finding: JsonObject;
        PreviousLanguage: Integer;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        BuildBase();
        Lib.AddCondition(PlaybookCodeTok, 10, "Playbook Cond. Type ori"::Success, 20000, 'data.verdict', "Playbook Cond. Operator ori"::Equals, 'pass');
        Lib.SetStepDisabled(PlaybookCodeTok, 10, true);
        RunAskTemplateCheck('LLM.Prompt.Ask', '{"includeTrace":true}', Findings);
        Assert.AreEqual(2, Findings.Count(), 'Both Ask warnings');
        AssertMessageStartsWith(Findings, 'AskDataConditionWithoutSchema', SchemaMessage);
        AssertMessageStartsWith(Findings, 'AskTraceDiscarded', TraceMessage);
        foreach Token in Findings do begin
            Finding := Token.AsObject();
            Assert.AreEqual('true', TextOf(Finding, 'stepDisabled'), 'Disabled warnings never block');
            if TextOf(Finding, 'code') = 'AskTraceDiscarded' then
                Assert.IsTrue(TextOf(Finding, 'nextStep').StartsWith(TraceNext), 'Localized trace next step')
            else
                Assert.IsTrue(TextOf(Finding, 'nextStep').StartsWith(SchemaNext), 'Localized schema next step');
        end;
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure RunAskTemplateCheck(TypeName: Text; Template: Text; var Findings: JsonArray)
    var
        Step: Record "Playbook Step ori";
        Checks: Codeunit "Playbook Verify Template ori";
        TemplateJson: JsonObject;
    begin
        Step.Get(PlaybookCodeTok, 10);
        TemplateJson.ReadFrom(Template);
        Checks.CheckAskTemplate(Step, TypeName, TemplateJson, Findings);
    end;

    [Test]
    procedure TemplateNotJson_Truncated_IsAnError()
    begin
        VerifyNotJson(1033, '{"tableName":', NotJsonStartTxt);
    end;

    [Test]
    procedure TemplateNotJson_Truncated_IsAnError_Icelandic()
    begin
        VerifyNotJson(1039, '{"tableName":', NotJsonStartIsTxt);
    end;

    [Test]
    procedure TemplateNotJson_Array_IsAnError()
    begin
        // [SCENARIO] The runner reads the template into a JSON object, so an array is as bad as broken text
        VerifyNotJson(1033, '[1,2]', NotJsonStartTxt);
    end;

    [Test]
    procedure TemplateValidOrEmpty_NoFinding()
    var
        Findings: JsonArray;
    begin
        BuildBase();
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer","fieldNumbers":[1,2]}', 0, '', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 20);
        Lib.AddStep(PlaybookCodeTok, 30, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '', 0, '', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 30);
        GetFindings(Findings);
        Assert.AreEqual(0, CountFindings(Findings, 'TemplateNotJson', -1), 'A JSON object and an empty template are fine');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure StepReference_Missing_IsAnError()
    begin
        VerifyMissingReference(1033, NotFoundStartTxt);
    end;

    [Test]
    procedure StepReference_Missing_IsAnError_Icelandic()
    begin
        VerifyMissingReference(1039, NotFoundStartIsTxt);
    end;

    [Test]
    procedure StepReference_CollectAndListForms_AreChecked()
    var
        Findings: JsonArray;
    begin
        // [SCENARIO] @collect:N and @10,45 name steps too
        BuildBase();
        AddStepWithTemplate(20, '{"items":"@collect:45"}');
        AddStepWithTemplate(30, '{"dump":"@10,46"}');
        GetFindings(Findings);
        Assert.AreEqual(1, CountFindings(Findings, 'StepReferenceNotFound', 20), '@collect:45 refers to a step that does not exist');
        Assert.AreEqual(1, CountFindings(Findings, 'StepReferenceNotFound', 30), '@10,46 refers to a step that does not exist');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure StepReference_NotEarlier_IsAnError()
    begin
        VerifyLaterReference(1033, NotEarlierStartTxt);
    end;

    [Test]
    procedure StepReference_NotEarlier_IsAnError_Icelandic()
    begin
        VerifyLaterReference(1039, NotEarlierStartIsTxt);
    end;

    [Test]
    procedure StepReference_ToItself_IsAnError()
    var
        Findings: JsonArray;
    begin
        BuildBase();
        AddStepWithTemplate(20, '{"x":"@20.value"}');
        GetFindings(Findings);
        Assert.AreEqual(1, CountFindings(Findings, 'StepReferenceNotEarlier', 20), 'A step cannot read its own result');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure StepReference_ToEarlierStep_NoFinding()
    var
        Findings: JsonArray;
    begin
        BuildBase();
        Lib.SetResultLogPaths(PlaybookCodeTok, 10, 'noOfRecords>count');
        AddStepWithTemplate(20, '{"x":"@10.count","y":"Total @10.count customers","z":"@collect:10","w":"@10,10"}');
        GetFindings(Findings);
        Assert.AreEqual(0, CountFindings(Findings, 'StepReferenceNotFound', -1), 'No missing step');
        Assert.AreEqual(0, CountFindings(Findings, 'StepReferenceNotEarlier', -1), 'No later step');
        Assert.AreEqual(0, CountFindings(Findings, 'UnknownFieldReference', -1), 'Step 10 stores count');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure StepReference_ShapesThatAreNotReferences_NoFinding()
    var
        Findings: JsonArray;
    begin
        // [SCENARIO] An e-mail address, a lonely @, the reserved roots and a nested object are not step references
        BuildBase();
        AddStepWithTemplate(20, '{"to":"info@10.is","note":"mail me @ 10","a":"@_who.telegramChatId","b":"@_initial.invoiceNo","c":"@_sys.today","d":"@_run,_steps","n":{"deep":["x@99.is","@_sys.today"]}}');
        GetFindings(Findings);
        Assert.AreEqual(0, CountFindings(Findings, 'StepReferenceNotFound', -1), 'Nothing here refers to a step');
        Assert.AreEqual(0, CountFindings(Findings, 'StepReferenceNotEarlier', -1), 'Nothing here refers to a later step');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure StepReference_RepeatedReference_IsReportedOnce()
    var
        Findings: JsonArray;
    begin
        BuildBase();
        AddStepWithTemplate(20, '{"a":"@45.x","b":"@45.y","c":"see @45.z"}');
        GetFindings(Findings);
        Assert.AreEqual(1, CountFindings(Findings, 'StepReferenceNotFound', 20), 'One finding per missing step and step');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure RoleCode_Unknown_IsAnError()
    begin
        VerifyUnknownRole(1033, RoleStartTxt);
    end;

    [Test]
    procedure RoleCode_Unknown_IsAnError_Icelandic()
    begin
        VerifyUnknownRole(1039, RoleStartIsTxt);
    end;

    [Test]
    procedure RoleCode_Known_NoFinding()
    var
        RoleSubscriber: Codeunit "Role Lookup Subscriber ori";
        Findings: JsonArray;
    begin
        RoleSubscriber.SetKnownRole('HAIKU');
        BindSubscription(RoleSubscriber);
        RunRoleCheck('LLM.Prompt.Complete', '{"roleCode":"HAIKU","prompt":"x"}', Findings);
        UnbindSubscription(RoleSubscriber);
        Assert.AreEqual(0, Findings.Count(), 'A role that exists is clean');
        Assert.AreEqual(1, RoleSubscriber.GetQuestionsAsked(), 'The role was looked up once');
    end;

    [Test]
    procedure RoleCode_EmptyReferenceOrAbsent_IsNotLookedUp()
    var
        RoleSubscriber: Codeunit "Role Lookup Subscriber ori";
        Findings: JsonArray;
    begin
        // [SCENARIO] No roleCode means the default model; a reference is resolved at run time: nothing to look up
        BindSubscription(RoleSubscriber);
        RunRoleCheck('LLM.Prompt.Complete', '{"roleCode":"","prompt":"x"}', Findings);
        Assert.AreEqual(0, Findings.Count(), 'Empty roleCode');
        RunRoleCheck('LLM.Prompt.Complete', '{"roleCode":"@_initial.role","prompt":"x"}', Findings);
        Assert.AreEqual(0, Findings.Count(), 'A reference');
        RunRoleCheck('LLM.Prompt.Complete', '{"prompt":"x"}', Findings);
        Assert.AreEqual(0, Findings.Count(), 'No roleCode');
        UnbindSubscription(RoleSubscriber);
        Assert.AreEqual(0, RoleSubscriber.GetQuestionsAsked(), 'Nothing was looked up');
    end;

    [Test]
    procedure RoleCode_OnOtherMessageType_IsNotLookedUp()
    var
        RoleSubscriber: Codeunit "Role Lookup Subscriber ori";
        Findings: JsonArray;
    begin
        BindSubscription(RoleSubscriber);
        RunRoleCheck('Data.Records.Get', '{"roleCode":"HAIKU"}', Findings);
        UnbindSubscription(RoleSubscriber);
        Assert.AreEqual(0, Findings.Count(), 'Only LLM.* types name a language model');
        Assert.AreEqual(0, RoleSubscriber.GetQuestionsAsked(), 'Nothing was looked up');
    end;

    [Test]
    procedure RoleCode_LongerThanACode_IsAnError()
    var
        Findings: JsonArray;
    begin
        // [SCENARIO] A role code is a Code[20]: a longer one cannot exist, whether or not language models are installed
        RunRoleCheck('LLM.Prompt.Complete', '{"roleCode":"A-ROLE-CODE-THAT-IS-LONGER-THAN-TWENTY"}', Findings);
        Assert.AreEqual(1, CountFindings(Findings, 'LanguageModelRoleNotFound', 10), 'Too long to exist');
    end;

    [Test]
    procedure RoleCode_InsideAWriteTransaction_IsNotDeterminable()
    var
        Lookup: Codeunit "Playbook Verify Lookup ori";
        Findings: JsonArray;
        Exists: Boolean;
    begin
        // [SCENARIO] No subscriber and a transaction that has written (no Commit): Codeunit.Run with a used result is
        // refused by Business Central, so the lookup says "not determinable" and the check stays silent
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 0, '', 0);
        Assert.IsTrue(Database.IsInWriteTransaction(), 'The test has written');

        // [WHEN] The role is looked up with Exists set to true beforehand
        Exists := true;
        Assert.IsFalse(Lookup.TryGetRoleExists('HAIKU', Exists), 'Not determinable inside a write transaction');
        // [THEN] Exists is false, and the lookup did not commit
        Assert.IsFalse(Exists, 'Exists is false when the question cannot be answered');
        Assert.IsTrue(Database.IsInWriteTransaction(), 'The lookup did not commit');

        // [WHEN] The role check runs for an LLM.* type name
        RunRoleCheckInPlace('LLM.Prompt.Complete', '{"roleCode":"HAIKU","prompt":"x"}', Findings);
        // [THEN] It says nothing, the rest of Verify still works and the transaction is still open
        Assert.AreEqual(0, Findings.Count(), 'The role check says nothing');
        GetFindings(Findings);
        Assert.AreEqual(1, CountFindings(Findings, 'ActionWithoutSuccessCondition', 10), 'The rest of Verify still works');
        Assert.IsTrue(Database.IsInWriteTransaction(), 'Verify did not commit');

        // A role code longer than a code needs no read, so it is still judged inside the transaction
        RunRoleCheckInPlace('LLM.Prompt.Complete', '{"roleCode":"A-ROLE-CODE-THAT-IS-LONGER-THAN-TWENTY"}', Findings);
        Assert.AreEqual(1, CountFindings(Findings, 'LanguageModelRoleNotFound', 10), 'Too long to exist, with no read');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure CurrentField_Unknown_Warns()
    begin
        VerifyUnknownCurrentField(1033, CurrentFieldStartTxt);
    end;

    [Test]
    procedure CurrentField_Unknown_Warns_Icelandic()
    begin
        VerifyUnknownCurrentField(1039, CurrentFieldStartIsTxt);
    end;

    [Test]
    procedure CurrentField_Known_NoWarning()
    var
        Findings: JsonArray;
    begin
        BuildForEachOverCustomers('{"tableView":"WHERE(No.=CONST(@_current.fields.No_),Name=FILTER(@_current.fields.Name),Sell-to=FILTER(@_current.fields.Contact))"}');
        GetFindings(Findings);
        Assert.AreEqual(0, CountFindings(Findings, 'UnknownFieldReference', -1), 'No_, Name and Contact are fields of Customer');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure CurrentField_SourceTableUndeterminable_NoWarning()
    var
        Findings: JsonArray;
    begin
        // [SCENARIO] A table that cannot be resolved is not judged
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"No Such Table 109"}', 0, '', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 10);
        Lib.AddNoOfRecordsCondition(PlaybookCodeTok, 10);
        Lib.AddStep(PlaybookCodeTok, 30, "Playbook Step Type ori"::Check, "Message Type ori"::"Data.Records.Get", '{"tableView":"@_current.fields.Whatever"}', 10, 'result', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 30);
        GetFindings(Findings);
        Assert.AreEqual(0, CountFindings(Findings, 'UnknownFieldReference', -1), 'An unknown table cannot be judged');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure StepField_Unknown_Warns()
    var
        Findings: JsonArray;
    begin
        // [SCENARIO] @10.nope when step 10 stores only v; and when it stores nothing at all
        BuildBase();
        Lib.SetResultLogPaths(PlaybookCodeTok, 10, 'noOfRecords>v');
        AddStepWithTemplate(20, '{"a":"@10.nope"}');
        GetFindings(Findings);
        Assert.AreEqual(1, CountFindings(Findings, 'UnknownFieldReference', 20), 'Step 10 stores v, not nope');
        AssertWarning(Findings, 'UnknownFieldReference', 20);

        Lib.SetResultLogPaths(PlaybookCodeTok, 10, '');
        GetFindings(Findings);
        Assert.AreEqual(1, CountFindings(Findings, 'UnknownFieldReference', 20), 'Step 10 stores nothing');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure StepField_Known_NoWarning()
    var
        Findings: JsonArray;
    begin
        BuildBase();
        Lib.SetResultLogPaths(PlaybookCodeTok, 10, 'noOfRecords>v, result[0]>first, result.valid');
        AddStepWithTemplate(20, '{"a":"@10.v","b":"@10.first.fields.Name","c":"@10.result_valid","d":"@10.V"}');
        GetFindings(Findings);
        Assert.AreEqual(0, CountFindings(Findings, 'UnknownFieldReference', -1), 'v, first and result_valid are stored (case does not matter)');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure IterField_Unknown_Warns()
    begin
        VerifyUnknownIterField(1033, StepFieldStartTxt);
    end;

    [Test]
    procedure IterField_Unknown_Warns_Icelandic()
    begin
        VerifyUnknownIterField(1039, StepFieldStartIsTxt);
    end;

    [Test]
    procedure IterField_Known_NoWarning()
    var
        Findings: JsonArray;
    begin
        BuildForEachWithStoredField();
        AddForEachStep(40, '{"v":"@30.@_iter.valid","w":"@30.@_iter._item","x":"@30.0.valid"}');
        GetFindings(Findings);
        Assert.AreEqual(0, CountFindings(Findings, 'UnknownFieldReference', -1), 'valid and _item are stored by step 30');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure IterField_ExplicitIteration_Unknown_Warns()
    var
        Findings: JsonArray;
    begin
        BuildForEachWithStoredField();
        AddForEachStep(40, '{"x":"@30.0.valdi"}');
        GetFindings(Findings);
        Assert.AreEqual(1, CountFindings(Findings, 'UnknownFieldReference', 40), 'An explicit iteration is judged the same way');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure StepField_OfPagedOrDisabledStep_IsNotJudged()
    var
        PlaybookStep: Record "Playbook Step ori";
        Findings: JsonArray;
    begin
        // [SCENARIO] A paged step stores per page and a disabled step stores nothing: their fields are not judged
        BuildBase();
        Lib.SetResultLogPaths(PlaybookCodeTok, 10, 'noOfRecords>v');
        AddStepWithTemplate(20, '{"a":"@10.nope"}');
        PlaybookStep.Get(PlaybookCodeTok, 10);
        PlaybookStep.Paged := true;
        PlaybookStep.Modify(true);
        GetFindings(Findings);
        Assert.AreEqual(0, CountFindings(Findings, 'UnknownFieldReference', -1), 'Paged');
        PlaybookStep.Paged := false;
        PlaybookStep.Modify(true);
        Lib.SetStepDisabled(PlaybookCodeTok, 10, true);
        GetFindings(Findings);
        Assert.AreEqual(0, CountFindings(Findings, 'UnknownFieldReference', -1), 'Disabled');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure Lookup_RecordExists_FoundNotFoundAndUndeterminable()
    var
        Lookup: Codeunit "Playbook Verify Lookup ori";
        Found: Boolean;
    begin
        // [SCENARIO] The read through Data.Records.Get answers found, not found, and "not determinable" for what cannot be read
        Lib.CreatePlaybook(PlaybookCodeTok);
        Commit();
        Assert.IsTrue(Lookup.TryLookupRecord('Playbook ori', 'Code', PlaybookCodeTok, Found), 'Determinable');
        Assert.IsTrue(Found, 'The playbook exists');
        Assert.IsTrue(Lookup.TryLookupRecord('Playbook ori', 'Code', 'NO-SUCH-109', Found), 'Determinable');
        Assert.IsFalse(Found, 'No such playbook');
        Assert.IsFalse(Lookup.TryLookupRecord('No Such Table 109 ori', 'Code', 'X', Found), 'A table that does not exist is not determinable');
        Assert.IsFalse(Lookup.TryLookupRecord('Playbook ori', 'Code', 'A|B', Found), 'A value with filter characters is not determinable');
        Assert.IsFalse(Lookup.TryLookupRecord('Playbook ori', 'Code', '', Found), 'An empty value is not determinable');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure Lookup_FieldNames_AreTheJsonNames()
    var
        Lookup: Codeunit "Playbook Verify Lookup ori";
        FieldNames: Dictionary of [Text, Boolean];
        ResolvedName: Text;
    begin
        Assert.IsTrue(Lookup.TryGetFieldNames('Customer', FieldNames, ResolvedName), 'Customer resolves by name');
        Assert.AreEqual('Customer', ResolvedName, 'The AL name');
        Assert.IsTrue(FieldNames.ContainsKey('no_'), 'No. is No_');
        Assert.IsTrue(FieldNames.ContainsKey('name'), 'Name');
        Assert.IsTrue(FieldNames.ContainsKey('selltocustomerno_') or FieldNames.ContainsKey('creditlimitlcy'), 'Punctuation is dropped from a name');
        Assert.IsFalse(FieldNames.ContainsKey('nmae'), 'A typo is not a field');
        Assert.IsTrue(Lookup.TryGetFieldNames('18', FieldNames, ResolvedName), 'A table number resolves');
        Assert.AreEqual('Customer', ResolvedName, 'Table 18 is Customer');
        Assert.IsFalse(Lookup.TryGetFieldNames('No Such Table 109', FieldNames, ResolvedName), 'An unknown table is not determinable');
    end;

    [Test]
    procedure Lookup_ToJsonName_FollowsTheDataTypes()
    var
        Lookup: Codeunit "Playbook Verify Lookup ori";
    begin
        Assert.AreEqual('no_', Lookup.ToJsonName('No.'), 'No.');
        Assert.AreEqual('selltocustomerno_', Lookup.ToJsonName('Sell-to Customer No.'), 'Sell-to Customer No.');
        Assert.AreEqual('balanceduelcy', Lookup.ToJsonName('Balance Due (LCY)'), 'Balance Due (LCY)');
        Assert.AreEqual('linediscount_', Lookup.ToJsonName('Line Discount %'), 'A percent sign becomes _');
        Assert.AreEqual('a_b_c_d', Lookup.ToJsonName('A/B\C"D'), 'Slash, backslash and quote become _');
    end;

    local procedure VerifyNotJson(LanguageId: Integer; Template: Text; ExpectedStart: Text)
    var
        Findings: JsonArray;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] A template that is not a JSON object is an error: the engine would send an empty request
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        BuildBase();
        AddStepWithTemplate(20, Template);

        GetFindings(Findings);

        Assert.AreEqual(1, Findings.Count(), 'One finding');
        AssertFinding(Findings, 'TemplateNotJson', 20, ErrorTok);
        AssertMessageStartsWith(Findings, 'TemplateNotJson', ExpectedStart);
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyMissingReference(LanguageId: Integer; ExpectedStart: Text)
    var
        Findings: JsonArray;
        PreviousLanguage: Integer;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        BuildBase();
        AddStepWithTemplate(20, '{"x":"@45.value"}');

        GetFindings(Findings);

        Assert.AreEqual(1, Findings.Count(), 'One finding');
        AssertFinding(Findings, 'StepReferenceNotFound', 20, ErrorTok);
        AssertMessageStartsWith(Findings, 'StepReferenceNotFound', ExpectedStart);
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyLaterReference(LanguageId: Integer; ExpectedStart: Text)
    var
        Findings: JsonArray;
        PreviousLanguage: Integer;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        BuildBase();
        AddStepWithTemplate(20, '{"x":"@30.value"}');
        AddStepWithTemplate(30, '{}');

        GetFindings(Findings);

        Assert.AreEqual(1, Findings.Count(), 'One finding');
        AssertFinding(Findings, 'StepReferenceNotEarlier', 20, ErrorTok);
        AssertMessageStartsWith(Findings, 'StepReferenceNotEarlier', ExpectedStart);
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyUnknownRole(LanguageId: Integer; ExpectedStart: Text)
    var
        RoleSubscriber: Codeunit "Role Lookup Subscriber ori";
        Findings: JsonArray;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] A roleCode that is not a language model of the company is an error
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        RoleSubscriber.SetKnownRole('SONNET');
        BindSubscription(RoleSubscriber);

        RunRoleCheck('LLM.Prompt.Complete', '{"roleCode":"HAIKU","prompt":"x"}', Findings);

        UnbindSubscription(RoleSubscriber);
        Assert.AreEqual(1, Findings.Count(), 'One finding');
        AssertFinding(Findings, 'LanguageModelRoleNotFound', 10, ErrorTok);
        AssertMessageStartsWith(Findings, 'LanguageModelRoleNotFound', ExpectedStart);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyUnknownCurrentField(LanguageId: Integer; ExpectedStart: Text)
    var
        Findings: JsonArray;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] @_current.fields.X names a field the table the forEach reads does not have
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        BuildForEachOverCustomers('{"tableView":"WHERE(No.=CONST(@_current.fields.Nmae))"}');

        GetFindings(Findings);

        Assert.AreEqual(1, Findings.Count(), 'One finding');
        AssertFinding(Findings, 'UnknownFieldReference', 30, WarningTok);
        AssertMessageStartsWith(Findings, 'UnknownFieldReference', ExpectedStart);
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyUnknownIterField(LanguageId: Integer; ExpectedStart: Text)
    var
        Findings: JsonArray;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] @30.@_iter.valdi when step 30 stores valid: the typo this check was written for
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        BuildForEachWithStoredField();
        AddForEachStep(40, '{"v":"@30.@_iter.valdi"}');

        GetFindings(Findings);

        Assert.AreEqual(1, Findings.Count(), 'One finding');
        AssertFinding(Findings, 'UnknownFieldReference', 40, WarningTok);
        AssertMessageStartsWith(Findings, 'UnknownFieldReference', ExpectedStart);
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    /// <summary>Runs the role check of a step named 10 with the given message type name and template.</summary>
    local procedure RunRoleCheck(TypeName: Text; Template: Text; var Findings: JsonArray)
    var
        PlaybookStep: Record "Playbook Step ori";
        TemplateChecks: Codeunit "Playbook Verify Template ori";
        TemplateJson: JsonObject;
    begin
        Clear(Findings);
        BuildBase();
        PlaybookStep.Get(PlaybookCodeTok, 10);
        TemplateJson.ReadFrom(Template);
        TemplateChecks.CheckRoleCode(PlaybookStep, TypeName, TemplateJson, Findings);
        Lib.Cleanup(PlaybookCodeTok);
    end;

    /// <summary>Runs the role check on step 10 of the playbook that already exists, without creating or committing anything.</summary>
    local procedure RunRoleCheckInPlace(TypeName: Text; Template: Text; var Findings: JsonArray)
    var
        PlaybookStep: Record "Playbook Step ori";
        TemplateChecks: Codeunit "Playbook Verify Template ori";
        TemplateJson: JsonObject;
    begin
        Clear(Findings);
        PlaybookStep.Get(PlaybookCodeTok, 10);
        TemplateJson.ReadFrom(Template);
        TemplateChecks.CheckRoleCode(PlaybookStep, TypeName, TemplateJson, Findings);
    end;

    /// <summary>Step 10 reads Customer (guarded); step 30 is a forEach Check over it with the given template.</summary>
    local procedure BuildForEachOverCustomers(Step30Template: Text)
    begin
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 0, '', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 10);
        Lib.AddNoOfRecordsCondition(PlaybookCodeTok, 10);
        Lib.AddStep(PlaybookCodeTok, 30, "Playbook Step Type ori"::Check, "Message Type ori"::"Data.Records.Get", Step30Template, 10, 'result', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 30);
    end;

    /// <summary>Step 30 is a forEach Check that stores <c>valid</c> per iteration; step 40 is added by the test.</summary>
    local procedure BuildForEachWithStoredField()
    begin
        BuildForEachOverCustomers('{"tableName":"Customer"}');
        Lib.SetResultLogPaths(PlaybookCodeTok, 30, 'text>valid');
    end;

    local procedure AddForEachStep(StepNo: Integer; Template: Text)
    begin
        Lib.AddStep(PlaybookCodeTok, StepNo, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", Template, 10, 'result', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, StepNo);
    end;

    local procedure AddStepWithTemplate(StepNo: Integer; Template: Text)
    begin
        Lib.AddStep(PlaybookCodeTok, StepNo, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", Template, 0, '', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, StepNo);
    end;

    local procedure BuildBase()
    begin
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 0, '', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 10);
    end;

    local procedure GetFindings(var Findings: JsonArray)
    var
        Verify: Codeunit "Playbook Verify ori";
    begin
        Verify.GetFindings(PlaybookCodeTok, Findings);
    end;

    /// <summary>Counts the findings with a code; a StepNo of -1 counts every step.</summary>
    local procedure CountFindings(Findings: JsonArray; FindingCode: Text; StepNo: Integer): Integer
    var
        Token: JsonToken;
        Count: Integer;
    begin
        foreach Token in Findings do
            if (TextOf(Token.AsObject(), 'code') = FindingCode) and ((StepNo = -1) or (IntOf(Token.AsObject(), 'stepNo') = StepNo)) then
                Count += 1;
        exit(Count);
    end;

    local procedure AssertWarning(Findings: JsonArray; FindingCode: Text; StepNo: Integer)
    begin
        AssertFinding(Findings, FindingCode, StepNo, WarningTok);
    end;

    local procedure AssertFinding(Findings: JsonArray; FindingCode: Text; StepNo: Integer; Severity: Text)
    var
        Token: JsonToken;
    begin
        foreach Token in Findings do
            if (TextOf(Token.AsObject(), 'code') = FindingCode) and (IntOf(Token.AsObject(), 'stepNo') = StepNo) then begin
                Assert.AreEqual(Severity, TextOf(Token.AsObject(), 'severity'), FindingCode + ' severity');
                Assert.IsTrue(TextOf(Token.AsObject(), 'message') <> '', FindingCode + ' has a message');
                Assert.IsTrue(TextOf(Token.AsObject(), 'nextStep') <> '', FindingCode + ' has a nextStep');
                exit;
            end;
        Assert.Fail(StrSubstNo(RequestFormat1Tok, FindingCode, StepNo));
    end;

    local procedure AssertMessageStartsWith(Findings: JsonArray; FindingCode: Text; ExpectedStart: Text)
    var
        Token: JsonToken;
        MessageText: Text;
    begin
        foreach Token in Findings do
            if TextOf(Token.AsObject(), 'code') = FindingCode then begin
                MessageText := TextOf(Token.AsObject(), 'message');
                Assert.IsTrue(MessageText.StartsWith(ExpectedStart), 'Localized start expected: ' + ExpectedStart + ' got: ' + MessageText);
                exit;
            end;
        Assert.Fail('No finding ' + FindingCode);
    end;

    local procedure TextOf(Source: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        if Source.Get(PropertyName, Token) then
            exit(Token.AsValue().AsText());
    end;

    local procedure IntOf(Source: JsonObject; PropertyName: Text): Integer
    var
        Token: JsonToken;
    begin
        if Source.Get(PropertyName, Token) then
            exit(Token.AsValue().AsInteger());
    end;
}
