namespace Origo.Bifrost.Orchestrator;

/// <summary>
/// Confirm-from-preview for unattended playbooks (issue #189, decision core#1365 D3). A message step whose request
/// template carries <c>"expectedCount": "@preview"</c> calls the type without expectedCount, reads the count Foundation
/// returns in <c>expected</c> of its ConfirmationRequired answer, and repeats the call with that count only when it is
/// at most the Max Count the playbook author set on the step. Above the cap the step fails and nothing irreversible is
/// executed. The setting Require Confirmation for Irreversible Messages is never changed and no playbook is
/// pre-authorised: the author's cap bounds every single run.
/// </summary>
codeunit 10035621 "Playbook Preview Count ori"
{
    Access = Internal;

    /// <summary>
    /// Removes the <c>"expectedCount": "@preview"</c> marker from a request template so that the reference resolver
    /// does not treat it as a workspace reference.
    /// </summary>
    /// <param name="RequestJson">The request template; the marker is removed when present.</param>
    /// <returns>True when the template asked for confirm-from-preview.</returns>
    procedure TakeMarker(var RequestJson: JsonObject): Boolean
    begin
        if not IsMarker(RequestJson) then
            exit(false);
        RequestJson.Remove(ExpectedCountTok);
        exit(true);
    end;

    /// <summary>
    /// Tells whether a request template carries the <c>@preview</c> marker.
    /// </summary>
    /// <param name="RequestJson">The request template.</param>
    /// <returns>True when expectedCount is the text @preview.</returns>
    procedure IsMarker(RequestJson: JsonObject): Boolean
    var
        CountToken: JsonToken;
    begin
        if not RequestJson.Get(ExpectedCountTok, CountToken) then
            exit(false);
        if not CountToken.IsValue() then
            exit(false);
        if CountToken.AsValue().IsNull() then
            exit(false);
        exit(CountToken.AsValue().AsText().Trim().ToLower() = PreviewTok);
    end;

    /// <summary>
    /// Runs a message step with confirm-from-preview: preview without expectedCount, confirm with the previewed count
    /// when it is within Max Count, otherwise refuse.
    /// </summary>
    /// <param name="Step">The step; Max Count is its cap.</param>
    /// <param name="RequestText">The request without expectedCount; receives the request actually sent last.</param>
    /// <param name="ResponseText">Receives the response of the call that decided the step.</param>
    /// <param name="Success">Receives whether the step succeeded.</param>
    /// <param name="ErrorText">Receives the error text when the step failed.</param>
    /// <param name="Note">Receives the line for the run log: the preview count and the confirmed count or the refusal.</param>
    procedure Run(Step: Record "Playbook Step ori"; var RequestText: Text; var ResponseText: Text; var Success: Boolean; var ErrorText: Text; var Note: Text)
    var
        StepExecutor: Codeunit "Playbook Step Executor ori";
        PreviewCount: Integer;
        IsConfirmationRequest: Boolean;
    begin
        Clear(ResponseText);
        ErrorText := '';
        Note := '';

        // Nothing is sent before the author's cap exists: an unbounded preview-confirm would pre-authorise the step.
        if Step."Max Count" <= 0 then begin
            Refuse(StrSubstNo(NoMaxCountErr, Step."Step No."), -1, Step."Max Count", ResponseText, Success, ErrorText, Note);
            exit;
        end;

        Commit();
        Success := StepExecutor.Execute(Step."Message Type", '', RequestText, ResponseText, ErrorText);
        IsConfirmationRequest := ReadPreview(ResponseText, PreviewCount);
        if not IsConfirmationRequest then begin
            // Foundation asked for no confirmation (a type that is not irreversible, or the setting is off): the
            // single call above was the run. It is never repeated.
            if Success then
                Note := StrSubstNo(NoConfirmationTxt, Step."Max Count");
            exit;
        end;

        if PreviewCount < 0 then begin
            Refuse(StrSubstNo(NoCountErr, Step."Step No."), PreviewCount, Step."Max Count", ResponseText, Success, ErrorText, Note);
            exit;
        end;
        if PreviewCount > Step."Max Count" then begin
            Refuse(StrSubstNo(OverCapErr, Step."Step No.", PreviewCount, Step."Max Count"), PreviewCount, Step."Max Count", ResponseText, Success, ErrorText, Note);
            exit;
        end;

        RequestText := AddExpectedCount(RequestText, PreviewCount);
        Note := StrSubstNo(ConfirmedTxt, PreviewCount, Step."Max Count", PreviewCount);
        ErrorText := '';
        Commit();
        Success := StepExecutor.Execute(Step."Message Type", '', RequestText, ResponseText, ErrorText);
    end;

    /// <summary>
    /// Reads a ConfirmationRequired answer. The answer is a response, or the text of a raised error.
    /// </summary>
    /// <param name="AnswerText">The text the call returned.</param>
    /// <param name="PreviewCount">Receives the count in expected, or -1 when the answer carries no whole count.</param>
    /// <returns>True when the answer is ConfirmationRequired.</returns>
    local procedure ReadPreview(AnswerText: Text; var PreviewCount: Integer): Boolean
    var
        AnswerJson: JsonObject;
        CodeToken: JsonToken;
        ExpectedToken: JsonToken;
        ExpectedText: Text;
    begin
        PreviewCount := -1;
        if AnswerText = '' then
            exit(false);
        if not AnswerJson.ReadFrom(AnswerText) then
            exit(false);
        if not AnswerJson.Get('code', CodeToken) then
            exit(false);
        if not CodeToken.IsValue() then
            exit(false);
        if CodeToken.AsValue().AsText() <> 'ConfirmationRequired' then
            exit(false);
        if not AnswerJson.Get('expected', ExpectedToken) then
            exit(true);
        if not ExpectedToken.IsValue() then
            exit(true);
        if ExpectedToken.AsValue().IsNull() then
            exit(true);
        ExpectedText := ExpectedToken.AsValue().AsText().Trim();
        if not IsWholeNumber(ExpectedText) then
            exit(true);
        if not Evaluate(PreviewCount, ExpectedText, 9) then
            PreviewCount := -1;
        exit(true);
    end;

    local procedure IsWholeNumber(Value: Text): Boolean
    var
        Index: Integer;
    begin
        if (Value = '') or (StrLen(Value) > 9) then
            exit(false);
        for Index := 1 to StrLen(Value) do
            if not (Value[Index] in ['0' .. '9']) then
                exit(false);
        exit(true);
    end;

    local procedure AddExpectedCount(RequestText: Text; Count: Integer): Text
    var
        RequestJson: JsonObject;
    begin
        if RequestText <> '' then
            RequestJson.ReadFrom(RequestText);
        if RequestJson.Contains(ExpectedCountTok) then
            RequestJson.Remove(ExpectedCountTok);
        RequestJson.Add(ExpectedCountTok, Count);
        RequestJson.WriteTo(RequestText);
        exit(RequestText);
    end;

    local procedure Refuse(Reason: Text; PreviewCount: Integer; MaxCount: Integer; var ResponseText: Text; var Success: Boolean; var ErrorText: Text; var Note: Text)
    var
        RefusalJson: JsonObject;
    begin
        ErrorText := ConfirmationRequiredTok + ': ' + Reason;
        Success := false;
        Note := StrSubstNo(RefusedTxt, Reason);
        RefusalJson.Add('status', 'Error');
        RefusalJson.Add('code', ConfirmationRequiredTok);
        RefusalJson.Add('error', Reason);
        RefusalJson.Add('parameter', 'maxCount');
        if PreviewCount >= 0 then
            RefusalJson.Add('expected', PreviewCount);
        RefusalJson.Add('maxCount', MaxCount);
        RefusalJson.WriteTo(ResponseText);
    end;

    var
        PreviewTok: Label '@preview', Locked = true;
        ExpectedCountTok: Label 'expectedCount', Locked = true;
        ConfirmationRequiredTok: Label 'ConfirmationRequired', Locked = true;
        NoMaxCountErr: Label 'Step %1 sends "expectedCount": "@preview" but has no Max Count. Set Max Count on the step to the most the playbook may confirm. Nothing was executed.', Comment = '%1 = step no, is-IS=Skref %1 sendir "expectedCount": "@preview" en hefur engan hámarksfjölda. Settu hámarksfjölda á skrefið, mest það sem keðjan má staðfesta. Ekkert var keyrt.';
        NoCountErr: Label 'The preview of step %1 returned no whole count in "expected", so there is nothing to confirm. Nothing was executed.', Comment = '%1 = step no, is-IS=Forskoðun skrefs %1 skilaði engum heiltölufjölda í "expected", svo ekkert er til að staðfesta. Ekkert var keyrt.';
        OverCapErr: Label 'The preview of step %1 counts %2, above the Max Count of %3. The step was not confirmed and nothing was executed.', Comment = '%1 = step no, %2 = previewed count, %3 = Max Count, is-IS=Forskoðun skrefs %1 telur %2, yfir hámarksfjölda %3. Skrefið var ekki staðfest og ekkert var keyrt.';
        ConfirmedTxt: Label 'Preview count %1, Max Count %2: confirmed with expectedCount %3.', Comment = '%1 = previewed count, %2 = Max Count, %3 = confirmed count, is-IS=Forskoðunarfjöldi %1, hámarksfjöldi %2: staðfest með expectedCount %3.';
        NoConfirmationTxt: Label 'Max Count %1: the type asked for no confirmation, so it ran once without expectedCount.', Comment = '%1 = Max Count, is-IS=Hámarksfjöldi %1: tegundin bað ekki um staðfestingu, svo hún keyrði einu sinni án expectedCount.';
        RefusedTxt: Label 'Refused: %1', Comment = '%1 = the reason, is-IS=Hafnað: %1';
}
