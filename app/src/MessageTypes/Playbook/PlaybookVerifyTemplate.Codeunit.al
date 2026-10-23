/// <summary>
/// The checks of Orchestrator.Playbook.Verify that read the request template of a step: that it is a JSON object,
/// that every @ reference points at an earlier step and at a field that step really stores, that
/// @_current.fields.X names a field of the table the forEach source read, and that the roleCode of a language
/// model step exists.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

codeunit 10035618 "Playbook Verify Template ori"
{
    Access = Internal;
    Permissions = tabledata "Playbook Step ori" = R;

    /// <summary>
    /// Runs every template-level check on one step.
    /// </summary>
    /// <param name="Step">The step to check; loaded with the fields the checks read.</param>
    /// <param name="Findings">Receives the findings of the step.</param>
    internal procedure CheckTemplate(Step: Record "Playbook Step ori"; var Findings: JsonArray)
    var
        Verify: Codeunit "Playbook Verify ori";
        TemplateJson: JsonObject;
        Seen: List of [Text];
        TemplateText: Text;
    begin
        TemplateText := Step.GetRequestTemplate();
        if TemplateText.Trim() = '' then
            exit;

        // The runner reads the template into a JsonObject and ignores the result: a template that is not a JSON
        // object is sent as an empty request {} without a word.
        if not TemplateJson.ReadFrom(TemplateText) then begin
            Verify.AddFinding(Findings, Verify.ErrorSeverity(), Step."Step No.", 'TemplateNotJson',
                StrSubstNo(TemplateNotJsonMsg, Step."Step No."), TemplateNotJsonNextStepTxt, Step.Disabled);
            exit;
        end;

        CheckRoleCode(Step, Verify.GetTypeName(Step."Message Type"), TemplateJson, Findings);
        ScanToken(Step, TemplateJson.AsToken(), Seen, Findings);
    end;

    /// <summary>
    /// A language model step (message type LLM.*) that names a roleCode: the role must exist in this company. An empty
    /// roleCode means the default model and a reference (@...) is resolved at run time, so neither is judged.
    /// </summary>
    /// <param name="Step">The step.</param>
    /// <param name="TypeName">The invariant name of the message type of the step.</param>
    /// <param name="TemplateJson">The request template of the step.</param>
    /// <param name="Findings">Receives the finding.</param>
    internal procedure CheckRoleCode(Step: Record "Playbook Step ori"; TypeName: Text; TemplateJson: JsonObject; var Findings: JsonArray)
    var
        Verify: Codeunit "Playbook Verify ori";
        Lookup: Codeunit "Playbook Verify Lookup ori";
        Token: JsonToken;
        RoleCode: Text;
        Exists: Boolean;
    begin
        if not TypeName.StartsWith('LLM.') then
            exit;
        if not TemplateJson.Get('roleCode', Token) then
            exit;
        if not Token.IsValue() then
            exit;
        RoleCode := Token.AsValue().AsText();
        // An empty roleCode means "the default model"; a reference is resolved at run time.
        if (RoleCode = '') or RoleCode.Contains('@') then
            exit;
        if not Lookup.TryGetRoleExists(RoleCode, Exists) then
            exit;
        if Exists then
            exit;
        Verify.AddFinding(Findings, Verify.ErrorSeverity(), Step."Step No.", 'LanguageModelRoleNotFound',
            StrSubstNo(RoleNotFoundMsg, Step."Step No.", TypeName, RoleCode), RoleNotFoundNextStepTxt, Step.Disabled);
    end;

    local procedure ScanToken(Step: Record "Playbook Step ori"; Token: JsonToken; var Seen: List of [Text]; var Findings: JsonArray)
    var
        Child: JsonToken;
        PropertyName: Text;
    begin
        case true of
            Token.IsValue():
                if not Token.AsValue().IsNull() then
                    ScanString(Step, Token.AsValue().AsText(), Seen, Findings);
            Token.IsObject():
                foreach PropertyName in Token.AsObject().Keys() do begin
                    Token.AsObject().Get(PropertyName, Child);
                    ScanToken(Step, Child, Seen, Findings);
                end;
            Token.IsArray():
                foreach Child in Token.AsArray() do
                    ScanToken(Step, Child, Seen, Findings);
        end;
    end;

    /// <summary>
    /// Finds the @ references in one string value the way the resolver reads them: a whole-value reference
    /// (@collect:N, @10,20,30) or an @path inside the text, a path being letters, digits, dot, underscore and brackets.
    /// An @ that follows a letter or digit (an e-mail address) is not a reference.
    /// </summary>
    local procedure ScanString(Step: Record "Playbook Step ori"; Value: Text; var Seen: List of [Text]; var Findings: JsonArray)
    var
        Reference: Text;
        Token: Text;
        AtPos: Integer;
        RefEnd: Integer;
        StepNo: Integer;
        IsReference: Boolean;
    begin
        if not Value.Contains('@') then
            exit;

        if Value.StartsWith('@') and not Value.Contains(' ') and not Value.Contains('(') then begin
            Reference := CopyStr(Value, 2);
            if Reference.StartsWith('collect:') then begin
                if TryGetStepNo(CopyStr(Reference, 9), StepNo) then
                    CheckStepReference(Step, StepNo, Seen, Findings);
                exit;
            end;
            if Reference.Contains(',') then begin
                foreach Token in Reference.Split(',') do
                    if TryGetStepNo(Token.Trim(), StepNo) then
                        CheckStepReference(Step, StepNo, Seen, Findings);
                exit;
            end;
        end;

        AtPos := Value.IndexOf('@');
        while AtPos > 0 do begin
            RefEnd := PathEnd(Value, AtPos);
            if RefEnd > AtPos + 1 then begin
                // AL does not short-circuit: Value[0] must never be evaluated.
                IsReference := true;
                if AtPos > 1 then
                    IsReference := not IsLetterOrDigit(Value[AtPos - 1]);
                if IsReference then
                    CheckPath(Step, Value, AtPos, CopyStr(Value, AtPos + 1, RefEnd - AtPos - 1), Seen, Findings);
                AtPos := Value.IndexOf('@', RefEnd);
            end else
                AtPos := Value.IndexOf('@', AtPos + 1);
        end;
    end;

    local procedure CheckPath(Step: Record "Playbook Step ori"; Value: Text; AtPos: Integer; Path: Text; var Seen: List of [Text]; var Findings: JsonArray)
    var
        Segments: List of [Text];
        FirstSegment: Text;
        StepNo: Integer;
    begin
        Segments := Path.Split('.');
        FirstSegment := Segments.Get(1);

        if TryGetStepNo(FirstSegment, StepNo) then begin
            CheckStepReference(Step, StepNo, Seen, Findings);
            CheckStepField(Step, StepNo, Segments, Seen, Findings);
            exit;
        end;
        if FirstSegment = '_iter' then begin
            if TryGetIterOwner(Value, AtPos, StepNo) then
                CheckIterField(Step, StepNo, Segments, Seen, Findings);
            exit;
        end;
        if FirstSegment = '_current' then
            CheckCurrentField(Step, Segments, Seen, Findings);
    end;

    local procedure CheckStepReference(Step: Record "Playbook Step ori"; ReferencedStepNo: Integer; var Seen: List of [Text]; var Findings: JsonArray)
    var
        ReferencedStep: Record "Playbook Step ori";
        Verify: Codeunit "Playbook Verify ori";
        SeenKey: Text;
    begin
        SeenKey := StrSubstNo(SeenStepTok, Format(ReferencedStepNo, 0, 9));
        if Seen.Contains(SeenKey) then
            exit;
        Seen.Add(SeenKey);

        ReferencedStep.SetLoadFields("Step No.");
        if not ReferencedStep.Get(Step."Playbook Code", ReferencedStepNo) then begin
            Verify.AddFinding(Findings, Verify.ErrorSeverity(), Step."Step No.", 'StepReferenceNotFound',
                StrSubstNo(StepNotFoundMsg, Step."Step No.", ReferencedStepNo), StepNotFoundNextStepTxt, Step.Disabled);
            exit;
        end;
        if ReferencedStepNo >= Step."Step No." then
            Verify.AddFinding(Findings, Verify.ErrorSeverity(), Step."Step No.", 'StepReferenceNotEarlier',
                StrSubstNo(StepNotEarlierMsg, Step."Step No.", ReferencedStepNo), StepNotEarlierNextStepTxt, Step.Disabled);
    end;

    /// <summary>
    /// @N.field reads what step N stored in the workspace. A single step stores only what its Result Log Paths name,
    /// at N.field; a forEach step stores them per iteration, at N.iteration.field, plus the element at _item.
    /// </summary>
    local procedure CheckStepField(Step: Record "Playbook Step ori"; ReferencedStepNo: Integer; Segments: List of [Text]; var Seen: List of [Text]; var Findings: JsonArray)
    var
        ReferencedStep: Record "Playbook Step ori";
        FieldName: Text;
        IterationNo: Integer;
    begin
        if Segments.Count() < 2 then
            exit;
        if not GetStoringStep(Step, ReferencedStepNo, ReferencedStep) then
            exit;

        if ReferencedStep.IsForEach() then begin
            // Only an explicit iteration (@30.0.street) is judged here; @30.@_iter.street is judged in CheckIterField.
            if (Segments.Count() < 3) or not TryGetStepNo(Segments.Get(2), IterationNo) then
                exit;
            FieldName := Segments.Get(3);
        end else
            FieldName := Segments.Get(2);
        CheckStoredField(Step, ReferencedStep, FieldName, Seen, Findings);
    end;

    local procedure CheckIterField(Step: Record "Playbook Step ori"; OwnerStepNo: Integer; Segments: List of [Text]; var Seen: List of [Text]; var Findings: JsonArray)
    var
        OwnerStep: Record "Playbook Step ori";
    begin
        if Segments.Count() < 2 then
            exit;
        if not GetStoringStep(Step, OwnerStepNo, OwnerStep) then
            exit;
        if not OwnerStep.IsForEach() then
            exit;
        CheckStoredField(Step, OwnerStep, Segments.Get(2), Seen, Findings);
    end;

    /// <summary>
    /// The step a reference reads from, when its stored fields can be judged: it exists, comes before the reading
    /// step, is enabled and is not paged (a paged step stores per page).
    /// </summary>
    local procedure GetStoringStep(Step: Record "Playbook Step ori"; StepNo: Integer; var StoringStep: Record "Playbook Step ori"): Boolean
    begin
        if StepNo >= Step."Step No." then
            exit(false);
        StoringStep.SetLoadFields("Step No.", "Iterate Array Path", "Result Log Paths", Disabled, Paged);
        if not StoringStep.Get(Step."Playbook Code", StepNo) then
            exit(false);
        exit(not StoringStep.Disabled and not StoringStep.Paged);
    end;

    local procedure CheckStoredField(Step: Record "Playbook Step ori"; StoringStep: Record "Playbook Step ori"; RawFieldName: Text; var Seen: List of [Text]; var Findings: JsonArray)
    var
        Verify: Codeunit "Playbook Verify ori";
        Stored: List of [Text];
        FieldName: Text;
        SeenKey: Text;
        StoredText: Text;
        Name: Text;
    begin
        FieldName := StripIndex(RawFieldName);
        if FieldName = '' then
            exit;
        GetStoredFieldNames(StoringStep, Stored);
        if Stored.Contains(FieldName.ToLower()) then
            exit;

        SeenKey := StrSubstNo(SeenFieldTok, Format(StoringStep."Step No.", 0, 9), FieldName.ToLower());
        if Seen.Contains(SeenKey) then
            exit;
        Seen.Add(SeenKey);

        foreach Name in Stored do
            if (Name <> '_item') then begin
                if StoredText <> '' then
                    StoredText += ', ';
                StoredText += Name;
            end;
        if StoredText = '' then
            StoredText := NothingTxt;
        Verify.AddFinding(Findings, Verify.WarningSeverity(), Step."Step No.", 'UnknownFieldReference',
            StrSubstNo(UnknownStepFieldMsg, Step."Step No.", StoringStep."Step No.", FieldName, StoredText),
            StrSubstNo(UnknownStepFieldNextStepTxt, StoringStep."Step No.", FieldName), Step.Disabled);
    end;

    /// <summary>
    /// The first segment of every target of the Result Log Paths of a step, lower case, plus _item for a forEach step.
    /// A mapping source>target stores at target; a mapping without an arrow stores at the path with dots as underscores.
    /// </summary>
    local procedure GetStoredFieldNames(StoringStep: Record "Playbook Step ori"; var Stored: List of [Text])
    var
        Mapping: Text;
        Target: Text;
        ArrowPos: Integer;
    begin
        Clear(Stored);
        foreach Mapping in StoringStep."Result Log Paths".Split(',') do begin
            Mapping := Mapping.Trim();
            if Mapping <> '' then begin
                ArrowPos := Mapping.IndexOf('>');
                if ArrowPos > 0 then
                    Target := CopyStr(Mapping, ArrowPos + 1).Trim().Split('.').Get(1)
                else
                    Target := Mapping.Replace('.', '_');
                Target := StripIndex(Target);
                if (Target <> '') and not Stored.Contains(Target.ToLower()) then
                    Stored.Add(Target.ToLower());
            end;
        end;
        if StoringStep.IsForEach() then
            Stored.Add('_item');
    end;

    /// <summary>
    /// @_current.fields.X in a forEach step whose source reads a table with Data.Records.Get: X must be the JSON name
    /// of a field of that table. A table or a source that cannot be determined is not judged.
    /// </summary>
    local procedure CheckCurrentField(Step: Record "Playbook Step ori"; Segments: List of [Text]; var Seen: List of [Text]; var Findings: JsonArray)
    var
        SourceStep: Record "Playbook Step ori";
        Verify: Codeunit "Playbook Verify ori";
        Lookup: Codeunit "Playbook Verify Lookup ori";
        FieldNames: Dictionary of [Text, Boolean];
        PrimaryKeyNames: List of [Text];
        SourceTemplate: JsonObject;
        Token: JsonToken;
        TableName: Text;
        ResolvedTableName: Text;
        FieldName: Text;
        SeenKey: Text;
    begin
        if (Segments.Count() < 3) or (Segments.Get(2).ToLower() <> 'fields') or not Step.IsForEach() then
            exit;
        if Step."Iterate Array Path".Trim() <> 'result' then
            exit;
        if Step."Iterate Source Step No." >= Step."Step No." then
            exit;
        SourceStep.SetLoadFields("Step No.", "Message Type");
        if not SourceStep.Get(Step."Playbook Code", Step."Iterate Source Step No.") then
            exit;
        if Verify.GetTypeName(SourceStep."Message Type") <> 'Data.Records.Get' then
            exit;
        if not SourceTemplate.ReadFrom(SourceStep.GetRequestTemplate()) then
            exit;
        if not (SourceTemplate.Get('tableName', Token) or SourceTemplate.Get('subject', Token)) then
            exit;
        if not Token.IsValue() then
            exit;
        TableName := Token.AsValue().AsText();
        if (TableName = '') or TableName.Contains('@') then
            exit;

        FieldName := StripIndex(Segments.Get(3));
        if FieldName = '' then
            exit;
        if not Lookup.TryGetFieldNames(TableName, FieldNames, ResolvedTableName) then
            exit;
        if FieldNames.ContainsKey(FieldName.ToLower()) then begin
            if not Lookup.TryGetPrimaryKeyNames(TableName, PrimaryKeyNames) then
                exit;
            if not PrimaryKeyNames.Contains(FieldName.ToLower()) then
                exit;
            SeenKey := StrSubstNo(SeenCurrentTok, FieldName.ToLower());
            if Seen.Contains(SeenKey) then
                exit;
            Seen.Add(SeenKey);
            Verify.AddFinding(Findings, Verify.WarningSeverity(), Step."Step No.", 'UnknownFieldReference',
                StrSubstNo(PrimaryKeyFieldMsg, Step."Step No.", FieldName, ResolvedTableName),
                StrSubstNo(PrimaryKeyFieldNextStepTxt, FieldName), Step.Disabled);
            exit;
        end;

        SeenKey := StrSubstNo(SeenCurrentTok, FieldName.ToLower());
        if Seen.Contains(SeenKey) then
            exit;
        Seen.Add(SeenKey);
        Verify.AddFinding(Findings, Verify.WarningSeverity(), Step."Step No.", 'UnknownFieldReference',
            StrSubstNo(UnknownCurrentFieldMsg, Step."Step No.", FieldName, ResolvedTableName),
            StrSubstNo(UnknownCurrentFieldNextStepTxt, ResolvedTableName), Step.Disabled);
    end;

    /// <summary>
    /// For an @_iter reference that follows "@N." returns N: the step whose same-iteration data is read.
    /// </summary>
    local procedure TryGetIterOwner(Value: Text; AtPos: Integer; var OwnerStepNo: Integer): Boolean
    var
        DigitsEnd: Integer;
        Index: Integer;
    begin
        if AtPos < 4 then
            exit(false);
        if Value[AtPos - 1] <> '.' then
            exit(false);
        DigitsEnd := AtPos - 2;
        Index := DigitsEnd;
        while (Index >= 1) and (Value[Index] >= '0') and (Value[Index] <= '9') do
            Index -= 1;
        if (Index = DigitsEnd) or (Index < 1) or (Value[Index] <> '@') then
            exit(false);
        exit(TryGetStepNo(CopyStr(Value, Index + 1, DigitsEnd - Index), OwnerStepNo));
    end;

    local procedure TryGetStepNo(Candidate: Text; var StepNo: Integer): Boolean
    var
        Ch: Char;
        Index: Integer;
    begin
        if (Candidate = '') or (StrLen(Candidate) > 9) then
            exit(false);
        for Index := 1 to StrLen(Candidate) do begin
            Ch := Candidate[Index];
            if (Ch < '0') or (Ch > '9') then
                exit(false);
        end;
        exit(Evaluate(StepNo, Candidate));
    end;

    local procedure PathEnd(Value: Text; AtPos: Integer): Integer
    var
        RefEnd: Integer;
    begin
        RefEnd := AtPos + 1;
        while (RefEnd <= StrLen(Value)) and IsPathChar(Value[RefEnd]) do
            RefEnd += 1;
        // A path never ends with a dot: a trailing dot is sentence punctuation (the resolver does the same).
        while (RefEnd > AtPos + 1) and (Value[RefEnd - 1] = '.') do
            RefEnd -= 1;
        exit(RefEnd);
    end;

    local procedure IsPathChar(Ch: Char): Boolean
    begin
        exit(IsLetterOrDigit(Ch) or (Ch in ['.', '_', '[', ']']));
    end;

    local procedure IsLetterOrDigit(Ch: Char): Boolean
    begin
        exit(((Ch >= 'a') and (Ch <= 'z')) or ((Ch >= 'A') and (Ch <= 'Z')) or ((Ch >= '0') and (Ch <= '9')));
    end;

    local procedure StripIndex(Segment: Text): Text
    var
        BracketPos: Integer;
    begin
        BracketPos := Segment.IndexOf('[');
        if BracketPos = 0 then
            exit(Segment);
        exit(CopyStr(Segment, 1, BracketPos - 1));
    end;

    var
        SeenStepTok: Label 'step|%1', Locked = true;
        SeenFieldTok: Label 'field|%1|%2', Locked = true;
        SeenCurrentTok: Label 'current|%1', Locked = true;
        TemplateNotJsonMsg: Label 'The request template of step %1 is not a valid JSON object. The engine does not fail on it: it sends an empty request {} to the message type.', Comment = '%1 = step no, is-IS=Beiðnisniðmát skrefs %1 er ekki gildur JSON-hlutur. Vélin stoppar ekki á því: hún sendir tóma beiðni {} til skilaboðategundarinnar.';
        TemplateNotJsonNextStepTxt: Label 'Fix the template: it must be one JSON object, with every string in double quotes and no comma after the last item. Set it again as base64 of the corrected JSON.', Comment = 'is-IS=Lagaðu sniðmátið: það verður að vera einn JSON-hlutur, með alla strengi innan tvöfaldra gæsalappa og án kommu á eftir síðasta atriði. Settu það aftur sem base64 af leiðrétta JSON-textanum.';
        StepNotFoundMsg: Label 'Step %1 refers to step %2 (@%2...), which does not exist in this playbook. The reference stays as literal text in the request.', Comment = '%1 = step no, %2 = referenced step no, is-IS=Skref %1 vísar í skref %2 (@%2...), sem er ekki til í þessari keðju. Tilvísunin helst sem hreinn texti í beiðninni.';
        StepNotFoundNextStepTxt: Label 'Correct the step number in the reference, or add the missing step.', Comment = 'is-IS=Leiðréttu skrefsnúmerið í tilvísuninni, eða bættu við skrefinu sem vantar.';
        StepNotEarlierMsg: Label 'Step %1 refers to step %2 (@%2...), which does not run before it, so its result does not exist yet when this step builds its request. The reference stays as literal text.', Comment = '%1 = step no, %2 = referenced step no, is-IS=Skref %1 vísar í skref %2 (@%2...), sem keyrir ekki á undan því, svo niðurstaða þess er ekki til þegar þetta skref býr til beiðni sína. Tilvísunin helst sem hreinn texti.';
        StepNotEarlierNextStepTxt: Label 'Refer only to steps with a lower number, or renumber the steps so that the step you read from comes first.', Comment = 'is-IS=Vísaðu aðeins í skref með lægra númer, eða endurnúmeraðu skrefin þannig að skrefið sem þú lest úr komi fyrst.';
        RoleNotFoundMsg: Label 'Step %1 calls %2 with roleCode %3, but this company has no language model with that code. Every call would answer RecordNotFound.', Comment = '%1 = step no, %2 = message type, %3 = role code, is-IS=Skref %1 kallar á %2 með roleCode %3, en þetta fyrirtæki hefur ekkert mállíkan með þeim kóða. Hvert kall myndi svara RecordNotFound.';
        RoleNotFoundNextStepTxt: Label 'List the codes with Data.Records.Get on table "Bifrost Language Model ori", then use one of them, or leave roleCode out to use the default language model.', Comment = 'is-IS=Sæktu kóðana með Data.Records.Get á töfluna "Bifrost Language Model ori" og notaðu einn þeirra, eða slepptu roleCode til að nota sjálfgefið mállíkan.';
        UnknownStepFieldMsg: Label 'Step %1 reads @%2.%3, but step %2 stores no field %3 in the workspace (its Result Log Paths store: %4). The reference stays as literal text.', Comment = '%1 = step no, %2 = storing step no, %3 = field name, %4 = the stored fields, is-IS=Skref %1 les @%2.%3, en skref %2 geymir ekkert %3 í vinnusvæðinu (Niðurstöðuskráningarslóðir þess geyma: %4). Tilvísunin helst sem hreinn texti.';
        UnknownStepFieldNextStepTxt: Label 'Add the field to Result Log Paths on step %1 (for example result>%2), or correct the name in the reference.', Comment = '%1 = storing step no, %2 = field name, is-IS=Bættu reitnum við Niðurstöðuskráningarslóðir í skrefi %1 (til dæmis result>%2), eða leiðréttu heitið í tilvísuninni.';
        UnknownCurrentFieldMsg: Label 'Step %1 reads @_current.fields.%2, but table %3 has no field with that name. The reference stays as literal text.', Comment = '%1 = step no, %2 = field name, %3 = table name, is-IS=Skref %1 les @_current.fields.%2, en taflan %3 hefur engan reit með því nafni. Tilvísunin helst sem hreinn texti.';
        UnknownCurrentFieldNextStepTxt: Label 'A field name in an answer has no spaces and no punctuation except _ (for example No_ for No.). Call Help.Fields.Get on table %1 to list the fields.', Comment = '%1 = table name, is-IS=Reitaheiti í svari hefur engin bil og engin greinarmerki nema _ (til dæmis No_ fyrir No.). Kallaðu á Help.Fields.Get á töfluna %1 til að sjá reitina.';
        PrimaryKeyFieldMsg: Label 'Step %1 reads @_current.fields.%2, but %2 is a primary-key field of table %3 and is returned under primaryKey, not fields.', Comment = '%1 = step no, %2 = JSON field name, %3 = table name, is-IS=Skref %1 les @_current.fields.%2, en %2 er aðallykilsreitur í töflunni %3 og er skilað undir primaryKey, ekki fields.';
        PrimaryKeyFieldNextStepTxt: Label 'Use @_current.primaryKey.%1 and inspect the source answer before running the playbook.', Comment = '%1 = JSON field name, is-IS=Notaðu @_current.primaryKey.%1 og skoðaðu upprunasvarið áður en verkbókin er keyrð.';
        NothingTxt: Label 'nothing', Comment = 'is-IS=ekkert';
}
