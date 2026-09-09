/// <summary>
/// Playbook orchestrator. Reads a playbook definition, executes steps in sequence,
/// handles foreach iteration over response arrays, applies bindings between steps,
/// evaluates success conditions, and logs all execution detail.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.Utilities;

codeunit 10035547 "Playbook Runner ori"
{
    Access = Internal;
    Permissions = tabledata "Playbook ori" = R,
                  tabledata "Playbook Step ori" = R,
                  tabledata "Playbook Condition ori" = R,
                  tabledata "Playbook Instance ori" = RIMD,
                  tabledata "Playbook Step Log ori" = RIMD;

    var
        JsonHelper: Codeunit "Playbook JSON Helper ori";
        LogMgt: Codeunit "Playbook Log Mgt ori";
        Workspace: Codeunit "Playbook Workspace ori";
        PlaybookNotFoundErr: Label 'Playbook %1 not found.', Comment = '%1 = playbook code, is-IS=Keðja %1 fannst ekki.';
        StepNotFoundErr: Label 'Step %1 not found in playbook %2.', Comment = '%1 = step no, %2 = playbook code, is-IS=Skref %1 fannst ekki í keðju %2.';
        MaxIterationsErr: Label 'Step %1 exceeded max iterations (%2).', Comment = '%1 = step no, %2 = max, is-IS=Skref %1 fór yfir hámarksfjölda ítrana (%2).';
        SkippedByStartCondTok: Label 'Skipped: start conditions not met.', Comment = 'is-IS=Sleppt: upphafsskilyrði ekki uppfyllt.';
        PerItemResults: Dictionary of [Text, Boolean];
        PageItemOffset: Integer;
        CurrentPageNo: Integer;
        RunStartTime: DateTime;

    /// <summary>
    /// Runs a playbook to completion.
    /// </summary>
    /// <param name="PlaybookCode">The playbook to execute.</param>
    /// <param name="InitialRequest">Initial request parameters as BigText (JSON). Can be empty.</param>
    /// <param name="FinalResponse">Receives the last step's response as BigText.</param>
    /// <param name="InstanceId">Receives the execution instance ID.</param>
    procedure Run(PlaybookCode: Code[20]; var InitialRequest: BigText; var FinalResponse: BigText; var InstanceId: Guid)
    var
        Playbook: Record "Playbook ori";
        PlaybookStep: Record "Playbook Step ori";
        ChainEndStep: Record "Playbook Step ori";
        ResponseStore: Dictionary of [Integer, JsonObject];
        InitialRequestText: Text;
        LastResponseText: Text;
        StepsExecuted: Integer;
        StepsFailed: Integer;
        ItemsProcessed: Integer;
        NextStepNo: Integer;
        StepSuccess: Boolean;
        PlaybookFailed: Boolean;
    begin
        if not Playbook.Get(PlaybookCode) then
            Error(PlaybookNotFoundErr, PlaybookCode);

        InitialRequestText := BigTextToText(InitialRequest);
        if InitialRequestText = '' then
            InitialRequestText := Playbook.GetInitialRequestTemplate();

        Workspace.Reset();
        StoreInitialRequest(InitialRequestText);
        InstanceId := LogMgt.CreateInstance(PlaybookCode, InitialRequestText);
        RunStartTime := CurrentDateTime();
        Workspace.BeginRun(PlaybookCode, Playbook.Description, InstanceId);

        // Find first step
        PlaybookStep.SetRange("Playbook Code", PlaybookCode);
        PlaybookStep.SetCurrentKey("Playbook Code", "Step No.");
        if not PlaybookStep.FindFirst() then begin
            LogMgt.CompleteInstance(InstanceId, "Playbook Inst. Status ori"::Completed, 0, 0, 0, '');
            exit;
        end;

        NextStepNo := PlaybookStep."Step No.";

        // Step loop
        while NextStepNo > 0 do begin
            if not PlaybookStep.Get(PlaybookCode, NextStepNo) then
                Error(StepNotFoundErr, NextStepNo, PlaybookCode);

            if PlaybookStep.Disabled then
                NextStepNo := PlaybookStep."Next Step No. (Success)"
            else
                if not StartConditionsHold(PlaybookStep) then begin
                    RecordSkippedStep(PlaybookStep, InstanceId);
                    NextStepNo := PlaybookStep."Next Step No. (Success)";
                end else begin
                    if PlaybookStep.Paged then begin
                        ExecutePagedBlock(PlaybookStep, InstanceId, InitialRequestText, ResponseStore, StepSuccess, StepsExecuted, StepsFailed, ItemsProcessed, LastResponseText);
                        if StepSuccess then
                            if PlaybookStep."Page Through Step No." > 0 then
                                if ChainEndStep.Get(PlaybookCode, PlaybookStep."Page Through Step No.") then
                                    PlaybookStep := ChainEndStep;
                    end else
                        ExecuteStep(PlaybookStep, InstanceId, InitialRequestText, ResponseStore, StepSuccess, StepsExecuted, StepsFailed, ItemsProcessed, LastResponseText);

                    if StepSuccess then
                        NextStepNo := PlaybookStep."Next Step No. (Success)"
                    else
                        NextStepNo := PlaybookStep."Next Step No. (Failure)";
                end;
        end;

        Workspace.CompleteRun(CurrentDateTime() - RunStartTime);
        PlaybookFailed := Workspace.RunFailed();
        if PlaybookFailed then
            LogMgt.CompleteInstance(InstanceId, "Playbook Inst. Status ori"::Failed, StepsExecuted, StepsFailed, ItemsProcessed, '')
        else
            LogMgt.CompleteInstance(InstanceId, "Playbook Inst. Status ori"::Completed, StepsExecuted, StepsFailed, ItemsProcessed, '');

        TextToBigText(LastResponseText, FinalResponse);
    end;

    /// <summary>Runs a playbook starting from a specific step, using pre-loaded ResponseStore entries.</summary>
    procedure Run(PlaybookCode: Code[20]; var InitialRequest: BigText; var FinalResponse: BigText; var InstanceId: Guid; StartStepNo: Integer)
    var
        Playbook: Record "Playbook ori";
        PlaybookStep: Record "Playbook Step ori";
        ChainEndStep: Record "Playbook Step ori";
        ResponseStore: Dictionary of [Integer, JsonObject];
        InitialRequestText: Text;
        LastResponseText: Text;
        StepsExecuted: Integer;
        StepsFailed: Integer;
        ItemsProcessed: Integer;
        NextStepNo: Integer;
        StepSuccess: Boolean;
        PlaybookFailed: Boolean;
    begin
        if not Playbook.Get(PlaybookCode) then
            Error(PlaybookNotFoundErr, PlaybookCode);

        InitialRequestText := BigTextToText(InitialRequest);
        if InitialRequestText = '' then
            InitialRequestText := Playbook.GetInitialRequestTemplate();

        Workspace.Reset();
        StoreInitialRequest(InitialRequestText);
        InstanceId := LogMgt.CreateInstance(PlaybookCode, InitialRequestText);
        RunStartTime := CurrentDateTime();
        Workspace.BeginRun(PlaybookCode, Playbook.Description, InstanceId);

        NextStepNo := StartStepNo;

        while NextStepNo > 0 do begin
            if not PlaybookStep.Get(PlaybookCode, NextStepNo) then
                Error(StepNotFoundErr, NextStepNo, PlaybookCode);

            if PlaybookStep.Disabled then
                NextStepNo := PlaybookStep."Next Step No. (Success)"
            else
                if not StartConditionsHold(PlaybookStep) then begin
                    RecordSkippedStep(PlaybookStep, InstanceId);
                    NextStepNo := PlaybookStep."Next Step No. (Success)";
                end else begin
                    if PlaybookStep.Paged then begin
                        ExecutePagedBlock(PlaybookStep, InstanceId, InitialRequestText, ResponseStore, StepSuccess, StepsExecuted, StepsFailed, ItemsProcessed, LastResponseText);
                        if StepSuccess then
                            if PlaybookStep."Page Through Step No." > 0 then
                                if ChainEndStep.Get(PlaybookCode, PlaybookStep."Page Through Step No.") then
                                    PlaybookStep := ChainEndStep;
                    end else
                        ExecuteStep(PlaybookStep, InstanceId, InitialRequestText, ResponseStore, StepSuccess, StepsExecuted, StepsFailed, ItemsProcessed, LastResponseText);

                    if StepSuccess then
                        NextStepNo := PlaybookStep."Next Step No. (Success)"
                    else
                        NextStepNo := PlaybookStep."Next Step No. (Failure)";
                end;
        end;

        Workspace.CompleteRun(CurrentDateTime() - RunStartTime);
        PlaybookFailed := Workspace.RunFailed();
        if PlaybookFailed then
            LogMgt.CompleteInstance(InstanceId, "Playbook Inst. Status ori"::Failed, StepsExecuted, StepsFailed, ItemsProcessed, '')
        else
            LogMgt.CompleteInstance(InstanceId, "Playbook Inst. Status ori"::Completed, StepsExecuted, StepsFailed, ItemsProcessed, '');

        TextToBigText(LastResponseText, FinalResponse);
    end;

    local procedure ExecutePagedBlock(PagedStep: Record "Playbook Step ori"; InstanceId: Guid; InitialRequestText: Text; var ResponseStore: Dictionary of [Integer, JsonObject]; var StepSuccess: Boolean; var StepsExecuted: Integer; var StepsFailed: Integer; var ItemsProcessed: Integer; var LastResponseText: Text)
    var
        ChainStep: Record "Playbook Step ori";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        BaseRequestText: Text;
        PagedRequestText: Text;
        CurrentSkip: Integer;
        PageSize: Integer;
        TotalRecords: Integer;
        PageNo: Integer;
        ChainStepNo: Integer;
        ChainSuccess: Boolean;
        PageResponseText: Text;
        PageErrorText: Text;
        PageSuccess: Boolean;
        PageStepStatus: Enum "Playbook Inst. Status ori";
        StartTime: DateTime;
    begin
        PageSize := PagedStep."Page Size";
        if PageSize <= 0 then
            PageSize := 500;
        CurrentSkip := 0;
        PageNo := 0;
        StepSuccess := true;

        // Resolve the step's request template as the base for paging
        BaseRequestText := PagedStep.GetRequestTemplate();
        if BaseRequestText = '' then
            BaseRequestText := InitialRequestText;

        repeat
            // Build paged request from step template, injecting skip/take
            Clear(RequestJson);
            if BaseRequestText <> '' then
                RequestJson.ReadFrom(BaseRequestText);
            JsonHelper.ResolveWorkspaceRefs(RequestJson);
            if RequestJson.Contains('skip') then RequestJson.Remove('skip');
            if RequestJson.Contains('take') then RequestJson.Remove('take');
            RequestJson.Add('skip', CurrentSkip);
            RequestJson.Add('take', PageSize);
            RequestJson.WriteTo(PagedRequestText);

            // Execute the paged data step directly (not through ExecuteStep to control logging)
            StartTime := CurrentDateTime();
            ExecuteMessageType(PagedStep."Message Type", PagedRequestText, PageResponseText, PageSuccess, PageErrorText);
            StepsExecuted += 1;
            if not PageSuccess then
                StepsFailed += 1;

            if PageSuccess then
                PageStepStatus := "Playbook Inst. Status ori"::Completed
            else
                PageStepStatus := "Playbook Inst. Status ori"::Failed;

            LogMgt.LogStep(InstanceId, PagedStep."Step No.", PageNo, PagedStep."Message Type",
                PagedRequestText, PageResponseText, CurrentDateTime() - StartTime,
                PageStepStatus, PageErrorText, '', Workspace.ToText());
            Workspace.RecordPage(PagedStep."Step No.", PagedStep."Exclude From Run Status");
            RecordStepOutcome(PagedStep, Workspace.StatusToText(PageStepStatus), false, false,
                CurrentDateTime() - StartTime, PageErrorText, PageResponseText, 0, 0);

            // Store response for downstream bindings
            if (PageResponseText <> '') and ResponseJson.ReadFrom(PageResponseText) then
                if ResponseStore.ContainsKey(PagedStep."Step No.") then
                    ResponseStore.Set(PagedStep."Step No.", ResponseJson)
                else
                    ResponseStore.Add(PagedStep."Step No.", ResponseJson);
            Workspace.WriteFromResponse(PagedStep."Step No.", PageNo, true, PageResponseText, PagedStep."Result Log Paths");

            if not PageSuccess then begin
                StepSuccess := false;
                exit;
            end;

            // Get total record count from response
            TotalRecords := 0;
            if ResponseStore.ContainsKey(PagedStep."Step No.") then begin
                ResponseJson := ResponseStore.Get(PagedStep."Step No.");
                TotalRecords := GetIntFromJson(ResponseJson, 'noOfRecords');
            end;

            // Execute downstream chain
            if PagedStep."Next Step No. (Success)" > 0 then begin
                PageItemOffset := CurrentSkip;
                CurrentPageNo := PageNo;
                ChainStepNo := PagedStep."Next Step No. (Success)";
                while (ChainStepNo > 0) and (ChainStepNo <= PagedStep."Page Through Step No.") do begin
                    if not ChainStep.Get(PagedStep."Playbook Code", ChainStepNo) then
                        Error(StepNotFoundErr, ChainStepNo, PagedStep."Playbook Code");
                    ExecuteStep(ChainStep, InstanceId, '', ResponseStore, ChainSuccess, StepsExecuted, StepsFailed, ItemsProcessed, LastResponseText);
                    if ChainSuccess then
                        ChainStepNo := ChainStep."Next Step No. (Success)"
                    else
                        ChainStepNo := ChainStep."Next Step No. (Failure)";
                end;
            end;

            // Clear per-item results for next page
            Clear(PerItemResults);
            PageItemOffset := 0;
            CurrentPageNo := 0;

            CurrentSkip += PageSize;
            PageNo += 1;
        until CurrentSkip >= TotalRecords;
    end;

    local procedure GetIntFromJson(JObj: JsonObject; FieldName: Text): Integer
    var
        Token: JsonToken;
    begin
        if JObj.Get(FieldName, Token) then
            if Token.IsValue() then
                exit(Token.AsValue().AsInteger());
        exit(0);
    end;

    local procedure ExecuteStep(PlaybookStep: Record "Playbook Step ori"; InstanceId: Guid; InitialRequestText: Text; var ResponseStore: Dictionary of [Integer, JsonObject]; var StepSuccess: Boolean; var StepsExecuted: Integer; var StepsFailed: Integer; var ItemsProcessed: Integer; var LastResponseText: Text)
    begin
        if PlaybookStep.IsForEach() then
            ExecuteForEachStep(PlaybookStep, InstanceId, ResponseStore, StepSuccess, StepsExecuted, StepsFailed, ItemsProcessed, LastResponseText)
        else
            ExecuteSingleStep(PlaybookStep, InstanceId, InitialRequestText, ResponseStore, StepSuccess, StepsExecuted, StepsFailed, LastResponseText);
    end;

    local procedure ExecuteSingleStep(PlaybookStep: Record "Playbook Step ori"; InstanceId: Guid; InitialRequestText: Text; var ResponseStore: Dictionary of [Integer, JsonObject]; var StepSuccess: Boolean; var StepsExecuted: Integer; var StepsFailed: Integer; var LastResponseText: Text)
    var
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        RequestText: Text;
        ResponseText: Text;
        ErrorText: Text;
        StartTime: DateTime;
        StepDuration: Duration;
        StepStatus: Enum "Playbook Inst. Status ori";
        ConditionHolds: Boolean;
        CheckAnswered: Boolean;
        TechnicalFailure: Boolean;
    begin
        // Build request from template or initial request
        RequestText := PlaybookStep.GetRequestTemplate();
        if RequestText = '' then
            RequestText := InitialRequestText;
        if RequestText <> '' then
            RequestJson.ReadFrom(RequestText);

        JsonHelper.ResolveWorkspaceRefs(RequestJson);
        RequestJson.WriteTo(RequestText);

        StartTime := CurrentDateTime();
        ExecuteMessageType(PlaybookStep."Message Type", RequestText, ResponseText, StepSuccess, ErrorText);
        StepDuration := CurrentDateTime() - StartTime;

        // Store response for downstream bindings
        if (ResponseText <> '') and ResponseJson.ReadFrom(ResponseText) then begin
            if ResponseStore.ContainsKey(PlaybookStep."Step No.") then
                ResponseStore.Set(PlaybookStep."Step No.", ResponseJson)
            else
                ResponseStore.Add(PlaybookStep."Step No.", ResponseJson);

            // Evaluate success conditions before logging
            if StepSuccess and PlaybookStep.HasConditions("Playbook Cond. Type ori"::Success) then begin
                ConditionHolds := JsonHelper.EvaluateConditionSet(ResponseJson, PlaybookStep."Playbook Code",
                    PlaybookStep."Step No.", "Playbook Cond. Type ori"::Success);
                CheckAnswered := true;
                StepSuccess := ConditionHolds;
            end;
        end;

        // A Check step answers a question. A false condition routes down the failure
        // path exactly as before, but it is not a failure and must not fail the run.
        TechnicalFailure := not StepSuccess and not (PlaybookStep.IsCheck() and CheckAnswered);

        StepsExecuted += 1;
        if not TechnicalFailure then
            StepStatus := "Playbook Inst. Status ori"::Completed
        else begin
            StepStatus := "Playbook Inst. Status ori"::Failed;
            StepsFailed += 1;
        end;

        LogMgt.LogStep(InstanceId, PlaybookStep."Step No.", CurrentPageNo, PlaybookStep."Message Type",
            RequestText, ResponseText, StepDuration, StepStatus, ErrorText, '', Workspace.ToText());
        Workspace.WriteFromResponse(PlaybookStep."Step No.", CurrentPageNo, false, ResponseText, PlaybookStep."Result Log Paths");

        RecordStepOutcome(PlaybookStep, Workspace.StatusToText(StepStatus), PlaybookStep.IsCheck() and CheckAnswered, ConditionHolds, StepDuration, ErrorText, ResponseText, 0, 0);
        ApplyErrorConditions(PlaybookStep);

        LastResponseText := ResponseText;
    end;

    local procedure ExecuteForEachStep(PlaybookStep: Record "Playbook Step ori"; InstanceId: Guid; var ResponseStore: Dictionary of [Integer, JsonObject]; var StepSuccess: Boolean; var StepsExecuted: Integer; var StepsFailed: Integer; var ItemsProcessed: Integer; var LastResponseText: Text)
    var
        SourceResponseJson: JsonObject;
        ItemsArray: JsonArray;
        ElementToken: JsonToken;
        ElementObj: JsonObject;
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        RequestText: Text;
        ResponseText: Text;
        RequestTemplate: Text;
        ElementText: Text;
        ErrorText: Text;
        StartTime: DateTime;
        StepDuration: Duration;
        StepStatus: Enum "Playbook Inst. Status ori";
        i: Integer;
        ItemSuccess: Boolean;
        AnyFailed: Boolean;
        ItemOutcome: Text;
        AggregateStatus: Text;
        ItemsHere: Integer;
        ItemsFailedHere: Integer;
    begin
        StepSuccess := true;
        RequestTemplate := PlaybookStep.GetRequestTemplate();

        // Get the source array
        if not ResponseStore.ContainsKey(PlaybookStep."Iterate Source Step No.") then begin
            StepSuccess := false;
            exit;
        end;

        SourceResponseJson := ResponseStore.Get(PlaybookStep."Iterate Source Step No.");
        if not JsonHelper.ExtractArray(SourceResponseJson, PlaybookStep."Iterate Array Path", ItemsArray) then begin
            StepSuccess := true; // Empty array = nothing to do, not a failure
            exit;
        end;

        // Iterate
        for i := 0 to ItemsArray.Count() - 1 do begin
            if i >= 10000 then begin
                LogMgt.LogStep(InstanceId, PlaybookStep."Step No.", PageItemOffset + i, PlaybookStep."Message Type",
                    '', '', 0, "Playbook Inst. Status ori"::Cancelled, StrSubstNo(MaxIterationsErr, PlaybookStep."Step No.", 10000), '', Workspace.ToText());
                StepSuccess := false;
                exit;
            end;

            // Skip if a prior step's same iteration failed
            if (PlaybookStep."Skip If Step Failed" <> 0) and
               not GetIterationSuccess(PlaybookStep."Skip If Step Failed", PageItemOffset + i)
            then begin
                ItemsArray.Get(i, ElementToken);
                ElementToken.WriteTo(ElementText);
                LogMgt.LogStep(InstanceId, PlaybookStep."Step No.", PageItemOffset + i, PlaybookStep."Message Type",
                    '', '', 0, "Playbook Inst. Status ori"::Cancelled, 'Skipped: prior step failed for this item.', ElementText, Workspace.ToText());
                Workspace.RecordIteration(PlaybookStep."Step No.", PageItemOffset + i, 'Skipped', ElementToken, '',
                    PlaybookStep."Exclude From Run Status");
            end else begin

                ItemsArray.Get(i, ElementToken);
                if ElementToken.IsObject() then
                    ElementObj := ElementToken.AsObject()
                else
                    Clear(ElementObj);

                ElementToken.WriteTo(ElementText);

                // Store current element and iteration index for template resolution
                Workspace.SetToken('_current', ElementToken);
                Workspace.SetValue('_iter', Format(PageItemOffset + i));

                // Build request from template
                Clear(RequestJson);
                if RequestTemplate <> '' then
                    RequestJson.ReadFrom(RequestTemplate);
                JsonHelper.ResolveWorkspaceRefs(RequestJson);
                RequestJson.WriteTo(RequestText);

                StartTime := CurrentDateTime();
                ExecuteMessageType(PlaybookStep."Message Type", RequestText, ResponseText, ItemSuccess, ErrorText);
                StepDuration := CurrentDateTime() - StartTime;

                StepsExecuted += 1;
                ItemsProcessed += 1;

                if ItemSuccess then
                    StepStatus := "Playbook Inst. Status ori"::Completed
                else begin
                    StepStatus := "Playbook Inst. Status ori"::Failed;
                    StepsFailed += 1;
                    AnyFailed := true;
                end;

                if ItemSuccess then
                    ItemOutcome := 'Completed'
                else
                    ItemOutcome := 'Failed';

                // Evaluate condition on successful execution
                if ItemSuccess and PlaybookStep.HasConditions("Playbook Cond. Type ori"::Success) then begin
                    Clear(ResponseJson);
                    if (ResponseText <> '') and ResponseJson.ReadFrom(ResponseText) then
                        if not JsonHelper.EvaluateConditionSet(ResponseJson, PlaybookStep."Playbook Code",
                            PlaybookStep."Step No.", "Playbook Cond. Type ori"::Success) then begin
                            StepStatus := "Playbook Inst. Status ori"::Cancelled;
                            ItemSuccess := false;
                            ItemOutcome := 'CheckFailed';
                        end;
                end;

                LogMgt.LogStep(InstanceId, PlaybookStep."Step No.", PageItemOffset + i, PlaybookStep."Message Type",
                    RequestText, ResponseText, StepDuration, StepStatus, ErrorText, ElementText, Workspace.ToText());
                SetIterationSuccess(PlaybookStep."Step No.", PageItemOffset + i, ItemSuccess);
                Workspace.WriteFromResponse(PlaybookStep."Step No.", PageItemOffset + i, true, ResponseText, PlaybookStep."Result Log Paths");
                Workspace.SetToken(Format(PlaybookStep."Step No.") + '.' + Format(PageItemOffset + i) + '._item', ElementToken);
                Workspace.RecordIteration(PlaybookStep."Step No.", PageItemOffset + i, ItemOutcome, ElementToken,
                    ErrorText, PlaybookStep."Exclude From Run Status");
                Workspace.RecordStepSummary(PlaybookStep."Step No.", ResponseText, PlaybookStep."Summary Paths",
                    PlaybookStep."Exclude From Run Status");
                if ItemOutcome = 'Failed' then
                    ItemsFailedHere += 1;
                ItemsHere += 1;

                if not ItemSuccess and PlaybookStep."Stop On Item Error" then begin
                    StepSuccess := false;
                    exit;
                end;
            end; // else (not skipped)
        end;

        // Store aggregate: the source response stays in the store, not individual iterations
        StepSuccess := not AnyFailed or not PlaybookStep."Stop On Item Error";

        if AnyFailed then
            AggregateStatus := 'Failed'
        else
            AggregateStatus := 'Completed';
        RecordStepOutcome(PlaybookStep, AggregateStatus, false, false, 0, '', '', ItemsHere, ItemsFailedHere);
        ApplyErrorConditions(PlaybookStep);

        LastResponseText := ResponseText;
    end;

    local procedure ExecuteMessageType(MessageType: Enum "Message Type ori"; RequestText: Text; var ResponseText: Text; var StepSuccess: Boolean; var ErrorText: Text)
    var
        StepExecutor: Codeunit "Playbook Step Executor ori";
    begin
        Clear(ResponseText);
        ErrorText := '';
        Commit();
        StepSuccess := StepExecutor.Execute(MessageType, '', RequestText, ResponseText, ErrorText);
    end;

    /// <summary>
    /// Start conditions are evaluated against the workspace, before the step runs —
    /// unlike Success conditions, which see only the step's own response afterwards.
    /// </summary>
    local procedure StartConditionsHold(PlaybookStep: Record "Playbook Step ori"): Boolean
    begin
        if not PlaybookStep.HasConditions("Playbook Cond. Type ori"::Start) then
            exit(true);
        exit(JsonHelper.EvaluateConditionSet(Workspace.GetData(), PlaybookStep."Playbook Code",
            PlaybookStep."Step No.", "Playbook Cond. Type ori"::Start));
    end;

    /// <summary>
    /// A skipped step is Cancelled, never Failed — the run's failure total drives the
    /// instance status, and a skipped success-path report must not fail the playbook.
    /// </summary>
    local procedure RecordSkippedStep(PlaybookStep: Record "Playbook Step ori"; InstanceId: Guid)
    begin
        LogMgt.LogStep(InstanceId, PlaybookStep."Step No.", 0, PlaybookStep."Message Type",
            '', '', 0, "Playbook Inst. Status ori"::Cancelled, SkippedByStartCondTok, '', Workspace.ToText());
        Workspace.RecordStepSkipped(PlaybookStep."Step No.", PlaybookStep.Description,
            Workspace.MessageTypeToText(PlaybookStep."Message Type"), SkippedByStartCondTok, PlaybookStep."Exclude From Run Status");
        Workspace.RollUpRun(PlaybookStep."Step No.", 'Cancelled', 0, 0, PlaybookStep."Exclude From Run Status");
    end;

    local procedure RecordStepOutcome(PlaybookStep: Record "Playbook Step ori"; StatusText: Text; IsCheckAnswered: Boolean; CheckResult: Boolean; StepDuration: Duration; ErrorText: Text; ResponseText: Text; ItemsHere: Integer; ItemsFailedHere: Integer)
    begin
        Workspace.RecordStep(PlaybookStep."Step No.", PlaybookStep.Description, Workspace.MessageTypeToText(PlaybookStep."Message Type"),
            StatusText, IsCheckAnswered, CheckResult, StepDuration, ErrorText, PlaybookStep."Exclude From Run Status");
        Workspace.RecordStepSummary(PlaybookStep."Step No.", ResponseText, PlaybookStep."Summary Paths",
            PlaybookStep."Exclude From Run Status");
        Workspace.RollUpRun(PlaybookStep."Step No.", StatusText, ItemsHere, ItemsFailedHere,
            PlaybookStep."Exclude From Run Status");
    end;

    /// <summary>
    /// Error conditions fail the run without changing the branch — the step succeeded
    /// and the chain continues, but the outcome needs attention.
    /// </summary>
    local procedure ApplyErrorConditions(PlaybookStep: Record "Playbook Step ori")
    begin
        if not PlaybookStep.HasConditions("Playbook Cond. Type ori"::Error) then
            exit;
        if JsonHelper.EvaluateConditionSet(Workspace.GetData(), PlaybookStep."Playbook Code",
            PlaybookStep."Step No.", "Playbook Cond. Type ori"::Error)
        then
            Workspace.EscalateRunFailure(PlaybookStep."Step No.");
    end;

    local procedure SetIterationSuccess(StepNo: Integer; IterationNo: Integer; Success: Boolean)
    begin
        PerItemResults.Set(StrSubstNo('%1-%2', StepNo, IterationNo), Success);
    end;

    local procedure GetIterationSuccess(StepNo: Integer; IterationNo: Integer): Boolean
    var
        Result: Boolean;
    begin
        if PerItemResults.Get(StrSubstNo('%1-%2', StepNo, IterationNo), Result) then
            exit(Result);
        exit(false);
    end;

    local procedure BigTextToText(var BT: BigText): Text
    var
        Result: Text;
    begin
        if BT.Length() = 0 then
            exit('');
        BT.GetSubText(Result, 1);
        exit(Result);
    end;

    local procedure TextToBigText(Source: Text; var Target: BigText)
    begin
        Clear(Target);
        if Source <> '' then
            Target.AddText(Source);
    end;

    local procedure StoreInitialRequest(InitialRequestText: Text)
    var
        InitialJson: JsonObject;
    begin
        if InitialRequestText = '' then
            exit;
        if not InitialJson.ReadFrom(InitialRequestText) then
            exit;
        Workspace.SetToken('_initial', InitialJson.AsToken());
    end;
}
