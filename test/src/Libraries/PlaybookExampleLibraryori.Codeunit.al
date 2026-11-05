namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;

/// <summary>
/// The worked examples of Help.Orchestrator.Get ("Worked Playbook Examples"), built step by step with the same
/// templates, conditions and gates the help prints. The templates are public functions so a test can check that the
/// help carries their base64 text.
/// </summary>
codeunit 96438 "Playbook Example Library ori"
{
    Access = Internal;

    var
        Lib: Codeunit "Playbook Test Library ori";

    /// <summary>
    /// Builds example 1 (CREDIT-CTRL): read customers (10), a Check per customer (30), a write per customer (40) and a notice (90).
    /// With <c>GateStepNo</c> 0 it is example 3, the anti-pattern.
    /// </summary>
    /// <param name="PlaybookCode">The code of the playbook to create.</param>
    /// <param name="GateStepNo">Skip If Step Failed of step 40: 30 is the corrected shape, 0 the ungated write.</param>
    procedure BuildCreditControl(PlaybookCode: Code[20]; GateStepNo: Integer)
    begin
        Lib.CreatePlaybook(PlaybookCode);
        Lib.AddStep(PlaybookCode, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", CreditReadTemplate(), 0, '', 0);
        Lib.AddStep(PlaybookCode, 30, "Playbook Step Type ori"::Check, "Message Type ori"::"Data.Records.Get", CreditDecideTemplate(), 10, 'result', 0);
        Lib.AddStep(PlaybookCode, 40, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Set", CreditBlockTemplate(), 10, 'result', GateStepNo);
        Lib.AddStep(PlaybookCode, 90, "Playbook Step Type ori"::Action, "Message Type ori"::"Orchestrator.Telegram.Message", CreditNoticeTemplate(), 0, '', 0);

        Lib.SetResultLogPaths(PlaybookCode, 10, 'noOfRecords>customerCount');
        Lib.SetNextSteps(PlaybookCode, 10, 30, 0);
        Lib.SetNextSteps(PlaybookCode, 30, 40, 40);
        Lib.SetNextSteps(PlaybookCode, 40, 90, 90);
        Lib.SetNextSteps(PlaybookCode, 90, 0, 0);
        Lib.SetExcludeFromRunStatus(PlaybookCode, 90);

        Lib.AddStatusSuccessCondition(PlaybookCode, 10);
        Lib.AddNoOfRecordsCondition(PlaybookCode, 10);
        Lib.AddStatusSuccessCondition(PlaybookCode, 30);
        Lib.AddNoOfRecordsCondition(PlaybookCode, 30);
        Lib.AddStatusSuccessCondition(PlaybookCode, 40);
        Lib.AddCondition(PlaybookCode, 90, "Playbook Cond. Type ori"::Start, 10000, '_who.telegramChatId', "Playbook Cond. Operator ori"::Exists, '');
        Lib.AddStatusSuccessCondition(PlaybookCode, 90);
    end;

    /// <summary>
    /// Builds example 2 (OVERDUE-REPORT): count the customers with an overdue balance and send the number. No write step.
    /// </summary>
    /// <param name="PlaybookCode">The code of the playbook to create.</param>
    procedure BuildOverdueReport(PlaybookCode: Code[20])
    begin
        Lib.CreatePlaybook(PlaybookCode);
        Lib.AddStep(PlaybookCode, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", ReportReadTemplate(), 0, '', 0);
        Lib.AddStep(PlaybookCode, 20, "Playbook Step Type ori"::Action, "Message Type ori"::"Orchestrator.Telegram.Message", ReportNoticeTemplate(), 0, '', 0);

        Lib.SetResultLogPaths(PlaybookCode, 10, 'noOfRecords>overdueCount');
        Lib.SetNextSteps(PlaybookCode, 10, 20, 20);
        Lib.SetNextSteps(PlaybookCode, 20, 0, 0);

        Lib.AddStatusSuccessCondition(PlaybookCode, 10);
        Lib.AddCondition(PlaybookCode, 20, "Playbook Cond. Type ori"::Start, 10000, '_who.telegramChatId', "Playbook Cond. Operator ori"::Exists, '');
        Lib.AddStatusSuccessCondition(PlaybookCode, 20);
    end;

    /// <summary>The request template of step 10 of example 1.</summary>
    /// <returns>The JSON text.</returns>
    procedure CreditReadTemplate(): Text
    begin
        exit('{"tableName":"Customer","fieldNumbers":[1,2],"tableView":"WHERE(Blocked=CONST( ))"}');
    end;

    /// <summary>The request template of step 30 of example 1.</summary>
    /// <returns>The JSON text.</returns>
    procedure CreditDecideTemplate(): Text
    begin
        exit('{"tableName":"Customer","fieldNumbers":[1],"tableView":"WHERE(No.=CONST(@_current.primaryKey.No_),Balance Due (LCY)=FILTER(>0))"}');
    end;

    /// <summary>The request template of step 40 of example 1.</summary>
    /// <returns>The JSON text.</returns>
    procedure CreditBlockTemplate(): Text
    begin
        exit('{"tableName":"Customer","data":[{"id":"@_current.id","fields":{"Blocked":"Invoice"}}]}');
    end;

    /// <summary>The request template of step 90 of example 1.</summary>
    /// <returns>The JSON text.</returns>
    procedure CreditNoticeTemplate(): Text
    begin
        exit('{"message":"Credit control: @10.customerCount customers checked, @_steps.40.items.succeeded blocked."}');
    end;

    /// <summary>The request template of step 10 of example 2.</summary>
    /// <returns>The JSON text.</returns>
    procedure ReportReadTemplate(): Text
    begin
        exit('{"tableName":"Customer","fieldNumbers":[1,2],"tableView":"WHERE(Balance Due (LCY)=FILTER(>0))"}');
    end;

    /// <summary>The request template of step 20 of example 2.</summary>
    /// <returns>The JSON text.</returns>
    procedure ReportNoticeTemplate(): Text
    begin
        exit('{"message":"Customers with an overdue balance: @10.overdueCount"}');
    end;

    /// <summary>
    /// Builds example 4 (POSTING-AUDIT): read a bounded set of customers, ask once per customer, then send the
    /// counts. The Ask step stores the invariant type name looked up at runtime. This app has no Language Models
    /// dependency, so a deployment without LLM.Prompt.Ask keeps an unlisted ordinal and Verify reports that.
    /// </summary>
    /// <param name="PlaybookCode">The code of the playbook to create.</param>
    procedure BuildPostingAudit(PlaybookCode: Code[20])
    var
        Playbook: Record "Playbook ori";
    begin
        Lib.CreatePlaybook(PlaybookCode);
        Playbook.Get(PlaybookCode);
        Playbook.Description := 'Audit customer posting setup and report the verdicts';
        Playbook.Modify(true);

        Lib.AddStep(PlaybookCode, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", PostingAuditReadTemplate(), 0, '', 0);
        Lib.AddStep(PlaybookCode, 30, "Playbook Step Type ori"::Check, ResolveAskMessageType(), PostingAuditAskTemplate(), 10, 'result', 0);
        Lib.AddStep(PlaybookCode, 90, "Playbook Step Type ori"::Action, "Message Type ori"::"Orchestrator.Telegram.Message", PostingAuditNoticeTemplate(), 0, '', 0);

        Lib.SetResultLogPaths(PlaybookCode, 10, 'noOfRecords>customerCount');
        Lib.SetResultLogPaths(PlaybookCode, 30, 'data.verdict>verdict,data.findings>findings,stopReason>stopReason');
        Lib.SetNextSteps(PlaybookCode, 10, 30, 0);
        Lib.SetNextSteps(PlaybookCode, 30, 90, 90);
        Lib.SetNextSteps(PlaybookCode, 90, 0, 0);
        Lib.SetExcludeFromRunStatus(PlaybookCode, 90);

        Lib.AddStatusSuccessCondition(PlaybookCode, 10);
        Lib.AddNoOfRecordsCondition(PlaybookCode, 10);
        Lib.AddStatusSuccessCondition(PlaybookCode, 30);
        Lib.AddCondition(PlaybookCode, 30, "Playbook Cond. Type ori"::Success, 20000, 'data.verdict', "Playbook Cond. Operator ori"::Equals, 'pass');
        Lib.AddCondition(PlaybookCode, 30, "Playbook Cond. Type ori"::Success, 30000, 'schemaValid', "Playbook Cond. Operator ori"::Equals, 'true');
        Lib.AddCondition(PlaybookCode, 90, "Playbook Cond. Type ori"::Start, 10000, '_who.telegramChatId', "Playbook Cond. Operator ori"::Exists, '');
        Lib.AddStatusSuccessCondition(PlaybookCode, 90);
    end;

    /// <summary>
    /// Builds example 5 (ARTIFACT-REFRESH) with the deterministic stand-ins of the four production types, so a test
    /// runs the chain without Attachments, Language Models or a mail server: read the stored HTML as text (10), ask the
    /// model to refresh it as html (20), sanitize the answer (30) and draft the email with the sanitized html as the
    /// attachment (40). Steps 20, 30 and 40 stop the chain on failure: Next Step (Failure) is 0.
    /// </summary>
    /// <param name="PlaybookCode">The code of the playbook to create.</param>
    procedure BuildArtifactRefresh(PlaybookCode: Code[20])
    begin
        Lib.CreatePlaybook(PlaybookCode);
        Lib.AddStep(PlaybookCode, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Test.Orchestrator.Artifact.Storage", ArtifactReadTemplate(), 0, '', 0);
        Lib.AddStep(PlaybookCode, 20, "Playbook Step Type ori"::Action, "Message Type ori"::"Test.Orchestrator.Artifact.Ask", ArtifactAskTemplate(), 0, '', 0);
        Lib.AddStep(PlaybookCode, 30, "Playbook Step Type ori"::Action, "Message Type ori"::"Test.Orchestrator.Artifact.Sanitize", ArtifactSanitizeTemplate(), 0, '', 0);
        Lib.AddStep(PlaybookCode, 40, "Playbook Step Type ori"::Action, "Message Type ori"::"Test.Orchestrator.Artifact.Email", ArtifactEmailTemplate(), 0, '', 0);

        Lib.SetResultLogPaths(PlaybookCode, 10, 'content>artifactText,recipient>recipient');
        Lib.SetResultLogPaths(PlaybookCode, 20, 'html>artifactHtml,stopReason>stopReason');
        Lib.SetResultLogPaths(PlaybookCode, 30, 'html>cleanHtml');
        Lib.SetNextSteps(PlaybookCode, 10, 20, 0);
        Lib.SetNextSteps(PlaybookCode, 20, 30, 0);
        Lib.SetNextSteps(PlaybookCode, 30, 40, 0);
        Lib.SetNextSteps(PlaybookCode, 40, 0, 0);
        Lib.AddStatusSuccessCondition(PlaybookCode, 10);
        Lib.AddStatusSuccessCondition(PlaybookCode, 20);
        Lib.AddStatusSuccessCondition(PlaybookCode, 30);
        Lib.AddStatusSuccessCondition(PlaybookCode, 40);
    end;

    /// <summary>The request template of step 10 of example 5.</summary>
    /// <returns>The JSON text.</returns>
    procedure ArtifactReadTemplate(): Text
    begin
        exit('{"storageCode":"ARTIFACTS","path":"claude/status.html","asText":true}');
    end;

    /// <summary>The request template of step 20 of example 5.</summary>
    /// <returns>The JSON text.</returns>
    procedure ArtifactAskTemplate(): Text
    begin
        exit('{"question":"Update the figures in this HTML with the current Business Central data. Return the complete HTML document and nothing else. HTML: @10.artifactText","outputFormat":"html","limits":{"maxToolCalls":6},"tools":{"allow":["get_records"]}}');
    end;

    /// <summary>The request template of step 30 of example 5.</summary>
    /// <returns>The JSON text.</returns>
    procedure ArtifactSanitizeTemplate(): Text
    begin
        exit('{"html":"@20.artifactHtml"}');
    end;

    /// <summary>The request template of step 40 of example 5.</summary>
    /// <returns>The JSON text.</returns>
    procedure ArtifactEmailTemplate(): Text
    begin
        exit('{"to":["@_who.salesperson.email"],"subject":"Refreshed artifact","htmlBody":"The refreshed artifact is attached.","attachments":[{"fileName":"artifact.html","contentType":"text/html","contentText":"@30.cleanHtml"}]}');
    end;

    /// <summary>True when this deployment lists LLM.Prompt.Ask. The example never names that value at compile time.</summary>
    /// <returns>True when the enum lists the invariant name.</returns>
    procedure AskTypeIsRegistered(): Boolean
    var
        MessageType: Enum "Message Type ori";
    begin
        exit(MessageType.Names().Contains(AskTypeNameTok));
    end;

    /// <summary>The request template of step 10 of example 4.</summary>
    /// <returns>The JSON text.</returns>
    procedure PostingAuditReadTemplate(): Text
    begin
        exit('{"tableName":"Customer","fieldNumbers":[1,2],"tableView":"WHERE(Blocked=CONST( ))","take":25}');
    end;

    /// <summary>The request template of step 30 of example 4.</summary>
    /// <returns>The JSON text.</returns>
    procedure PostingAuditAskTemplate(): Text
    begin
        exit('{"question":"Is customer @_current.primaryKey.No_ (@_current.fields.Name) configured correctly for posting sales invoices? Check the posting groups, the VAT business posting group, the payment terms, and that the posting groups have their accounts filled. Answer with a verdict of pass, fail or unknown and list each problem with the field name. Read only; do not change the customer.","record":{"tableName":"Customer","systemId":"@_current.id"},"limits":{"maxToolCalls":4},"tools":{"allow":["get_records"]},"responseSchema":{"type":"object","properties":{"verdict":{"type":"string","enum":["pass","fail","unknown"]},"findings":{"type":"array","items":{"type":"string"}}},"required":["verdict","findings"]}}');
    end;

    /// <summary>The request template of step 90 of example 4.</summary>
    /// <returns>The JSON text.</returns>
    procedure PostingAuditNoticeTemplate(): Text
    begin
        exit('{"message":"Posting audit finished: @_steps.30.items"}');
    end;

    /// <summary>
    /// Resolves LLM.Prompt.Ask from the enum names at runtime. When Language Models is not installed the step
    /// keeps an unlisted ordinal so Verify reports MessageTypeUnavailable instead of a compile-time dependency.
    /// </summary>
    /// <returns>The registered Ask type, or an unlisted ordinal.</returns>
    local procedure ResolveAskMessageType() MessageType: Enum "Message Type ori"
    var
        Names: List of [Text];
        Ordinals: List of [Integer];
        Index: Integer;
    begin
        Names := MessageType.Names();
        Ordinals := MessageType.Ordinals();
        for Index := 1 to Names.Count() do
            if Names.Get(Index) = AskTypeNameTok then
                exit(Enum::"Message Type ori".FromInteger(Ordinals.Get(Index)));
        if not TryUnlistedAskType(MessageType) then
            Error(UnlistedRefusedErr);
    end;

    [TryFunction]
    local procedure TryUnlistedAskType(var MessageType: Enum "Message Type ori")
    var
        Ordinal: Integer;
    begin
        Evaluate(Ordinal, UnlistedOrdinalTok);
        if MessageType.Ordinals().Contains(Ordinal) then
            Error('');
        MessageType := Enum::"Message Type ori".FromInteger(Ordinal);
    end;

    var
        AskTypeNameTok: Label 'LLM.Prompt.Ask', Locked = true;
        UnlistedOrdinalTok: Label '99999999', Locked = true;
        UnlistedRefusedErr: Label 'The platform refused to hold an ordinal that the enum does not list.', Locked = true;
}
