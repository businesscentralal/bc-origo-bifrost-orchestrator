namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>Transform operation, failure isolation and runner acceptance for issue 155.</summary>
codeunit 96468 "Transform Exec Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Executor: Codeunit "Playbook Transform Exec ori";
        Lib: Codeunit "Playbook Test Library ori";

    /// <summary>CopyPreservesNestedJsonType.</summary>
    [Test]
    procedure Scenario_AC42_CopyPreservesNestedJsonType()
    var
        Source: JsonToken;
        Result: JsonToken;
        Text: Text;
    begin
        // Story #155, AC4.2 | Time: independent of Today/WorkDate | Risk: None
        Source.ReadFrom('{"items":[1,true,null]}');
        Result := Executor.ApplyOperation("Transform Operation ori"::Copy, Source, '', '');
        Result.WriteTo(Text);
        Assert.AreEqual('{"items":[1,true,null]}', Text, 'Copy must retain structured JSON');
    end;

    /// <summary>ConstantDoesNotInterpretReferences.</summary>
    [Test]
    procedure Scenario_AC42_ConstantDoesNotInterpretReferences()
    var
        Source: JsonToken;
        Result: JsonToken;
    begin
        // Story #155, AC4.2 | Time: independent of Today/WorkDate | Risk: None
        Result := Executor.ApplyOperation("Transform Operation ori"::Constant, Source, '@_who.secret', '');
        Assert.AreEqual('@_who.secret', Result.AsValue().AsText(), 'Constant remains literal text');
    end;

    /// <summary>NegatePreservesDecimalAndTextAcrossLanguages.</summary>
    [Test]
    procedure Scenario_AC42_NegatePreservesDecimalAndTextAcrossLanguages()
    var
        NumberToken: JsonToken;
        TextToken: JsonToken;
        NumberResult: JsonToken;
        TextResult: JsonToken;
        OriginalLanguage: Integer;
    begin
        // Story #155, AC4.2 | Time: independent of Today/WorkDate | Risk: Restore session language before asserting
        OriginalLanguage := GlobalLanguage();
        NumberToken.ReadFrom('123.45');
        TextToken.ReadFrom('"-123.45"');
        GlobalLanguage(1039);
        NumberResult := Executor.ApplyOperation("Transform Operation ori"::Negate, NumberToken, '', '');
        TextResult := Executor.ApplyOperation("Transform Operation ori"::Negate, TextToken, '', '');
        GlobalLanguage(OriginalLanguage);
        Assert.AreEqual(-123.45, NumberResult.AsValue().AsDecimal(), 'Numeric type retained');
        Assert.AreEqual('123.45', TextResult.AsValue().AsText(), 'Invariant text independent of session locale');
    end;

    /// <summary>NegateLeavesNonnumericTextUnchanged.</summary>
    [Test]
    procedure Scenario_AC42_NegateLeavesNonnumericTextUnchanged()
    var
        Source: JsonToken;
        Result: JsonToken;
    begin
        // Story #155, AC4.2 | Time: independent of Today/WorkDate | Risk: None
        Source.ReadFrom('"not an amount"');
        Result := Executor.ApplyOperation("Transform Operation ori"::Negate, Source, '', '');
        Assert.AreEqual('not an amount', Result.AsValue().AsText(), 'Nonnumeric text unchanged');
    end;

    /// <summary>ReplaceTextIsLiteralAndCaseSensitive.</summary>
    [Test]
    procedure Scenario_AC42_ReplaceTextIsLiteralAndCaseSensitive()
    var
        Source: JsonToken;
        Result: JsonToken;
    begin
        // Story #155, AC4.2 | Time: independent of Today/WorkDate | Risk: None
        Source.ReadFrom('"ABC abc ABC"');
        Result := Executor.ApplyOperation("Transform Operation ori"::"Replace Text", Source, 'ABC', 'X');
        Assert.AreEqual('X abc X', Result.AsValue().AsText(), 'Literal replacement');
    end;

    /// <summary>MissingSourceReturnsFailureWithoutPartialOutput.</summary>
    [Test]
    procedure Scenario_AC42_MissingSourceReturnsFailureWithoutPartialOutput()
    var
        Step: Record "Playbook Step ori";
        Input: JsonObject;
        ResponseText: Text;
        ErrorText: Text;
    begin
        // Story #155, AC4.2 | Time: independent of Today/WorkDate | Risk: None
        CreateTransform(Step);
        AddMapping(Step, 10000, 'first', 'known', "Transform Operation ori"::Copy);
        AddMapping(Step, 20000, 'second', 'missing', "Transform Operation ori"::Copy);
        Input.Add('known', 7);
        Assert.IsFalse(Executor.Execute(Step, Input, ResponseText, ErrorText), 'Missing input fails');
        Assert.AreEqual('', ResponseText, 'No partial output escapes');
        Assert.IsTrue(ErrorText.Contains('missing'), 'Error identifies source');
        Lib.Cleanup(Step."Playbook Code");
    end;

    /// <summary>RunnerTransformsArrayWithoutDispatchingTheStep.</summary>
    [Test]
    procedure Scenario_AC44_RunnerTransformsArrayWithoutDispatchingTheStep()
    var
        FirstStep: Record "Playbook Step ori";
        Step: Record "Playbook Step ori";
        Instance: Record "Playbook Instance ori";
        StepLog: Record "Playbook Step Log ori";
        Runner: Codeunit "Playbook Runner ori";
        Workspace: Codeunit "Playbook Workspace ori";
        InitialRequest: BigText;
        Response: BigText;
        InstanceId: Guid;
        Token: JsonToken;
        Rows: JsonArray;
        Row: JsonToken;
        Amount: JsonToken;
    begin
        // Story #155, AC4.4 | Time: independent of Today/WorkDate | Risk: Workspace seeding legitimately dispatches WhoAmI
        CreateTransform(FirstStep);
        FirstStep.SetRequestTemplate('{"rows":[{"amount":12.5},{"amount":-8}]}');
        FirstStep."Next Step No. (Success)" := 20;
        FirstStep.Modify(true);
        AddMapping(FirstStep, 10000, 'result', 'rows', "Transform Operation ori"::Copy);
        Step.Init();
        Step."Playbook Code" := FirstStep."Playbook Code";
        Step."Step No." := 20;
        Step."Step Kind" := Step."Step Kind"::Transform;
        Step."Iterate Source Step No." := 10;
        Step."Iterate Array Path" := 'result';
        Step."Stop On Item Error" := true;
        Step.Insert(true);
        AddMapping(Step, 10000, 'amount', 'amount', "Transform Operation ori"::Negate);
        Commit();
        Runner.Run(FirstStep."Playbook Code", InitialRequest, Response, InstanceId);
        Instance.Get(InstanceId);
        Assert.AreEqual(Instance.Status::Completed, Instance.Status, 'Blank message type must never be dispatched for Transform');
        Assert.AreEqual(3, Instance."Steps Executed", 'One source plus two transformed items');
        Assert.IsTrue(Workspace.GetToken('20.result', Token), 'Transform aggregate is available downstream');
        Rows := Token.AsArray();
        Assert.AreEqual(2, Rows.Count(), 'Both rows retained');
        Rows.Get(0, Row);
        Row.AsObject().Get('amount', Amount);
        Assert.AreEqual(-12.5, Amount.AsValue().AsDecimal(), 'First mapped amount');
        Rows.Get(1, Row);
        Row.AsObject().Get('amount', Amount);
        Assert.AreEqual(8, Amount.AsValue().AsDecimal(), 'Second mapped amount');
        StepLog.SetRange("Instance ID", InstanceId);
        StepLog.SetRange("Step Kind", StepLog."Step Kind"::Transform);
        Assert.AreEqual(3, StepLog.Count(), 'Every log identifies Transform');
        Lib.Cleanup(FirstStep."Playbook Code");
        Commit();
    end;

    /// <summary>Preview retains its seeded-only contract even when local Transform definitions exist.</summary>
    [Test]
    procedure Scenario_AC44_PreviewDoesNotRunTransformDefinitions()
    var
        Step: Record "Playbook Step ori";
        Instance: Record "Playbook Instance ori";
        TempArgument: Record "Message Argument ori" temporary;
        DispatchHelper: Codeunit "Orch Dispatch Helper ori";
        Request: JsonObject;
        Response: JsonObject;
        Initial: JsonObject;
        Token: JsonToken;
    begin
        // Story #155, AC4.4 | Time: independent of Today/WorkDate | Risk: Preview seeds WhoAmI through its established dispatch
        CreateTransform(Step);
        AddMapping(Step, 10000, 'amount', 'amount', "Transform Operation ori"::Negate);
        Initial.Add('amount', 12.5);
        Request.Add('initialRequest', Initial);
        TempArgument.Insert();
        TempArgument.SetRequestJson(Request);
        Commit();
        DispatchHelper.Execute("Message Type ori"::"Orchestrator.Workspace.Preview", TempArgument);
        Response := TempArgument.GetResponseJson();
        Assert.IsTrue(Response.Get('_initial', Token), 'Preview preserves initial input');
        Token.AsObject().Get('amount', Token);
        Assert.AreEqual(12.5, Token.AsValue().AsDecimal(), 'Preview must not transform the seed');
        Assert.IsFalse(Response.Contains('10'), 'Preview must not claim a step result');
        Instance.SetRange("Playbook Code", Step."Playbook Code");
        Assert.IsTrue(Instance.IsEmpty(), 'Preview must not start a saved playbook');
        Lib.Cleanup(Step."Playbook Code");
        Commit();
    end;

    local procedure CreateTransform(var Step: Record "Playbook Step ori")
    var
        Code: Code[20];
    begin
        Code := CopyStr('T' + DelChr(Format(CreateGuid(), 0, 4), '=', '{}-'), 1, MaxStrLen(Code));
        Lib.CreatePlaybook(Code);
        Step.Init();
        Step."Playbook Code" := Code;
        Step."Step No." := 10;
        Step."Step Kind" := Step."Step Kind"::Transform;
        Step.Insert(true);
    end;

    local procedure AddMapping(Step: Record "Playbook Step ori"; LineNo: Integer; Target: Text[250]; Source: Text[250]; Operation: Enum "Transform Operation ori")
    var
        Mapping: Record "Playbook Transform ori";
    begin
        Mapping.Init();
        Mapping."Playbook Code" := Step."Playbook Code";
        Mapping."Step No." := Step."Step No.";
        Mapping."Line No." := LineNo;
        Mapping."Target Path" := Target;
        Mapping."Source Path" := Source;
        Mapping.Operation := Operation;
        Mapping.Insert(true);
    end;
}
