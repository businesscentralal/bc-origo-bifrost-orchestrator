namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;

codeunit 96421 "Playbook Run Msg Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        IsInitialized := true;
    end;

    [Test]
    procedure RunErrorsWhenPlaybookCodeMissing()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Playbook Msg Handler ori";
    begin
        // [SCENARIO] Playbook.Run errors when playbookCode is missing
        CreateArgument(TempArgument, '{}');

        asserterror Handler.ExecuteRun(TempArgument);
        Assert.ExpectedError('playbookCode');
    end;

    [Test]
    procedure RunErrorsForUnknownPlaybookCode()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Playbook Msg Handler ori";
    begin
        // [SCENARIO] Playbook.Run errors for a non-existent playbook code
        CreateArgument(TempArgument, '{"playbookCode": "DOES-NOT-EXIST"}');

        asserterror Handler.ExecuteRun(TempArgument);
        Assert.ExpectedError('DOES-NOT-EXIST');
    end;

    // Requires live MCP server — run manually only
    procedure RunEmptyPlaybookReturnsCompleted()
    var
        Playbook: Record "Playbook ori";
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Playbook Msg Handler ori";
        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] Running a playbook with no steps completes successfully
        Initialize();
        CreateMinimalPlaybook(Playbook, 'PB-RUN-T1');

        CreateArgument(TempArgument, '{"playbookCode": "' + Playbook.Code + '"}');
        Handler.ExecuteRun(TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('status', Token);
        Assert.AreEqual('Success', Token.AsValue().AsText(), 'Status should be Success');
        ResponseJson.Get('playbookStatus', Token);
        Assert.AreEqual('Completed', Token.AsValue().AsText(), 'Empty playbook should complete');
        Assert.IsTrue(ResponseJson.Contains('instanceId'), 'Missing instanceId');
        Assert.IsTrue(ResponseJson.Contains('stepsExecuted'), 'Missing stepsExecuted');

        CleanupPlaybook(Playbook.Code);
    end;

    // Requires live MCP server — run manually only
    procedure RunAcceptsPlaybookCodeInSubject()
    var
        Playbook: Record "Playbook ori";
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Playbook Msg Handler ori";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] Playbook.Run accepts playbookCode via Subject fallback
        Initialize();
        CreateMinimalPlaybook(Playbook, 'PB-RUN-T2');

        TempArgument.Init();
        TempArgument.Subject := Playbook.Code;
        TempArgument.Insert();
        RequestJson.ReadFrom('{}');
        TempArgument.SetRequestJson(RequestJson);

        Handler.ExecuteRun(TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('playbookCode', Token);
        Assert.AreEqual(Playbook.Code, Token.AsValue().AsText(), 'Should resolve code from Subject');

        CleanupPlaybook(Playbook.Code);
    end;

    // RunEmptyPlaybookReturnsCompleted and RunAcceptsPlaybookCodeInSubject
    // require a live MCP server (Runner → SeedWhoAmI → CallTool → session-starting log)
    // and cannot run in CI.  Kept as local-only manual tests below.

    /// <summary>Paging injects skip/take into the outgoing request and preserves the caller payload.</summary>
    [Test]
    procedure Scenario_AC07_PagedStep_ReceivesItsOwnSkipAndTake()
    var
        Playbook: Record "Playbook ori";
        PlaybookStep: Record "Playbook Step ori";
        Instance: Record "Playbook Instance ori";
        StepLog: Record "Playbook Step Log ori";
        Runner: Codeunit "Playbook Runner ori";
        InitialRequest: BigText;
        FinalResponse: BigText;
        InstanceId: Guid;
        Request: JsonObject;
        Value: JsonToken;
        InitialText: Text;
    begin
        // Story #68, AC07 | Time: independent of Today/WorkDate | Risk: dispatcher transaction boundary.
        Initialize();
        // [GIVEN] A self-created paged step with stale skip/take in its outgoing template.
        CreateMinimalPlaybook(Playbook, 'PB-GUARD-68');
        PlaybookStep.Init();
        PlaybookStep."Playbook Code" := Playbook.Code;
        PlaybookStep."Step No." := 10;
        PlaybookStep."Message Type" := "Message Type ori"::"Help.Implementation.Get";
        PlaybookStep.Paged := true;
        PlaybookStep."Page Size" := 2;
        PlaybookStep.SetRequestTemplate('{"messageTypes":["Orchestrator.Playbook.Schedule"],"chapters":["parameters"],"skip":99,"take":99,"marker":"outgoing"}');
        PlaybookStep.Insert(true);
        InitialText := '{"marker":"caller"}';
        InitialRequest.AddText(InitialText);
        Commit();
        // [WHEN] The real runner dispatches the first page (Help has no subsequent result pages).
        Runner.Run(Playbook.Code, InitialRequest, FinalResponse, InstanceId);
        // [THEN] Only the outgoing step request receives paging keys; its other fields survive.
        StepLog.Get(InstanceId, 10, 0);
        Assert.IsTrue(Request.ReadFrom(StepLog.GetRequestSent()), 'Valid logged page request');
        Request.Get('skip', Value);
        Assert.AreEqual(0, Value.AsValue().AsInteger(), 'First page starts at zero');
        Request.Get('take', Value);
        Assert.AreEqual(2, Value.AsValue().AsInteger(), 'Configured page size replaces stale take');
        Request.Get('marker', Value);
        Assert.AreEqual('outgoing', Value.AsValue().AsText(), 'Outgoing step template is preserved');
        Assert.IsTrue(Request.ReadFrom(StepLog.GetResponseReceived()), 'Valid help response');
        Request.Get('status', Value);
        Assert.AreEqual('Success', Value.AsValue().AsText(), 'The paged step returns a successful help response');
        InitialRequest.GetSubText(InitialText, 1);
        Assert.AreEqual('{"marker":"caller"}', InitialText, 'Caller request remains unchanged');
        Instance.Get(InstanceId);
        Assert.AreEqual(1, Instance."Steps Executed", 'One dispatch for a non-paged help result');
        Assert.AreEqual(0, Instance."Steps Failed", 'Documented free Help dispatch succeeds');
        Assert.AreEqual("Playbook Inst. Status ori"::Completed, Instance.Status, 'Paged step completes');
        // Remove only this test's owned playbook and execution records across committed dispatch.
        StepLog.SetRange("Instance ID", InstanceId);
        StepLog.DeleteAll(true);
        Instance.Delete(true);
        CleanupPlaybook(Playbook.Code);
        Commit();
    end;

    local procedure CreateArgument(var TempArgument: Record "Message Argument ori" temporary; RequestJsonText: Text)
    var
        RequestJson: JsonObject;
    begin
        TempArgument.Init();
        TempArgument.Insert();
        RequestJson.ReadFrom(RequestJsonText);
        TempArgument.SetRequestJson(RequestJson);
    end;

    local procedure CreateMinimalPlaybook(var Playbook: Record "Playbook ori"; PlaybookCode: Code[20])
    begin
        if Playbook.Get(PlaybookCode) then begin
            Playbook.Description := 'Test playbook';
            Playbook.Modify(true);
            exit;
        end;
        Playbook.Init();
        Playbook.Code := PlaybookCode;
        Playbook.Description := 'Test playbook';
        Playbook.Insert(true);
    end;

    local procedure CleanupPlaybook(PlaybookCode: Code[20])
    var
        Playbook: Record "Playbook ori";
        Instance: Record "Playbook Instance ori";
    begin
        Instance.SetRange("Playbook Code", PlaybookCode);
        Instance.DeleteAll(true);
        if Playbook.Get(PlaybookCode) then
            Playbook.Delete(true);
    end;
}
