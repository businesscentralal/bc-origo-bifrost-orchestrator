namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>
/// Issue #182: Playbook Verify reports the run-time refusals before the first run (irreversible step without
/// expectedCount, request keys the type does not declare, list positions written name.0) and the step log names every
/// refusal. Name-based seams only: the Telegram type is verified, never dispatched; the run uses the test fixtures.
/// </summary>
codeunit 96486 "Playbook Runtime Refusal Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Lib: Codeunit "Playbook Test Library ori";
        PlaybookCodeTok: Label 'XVER-182', Locked = true;
        TelegramNoCountTok: Label '{"message":"alert"}', Locked = true;
        TelegramCountTok: Label '{"message":"alert","expectedCount":1}', Locked = true;
        TelegramUnknownKeyTok: Label '{"message":"alert","expectedCount":1,"chatId":"42"}', Locked = true;
        UnreadableTemplateTok: Label '{"prompt":"Read the file.","file":{"data":"not-base64!!","mimeType":"application/pdf","fileName":"broken.pdf"}}', Locked = true;

    [Test]
    procedure Irreversible_WithoutExpectedCountWarns_WithItOrSettingOffDoesNot()
    var
        Findings: JsonArray;
    begin
        // [SCENARIO] AC01: an irreversible type without expectedCount warns while the confirmation setting is on.
        SetupPlaybook(TelegramNoCountTok);
        GetFindings(Findings);
        Assert.AreEqual(1, CountCode(Findings, 'IrreversibleWithoutConfirmation'), 'No expectedCount warns');
        Assert.AreEqual('warning', GetField(Findings, 'IrreversibleWithoutConfirmation', 'severity'), 'Warning severity');

        SetTemplate(TelegramCountTok);
        Clear(Findings);
        GetFindings(Findings);
        Assert.AreEqual(0, CountCode(Findings, 'IrreversibleWithoutConfirmation'), 'expectedCount present is silent');

        SetTemplate(TelegramNoCountTok);
        WithConfirmationSetting(false, Findings);
        Assert.AreEqual(0, CountCode(Findings, 'IrreversibleWithoutConfirmation'), 'Setting off is silent');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure Irreversible_MessageIsTranslated()
    begin
        VerifyIrreversibleLanguage(1033, 'Step 10 calls Orchestrator.Telegram.Message, which is irreversible', 'Add expectedCount');
        VerifyIrreversibleLanguage(1039, 'Skref 10 kallar á Orchestrator.Telegram.Message, sem er óafturkræft', 'Bættu expectedCount');
    end;

    [Test]
    procedure UnknownKey_NamesKeyAndDeclaredParameters_ReadTypeWarnsToo()
    var
        Findings: JsonArray;
    begin
        // [SCENARIO] AC02: a key a write type does not declare warns and names the declared parameters; a read type warns too (#217).
        SetupPlaybook(TelegramUnknownKeyTok);
        GetFindings(Findings);
        Assert.AreEqual(1, CountCode(Findings, 'UnknownRequestKey'), 'chatId is not declared');
        Assert.IsTrue(GetField(Findings, 'UnknownRequestKey', 'message').Contains('chatId'), 'The key is named');
        Assert.IsTrue(GetField(Findings, 'UnknownRequestKey', 'nextStep').Contains('message'), 'The declared parameters are named');

        SetTemplate(TelegramCountTok);
        Clear(Findings);
        GetFindings(Findings);
        Assert.AreEqual(0, CountCode(Findings, 'UnknownRequestKey'), 'Declared keys are silent');

        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer","madeUpKey":1}', 0, '', 0);
        Clear(Findings);
        GetFindings(Findings);
        Assert.AreEqual(1, CountCode(Findings, 'UnknownRequestKey'), 'A read type warns on an unknown key (#217)');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure Reference_ListPositionAsSegmentWarns_BracketAndIterationDoNot()
    var
        Findings: JsonArray;
    begin
        // [SCENARIO] AC03: @10.result.0.id never matches; @10.result[0].id and the iteration form @30.0.x do.
        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 0, '', 0);
        Lib.SetResultLogPaths(PlaybookCodeTok, 10, 'result');
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer","tableView":"@10.result.0.id"}', 0, '', 0);
        GetFindings(Findings);
        Assert.AreEqual(1, CountCode(Findings, 'UnresolvableReference'), 'result.0.id warns');
        Assert.IsTrue(GetField(Findings, 'UnresolvableReference', 'nextStep').Contains('result[0].id'), 'The fix is named');

        SetStepTemplate(20, '{"tableName":"Customer","tableView":"@10.result[0].id"}');
        Clear(Findings);
        GetFindings(Findings);
        Assert.AreEqual(0, CountCode(Findings, 'UnresolvableReference'), 'Bracket form is silent');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure Reference_Warning_IsTranslated()
    begin
        VerifyReferenceLanguage(1033, 'but a list position is written name[0]');
        VerifyReferenceLanguage(1039, 'en staða í lista er skrifuð nafn[0]');
    end;

    [Test]
    procedure Run_UnresolvedReferenceFailsStepWithoutSending()
    var
        StepLog: Record "Playbook Step Log ori";
        InstanceId: Guid;
    begin
        // [SCENARIO] AC03 runner: an unresolved @ reference fails the step with a clear error; nothing is sent literally.
        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Test.Orchestrator.FileSource", '{"source":"pdf"}', 0, '', 0);
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Action, "Message Type ori"::"Test.Orchestrator.FileSource", '{"source":"@10.result.0.id"}', 0, '', 0);
        Lib.SetNextSteps(PlaybookCodeTok, 10, 20, 0);
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        StepLog.Get(InstanceId, 20, 0);
        Assert.AreEqual(StepLog.Status::Failed, StepLog.Status, 'Unresolved reference fails the step');
        Assert.IsTrue(StepLog."Error Text".Contains('@10.result.0.id'), 'The reference is named: ' + StepLog."Error Text");
        Assert.AreEqual('', StepLog.GetResponseReceived(), 'Nothing was dispatched');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure StepLog_RefusalCodeAndTextOnAnActionStep()
    var
        StepLog: Record "Playbook Step Log ori";
        InstanceId: Guid;
    begin
        // [SCENARIO] AC04: a refusal fails an action step whose Success condition is status = Success; Error Text holds code: error.
        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Test.Orchestrator.FileReader", UnreadableTemplateTok, 0, '', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 10);
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        StepLog.Get(InstanceId, 10, 0);
        Assert.AreEqual(StepLog.Status::Failed, StepLog.Status, 'The refused step fails');
        Assert.AreEqual('PreconditionFailed: The file could not be read.', StepLog."Error Text", 'code: error is logged');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    local procedure VerifyIrreversibleLanguage(LanguageId: Integer; MessageStart: Text; NextStart: Text)
    var
        Findings: JsonArray;
        PreviousLanguage: Integer;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        SetupPlaybook(TelegramNoCountTok);
        GetFindings(Findings);
        Assert.IsTrue(GetField(Findings, 'IrreversibleWithoutConfirmation', 'message').StartsWith(MessageStart), 'Localized message');
        Assert.IsTrue(GetField(Findings, 'IrreversibleWithoutConfirmation', 'nextStep').StartsWith(NextStart), 'Localized next step');
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyReferenceLanguage(LanguageId: Integer; Fragment: Text)
    var
        Findings: JsonArray;
        PreviousLanguage: Integer;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer"}', 0, '', 0);
        Lib.SetResultLogPaths(PlaybookCodeTok, 10, 'result');
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer","tableView":"@10.result.0.id"}', 0, '', 0);
        GetFindings(Findings);
        Assert.IsTrue(GetField(Findings, 'UnresolvableReference', 'message').Contains(Fragment), 'Localized message');
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure SetupPlaybook(Template: Text)
    begin
        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Orchestrator.Telegram.Message", Template, 0, '', 0);
    end;

    local procedure SetTemplate(Template: Text)
    begin
        SetStepTemplate(10, Template);
    end;

    local procedure SetStepTemplate(StepNo: Integer; Template: Text)
    var
        Step: Record "Playbook Step ori";
        MessageType: Enum "Message Type ori";
    begin
        Step.Get(PlaybookCodeTok, StepNo);
        MessageType := Step."Message Type";
        Step.Delete();
        Lib.AddStep(PlaybookCodeTok, StepNo, "Playbook Step Type ori"::Action, MessageType, Template, 0, '', 0);
    end;

    local procedure GetFindings(var Findings: JsonArray)
    var
        Verify: Codeunit "Playbook Verify ori";
    begin
        Verify.GetFindings(PlaybookCodeTok, Findings);
    end;

    local procedure WithConfirmationSetting(Value: Boolean; var Findings: JsonArray)
    var
        SetupRef: RecordRef;
        RequiredField: FieldRef;
        Previous: Boolean;
    begin
        SetupRef.Open(Database::"Setup ori");
        if not SetupRef.FindFirst() then begin
            SetupRef.Init();
            SetupRef.Insert();
        end;
        RequiredField := SetupRef.Field(36);
        Previous := RequiredField.Value();
        RequiredField.Value := Value;
        SetupRef.Modify();
        Clear(Findings);
        GetFindings(Findings);
        RequiredField.Value := Previous;
        SetupRef.Modify();
    end;

    local procedure CountCode(Findings: JsonArray; FindingCode: Text): Integer
    var
        Token: JsonToken;
        CodeToken: JsonToken;
        Total: Integer;
    begin
        foreach Token in Findings do
            if Token.AsObject().Get('code', CodeToken) then
                if CodeToken.AsValue().AsText() = FindingCode then
                    Total += 1;
        exit(Total);
    end;

    local procedure GetField(Findings: JsonArray; FindingCode: Text; FieldName: Text): Text
    var
        Token: JsonToken;
        CodeToken: JsonToken;
        FieldToken: JsonToken;
    begin
        foreach Token in Findings do
            if Token.AsObject().Get('code', CodeToken) then
                if CodeToken.AsValue().AsText() = FindingCode then begin
                    Token.AsObject().Get(FieldName, FieldToken);
                    exit(FieldToken.AsValue().AsText());
                end;
        exit('');
    end;
}
