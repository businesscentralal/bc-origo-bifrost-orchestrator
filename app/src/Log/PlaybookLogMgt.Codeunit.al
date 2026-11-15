/// <summary>
/// CRUD helpers for playbook instance and step log records.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035549 "Playbook Log Mgt ori"
{
    Access = Internal;
    Permissions = tabledata "Playbook Instance ori" = RIMD,
                  tabledata "Playbook Step Log ori" = RIMD;

    /// <summary>
    /// Creates a new playbook instance record and returns its ID.
    /// </summary>
    procedure CreateInstance(PlaybookCode: Code[20]; InitialRequestText: Text): Guid
    var
        Instance: Record "Playbook Instance ori";
        OutStr: OutStream;
    begin
        Instance.Init();
        Instance.ID := CreateGuid();
        Instance."Playbook Code" := PlaybookCode;
        Instance.Status := Instance.Status::Running;
        Instance."Started At" := CurrentDateTime();
        Instance."Initiated By" := UserSecurityId();

        if InitialRequestText <> '' then begin
            Instance.Context.CreateOutStream(OutStr, TextEncoding::UTF8);
            OutStr.WriteText(InitialRequestText);
        end;

        Instance.Insert(true);
        exit(Instance.ID);
    end;

    /// <summary>
    /// Marks an instance as completed or failed.
    /// </summary>
    procedure CompleteInstance(InstanceId: Guid; NewStatus: Enum "Playbook Inst. Status ori"; StepsExecuted: Integer; StepsFailed: Integer; ItemsProcessed: Integer; ErrorText: Text)
    var
        Instance: Record "Playbook Instance ori";
    begin
        Instance.Get(InstanceId);
        Instance.Status := NewStatus;
        Instance."Completed At" := CurrentDateTime();
        Instance."Total Duration" := Instance."Completed At" - Instance."Started At";
        Instance."Steps Executed" := StepsExecuted;
        Instance."Steps Failed" := StepsFailed;
        Instance."Items Processed" := ItemsProcessed;
        Instance."Error Text" := CopyStr(ErrorText, 1, MaxStrLen(Instance."Error Text"));
        Instance.Modify(true);
    end;

    /// <summary>
    /// The Error Text of a failed step: the first of its Failed log rows (the lowest iteration) that has one.
    /// </summary>
    /// <param name="InstanceId">The playbook instance.</param>
    /// <param name="StepNo">The step.</param>
    /// <returns>The step's error text, or empty when the step logged none.</returns>
    procedure GetStepErrorText(InstanceId: Guid; StepNo: Integer): Text
    var
        StepLog: Record "Playbook Step Log ori";
    begin
        StepLog.SetLoadFields("Error Text");
        StepLog.SetRange("Instance ID", InstanceId);
        StepLog.SetRange("Step No.", StepNo);
        StepLog.SetRange(Status, StepLog.Status::Failed);
        StepLog.SetFilter("Error Text", '<>%1', '');
        if StepLog.FindFirst() then
            exit(StepLog."Error Text");
        exit('');
    end;

    /// <summary>
    /// The number of the first step of an instance that logged a Failed row, or 0.
    /// </summary>
    /// <param name="InstanceId">The playbook instance.</param>
    /// <returns>The lowest failed step number, or 0.</returns>
    procedure GetFirstFailedStepNo(InstanceId: Guid): Integer
    var
        StepLog: Record "Playbook Step Log ori";
    begin
        StepLog.SetLoadFields("Step No.");
        StepLog.SetRange("Instance ID", InstanceId);
        StepLog.SetRange(Status, StepLog.Status::Failed);
        if StepLog.FindFirst() then
            exit(StepLog."Step No.");
        exit(0);
    end;

    /// <summary>
    /// Logs a single step execution (one Dispatcher call).
    /// </summary>
    procedure LogStep(InstanceId: Guid; StepNo: Integer; IterationNo: Integer; MessageType: Enum "Message Type ori"; RequestText: Text; ResponseText: Text; StepDuration: Duration; StepStatus: Enum "Playbook Inst. Status ori"; ErrorText: Text; ElementText: Text; WorkspaceText: Text)
    begin
        LogStep(InstanceId, StepNo, IterationNo, MessageType, RequestText, ResponseText, StepDuration, StepStatus, ErrorText, ElementText, WorkspaceText, '');
    end;

    /// <summary>
    /// Logs a single step execution with the line a step that confirms from the preview writes (issue #189).
    /// </summary>
    /// <param name="ConfirmationNote">The preview count and the confirmed count, or the refusal; empty for an ordinary step.</param>
    procedure LogStep(InstanceId: Guid; StepNo: Integer; IterationNo: Integer; MessageType: Enum "Message Type ori"; RequestText: Text; ResponseText: Text; StepDuration: Duration; StepStatus: Enum "Playbook Inst. Status ori"; ErrorText: Text; ElementText: Text; WorkspaceText: Text; ConfirmationNote: Text)
    var
        StepLog: Record "Playbook Step Log ori";
        Instance: Record "Playbook Instance ori";
        Step: Record "Playbook Step ori";
    begin
        StepLog.Init();
        Instance.SetLoadFields("Playbook Code");
        Step.SetLoadFields("Step Kind");
        if Instance.Get(InstanceId) then
            if Step.Get(Instance."Playbook Code", StepNo) then
                StepLog."Step Kind" := Step."Step Kind";
        StepLog."Instance ID" := InstanceId;
        StepLog."Step No." := StepNo;
        StepLog."Iteration No." := IterationNo;
        StepLog."Message Type" := MessageType;
        StepLog.Status := StepStatus;
        StepLog.Duration := StepDuration;
        StepLog."Error Text" := CopyStr(ErrorText, 1, MaxStrLen(StepLog."Error Text"));
        StepLog."Confirmation Note" := CopyStr(ConfirmationNote, 1, MaxStrLen(StepLog."Confirmation Note"));

        if RequestText <> '' then
            StepLog.SetRequestSent(RequestText);
        if ResponseText <> '' then
            StepLog.SetResponseReceived(ResponseText);
        if ElementText <> '' then
            StepLog.SetIteratorElement(ElementText);
        if (WorkspaceText <> '') and (StepStatus = StepStatus::Failed) then
            StepLog.SetWorkspaceSnapshot(WorkspaceText);

        StepLog.Insert(true);
    end;
}
