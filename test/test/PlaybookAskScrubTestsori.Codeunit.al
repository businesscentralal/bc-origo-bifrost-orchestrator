namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>Issue #134: trace scrubbing at dispatch, all runner paths, debug logging, and run/help guidance.</summary>
codeunit 96444 "Playbook Ask Scrub Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;
    RequiredTestIsolation = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Lib: Codeunit "Playbook Test Library ori";
        Scrub: Codeunit "Playbook Response Scrub ori";
        PlaybookCodeTok: Label 'XASK-SCRUB', Locked = true;
        TraceMarkerTok: Label 'XASK-PRIVATE-TRACE', Locked = true;

    [Test]
    procedure Scrub_PreservesAllOtherProperties()
    var
        Response: Text;
        Original: JsonObject;
        Actual: JsonObject;
        ExpectedToken: JsonToken;
        ActualToken: JsonToken;
        PropertyName: Text;
    begin
        Response := '{"trace":[{"prompt":"private"}],"answer":"done","data":{"trace":"nested"},"toolCalls":2,"schemaValid":true}';
        Original.ReadFrom(Response);
        Scrub.Scrub('LLM.Prompt.Ask', Response);
        Actual.ReadFrom(Response);
        Assert.IsFalse(Actual.Contains('trace'), 'Only top-level trace is discarded');
        Assert.AreEqual(Original.Keys().Count() - 1, Actual.Keys().Count(), 'Other properties remain');
        foreach PropertyName in Actual.Keys() do begin
            Original.Get(PropertyName, ExpectedToken);
            Actual.Get(PropertyName, ActualToken);
            Assert.AreEqual(TokenText(ExpectedToken), TokenText(ActualToken), 'Property preserved: ' + PropertyName);
        end;
    end;

    [Test]
    procedure Scrub_UnchangedPayloadsRetainBytes()
    begin
        AssertUnchanged('LLM.Prompt.Ask', 'not json');
        AssertUnchanged('LLM.Prompt.Ask', '[{"trace":"nested"}]');
        AssertUnchanged('LLM.Prompt.Ask', ' { "status" : "Error", "error" : "failure" } ');
        AssertUnchanged('LLM.Prompt.Ask', ' { "answer" : "yes", "data" : null } ');
        AssertUnchanged('LLM.Prompt.Complete', ' { "trace" : "other type" } ');
        AssertUnchanged('Test.Orchestrator.Ask', ' { "trace" : "unregistered seam" } ');
    end;

    [Test]
    [HandlerFunctions('DebugWarningHandler')]
    procedure SingleStep_NoTraceInAnyOrchestratorStore()
    begin
        VerifyPersistence(false, false, false, 1);
    end;

    [Test]
    [HandlerFunctions('DebugWarningHandler')]
    procedure FailedStep_WorkspaceSnapshotHasNoTrace()
    begin
        VerifyPersistence(false, false, true, 1);
    end;

    [Test]
    [HandlerFunctions('DebugWarningHandler')]
    procedure ForEach_NoTraceInLogsWorkspaceOrSummary()
    begin
        VerifyPersistence(true, false, false, 2);
    end;

    [Test]
    [HandlerFunctions('DebugWarningHandler')]
    procedure Paged_NoTraceAcrossPageAndIterationLogs()
    begin
        VerifyPersistence(true, true, false, 4);
    end;

    [Test]
    procedure RunAndHelp_DescribeTimeoutAndRetentionBoundaries()
    var
        RunMessage: Codeunit "Playbook Run Msg ori";
        VerifyMessage: Codeunit "Playbook Verify Msg ori";
        Help: Codeunit "Help ori";
        Notes: Text;
        Overview: Text;
    begin
        RunMessage.GetNotes(Notes);
        Assert.IsTrue(Notes.Contains('in-process through the dispatcher'), 'Step execution boundary');
        Assert.IsTrue(Notes.Contains('external caller of Orchestrator.Playbook.Run'), 'Timeout owner');
        Assert.IsTrue(Notes.Contains('Run Now in the BC client have no client timeout'), 'Run Now boundary');
        Assert.IsTrue(Notes.Contains('Job Timeout'), 'Job queue outer bound');
        Overview := Help.GetOverview();
        Assert.IsTrue(Overview.Contains('Orchestrator stores no trace.'), 'Orchestrator trace boundary');
        Assert.IsTrue(Overview.Contains('message log keeps the request and response of every message until retention deletes it'), 'Foundation retention boundary');
        Assert.IsTrue(Overview.Contains('schemaValid'), 'Schema validation guidance');
        Assert.IsTrue(Overview.Contains('Every tool call Ask makes is a counted message'), 'Metering guidance');
        Assert.IsFalse(Overview.Contains('stuck in `Running` for ever'), 'Remove unsupported timeout claim');
        VerifyMessage.GetNotes(Notes);
        Assert.IsTrue(Notes.Contains('AskForEachUnbounded'), 'Bound warning documented');
        Assert.IsTrue(Notes.Contains('AskDataConditionWithoutSchema'), 'Schema warning documented');
        Assert.IsTrue(Notes.Contains('AskTraceDiscarded'), 'Trace warning documented');
    end;

    /// <summary>Consumes the known setup notifications without consenting to or changing licence state.</summary>
    /// <param name="DebugNotification">The notification raised by the real setup page.</param>
    /// <returns>False so the test owns the notification.</returns>
    [SendNotificationHandler]
    procedure DebugWarningHandler(var DebugNotification: Notification): Boolean
    begin
        Assert.IsTrue(
            (DebugNotification.Id = 'b8e2a714-5c3f-4d91-ae07-6f9d1c4b8e25') or
            (DebugNotification.Id = 'a7b3c91d-4e8f-4a2b-9c6d-1f5e8a3b7d02') or
            (DebugNotification.Id = 'd8e7f6a5-4b3c-4d2e-9f1a-8c7b6a5d4e3f'), 'Only known debug/setup notifications');
        exit(false);
    end;

    local procedure VerifyPersistence(ForEachStep: Boolean; PagedSource: Boolean; FailCondition: Boolean; ExpectedLogs: Integer)
    var
        Setup: Record "Setup ori";
        Step: Record "Playbook Step ori";
        StepLog: Record "Playbook Step Log ori";
        RequestLog: Record "Request Log ori";
        Workspace: Codeunit "Playbook Workspace ori";
        Runner: Codeunit "Playbook Runner ori";
        InitialRequest: BigText;
        FinalResponse: BigText;
        SetupPage: TestPage "Setup ori";
        InstanceId: Guid;
        OriginalDebugMode: Boolean;
        BeforeEntryNo: BigInteger;
        WaitAttempt: Integer;
        Response: JsonObject;
        Token: JsonToken;
        Value: Text;
        LogStream: InStream;
    begin
        Scrub.ClearTestTypes();
        Scrub.AddTestType('Test.Orchestrator.Ask');
        OriginalDebugMode := Setup.GetRequestDebugMode();
        SetupPage.OpenEdit();
        SetupPage."Request Debug Mode".SetValue(true);
        SetupPage.Close();
        Commit();
        Assert.IsTrue(Setup.GetRequestDebugMode(), 'Actual debug mode enabled through UI');
        if RequestLog.FindLast() then
            BeforeEntryNo := RequestLog."Entry No.";
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Test.Orchestrator.Ask", '{}', 0, '', 0);
        Lib.AddStatusSuccessCondition(PlaybookCodeTok, 10);
        if ForEachStep then begin
            Lib.AddStep(PlaybookCodeTok, 30, "Playbook Step Type ori"::Action, "Message Type ori"::"Test.Orchestrator.Ask", '{}', 10, 'result', 0);
            Lib.AddStatusSuccessCondition(PlaybookCodeTok, 30);
        end;
        Step.SetRange("Playbook Code", PlaybookCodeTok);
        if Step.FindSet(true) then
            repeat
                Step."Result Log Paths" := 'trace>trace,answer>answer,data>data,toolCalls>toolCalls';
                Step."Summary Paths" := 'trace,answer,data,toolCalls';
                Step.Modify();
            until Step.Next() = 0;
        if PagedSource then begin
            Step.Get(PlaybookCodeTok, 10);
            Step.Paged := true;
            Step."Page Size" := 1;
            Step."Page Through Step No." := 30;
            Step.Modify();
        end;
        if FailCondition then
            Lib.AddCondition(PlaybookCodeTok, 10, "Playbook Cond. Type ori"::Success, 20000, 'answer', "Playbook Cond. Operator ori"::Equals, 'not this answer');
        Commit();
        Runner.Run(PlaybookCodeTok, InitialRequest, FinalResponse, InstanceId);
        // Restore environment settings before assertions so a failed assertion does not leave debugging on.
        SetupPage.OpenEdit();
        SetupPage."Request Debug Mode".SetValue(OriginalDebugMode);
        SetupPage.Close();
        Scrub.ClearTestTypes();
        Commit();
        StepLog.SetRange("Instance ID", InstanceId);
        Assert.AreEqual(ExpectedLogs, StepLog.Count(), 'Every expected dispatcher call wrote a log');
        Assert.IsTrue(StepLog.FindSet(), 'At least one real step executed');
        repeat
            Response.ReadFrom(StepLog.GetResponseReceived());
            Assert.IsFalse(Response.Contains('trace'), 'Trace absent from response log');
            Response.Get('answer', Token);
            Assert.AreEqual('audit complete', Token.AsValue().AsText(), 'Answer retained');
            Response.Get('toolCalls', Token);
            Assert.AreEqual(2, Token.AsValue().AsInteger(), 'Counts retained');
            Response.Get('data', Token);
            Assert.IsTrue(Token.AsObject().Contains('trace'), 'Nested business field untouched');
            Assert.IsFalse(StepLog.GetWorkspaceSnapshot().Contains(TraceMarkerTok), 'No trace in failed-step snapshot');
            StepLog.CalcFields("Iterator Element");
            StepLog."Iterator Element".CreateInStream(LogStream, TextEncoding::UTF8);
            LogStream.ReadText(Value);
            Assert.IsFalse(Value.Contains(TraceMarkerTok), 'No trace in iterator element');
        until StepLog.Next() = 0;
        Assert.IsFalse(Workspace.ToText().Contains(TraceMarkerTok), 'No trace in workspace or step summary');
        FinalResponse.GetSubText(Value, 1);
        Assert.IsFalse(Value.Contains(TraceMarkerTok), 'No trace in final response');
        RequestLog.SetFilter("Entry No.", '>%1', BeforeEntryNo);
        RequestLog.SetRange(Operation, 'Test.Orchestrator.Ask');
        RequestLog.SetRange(SystemCreatedBy, UserSecurityId());
        // Foundation writes debug logs in background sessions; wait for the actual rows.
        for WaitAttempt := 1 to 100 do begin
            SelectLatestVersion();
            if RequestLog.Count() = ExpectedLogs then
                break;
            Sleep(100);
        end;
        Assert.AreEqual(ExpectedLogs, RequestLog.Count(), 'Debug log written for every fixture call');
        VerifyDebugLogs(RequestLog);
        RequestLog.DeleteAll(true);
        Assert.IsTrue(RequestLog.IsEmpty(), 'Owned request logs removed');
        Lib.Cleanup(PlaybookCodeTok);
        Assert.IsTrue(StepLog.IsEmpty(), 'Owned step logs removed');
    end;

    local procedure VerifyDebugLogs(var RequestLog: Record "Request Log ori")
    var
        TempArgument: Record "Message Argument ori" temporary;
        MessageImpl: Interface "Msg Interface ori";
        Request: JsonObject;
        Response: JsonObject;
        Token: JsonToken;
        Entries: JsonArray;
        Body: JsonObject;
    begin
        Request.Add('take', 100);
        Request.Add('tableView', RequestLog.GetView(false));
        TempArgument.Init();
        TempArgument.Insert();
        TempArgument.SetRequestJson(Request);
        MessageImpl := "Message Type ori"::"Data.RequestLog.Get";
        MessageImpl.ExecuteBifrostTask(TempArgument);
        Response := TempArgument.GetResponseJson();
        Assert.IsTrue(Response.Get('entries', Token), 'Read owned logs through the public message interface');
        Entries := Token.AsArray();
        Assert.AreEqual(RequestLog.Count(), Entries.Count(), 'Every owned log was read');
        foreach Token in Entries do begin
            Token.AsObject().Get('responseBody', Token);
            Assert.IsTrue(Body.ReadFrom(Token.AsValue().AsText()), 'Debug response remains JSON');
            Assert.IsFalse(Body.Contains('trace'), 'Debug log has no trace');
            Assert.IsTrue(Body.Contains('answer') and Body.Contains('data') and Body.Contains('toolCalls'), 'Debug fields retained');
        end;
    end;

    local procedure AssertUnchanged(TypeName: Text; Original: Text)
    var
        Actual: Text;
    begin
        Scrub.ClearTestTypes();
        Actual := Original;
        Scrub.Scrub(TypeName, Actual);
        Assert.AreEqual(Original, Actual, 'Byte-for-byte response preservation');
    end;

    local procedure TokenText(Token: JsonToken) Result: Text
    begin
        Token.WriteTo(Result);
    end;
}
