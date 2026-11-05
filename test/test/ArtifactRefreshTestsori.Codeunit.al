namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;
using System.Text;

/// <summary>
/// Issue #153 (O1): the ARTIFACT-REFRESH example and the verify rules that guard an artifact chain. The production types
/// (Storage.File.Get asText, LLM.Prompt.Ask html, Content.Html.Sanitize, Email.Draft.Set) are replaced by deterministic
/// stand-ins that Verify judges as the production names. No email is sent: the email stand-in only records the call.
/// </summary>
codeunit 96467 "Artifact Refresh Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Examples: Codeunit "Playbook Example Library ori";
        Lib: Codeunit "Playbook Test Library ori";
        State: Codeunit "Artifact Mock State ori";
        VerifyMgt: Codeunit "Playbook Verify ori";
        CodeTok: Label 'ARTIFACT-153', Locked = true;
        ReplacedDescriptionTok: Label 'Template replaced by the test', Locked = true;
        PrivateTraceTok: Label 'XARTIFACT-PRIVATE-TRACE', Locked = true;
        CleanHtmlTok: Label '<html><body><p>Open invoices: 12</p></body></html>', Locked = true;

    [Test]
    procedure Example_VerifiesClean_1033()
    begin
        VerifyExampleClean(1033);
    end;

    [Test]
    procedure Example_VerifiesClean_1039()
    begin
        VerifyExampleClean(1039);
    end;

    [Test]
    procedure Rule_EmailAttachmentNotBoundToSanitize_Warns()
    var
        Findings: JsonArray;
    begin
        // [SCENARIO] An attachment bound to the Ask answer (step 20) instead of the Sanitize answer is reported on step 40 only
        Setup();
        ReplaceTemplate(40, Examples.ArtifactEmailTemplate().Replace('@30.cleanHtml', '@20.artifactHtml'));
        GetFindings(Findings);
        Assert.AreEqual(1, CountCode(Findings, 'EmailContentNotSanitized', 40), 'One EmailContentNotSanitized on step 40: ' + AsText(Findings));
        Assert.AreEqual(1, Findings.Count(), 'No other finding: ' + AsText(Findings));
        Teardown();
    end;

    [Test]
    procedure Rule_EmailAttachmentLiteral_And_BodyReferencingAsk_Warn()
    var
        Findings: JsonArray;
    begin
        // [SCENARIO] A literal attachment and a body that carries the unsanitized answer are each reported; a body written in the template is not
        Setup();
        ReplaceTemplate(40, '{"to":["@_who.salesperson.email"],"htmlBody":"Fresh: @20.artifactHtml","attachments":[{"contentText":"<p>x</p>"}]}');
        GetFindings(Findings);
        Assert.AreEqual(2, CountCode(Findings, 'EmailContentNotSanitized', 40), 'Body and attachment: ' + AsText(Findings));
        ReplaceTemplate(40, '{"to":["@_who.salesperson.email"],"htmlBody":"Written by the author.","attachments":[{"contentText":"@30.cleanHtml"}]}');
        Clear(Findings);
        GetFindings(Findings);
        Assert.AreEqual(0, Findings.Count(), 'A literal body without a reference and a bound attachment are clean: ' + AsText(Findings));
        Teardown();
    end;

    [Test]
    procedure Rule_SanitizeAfterTheEmail_Warns()
    var
        Findings: JsonArray;
    begin
        // [SCENARIO] A reference to a Sanitize step that does not run before the email step does not count
        Setup();
        ReplaceTemplate(40, Examples.ArtifactEmailTemplate().Replace('@30.cleanHtml', '@50.cleanHtml'));
        GetFindings(Findings);
        Assert.AreEqual(1, CountCode(Findings, 'EmailContentNotSanitized', 40), AsText(Findings));
        Teardown();
    end;

    [Test]
    procedure Rule_AskWithoutToolsAllow_Warns()
    var
        Findings: JsonArray;
    begin
        // [SCENARIO] Missing, empty and referenced tools.allow
        Setup();
        ReplaceTemplate(20, '{"question":"q HTML: @10.artifactText","outputFormat":"html"}');
        GetFindings(Findings);
        Assert.AreEqual(1, CountCode(Findings, 'AskWithoutToolsAllow', 20), 'Missing: ' + AsText(Findings));
        ReplaceTemplate(20, '{"question":"q","tools":{"allow":[]}}');
        Clear(Findings);
        GetFindings(Findings);
        Assert.AreEqual(1, CountCode(Findings, 'AskWithoutToolsAllow', 20), 'Empty: ' + AsText(Findings));
        ReplaceTemplate(20, '{"question":"q","tools":{"allow":["get_records"]}}');
        Clear(Findings);
        GetFindings(Findings);
        Assert.AreEqual(0, CountCode(Findings, 'AskWithoutToolsAllow', 20), 'Present: ' + AsText(Findings));
        ReplaceTemplate(20, '{"question":"q","tools":{"allow":"@_initial.tools"}}');
        Clear(Findings);
        GetFindings(Findings);
        Assert.AreEqual(0, CountCode(Findings, 'AskWithoutToolsAllow', 20), 'Reference: ' + AsText(Findings));
        Teardown();
    end;

    [Test]
    procedure Rule_IncludeTrace_Warns()
    var
        Findings: JsonArray;
    begin
        // [SCENARIO] includeTrace true on the artifact Ask step is reported by the existing AskTraceDiscarded rule
        Setup();
        VerifyMgt.SetTestAskType('Test.Orchestrator.Artifact.Ask');
        ReplaceTemplate(20, '{"question":"q","includeTrace":true,"tools":{"allow":["get_records"]}}');
        GetFindings(Findings);
        Assert.AreEqual(1, CountCode(Findings, 'AskTraceDiscarded', 20), AsText(Findings));
        VerifyMgt.SetTestAskType('');
        Teardown();
    end;

    [Test]
    procedure Rule_LiteralExternalRecipient_Warns()
    var
        Findings: JsonArray;
    begin
        // [SCENARIO] A literal address in to, cc or bcc is reported once per property; references and an empty list are not
        Setup();
        ReplaceTemplate(40, '{"to":["someone@example.com"],"cc":"copy@example.com","bcc":["@_who.salesperson.email"],"attachments":[{"contentText":"@30.cleanHtml"}]}');
        GetFindings(Findings);
        Assert.AreEqual(2, CountCode(Findings, 'EmailLiteralRecipient', 40), AsText(Findings));
        ReplaceTemplate(40, '{"to":["@_who.salesperson.email"],"cc":[],"attachments":[{"contentText":"@30.cleanHtml"}]}');
        Clear(Findings);
        GetFindings(Findings);
        Assert.AreEqual(0, Findings.Count(), AsText(Findings));
        Teardown();
    end;

    [Test]
    procedure Run_OneMegabyteArtifact_StoresNoTraceAndNoDuplicatedBody()
    var
        Instance: Record "Playbook Instance ori";
        StepLog: Record "Playbook Step Log ori";
        Workspace: Codeunit "Playbook Workspace ori";
        InstanceId: Guid;
        Artifact: Text;
        Stored: Text;
    begin
        // [SCENARIO] A 1 MB artifact runs to the email stand-in. No step log holds the trace; the workspace holds the html only under the mapped names
        Setup();
        Artifact := '<html><body>' + PadStr('', 1048576, 'a') + '</body></html>';
        State.Setup(Artifact, 0);
        UseOwnedRecipient();
        Lib.RunPlaybook(CodeTok, InstanceId);

        Instance.Get(InstanceId);
        Assert.AreEqual("Playbook Inst. Status ori"::Completed, Instance.Status, 'The run completes');
        Assert.AreEqual(1, State.GetAskCount(), 'Ask once');
        Assert.AreEqual(1, State.GetSanitizeCount(), 'Sanitize once');
        Assert.AreEqual(1, State.GetEmailCount(), 'One email stand-in call, nothing sent');
        Assert.AreEqual(StrLen(Artifact), StrLen(State.GetLastAttachmentText()), 'The attachment is the full sanitized html');

        StepLog.SetRange("Instance ID", InstanceId);
        StepLog.FindSet();
        repeat
            Assert.IsFalse(StepLog.GetResponseReceived().Contains(PrivateTraceTok), 'No step log holds the Ask trace (step ' + Format(StepLog."Step No.") + ')');
        until StepLog.Next() = 0;

        Assert.IsTrue(Workspace.GetValue('20.artifactHtml', Stored), 'The Ask html is stored under its mapped name');
        Assert.AreEqual(StrLen(Artifact), StrLen(Stored), 'Stored once, whole');
        Assert.IsFalse(Workspace.GetValue('20.trace', Stored), 'The trace is not stored in the workspace');
        Assert.IsFalse(Workspace.GetValue('20.html', Stored), 'The unmapped html field is not stored a second time');
        Teardown();
    end;

    [Test]
    procedure Run_SizeCapExceeded_StopsBeforeTheEmail()
    var
        Instance: Record "Playbook Instance ori";
        StepLog: Record "Playbook Step Log ori";
        InstanceId: Guid;
    begin
        // [SCENARIO] The sanitize stand-in refuses an answer over its cap: the run fails at step 30 and step 40 never runs
        Setup();
        State.Setup('<html><body>' + PadStr('', 2000, 'a') + '</body></html>', 1000);
        UseOwnedRecipient();
        Lib.RunPlaybook(CodeTok, InstanceId);

        Instance.Get(InstanceId);
        Assert.AreEqual("Playbook Inst. Status ori"::Failed, Instance.Status, 'The run fails');
        Assert.AreEqual(1, State.GetSanitizeCount(), 'Sanitize was called');
        Assert.AreEqual(0, State.GetEmailCount(), 'The email step did not run');
        StepLog.SetRange("Instance ID", InstanceId);
        StepLog.SetRange("Step No.", 40);
        Assert.IsTrue(StepLog.IsEmpty(), 'No step log row for step 40');
        Teardown();
    end;

    [Test]
    procedure Run_HtmlWithScript_StopsBeforeTheEmail()
    var
        Instance: Record "Playbook Instance ori";
        InstanceId: Guid;
    begin
        // [SCENARIO] The sanitize stand-in refuses html that carries a script: the email step does not run
        Setup();
        State.Setup('<html><script>alert(1)</script></html>', 0);
        UseOwnedRecipient();
        Lib.RunPlaybook(CodeTok, InstanceId);

        Instance.Get(InstanceId);
        Assert.AreEqual("Playbook Inst. Status ori"::Failed, Instance.Status, 'The run fails');
        Assert.AreEqual(0, State.GetEmailCount(), 'The email step did not run');
        Teardown();
    end;

    [Test]
    procedure Run_Twice_InARow_LeavesNoData()
    var
        Instance: Record "Playbook Instance ori";
        First: Guid;
        Second: Guid;
    begin
        // [SCENARIO] The same owned playbook code is built, run and removed twice; nothing is left behind
        Setup();
        State.Setup(CleanHtmlTok, 0);
        UseOwnedRecipient();
        Lib.RunPlaybook(CodeTok, First);
        Teardown();
        Setup();
        State.Setup(CleanHtmlTok, 0);
        UseOwnedRecipient();
        Lib.RunPlaybook(CodeTok, Second);
        Assert.AreEqual(1, State.GetAskCount(), 'The state was reset between runs (one Ask in the second run)');
        Teardown();
        Instance.SetRange("Playbook Code", CodeTok);
        Assert.IsTrue(Instance.IsEmpty(), 'No instance is left');
    end;

    [Test]
    procedure Help_CarriesTheArtifactRefreshExample()
    var
        HelpMgt: Codeunit "Help ori";
        Base64Convert: Codeunit "Base64 Convert";
        HelpText: Text;
        Template: Text;
    begin
        // [SCENARIO] The help is English-only and carries the base64 of every template, with the guard rails explained
        HelpText := HelpMgt.GetOverview();
        Assert.IsTrue(HelpText.Contains('ARTIFACT-REFRESH'), 'ARTIFACT-REFRESH');
        foreach Template in TemplateList() do
            Assert.IsTrue(HelpText.Contains(Base64Convert.ToBase64(Template)), 'Base64 of ' + Template);
        foreach Template in TemplateList() do
            Assert.IsTrue(HelpText.Contains(Template), 'Decoded ' + Template);
        Assert.IsTrue(HelpText.Contains('`EmailContentNotSanitized`'), 'EmailContentNotSanitized');
        Assert.IsTrue(HelpText.Contains('`AskWithoutToolsAllow`'), 'AskWithoutToolsAllow');
        Assert.IsTrue(HelpText.Contains('`EmailLiteralRecipient`'), 'EmailLiteralRecipient');
    end;

    local procedure TemplateList() Templates: List of [Text]
    begin
        Templates.Add(Examples.ArtifactReadTemplate());
        Templates.Add(Examples.ArtifactAskTemplate());
        Templates.Add(Examples.ArtifactSanitizeTemplate());
        Templates.Add(Examples.ArtifactEmailTemplate());
    end;

    local procedure VerifyExampleClean(LanguageId: Integer)
    var
        Findings: JsonArray;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] The example verifies with no finding in the given language
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Setup();
        GetFindings(Findings);
        Teardown();
        GlobalLanguage(PreviousLanguage);
        Assert.AreEqual(0, Findings.Count(), 'No finding: ' + AsText(Findings));
    end;

    local procedure Setup()
    begin
        State.Reset();
        VerifyMgt.SetTestAlias('Test.Orchestrator.Artifact.Storage', 'Storage.File.Get');
        VerifyMgt.SetTestAlias('Test.Orchestrator.Artifact.Ask', 'LLM.Prompt.Ask');
        VerifyMgt.SetTestAlias('Test.Orchestrator.Artifact.Sanitize', 'Content.Html.Sanitize');
        VerifyMgt.SetTestAlias('Test.Orchestrator.Artifact.Email', 'Email.Draft.Set');
        Examples.BuildArtifactRefresh(CodeTok);
    end;

    local procedure Teardown()
    begin
        Lib.Cleanup(CodeTok);
        VerifyMgt.SetTestAlias('', '');
        State.Reset();
    end;

    local procedure GetFindings(var Findings: JsonArray)
    begin
        VerifyMgt.GetFindings(CodeTok, Findings);
    end;

    local procedure ReplaceTemplate(StepNo: Integer; Template: Text)
    var
        Step: Record "Playbook Step ori";
    begin
        Step.Get(CodeTok, StepNo);
        Step.Description := ReplacedDescriptionTok;
        Step.SetRequestTemplate(Template);
        Step.Modify(true);
    end;

    /// <summary>The run tests cannot depend on a salesperson of the test user: the recipient comes from the owned storage stand-in.</summary>
    local procedure UseOwnedRecipient()
    begin
        ReplaceTemplate(40, Examples.ArtifactEmailTemplate().Replace('@_who.salesperson.email', '@10.recipient'));
    end;

    local procedure CountCode(Findings: JsonArray; FindingCode: Text; StepNo: Integer): Integer
    var
        Token: JsonToken;
        Value: JsonToken;
        Finding: JsonObject;
        Count: Integer;
    begin
        foreach Token in Findings do begin
            Finding := Token.AsObject();
            Finding.Get('code', Value);
            if Value.AsValue().AsText() = FindingCode then begin
                Finding.Get('stepNo', Value);
                if Value.AsValue().AsInteger() = StepNo then
                    Count += 1;
            end;
        end;
        exit(Count);
    end;

    local procedure AsText(Findings: JsonArray): Text
    var
        Result: Text;
    begin
        Findings.WriteTo(Result);
        exit(Result);
    end;
}
