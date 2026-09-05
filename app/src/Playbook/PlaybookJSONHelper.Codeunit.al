/// <summary>
/// Stateless JSON utilities for the playbook runner: workspace reference resolution,
/// condition evaluation, array extraction, and simple dot-notation path resolver.
/// </summary>
namespace Origo.Bifrost.Nornir;

codeunit 10035546 "Playbook JSON Helper ori"
{
    Access = Internal;

    /// <summary>
    /// Walks the serialized request JSON and replaces "@path" string values with
    /// workspace data. "@collect:N" gathers forEach iteration objects into an array.
    /// </summary>
    internal procedure ResolveWorkspaceRefs(var RequestJson: JsonObject)
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

            if RefEnd > SearchPos + 1 then begin
                RefText := CopyStr(JsonText, SearchPos + 1, RefEnd - SearchPos - 1);
                if Workspace.GetToken(RefText, ResolvedToken) then begin
                    if ResolvedToken.IsValue() then
                        ResolvedValue := ResolvedToken.AsValue().AsText()
                    else
                        ResolvedToken.WriteTo(ResolvedValue);
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

    /// <summary>
    /// Evaluates every condition of one type for a step: AND within a Group No.,
    /// OR across groups. An empty set is true.
    /// </summary>
    internal procedure EvaluateConditionSet(SourceJson: JsonObject; PlaybookCode: Code[20]; StepNo: Integer; CondType: Enum "Playbook Cond. Type ori"): Boolean
    var
        Condition: Record "Playbook Condition ori";
        CurrentGroup: Integer;
        GroupHolds: Boolean;
    begin
        Condition.FilterForStep(PlaybookCode, StepNo, CondType);
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
    internal procedure EvaluateCondition(SourceJson: JsonObject; ConditionPath: Text; Operator: Enum "Playbook Cond. Operator ori"; ConditionValue: Text): Boolean
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
    internal procedure ExtractArray(ResponseJson: JsonObject; ArrayPath: Text; var ResultArray: JsonArray): Boolean
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
    internal procedure ResolveJsonPath(Source: JsonObject; Path: Text; var Result: JsonToken): Boolean
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
                Evaluate(ArrayIndex, IndexText, 9);

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
}
