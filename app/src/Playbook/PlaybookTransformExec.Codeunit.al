namespace Origo.Bifrost.Orchestrator;

/// <summary>Maps a JSON row using local, side-effect-free operations. Never calls the message dispatcher.</summary>
codeunit 10035627 "Playbook Transform Exec ori"
{
    Access = Internal;

    /// <summary>Builds a new output row; errors leave the input and workspace unchanged.</summary>
    /// <param name="Step">Transform definition.</param>
    /// <param name="Input">Input row or resolved request template.</param>
    /// <param name="ResponseText">Output row on success.</param>
    /// <param name="ErrorText">Actionable error on failure.</param>
    /// <returns>True only when every mapping succeeded.</returns>
    internal procedure Execute(Step: Record "Playbook Step ori"; Input: JsonObject; var ResponseText: Text; var ErrorText: Text): Boolean
    var
        Output: JsonObject;
    begin
        Clear(ResponseText);
        Clear(ErrorText);
        ClearLastError();
        if not TryMap(Step, Input, Output) then begin
            ErrorText := GetLastErrorText();
            exit(false);
        end;
        Output.WriteTo(ResponseText);
        exit(true);
    end;

    [TryFunction]
    local procedure TryMap(Step: Record "Playbook Step ori"; Input: JsonObject; var Output: JsonObject)
    var
        Mapping: Record "Playbook Transform ori";
        Workspace: Codeunit "Playbook Workspace ori";
        JsonHelper: Codeunit "Playbook JSON Helper ori";
        Token: JsonToken;
        Found: Boolean;
    begin
        if Step."Message Type".AsInteger() <> 0 then
            Error(ErrorInfo.Create(MessageTypeErr));
        if Step.Paged then
            Error(ErrorInfo.Create(PagedErr));
        Mapping.SetRange("Playbook Code", Step."Playbook Code");
        Mapping.SetRange("Step No.", Step."Step No.");
        Mapping.SetLoadFields("Target Path", "Source Path", Operation, "Argument 1", "Argument 2");
        Mapping.ReadIsolation := IsolationLevel::ReadCommitted;
        if not Mapping.FindSet() then
            Error(ErrorInfo.Create(NoMappingsErr));
        repeat
            if not IsTargetPathValid(Mapping."Target Path") then
                Error(ErrorInfo.Create(StrSubstNo(TargetPathErr, Mapping."Target Path")));
            Clear(Token);
            if Mapping.Operation <> Mapping.Operation::Constant then begin
                if Mapping."Source Path".StartsWith('@') then
                    Found := Workspace.GetToken(CopyStr(Mapping."Source Path", 2), Token)
                else
                    Found := JsonHelper.ResolveJsonPath(Input, Mapping."Source Path", Token);
                if not Found then
                    Error(ErrorInfo.Create(StrSubstNo(SourcePathErr, Mapping."Source Path")));
            end;
            Token := ApplyOperation(Mapping.Operation, Token, Mapping."Argument 1", Mapping."Argument 2");
            SetOutputPath(Output, Mapping."Target Path", Token);
        until Mapping.Next() = 0;
    end;

    /// <summary>Applies a field operation without changing the supplied token.</summary>
    /// <param name="Operation">Operation to apply.</param>
    /// <param name="Source">Source JSON value; Copy accepts any JSON type.</param>
    /// <param name="Argument1">Constant or search string.</param>
    /// <param name="Argument2">Replacement string.</param>
    /// <returns>The transformed token, with numeric/text type preserved for Negate.</returns>
    internal procedure ApplyOperation(Operation: Enum "Transform Operation ori"; Source: JsonToken; Argument1: Text; Argument2: Text): JsonToken
    var
        Value: JsonValue;
        Number: Decimal;
        SourceText: Text;
        Serialized: Text;
    begin
        case Operation of
            Operation::Copy:
                exit(Source.Clone());
            Operation::Constant:
                Value.SetValue(Argument1);
            Operation::Negate:
                begin
                    if not Source.IsValue() then
                        Error(ErrorInfo.Create(ScalarErr));
                    if Source.AsValue().IsNull() then
                        exit(Source.Clone());
                    SourceText := Source.AsValue().AsText();
                    if not Evaluate(Number, SourceText, 9) then
                        exit(Source.Clone());
                    Source.WriteTo(Serialized);
                    if Serialized.StartsWith('"') then
                        Value.SetValue(Format(-Number, 0, 9))
                    else
                        Value.SetValue(-Number);
                end;
            Operation::"Replace Text":
                begin
                    if not Source.IsValue() then
                        Error(ErrorInfo.Create(ScalarErr));
                    if Source.AsValue().IsNull() then
                        exit(Source.Clone());
                    if Argument1 = '' then
                        Error(ErrorInfo.Create(EmptySearchErr));
                    Value.SetValue(Source.AsValue().AsText().Replace(Argument1, Argument2));
                end;
            else
                Error(ErrorInfo.Create(UnknownOperationErr));
        end;
        exit(Value.AsToken());
    end;

    /// <summary>Checks output property paths; output arrays and workspace writes are deliberately unsupported.</summary>
    /// <param name="Path">Dot-separated property path.</param>
    /// <returns>True for nonempty property segments without reference or array operators.</returns>
    internal procedure IsTargetPathValid(Path: Text): Boolean
    var
        Segment: Text;
    begin
        if Path = '' then
            exit(false);
        foreach Segment in Path.Split('.') do
            if (Segment.Trim() = '') or Segment.Contains('@') or Segment.Contains('[') or Segment.Contains(']') then
                exit(false);
        exit(true);
    end;

    local procedure SetOutputPath(var Output: JsonObject; Path: Text; Token: JsonToken)
    var
        Child: JsonObject;
        Existing: JsonToken;
        Segment: Text;
        Separator: Integer;
    begin
        Separator := Path.IndexOf('.');
        if Separator = 0 then begin
            if Output.Contains(Path) then
                Error(ErrorInfo.Create(StrSubstNo(DuplicateTargetErr, Path)));
            Output.Add(Path, Token.Clone());
            exit;
        end;
        Segment := CopyStr(Path, 1, Separator - 1);
        if Output.Get(Segment, Existing) then begin
            if not Existing.IsObject() then
                Error(ErrorInfo.Create(StrSubstNo(DuplicateTargetErr, Path)));
            Child := Existing.AsObject();
        end;
        SetOutputPath(Child, CopyStr(Path, Separator + 1), Token);
        if Output.Contains(Segment) then
            Output.Replace(Segment, Child)
        else
            Output.Add(Segment, Child);
    end;

    var
        PagedErr: Label 'Transform steps cannot fetch pages. Use a preceding paged reader.', Comment = 'is-IS=Umbreytingarskref geta ekki sótt síður. Notaðu fyrra síðuskipt lestrarskref.';
        MessageTypeErr: Label 'A Transform step must not have a message type.', Comment = 'is-IS=Umbreytingarskref má ekki hafa skilaboðagerð.';
        NoMappingsErr: Label 'Add at least one field mapping to the Transform step.', Comment = 'is-IS=Bættu að minnsta kosti einni reitavörpun við umbreytingarskrefið.';
        TargetPathErr: Label 'Transform target path %1 is invalid.', Comment = '%1 = target path, is-IS=Markslóð umbreytingar %1 er ógild.';
        SourcePathErr: Label 'Transform source path %1 was not found.', Comment = '%1 = source path, is-IS=Upprunaslóð umbreytingar %1 fannst ekki.';
        ScalarErr: Label 'This transform operation requires a scalar value.', Comment = 'is-IS=Þessi umbreytingaraðgerð krefst staks gildis.';
        EmptySearchErr: Label 'Replace Text requires a nonempty Argument 1.', Comment = 'is-IS=Viðfang 1 má ekki vera autt við textaskipti.';
        UnknownOperationErr: Label 'The transform operation is not supported.', Comment = 'is-IS=Umbreytingaraðgerðin er ekki studd.';
        DuplicateTargetErr: Label 'Transform target path %1 overlaps another mapping.', Comment = '%1 = target path, is-IS=Markslóð umbreytingar %1 skarast við aðra vörpun.';
}
