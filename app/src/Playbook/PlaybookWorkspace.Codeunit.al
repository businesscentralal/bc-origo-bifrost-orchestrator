/// <summary>
/// SingleInstance workspace for playbook execution. Holds a single JSON document
/// that steps write to and read from. Supports hierarchical dot-notation paths for
/// both storage and retrieval, preserving JSON types (values, objects, arrays).
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035583 "Playbook Workspace ori"
{
    Access = Internal;
    SingleInstance = true;

    var
        Data: JsonObject;

    /// <summary>
    /// Clears the workspace and seeds it for a new run. Because the codeunit is SingleInstance the
    /// document survives between runs in the same session, so every playbook has to start here.
    /// Seeding adds <c>_sys</c> (dates, company, user) and <c>_who</c> (the Help.WhoAmI.Get result),
    /// so steps can reference them without asking for them.
    /// </summary>
    procedure Reset()
    var
        EmptyObj: JsonObject;
    begin
        Data := EmptyObj;
        SeedSystemConstants();
        SeedWhoAmI();
    end;

    /// <summary>Sets a text value at a dot-notation path, creating intermediate objects as needed.</summary>
    procedure SetValue(Path: Text; Value: Text)
    var
        JValue: JsonValue;
    begin
        JValue.SetValue(Value);
        SetTokenAtPath(Path, JValue.AsToken());
    end;

    /// <summary>Sets a JSON token (object, array, or value) at a dot-notation path.</summary>
    procedure SetToken(Path: Text; Token: JsonToken)
    begin
        SetTokenAtPath(Path, Token);
    end;

    /// <summary>Gets a text value at a dot-notation path.</summary>
    procedure GetValue(Path: Text; var Result: Text): Boolean
    var
        Token: JsonToken;
    begin
        if not GetTokenAtPath(Path, Token) then
            exit(false);
        if Token.IsValue() then
            Result := Token.AsValue().AsText()
        else
            Token.WriteTo(Result);
        exit(true);
    end;

    /// <summary>Gets a raw JSON token at a dot-notation path, preserving type.</summary>
    procedure GetToken(Path: Text; var Token: JsonToken): Boolean
    begin
        exit(GetTokenAtPath(Path, Token));
    end;

    /// <summary>
    /// Returns the whole workspace document, including the <c>_run</c>, <c>_steps</c>, <c>_sys</c>
    /// and <c>_who</c> reporting keys.
    /// </summary>
    /// <returns>JsonObject. The workspace document as it stands.</returns>
    procedure GetData(): JsonObject
    begin
        exit(Data);
    end;

    /// <summary>
    /// Extracts fields from a step response and stores them in the workspace,
    /// keyed by step number (and iteration for forEach steps) — mirroring the
    /// step log's (StepNo, IterationNo) key structure.
    /// Single step: stored at &lt;StepNo&gt;.&lt;field&gt;.
    /// forEach/paged: stored at &lt;StepNo&gt;.&lt;IterationNo&gt;.&lt;field&gt;.
    /// PathMappings supports "source>target" to rename the field under the step key.
    /// </summary>
    procedure WriteFromResponse(StepNo: Integer; IterationNo: Integer; IsIterated: Boolean; ResponseText: Text; PathMappings: Text)
    var
        JsonHelper: Codeunit "Playbook JSON Helper ori";
        ResponseJson: JsonObject;
        ResolvedToken: JsonToken;
        MappingList: List of [Text];
        Mapping: Text;
        SourcePath: Text;
        FieldName: Text;
        FullTargetPath: Text;
        StepKey: Text;
        ArrowPos: Integer;
    begin
        if (ResponseText = '') or (PathMappings = '') then
            exit;
        if not ResponseJson.ReadFrom(ResponseText) then
            exit;

        StepKey := Format(StepNo);

        MappingList := PathMappings.Split(',');
        foreach Mapping in MappingList do begin
            Mapping := Mapping.Trim();
            ArrowPos := Mapping.IndexOf('>');
            if ArrowPos > 0 then begin
                SourcePath := CopyStr(Mapping, 1, ArrowPos - 1).Trim();
                FieldName := CopyStr(Mapping, ArrowPos + 1).Trim();
            end else begin
                SourcePath := Mapping;
                FieldName := Mapping.Replace('.', '_');
            end;

            if IsIterated then
                FullTargetPath := StepKey + '.' + Format(IterationNo) + '.' + FieldName
            else
                FullTargetPath := StepKey + '.' + FieldName;

            if JsonHelper.ResolveJsonPath(ResponseJson, SourcePath, ResolvedToken) then
                SetTokenAtPath(FullTargetPath, ResolvedToken);
        end;
    end;

    /// <summary>
    /// Serialises the whole workspace to JSON. This is everything the steps collected, so it can be
    /// large — use <c>ToFilteredText</c> when only some step keys are wanted.
    /// </summary>
    /// <returns>Text. The workspace document as JSON.</returns>
    procedure ToText(): Text
    var
        Result: Text;
    begin
        Data.WriteTo(Result);
        exit(Result);
    end;

    /// <summary>Returns a JSON string containing only the listed step keys (comma-separated).</summary>
    procedure ToFilteredText(StepKeys: Text): Text
    var
        FilteredObj: JsonObject;
        KeyList: List of [Text];
        StepKey: Text;
        Token: JsonToken;
        Result: Text;
    begin
        KeyList := StepKeys.Split(',');
        foreach StepKey in KeyList do begin
            StepKey := StepKey.Trim();
            if Data.Get(StepKey, Token) then
                FilteredObj.Add(StepKey, Token);
        end;
        FilteredObj.WriteTo(Result);
        exit(Result);
    end;

    /// <summary>
    /// Gathers all numbered iteration objects under a step key into a JSON array.
    /// Keys "0", "1", "2", ... are collected in order.
    /// </summary>
    procedure Collect(StepKey: Text; var ResultArray: JsonArray): Boolean
    var
        StepToken: JsonToken;
        ItemToken: JsonToken;
        StepObj: JsonObject;
        i: Integer;
    begin
        Clear(ResultArray);
        if not GetTokenAtPath(StepKey, StepToken) then
            exit(false);
        if not StepToken.IsObject() then
            exit(false);

        StepObj := StepToken.AsObject();
        i := 0;
        while StepObj.Get(Format(i), ItemToken) do begin
            ResultArray.Add(ItemToken);
            i += 1;
        end;
        exit(ResultArray.Count() > 0);
    end;

    local procedure SetTokenAtPath(Path: Text; Value: JsonToken)
    var
        Segments: List of [Text];
        CurrentObj: JsonObject;
        ChildObj: JsonObject;
        Token: JsonToken;
        Segment: Text;
        LastSegment: Text;
        i: Integer;
    begin
        if Path = '' then
            exit;

        Segments := Path.Split('.');
        if Segments.Count() = 1 then begin
            if Data.Contains(Path) then
                Data.Remove(Path);
            Data.Add(Path, Value);
            exit;
        end;

        CurrentObj := Data;
        for i := 1 to Segments.Count() - 1 do begin
            Segments.Get(i, Segment);
            if CurrentObj.Contains(Segment) then begin
                CurrentObj.Get(Segment, Token);
                if Token.IsObject() then
                    CurrentObj := Token.AsObject()
                else begin
                    CurrentObj.Remove(Segment);
                    Clear(ChildObj);
                    CurrentObj.Add(Segment, ChildObj);
                    CurrentObj.Get(Segment, Token);
                    CurrentObj := Token.AsObject();
                end;
            end else begin
                Clear(ChildObj);
                CurrentObj.Add(Segment, ChildObj);
                CurrentObj.Get(Segment, Token);
                CurrentObj := Token.AsObject();
            end;
        end;

        Segments.Get(Segments.Count(), LastSegment);
        if CurrentObj.Contains(LastSegment) then
            CurrentObj.Remove(LastSegment);
        CurrentObj.Add(LastSegment, Value);
    end;

    local procedure GetTokenAtPath(Path: Text; var Result: JsonToken): Boolean
    var
        JsonHelper: Codeunit "Playbook JSON Helper ori";
    begin
        if Path = '' then
            exit(false);
        exit(JsonHelper.ResolveJsonPath(Data, Path, Result));
    end;

    // ---------------------------------------------------------------------
    // Run reporting: _run holds the playbook status, _steps holds one entry per
    // step. Both are top-level so ToFilteredText('_run,_steps') yields the whole
    // execution narrative without any of the bulk data the steps collected.
    //
    // Steps flagged "Exclude From Run Status" — the reporting tail itself — are
    // recorded under _tail instead. They stay out of the _run totals and out of
    // the narrative the report is about, but remain referenceable, so one tail
    // step can condition on another's outcome.
    // ---------------------------------------------------------------------

    /// <summary>Seeds _run at the start of a playbook. Call after Reset().</summary>
    procedure BeginRun(PlaybookCode: Code[20]; PlaybookDescription: Text; InstanceId: Guid)
    var
        RunObj: JsonObject;
        EmptyArr: JsonArray;
    begin
        RunObj.Add('playbookCode', PlaybookCode);
        RunObj.Add('description', PlaybookDescription);
        RunObj.Add('instanceId', Format(InstanceId, 0, 4));
        RunObj.Add('startedAt', Format(CurrentDateTime, 0, 9));
        RunObj.Add('durationMs', 0);
        RunObj.Add('stepsExecuted', 0);
        RunObj.Add('stepsSucceeded', 0);
        RunObj.Add('stepsFailed', 0);
        RunObj.Add('stepsSkipped', 0);
        RunObj.Add('itemsProcessed', 0);
        RunObj.Add('itemsFailed', 0);
        RunObj.Add('failed', false);
        RunObj.Add('firstFailedStepNo', 0);
        RunObj.Add('failedStepNos', EmptyArr);
        SetTokenAtPath('_run', RunObj.AsToken());
    end;

    /// <summary>Records the outcome of one step execution. Accumulates: a paged or
    /// iterated step is written many times and must not overwrite itself.</summary>
    procedure RecordStep(StepNo: Integer; StepDescription: Text; MessageType: Text; StatusText: Text; IsCheck: Boolean; CheckResult: Boolean; DurationMs: Integer; ErrorText: Text; Excluded: Boolean)
    var
        StepObj: JsonObject;
    begin
        StepObj := GetOrCreateStep(StepNo, StepDescription, MessageType, Excluded);
        SetJsonText(StepObj, 'status', DegradeStatus(GetJsonText(StepObj, 'status'), StatusText));
        SetJsonInt(StepObj, 'durationMs', GetJsonInt(StepObj, 'durationMs') + DurationMs);
        if IsCheck then
            SetJsonBool(StepObj, 'checkResult', CheckResult);
        if ErrorText <> '' then
            SetJsonText(StepObj, 'error', CopyStr(ErrorText, 1, MaxErrorLen()));
        SetTokenAtPath(StepPath(StepNo, Excluded), StepObj.AsToken());
    end;

    /// <summary>Marks a step skipped by its Start conditions, with the reason.</summary>
    procedure RecordStepSkipped(StepNo: Integer; StepDescription: Text; MessageType: Text; Reason: Text; Excluded: Boolean)
    var
        StepObj: JsonObject;
    begin
        StepObj := GetOrCreateStep(StepNo, StepDescription, MessageType, Excluded);
        SetJsonText(StepObj, 'status', 'Cancelled');
        SetJsonText(StepObj, 'skippedReason', Reason);
        SetTokenAtPath(StepPath(StepNo, Excluded), StepObj.AsToken());
    end;

    /// <summary>Counts one iteration and, when it did not succeed, records what failed and why.</summary>
    procedure RecordIteration(StepNo: Integer; IterationNo: Integer; Outcome: Text; ItemToken: JsonToken; ErrorText: Text; Excluded: Boolean)
    var
        StepObj: JsonObject;
        ItemsObj: JsonObject;
        FailuresArr: JsonArray;
        FailureObj: JsonObject;
        Token: JsonToken;
    begin
        StepObj := GetOrCreateStep(StepNo, '', '', Excluded);
        SetJsonBool(StepObj, 'iterated', true);

        if StepObj.Get('items', Token) then
            ItemsObj := Token.AsObject();
        SetJsonInt(ItemsObj, 'total', GetJsonInt(ItemsObj, 'total') + 1);
        case Outcome of
            'Completed':
                SetJsonInt(ItemsObj, 'succeeded', GetJsonInt(ItemsObj, 'succeeded') + 1);
            'Failed':
                SetJsonInt(ItemsObj, 'failed', GetJsonInt(ItemsObj, 'failed') + 1);
            'CheckFailed':
                SetJsonInt(ItemsObj, 'checkFailed', GetJsonInt(ItemsObj, 'checkFailed') + 1);
            'Skipped':
                SetJsonInt(ItemsObj, 'skipped', GetJsonInt(ItemsObj, 'skipped') + 1);
        end;
        SetJsonObject(StepObj, 'items', ItemsObj);

        if Outcome in ['Failed', 'CheckFailed'] then begin
            if StepObj.Get('failures', Token) then
                FailuresArr := Token.AsArray();
            if FailuresArr.Count() < MaxFailures() then begin
                FailureObj.Add('iteration', IterationNo);
                FailureObj.Add('outcome', Outcome);
                FailureObj.Add('item', ProjectItem(ItemToken));
                FailureObj.Add('error', CopyStr(ErrorText, 1, MaxErrorLen()));
                FailuresArr.Add(FailureObj);
                SetJsonArray(StepObj, 'failures', FailuresArr);
            end else
                SetJsonBool(StepObj, 'failuresTruncated', true);
        end;

        SetTokenAtPath(StepPath(StepNo, Excluded), StepObj.AsToken());
    end;

    /// <summary>Counts one page of a paged step.</summary>
    procedure RecordPage(StepNo: Integer; Excluded: Boolean)
    var
        StepObj: JsonObject;
    begin
        StepObj := GetOrCreateStep(StepNo, '', '', Excluded);
        SetJsonInt(StepObj, 'pages', GetJsonInt(StepObj, 'pages') + 1);
        SetTokenAtPath(StepPath(StepNo, Excluded), StepObj.AsToken());
    end;

    /// <summary>
    /// Copies the step's curated business values into _steps.&lt;n&gt;.result.
    /// Deliberately separate from Result Log Paths: that feeds later steps and often
    /// carries large arrays; this feeds the report and must stay small.
    /// </summary>
    procedure RecordStepSummary(StepNo: Integer; ResponseText: Text; SummaryPaths: Text; Excluded: Boolean)
    var
        JsonHelper: Codeunit "Playbook JSON Helper ori";
        ResponseJson: JsonObject;
        StepObj: JsonObject;
        ResultObj: JsonObject;
        Token: JsonToken;
        ResolvedToken: JsonToken;
        MappingList: List of [Text];
        Mapping: Text;
        SourcePath: Text;
        TargetName: Text;
        SepPos: Integer;
    begin
        if (SummaryPaths = '') or (ResponseText = '') then
            exit;
        if not ResponseJson.ReadFrom(ResponseText) then
            exit;

        StepObj := GetOrCreateStep(StepNo, '', '', Excluded);
        if StepObj.Get('result', Token) then
            ResultObj := Token.AsObject();

        MappingList := SummaryPaths.Split(',');
        foreach Mapping in MappingList do begin
            Mapping := Mapping.Trim();
            if Mapping <> '' then begin
                SepPos := Mapping.IndexOf('>');
                if SepPos > 0 then begin
                    SourcePath := CopyStr(Mapping, 1, SepPos - 1).Trim();
                    TargetName := CopyStr(Mapping, SepPos + 1).Trim();
                end else begin
                    SourcePath := Mapping;
                    TargetName := Mapping;
                end;
                if JsonHelper.ResolveJsonPath(ResponseJson, SourcePath, ResolvedToken) then
                    if ResolvedToken.IsValue() then begin
                        if ResultObj.Contains(TargetName) then
                            ResultObj.Remove(TargetName);
                        ResultObj.Add(TargetName, CopyStr(ResolvedToken.AsValue().AsText(), 1, MaxSummaryLen()));
                    end;
            end;
        end;

        SetJsonObject(StepObj, 'result', ResultObj);
        SetTokenAtPath(StepPath(StepNo, Excluded), StepObj.AsToken());
    end;

    /// <summary>Rolls a step's outcome into the _run totals.</summary>
    procedure RollUpRun(StepNo: Integer; StatusText: Text; ItemsThisStep: Integer; ItemsFailedThisStep: Integer; Excluded: Boolean)
    var
        RunObj: JsonObject;
        Token: JsonToken;
    begin
        if Excluded then
            exit;
        if not GetTokenAtPath('_run', Token) then
            exit;
        RunObj := Token.AsObject();

        SetJsonInt(RunObj, 'stepsExecuted', GetJsonInt(RunObj, 'stepsExecuted') + 1);
        SetJsonInt(RunObj, 'durationMs', ElapsedMs(GetJsonText(RunObj, 'startedAt')));
        SetJsonInt(RunObj, 'itemsProcessed', GetJsonInt(RunObj, 'itemsProcessed') + ItemsThisStep);
        SetJsonInt(RunObj, 'itemsFailed', GetJsonInt(RunObj, 'itemsFailed') + ItemsFailedThisStep);

        case StatusText of
            'Completed':
                SetJsonInt(RunObj, 'stepsSucceeded', GetJsonInt(RunObj, 'stepsSucceeded') + 1);
            'Cancelled':
                SetJsonInt(RunObj, 'stepsSkipped', GetJsonInt(RunObj, 'stepsSkipped') + 1);
            'Failed':
                begin
                    SetJsonInt(RunObj, 'stepsFailed', GetJsonInt(RunObj, 'stepsFailed') + 1);
                    MarkRunFailed(RunObj, StepNo);
                end;
        end;

        SetTokenAtPath('_run', RunObj.AsToken());
    end;

    /// <summary>Flags the run as failed without touching step counters — used by Error conditions.</summary>
    procedure EscalateRunFailure(StepNo: Integer)
    var
        RunObj: JsonObject;
        Token: JsonToken;
    begin
        if not GetTokenAtPath('_run', Token) then
            exit;
        RunObj := Token.AsObject();
        MarkRunFailed(RunObj, StepNo);
        SetTokenAtPath('_run', RunObj.AsToken());
    end;

    /// <summary>Stamps the elapsed time on _run at the end of the playbook.</summary>
    procedure CompleteRun(DurationMs: Integer)
    var
        RunObj: JsonObject;
        Token: JsonToken;
    begin
        if not GetTokenAtPath('_run', Token) then
            exit;
        RunObj := Token.AsObject();
        SetJsonInt(RunObj, 'durationMs', DurationMs);
        SetJsonText(RunObj, 'finishedAt', Format(CurrentDateTime, 0, 9));
        SetTokenAtPath('_run', RunObj.AsToken());
    end;

    /// <summary>True when any step has failed or an Error condition has escalated.</summary>
    procedure RunFailed(): Boolean
    var
        RunObj: JsonObject;
        Token: JsonToken;
        ValueToken: JsonToken;
    begin
        if not GetTokenAtPath('_run', Token) then
            exit(false);
        RunObj := Token.AsObject();
        if RunObj.Get('failed', ValueToken) then
            exit(ValueToken.AsValue().AsBoolean());
        exit(false);
    end;

    local procedure MarkRunFailed(var RunObj: JsonObject; StepNo: Integer)
    var
        FailedArr: JsonArray;
        Token: JsonToken;
    begin
        SetJsonBool(RunObj, 'failed', true);
        if GetJsonInt(RunObj, 'firstFailedStepNo') = 0 then
            SetJsonInt(RunObj, 'firstFailedStepNo', StepNo);
        if RunObj.Get('failedStepNos', Token) then
            FailedArr := Token.AsArray();
        FailedArr.Add(StepNo);
        SetJsonArray(RunObj, 'failedStepNos', FailedArr);
    end;

    /// <summary>
    /// Where a step's entry lives: _steps for the work being reported on, _tail for
    /// the reporting steps themselves.
    /// </summary>
    local procedure StepPath(StepNo: Integer; Excluded: Boolean): Text
    begin
        if Excluded then
            exit('_tail.' + Format(StepNo));
        exit('_steps.' + Format(StepNo));
    end;

    local procedure GetOrCreateStep(StepNo: Integer; StepDescription: Text; MessageType: Text; Excluded: Boolean) StepObj: JsonObject
    var
        Token: JsonToken;
    begin
        if GetTokenAtPath(StepPath(StepNo, Excluded), Token) then
            if Token.IsObject() then
                StepObj := Token.AsObject();
        if not StepObj.Contains('stepNo') then
            StepObj.Add('stepNo', StepNo);
        if (StepDescription <> '') and not StepObj.Contains('description') then
            StepObj.Add('description', StepDescription);
        if (MessageType <> '') and not StepObj.Contains('messageType') then
            StepObj.Add('messageType', MessageType);
    end;

    /// <summary>
    /// Status never improves across repeats: one failing page or iteration leaves
    /// the whole step Failed.
    /// </summary>
    local procedure DegradeStatus(Existing: Text; Incoming: Text): Text
    begin
        if Existing = 'Failed' then
            exit('Failed');
        if Incoming = 'Failed' then
            exit('Failed');
        if Existing = '' then
            exit(Incoming);
        if Existing = 'Cancelled' then
            exit(Incoming);
        exit(Existing);
    end;

    /// <summary>A small identifying projection of an iterated element — never the whole thing.</summary>
    local procedure ProjectItem(ItemToken: JsonToken) Projection: JsonObject
    var
        SourceObj: JsonObject;
        KeyName: Text;
        Token: JsonToken;
        Taken: Integer;
    begin
        Taken := 0;
        if not ItemToken.IsObject() then
            exit;
        SourceObj := ItemToken.AsObject();
        foreach KeyName in SourceObj.Keys() do begin
            if Taken >= MaxItemFields() then
                exit;
            if SourceObj.Get(KeyName, Token) then
                if Token.IsValue() then begin
                    Projection.Add(KeyName, CopyStr(Token.AsValue().AsText(), 1, MaxSummaryLen()));
                    Taken += 1;
                end;
        end;
    end;

    /// <summary>
    /// The invariant text used for _steps.status and compared in RollUpRun.
    /// Reads the declared enum name rather than Format(): plain Format returns the
    /// localised caption ("Lokið"), and Format(x, 0, 9) returns the ordinal ("2").
    /// </summary>
    procedure StatusToText(StepStatus: Enum "Playbook Inst. Status ori"): Text
    begin
        exit(StepStatus.Names().Get(StepStatus.Ordinals().IndexOf(StepStatus.AsInteger())));
    end;

    /// <summary>
    /// The dotted message type identifier for _steps.messageType, from the declared
    /// enum name. These captions happen to match today, but the name is what the
    /// contract promises.
    /// </summary>
    procedure MessageTypeToText(MessageType: Enum "Message Type ori"): Text
    begin
        exit(MessageType.Names().Get(MessageType.Ordinals().IndexOf(MessageType.AsInteger())));
    end;

    /// <summary>
    /// Milliseconds since the run began. Kept current on every roll-up so a reporting
    /// step reading _run mid-run sees a real elapsed time rather than zero.
    /// </summary>
    local procedure ElapsedMs(StartedAt: Text): Integer
    var
        StartTime: DateTime;
    begin
        if StartedAt = '' then
            exit(0);
        if not Evaluate(StartTime, StartedAt, 9) then
            exit(0);
        exit(CurrentDateTime() - StartTime);
    end;

    local procedure MaxFailures(): Integer
    begin
        exit(20);
    end;

    local procedure MaxErrorLen(): Integer
    begin
        exit(500);
    end;

    local procedure MaxSummaryLen(): Integer
    begin
        exit(250);
    end;

    local procedure MaxItemFields(): Integer
    begin
        exit(5);
    end;

    local procedure GetJsonText(JObj: JsonObject; KeyName: Text): Text
    var
        Token: JsonToken;
    begin
        if JObj.Get(KeyName, Token) then
            if Token.IsValue() then
                exit(Token.AsValue().AsText());
        exit('');
    end;

    local procedure GetJsonInt(JObj: JsonObject; KeyName: Text): Integer
    var
        Token: JsonToken;
    begin
        if JObj.Get(KeyName, Token) then
            if Token.IsValue() then
                exit(Token.AsValue().AsInteger());
        exit(0);
    end;

    local procedure SetJsonText(var JObj: JsonObject; KeyName: Text; NewValue: Text)
    begin
        if JObj.Contains(KeyName) then
            JObj.Remove(KeyName);
        JObj.Add(KeyName, NewValue);
    end;

    local procedure SetJsonInt(var JObj: JsonObject; KeyName: Text; NewValue: Integer)
    begin
        if JObj.Contains(KeyName) then
            JObj.Remove(KeyName);
        JObj.Add(KeyName, NewValue);
    end;

    local procedure SetJsonBool(var JObj: JsonObject; KeyName: Text; NewValue: Boolean)
    begin
        if JObj.Contains(KeyName) then
            JObj.Remove(KeyName);
        JObj.Add(KeyName, NewValue);
    end;

    local procedure SetJsonObject(var JObj: JsonObject; KeyName: Text; NewValue: JsonObject)
    begin
        if JObj.Contains(KeyName) then
            JObj.Remove(KeyName);
        JObj.Add(KeyName, NewValue);
    end;

    local procedure SetJsonArray(var JObj: JsonObject; KeyName: Text; NewValue: JsonArray)
    begin
        if JObj.Contains(KeyName) then
            JObj.Remove(KeyName);
        JObj.Add(KeyName, NewValue);
    end;

    local procedure SeedSystemConstants()
    var
        SysObj: JsonObject;
        TodayDate: Date;
    begin
        TodayDate := Today;
        SysObj.Add('today', Format(TodayDate, 0, 9));
        SysObj.Add('workDate', Format(WorkDate(), 0, 9));
        SysObj.Add('now', Format(CurrentDateTime, 0, 9));
        SysObj.Add('year', Date2DMY(TodayDate, 3));
        SysObj.Add('lastMonthStart', Format(CalcDate('<-CM-1M>', TodayDate), 0, 9));
        SysObj.Add('lastMonthEnd', Format(CalcDate('<CM-1M>', TodayDate), 0, 9));
        SysObj.Add('thisMonthStart', Format(CalcDate('<-CM>', TodayDate), 0, 9));
        SysObj.Add('thisQuarterStart', Format(CalcDate('<-CQ>', TodayDate), 0, 9));
        SysObj.Add('thisYearStart', Format(CalcDate('<-CY>', TodayDate), 0, 9));
        SysObj.Add('companyName', CompanyName);
        SysObj.Add('userId', UserId());
        SetTokenAtPath('_sys', SysObj.AsToken());
    end;

    local procedure SeedWhoAmI()
    var
        Executor: Codeunit "Playbook Step Executor ori";
        ResponseText: Text;
        ErrorText: Text;
        WhoAmIJson: JsonObject;
    begin
        if not Executor.Execute(Enum::"Message Type ori"::"Help.WhoAmI.Get", '', '', ResponseText, ErrorText) then
            exit;
        if ResponseText = '' then
            exit;
        if not WhoAmIJson.ReadFrom(ResponseText) then
            exit;
        // Remove status field — not useful in workspace
        if WhoAmIJson.Contains('status') then
            WhoAmIJson.Remove('status');
        SetTokenAtPath('_who', WhoAmIJson.AsToken());
    end;
}
