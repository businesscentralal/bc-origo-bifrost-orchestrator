namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>
/// Issue #189 (core#1365 D3): a playbook step confirms from the preview up to a Max Count. The fixture type answers
/// ConfirmationRequired with a configured preview and counts how often its irreversible part ran, so every test
/// proves what executed. Under cap, equal to cap, over cap, missing Max Count, a preview without a count, a type that asks
/// for no confirmation, a forEach step, Verify and the log in 1033 and 1039.
/// </summary>
codeunit 96489 "Playbook Preview Count Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Lib: Codeunit "Playbook Test Library ori";
        Fixture: Codeunit "Preview Count Fixture Msg ori";
        PlaybookCodeTok: Label 'XPRV-189', Locked = true;
        PreviewTemplateTok: Label '{"expectedCount":"@preview"}', Locked = true;
        FixedTemplateTok: Label '{"expectedCount":3}', Locked = true;

    [Test]
    procedure Preview_UnderCap_ConfirmsWithPreviewedCount()
    var
        StepLog: Record "Playbook Step Log ori";
        InstanceId: Guid;
    begin
        // [SCENARIO] AC01 / AC04: expected 3 <= Max Count 5. The type runs once, with expectedCount 3, and the log says so.
        SetupPlaybook(PreviewTemplateTok, 5, '3');
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        GetStepLog(InstanceId, 10, 0, StepLog);
        Assert.AreEqual(StepLog.Status::Completed, StepLog.Status, 'Under cap completes');
        Assert.AreEqual(1, Fixture.Executed(), 'The irreversible part ran once');
        Assert.AreEqual(1, Fixture.Previews(), 'One preview call');
        Assert.AreEqual(3, Fixture.ConfirmedCount(), 'Confirmed with the previewed count');
        Assert.AreEqual('Preview count 3, Max Count 5: confirmed with expectedCount 3.', StepLog."Confirmation Note", 'Run log names preview and confirmed count');
        Assert.IsTrue(RequestSent(StepLog).Contains('"expectedCount":3'), 'The request that ran is logged with the confirmed count');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure Preview_EqualToCap_Confirms()
    var
        StepLog: Record "Playbook Step Log ori";
        InstanceId: Guid;
    begin
        // [SCENARIO] AC05: expected 5 = Max Count 5 is within the cap.
        SetupPlaybook(PreviewTemplateTok, 5, '5');
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        GetStepLog(InstanceId, 10, 0, StepLog);
        Assert.AreEqual(StepLog.Status::Completed, StepLog.Status, 'Equal to cap completes');
        Assert.AreEqual(1, Fixture.Executed(), 'Ran once');
        Assert.AreEqual(5, Fixture.ConfirmedCount(), 'Confirmed with 5');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure Preview_OverCap_FailsNamingCountAndCap_ExecutesNothing()
    var
        StepLog: Record "Playbook Step Log ori";
        Instance: Record "Playbook Instance ori";
        InstanceId: Guid;
        SettingBefore: Boolean;
    begin
        // [SCENARIO] AC02 / AC04: expected 6 > Max Count 5: ConfirmationRequired naming 6 and 5; nothing executed; setting untouched.
        SettingBefore := ConfirmationSetting();
        SetupPlaybook(PreviewTemplateTok, 5, '6');
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        GetStepLog(InstanceId, 10, 0, StepLog);
        Assert.AreEqual(StepLog.Status::Failed, StepLog.Status, 'Over cap fails');
        Assert.AreEqual(0, Fixture.Executed(), 'Nothing irreversible ran');
        Assert.AreEqual(1, Fixture.Previews(), 'Only the preview was called');
        Assert.AreEqual('ConfirmationRequired: The preview of step 10 counts 6, above the Max Count of 5. The step was not confirmed and nothing was executed.', StepLog."Error Text", 'Error names count and cap');
        Assert.AreEqual('Refused: The preview of step 10 counts 6, above the Max Count of 5. The step was not confirmed and nothing was executed.', StepLog."Confirmation Note", 'Run log names the refusal');
        Instance.Get(InstanceId);
        Assert.AreEqual(Instance.Status::Failed, Instance.Status, 'The run fails');
        Assert.IsTrue(Instance."Error Text".Contains('ConfirmationRequired'), 'The run error names the refusal: ' + Instance."Error Text");
        Assert.AreEqual(SettingBefore, ConfirmationSetting(), 'The setting is unchanged');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure Preview_WithoutMaxCount_RefusesBeforeAnyCall()
    var
        StepLog: Record "Playbook Step Log ori";
        InstanceId: Guid;
    begin
        // [SCENARIO] AC05: no Max Count means no cap, so nothing is sent at all.
        SetupPlaybook(PreviewTemplateTok, 0, '2');
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        GetStepLog(InstanceId, 10, 0, StepLog);
        Assert.AreEqual(StepLog.Status::Failed, StepLog.Status, 'No cap fails');
        Assert.AreEqual(0, Fixture.Previews(), 'Not even the preview was sent');
        Assert.AreEqual(0, Fixture.Executed(), 'Nothing ran');
        Assert.IsTrue(StepLog."Error Text".StartsWith('ConfirmationRequired: Step 10 sends "expectedCount": "@preview" but has no Max Count'), StepLog."Error Text");
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure Preview_ReturnsNoCount_FailsAndExecutesNothing()
    var
        StepLog: Record "Playbook Step Log ori";
        InstanceId: Guid;
    begin
        // [SCENARIO] AC05: a type whose preview carries no count, or a count that is not a whole number, cannot be confirmed.
        SetupPlaybook(PreviewTemplateTok, 5, '');
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        GetStepLog(InstanceId, 10, 0, StepLog);
        Assert.AreEqual(StepLog.Status::Failed, StepLog.Status, 'No count fails');
        Assert.AreEqual(0, Fixture.Executed(), 'Nothing ran');
        Assert.IsTrue(StepLog."Error Text".Contains('returned no whole count'), StepLog."Error Text");
        Lib.Cleanup(PlaybookCodeTok);

        SetupPlaybook(PreviewTemplateTok, 5, '"TEMPLATE|BATCH"');
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        GetStepLog(InstanceId, 10, 0, StepLog);
        Assert.AreEqual(StepLog.Status::Failed, StepLog.Status, 'A text instead of a count fails');
        Assert.AreEqual(0, Fixture.Executed(), 'Nothing ran for a text');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure Preview_StringCountWithinCap_Confirms()
    var
        StepLog: Record "Playbook Step Log ori";
        InstanceId: Guid;
    begin
        // [SCENARIO] Foundation answers expected as text ("1"); a whole number in text is a count.
        SetupPlaybook(PreviewTemplateTok, 2, '"1"');
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        GetStepLog(InstanceId, 10, 0, StepLog);
        Assert.AreEqual(StepLog.Status::Completed, StepLog.Status, 'Text count within cap completes');
        Assert.AreEqual(1, Fixture.ConfirmedCount(), 'Confirmed with 1');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure Preview_TypeAsksForNoConfirmation_RunsOnce()
    var
        StepLog: Record "Playbook Step Log ori";
        InstanceId: Guid;
    begin
        // [SCENARIO] A type that asks for no confirmation ran on the first call; the runner never repeats it.
        SetupPlaybook(PreviewTemplateTok, 5, '3');
        Fixture.Configure('3', true);
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        GetStepLog(InstanceId, 10, 0, StepLog);
        Assert.AreEqual(StepLog.Status::Completed, StepLog.Status, 'Completes');
        Assert.AreEqual(1, Fixture.Executed(), 'Ran exactly once');
        Assert.AreEqual(0, Fixture.Previews(), 'No preview answer');
        Assert.IsTrue(StepLog."Confirmation Note".Contains('ran once'), StepLog."Confirmation Note");
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure Preview_FixedExpectedCount_IsUnchanged()
    var
        StepLog: Record "Playbook Step Log ori";
        InstanceId: Guid;
    begin
        // [SCENARIO] A step with a fixed expectedCount and no Max Count behaves as before: no preview call, no note.
        SetupPlaybook(FixedTemplateTok, 0, '3');
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        GetStepLog(InstanceId, 10, 0, StepLog);
        Assert.AreEqual(StepLog.Status::Completed, StepLog.Status, 'Fixed count completes');
        Assert.AreEqual(0, Fixture.Previews(), 'No preview call');
        Assert.AreEqual(1, Fixture.Executed(), 'Ran once');
        Assert.AreEqual('', StepLog."Confirmation Note", 'No note for an ordinary step');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure Preview_ForEach_CapAppliesToEveryItem()
    var
        StepLog: Record "Playbook Step Log ori";
        InstanceId: Guid;
        Items: Integer;
    begin
        // [SCENARIO] AC01 / AC04: each forEach item previews and confirms on its own and logs its own note.
        Lib.CreatePlaybook(PlaybookCodeTok);
        Fixture.Configure('3', false);
        Lib.AddLayoutSourceStep(PlaybookCodeTok, 10);
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Action, "Message Type ori"::"Test.Orchestrator.PreviewCount", PreviewTemplateTok, 10, 'layouts', 0);
        SetMaxCount(20, 4);
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        StepLog.SetRange("Instance ID", InstanceId);
        StepLog.SetRange("Step No.", 20);
        Items := StepLog.Count();
        Assert.IsTrue(Items > 0, 'The source lists layouts');
        Assert.AreEqual(Items, Fixture.Executed(), 'One confirmed execution per item');
        Assert.AreEqual(Items, Fixture.Previews(), 'One preview per item');
        StepLog.SetFilter("Confirmation Note", '<>%1', '');
        Assert.AreEqual(Items, StepLog.Count(), 'Every item logs its note');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure Verify_PreviewWithoutMaxCount_AndMaxCountWithoutPreview_AreErrors()
    var
        Findings: JsonArray;
    begin
        // [SCENARIO] AC03: both mismatches are errors; the matching pair and a fixed count are silent.
        SetupPlaybook(PreviewTemplateTok, 0, '3');
        GetFindings(Findings);
        Assert.AreEqual(1, CountCode(Findings, 'PreviewWithoutMaxCount'), '@preview without Max Count');
        Assert.AreEqual('error', GetField(Findings, 'PreviewWithoutMaxCount', 'severity'), 'Error severity');
        Assert.AreEqual(0, CountCode(Findings, 'MaxCountWithoutPreview'), 'Not the other mismatch');

        SetMaxCount(10, 5);
        Clear(Findings);
        GetFindings(Findings);
        Assert.AreEqual(0, CountCode(Findings, 'PreviewWithoutMaxCount'), 'Max Count set is silent');
        Assert.AreEqual(0, CountCode(Findings, 'MaxCountWithoutPreview'), 'The pair is silent');
        Assert.AreEqual(0, CountCode(Findings, 'UnresolvableReference') + CountCode(Findings, 'StepReferenceNotFound'), '@preview is not a workspace reference');

        SetStepTemplate(10, FixedTemplateTok);
        SetMaxCount(10, 5);
        Clear(Findings);
        GetFindings(Findings);
        Assert.AreEqual(1, CountCode(Findings, 'MaxCountWithoutPreview'), 'Max Count without @preview');
        Assert.AreEqual('error', GetField(Findings, 'MaxCountWithoutPreview', 'severity'), 'Error severity');

        SetStepTemplate(10, FixedTemplateTok);
        Clear(Findings);
        GetFindings(Findings);
        Assert.AreEqual(0, CountCode(Findings, 'MaxCountWithoutPreview') + CountCode(Findings, 'PreviewWithoutMaxCount'), 'A fixed count without a cap is silent');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure Verify_PreviewWithoutMaxCount_BlocksTheRun()
    var
        Verify: Codeunit "Playbook Verify ori";
    begin
        // [SCENARIO] AC03: an error finding refuses the run (Verify rules of #182).
        SetupPlaybook(PreviewTemplateTok, 0, '3');
        asserterror Verify.AssertSafeToStart(PlaybookCodeTok, false);
        Assert.ExpectedError('PreviewWithoutMaxCount');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    [Test]
    procedure Texts_AreTranslated_1033And1039()
    begin
        VerifyLanguage(1033, 'but has no Max Count', 'Max Count', 'Refused: The preview of step 10 counts 6');
        VerifyLanguage(1039, 'en hefur engan hámarksfjölda', 'hámarksfjölda', 'Hafnað: Forskoðun skrefs 10 telur 6');
    end;

    local procedure VerifyLanguage(LanguageId: Integer; VerifyFragment: Text; NextFragment: Text; NoteStart: Text)
    var
        StepLog: Record "Playbook Step Log ori";
        Findings: JsonArray;
        InstanceId: Guid;
        PreviousLanguage: Integer;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        SetupPlaybook(PreviewTemplateTok, 0, '3');
        GetFindings(Findings);
        Assert.IsTrue(GetField(Findings, 'PreviewWithoutMaxCount', 'message').Contains(VerifyFragment), 'Localized finding');
        Assert.IsTrue(GetField(Findings, 'PreviewWithoutMaxCount', 'nextStep').Contains(NextFragment), 'Localized next step');
        SetupPlaybook(PreviewTemplateTok, 5, '6');
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        GetStepLog(InstanceId, 10, 0, StepLog);
        Assert.IsTrue(StepLog."Confirmation Note".StartsWith(NoteStart), 'Localized run log note: ' + StepLog."Confirmation Note");
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure SetupPlaybook(Template: Text; MaxCount: Integer; Preview: Text)
    begin
        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Fixture.Configure(Preview, false);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Test.Orchestrator.PreviewCount", Template, 0, '', 0);
        if MaxCount > 0 then
            SetMaxCount(10, MaxCount);
    end;

    local procedure SetMaxCount(StepNo: Integer; MaxCount: Integer)
    var
        Step: Record "Playbook Step ori";
    begin
        Step.Get(PlaybookCodeTok, StepNo);
        Step."Max Count" := MaxCount;
        Step.Modify(true);
    end;

    local procedure SetStepTemplate(StepNo: Integer; Template: Text)
    var
        Step: Record "Playbook Step ori";
    begin
        Step.Get(PlaybookCodeTok, StepNo);
        Step.SetRequestTemplate(Template);
        Step."Max Count" := 0;
        Step.Modify(true);
    end;

    local procedure GetStepLog(InstanceId: Guid; StepNo: Integer; IterationNo: Integer; var StepLog: Record "Playbook Step Log ori")
    begin
        StepLog.Get(InstanceId, StepNo, IterationNo);
    end;

    local procedure RequestSent(StepLog: Record "Playbook Step Log ori"): Text
    begin
        exit(StepLog.GetRequestSent());
    end;

    local procedure GetFindings(var Findings: JsonArray)
    var
        Verify: Codeunit "Playbook Verify ori";
    begin
        Verify.GetFindings(PlaybookCodeTok, Findings);
    end;

    local procedure ConfirmationSetting(): Boolean
    var
        SetupRef: RecordRef;
        RequiredField: FieldRef;
    begin
        SetupRef.Open(Database::"Setup ori");
        if not SetupRef.FindFirst() then
            exit(true);
        RequiredField := SetupRef.Field(36);
        exit(RequiredField.Value());
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
