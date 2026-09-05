/// <summary>
/// CRUD helpers for playbook instance and step log records.
/// </summary>
namespace Origo.Bifrost.Nornir;

using Origo.Bifrost;

codeunit 10035549 "Playbook Log Mgt ori"
{
    Access = Internal;
    Permissions = tabledata "Playbook Instance ori" = RIMD,
                  tabledata "Playbook Step Log ori" = RIMD;

    /// <summary>
    /// Creates a new playbook instance record and returns its ID.
    /// </summary>
    internal procedure CreateInstance(PlaybookCode: Code[20]; InitialRequestText: Text): Guid
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
    internal procedure CompleteInstance(InstanceId: Guid; NewStatus: Enum "Playbook Inst. Status ori"; StepsExecuted: Integer; StepsFailed: Integer; ItemsProcessed: Integer; ErrorText: Text)
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
    /// Logs a single step execution (one Dispatcher call).
    /// </summary>
    internal procedure LogStep(InstanceId: Guid; StepNo: Integer; IterationNo: Integer; MessageType: Enum "Message Type ori"; RequestText: Text; ResponseText: Text; StepDuration: Duration; StepStatus: Enum "Playbook Inst. Status ori"; ErrorText: Text; ElementText: Text; WorkspaceText: Text)
    var
        StepLog: Record "Playbook Step Log ori";
    begin
        StepLog.Init();
        StepLog."Instance ID" := InstanceId;
        StepLog."Step No." := StepNo;
        StepLog."Iteration No." := IterationNo;
        StepLog."Message Type" := MessageType;
        StepLog.Status := StepStatus;
        StepLog.Duration := StepDuration;
        StepLog."Error Text" := CopyStr(ErrorText, 1, MaxStrLen(StepLog."Error Text"));

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
