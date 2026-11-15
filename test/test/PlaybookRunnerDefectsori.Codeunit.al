namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>
/// Issue #183: playbook runner defects found on a customer replay. Exists ignores empty values, a reference
/// keeps the JSON type of its source, a Failed step always carries an error text, and Transform steps do not
/// log a message type of "0". Unit-level, no live calls; the step scenarios run in en-US (1033) and is-IS (1039).
/// </summary>
codeunit 96485 "Playbook Runner Defects ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Lib: Codeunit "Playbook Test Library ori";
        PlaybookCodeTok: Label 'RUN-183', Locked = true;
        FailingReportErrTxt: Label 'Deliberate failure from the test report.', Locked = true;
        RequestFormat1Tok: Label '{"reportId":%1,"expectedCount":1}', Locked = true;
        ConditionNotMetEnTxt: Label 'condition not met: path "isReady" Equals "true", actual (missing)', Locked = true;
        ConditionNotMetIsTxt: Label 'skilyrði ekki uppfyllt: slóð "isReady" Equals "true", raunverulegt gildi (missing)', Locked = true;

    // ---- AC01: Exists ----------------------------------------------------------------------

    /// <summary>Exists is false for a missing path, null, an empty string, an empty array and an empty object.</summary>
    [Test]
    procedure Exists_IsFalseForMissingNullAndEmptyValues()
    var
        Helper: Codeunit "Playbook JSON Helper ori";
        Source: JsonObject;
    begin
        Source.ReadFrom('{"empty":"","nothing":null,"list":[],"obj":{}}');
        Assert.IsFalse(Helper.EvaluateCondition(Source, 'absent', "Playbook Cond. Operator ori"::Exists, ''), 'missing path');
        Assert.IsFalse(Helper.EvaluateCondition(Source, 'empty', "Playbook Cond. Operator ori"::Exists, ''), 'empty string');
        Assert.IsFalse(Helper.EvaluateCondition(Source, 'nothing', "Playbook Cond. Operator ori"::Exists, ''), 'null');
        Assert.IsFalse(Helper.EvaluateCondition(Source, 'list', "Playbook Cond. Operator ori"::Exists, ''), 'empty array');
        Assert.IsFalse(Helper.EvaluateCondition(Source, 'obj', "Playbook Cond. Operator ori"::Exists, ''), 'empty object');
    end;

    /// <summary>Exists is true for text, numbers (also 0), booleans (also false), and non-empty arrays and objects.</summary>
    [Test]
    procedure Exists_IsTrueForValues()
    var
        Helper: Codeunit "Playbook JSON Helper ori";
        Source: JsonObject;
    begin
        Source.ReadFrom('{"text":"x","blank":" ","zero":0,"no":false,"list":[1],"obj":{"a":1},"who":{"telegramChatId":"123"}}');
        Assert.IsTrue(Helper.EvaluateCondition(Source, 'text', "Playbook Cond. Operator ori"::Exists, ''), 'text');
        Assert.IsTrue(Helper.EvaluateCondition(Source, 'blank', "Playbook Cond. Operator ori"::Exists, ''), 'a space is a value');
        Assert.IsTrue(Helper.EvaluateCondition(Source, 'zero', "Playbook Cond. Operator ori"::Exists, ''), 'zero');
        Assert.IsTrue(Helper.EvaluateCondition(Source, 'no', "Playbook Cond. Operator ori"::Exists, ''), 'false');
        Assert.IsTrue(Helper.EvaluateCondition(Source, 'list', "Playbook Cond. Operator ori"::Exists, ''), 'array');
        Assert.IsTrue(Helper.EvaluateCondition(Source, 'obj', "Playbook Cond. Operator ori"::Exists, ''), 'object');
        Assert.IsTrue(Helper.EvaluateCondition(Source, 'who.telegramChatId', "Playbook Cond. Operator ori"::Exists, ''), 'nested text');
    end;

    // ---- AC02: references keep the JSON type -----------------------------------------------

    /// <summary>A digit-only Code stays a string, an Integer stays a number, a boolean stays a boolean.</summary>
    [Test]
    procedure Reference_KeepsJsonTypeOfSource()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        Helper: Codeunit "Playbook JSON Helper ori";
        Item: JsonObject;
        Request: JsonObject;
        RequestText: Text;
    begin
        Workspace.Reset();
        Item.ReadFrom('{"primaryKey":{"No_":"1001","EntryNo_":42},"fields":{"Code":"007","Amount":1.5,"Open":true,"Name":"Bob"}}');
        Workspace.SetToken('_current', Item.AsToken());
        Request.ReadFrom('{"invoiceNo":"@_current.primaryKey.No_","entryNo":"@_current.primaryKey.EntryNo_","code":"@_current.fields.Code","amount":"@_current.fields.Amount","open":"@_current.fields.Open","name":"@_current.fields.Name","text":"No @_current.primaryKey.No_"}');
        Helper.ResolveWorkspaceRefs(Request);
        Request.WriteTo(RequestText);
        Assert.AreEqual('{"invoiceNo":"1001","entryNo":42,"code":"007","amount":1.5,"open":true,"name":"Bob","text":"No 1001"}', RequestText, 'types kept');
        Workspace.Reset();
    end;

    /// <summary>A reference to a missing value is still rejected before dispatch (edge case).</summary>
    [Test]
    procedure Reference_ToMissingValueIsRejected()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        Helper: Codeunit "Playbook JSON Helper ori";
        Request: JsonObject;
        ErrorText: Text;
    begin
        Workspace.Reset();
        Request.ReadFrom('{"invoiceNo":"@_current.primaryKey.No_"}');
        Assert.IsFalse(Helper.TryResolveWorkspaceRefs(Request, ErrorText), 'missing reference fails');
        Assert.AreNotEqual('', ErrorText, 'error text');
        Workspace.Reset();
    end;

    // ---- AC03: a Failed step says why ------------------------------------------------------

    /// <summary>A failed Success condition is named, in English.</summary>
    [Test]
    procedure FailedCondition_NamesTheCondition_1033()
    begin
        VerifyConditionFailure(1033, ConditionNotMetEnTxt);
    end;

    /// <summary>A failed Success condition is named, in Icelandic.</summary>
    [Test]
    procedure FailedCondition_NamesTheCondition_1039()
    begin
        VerifyConditionFailure(1039, ConditionNotMetIsTxt);
    end;

    /// <summary>A message that answered status Error gives code: error, in English.</summary>
    [Test]
    procedure MessageError_GivesTheResponseError_1033()
    begin
        VerifyMessageError(1033);
    end;

    /// <summary>A message that answered status Error gives code: error, in Icelandic.</summary>
    [Test]
    procedure MessageError_GivesTheResponseError_1039()
    begin
        VerifyMessageError(1039);
    end;

    /// <summary>Every failed iteration of a forEach step carries an error text.</summary>
    [Test]
    procedure ForEachFailedCondition_NamesTheCondition()
    var
        StepLog: Record "Playbook Step Log ori";
        InstanceId: Guid;
    begin
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddLayoutSourceStep(PlaybookCodeTok, 10);
        Lib.AddStep(PlaybookCodeTok, 30, "Playbook Step Type ori"::Action, "Message Type ori"::"Help.Implementation.Get", HelpRequest(), 10, 'layouts', 0);
        Lib.AddSuccessCondition(PlaybookCodeTok, 30, 'isReady', 'true');
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        StepLog.SetRange("Instance ID", InstanceId);
        StepLog.SetRange("Step No.", 30);
        StepLog.SetRange(Status, StepLog.Status::Failed);
        Assert.IsTrue(StepLog.FindSet(), 'Failed iterations expected');
        repeat
            Assert.IsTrue(StepLog."Error Text".Contains('isReady'), 'Iteration error text names the path: ' + StepLog."Error Text");
        until StepLog.Next() = 0;
        Lib.Cleanup(PlaybookCodeTok);
    end;

    /// <summary>The explanation is never empty, also for an empty response and when nothing explains the failure.</summary>
    [Test]
    procedure DescribeStepFailure_IsNeverEmpty()
    var
        Helper: Codeunit "Playbook JSON Helper ori";
    begin
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Help.Implementation.Get", HelpRequest(), 0, '', 0);
        Assert.AreNotEqual('', Helper.DescribeStepFailure('', PlaybookCodeTok, 10, "Playbook Cond. Type ori"::Success), 'empty response');
        Assert.AreNotEqual('', Helper.DescribeStepFailure('not json', PlaybookCodeTok, 10, "Playbook Cond. Type ori"::Success), 'not JSON');
        Assert.AreNotEqual('', Helper.DescribeStepFailure('{"status":"Success"}', PlaybookCodeTok, 10, "Playbook Cond. Type ori"::Success), 'no condition');
        Assert.AreEqual('ConfirmationRequired: Confirm first.', Helper.DescribeStepFailure('{"status":"Error","code":"ConfirmationRequired","error":"Confirm first."}', PlaybookCodeTok, 10, "Playbook Cond. Type ori"::Success), 'code: error');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    // ---- AC04: Transform steps do not log a message type -----------------------------------

    /// <summary>A Transform step reports its step type, and its log keeps a blank message type, never "0".</summary>
    [Test]
    procedure Transform_LogsStepTypeNotZero()
    var
        Step: Record "Playbook Step ori";
        Mapping: Record "Playbook Transform ori";
        StepLog: Record "Playbook Step Log ori";
        Runner: Codeunit "Playbook Runner ori";
        Workspace: Codeunit "Playbook Workspace ori";
        InitialRequest: BigText;
        Response: BigText;
        InstanceId: Guid;
        Result: Text;
    begin
        Lib.CreatePlaybook(PlaybookCodeTok);
        Step.Init();
        Step."Playbook Code" := PlaybookCodeTok;
        Step."Step No." := 10;
        Step."Step Kind" := Step."Step Kind"::Transform;
        Step.Insert(true);
        Step.SetRequestTemplate('{"value":"A"}');
        Step.Modify(true);
        Mapping.Init();
        Mapping."Playbook Code" := PlaybookCodeTok;
        Mapping."Step No." := 10;
        Mapping."Line No." := 10000;
        Mapping."Target Path" := 'out';
        Mapping."Source Path" := 'value';
        Mapping.Operation := "Transform Operation ori"::Copy;
        Mapping.Insert(true);
        Commit();
        Runner.Run(PlaybookCodeTok, InitialRequest, Response, InstanceId);
        Assert.IsTrue(Workspace.GetValue('_steps.10.messageType', Result), '_steps.10.messageType exists');
        Assert.AreEqual('Transform', Result, 'step type');
        StepLog.SetRange("Instance ID", InstanceId);
        Assert.IsTrue(StepLog.FindFirst(), 'step log');
        Assert.AreEqual(0, StepLog."Message Type".AsInteger(), 'no message type stored');
        Assert.AreEqual('', StepLog.GetMessageTypeText(), 'the log shows blank, never 0');
        Lib.Cleanup(PlaybookCodeTok);
        Commit();
    end;

    local procedure VerifyConditionFailure(LanguageId: Integer; ExpectedText: Text)
    var
        StepLog: Record "Playbook Step Log ori";
        InstanceId: Guid;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] A step whose Success condition does not hold is Failed with the condition named
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Help.Implementation.Get", HelpRequest(), 0, '', 0);
        Lib.AddSuccessCondition(PlaybookCodeTok, 10, 'isReady', 'true');
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        StepLog.Get(InstanceId, 10, 0);
        Assert.AreEqual(StepLog.Status::Failed, StepLog.Status, 'Step is Failed');
        Assert.IsTrue(StepLog."Error Text".Contains(ExpectedText), 'Expected "' + ExpectedText + '" in: ' + StepLog."Error Text");
        Assert.IsTrue(StepLog."Error Text".StartsWith('Success') or (StepLog."Error Text".Contains('Success')), 'Condition type named: ' + StepLog."Error Text");
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyMessageError(LanguageId: Integer)
    var
        StepLog: Record "Playbook Step Log ori";
        InstanceId: Guid;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] A step whose message answered status Error is Failed with the response's error text
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Orchestrator.Report.Run", StrSubstNo(RequestFormat1Tok, Report::"Test Failing Report"), 0, '', 0);
        Lib.AddSuccessCondition(PlaybookCodeTok, 10, 'status', 'Success');
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        StepLog.Get(InstanceId, 10, 0);
        Assert.AreEqual(StepLog.Status::Failed, StepLog.Status, 'Step is Failed');
        Assert.IsTrue(StepLog."Error Text".Contains(FailingReportErrTxt), 'The response error is the error text: ' + StepLog."Error Text");
        Assert.AreNotEqual('', StepLog.GetMessageTypeText(), 'A message step keeps its message type text');
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure HelpRequest(): Text
    begin
        exit('{"messageTypes":["Orchestrator.Playbook.Schedule"],"chapters":["parameters"]}');
    end;
}
