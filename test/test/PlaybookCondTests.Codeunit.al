namespace Origo.Bifrost.Nornir.Test;

using Origo.Bifrost;
using Origo.Bifrost.Nornir;
using System.TestTools.TestRunner;

/// <summary>
/// Conditions and run reporting: the group evaluation rule, Check semantics, and
/// the _run / _steps workspace namespaces the report email is built from.
/// </summary>
codeunit 96318 "Playbook Cond Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        PlaybookCodeTok: Label 'COND-TEST', Locked = true;
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        TestInstall: Codeunit "Test Install";
    begin
        if IsInitialized then
            exit;
        TestInstall.DisableRequestDebugMode();
        IsInitialized := true;
    end;

    // ---------- condition set evaluation ----------

    [Test]
    procedure EmptyConditionSetIsTrue()
    var
        JsonHelper: Codeunit "Playbook JSON Helper ori";
        SourceJson: JsonObject;
    begin
        // [SCENARIO] A step with no conditions of a type always passes — existing playbooks are unaffected
        ClearConditions(9000);
        SourceJson.Add('status', 'Success');

        Assert.IsTrue(
            JsonHelper.EvaluateConditionSet(SourceJson, PlaybookCodeTok, 9000, "Playbook Cond. Type ori"::Start),
            'An empty condition set should evaluate true');
    end;

    [Test]
    procedure AllConditionsInAGroupMustHold()
    var
        JsonHelper: Codeunit "Playbook JSON Helper ori";
        SourceJson: JsonObject;
    begin
        // [SCENARIO] AND within a group
        ClearConditions(9010);
        AddCondition(9010, "Playbook Cond. Type ori"::Start, 1, 10000, 'a', "Playbook Cond. Operator ori"::Equals, '1');
        AddCondition(9010, "Playbook Cond. Type ori"::Start, 1, 20000, 'b', "Playbook Cond. Operator ori"::Equals, '2');

        SourceJson.Add('a', '1');
        SourceJson.Add('b', '2');
        Assert.IsTrue(
            JsonHelper.EvaluateConditionSet(SourceJson, PlaybookCodeTok, 9010, "Playbook Cond. Type ori"::Start),
            'Both conditions hold, so the group holds');

        Clear(SourceJson);
        SourceJson.Add('a', '1');
        SourceJson.Add('b', 'wrong');
        Assert.IsFalse(
            JsonHelper.EvaluateConditionSet(SourceJson, PlaybookCodeTok, 9010, "Playbook Cond. Type ori"::Start),
            'One condition failing should fail the whole group');
    end;

    [Test]
    procedure AnyGroupHoldingIsEnough()
    var
        JsonHelper: Codeunit "Playbook JSON Helper ori";
        SourceJson: JsonObject;
    begin
        // [SCENARIO] OR across groups
        ClearConditions(9020);
        AddCondition(9020, "Playbook Cond. Type ori"::Start, 1, 10000, 'a', "Playbook Cond. Operator ori"::Equals, 'yes');
        AddCondition(9020, "Playbook Cond. Type ori"::Start, 2, 10000, 'b', "Playbook Cond. Operator ori"::Equals, 'yes');

        SourceJson.Add('a', 'no');
        SourceJson.Add('b', 'yes');
        Assert.IsTrue(
            JsonHelper.EvaluateConditionSet(SourceJson, PlaybookCodeTok, 9020, "Playbook Cond. Type ori"::Start),
            'Group 1 fails but group 2 holds, so the set holds');

        Clear(SourceJson);
        SourceJson.Add('a', 'no');
        SourceJson.Add('b', 'no');
        Assert.IsFalse(
            JsonHelper.EvaluateConditionSet(SourceJson, PlaybookCodeTok, 9020, "Playbook Cond. Type ori"::Start),
            'No group holds, so the set fails');
    end;

    [Test]
    procedure GroupsAreIndependentNotLeftToRight()
    var
        JsonHelper: Codeunit "Playbook JSON Helper ori";
        SourceJson: JsonObject;
    begin
        // [SCENARIO] A failing first group must not poison a later group.
        // This is the case a flat And/Or column gets wrong.
        ClearConditions(9030);
        AddCondition(9030, "Playbook Cond. Type ori"::Start, 1, 10000, 'a', "Playbook Cond. Operator ori"::Equals, 'x');
        AddCondition(9030, "Playbook Cond. Type ori"::Start, 1, 20000, 'b', "Playbook Cond. Operator ori"::Equals, 'x');
        AddCondition(9030, "Playbook Cond. Type ori"::Start, 2, 10000, 'c', "Playbook Cond. Operator ori"::Equals, 'ok');

        SourceJson.Add('a', 'x');
        SourceJson.Add('b', 'NOT x');
        SourceJson.Add('c', 'ok');

        Assert.IsTrue(
            JsonHelper.EvaluateConditionSet(SourceJson, PlaybookCodeTok, 9030, "Playbook Cond. Type ori"::Start),
            'Group 2 holds on its own merits regardless of group 1');
    end;

    [Test]
    procedure ConditionTypesAreEvaluatedIndependently()
    var
        JsonHelper: Codeunit "Playbook JSON Helper ori";
        SourceJson: JsonObject;
    begin
        // [SCENARIO] A Start condition must not be seen when evaluating Success
        ClearConditions(9040);
        AddCondition(9040, "Playbook Cond. Type ori"::Start, 1, 10000, 'a', "Playbook Cond. Operator ori"::Equals, 'never');

        SourceJson.Add('a', 'something else');
        Assert.IsFalse(
            JsonHelper.EvaluateConditionSet(SourceJson, PlaybookCodeTok, 9040, "Playbook Cond. Type ori"::Start),
            'The Start condition should fail');
        Assert.IsTrue(
            JsonHelper.EvaluateConditionSet(SourceJson, PlaybookCodeTok, 9040, "Playbook Cond. Type ori"::Success),
            'Success has no conditions of its own, so it should pass');
    end;

    // ---------- step table helpers ----------

    [Test]
    procedure HasConditionsSeesOnlyItsOwnType()
    var
        PlaybookStep: Record "Playbook Step ori";
    begin
        // [SCENARIO] HasConditions is scoped by type
        ClearConditions(9050);
        AddCondition(9050, "Playbook Cond. Type ori"::Error, 1, 10000, 'warnings', "Playbook Cond. Operator ori"::GreaterThan, '0');

        PlaybookStep.Init();
        PlaybookStep."Playbook Code" := CopyStr(PlaybookCodeTok, 1, MaxStrLen(PlaybookStep."Playbook Code"));
        PlaybookStep."Step No." := 9050;

        Assert.IsTrue(PlaybookStep.HasConditions("Playbook Cond. Type ori"::Error), 'Error conditions exist');
        Assert.IsFalse(PlaybookStep.HasConditions("Playbook Cond. Type ori"::Start), 'No Start conditions exist');
    end;

    [Test]
    procedure StepTypeDefaultsToAction()
    var
        PlaybookStep: Record "Playbook Step ori";
    begin
        // [SCENARIO] Existing behaviour is the default — a false condition is a failure
        PlaybookStep.Init();
        Assert.IsFalse(PlaybookStep.IsCheck(), 'A new step should default to Action');

        PlaybookStep."Step Type" := PlaybookStep."Step Type"::Check;
        Assert.IsTrue(PlaybookStep.IsCheck(), 'Check should be recognised');
    end;

    // ---------- run reporting ----------

    [Test]
    procedure BeginRunSeedsRunNamespace()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        InstanceId: Guid;
        Result: Text;
    begin
        // [SCENARIO] _run carries the instance ID, which is how a report step filters the step log
        InstanceId := CreateGuid();
        Initialize();
        Workspace.Reset();
        Workspace.BeginRun('MONTHEND', 'Month-end close', InstanceId);

        Assert.IsTrue(Workspace.GetValue('_run.playbookCode', Result), 'playbookCode should be present');
        Assert.AreEqual('MONTHEND', Result, 'playbookCode');
        Assert.IsTrue(Workspace.GetValue('_run.instanceId', Result), 'instanceId should be present');
        Assert.AreNotEqual('', Result, 'instanceId should not be blank');
        Assert.IsFalse(Workspace.RunFailed(), 'A fresh run has not failed');
    end;

    [Test]
    procedure RollUpCountsAndFlagsFailure()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        Result: Text;
    begin
        // [SCENARIO] _run aggregates step outcomes
        Initialize();
        Workspace.Reset();
        Workspace.BeginRun('P', 'desc', CreateGuid());

        Workspace.RollUpRun(10, 'Completed', 0, 0, false);
        Workspace.RollUpRun(20, 'Failed', 5, 2, false);
        Workspace.RollUpRun(30, 'Cancelled', 0, 0, false);

        Workspace.GetValue('_run.stepsExecuted', Result);
        Assert.AreEqual('3', Result, 'stepsExecuted');
        Workspace.GetValue('_run.stepsSucceeded', Result);
        Assert.AreEqual('1', Result, 'stepsSucceeded');
        Workspace.GetValue('_run.stepsFailed', Result);
        Assert.AreEqual('1', Result, 'stepsFailed');
        Workspace.GetValue('_run.stepsSkipped', Result);
        Assert.AreEqual('1', Result, 'stepsSkipped');
        Workspace.GetValue('_run.firstFailedStepNo', Result);
        Assert.AreEqual('20', Result, 'firstFailedStepNo');
        Assert.IsTrue(Workspace.RunFailed(), 'The run should be flagged failed');
    end;

    [Test]
    procedure ExcludedStepsLeaveRunStatusAlone()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        Result: Text;
        Token: JsonToken;
    begin
        // [SCENARIO] The reporting tail must not narrate itself or inflate the totals
        Initialize();
        Workspace.Reset();
        Workspace.BeginRun('P', 'desc', CreateGuid());

        Workspace.RollUpRun(10, 'Completed', 0, 0, false);
        Workspace.RecordStep(900, 'Send report', 'Orchestrator.Telegram.Message', 'Completed', false, false, 5, '', true);
        Workspace.RollUpRun(900, 'Completed', 0, 0, true);

        Workspace.GetValue('_run.stepsExecuted', Result);
        Assert.AreEqual('1', Result, 'The excluded step should not be counted');
        Assert.IsFalse(Workspace.GetToken('_steps.900', Token), 'The excluded step should not appear in _steps');
    end;

    [Test]
    procedure EscalateFailsTheRunWithoutTouchingCounters()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        Result: Text;
    begin
        // [SCENARIO] An Error condition fails the run while the step still succeeded
        Initialize();
        Workspace.Reset();
        Workspace.BeginRun('P', 'desc', CreateGuid());
        Workspace.RollUpRun(10, 'Completed', 0, 0, false);

        Workspace.EscalateRunFailure(10);

        Assert.IsTrue(Workspace.RunFailed(), 'Escalation should fail the run');
        Workspace.GetValue('_run.stepsFailed', Result);
        Assert.AreEqual('0', Result, 'Escalation must not increment stepsFailed');
        Workspace.GetValue('_run.stepsSucceeded', Result);
        Assert.AreEqual('1', Result, 'The step still succeeded');
    end;

    [Test]
    procedure RepeatedStepAccumulatesInsteadOfOverwriting()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        Result: Text;
    begin
        // [SCENARIO] A paged or iterated step is recorded many times and must not
        // overwrite itself — page 3 must not erase pages 1 and 2.
        Initialize();
        Workspace.Reset();
        Workspace.BeginRun('P', 'desc', CreateGuid());

        Workspace.RecordStep(20, 'Fetch page', 'Data.Records.Get', 'Completed', false, false, 100, '', false);
        Workspace.RecordPage(20, false);
        Workspace.RecordStep(20, 'Fetch page', 'Data.Records.Get', 'Completed', false, false, 150, '', false);
        Workspace.RecordPage(20, false);

        Workspace.GetValue('_steps.20.pages', Result);
        Assert.AreEqual('2', Result, 'Both pages should be counted');
        Workspace.GetValue('_steps.20.durationMs', Result);
        Assert.AreEqual('250', Result, 'Durations should sum across pages');
    end;

    [Test]
    procedure StatusDegradesAndNeverImproves()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        Result: Text;
    begin
        // [SCENARIO] One failing page leaves the whole step Failed
        Initialize();
        Workspace.Reset();
        Workspace.BeginRun('P', 'desc', CreateGuid());

        Workspace.RecordStep(20, 'Fetch', 'Data.Records.Get', 'Completed', false, false, 10, '', false);
        Workspace.RecordStep(20, 'Fetch', 'Data.Records.Get', 'Failed', false, false, 10, 'boom', false);
        Workspace.RecordStep(20, 'Fetch', 'Data.Records.Get', 'Completed', false, false, 10, '', false);

        Workspace.GetValue('_steps.20.status', Result);
        Assert.AreEqual('Failed', Result, 'A later success must not erase an earlier failure');
    end;

    [Test]
    procedure IterationFailuresCarryItemAndError()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        ItemObj: JsonObject;
        Token: JsonToken;
        Result: Text;
    begin
        // [SCENARIO] This is what turns "2 failed" into a sentence a person can act on
        Initialize();
        Workspace.Reset();
        Workspace.BeginRun('P', 'desc', CreateGuid());

        ItemObj.Add('no', '103002');
        ItemObj.Add('name', 'CRONUS Ltd.');
        Workspace.RecordIteration(30, 2, 'Failed', ItemObj.AsToken(), 'Posting Date is not within your range.', false);

        Workspace.GetValue('_steps.30.items.failed', Result);
        Assert.AreEqual('1', Result, 'items.failed');
        Assert.IsTrue(Workspace.GetToken('_steps.30.failures', Token), 'failures array should exist');
        Assert.AreEqual(1, Token.AsArray().Count(), 'one failure recorded');

        Workspace.GetValue('_steps.30.failures[0].item.no', Result);
        Assert.AreEqual('103002', Result, 'the failing item should be identifiable');
        Workspace.GetValue('_steps.30.failures[0].error', Result);
        Assert.IsTrue(Result.Contains('Posting Date'), 'the error text should be carried');
    end;

    [Test]
    procedure CheckFailuresAreCountedSeparatelyFromErrors()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        ItemObj: JsonObject;
        Result: Text;
    begin
        // [SCENARIO] "kennitala invalid" is not "the step broke"
        Initialize();
        Workspace.Reset();
        Workspace.BeginRun('P', 'desc', CreateGuid());

        ItemObj.Add('no', '10000');
        Workspace.RecordIteration(20, 0, 'Completed', ItemObj.AsToken(), '', false);
        Workspace.RecordIteration(20, 1, 'CheckFailed', ItemObj.AsToken(), '', false);

        Workspace.GetValue('_steps.20.items.total', Result);
        Assert.AreEqual('2', Result, 'items.total');
        Workspace.GetValue('_steps.20.items.succeeded', Result);
        Assert.AreEqual('1', Result, 'items.succeeded');
        Workspace.GetValue('_steps.20.items.checkFailed', Result);
        Assert.AreEqual('1', Result, 'items.checkFailed');
        Assert.IsFalse(Workspace.GetValue('_steps.20.items.failed', Result), 'nothing technically failed');
    end;

    [Test]
    procedure FailureListIsCappedButCountsStayExact()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        ItemObj: JsonObject;
        Token: JsonToken;
        Result: Text;
        i: Integer;
    begin
        // [SCENARIO] The workspace is re-serialised constantly and snapshotted on failure,
        // so the list is bounded — but the count must never lie.
        Initialize();
        Workspace.Reset();
        Workspace.BeginRun('P', 'desc', CreateGuid());
        ItemObj.Add('no', 'X');

        for i := 1 to 25 do
            Workspace.RecordIteration(40, i, 'Failed', ItemObj.AsToken(), 'err', false);

        Workspace.GetToken('_steps.40.failures', Token);
        Assert.AreEqual(20, Token.AsArray().Count(), 'the list should be capped at 20');
        Workspace.GetValue('_steps.40.failuresTruncated', Result);
        Assert.AreEqual('true', Result, 'truncation should be flagged');
        Workspace.GetValue('_steps.40.items.failed', Result);
        Assert.AreEqual('25', Result, 'the count must remain exact');
    end;

    [Test]
    procedure SkippedStepRecordsTheReason()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        Result: Text;
    begin
        // [SCENARIO] "Reconciliation was skipped because nothing posted" is often the
        // most useful sentence in the report
        Initialize();
        Workspace.Reset();
        Workspace.BeginRun('P', 'desc', CreateGuid());

        Workspace.RecordStepSkipped(50, 'Reconcile', 'Finance.BankReconciliation.Post', 'Skipped: start conditions not met.', false);

        Workspace.GetValue('_steps.50.status', Result);
        Assert.AreEqual('Cancelled', Result, 'A skipped step is Cancelled, never Failed');
        Workspace.GetValue('_steps.50.skippedReason', Result);
        Assert.IsTrue(Result.Contains('start conditions'), 'the reason should be recorded');
    end;

    [Test]
    procedure SummaryPathsFeedTheReportNotTheWorkspaceData()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        Result: Text;
    begin
        // [SCENARIO] Summary Paths is deliberately separate from Result Log Paths
        Initialize();
        Workspace.Reset();
        Workspace.BeginRun('P', 'desc', CreateGuid());

        Workspace.RecordStepSummary(60, '{"postedInvoices":3,"totalAmount":45280,"bulk":"ignored"}',
            'postedInvoices,totalAmount>amount', false);

        Workspace.GetValue('_steps.60.result.postedInvoices', Result);
        Assert.AreEqual('3', Result, 'unmapped path keeps its name');
        Workspace.GetValue('_steps.60.result.amount', Result);
        Assert.AreEqual('45280', Result, 'source>target renames');
        Assert.IsFalse(Workspace.GetValue('_steps.60.result.bulk', Result), 'unlisted fields stay out of the report');
    end;

    [Test]
    procedure RunAndStepsFilterToTheReportPayload()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        Filtered: Text;
    begin
        // [SCENARIO] "@_run,_steps" is the whole email prompt — narrative without bulk.
        // This is why the namespaces are top-level rather than nested under the step key.
        Initialize();
        Workspace.Reset();
        Workspace.BeginRun('P', 'desc', CreateGuid());
        Workspace.RecordStep(10, 'Fetch', 'Data.Records.Get', 'Completed', false, false, 10, '', false);
        Workspace.SetValue('10.bulk', 'a very large collected payload');

        Filtered := Workspace.ToFilteredText('_run,_steps');

        Assert.IsTrue(Filtered.Contains('"_run"'), 'the run status should be included');
        Assert.IsTrue(Filtered.Contains('"_steps"'), 'the step narrative should be included');
        Assert.IsFalse(Filtered.Contains('very large collected payload'), 'bulk step data must stay out');
    end;

    [Test]
    procedure StatusTextComesFromTheEnumName()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        StepStatus: Enum "Playbook Inst. Status ori";
    begin
        // [SCENARIO] _steps.status carries the declared enum name, which is also what
        // RollUpRun compares against. Neither Format overload can supply it: plain
        // Format() returns the localised caption ("Lokið" in an Icelandic session) and
        // Format(x, 0, 9) returns the ordinal ("2"). Either would leave every counter
        // silently at zero.
        StepStatus := StepStatus::Completed;
        Assert.AreEqual('Completed', Workspace.StatusToText(StepStatus), 'Completed');
        Assert.AreNotEqual(Format(StepStatus, 0, 9), Workspace.StatusToText(StepStatus),
            'Format 9 gives the ordinal, not the name');

        StepStatus := StepStatus::Failed;
        Assert.AreEqual('Failed', Workspace.StatusToText(StepStatus), 'Failed');
        StepStatus := StepStatus::Cancelled;
        Assert.AreEqual('Cancelled', Workspace.StatusToText(StepStatus), 'Cancelled');
    end;

    [Test]
    procedure MessageTypeTextComesFromTheEnumName()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        MessageType: Enum "Message Type ori";
    begin
        // [SCENARIO] _steps.messageType has to be readable by a language model writing the
        // report email. Format(x, 0, 9) returns the ordinal ("10035541"), which is useless
        // there. The declared enum name is the dotted identifier.
        MessageType := MessageType::"Orchestrator.Status.Get";
        Assert.AreEqual('Orchestrator.Status.Get', Workspace.MessageTypeToText(MessageType),
            'the enum name is the dotted identifier');
        Assert.AreNotEqual(Format(MessageType, 0, 9), Workspace.MessageTypeToText(MessageType),
            'Format 9 gives the ordinal, not the name');
    end;

    // ---------- helpers ----------

    [Test]
    procedure ExcludedStepsAreStillReferenceableUnderTail()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        Result: Text;
    begin
        // [SCENARIO] A reporting step must be able to condition on an earlier reporting
        // step's outcome. Excluding them from the workspace entirely made that
        // impossible, and the dependent step was silently skipped as "start conditions
        // not met" — which reads like a condition problem rather than a missing path.
        Initialize();
        Workspace.Reset();
        Workspace.BeginRun('P', 'desc', CreateGuid());

        Workspace.RecordStep(900, 'Compose report', 'LLM.Prompt.Complete', 'Completed', false, false, 12, '', true);

        Assert.IsTrue(Workspace.GetValue('_tail.900.status', Result), '_tail entry should exist');
        Assert.AreEqual('Completed', Result, 'with the recorded status');
        Workspace.GetValue('_tail.900.description', Result);
        Assert.AreEqual('Compose report', Result, 'and the description');
    end;

    [Test]
    procedure TailStaysOutOfTheReportPayload()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        Filtered: Text;
    begin
        // [SCENARIO] _tail is referenceable but must not reach "@_run,_steps", so the
        // report never describes the steps that produce the report.
        Initialize();
        Workspace.Reset();
        Workspace.BeginRun('P', 'desc', CreateGuid());
        Workspace.RecordStep(10, 'Real work', 'Data.Records.Get', 'Completed', false, false, 10, '', false);
        Workspace.RecordStep(900, 'Compose report', 'LLM.Prompt.Complete', 'Completed', false, false, 12, '', true);

        Filtered := Workspace.ToFilteredText('_run,_steps');

        Assert.IsTrue(Filtered.Contains('Real work'), 'the work being reported on is included');
        Assert.IsFalse(Filtered.Contains('Compose report'), 'the reporting tail is not');
    end;

    local procedure ClearConditions(StepNo: Integer)
    var
        Condition: Record "Playbook Condition ori";
    begin
        Condition.SetRange("Playbook Code", PlaybookCodeTok);
        Condition.SetRange("Step No.", StepNo);
        Condition.DeleteAll();
    end;

    local procedure AddCondition(StepNo: Integer; CondType: Enum "Playbook Cond. Type ori"; GroupNo: Integer; LineNo: Integer; Path: Text; Operator: Enum "Playbook Cond. Operator ori"; ConditionValue: Text)
    var
        Condition: Record "Playbook Condition ori";
    begin
        Condition.Init();
        Condition."Playbook Code" := CopyStr(PlaybookCodeTok, 1, MaxStrLen(Condition."Playbook Code"));
        Condition."Step No." := StepNo;
        Condition."Condition Type" := CondType;
        Condition."Group No." := GroupNo;
        Condition."Line No." := LineNo;
        Condition.Path := CopyStr(Path, 1, MaxStrLen(Condition.Path));
        Condition.Operator := Operator;
        Condition."Value" := CopyStr(ConditionValue, 1, MaxStrLen(Condition."Value"));
        Condition.Insert();
    end;
}
