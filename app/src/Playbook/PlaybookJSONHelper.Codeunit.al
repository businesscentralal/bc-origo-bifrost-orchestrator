/// <summary>
/// Stateless JSON utilities for the playbook runner: workspace reference resolution,
/// condition evaluation, array extraction, and simple dot-notation path resolver.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

codeunit 10035546 "Playbook JSON Helper ori"
{
    Access = Internal;

    /// <summary>
    /// Tells whether a message type answered with an error instead of raising one. Bifrost message
    /// types return refusals and handled failures as a response whose <c>status</c> is not
    /// <c>Success</c>: <c>status = "Error"</c> (or <c>Refused</c>, <c>Failed</c>), or any other
    /// non-<c>Success</c> status that carries an <c>error</c> text. The error text keeps the
    /// message type's <c>code</c> and <c>error</c> (or <c>message</c>) so it can be logged.
    /// A response without a <c>status</c>, with <c>status = "Success"</c> or one that is not a JSON
    /// object is never an error here.
    /// </summary>
    /// <param name="ResponseText">The response text of the message type.</param>
    /// <param name="ErrorText">Receives "code: error" (or just the error) when the response is an error, otherwise empty.</param>
    /// <returns>True when the response is a technical error answer.</returns>
    procedure IsErrorResponse(ResponseText: Text; var ErrorText: Text): Boolean
    var
        ResponseJson: JsonObject;
        StatusText: Text;
        CodeText: Text;
        MessageText: Text;
    begin
        ErrorText := '';
        if ResponseText = '' then
            exit(false);
        if not ResponseJson.ReadFrom(ResponseText) then
            exit(false);

        StatusText := GetTextProperty(ResponseJson, 'status');
        if StatusText = '' then
            exit(false);
        if StatusText.ToLower() = 'success' then
            exit(false);

        CodeText := GetTextProperty(ResponseJson, 'code');
        MessageText := GetTextProperty(ResponseJson, 'error');
        if MessageText = '' then
            MessageText := GetTextProperty(ResponseJson, 'message');

        if not (StatusText.ToLower() in ['error', 'refused', 'failed']) then
            if MessageText = '' then
                exit(false);

        if MessageText = '' then
            MessageText := StatusText;
        if CodeText <> '' then
            ErrorText := CodeText + ': ' + MessageText
        else
            ErrorText := MessageText;
        exit(true);
    end;

    local procedure GetTextProperty(Source: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        if not Source.Get(PropertyName, Token) then
            exit('');
        if not Token.IsValue() then
            exit('');
        if Token.AsValue().IsNull() then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    /// <summary>
    /// Walks the serialized request JSON and replaces "@path" string values with
    /// workspace data. "@collect:N" gathers forEach iteration objects into an array.
    /// </summary>
    procedure ResolveWorkspaceRefs(var RequestJson: JsonObject)
    var
        Workspace: Codeunit "Playbook Workspace ori";
        RequestText: Text;
        IterValue: Text;
    begin
        RequestJson.WriteTo(RequestText);
        if not RequestText.Contains('@') then
            exit;
        // Pass 0: expand @_iter so paths like @30.@_iter.street become @30.0.street
        if Workspace.GetValue('_iter', IterValue) then
            RequestText := RequestText.Replace('@_iter', IterValue);
        // Pass 1: standalone "@path" → token replacement
        RequestText := ResolveStandaloneRefs(RequestText, Workspace);
        // Pass 2: embedded @path within strings → text interpolation
        RequestText := ResolveEmbeddedRefs(RequestText, Workspace);
        Clear(RequestJson);
        RequestJson.ReadFrom(RequestText);
    end;

    /// <summary>Checks references in the original request before resolution, so missing data never reaches dispatch as literal tokens.</summary>
    /// <param name="RequestJson">The step request; resolved only when all references exist.</param>
    /// <param name="ErrorText">Receives the first unresolved reference and corrective guidance.</param>
    /// <returns>True when the request can be dispatched.</returns>
    procedure TryResolveWorkspaceRefs(var RequestJson: JsonObject; var ErrorText: Text): Boolean
    var
        Workspace: Codeunit "Playbook Workspace ori";
        ValidationJson: JsonObject;
        RequestText: Text;
        IterValue: Text;
    begin
        Clear(ErrorText);
        RequestJson.WriteTo(RequestText);
        if Workspace.GetValue('_iter', IterValue) then
            RequestText := RequestText.Replace('@_iter', IterValue);
        ValidationJson.ReadFrom(RequestText);
        if not CheckReferenceToken(ValidationJson.AsToken(), ErrorText) then
            exit(false);
        ResolveWorkspaceRefs(RequestJson);
        exit(true);
    end;

    local procedure CheckReferenceToken(Token: JsonToken; var ErrorText: Text): Boolean
    var
        Child: JsonToken;
        PropertyName: Text;
    begin
        case true of
            Token.IsValue():
                if not Token.AsValue().IsNull() then
                    exit(CheckReferenceString(Token.AsValue().AsText(), ErrorText));
            Token.IsObject():
                foreach PropertyName in Token.AsObject().Keys() do begin
                    Token.AsObject().Get(PropertyName, Child);
                    if not CheckReferenceToken(Child, ErrorText) then
                        exit(false);
                end;
            Token.IsArray():
                foreach Child in Token.AsArray() do
                    if not CheckReferenceToken(Child, ErrorText) then
                        exit(false);
        end;
        exit(true);
    end;

    local procedure CheckReferenceString(Value: Text; var ErrorText: Text): Boolean
    var
        Workspace: Codeunit "Playbook Workspace ori";
        ResolvedToken: JsonToken;
        CollectedArray: JsonArray;
        Reference: Text;
        AtPos: Integer;
        RefEnd: Integer;
        IsReference: Boolean;
    begin
        if Value.StartsWith('@') and not Value.Contains(' ') and not Value.Contains('(') then begin
            Reference := CopyStr(Value, 2);
            if Reference.StartsWith('collect:') then begin
                if Workspace.Collect(CopyStr(Reference, 9), CollectedArray) then
                    exit(true);
                ErrorText := StrSubstNo(UnresolvedReferenceErr, Value);
                exit(false);
            end;
            // A filtered workspace dump resolves to a JSON string, including when its selection is empty.
            if Reference.Contains(',') then
                exit(true);
        end;
        AtPos := Value.IndexOf('@');
        while AtPos > 0 do begin
            RefEnd := AtPos + 1;
            while RefEnd <= StrLen(Value) do begin
                if not IsReferencePathChar(Value[RefEnd]) then
                    break;
                RefEnd += 1;
            end;
            while RefEnd > AtPos + 1 do begin
                if Value[RefEnd - 1] <> '.' then
                    break;
                RefEnd -= 1;
            end;
            IsReference := RefEnd > AtPos + 1;
            if AtPos > 1 then
                if IsReferenceLetterOrDigit(Value[AtPos - 1]) then
                    IsReference := false;
            if IsReference then begin
                Reference := CopyStr(Value, AtPos + 1, RefEnd - AtPos - 1);
                if not Workspace.GetToken(Reference, ResolvedToken) then begin
                    ErrorText := StrSubstNo(UnresolvedReferenceErr, '@' + Reference);
                    exit(false);
                end;
            end;
            AtPos := Value.IndexOf('@', RefEnd);
        end;
        exit(true);
    end;

    local procedure IsReferencePathChar(Ch: Char): Boolean
    begin
        exit(IsReferenceLetterOrDigit(Ch) or (Ch in ['.', '_', '[', ']']));
    end;

    local procedure IsReferenceLetterOrDigit(Ch: Char): Boolean
    begin
        exit(((Ch >= 'a') and (Ch <= 'z')) or ((Ch >= 'A') and (Ch <= 'Z')) or ((Ch >= '0') and (Ch <= '9')));
    end;

    local procedure ResolveStandaloneRefs(JsonText: Text; var Workspace: Codeunit "Playbook Workspace ori"): Text
    var
        ResolvedToken: JsonToken;
        CollectedArray: JsonArray;
        EscapedValue: JsonValue;
        SearchPos: Integer;
        QuoteEnd: Integer;
        RefText: Text;
        WsPath: Text;
        ResolvedText: Text;
    begin
        SearchPos := JsonText.IndexOf('"@');
        while SearchPos > 0 do begin
            QuoteEnd := JsonText.IndexOf('"', SearchPos + 2);
            if QuoteEnd = 0 then
                exit(JsonText);

            RefText := CopyStr(JsonText, SearchPos + 2, QuoteEnd - SearchPos - 2);
            // Only standalone: no other text before/after the @ref
            if RefText.Contains(' ') or RefText.Contains('(') then begin
                SearchPos := QuoteEnd + 1;
                SearchPos := JsonText.IndexOf('"@', SearchPos);
            end else begin
                Clear(ResolvedText);
                if RefText.StartsWith('collect:') then begin
                    WsPath := CopyStr(RefText, 9);
                    if Workspace.Collect(WsPath, CollectedArray) then
                        CollectedArray.WriteTo(ResolvedText);
                end else
                    if RefText.Contains(',') then begin
                        EscapedValue.SetValue(Workspace.ToFilteredText(RefText));
                        EscapedValue.WriteTo(ResolvedText);
                    end else begin
                        WsPath := RefText;
                        if Workspace.GetToken(WsPath, ResolvedToken) then
                            ResolvedText := TokenToJsonLiteral(ResolvedToken);
                    end;

                if ResolvedText <> '' then begin
                    JsonText := CopyStr(JsonText, 1, SearchPos - 1) + ResolvedText + CopyStr(JsonText, QuoteEnd + 1);
                    SearchPos := SearchPos + StrLen(ResolvedText);
                end else
                    SearchPos := QuoteEnd + 1;

                SearchPos := JsonText.IndexOf('"@', SearchPos);
            end;
        end;
        exit(JsonText);
    end;

    local procedure ResolveEmbeddedRefs(JsonText: Text; var Workspace: Codeunit "Playbook Workspace ori"): Text
    var
        ResolvedToken: JsonToken;
        SearchPos: Integer;
        RefEnd: Integer;
        RefText: Text;
        ResolvedValue: Text;
        Ch: Char;
    begin
        SearchPos := JsonText.IndexOf('@');
        while SearchPos > 0 do begin
            // Find end of path: valid chars are letters, digits, dot, underscore, brackets
            RefEnd := SearchPos + 1;
            while RefEnd <= StrLen(JsonText) do begin
                Ch := JsonText[RefEnd];
                if not (((Ch >= 'a') and (Ch <= 'z')) or ((Ch >= 'A') and (Ch <= 'Z')) or
                        ((Ch >= '0') and (Ch <= '9')) or (Ch = '.') or (Ch = '_') or
                        (Ch = '[') or (Ch = ']'))
                then
                    break;
                RefEnd += 1;
            end;
            // A path never ends with a dot: trailing dots are sentence punctuation and stay in the text (#101)
            while (RefEnd > SearchPos + 1) and (JsonText[RefEnd - 1] = '.') do
                RefEnd -= 1;

            if RefEnd > SearchPos + 1 then begin
                RefText := CopyStr(JsonText, SearchPos + 1, RefEnd - SearchPos - 1);
                if Workspace.GetToken(RefText, ResolvedToken) then begin
                    if ResolvedToken.IsValue() then
                        ResolvedValue := ResolvedToken.AsValue().AsText()
                    else
                        ResolvedToken.WriteTo(ResolvedValue);
                    // An embedded reference sits inside a JSON string: escape quotes, backslashes and line breaks (#101)
                    ResolvedValue := EscapeForJsonString(ResolvedValue);
                    JsonText := CopyStr(JsonText, 1, SearchPos - 1) + ResolvedValue + CopyStr(JsonText, RefEnd);
                    SearchPos := SearchPos + StrLen(ResolvedValue);
                end else
                    SearchPos := RefEnd;
            end else
                SearchPos += 1;

            SearchPos := JsonText.IndexOf('@', SearchPos);
        end;
        exit(JsonText);
    end;

    local procedure EscapeForJsonString(Value: Text): Text
    var
        JsonValueHolder: JsonValue;
        Quoted: Text;
    begin
        JsonValueHolder.SetValue(Value);
        JsonValueHolder.WriteTo(Quoted);
        exit(CopyStr(Quoted, 2, StrLen(Quoted) - 2));
    end;

    /// <summary>
    /// Evaluates every condition of one type for a step: AND within a Group No.,
    /// OR across groups. An empty set is true.
    /// </summary>
    procedure EvaluateConditionSet(SourceJson: JsonObject; PlaybookCode: Code[20]; StepNo: Integer; CondType: Enum "Playbook Cond. Type ori"): Boolean
    var
        Condition: Record "Playbook Condition ori";
        CurrentGroup: Integer;
        GroupHolds: Boolean;
    begin
        Condition.FilterForStep(PlaybookCode, StepNo, CondType);
        Condition.ReadIsolation := IsolationLevel::ReadCommitted;
        if not Condition.FindSet() then
            exit(true);

        CurrentGroup := Condition."Group No.";
        GroupHolds := true;
        repeat
            if Condition."Group No." <> CurrentGroup then begin
                // A completed group that held is enough — the groups are ORed.
                if GroupHolds then
                    exit(true);
                CurrentGroup := Condition."Group No.";
                GroupHolds := true;
            end;
            if not EvaluateCondition(SourceJson, Condition.Path, Condition.Operator, Condition."Value") then
                GroupHolds := false;
        until Condition.Next() = 0;

        exit(GroupHolds);
    end;

    /// <summary>
    /// Evaluates a success condition against a response JSON object.
    /// </summary>
    /// <param name="SourceJson">The JSON to evaluate against — a response, or the workspace.</param>
    /// <param name="ConditionPath">JSON path to the field to check.</param>
    /// <param name="Operator">Comparison operator.</param>
    /// <param name="ConditionValue">Expected value to compare against.</param>
    /// <returns>True if the condition is satisfied.</returns>
    procedure EvaluateCondition(SourceJson: JsonObject; ConditionPath: Text; Operator: Enum "Playbook Cond. Operator ori"; ConditionValue: Text): Boolean
    var
        ResolvedToken: JsonToken;
        ActualValue: Text;
        ActualDecimal: Decimal;
        ExpectedDecimal: Decimal;
    begin
        if ConditionPath = '' then
            exit(true);

        if Operator = Operator::Exists then
            exit(ResolveJsonPath(SourceJson, ConditionPath, ResolvedToken));

        if not ResolveJsonPath(SourceJson, ConditionPath, ResolvedToken) then
            exit(false);

        ActualValue := GetTokenAsText(ResolvedToken);

        case Operator of
            Operator::Equals:
                exit(ActualValue = ConditionValue);
            Operator::NotEquals:
                exit(ActualValue <> ConditionValue);
            Operator::Contains:
                exit(ActualValue.Contains(ConditionValue));
            Operator::GreaterThan,
            Operator::LessThan,
            Operator::GreaterOrEqual,
            Operator::LessOrEqual:
                begin
                    if not Evaluate(ActualDecimal, ActualValue, 9) then
                        exit(false);
                    if not Evaluate(ExpectedDecimal, ConditionValue, 9) then
                        exit(false);
                    case Operator of
                        Operator::GreaterThan:
                            exit(ActualDecimal > ExpectedDecimal);
                        Operator::LessThan:
                            exit(ActualDecimal < ExpectedDecimal);
                        Operator::GreaterOrEqual:
                            exit(ActualDecimal >= ExpectedDecimal);
                        Operator::LessOrEqual:
                            exit(ActualDecimal <= ExpectedDecimal);
                    end;
                end;
        end;
    end;

    /// <summary>
    /// Extracts a JSON array from a response at the given path.
    /// </summary>
    /// <param name="ResponseJson">The source JSON object.</param>
    /// <param name="ArrayPath">Dot-notation path to the array field.</param>
    /// <param name="ResultArray">Returns the extracted array.</param>
    /// <returns>True if the array was found and extracted.</returns>
    procedure ExtractArray(ResponseJson: JsonObject; ArrayPath: Text; var ResultArray: JsonArray): Boolean
    var
        Token: JsonToken;
    begin
        Clear(ResultArray);
        if not ResolveJsonPath(ResponseJson, ArrayPath, Token) then
            exit(false);

        if not Token.IsArray() then
            exit(false);

        ResultArray := Token.AsArray();
        exit(true);
    end;

    /// <summary>
    /// Resolves a simple dot-notation path against a JSON object.
    /// Supports: "field", "parent.child", "array[0].field".
    /// Does NOT support full JSONPath spec — just dot + numeric array index.
    /// </summary>
    /// <param name="Source">The source JSON object.</param>
    /// <param name="Path">Dot-notation path (e.g., "items[0].uuid").</param>
    /// <param name="Result">Returns the resolved token.</param>
    /// <returns>True if the path was resolved successfully.</returns>
    procedure ResolveJsonPath(Source: JsonObject; Path: Text; var Result: JsonToken): Boolean
    var
        Segments: List of [Text];
        Segment: Text;
        CurrentToken: JsonToken;
        ArrayIndex: Integer;
        BracketPos: Integer;
        FieldName: Text;
        IndexText: Text;
    begin
        if Path = '' then
            exit(false);

        CurrentToken := Source.AsToken();
        Segments := Path.Split('.');

        foreach Segment in Segments do begin
            BracketPos := Segment.IndexOf('[');
            if BracketPos > 0 then begin
                FieldName := Segment.Substring(1, BracketPos - 1);
                IndexText := Segment.Substring(BracketPos + 1, Segment.IndexOf(']') - BracketPos - 1);
                // A non-numeric index such as items[x] must fail the path like every other bad
                // segment here, not raise a hard error out of the playbook step.
                if not Evaluate(ArrayIndex, IndexText, 9) then
                    exit(false);

                if not CurrentToken.AsObject().Get(FieldName, CurrentToken) then
                    exit(false);
                if not CurrentToken.IsArray() then
                    exit(false);
                if ArrayIndex >= CurrentToken.AsArray().Count() then
                    exit(false);
                CurrentToken.AsArray().Get(ArrayIndex, CurrentToken);
            end else begin
                if not CurrentToken.IsObject() then
                    exit(false);
                if not CurrentToken.AsObject().Get(Segment, CurrentToken) then
                    exit(false);
            end;
        end;

        Result := CurrentToken;
        exit(true);
    end;

    local procedure GetTokenAsText(Token: JsonToken): Text
    begin
        if Token.IsValue() then
            exit(Token.AsValue().AsText());
        exit(FormatToken(Token));
    end;

    local procedure FormatToken(Token: JsonToken): Text
    var
        Result: Text;
    begin
        Token.WriteTo(Result);
        exit(Result);
    end;

    /// <summary>Converts a token to a JSON literal, auto-detecting numeric strings as bare numbers.</summary>
    local procedure TokenToJsonLiteral(Token: JsonToken): Text
    var
        TextVal: Text;
        DecVal: Decimal;
        Result: Text;
    begin
        if not Token.IsValue() then begin
            Token.WriteTo(Result);
            exit(Result);
        end;
        TextVal := Token.AsValue().AsText();
        if TextVal in ['true', 'false'] then
            exit(TextVal);
        if (TextVal <> '') and Evaluate(DecVal, TextVal, 9) and (StrLen(TextVal) < 20) then
            exit(TextVal);
        Token.WriteTo(Result);
        exit(Result);
    end;
    var
        UnresolvedReferenceErr: Label 'Unresolved workspace reference %1. Inspect the source response and correct the path before running the step. No message was sent.', Comment = '%1 = workspace reference, is-IS=Óleyst vinnusvæðistilvísun %1. Skoðaðu upprunasvarið og leiðréttu slóðina áður en skrefið er keyrt. Engin skilaboð voru send.';
}
