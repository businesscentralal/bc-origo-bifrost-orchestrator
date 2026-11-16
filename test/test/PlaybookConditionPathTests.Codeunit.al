namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>
/// Issue #194: Verify checks Success condition paths against the declared response of the called message type.
/// Orchestrator.Playbook.Verify is the called type: its response declares status, valid and findings (with children).
/// No live calls: the playbook is verified, never run.
/// </summary>
codeunit 96490 "Playbook Condition Path Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Lib: Codeunit "Playbook Test Library ori";
        PlaybookCodeTok: Label 'CND-194', Locked = true;
        FindingCodeTok: Label 'UnknownFieldReference', Locked = true;

    /// <summary>A path that the response declares gives no finding.</summary>
    [Test]
    procedure Scenario_AC02_DeclaredPath_NoFinding()
    var
        Findings: JsonArray;
    begin
        // Story #194 | Time: independent of Today and WorkDate | Risk: None
        // [SCENARIO] AC: valid, status and findings[0].code are declared in the response.
        SetupStep();
        Lib.AddSuccessCondition(PlaybookCodeTok, 10, 'status', 'Success');
        AddVerifyStep(20);
        Lib.AddSuccessCondition(PlaybookCodeTok, 20, 'findings[0].code', 'X');
        AddVerifyStep(30);
        Lib.AddSuccessCondition(PlaybookCodeTok, 30, 'valid', 'true');
        GetFindings(Findings);
        Assert.AreEqual(0, CountCode(Findings), 'Declared paths are not reported');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    /// <summary>A path nested one level too deep (result.valid) is reported once, naming the path and the declared fields.</summary>
    [Test]
    procedure Scenario_AC01_UndeclaredPath_IsWarned()
    var
        Findings: JsonArray;
    begin
        // Story #194 | Time: independent of Today and WorkDate | Risk: None
        // [SCENARIO] AC: the path result.valid is not in the response (the issue's Kennitala shape, mirrored).
        SetupStep();
        Lib.AddSuccessCondition(PlaybookCodeTok, 10, 'result.valid', 'true');
        GetFindings(Findings);
        Assert.AreEqual(1, CountCode(Findings), 'One finding per path');
        Assert.AreEqual('warning', GetField(Findings, 'severity'), 'It is a warning');
        Assert.IsTrue(GetField(Findings, 'message').Contains('result.valid'), 'The path is named');
        Assert.IsTrue(GetField(Findings, 'message').Contains('playbookCode'), 'The declared fields are listed');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    /// <summary>An unknown child under a field that lists children is reported once.</summary>
    [Test]
    procedure Scenario_AC01_UnknownChild_IsWarned()
    var
        Findings: JsonArray;
    begin
        // Story #194, AC01 | Time: independent of Today and WorkDate | Risk: None
        // [SCENARIO] edge: findings[0].bogus is not a child of findings.
        SetupStep();
        Lib.AddSuccessCondition(PlaybookCodeTok, 10, 'findings[0].bogus', 'a');
        GetFindings(Findings);
        Assert.AreEqual(1, CountCode(Findings), 'Reported once');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    /// <summary>The finding text is in the session language, in 1033 and 1039.</summary>
    [Test]
    procedure Scenario_AC03_FindingText_1033And1039()
    var
        Findings: JsonArray;
        PreviousLanguage: Integer;
    begin
        // Story #194, AC03 | Time: independent of Today and WorkDate | Risk: None
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        SetupStep();
        Lib.AddSuccessCondition(PlaybookCodeTok, 10, 'nope', 'true');
        GetFindings(Findings);
        Assert.IsTrue(GetField(Findings, 'message').StartsWith('Step 10 has a Success condition on nope'), 'English text');
        Assert.IsTrue(GetField(Findings, 'nextStep').StartsWith('Change the condition path nope'), 'English correction');
        Clear(Findings);
        GlobalLanguage(1039);
        GetFindings(Findings);
        Assert.IsTrue(GetField(Findings, 'message').StartsWith('Skref 10 hefur árangursskilyrði á nope'), 'Icelandic text');
        Assert.IsTrue(GetField(Findings, 'nextStep').StartsWith('Breyttu slóð skilyrðisins nope'), 'Icelandic correction');
        GlobalLanguage(PreviousLanguage);
        Lib.Cleanup(PlaybookCodeTok);
    end;

    /// <summary>The reported missing result prefix warns, and the corrected paths are accepted.</summary>
    [Test]
    procedure Scenario_AC01_NestedResult_RequiresPrefix()
    var
        Findings: JsonArray;
    begin
        // Story #194, AC01 | Time: independent of Today and WorkDate | Risk: None
        // [GIVEN] The called type declares result.valid and result.temporary.
        SetupNestedStep();
        Lib.AddSuccessCondition(PlaybookCodeTok, 10, 'valid', 'true');
        Lib.AddCondition(PlaybookCodeTok, 10, "Playbook Cond. Type ori"::Success, 20000, 'temporary', "Playbook Cond. Operator ori"::Equals, 'false');
        // [WHEN] Verify reads the conditions without dispatching the step.
        GetFindings(Findings);
        // [THEN] Both missing prefixes warn; using the declared paths clears both warnings.
        Assert.AreEqual(2, CountCode(Findings), 'Both unprefixed fields must warn');
        SetupNestedStep();
        Lib.AddSuccessCondition(PlaybookCodeTok, 10, 'result.valid', 'true');
        Lib.AddCondition(PlaybookCodeTok, 10, "Playbook Cond. Type ori"::Success, 20000, 'result.temporary', "Playbook Cond. Operator ori"::Equals, 'false');
        GetFindings(Findings);
        Assert.AreEqual(0, Findings.Count(), 'Both correctly prefixed fields are clean');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    /// <summary>Start and Error paths belong to the workspace, not to the response contract.</summary>
    [Test]
    procedure Scenario_AC02_WorkspaceConditions_AreNotJudged()
    var
        Findings: JsonArray;
    begin
        // Story #194, AC02 | Time: independent of Today and WorkDate | Risk: None
        // [GIVEN] Workspace paths exist only on Start and Error conditions.
        SetupNestedStep();
        Lib.AddSuccessCondition(PlaybookCodeTok, 10, 'result.valid', 'true');
        Lib.AddCondition(PlaybookCodeTok, 10, "Playbook Cond. Type ori"::Start, 10000, '_initial.ready', "Playbook Cond. Operator ori"::Equals, 'true');
        Lib.AddCondition(PlaybookCodeTok, 10, "Playbook Cond. Type ori"::Error, 10000, '_steps.10.failed', "Playbook Cond. Operator ori"::Equals, 'true');
        // [WHEN] The playbook is verified.
        GetFindings(Findings);
        // [THEN] Workspace conditions are not compared to the response fields.
        Assert.AreEqual(0, Findings.Count(), 'Start and Error use the workspace');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    /// <summary>Duplicate paths produce one warning and a disabled step remains informational.</summary>
    [Test]
    procedure Scenario_AC03_DisabledDuplicate_WarnsOnceWithoutBlocking()
    var
        Step: Record "Playbook Step ori";
        Verify: Codeunit "Playbook Verify ori";
        Findings: JsonArray;
        Blocking: JsonArray;
        Summary: Text;
    begin
        // Story #194, AC03 | Time: independent of Today and WorkDate | Risk: None
        // [GIVEN] A disabled step contains the same invalid response path twice.
        SetupNestedStep();
        Step.Get(PlaybookCodeTok, 10);
        Step.Disabled := true;
        Step.Modify(true);
        Lib.AddSuccessCondition(PlaybookCodeTok, 10, 'valid', 'true');
        Lib.AddCondition(PlaybookCodeTok, 10, "Playbook Cond. Type ori"::Success, 20000, 'valid', "Playbook Cond. Operator ori"::Exists, '');
        // [WHEN] Both informational and blocking findings are read.
        GetFindings(Findings);
        // [THEN] The duplicate warns once and does not block a run.
        Assert.AreEqual(1, CountCode(Findings), 'One warning for the repeated path');
        Assert.AreEqual('true', GetField(Findings, 'stepDisabled'), 'Disabled step is identified');
        Assert.IsFalse(Verify.GetBlockingFindings(PlaybookCodeTok, false, Blocking, Summary), 'Disabled warnings do not block');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    /// <summary>Unknown response fields remain not determinable when the type supplies no response chapter.</summary>
    [Test]
    procedure Scenario_AC02_NoResponseContract_StaysSilent()
    var
        Findings: JsonArray;
    begin
        // Story #194, AC02 | Time: independent of Today and WorkDate | Risk: None
        // [GIVEN] An installed test type declares no response chapter.
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Test.Orchestrator.Ask", '{}', 0, '', 0);
        Lib.AddSuccessCondition(PlaybookCodeTok, 10, 'unknown', 'true');
        // [WHEN] The playbook is verified.
        GetFindings(Findings);
        // [THEN] Verify does not invent response declarations.
        Assert.AreEqual(0, CountCode(Findings), 'Undeclared response shapes cannot be judged');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    local procedure SetupNestedStep()
    begin
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Test.Orchestrator.ConditionResponse", '', 0, '', 0);
    end;

    local procedure SetupStep()
    begin
        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        AddVerifyStep(10);
    end;

    local procedure AddVerifyStep(StepNo: Integer)
    begin
        Lib.AddStep(PlaybookCodeTok, StepNo, "Playbook Step Type ori"::Action, "Message Type ori"::"Orchestrator.Playbook.Verify", '{"playbookCode":"CND-194"}', 0, '', 0);
    end;

    local procedure GetFindings(var Findings: JsonArray)
    var
        Verify: Codeunit "Playbook Verify ori";
    begin
        Verify.GetFindings(PlaybookCodeTok, Findings);
    end;

    local procedure CountCode(Findings: JsonArray): Integer
    var
        Token: JsonToken;
        CodeToken: JsonToken;
        Total: Integer;
    begin
        foreach Token in Findings do
            if Token.AsObject().Get('code', CodeToken) then
                if CodeToken.AsValue().AsText() = FindingCodeTok then
                    Total += 1;
        exit(Total);
    end;

    local procedure GetField(Findings: JsonArray; FieldName: Text): Text
    var
        Token: JsonToken;
        CodeToken: JsonToken;
        FieldToken: JsonToken;
    begin
        foreach Token in Findings do
            if Token.AsObject().Get('code', CodeToken) then
                if CodeToken.AsValue().AsText() = FindingCodeTok then begin
                    Token.AsObject().Get(FieldName, FieldToken);
                    exit(FieldToken.AsValue().AsText());
                end;
        exit('');
    end;
}
