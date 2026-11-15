namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>
/// Issue #187: 28.0.4 release items. Verify accepts the envelope keys (subject, strict) in a step template, a Failed
/// instance names its first failed step and that step's error, and the forEach skip text is translated. Unit-level,
/// no live calls: the Telegram type is verified, never dispatched; the runs use Help and ReportLayout fixtures.
/// </summary>
codeunit 96487 "Playbook Release Items Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Lib: Codeunit "Playbook Test Library ori";
        PlaybookCodeTok: Label 'REL-187', Locked = true;
        SubjectAndUnknownTok: Label '{"subject":"BIFT-187","message":"alert","expectedCount":1,"madeUpKey":1}', Locked = true;
        SubjectAndStrictTok: Label '{"subject":"BIFT-187","strict":true,"message":"alert","expectedCount":1}', Locked = true;
        StepFailedEnTok: Label 'Step %1 failed: ', Locked = true;
        StepFailedIsTok: Label 'Skref %1 mistókst: ', Locked = true;
        SkippedEnTxt: Label 'Skipped: prior step failed for this item.', Locked = true;
        SkippedIsTxt: Label 'Sleppt: fyrra skref mistókst fyrir þennan hlut.', Locked = true;

    // ---- AC01: Verify and envelope keys ----------------------------------------------------

    /// <summary>A template with subject and an unknown data key reports only the data key.</summary>
    [Test]
    procedure Verify_SubjectIsAccepted_UnknownDataKeyIsReported()
    var
        Findings: JsonArray;
    begin
        // [SCENARIO] AC01: subject is an envelope key; madeUpKey is neither a parameter nor an envelope key.
        SetupTelegramStep(SubjectAndUnknownTok);
        GetFindings(Findings);
        Assert.AreEqual(1, CountCode(Findings, 'UnknownRequestKey'), 'Only the data key is reported');
        Assert.IsTrue(GetField(Findings, 'UnknownRequestKey', 'message').Contains('madeUpKey'), 'The data key is named');
        Assert.IsFalse(GetField(Findings, 'UnknownRequestKey', 'message').Contains('subject'), 'subject is not reported');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    /// <summary>subject and strict together with declared keys give no UnknownRequestKey, in 1033 and 1039.</summary>
    [Test]
    procedure Verify_SubjectAndStrict_NoFinding_1033And1039()
    begin
        VerifyEnvelopeKeysSilent(1033);
        VerifyEnvelopeKeysSilent(1039);
    end;

    // ---- AC02: instance Error Text ---------------------------------------------------------

    /// <summary>A Failed instance names the failed step and its error, in English.</summary>
    [Test]
    procedure FailedInstance_ErrorTextNamesStep_1033()
    begin
        VerifyInstanceErrorText(1033, StepFailedEnTok);
    end;

    /// <summary>A Failed instance names the failed step and its error, in Icelandic.</summary>
    [Test]
    procedure FailedInstance_ErrorTextNamesStep_1039()
    begin
        VerifyInstanceErrorText(1039, StepFailedIsTok);
    end;

    /// <summary>A forEach step with failed items: the instance names that step and its first failed iteration's error.</summary>
    [Test]
    procedure FailedInstance_ForEach_NamesFirstFailedIteration()
    var
        Instance: Record "Playbook Instance ori";
        StepLog: Record "Playbook Step Log ori";
        InstanceId: Guid;
    begin
        // [SCENARIO] AC02 edge: step 10 succeeds, every item of step 30 fails its condition.
        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddLayoutSourceStep(PlaybookCodeTok, 10);
        Lib.AddStep(PlaybookCodeTok, 30, "Playbook Step Type ori"::Action, "Message Type ori"::"Help.Implementation.Get", HelpRequest(), 10, 'layouts', 0);
        Lib.AddSuccessCondition(PlaybookCodeTok, 30, 'isReady', 'true');
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);

        StepLog.SetRange("Instance ID", InstanceId);
        StepLog.SetRange("Step No.", 30);
        StepLog.SetRange(Status, StepLog.Status::Failed);
        Assert.IsTrue(StepLog.FindFirst(), 'A failed iteration is expected');
        Instance.Get(InstanceId);
        Assert.AreEqual(Instance.Status::Failed, Instance.Status, 'The instance is Failed');
        Assert.AreEqual(StrSubstNo(StepFailedEnTok, 30) + StepLog."Error Text", Instance."Error Text", 'First failed iteration is named');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    /// <summary>A Completed instance keeps an empty Error Text.</summary>
    [Test]
    procedure CompletedInstance_ErrorTextStaysEmpty()
    var
        Instance: Record "Playbook Instance ori";
        InstanceId: Guid;
    begin
        // [SCENARIO] AC02 negative: nothing failed, nothing is written.
        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Help.Implementation.Get", HelpRequest(), 0, '', 0);
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        Instance.Get(InstanceId);
        Assert.AreEqual(Instance.Status::Completed, Instance.Status, 'The instance is Completed');
        Assert.AreEqual('', Instance."Error Text", 'No error text on a Completed instance');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    // ---- AC03: translated skip text --------------------------------------------------------

    /// <summary>The per-item skip text is English in 1033.</summary>
    [Test]
    procedure SkipText_1033()
    begin
        VerifySkipText(1033, SkippedEnTxt);
    end;

    /// <summary>The per-item skip text is Icelandic in 1039.</summary>
    [Test]
    procedure SkipText_IsTranslated_1039()
    begin
        VerifySkipText(1039, SkippedIsTxt);
    end;

    local procedure VerifyEnvelopeKeysSilent(LanguageId: Integer)
    var
        Findings: JsonArray;
        PreviousLanguage: Integer;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        SetupTelegramStep(SubjectAndStrictTok);
        GetFindings(Findings);
        Assert.AreEqual(0, CountCode(Findings, 'UnknownRequestKey'), 'subject and strict are envelope keys');
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyInstanceErrorText(LanguageId: Integer; PrefixFormat: Text)
    var
        Instance: Record "Playbook Instance ori";
        StepLog: Record "Playbook Step Log ori";
        InstanceId: Guid;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] AC02: step 10 passes, step 20's Success condition does not hold; the instance names step 20.
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Help.Implementation.Get", HelpRequest(), 0, '', 0);
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Action, "Message Type ori"::"Help.Implementation.Get", HelpRequest(), 0, '', 0);
        Lib.AddSuccessCondition(PlaybookCodeTok, 20, 'isReady', 'true');
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);

        StepLog.Get(InstanceId, 20, 0);
        Assert.AreEqual(StepLog.Status::Failed, StepLog.Status, 'Step 20 is Failed');
        Assert.AreNotEqual('', StepLog."Error Text", 'Step 20 has an error text');
        Instance.Get(InstanceId);
        Assert.AreEqual(Instance.Status::Failed, Instance.Status, 'The instance is Failed');
        Assert.AreEqual(StrSubstNo(PrefixFormat, 20) + StepLog."Error Text", Instance."Error Text", 'Instance Error Text');
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifySkipText(LanguageId: Integer; ExpectedText: Text)
    var
        StepLog: Record "Playbook Step Log ori";
        InstanceId: Guid;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] AC03: every item of step 30 fails, so step 40 (Skip If Step Failed 30) skips each item.
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddLayoutSourceStep(PlaybookCodeTok, 10);
        Lib.AddStep(PlaybookCodeTok, 30, "Playbook Step Type ori"::Action, "Message Type ori"::"Help.Implementation.Get", HelpRequest(), 10, 'layouts', 0);
        Lib.AddSuccessCondition(PlaybookCodeTok, 30, 'isReady', 'true');
        Lib.AddStep(PlaybookCodeTok, 40, "Playbook Step Type ori"::Action, "Message Type ori"::"Help.Implementation.Get", HelpRequest(), 10, 'layouts', 30);
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);

        StepLog.SetRange("Instance ID", InstanceId);
        StepLog.SetRange("Step No.", 40);
        Assert.IsTrue(StepLog.FindSet(), 'Step 40 logs its skipped items');
        repeat
            Assert.AreEqual(StepLog.Status::Cancelled, StepLog.Status, 'A skipped item is Cancelled');
            Assert.AreEqual(ExpectedText, StepLog."Error Text", 'Skip text in the run language');
        until StepLog.Next() = 0;
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure SetupTelegramStep(Template: Text)
    begin
        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Orchestrator.Telegram.Message", Template, 0, '', 0);
    end;

    local procedure GetFindings(var Findings: JsonArray)
    var
        Verify: Codeunit "Playbook Verify ori";
    begin
        Verify.GetFindings(PlaybookCodeTok, Findings);
    end;

    local procedure HelpRequest(): Text
    begin
        exit('{"messageTypes":["Orchestrator.Playbook.Schedule"],"chapters":["parameters"]}');
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
