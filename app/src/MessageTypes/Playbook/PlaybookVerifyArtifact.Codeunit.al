/// <summary>
/// The checks of Orchestrator.Playbook.Verify that guard an artifact chain (read a stored HTML file, refresh it with
/// LLM.Prompt.Ask, sanitize the answer, send it): an email whose body or attachment is not bound to a
/// Content.Html.Sanitize answer, an Ask step without tools.allow and an email to a literal address. They look at the
/// invariant message type names only, so this app needs no dependency on the apps that provide the types.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

codeunit 10035621 "Playbook Verify Artifact ori"
{
    Access = Internal;
    Permissions = tabledata "Playbook Step ori" = R;

    /// <summary>Runs the artifact checks on one step.</summary>
    /// <param name="Step">The step to check.</param>
    /// <param name="Findings">Receives the warnings of the step.</param>
    internal procedure CheckStep(Step: Record "Playbook Step ori"; var Findings: JsonArray)
    var
        Verify: Codeunit "Playbook Verify ori";
        TemplateJson: JsonObject;
        TemplateText: Text;
        TypeName: Text;
    begin
        TypeName := Verify.GetAliasedTypeName(Step."Message Type");
        if (TypeName <> AskTypeNameTok) and not IsEmailType(TypeName) then
            exit;
        TemplateText := Step.GetRequestTemplate();
        // A template that is not a JSON object has its own error (TemplateNotJson).
        if (TemplateText.Trim() <> '') and not TemplateJson.ReadFrom(TemplateText) then
            exit;
        if TypeName = AskTypeNameTok then
            CheckAskToolsAllow(Step, TemplateJson, Findings)
        else begin
            CheckEmailContent(Step, TemplateJson, Findings);
            CheckEmailRecipients(Step, TemplateJson, Findings);
        end;
    end;

    /// <summary>Tells whether a message type name sends or drafts an email.</summary>
    /// <param name="TypeName">The invariant message type name.</param>
    /// <returns>True for Email.Draft.Set and Orchestrator.Email.Send.</returns>
    internal procedure IsEmailType(TypeName: Text): Boolean
    begin
        exit((TypeName = EmailDraftTypeNameTok) or (TypeName = EmailSendTypeNameTok));
    end;

    local procedure CheckAskToolsAllow(Step: Record "Playbook Step ori"; TemplateJson: JsonObject; var Findings: JsonArray)
    var
        Verify: Codeunit "Playbook Verify ori";
        ToolsToken: JsonToken;
        AllowToken: JsonToken;
    begin
        // A reference (@...) is resolved at run time and is not judged here. AL does not short-circuit: never
        // dereference a token before its kind is known.
        if TemplateJson.Get('tools', ToolsToken) then begin
            if ToolsToken.IsValue() then
                if ToolsToken.AsValue().AsText().StartsWith('@') then
                    exit;
            if ToolsToken.IsObject() then
                if ToolsToken.AsObject().Get('allow', AllowToken) then begin
                    if AllowToken.IsArray() then
                        if AllowToken.AsArray().Count() > 0 then
                            exit;
                    if AllowToken.IsValue() then
                        if AllowToken.AsValue().AsText().StartsWith('@') then
                            exit;
                end;
        end;
        Verify.AddFinding(Findings, Verify.WarningSeverity(), Step."Step No.", 'AskWithoutToolsAllow',
            StrSubstNo(AskWithoutToolsAllowMsg, Step."Step No."), AskWithoutToolsAllowNextStepTxt, Step.Disabled);
    end;

    local procedure CheckEmailContent(Step: Record "Playbook Step ori"; TemplateJson: JsonObject; var Findings: JsonArray)
    var
        Token: JsonToken;
        Attachment: JsonToken;
        ContentToken: JsonToken;
        PropertyName: Text;
    begin
        foreach PropertyName in BodyPropertyNames() do
            if TemplateJson.Get(PropertyName, Token) then
                if IsUnsanitizedBody(Step, Token) then
                    ReportUnsanitized(Step, PropertyName, Findings);

        if not TemplateJson.Get('attachments', Token) then
            exit;
        if not Token.IsArray() then
            exit;
        foreach Attachment in Token.AsArray() do
            if Attachment.IsObject() then
                if Attachment.AsObject().Get('contentText', ContentToken) then
                    if IsUnsanitizedText(Step, ContentToken) then
                        ReportUnsanitized(Step, 'attachments[].contentText', Findings);
    end;

    local procedure ReportUnsanitized(Step: Record "Playbook Step ori"; PropertyName: Text; var Findings: JsonArray)
    var
        Verify: Codeunit "Playbook Verify ori";
    begin
        Verify.AddFinding(Findings, Verify.WarningSeverity(), Step."Step No.", 'EmailContentNotSanitized',
            StrSubstNo(EmailContentNotSanitizedMsg, Step."Step No.", PropertyName), EmailContentNotSanitizedNextStepTxt, Step.Disabled);
    end;

    /// <summary>A body written in the template is the author's own text. A body that carries a step reference must carry the answer of a Content.Html.Sanitize step.</summary>
    local procedure IsUnsanitizedBody(Step: Record "Playbook Step ori"; Token: JsonToken): Boolean
    var
        Value: Text;
        AtPos: Integer;
    begin
        if not Token.IsValue() then
            exit(false);
        if Token.AsValue().IsNull() then
            exit(false);
        Value := Token.AsValue().AsText();
        AtPos := Value.IndexOf('@');
        while AtPos > 0 do begin
            if AtPos < StrLen(Value) then
                if Value[AtPos + 1] in ['0' .. '9'] then
                    exit(not IsSanitizedReference(Step, Value));
            AtPos := Value.IndexOf('@', AtPos + 1);
        end;
        exit(false);
    end;

    /// <summary>True when a text value is not a whole-value reference to the answer of an earlier Content.Html.Sanitize step.</summary>
    local procedure IsUnsanitizedText(Step: Record "Playbook Step ori"; Token: JsonToken): Boolean
    var
        Value: Text;
    begin
        if not Token.IsValue() then
            exit(false);
        if Token.AsValue().IsNull() then
            exit(false);
        Value := Token.AsValue().AsText();
        if Value.Trim() = '' then
            exit(false);
        exit(not IsSanitizedReference(Step, Value));
    end;

    local procedure IsSanitizedReference(Step: Record "Playbook Step ori"; Value: Text): Boolean
    var
        SourceStep: Record "Playbook Step ori";
        Verify: Codeunit "Playbook Verify ori";
        Reference: Text;
        StepNoText: Text;
        StepNo: Integer;
        DotPos: Integer;
    begin
        if not Value.StartsWith('@') or Value.Contains(' ') then
            exit(false);
        Reference := CopyStr(Value, 2);
        DotPos := Reference.IndexOf('.');
        if DotPos < 2 then
            exit(false);
        StepNoText := CopyStr(Reference, 1, DotPos - 1);
        if not Evaluate(StepNo, StepNoText) then
            exit(false);
        if (StepNo <= 0) or (StepNo >= Step."Step No.") then
            exit(false);
        SourceStep.SetLoadFields("Step No.", "Message Type");
        if not SourceStep.Get(Step."Playbook Code", StepNo) then
            exit(false);
        exit(Verify.GetAliasedTypeName(SourceStep."Message Type") = SanitizeTypeNameTok);
    end;

    local procedure CheckEmailRecipients(Step: Record "Playbook Step ori"; TemplateJson: JsonObject; var Findings: JsonArray)
    var
        Token: JsonToken;
        PropertyName: Text;
    begin
        foreach PropertyName in RecipientPropertyNames() do
            if TemplateJson.Get(PropertyName, Token) then
                if HasLiteralAddress(Token) then
                    AddRecipientFinding(Step, PropertyName, Findings);
    end;

    local procedure HasLiteralAddress(Token: JsonToken): Boolean
    var
        Item: JsonToken;
    begin
        if not Token.IsArray() then
            exit(IsLiteralAddress(Token));
        foreach Item in Token.AsArray() do
            if IsLiteralAddress(Item) then
                exit(true);
        exit(false);
    end;

    local procedure AddRecipientFinding(Step: Record "Playbook Step ori"; PropertyName: Text; var Findings: JsonArray)
    var
        Verify: Codeunit "Playbook Verify ori";
    begin
        Verify.AddFinding(Findings, Verify.WarningSeverity(), Step."Step No.", 'EmailLiteralRecipient',
            StrSubstNo(EmailLiteralRecipientMsg, Step."Step No.", PropertyName), EmailLiteralRecipientNextStepTxt, Step.Disabled);
    end;

    /// <summary>A literal address has an @ after a first character; a reference starts with @.</summary>
    local procedure IsLiteralAddress(Token: JsonToken): Boolean
    var
        Value: Text;
    begin
        if not Token.IsValue() then
            exit(false);
        if Token.AsValue().IsNull() then
            exit(false);
        Value := Token.AsValue().AsText().Trim();
        if Value.StartsWith('@') then
            exit(false);
        exit(Value.IndexOf('@') > 1);
    end;

    local procedure BodyPropertyNames() Names: List of [Text]
    begin
        Names.AddRange('htmlBody', 'body');
    end;

    local procedure RecipientPropertyNames() Names: List of [Text]
    begin
        Names.AddRange('to', 'cc', 'bcc');
    end;

    var
        AskTypeNameTok: Label 'LLM.Prompt.Ask', Locked = true;
        SanitizeTypeNameTok: Label 'Content.Html.Sanitize', Locked = true;
        EmailDraftTypeNameTok: Label 'Email.Draft.Set', Locked = true;
        EmailSendTypeNameTok: Label 'Orchestrator.Email.Send', Locked = true;
        AskWithoutToolsAllowMsg: Label 'Ask step %1 has no tools.allow. Without an explicit list the model may be offered every tool the caller may use, also tools that write.', Comment = '%1 = Ask step no, is-IS=Ask-skref %1 hefur ekkert tools.allow. Án skýrs lista gæti líkaninu staðið til boða hvert það verkfæri sem kallandinn má nota, líka verkfæri sem skrifa.';
        AskWithoutToolsAllowNextStepTxt: Label 'Add tools.allow to the request template of step %1 with the read tools the question needs, for example {"tools":{"allow":["get_records"]}}.', Comment = '%1 = Ask step no, is-IS=Bættu tools.allow við beiðnisniðmát skrefs %1 með þeim lesverkfærum sem spurningin þarf, til dæmis {"tools":{"allow":["get_records"]}}.';
        EmailContentNotSanitizedMsg: Label 'Email step %1 sets %2 to something other than the answer of a Content.Html.Sanitize step that runs before it. Model output or stored HTML can carry script, so it must not reach a recipient unsanitized.', Comment = '%1 = email step no, %2 = request property, is-IS=Tölvupóstskref %1 stillir %2 á annað en svar Content.Html.Sanitize-skrefs sem keyrir á undan því. Úttak líkans eða vistað HTML getur borið skriftu, svo það má ekki berast viðtakanda ósótthreinsað.';
        EmailContentNotSanitizedNextStepTxt: Label 'Add a Content.Html.Sanitize step after the step that produces the HTML and bind this property to its answer, for example "@3.html".', Comment = 'is-IS=Bættu við Content.Html.Sanitize-skrefi á eftir skrefinu sem býr til HTML og bindðu þennan eiginleika við svar þess, til dæmis "@3.html".';
        EmailLiteralRecipientMsg: Label 'Email step %1 has a literal address in %2. A playbook that sends a model-produced artifact must not carry an external recipient in its template.', Comment = '%1 = email step no, %2 = request property, is-IS=Tölvupóstskref %1 hefur fast netfang í %2. Keðja sem sendir afurð frá líkani má ekki bera ytri viðtakanda í sniðmáti sínu.';
        EmailLiteralRecipientNextStepTxt: Label 'Take the recipient from a setup field or a reference, for example "@_who.salesperson.email", never from a literal address.', Comment = 'is-IS=Taktu viðtakandann úr uppsetningarreit eða tilvísun, til dæmis "@_who.salesperson.email", aldrei úr föstu netfangi.';
}
