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
    end;

    /// <summary>
    /// Adds the read-only forEach source: a step that lists the layouts of the sample report.
    /// </summary>
    /// <param name="PlaybookCode">The playbook code.</param>
    /// <param name="StepNo">The step number.</param>
    procedure AddLayoutSourceStep(PlaybookCode: Code[20]; StepNo: Integer)
    begin
        AddStep(PlaybookCode, StepNo, "Playbook Step Type ori"::Action, "Message Type ori"::"Orchestrator.ReportLayout.List",
            StrSubstNo('{"reportId":%1}', Report::"Layout Sample Report ori"), 0, '', 0);
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
}
