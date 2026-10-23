namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;

/// <summary>
/// Builds disposable playbooks, runs them through the real runner and removes everything the run wrote.
/// The array a forEach step iterates comes from <c>Orchestrator.ReportLayout.List</c> on the sample
/// report, a read-only message type with no side effects; the failing answers come from
/// <c>Orchestrator.Report.Run</c> on the always-failing test report.
/// </summary>
codeunit 96434 "Playbook Test Library ori"
{
    Access = Internal;

    /// <summary>
    /// Creates (or resets) a playbook header with no steps.
    /// </summary>
    /// <param name="PlaybookCode">The playbook code.</param>
    procedure CreatePlaybook(PlaybookCode: Code[20])
    var
        Playbook: Record "Playbook ori";
    begin
        Cleanup(PlaybookCode);
        Playbook.Init();
        Playbook.Code := PlaybookCode;
        Playbook.Description := 'Test playbook';
        Playbook.Insert(true);
    end;

    /// <summary>
    /// Adds a step to a playbook.
    /// </summary>
    /// <param name="PlaybookCode">The playbook code.</param>
    /// <param name="StepNo">The step number.</param>
    /// <param name="StepType">Action or Check.</param>
    /// <param name="MessageType">The message type the step calls.</param>
    /// <param name="Template">The request template JSON.</param>
    /// <param name="IterateSourceStepNo">Source step of the forEach, or 0 for a single step.</param>
    /// <param name="IterateArrayPath">Array path of the forEach, or empty for a single step.</param>
    /// <param name="SkipIfStepFailed">Skip If Step Failed, or 0.</param>
    procedure AddStep(PlaybookCode: Code[20]; StepNo: Integer; StepType: Enum "Playbook Step Type ori"; MessageType: Enum "Message Type ori"; Template: Text; IterateSourceStepNo: Integer; IterateArrayPath: Text[250]; SkipIfStepFailed: Integer)
    var
        PlaybookStep: Record "Playbook Step ori";
    begin
        PlaybookStep.Init();
        PlaybookStep."Playbook Code" := PlaybookCode;
        PlaybookStep."Step No." := StepNo;
        PlaybookStep."Step Type" := StepType;
        PlaybookStep."Message Type" := MessageType;
        PlaybookStep."Iterate Source Step No." := IterateSourceStepNo;
        PlaybookStep."Iterate Array Path" := IterateArrayPath;
        PlaybookStep."Skip If Step Failed" := SkipIfStepFailed;
        if Template <> '' then
            PlaybookStep.SetRequestTemplate(Template);
        PlaybookStep.Insert(true);
        LinkPreviousStep(PlaybookCode, StepNo);
    end;

    /// <summary>
    /// Points the Next Step edges (success and failure) of the step before this one at this step, so a
    /// playbook of several steps runs in step order the way the runner follows edges.
    /// </summary>
    local procedure LinkPreviousStep(PlaybookCode: Code[20]; StepNo: Integer)
    var
        PreviousStep: Record "Playbook Step ori";
    begin
        PreviousStep.SetRange("Playbook Code", PlaybookCode);
        PreviousStep.SetFilter("Step No.", '<%1', StepNo);
        if not PreviousStep.FindLast() then
            exit;
        PreviousStep."Next Step No. (Success)" := StepNo;
        PreviousStep."Next Step No. (Failure)" := StepNo;
        PreviousStep.Modify(true);
    end;

    /// <summary>
    /// Adds the read-only forEach source: a step that lists the layouts of the sample report.
    /// </summary>
    /// <param name="PlaybookCode">The playbook code.</param>
    /// <param name="StepNo">The step number.</param>
    procedure AddLayoutSourceStep(PlaybookCode: Code[20]; StepNo: Integer)
    begin
        AddStep(PlaybookCode, StepNo, "Playbook Step Type ori"::Action, "Message Type ori"::"Orchestrator.ReportLayout.List",
            StrSubstNo(Format1Tok, Report::"Layout Sample Report ori"), 0, '', 0);
    end;

    /// <summary>
    /// Adds a Success condition to a step.
    /// </summary>
    /// <param name="PlaybookCode">The playbook code.</param>
    /// <param name="StepNo">The step the condition guards.</param>
    /// <param name="Path">The response path.</param>
    /// <param name="ConditionValue">The value the path must equal.</param>
    procedure AddSuccessCondition(PlaybookCode: Code[20]; StepNo: Integer; Path: Text[250]; ConditionValue: Text[250])
    var
        Condition: Record "Playbook Condition ori";
    begin
        Condition.Init();
        Condition."Playbook Code" := PlaybookCode;
        Condition."Step No." := StepNo;
        Condition."Condition Type" := Condition."Condition Type"::Success;
        Condition."Group No." := 1;
        Condition."Line No." := 10000;
        Condition.Path := Path;
        Condition.Operator := Condition.Operator::Equals;
        Condition.Value := ConditionValue;
        Condition.Insert(true);
    end;

    /// <summary>
    /// Adds a condition of any type to a step.
    /// </summary>
    /// <param name="PlaybookCode">The playbook code.</param>
    /// <param name="StepNo">The step the condition guards.</param>
    /// <param name="ConditionType">Start, Success or Error.</param>
    /// <param name="LineNo">The line number within the group (10000, 20000, ...).</param>
    /// <param name="Path">The path the condition reads.</param>
    /// <param name="Operator">The comparison operator.</param>
    /// <param name="ConditionValue">The value to compare with.</param>
    procedure AddCondition(PlaybookCode: Code[20]; StepNo: Integer; ConditionType: Enum "Playbook Cond. Type ori"; LineNo: Integer; Path: Text[250]; Operator: Enum "Playbook Cond. Operator ori"; ConditionValue: Text[250])
    var
        Condition: Record "Playbook Condition ori";
    begin
        Condition.Init();
        Condition."Playbook Code" := PlaybookCode;
        Condition."Step No." := StepNo;
        Condition."Condition Type" := ConditionType;
        Condition."Group No." := 1;
        Condition."Line No." := LineNo;
        Condition.Path := Path;
        Condition.Operator := Operator;
        Condition.Value := ConditionValue;
        Condition.Insert(true);
    end;

    /// <summary>
    /// Adds the Success condition <c>status Equals Success</c> that every step should have.
    /// </summary>
    /// <param name="PlaybookCode">The playbook code.</param>
    /// <param name="StepNo">The step the condition guards.</param>
    procedure AddStatusSuccessCondition(PlaybookCode: Code[20]; StepNo: Integer)
    begin
        AddCondition(PlaybookCode, StepNo, "Playbook Cond. Type ori"::Success, 10000, 'status', "Playbook Cond. Operator ori"::Equals, 'Success');
    end;

    /// <summary>
    /// Adds the Success condition <c>noOfRecords GreaterThan 0</c> that guards a record reader.
    /// </summary>
    /// <param name="PlaybookCode">The playbook code.</param>
    /// <param name="StepNo">The step the condition guards.</param>
    procedure AddNoOfRecordsCondition(PlaybookCode: Code[20]; StepNo: Integer)
    begin
        AddCondition(PlaybookCode, StepNo, "Playbook Cond. Type ori"::Success, 20000, 'noOfRecords', "Playbook Cond. Operator ori"::GreaterThan, '0');
    end;

    /// <summary>
    /// Sets the Next Step edges of a step.
    /// </summary>
    /// <param name="PlaybookCode">The playbook code.</param>
    /// <param name="StepNo">The step to change.</param>
    /// <param name="OnSuccess">Next Step No. (Success).</param>
    /// <param name="OnFailure">Next Step No. (Failure).</param>
    procedure SetNextSteps(PlaybookCode: Code[20]; StepNo: Integer; OnSuccess: Integer; OnFailure: Integer)
    var
        PlaybookStep: Record "Playbook Step ori";
    begin
        PlaybookStep.Get(PlaybookCode, StepNo);
        PlaybookStep."Next Step No. (Success)" := OnSuccess;
        PlaybookStep."Next Step No. (Failure)" := OnFailure;
        PlaybookStep.Modify(true);
    end;

    /// <summary>
    /// Sets the Result Log Paths of a step.
    /// </summary>
    /// <param name="PlaybookCode">The playbook code.</param>
    /// <param name="StepNo">The step to change.</param>
    /// <param name="ResultLogPaths">The paths, for example noOfRecords>customerCount.</param>
    procedure SetResultLogPaths(PlaybookCode: Code[20]; StepNo: Integer; ResultLogPaths: Text[2048])
    var
        PlaybookStep: Record "Playbook Step ori";
    begin
        PlaybookStep.Get(PlaybookCode, StepNo);
        PlaybookStep."Result Log Paths" := ResultLogPaths;
        PlaybookStep.Modify(true);
    end;

    /// <summary>
    /// Enables or disables a step.
    /// </summary>
    /// <param name="PlaybookCode">The playbook code.</param>
    /// <param name="StepNo">The step to change.</param>
    /// <param name="Disabled">True to disable the step.</param>
    procedure SetStepDisabled(PlaybookCode: Code[20]; StepNo: Integer; Disabled: Boolean)
    var
        PlaybookStep: Record "Playbook Step ori";
    begin
        PlaybookStep.Get(PlaybookCode, StepNo);
        PlaybookStep.Validate(Disabled, Disabled);
        PlaybookStep.Modify(true);
    end;

    /// <summary>
    /// Keeps a step out of the run status (the reporting tail).
    /// </summary>
    /// <param name="PlaybookCode">The playbook code.</param>
    /// <param name="StepNo">The step to change.</param>
    procedure SetExcludeFromRunStatus(PlaybookCode: Code[20]; StepNo: Integer)
    var
        PlaybookStep: Record "Playbook Step ori";
    begin
        PlaybookStep.Get(PlaybookCode, StepNo);
        PlaybookStep."Exclude From Run Status" := true;
        PlaybookStep.Modify(true);
    end;

    /// <summary>
    /// Runs the playbook through the real runner, as the Run message type and the Job Queue do.
    /// </summary>
    /// <param name="PlaybookCode">The playbook to run.</param>
    /// <param name="InstanceId">Receives the instance ID of the run.</param>
    procedure RunPlaybook(PlaybookCode: Code[20]; var InstanceId: Guid)
    var
        Runner: Codeunit "Playbook Runner ori";
        InitialRequest: BigText;
        FinalResponse: BigText;
    begin
        Commit();
        Runner.Run(PlaybookCode, InitialRequest, FinalResponse, InstanceId);
    end;

    /// <summary>
    /// Removes the playbook, its steps, conditions, instances and step logs.
    /// </summary>
    /// <param name="PlaybookCode">The playbook to remove.</param>
    procedure Cleanup(PlaybookCode: Code[20])
    var
        Playbook: Record "Playbook ori";
        PlaybookStep: Record "Playbook Step ori";
        Instance: Record "Playbook Instance ori";
        StepLog: Record "Playbook Step Log ori";
    begin
        Instance.SetRange("Playbook Code", PlaybookCode);
        if Instance.FindSet() then
            repeat
                StepLog.SetRange("Instance ID", Instance.ID);
                StepLog.DeleteAll(true);
            until Instance.Next() = 0;
        Instance.DeleteAll(true);

        PlaybookStep.SetRange("Playbook Code", PlaybookCode);
        PlaybookStep.DeleteAll(true);

        if Playbook.Get(PlaybookCode) then
            Playbook.Delete(true);
        Commit();
    end;
    var
        Format1Tok: Label '{"reportId":%1}', Locked = true;
}
