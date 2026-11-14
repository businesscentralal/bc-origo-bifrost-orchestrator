namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>
/// Issue #180 AC06: the playbook shapes that hand a PDF or a picture from one step to an LLM step as an inline
/// file (LLM.Prompt.Complete file = {data, mimeType, fileName}), and the error branch for an unreadable file.
/// Mock only: the LLM step is a deterministic fixture, no provider and no credentials. The text shape and the
/// Ask error branch are covered by Example4_RunRecordsPassFailUnknownAndErrorThenAllPassNotice.
/// Every scenario runs in en-US (1033) and is-IS (1039).
/// </summary>
codeunit 96484 "Playbook LLM File Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Lib: Codeunit "Playbook Test Library ori";
        Fixture: Codeunit "LLM File Fixture Msg ori";
        PlaybookCodeTok: Label 'XLLM-FILE-180', Locked = true;
        PdfTemplateTok: Label '{"source":"pdf"}', Locked = true;
        PictureTemplateTok: Label '{"source":"picture"}', Locked = true;
        PdfReaderTemplateTok: Label '{"prompt":"Reply with the customer name.","file":{"data":"@10.pdf","mimeType":"application/pdf","fileName":"customer.pdf"}}', Locked = true;
        PictureReaderTemplateTok: Label '{"prompt":"Name the furniture.","file":{"data":"@10.picture","mimeType":"image/jpeg","fileName":"item.jpg"}}', Locked = true;
        UnreadableTemplateTok: Label '{"prompt":"Read the file.","file":{"data":"not-base64!!","mimeType":"application/pdf","fileName":"broken.pdf"}}', Locked = true;
        CustomerNameTok: Label 'The Cannon Group PLC', Locked = true;
        AnsweredNoTxt: Label 'Check answered no.', Locked = true;
        AnsweredNoIsTxt: Label 'Athugun svaraði nei.', Locked = true;

    [Test]
    procedure PdfShape_BinaryOutputReachesInlineFileAndAnswerIsCompared()
    begin
        VerifyPdfShape(1033);
        VerifyPdfShape(1039);
    end;

    [Test]
    procedure PictureShape_RecordPictureReachesInlineFileAndVerdictBranches()
    begin
        VerifyPictureShape(1033, 'desk', true);
        VerifyPictureShape(1039, 'desk', true);
        VerifyPictureShape(1033, 'table', false);
        VerifyPictureShape(1039, 'table', false);
    end;

    [Test]
    procedure FileError_UnreadableFileFollowsTheErrorBranch()
    begin
        VerifyFileError(1033);
        VerifyFileError(1039);
    end;

    [Test]
    procedure BinaryStep_StatusConditionFailsAndContentTypeConditionPasses()
    begin
        VerifyBinaryGate(1033);
        VerifyBinaryGate(1039);
    end;

    local procedure VerifyPdfShape(LanguageId: Integer)
    var
        Instance: Record "Playbook Instance ori";
        StepLog: Record "Playbook Step Log ori";
        InstanceId: Guid;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] A step makes a PDF, the LLM step gets its bytes as an inline file, and a Check compares the answer
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Test.Orchestrator.FileSource", PdfTemplateTok, 0, '', 0);
        Lib.SetResultLogPaths(PlaybookCodeTok, 10, 'base64>pdf,contentType>contentType');
        Lib.AddCondition(PlaybookCodeTok, 10, "Playbook Cond. Type ori"::Success, 10000, 'contentType', "Playbook Cond. Operator ori"::Equals, 'application/pdf');
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Check, "Message Type ori"::"Test.Orchestrator.FileReader", PdfReaderTemplateTok, 0, '', 0);
        Lib.SetResultLogPaths(PlaybookCodeTok, 20, 'reply>name');
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 20);
        Lib.AddCondition(PlaybookCodeTok, 20, "Playbook Cond. Type ori"::Success, 20000, 'reply', "Playbook Cond. Operator ori"::Equals, CustomerNameTok);
        Lib.SetNextSteps(PlaybookCodeTok, 20, 0, 0);

        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);

        Instance.Get(InstanceId);
        Assert.AreEqual(Instance.Status::Completed, Instance.Status, 'The PDF playbook completes');
        Assert.AreEqual(0, Instance."Steps Failed", 'No step fails');
        StepLog.Get(InstanceId, 10, 0);
        Assert.AreEqual(StepLog.Status::Completed, StepLog.Status, 'The PDF step completes');
        Assert.IsTrue(StepLog.GetResponseReceived().Contains('"contentType":"application/pdf"'), 'The PDF is stored as a binary envelope');
        StepLog.Get(InstanceId, 20, 0);
        Assert.AreEqual(StepLog.Status::Completed, StepLog.Status, 'The answer matches the record, so the Check says yes');
        Assert.IsTrue(StepLog.GetRequestSent().Contains(Fixture.ToBase64(Fixture.PdfContent())), 'The inline file carries the base64 of the PDF step');
        Assert.IsTrue(StepLog.GetResponseReceived().Contains(CustomerNameTok), 'The answer is read from the PDF');
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyPictureShape(LanguageId: Integer; Expected: Text[250]; ExpectYes: Boolean)
    var
        Instance: Record "Playbook Instance ori";
        StepLog: Record "Playbook Step Log ori";
        InstanceId: Guid;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] A record with a base64 picture feeds the LLM step; the verdict decides whether the next step runs
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Test.Orchestrator.FileSource", PictureTemplateTok, 0, '', 0);
        Lib.SetResultLogPaths(PlaybookCodeTok, 10, 'result[0].picture>picture');
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 10);
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Check, "Message Type ori"::"Test.Orchestrator.FileReader", PictureReaderTemplateTok, 0, '', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 20);
        Lib.AddCondition(PlaybookCodeTok, 20, "Playbook Cond. Type ori"::Success, 20000, 'reply', "Playbook Cond. Operator ori"::Equals, Expected);
        Lib.AddStep(PlaybookCodeTok, 30, "Playbook Step Type ori"::Action, "Message Type ori"::"Test.Orchestrator.FileSource", PdfTemplateTok, 0, '', 0);
        Lib.AddCondition(PlaybookCodeTok, 30, "Playbook Cond. Type ori"::Success, 10000, 'contentType', "Playbook Cond. Operator ori"::Equals, 'application/pdf');
        Lib.SetNextSteps(PlaybookCodeTok, 20, 30, 0);
        Lib.SetNextSteps(PlaybookCodeTok, 30, 0, 0);

        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);

        Instance.Get(InstanceId);
        Assert.AreEqual(Instance.Status::Completed, Instance.Status, 'An answer of yes or no never fails the run');
        StepLog.Get(InstanceId, 20, 0);
        Assert.IsTrue(StepLog.GetRequestSent().Contains(Fixture.ToBase64(Fixture.PictureContent())), 'The inline file carries the base64 picture');
        if ExpectYes then begin
            Assert.AreEqual(StepLog.Status::Completed, StepLog.Status, 'The verdict is yes');
            Assert.AreEqual('', StepLog."Error Text", 'A yes answer logs no text');
            Assert.IsTrue(StepLog.Get(InstanceId, 30, 0), 'The yes branch runs the next step');
        end else begin
            Assert.AreEqual(StepLog.Status::Completed, StepLog.Status, 'A single Check that answers no is not a failure');
            Assert.IsTrue(StepLog."Error Text" in [AnsweredNoTxt, AnsweredNoIsTxt], 'The no answer is logged: ' + StepLog."Error Text");
            Assert.IsFalse(StepLog.Get(InstanceId, 30, 0), 'The no branch does not run the next step');
        end;
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyFileError(LanguageId: Integer)
    var
        Instance: Record "Playbook Instance ori";
        StepLog: Record "Playbook Step Log ori";
        InstanceId: Guid;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] An unreadable inline file gives a typed refusal; the playbook follows its error branch, not the success branch
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Check, "Message Type ori"::"Test.Orchestrator.FileReader", UnreadableTemplateTok, 0, '', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 10);
        Lib.AddStep(PlaybookCodeTok, 20, "Playbook Step Type ori"::Action, "Message Type ori"::"Test.Orchestrator.FileSource", PdfTemplateTok, 0, '', 0);
        Lib.AddCondition(PlaybookCodeTok, 20, "Playbook Cond. Type ori"::Success, 10000, 'contentType', "Playbook Cond. Operator ori"::Equals, 'application/pdf');
        Lib.AddStep(PlaybookCodeTok, 30, "Playbook Step Type ori"::Action, "Message Type ori"::"Test.Orchestrator.FileSource", PictureTemplateTok, 0, '', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 30);
        Lib.SetNextSteps(PlaybookCodeTok, 10, 20, 30);
        Lib.SetNextSteps(PlaybookCodeTok, 20, 0, 0);
        Lib.SetNextSteps(PlaybookCodeTok, 30, 0, 0);

        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);

        Instance.Get(InstanceId);
        Assert.AreEqual(Instance.Status::Failed, Instance.Status, 'A refused LLM step fails the run');
        Assert.AreEqual(1, Instance."Steps Failed", 'Only the LLM step fails');
        StepLog.Get(InstanceId, 10, 0);
        Assert.AreEqual(StepLog.Status::Failed, StepLog.Status, 'The refusal is a failure, not the answer no');
        Assert.IsTrue(StepLog."Error Text".Contains('PreconditionFailed'), 'The typed code is logged: ' + StepLog."Error Text");
        Assert.IsTrue(StepLog.GetResponseReceived().Contains('"nextStep"'), 'The refusal carries a next step');
        Assert.IsFalse(StepLog.Get(InstanceId, 20, 0), 'The success branch does not run');
        Assert.IsTrue(StepLog.Get(InstanceId, 30, 0), 'The error branch runs');
        Assert.AreEqual(StepLog.Status::Completed, StepLog.Status, 'The error branch completes');
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyBinaryGate(LanguageId: Integer)
    var
        StepLog: Record "Playbook Step Log ori";
        InstanceId: Guid;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] Edge case: a binary envelope has no status, so status Equals Success fails it; contentType gates it
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Lib.Cleanup(PlaybookCodeTok);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Test.Orchestrator.FileSource", PdfTemplateTok, 0, '', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 10);
        Lib.SetNextSteps(PlaybookCodeTok, 10, 0, 0);
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        StepLog.Get(InstanceId, 10, 0);
        Assert.AreEqual(StepLog.Status::Failed, StepLog.Status, 'status Equals Success cannot pass a binary envelope');
        Lib.Cleanup(PlaybookCodeTok);

        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Test.Orchestrator.FileSource", PdfTemplateTok, 0, '', 0);
        Lib.AddCondition(PlaybookCodeTok, 10, "Playbook Cond. Type ori"::Success, 10000, 'contentType', "Playbook Cond. Operator ori"::Equals, 'application/pdf');
        Lib.SetNextSteps(PlaybookCodeTok, 10, 0, 0);
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        StepLog.Get(InstanceId, 10, 0);
        Assert.AreEqual(StepLog.Status::Completed, StepLog.Status, 'contentType Equals application/pdf passes the binary envelope');
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;
}
