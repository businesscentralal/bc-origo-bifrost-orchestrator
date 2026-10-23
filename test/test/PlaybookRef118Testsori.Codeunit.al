namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>Issue #118: use primary-key paths, warn before execution and fail unresolved requests before dispatch.</summary>
codeunit 96442 "Playbook Ref 118 Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Lib: Codeunit "Playbook Test Library ori";
        PlaybookCodeTok: Label 'XREF118', Locked = true;

    /// <summary>The wrong primary-key path warns in English.</summary>
    [Test]
    procedure PrimaryKeyUnderFieldsWarnsEnglish()
    begin
        VerifyPrimaryKeyWarning(1033, 'Step 30 reads @_current.fields.No_');
    end;

    /// <summary>The wrong primary-key path warns in Icelandic.</summary>
    [Test]
    procedure PrimaryKeyUnderFieldsWarnsIcelandic()
    begin
        VerifyPrimaryKeyWarning(1039, 'Skref 30 les @_current.fields.No_');
    end;

    /// <summary>A primary-key path and an ordinary field both resolve from the actual response shape.</summary>
    [Test]
    procedure CorrectPathsResolve()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        Helper: Codeunit "Playbook JSON Helper ori";
        Request: JsonObject;
        Item: JsonObject;
        Value: JsonToken;
        ErrorText: Text;
    begin
        Workspace.Reset();
        Item.ReadFrom('{"id":"X118","primaryKey":{"No_":"X118"},"fields":{"Name":"Reference test"}}');
        Workspace.SetToken('_current', Item.AsToken());
        Request.ReadFrom('{"tableView":"WHERE(No.=CONST(@_current.primaryKey.No_))","name":"@_current.fields.Name"}');
        Assert.IsTrue(Helper.TryResolveWorkspaceRefs(Request, ErrorText), ErrorText);
        Request.Get('tableView', Value);
        Assert.AreEqual('WHERE(No.=CONST(X118))', Value.AsValue().AsText(), 'Filter uses the primary-key value');
        Request.Get('name', Value);
        Assert.AreEqual('Reference test', Value.AsValue().AsText(), 'Ordinary field resolves');
        Assert.AreEqual('', ErrorText, 'No error');
        Workspace.Reset();
    end;

    /// <summary>Missing embedded and standalone references fail, without partially rewriting the request.</summary>
    [Test]
    procedure UnresolvedRequestsAreRejected()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        Helper: Codeunit "Playbook JSON Helper ori";
        Request: JsonObject;
        Value: JsonToken;
        ErrorText: Text;
    begin
        Workspace.Reset();
        Request.ReadFrom('{"tableView":"WHERE(No.=CONST(@_current.fields.No_))"}');
        Assert.IsFalse(Helper.TryResolveWorkspaceRefs(Request, ErrorText), 'Missing embedded key fails');
        Assert.IsTrue(ErrorText.Contains('@_current.fields.No_'), 'Error identifies the path');
        Request.Get('tableView', Value);
        Assert.AreEqual('WHERE(No.=CONST(@_current.fields.No_))', Value.AsValue().AsText(), 'Unsent request retained for diagnosis');
        Request.ReadFrom('{"nested":[{"value":"@10.missing"}]}');
        Assert.IsFalse(Helper.TryResolveWorkspaceRefs(Request, ErrorText), 'Nested standalone key fails');
        Assert.IsTrue(ErrorText.Contains('@10.missing'), 'Nested path identified');
        Workspace.Reset();
    end;

    /// <summary>Mail addresses and reference-looking text supplied as data are not rejected as template references.</summary>
    [Test]
    procedure LiteralMailAndResolvedDataRemainValid()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        Helper: Codeunit "Playbook JSON Helper ori";
        Request: JsonObject;
        ErrorText: Text;
    begin
        Workspace.Reset();
        Workspace.SetValue('10.text', 'Mail support@example.com or quote @_current.missing');
        Request.ReadFrom('{"mail":"support@example.com","body":"@10.text"}');
        Assert.IsTrue(Helper.TryResolveWorkspaceRefs(Request, ErrorText), 'Only original template references are checked: ' + ErrorText);
        Workspace.Reset();
    end;

    /// <summary>Same-iteration references resolve before validation, preserving the published syntax.</summary>
    [Test]
    procedure SameIterationAndFilteredDumpResolve()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        Helper: Codeunit "Playbook JSON Helper ori";
        Request: JsonObject;
        Value: JsonToken;
        ErrorText: Text;
    begin
        Workspace.Reset();
        Workspace.SetValue('_iter', '0');
        Workspace.SetValue('30.0.answer', 'yes');
        Request.ReadFrom('{"answer":"@30.@_iter.answer","dump":"@10,30"}');
        Assert.IsTrue(Helper.TryResolveWorkspaceRefs(Request, ErrorText), ErrorText);
        Request.Get('answer', Value);
        Assert.AreEqual('yes', Value.AsValue().AsText(), 'Iteration path resolves');
        Workspace.Reset();
    end;

    /// <summary>An unresolved Check is Failed rather than a successful answer of no.</summary>
    [Test]
    procedure SingleCheckMissingReferenceFails()
    begin
        VerifyRunnerRejects(1033, false, false);
    end;

    /// <summary>A forEach Check never dispatches an unresolved primary-key token.</summary>
    [Test]
    procedure ForEachCheckMissingReferenceFails()
    begin
        VerifyRunnerRejects(1033, true, false);
    end;

    /// <summary>A forEach Action also fails before dispatch, with an Icelandic diagnostic.</summary>
    [Test]
    procedure ForEachActionMissingReferenceFailsIcelandic()
    begin
        VerifyRunnerRejects(1039, true, true);
    end;

    local procedure VerifyPrimaryKeyWarning(LanguageId: Integer; ExpectedStart: Text)
    var
        Verify: Codeunit "Playbook Verify ori";
        Findings: JsonArray;
        Finding: JsonObject;
        Token: JsonToken;
        PreviousLanguage: Integer;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Customer","fieldNumbers":[1,2]}', 0, '', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 10);
        Lib.AddNoOfRecordsCondition(PlaybookCodeTok, 10);
        Lib.AddStep(PlaybookCodeTok, 30, "Playbook Step Type ori"::Check, "Message Type ori"::"Data.Records.Get", '{"tableView":"WHERE(No.=CONST(@_current.fields.No_))","again":"@_current.fields.No_"}', 10, 'result', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 30);
        Verify.GetFindings(PlaybookCodeTok, Findings);
        Assert.AreEqual(1, Findings.Count(), 'Repeated wrong path warns once');
        Findings.Get(0, Token);
        Finding := Token.AsObject();
        Finding.Get('code', Token);
        Assert.AreEqual('UnknownFieldReference', Token.AsValue().AsText(), 'Warning code');
        Finding.Get('severity', Token);
        Assert.AreEqual('warning', Token.AsValue().AsText(), 'Severity');
        Finding.Get('message', Token);
        Assert.IsTrue(Token.AsValue().AsText().StartsWith(ExpectedStart), 'Localized explanation');
        Finding.Get('nextStep', Token);
        Assert.IsTrue(Token.AsValue().AsText().Contains('@_current.primaryKey.No_'), 'Corrective path');
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyRunnerRejects(LanguageId: Integer; ForEachStep: Boolean; ActionStep: Boolean)
    var
        Instance: Record "Playbook Instance ori";
        StepLog: Record "Playbook Step Log ori";
        StepType: Enum "Playbook Step Type ori";
        InstanceId: Guid;
        StepNo: Integer;
        PreviousLanguage: Integer;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Lib.CreatePlaybook(PlaybookCodeTok);
        StepNo := 10;
        if ForEachStep then begin
            // This source reads only the playbook created by this test, never a shared customer fixture.
            Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", '{"tableName":"Playbook ori","tableView":"WHERE(Code=CONST(XREF118))"}', 0, '', 0);
            StepNo := 30;
        end;
        StepType := StepType::Check;
        if ActionStep then
            StepType := StepType::Action;
        if ForEachStep then
            Lib.AddStep(PlaybookCodeTok, StepNo, StepType, "Message Type ori"::"Data.Records.Get", '{"tableName":"Playbook ori","tableView":"WHERE(Code=CONST(@_current.fields.Code))"}', 10, 'result', 0)
        else
            Lib.AddStep(PlaybookCodeTok, StepNo, StepType, "Message Type ori"::"Data.Records.Get", '{"tableName":"Playbook ori","tableView":"WHERE(Code=CONST(@_initial.missing))"}', 0, '', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, StepNo);
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        Instance.Get(InstanceId);
        Assert.AreEqual(Instance.Status::Failed, Instance.Status, 'Run fails on an unresolved token');
        Assert.AreEqual(1, Instance."Steps Failed", 'Exactly one failed request');
        StepLog.Get(InstanceId, StepNo, 0);
        Assert.AreEqual(StepLog.Status::Failed, StepLog.Status, 'Technical failure, never answered no');
        Assert.IsTrue(StepLog."Error Text".Contains('@_'), 'Log identifies unresolved reference');
        Assert.AreEqual('', StepLog.GetResponseReceived(), 'No response because dispatch never ran');
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;
}
