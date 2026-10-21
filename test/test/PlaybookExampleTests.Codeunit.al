namespace Origo.Bifrost.Orchestrator.Test;

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
        Assert.IsTrue(HelpText.IndexOf('## Building a playbook safely') < HelpText.IndexOf('## Message Types (21)'), 'The chapter comes before the message type table');
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
        // The decoded templates are printed beside them
        AssertContains(HelpText, Examples.CreditDecideTemplate());
        AssertContains(HelpText, Examples.CreditBlockTemplate());
        AssertContains(HelpText, Examples.ReportReadTemplate());
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
