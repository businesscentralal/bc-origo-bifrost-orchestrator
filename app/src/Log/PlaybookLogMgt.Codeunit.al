/// <summary>
/// CRUD helpers for playbook instance and step log records.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035549 "Playbook Log Mgt ori"
{
    Access = Internal;
    Permissions = tabledata "Playbook ori" = RM,
                  tabledata "Playbook Instance ori" = RIMD,
                  tabledata "Playbook Step Log ori" = RIMD;

    var
        AbandonedErr: Label 'Closed as abandoned: the run was still Running %1 hours after it started and never wrote its own completion.', Comment = '%1 = hours since the run started, is-IS=Lokað sem yfirgefið: keyrslan var enn í gangi %1 klukkustundum eftir að hún hófst og skráði aldrei lok sín.';
        RedactedTok: Label '[redacted]', Locked = true;
        SecretMarkersTok: Label 'password,secret,apikey,api_key,authorization,bearer,credential,accesstoken,refreshtoken,access_token,refresh_token', Locked = true;

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
    /// Closes instances that are still Running long after they started as Failed, with an error text and
    /// Completed At. Nothing is deleted; the step log rows stay. A playbook header that still points at a
    /// closed instance is corrected to Failed. Only instances in the record's current filter are touched.
    /// </summary>
    /// <param name="Instance">The instances to look at (filters are kept).</param>
    /// <param name="OlderThanHours">Only instances that started more than this many hours ago are closed.</param>
    /// <returns>The number of instances closed.</returns>
    procedure CloseAbandonedInstances(var Instance: Record "Playbook Instance ori"; OlderThanHours: Integer): Integer
    var
        Candidate: Record "Playbook Instance ori";
        Playbook: Record "Playbook ori";
        Closed: Integer;
    begin
        Candidate.CopyFilters(Instance);
        Candidate.SetRange(Status, Candidate.Status::Running);
        Candidate.SetFilter("Started At", '<%1', CurrentDateTime() - OlderThanHours * 3600000L);
        if Candidate.FindSet(true) then
            repeat
                Candidate.Status := Candidate.Status::Failed;
                Candidate."Completed At" := CurrentDateTime();
                Candidate."Total Duration" := Candidate."Completed At" - Candidate."Started At";
                Candidate."Error Text" := CopyStr(StrSubstNo(AbandonedErr, OlderThanHours), 1, MaxStrLen(Candidate."Error Text"));
                Candidate.Modify(true);
                if Playbook.Get(Candidate."Playbook Code") then
                    if (Playbook."Last Run Instance ID" = Candidate.ID) and (Playbook."Last Run Status" = Playbook."Last Run Status"::Running) then begin
                        Playbook."Last Run Status" := Playbook."Last Run Status"::Failed;
                        Playbook.Modify();
                    end;
                Closed += 1;
            until Candidate.Next() = 0;
        exit(Closed);
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
    /// The response as JSON: JSON text is kept as it is, a plain-text answer becomes {"status":"Error","error":"..."}.
    /// </summary>
    local procedure AsJsonResponse(ResponseText: Text; IsError: Boolean): Text
    var
        Token: JsonToken;
        Wrapped: JsonObject;
        Result: Text;
    begin
        if Token.ReadFrom(ResponseText) then
            if Token.IsObject() or Token.IsArray() then
                exit(ResponseText);
        if IsError then begin
            Wrapped.Add('status', 'Error');
            Wrapped.Add('error', ResponseText);
        end else begin
            Wrapped.Add('status', 'Success');
            Wrapped.Add('result', ResponseText);
        end;
        Wrapped.WriteTo(Result);
        exit(Result);
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
    begin
        LogStep(InstanceId, StepNo, IterationNo, MessageType, RequestText, ResponseText, StepDuration, StepStatus, ErrorText, ElementText, WorkspaceText, ConfirmationNote, '');
    end;

    /// <summary>
    /// Logs a single step execution with an outcome note (issue #218). An outcome that is not an error, such as a
    /// Check that answered no, goes in the note and never in Error Text. Response Received is always JSON: a
    /// plain-text error answer is stored as {"status":"Error","error":"..."}.
    /// </summary>
    /// <param name="OutcomeNote">The non-error outcome of the step, or empty.</param>
    procedure LogStep(InstanceId: Guid; StepNo: Integer; IterationNo: Integer; MessageType: Enum "Message Type ori"; RequestText: Text; ResponseText: Text; StepDuration: Duration; StepStatus: Enum "Playbook Inst. Status ori"; ErrorText: Text; ElementText: Text; WorkspaceText: Text; ConfirmationNote: Text; OutcomeNote: Text)
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
        StepLog."Outcome Note" := CopyStr(OutcomeNote, 1, MaxStrLen(StepLog."Outcome Note"));

        if RequestText <> '' then
            StepLog.SetRequestSent(RequestText);
        if ResponseText <> '' then
            StepLog.SetResponseReceived(AsJsonResponse(ResponseText, (StepStatus = StepStatus::Failed) or (ErrorText <> '')));
        if ElementText <> '' then
            StepLog.SetIteratorElement(ElementText);
        if (WorkspaceText <> '') and (StepStatus = StepStatus::Failed) then
            StepLog.SetWorkspaceSnapshot(RedactWorkspaceSnapshot(WorkspaceText));

        StepLog.Insert(true);
    end;

    /// <summary>
    /// Removes personal data and secret-like values from a workspace document before it is stored in a
    /// long-lived step log (issue #216). The whole <c>_who</c> context (user, salesperson, company contact
    /// data, Telegram chat ID, notifications, approvals, system prompt) is replaced by a marker, <c>_sys.userId</c>
    /// is masked, and any property whose name looks like a secret is masked at every depth. Step results
    /// (<c>_steps</c>), <c>_run</c>, <c>_initial</c> and the other <c>_sys</c> values stay, so a failed step
    /// can still be debugged.
    /// </summary>
    /// <param name="WorkspaceText">The serialised workspace JSON.</param>
    /// <returns>Text. The redacted JSON, or the original text when it is not a JSON object.</returns>
    internal procedure RedactWorkspaceSnapshot(WorkspaceText: Text): Text
    var
        Root: JsonObject;
        SysToken: JsonToken;
        Result: Text;
    begin
        if not Root.ReadFrom(WorkspaceText) then
            exit(WorkspaceText);
        if Root.Contains('_who') then begin
            Root.Remove('_who');
            Root.Add('_who', RedactedTok);
        end;
        if Root.Get('_sys', SysToken) then
            if SysToken.IsObject() then
                if SysToken.AsObject().Contains('userId') then begin
                    SysToken.AsObject().Remove('userId');
                    SysToken.AsObject().Add('userId', RedactedTok);
                end;
        MaskSecretLikeKeys(Root);
        Root.WriteTo(Result);
        exit(Result);
    end;

    local procedure MaskSecretLikeKeys(var Node: JsonObject)
    var
        Child: JsonToken;
        Element: JsonToken;
        ChildArray: JsonArray;
        ChildObject: JsonObject;
        KeyName: Text;
        Keys: List of [Text];
    begin
        Keys := Node.Keys();
        foreach KeyName in Keys do begin
            Node.Get(KeyName, Child);
            if IsSecretLikeKey(KeyName) and Child.IsValue() then begin
                if not Child.AsValue().IsNull() then
                    Node.Replace(KeyName, RedactedTok);
                continue;
            end;
            if Child.IsObject() then begin
                ChildObject := Child.AsObject();
                MaskSecretLikeKeys(ChildObject);
            end else
                if Child.IsArray() then begin
                    ChildArray := Child.AsArray();
                    foreach Element in ChildArray do
                        if Element.IsObject() then begin
                            ChildObject := Element.AsObject();
                            MaskSecretLikeKeys(ChildObject);
                        end;
                end;
        end;
    end;

    local procedure IsSecretLikeKey(KeyName: Text): Boolean
    var
        Marker: Text;
        Lower: Text;
    begin
        Lower := KeyName.ToLower();
        foreach Marker in SecretMarkersTok.Split(',') do
            if Lower.Contains(Marker) then
                exit(true);
        exit(false);
    end;
}
