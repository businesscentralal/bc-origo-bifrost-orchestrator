namespace Origo.Bifrost.Orchestrator;

/// <summary>Checks Transform mappings without running a message or reading business records.</summary>
codeunit 10035628 "Playbook Transform Verify ori"
{
    Access = Internal;
    Permissions = tabledata "Playbook Transform ori" = R;

    /// <summary>Reports invalid kind configuration, missing paths and conflicting targets.</summary>
    /// <param name="Step">The Transform step.</param>
    /// <param name="Findings">Receives ordinary Verify findings.</param>
    internal procedure CheckStep(Step: Record "Playbook Step ori"; var Findings: JsonArray)
    var
        Mapping: Record "Playbook Transform ori";
        Executor: Codeunit "Playbook Transform Exec ori";
        Verify: Codeunit "Playbook Verify ori";
        Targets: List of [Text];
        Target: Text;
    begin
        if Step."Message Type".AsInteger() <> 0 then
            Verify.AddFinding(Findings, Verify.ErrorSeverity(), Step."Step No.", 'TransformMessageType', MessageTypeErr,
                StrSubstNo(ClearMessageTypeTxt, Step."Step No."), Step.Disabled);
        if Step.Paged then
            AddError(Step, Findings, 'TransformPaged', PagedErr);
        Mapping.SetRange("Playbook Code", Step."Playbook Code");
        Mapping.SetRange("Step No.", Step."Step No.");
        Mapping.SetLoadFields("Target Path", "Source Path", Operation, "Argument 1", "Argument 2");
        Mapping.ReadIsolation := IsolationLevel::ReadCommitted;
        if not Mapping.FindSet() then begin
            AddError(Step, Findings, 'TransformWithoutMapping', NoMappingsErr);
            exit;
        end;
        repeat
            if not Executor.IsTargetPathValid(Mapping."Target Path") then
                AddError(Step, Findings, 'TransformTargetInvalid', StrSubstNo(TargetErr, Mapping."Target Path"));
            foreach Target in Targets do
                if (Target = Mapping."Target Path") or Target.StartsWith(Mapping."Target Path" + '.') or Mapping."Target Path".StartsWith(Target + '.') then
                    AddError(Step, Findings, 'TransformTargetOverlap', StrSubstNo(TargetErr, Mapping."Target Path"));
            Targets.Add(Mapping."Target Path");
            if Mapping.Operation <> Mapping.Operation::Constant then
                CheckSource(Step, Mapping."Source Path", Findings);
            if (Mapping.Operation = Mapping.Operation::"Replace Text") and (Mapping."Argument 1" = '') then
                AddError(Step, Findings, 'TransformSearchEmpty', SearchErr);
            if not (Mapping.Operation in [Mapping.Operation::Copy, Mapping.Operation::Constant, Mapping.Operation::Negate, Mapping.Operation::"Replace Text"]) then
                AddError(Step, Findings, 'TransformOperationUnknown', OperationErr);
        until Mapping.Next() = 0;
    end;

    local procedure CheckSource(Step: Record "Playbook Step ori"; Path: Text; var Findings: JsonArray)
    var
        TemplateChecks: Codeunit "Playbook Verify Template ori";
        JsonHelper: Codeunit "Playbook JSON Helper ori";
        Input: JsonObject;
        Template: JsonObject;
        Token: JsonToken;
        TemplateText: Text;
    begin
        if Path = '' then begin
            AddError(Step, Findings, 'TransformSourceUnknown', SourceErr);
            exit;
        end;
        if not Path.StartsWith('@') then
            if Step.IsForEach() then
                Path := '@_current.' + Path
            else begin
                if not Input.ReadFrom(Step.GetRequestTemplate()) then begin
                    AddError(Step, Findings, 'TransformSourceUnknown', StrSubstNo(SourcePathErr, Path));
                    exit;
                end;
                if not JsonHelper.ResolveJsonPath(Input, Path, Token) then
                    AddError(Step, Findings, 'TransformSourceUnknown', StrSubstNo(SourcePathErr, Path));
                exit;
            end;
        if Path.StartsWith('@_') then
            if not (Path.StartsWith('@_current.') or Path.StartsWith('@_initial.') or Path.StartsWith('@_sys.') or Path.StartsWith('@_who.') or Path.StartsWith('@_run.') or Path.StartsWith('@_steps.') or (Path = '@_iter')) then begin
                AddError(Step, Findings, 'TransformSourceUnknown', StrSubstNo(SourcePathErr, Path));
                exit;
            end;
        if Path.StartsWith('@_current.') and not Step.IsForEach() then begin
            AddError(Step, Findings, 'TransformSourceUnknown', StrSubstNo(SourcePathErr, Path));
            exit;
        end;
        // Reuse the same reference checks as request templates, on an unpersisted record buffer.
        Template.Add('source', Path);
        Template.WriteTo(TemplateText);
        Step.SetRequestTemplate(TemplateText);
        TemplateChecks.CheckTemplate(Step, Findings);
    end;

    local procedure AddError(Step: Record "Playbook Step ori"; var Findings: JsonArray; Code: Text; MessageText: Text)
    var
        Verify: Codeunit "Playbook Verify ori";
    begin
        Verify.AddFinding(Findings, Verify.ErrorSeverity(), Step."Step No.", Code, MessageText, NextStepTxt, Step.Disabled);
    end;

    var
        MessageTypeErr: Label 'Remove the message type from the Transform step.', Comment = 'is-IS=Fjarlægðu skilaboðagerðina úr umbreytingarskrefinu.';
        PagedErr: Label 'A Transform step cannot fetch pages. Iterate over a preceding reader step instead.', Comment = 'is-IS=Umbreytingarskref getur ekki sótt síður. Ítraðu í staðinn yfir fyrra lestrarskref.';
        NoMappingsErr: Label 'A Transform step needs at least one field mapping.', Comment = 'is-IS=Umbreytingarskref þarf að minnsta kosti eina reitavörpun.';
        TargetErr: Label 'Transform target %1 is empty, invalid or overlaps another target.', Comment = '%1 = target path, is-IS=Markslóð umbreytingar %1 er auð, ógild eða skarast við aðra markslóð.';
        SourceErr: Label 'A non-Constant transform needs a source path.', Comment = 'is-IS=Umbreyting sem er ekki fasti þarf upprunaslóð.';
        SourcePathErr: Label 'Transform source path %1 is unknown in this input.', Comment = '%1 = source path, is-IS=Upprunaslóð umbreytingar %1 er óþekkt í þessu inntaki.';
        SearchErr: Label 'Replace Text requires a nonempty search string in Argument 1.', Comment = 'is-IS=Textaskipti krefjast leitartexta í viðfangi 1.';
        OperationErr: Label 'The transform operation is not supported.', Comment = 'is-IS=Umbreytingaraðgerðin er ekki studd.';
        ClearMessageTypeTxt: Label 'Clear the Message Type on step %1: re-select Step Kind = Transform on the step (page or Data.Records.Set), which clears it, then verify the playbook again.', Comment = '%1 = step number, is-IS=Hreinsaðu skilaboðagerðina á skrefi %1: veldu aftur tegund skrefs Umbreyting á skrefinu (síða eða Data.Records.Set), það hreinsar hana, og yfirfarðu keðjuna aftur.';
        NextStepTxt: Label 'Correct the Transform field mappings and verify the playbook again.', Comment = 'is-IS=Leiðréttu reitavarpanir umbreytingarinnar og yfirfarðu keðjuna aftur.';
}
