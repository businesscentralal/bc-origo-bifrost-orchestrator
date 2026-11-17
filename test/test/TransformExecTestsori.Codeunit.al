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

    /// <summary>ParseJsonTurnsTextIntoObject (#193).</summary>
    [Test]
    procedure Scenario_193_ParseJsonTurnsTextIntoObject()
    var
        TextValue: JsonValue;
        Source: JsonToken;
        Result: JsonToken;
        Value: JsonToken;
        Reply: JsonObject;
        ReplyText: Text;
    begin
        // Issue #193 | Time: independent of Today/WorkDate | Risk: None
        Reply.Add('header', 'INV-1');
        Reply.WriteTo(ReplyText);
        TextValue.SetValue(ReplyText);
        Source := TextValue.AsToken();
        Result := Executor.ApplyOperation("Transform Operation ori"::"Parse JSON", Source, '', '');
        Assert.IsTrue(Result.IsObject(), 'Text holding a JSON object becomes an object');
        Result.AsObject().Get('header', Value);
        Assert.AreEqual('INV-1', Value.AsValue().AsText(), 'Property survives');
        TextValue.SetValue('[1,2]');
        Source := TextValue.AsToken();
        Result := Executor.ApplyOperation("Transform Operation ori"::"Parse JSON", Source, '', '');
        Assert.IsTrue(Result.IsArray(), 'Text holding a JSON array becomes an array');
        Assert.AreEqual(2, Result.AsArray().Count(), 'Both elements kept');
    end;

    /// <summary>ParseJsonAcceptsMarkdownFenceAndPassesThroughObjects (#193).</summary>
    [Test]
    procedure Scenario_193_ParseJsonAcceptsFenceAndPassesThroughObjects()
    var
        TextValue: JsonValue;
        Source: JsonToken;
        Result: JsonToken;
        Value: JsonToken;
        LineFeed: Text[1];
        Fenced: Text;
    begin
        // Issue #193 edge: language models wrap JSON in a code fence | Risk: None
        LineFeed[1] := 10;
        Fenced := '```json' + LineFeed + '{"a":1}' + LineFeed + '```';
        TextValue.SetValue(Fenced);
        Source := TextValue.AsToken();
        Result := Executor.ApplyOperation("Transform Operation ori"::"Parse JSON", Source, '', '');
        Assert.IsTrue(Result.IsObject(), 'Fenced JSON is parsed');
        Result.AsObject().Get('a', Value);
        Assert.AreEqual(1, Value.AsValue().AsInteger(), 'Fenced value');
        Source.ReadFrom('{"b":2}');
        Result := Executor.ApplyOperation("Transform Operation ori"::"Parse JSON", Source, '', '');
        Assert.IsTrue(Result.IsObject(), 'An object source is copied');
        Source.ReadFrom('null');
        Result := Executor.ApplyOperation("Transform Operation ori"::"Parse JSON", Source, '', '');
        Assert.IsTrue(Result.AsValue().IsNull(), 'Null stays null');
    end;

    /// <summary>ParseJsonRejectsInvalidAndScalarText (#193).</summary>
    [Test]
    procedure Scenario_193_ParseJsonRejectsInvalidAndScalarText()
    var
        TextValue: JsonValue;
        Source: JsonToken;
        Result: JsonToken;
    begin
        // Issue #193 invalid input | Risk: None
        TextValue.SetValue('not json {');
        Source := TextValue.AsToken();
        asserterror Result := Executor.ApplyOperation("Transform Operation ori"::"Parse JSON", Source, '', '');
        Assert.ExpectedError('not valid JSON');
        TextValue.SetValue('42');
        Source := TextValue.AsToken();
        asserterror Result := Executor.ApplyOperation("Transform Operation ori"::"Parse JSON", Source, '', '');
        Assert.ExpectedError('JSON object or array');
    end;

    /// <summary>TransformStepDeliversParsedObjectToTarget (#193).</summary>
    [Test]
    procedure Scenario_193_TransformStepDeliversParsedObject()
    var
        Step: Record "Playbook Step ori";
        Input: JsonObject;
        Output: JsonObject;
        Token: JsonToken;
        ResponseText: Text;
        ErrorText: Text;
    begin
        // Issue #193 AC: whole-value text reply becomes an object a later step can pass on | Risk: None
        CreateTransform(Step);
        AddMapping(Step, 10000, 'documentData', 'reply', "Transform Operation ori"::"Parse JSON");
        Input.Add('reply', '{"header":{"number":"INV-1"}}');
        Assert.IsTrue(Executor.Execute(Step, Input, ResponseText, ErrorText), ErrorText);
        Output.ReadFrom(ResponseText);
        Output.Get('documentData', Token);
        Assert.IsTrue(Token.IsObject(), 'documentData is an object, not text');
        Lib.Cleanup(Step."Playbook Code");
    end;

    /// <summary>TransformSourceExpandsIterationIndex (#212).</summary>
    [Test]
    procedure Scenario_212_SourcePathExpandsIterationIndex()
    var
        Step: Record "Playbook Step ori";
        Workspace: Codeunit "Playbook Workspace ori";
        Input: JsonObject;
        Output: JsonObject;
        Token: JsonToken;
        Inner: JsonToken;
        ResponseText: Text;
        ErrorText: Text;
    begin
        // Issue #212 AC: @50.@_iter.reply reads the same item of an earlier forEach step | Risk: Workspace is single instance
        Workspace.SetValue('50.0.reply', '{"n":"first"}');
        Workspace.SetValue('50.1.reply', '{"n":"second"}');
        Workspace.SetValue('_iter', '1');
        CreateTransform(Step);
        AddMapping(Step, 10000, 'documentData', '@50.@_iter.reply', "Transform Operation ori"::"Parse JSON");
        Assert.IsTrue(Executor.Execute(Step, Input, ResponseText, ErrorText), ErrorText);
        Output.ReadFrom(ResponseText);
        Output.Get('documentData', Token);
        Assert.IsTrue(Token.IsObject(), 'documentData is an object');
        Token.AsObject().Get('n', Inner);
        Assert.AreEqual('second', Inner.AsValue().AsText(), 'Item of iteration 1 is read');
        Workspace.SetValue('_iter', '0');
        Assert.IsTrue(Executor.Execute(Step, Input, ResponseText, ErrorText), ErrorText);
        Output.ReadFrom(ResponseText);
        Output.Get('documentData', Token);
        Token.AsObject().Get('n', Inner);
        Assert.AreEqual('first', Inner.AsValue().AsText(), 'Item of iteration 0 is read');
        Lib.Cleanup(Step."Playbook Code");
    end;

    /// <summary>MissingIterationItemFailsWithPath (#212).</summary>
    [Test]
    procedure Scenario_212_MissingIterationItemFails()
    var
        Step: Record "Playbook Step ori";
        Workspace: Codeunit "Playbook Workspace ori";
        Input: JsonObject;
        ResponseText: Text;
        ErrorText: Text;
    begin
        // Issue #212 invalid input: iteration without an item fails and names the path | Risk: None
        Workspace.SetValue('50.0.reply', '{}');
        Workspace.SetValue('_iter', '5');
        CreateTransform(Step);
        AddMapping(Step, 10000, 'documentData', '@50.@_iter.reply', "Transform Operation ori"::Copy);
        Assert.IsFalse(Executor.Execute(Step, Input, ResponseText, ErrorText), 'Missing item fails');
        Assert.IsTrue(ErrorText.Contains('@50.@_iter.reply'), 'Error names the source path');
        Lib.Cleanup(Step."Playbook Code");
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

    /// <summary>Verify warns on declared string output feeding an object or array, including iteration references.</summary>
    [Test]
    procedure Scenario_AC02_StringReferenceToObject_Warns()
    begin
        // Issue #193, AC02 | Time: independent of Today/WorkDate | Risk: None
        CheckStringReference('{"initialRequest":"@10.playbookCode"}', false, false, false, 1033, 1);
        CheckStringReference('{"initialRequest":"@10.@_iter.playbookCode"}', true, false, false, 1033, 1);
        CheckStringReference('{"initialRequest":"@10.0.playbookCode"}', true, false, false, 1033, 1);
        CheckStringReference('{"fieldNumbers":"@10.playbookCode"}', false, true, false, 1033, 1);
    end;

    /// <summary>Literal objects, non-string or unknown output and converted Transform output do not warn.</summary>
    [Test]
    procedure Scenario_AC02_ObjectAndUnknownReferences_NoWarning()
    begin
        // Issue #193, AC02 | Time: independent of Today/WorkDate | Risk: None
        CheckStringReference('{"initialRequest":{}}', false, false, false, 1033, 0);
        CheckStringReference('{"initialRequest":null}', false, false, false, 1033, 0);
        CheckStringReference('{"initialRequest":"@10.findings"}', false, false, false, 1033, 0);
        CheckStringReference('{"initialRequest":"@10.unknown"}', false, false, false, 1033, 0);
        CheckStringReference('{"initialRequest":"@_initial.documentData"}', false, false, false, 1033, 0);
        CheckStringReference('{"initialRequest":"prefix @10.playbookCode"}', false, false, false, 1033, 0);
        CheckStringReference('{"initialRequest":"@10.playbookCode suffix"}', false, false, false, 1033, 0);
        CheckStringReference('{"playbookCode":"@10.playbookCode"}', false, false, false, 1033, 0);
        CheckStringReference('{"initialRequest":"@10.result"}', false, false, true, 1033, 0);
    end;

    /// <summary>The warning and conversion advice are localized, and disabled steps never block.</summary>
    [Test]
    procedure Scenario_AC02_StringWarning_LocalizedAndDisabled()
    begin
        // Issue #193, AC02 | Time: independent of Today/WorkDate | Risk: None
        CheckStringReference('{"initialRequest":"@10.playbookCode"}', false, false, false, 1039, 1);
    end;

    local procedure CheckStringReference(Template: Text; ForEachSource: Boolean; ArrayParameter: Boolean; ParsedSource: Boolean; LanguageId: Integer; ExpectedCount: Integer)
    var
        SourceStep: Record "Playbook Step ori";
        TargetStep: Record "Playbook Step ori";
        Verify: Codeunit "Playbook Verify ori";
        Findings: JsonArray;
        Finding: JsonToken;
        Value: JsonToken;
        Code: Code[20];
        Count: Integer;
        PreviousLanguage: Integer;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Code := CopyStr('P193-' + DelChr(Format(CreateGuid(), 0, 4), '=', '{}-'), 1, 20);
        Lib.CreatePlaybook(Code);
        Lib.AddStep(Code, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Orchestrator.Playbook.Verify", '{}', 0, '', 0);
        SourceStep.Get(Code, 10);
        if ForEachSource then
            SourceStep."Iterate Array Path" := 'result';
        if ParsedSource then begin
            SourceStep.Validate("Step Kind", SourceStep."Step Kind"::Transform);
            SourceStep.SetRequestTemplate('{"reply":"{\"header\":{}}"}');
            AddMapping(SourceStep, 10000, 'result', 'reply', "Transform Operation ori"::"Parse JSON");
        end;
        SourceStep.Modify(true);
        if ArrayParameter then
            Lib.AddStep(Code, 20, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get", Template, 0, '', 0)
        else
            Lib.AddStep(Code, 20, "Playbook Step Type ori"::Action, "Message Type ori"::"Orchestrator.Playbook.Run", Template, 0, '', 0);
        TargetStep.Get(Code, 20);
        TargetStep.Disabled := LanguageId = 1039;
        TargetStep.Modify(true);
        // [WHEN] The normal Verify entry point collects all step and template checks.
        Verify.GetFindings(Code, Findings);
        // [THEN] Only proved string-to-object mismatches receive this warning.
        foreach Finding in Findings do begin
            Finding.AsObject().Get('code', Value);
            if Value.AsValue().AsText() = 'StringReferenceToObject' then begin
                Count += 1;
                Finding.AsObject().Get('severity', Value);
                Assert.AreEqual('warning', Value.AsValue().AsText(), 'A type mismatch is a warning');
                Finding.AsObject().Get('stepNo', Value);
                Assert.AreEqual(20, Value.AsValue().AsInteger(), 'Warning names the consumer');
                Finding.AsObject().Get('message', Value);
                if LanguageId = 1039 then begin
                    Assert.IsTrue(Value.AsValue().AsText().StartsWith('Skref 20'), 'Icelandic warning');
                    Assert.IsTrue(Finding.AsObject().Contains('stepDisabled'), 'Disabled warning is informational');
                end else
                    Assert.IsTrue(Value.AsValue().AsText().StartsWith('Step 20'), 'English warning');
                Finding.AsObject().Get('nextStep', Value);
                if LanguageId = 1039 then
                    Assert.IsTrue(Value.AsValue().AsText().Contains('Þátta JSON'), 'Icelandic conversion advice')
                else
                    Assert.IsTrue(Value.AsValue().AsText().Contains('Parse JSON'), 'English conversion advice');
            end;
        end;
        Assert.AreEqual(ExpectedCount, Count, 'StringReferenceToObject count: ' + Template);
        Lib.Cleanup(Code);
        GlobalLanguage(PreviousLanguage);
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
