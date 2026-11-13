namespace Origo.Bifrost.Orchestrator.Test;

using Microsoft.Sales.Customer;
using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;
using System.Text;

/// <summary>
/// Issue #109: the worked examples of Help.Orchestrator.Get are built step by step and verified. Examples 1 and 2 verify
/// with no findings in 1033 and 1039; example 3, the anti-pattern, verifies with exactly the UnsafeForEachWrite warning.
/// The help carries the base64 of every template and the chapters the issue asks for.
/// </summary>
codeunit 96436 "Playbook Example Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Examples: Codeunit "Playbook Example Library ori";
        Lib: Codeunit "Playbook Test Library ori";
        CreditCodeTok: Label 'CREDIT-CTRL', Locked = true;
        ReportCodeTok: Label 'OVERDUE-REPORT', Locked = true;
        AntiPatternCodeTok: Label 'CUST-BLOCK-ALL', Locked = true;
        PostingAuditCodeTok: Label 'POSTING-AUDIT', Locked = true;
        CheckAnsweredNoTok: Label 'Check answered no.', Locked = true;
        OwnedChatIdTok: Label '135135135', Locked = true;
        HadOwnedChatSetup: Boolean;
        OriginalChatId: Text[50];
        UnsafeStartTxt: Label 'Step 40 (Data.Records.Set) writes for every item of an array that an earlier forEach Check step 30 decides on', Locked = true;
        UnsafeStartIsTxt: Label 'Skref 40 (Data.Records.Set) skrifar fyrir öll atriði fylkis sem forEach-athugunarskref 30 á undan tekur ákvörðun um', Locked = true;

    [Test]
    procedure Example1_PerRecordDecisionThenWrite_VerifiesClean()
    begin
        VerifyCreditControlClean(1033);
    end;

    [Test]
    procedure Example1_PerRecordDecisionThenWrite_VerifiesClean_Icelandic()
    begin
        VerifyCreditControlClean(1039);
    end;

    [Test]
    procedure Example2_ReadOnlyReport_VerifiesClean()
    begin
        VerifyReportClean(1033);
    end;

    [Test]
    procedure Example2_ReadOnlyReport_VerifiesClean_Icelandic()
    begin
        VerifyReportClean(1039);
    end;

    [Test]
    procedure Example3_AntiPattern_WarnsExactlyOnce()
    begin
        VerifyAntiPattern(1033, UnsafeStartTxt);
    end;

    [Test]
    procedure Example3_AntiPattern_WarnsExactlyOnce_Icelandic()
    begin
        VerifyAntiPattern(1039, UnsafeStartIsTxt);
    end;

    [Test]
    procedure Example1_WithEveryStepDisabled_StillVerifiesWithoutErrors()
    var
        Verify: Codeunit "Playbook Verify ori";
        Findings: JsonArray;
        StepNos: List of [Integer];
        StepNo: Integer;
    begin
        // [SCENARIO] The build order of the help: create every step disabled, then verify
        Examples.BuildCreditControl(CreditCodeTok, 30);
        StepNos := StepNumbers();
        foreach StepNo in StepNos do
            Lib.SetStepDisabled(CreditCodeTok, StepNo, true);

        Verify.GetFindings(CreditCodeTok, Findings);

        Assert.AreEqual(0, Verify.CountFindings(Findings, 'error'), 'No errors with every step disabled');
        Lib.Cleanup(CreditCodeTok);
    end;

    [Test]
    procedure Help_CarriesTheWorkflowTheExamplesAndTheRules()
    var
        HelpMgt: Codeunit "Help ori";
        HelpText: Text;
    begin
        // [SCENARIO] AC1, AC2 and AC5: the chapter, the examples, the anti-pattern label and the new rules are in the help
        HelpText := HelpMgt.GetOverview();

        AssertContains(HelpText, '## Building a playbook safely');
        AssertContains(HelpText, '## Worked Playbook Examples');
        AssertContains(HelpText, '### Example 1');
        AssertContains(HelpText, '### Example 2');
        AssertContains(HelpText, '### Example 3');
        AssertContains(HelpText, '**Do not build this.**');
        AssertContains(HelpText, 'Create the header and the steps with every step `Disabled = true`');
        AssertContains(HelpText, '`describe_message_type`');
        AssertContains(HelpText, '`Bifrost Language Model ori`');
        AssertContains(HelpText, 'Enable the write steps one at a time');
        AssertContains(HelpText, '"SkipIfStepFailed": 30');
        AssertContains(HelpText, '"SkipIfStepFailed": 0');
        AssertContains(HelpText, '"ExcludeFromRunStatus": true');
        AssertContains(HelpText, '**Build with every step disabled.**');
        AssertContains(HelpText, '**Verify before every run, and before every schedule.**');
        AssertContains(HelpText, '**Never write in a forEach without a per-record gate.**');
        AssertContains(HelpText, '**Check that every message type and every role code you name exists.**');
        AssertContains(HelpText, 'read "Building a playbook safely"');
        Assert.IsTrue(HelpText.IndexOf('## Building a playbook safely') < HelpText.IndexOf('## Message Types (26)'), 'The chapter comes before the message type table');
        Assert.IsTrue(HelpText.IndexOf('**I need to...**') < HelpText.IndexOf('## Building a playbook safely'), 'The chapter comes after the Quick Decision Tree');
    end;

    [Test]
    procedure Help_CarriesTheBase64OfEveryExampleTemplate()
    var
        HelpMgt: Codeunit "Help ori";
        HelpText: Text;
    begin
        // [SCENARIO] The help is copy-pasteable: the base64 it prints is the base64 of the templates this test builds
        HelpText := HelpMgt.GetOverview();

        AssertContains(HelpText, ToBase64(Examples.CreditReadTemplate()));
        AssertContains(HelpText, ToBase64(Examples.CreditDecideTemplate()));
        AssertContains(HelpText, ToBase64(Examples.CreditBlockTemplate()));
        AssertContains(HelpText, ToBase64(Examples.CreditNoticeTemplate()));
        AssertContains(HelpText, ToBase64(Examples.ReportReadTemplate()));
        AssertContains(HelpText, ToBase64(Examples.ReportNoticeTemplate()));
        AssertContains(HelpText, ToBase64(Examples.PostingAuditReadTemplate()));
        AssertContains(HelpText, ToBase64(Examples.PostingAuditAskTemplate()));
        AssertContains(HelpText, ToBase64(Examples.PostingAuditNoticeTemplate()));
        // The decoded templates are printed beside them
        AssertContains(HelpText, Examples.CreditDecideTemplate());
        AssertContains(HelpText, Examples.CreditBlockTemplate());
        AssertContains(HelpText, Examples.ReportReadTemplate());
        AssertContains(HelpText, Examples.PostingAuditReadTemplate());
        AssertContains(HelpText, Examples.PostingAuditAskTemplate());
        AssertContains(Examples.PostingAuditAskTemplate(), 'posting sales invoices');
        AssertContains(Examples.PostingAuditAskTemplate(), 'Check the posting groups, the VAT business posting group, the payment terms');
        AssertContains(Examples.PostingAuditAskTemplate(), 'the posting groups have their accounts filled');
        AssertContains(Examples.PostingAuditAskTemplate(), 'list each problem with the field name');
        AssertContains(Examples.PostingAuditAskTemplate(), '"record":{"tableName":"Customer","systemId":"@_current.id"}');
        AssertContains(HelpText, Examples.PostingAuditNoticeTemplate());
    end;

    [Test]
    procedure Example4_PostingAudit_VerifiesForTheInstalledAskType()
    begin
        VerifyPostingAudit(1033);
    end;

    [Test]
    procedure Example4_PostingAudit_VerifiesForTheInstalledAskType_Icelandic()
    begin
        VerifyPostingAudit(1039);
    end;

    [Test]
    procedure Example4_AskTemplateRaisesNoneOfTheAskWarnings()
    var
        Step: Record "Playbook Step ori";
        Checks: Codeunit "Playbook Verify Step ori";
        TemplateChecks: Codeunit "Playbook Verify Template ori";
        Verify: Codeunit "Playbook Verify ori";
        TemplateJson: JsonObject;
        Findings: JsonArray;
        Token: JsonToken;
    begin
        // [SCENARIO] #135 AC04: take, responseSchema and no includeTrace, proved even when Ask is not installed
        Verify.SetTestAskType('');
        Examples.BuildPostingAudit(PostingAuditCodeTok);
        Step.Get(PostingAuditCodeTok, 30);
        Checks.CheckAskForEach(Step, 'LLM.Prompt.Ask', Findings);
        Assert.AreEqual(0, Findings.Count(), 'take on step 10 bounds the Ask forEach');
        Assert.IsTrue(TemplateJson.ReadFrom(Step.GetRequestTemplate()), 'Step 30 template is JSON');
        TemplateChecks.CheckAskTemplate(Step, 'LLM.Prompt.Ask', TemplateJson, Findings);
        Assert.AreEqual(0, Findings.Count(), 'Schema is present and includeTrace is absent');
        Assert.IsTrue(TemplateJson.Contains('responseSchema'), 'responseSchema');
        Assert.IsFalse(TemplateJson.Contains('includeTrace'), 'includeTrace');
        Assert.IsFalse(TemplateJson.Contains('roleCode'), 'roleCode is omitted');
        Step.Get(PostingAuditCodeTok, 10);
        Assert.IsTrue(TemplateJson.ReadFrom(Step.GetRequestTemplate()), 'Step 10 template is JSON');
        Assert.IsTrue(TemplateJson.Contains('take'), 'take');

        Verify.GetFindings(PostingAuditCodeTok, Findings);
        foreach Token in Findings do
            AssertAskWarningAbsent(Token.AsObject());
        Lib.Cleanup(PostingAuditCodeTok);
        Verify.SetTestAskType('');
    end;

    [Test]
    procedure Help_CarriesThePostingAuditExample()
    var
        HelpMgt: Codeunit "Help ori";
        HelpText: Text;
    begin
        // [SCENARIO] #135 AC01, AC06 and AC07: the chapter, the why-text and the run guidance
        HelpText := HelpMgt.GetOverview();

        Assert.IsFalse(HelpText.Contains('Three complete playbooks'), 'The intro must not count the playbooks');
        AssertContains(HelpText, '### Example 4');
        AssertContains(HelpText, 'POSTING-AUDIT');
        AssertContains(HelpText, '`roleCode` is optional');
        AssertContains(HelpText, 'LanguageModelRoleNotFound');
        AssertContains(HelpText, 'cost grows with the customers read in step 10');
        AssertContains(HelpText, 'Summary Paths on a forEach holds only the last item');
        AssertContains(HelpText, '_steps.30.items');
        AssertContains(HelpText, 'external caller of `Orchestrator.Playbook.Run`');
        AssertContains(HelpText, 'Orchestrator.Playbook.Enqueue');
        AssertContains(HelpText, 'Run Now');
        Assert.IsTrue(HelpText.IndexOf('### Example 3') < HelpText.IndexOf('### Example 4'), 'Example 4 follows example 3');
        Assert.IsTrue(HelpText.IndexOf('### Example 4') < HelpText.IndexOf('### A decision that needs judgement'), 'Example 4 stays with the worked examples');
    end;

    [Test]
    procedure Example4_RunRecordsPassFailUnknownAndErrorThenAllPassNotice()
    var
        Instance: Record "Playbook Instance ori";
        Fixture: Codeunit "Posting Audit Ask Msg ori";
        Workspace: Codeunit "Playbook Workspace ori";
        MixedInstanceId: Guid;
        PreviousLanguage: Integer;
        PassInstanceId: Guid;
        Succeeded: Text;
        CheckFailed: Text;
        Errored: Text;
        FailFindings: Text;
        UnknownFindings: Text;
        PassNotice: Text;
        SawPass: Boolean;
        SawFail: Boolean;
        SawUnknown: Boolean;
        SawError: Boolean;
    begin
        // [SCENARIO] #135 AC05: one customer each of pass, fail, unknown and Error, then an all-pass notice
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        Fixture.Reset();
        DeleteOwnedCustomers();
        InsertOwnedCustomers();
        SetOwnedChatId();
        Examples.BuildPostingAudit(PostingAuditCodeTok);
        ReplaceAskStepWithFixture();

        Lib.RunPlaybook(PostingAuditCodeTok, MixedInstanceId);
        Assert.IsTrue(Workspace.GetValue('_steps.30.items.succeeded', Succeeded), 'succeeded is present');
        Assert.IsTrue(Workspace.GetValue('_steps.30.items.checkFailed', CheckFailed), 'checkFailed is present');
        Assert.IsTrue(Workspace.GetValue('_steps.30.items.errored', Errored), 'errored is present');
        ReadCustomerOutcomes(MixedInstanceId, SawPass, SawFail, SawUnknown, SawError, FailFindings, UnknownFindings);
        Instance.Get(MixedInstanceId);
        Assert.AreEqual("Playbook Inst. Status ori"::Failed, Instance.Status, 'The errored customer fails the run');

        Fixture.SetAllPass(true);
        Lib.RunPlaybook(PostingAuditCodeTok, PassInstanceId);
        PassNotice := NoticeRequest(PassInstanceId);
        Instance.Get(PassInstanceId);
        Assert.AreEqual("Playbook Inst. Status ori"::Completed, Instance.Status, 'An all-pass run completes; the excluded notice does not fail it');

        RestoreOwnedChatId();
        DeleteOwnedCustomers();
        Lib.Cleanup(PostingAuditCodeTok);
        Fixture.Reset();
        GlobalLanguage(PreviousLanguage);

        Assert.AreEqual('1', Succeeded, 'items.succeeded');
        Assert.AreEqual('2', CheckFailed, 'items.checkFailed');
        Assert.AreEqual('1', Errored, 'items.errored');
        Assert.IsTrue(SawPass and SawFail and SawUnknown and SawError, 'One customer of each answer');
        Assert.IsTrue(FailFindings.Contains('Payment Terms Code'), 'Fail findings name the field');
        Assert.IsTrue(UnknownFindings.Contains('Gen. Bus. Posting Group'), 'Unknown findings name the field');
        Assert.IsTrue(PassNotice.Contains('Posting audit finished'), 'The notice was resolved');
        Assert.IsFalse(PassNotice.Contains('@'), 'No literal @ remains in the notice');
    end;

    [Test]
    procedure Help_ListsEveryFindingCodeOfVerify()
    var
        HelpMgt: Codeunit "Help ori";
        HelpText: Text;
        FindingCode: Text;
        Codes: List of [Text];
    begin
        HelpText := HelpMgt.GetOverview();
        Codes.AddRange('MessageTypeUnavailable', 'LanguageModelRoleNotFound', 'TemplateNotJson', 'StepReferenceNotFound', 'StepReferenceNotEarlier',
            'CheckWithoutSuccessCondition', 'NextStepNotFound', 'IterateSourceInvalid', 'InvalidSkipGate', 'ScheduledWithErrors',
            'UnsafeForEachWrite', 'ActionWithoutSuccessCondition', 'ForEachSourceUnguarded', 'UnknownFieldReference');
        foreach FindingCode in Codes do
            AssertContains(HelpText, '`' + FindingCode + '`');
    end;

    local procedure VerifyPostingAudit(LanguageId: Integer)
    var
        Verify: Codeunit "Playbook Verify ori";
        Findings: JsonArray;
        Token: JsonToken;
        Finding: JsonObject;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] Example 4 verifies clean when Ask is installed, and reports only MessageTypeUnavailable when it is not
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Verify.SetTestAskType('');
        Examples.BuildPostingAudit(PostingAuditCodeTok);
        Verify.GetFindings(PostingAuditCodeTok, Findings);

        if Examples.AskTypeIsRegistered() then
            Assert.AreEqual(0, Findings.Count(), 'Example 4 has no findings: ' + FindingsText(Findings))
        else begin
            Assert.AreEqual(1, Findings.Count(), 'Exactly one finding when Ask is absent: ' + FindingsText(Findings));
            Findings.Get(0, Token);
            Finding := Token.AsObject();
            Finding.Get('code', Token);
            Assert.AreEqual('MessageTypeUnavailable', Token.AsValue().AsText(), 'code');
            Finding.Get('stepNo', Token);
            Assert.AreEqual(30, Token.AsValue().AsInteger(), 'stepNo');
        end;

        Lib.Cleanup(PostingAuditCodeTok);
        Verify.SetTestAskType('');
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure AssertAskWarningAbsent(Finding: JsonObject)
    var
        Token: JsonToken;
    begin
        Finding.Get('code', Token);
        Assert.AreNotEqual('AskForEachUnbounded', Token.AsValue().AsText(), 'No unbounded warning');
        Assert.AreNotEqual('AskDataConditionWithoutSchema', Token.AsValue().AsText(), 'No schema warning');
        Assert.AreNotEqual('AskTraceDiscarded', Token.AsValue().AsText(), 'No trace warning');
    end;

    local procedure ReplaceAskStepWithFixture()
    var
        Step: Record "Playbook Step ori";
    begin
        Step.Get(PostingAuditCodeTok, 30);
        Step."Message Type" := "Message Type ori"::"Test.Orchestrator.PostingAudit";
        Step.Modify(true);
        Step.Get(PostingAuditCodeTok, 10);
        Step.SetRequestTemplate('{"tableName":"Customer","fieldNumbers":[1,2],"tableView":"WHERE(No.=FILTER(Z135A|Z135B|Z135C|Z135D))","take":4}');
        Step.Modify(true);
    end;

    local procedure ReadCustomerOutcomes(InstanceId: Guid; var SawPass: Boolean; var SawFail: Boolean; var SawUnknown: Boolean; var SawError: Boolean; var FailFindings: Text; var UnknownFindings: Text)
    var
        StepLog: Record "Playbook Step Log ori";
        Workspace: Codeunit "Playbook Workspace ori";
        Request: Text;
        Findings: Text;
        Customers: Integer;
    begin
        StepLog.SetRange("Instance ID", InstanceId);
        StepLog.SetRange("Step No.", 30);
        if StepLog.FindSet() then
            repeat
                Request := StepLog.GetRequestSent();
                AssertPostingAuditRecordContext(Request);
                Customers += 1;
                if Request.Contains('Z135A') then begin
                    SawPass := true;
                    Assert.AreEqual("Playbook Inst. Status ori"::Completed, StepLog.Status, 'pass');
                end;
                if Request.Contains('Z135B') then begin
                    SawFail := true;
                    Assert.AreEqual("Playbook Inst. Status ori"::Cancelled, StepLog.Status, 'fail is not a run failure');
                    Assert.AreEqual(CheckAnsweredNoTok, StepLog."Error Text", 'fail says the check answered no');
                    Assert.IsTrue(Workspace.GetValue(FindingsPath(StepLog."Iteration No."), Findings), 'fail findings stored');
                    FailFindings := Findings;
                end;
                if Request.Contains('Z135C') then begin
                    SawUnknown := true;
                    Assert.AreEqual("Playbook Inst. Status ori"::Cancelled, StepLog.Status, 'unknown is not a run failure');
                    Assert.AreEqual(CheckAnsweredNoTok, StepLog."Error Text", 'unknown says the check answered no');
                    Assert.IsTrue(Workspace.GetValue(FindingsPath(StepLog."Iteration No."), Findings), 'unknown findings stored');
                    UnknownFindings := Findings;
                end;
                if Request.Contains('Z135D') then begin
                    SawError := true;
                    Assert.AreEqual("Playbook Inst. Status ori"::Failed, StepLog.Status, 'status Error is a technical failure');
                end;
            until StepLog.Next() = 0;
        Assert.AreEqual(4, Customers, 'Step 30 ran once per owned customer');
    end;

    local procedure AssertPostingAuditRecordContext(RequestText: Text)
    var
        Customer: Record Customer;
        Request: JsonObject;
        RecordContext: JsonObject;
        Token: JsonToken;
        CustomerId: Guid;
    begin
        Assert.IsTrue(Request.ReadFrom(RequestText), 'The resolved Ask request is JSON');
        Assert.IsTrue(Request.Get('record', Token), 'The Ask request includes record context');
        Assert.IsTrue(Token.IsObject(), 'Record context must be an object, not a GUID string');
        RecordContext := Token.AsObject();
        Assert.IsTrue(RecordContext.Get('tableName', Token), 'Record context identifies the table');
        Assert.AreEqual('Customer', Token.AsValue().AsText(), 'Record context is a Customer');
        Assert.IsTrue(RecordContext.Get('systemId', Token), 'Record context identifies the customer SystemId');
        Assert.IsTrue(Evaluate(CustomerId, Token.AsValue().AsText()), 'The current customer id resolves to a GUID');
        Assert.IsTrue(Customer.GetBySystemId(CustomerId), 'Record context resolves to an existing owned customer');
        AssertContains(RequestText, Customer."No.");
        AssertContains(RequestText, Customer.Name);
    end;

    local procedure FindingsPath(IterationNo: Integer): Text
    begin
        exit('30.' + Format(IterationNo) + '.findings');
    end;

    local procedure NoticeRequest(InstanceId: Guid): Text
    var
        StepLog: Record "Playbook Step Log ori";
    begin
        StepLog.SetRange("Instance ID", InstanceId);
        StepLog.SetRange("Step No.", 90);
        StepLog.FindFirst();
        exit(StepLog.GetRequestSent());
    end;

    local procedure InsertOwnedCustomers()
    begin
        InsertOwnedCustomer('Z135A', 'Posting audit pass');
        InsertOwnedCustomer('Z135B', 'Posting audit fail');
        InsertOwnedCustomer('Z135C', 'Posting audit unknown');
        InsertOwnedCustomer('Z135D', 'Posting audit error');
    end;

    local procedure InsertOwnedCustomer(No: Code[20]; Name: Text[100])
    var
        Customer: Record Customer;
    begin
        Customer.Init();
        Customer."No." := No;
        Customer.Name := Name;
        Customer.Insert(false);
    end;

    local procedure DeleteOwnedCustomers()
    begin
        DeleteOwnedCustomer('Z135A');
        DeleteOwnedCustomer('Z135B');
        DeleteOwnedCustomer('Z135C');
        DeleteOwnedCustomer('Z135D');
    end;

    local procedure DeleteOwnedCustomer(No: Code[20])
    var
        Customer: Record Customer;
    begin
        if Customer.Get(No) then
            Customer.Delete(false);
    end;

    local procedure SetOwnedChatId()
    var
        UserSetup: Record "User Setup ori";
    begin
        HadOwnedChatSetup := UserSetup.Get(UserSecurityId());
        if HadOwnedChatSetup then
            OriginalChatId := UserSetup."Telegram Chat ID ori"
        else begin
            UserSetup.Init();
            UserSetup."User Security ID" := UserSecurityId();
            UserSetup.Insert(false);
        end;
        UserSetup."Telegram Chat ID ori" := OwnedChatIdTok;
        UserSetup.Modify(false);
    end;

    local procedure RestoreOwnedChatId()
    var
        UserSetup: Record "User Setup ori";
    begin
        if not UserSetup.Get(UserSecurityId()) then
            exit;
        if HadOwnedChatSetup then begin
            UserSetup."Telegram Chat ID ori" := OriginalChatId;
            UserSetup.Modify(false);
        end else
            UserSetup.Delete(false);
    end;

    local procedure VerifyCreditControlClean(LanguageId: Integer)
    var
        Verify: Codeunit "Playbook Verify ori";
        Findings: JsonArray;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] Example 1, the credit-control shape done right, verifies with no findings
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Examples.BuildCreditControl(CreditCodeTok, 30);

        Verify.GetFindings(CreditCodeTok, Findings);

        Assert.AreEqual(0, Findings.Count(), 'Example 1 has no findings: ' + FindingsText(Findings));
        Lib.Cleanup(CreditCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyReportClean(LanguageId: Integer)
    var
        Verify: Codeunit "Playbook Verify ori";
        Findings: JsonArray;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] Example 2, the read-only report, verifies with no findings
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Examples.BuildOverdueReport(ReportCodeTok);

        Verify.GetFindings(ReportCodeTok, Findings);

        Assert.AreEqual(0, Findings.Count(), 'Example 2 has no findings: ' + FindingsText(Findings));
        Lib.Cleanup(ReportCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyAntiPattern(LanguageId: Integer; ExpectedStart: Text)
    var
        Verify: Codeunit "Playbook Verify ori";
        Findings: JsonArray;
        Token: JsonToken;
        Finding: JsonObject;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] Example 3, the ungated forEach write, produces the UnsafeForEachWrite warning and nothing else
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Examples.BuildCreditControl(AntiPatternCodeTok, 0);

        Verify.GetFindings(AntiPatternCodeTok, Findings);

        Assert.AreEqual(1, Findings.Count(), 'Exactly one finding: ' + FindingsText(Findings));
        Findings.Get(0, Token);
        Finding := Token.AsObject();
        Finding.Get('code', Token);
        Assert.AreEqual('UnsafeForEachWrite', Token.AsValue().AsText(), 'code');
        Finding.Get('severity', Token);
        Assert.AreEqual('warning', Token.AsValue().AsText(), 'severity');
        Finding.Get('stepNo', Token);
        Assert.AreEqual(40, Token.AsValue().AsInteger(), 'stepNo');
        Finding.Get('checkStepNo', Token);
        Assert.AreEqual(30, Token.AsValue().AsInteger(), 'checkStepNo');
        Finding.Get('message', Token);
        Assert.IsTrue(Token.AsValue().AsText().StartsWith(ExpectedStart), 'Localized start expected: ' + ExpectedStart + ' got: ' + Token.AsValue().AsText());
        Lib.Cleanup(AntiPatternCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure StepNumbers() StepNos: List of [Integer]
    begin
        StepNos.AddRange(10, 30, 40, 90);
    end;

    local procedure FindingsText(Findings: JsonArray): Text
    var
        Result: Text;
    begin
        Findings.WriteTo(Result);
        exit(Result);
    end;

    local procedure ToBase64(Value: Text): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
    begin
        exit(Base64Convert.ToBase64(Value));
    end;

    local procedure AssertContains(HelpText: Text; Expected: Text)
    begin
        Assert.IsTrue(HelpText.Contains(Expected), 'The help must contain: ' + Expected);
    end;
}
