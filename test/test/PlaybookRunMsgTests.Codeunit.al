namespace Origo.Bifrost.Nornir.Test;

using Origo.Bifrost;
using Origo.Bifrost.Nornir;

codeunit 96321 "Playbook Run Msg Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        TestInstall: Codeunit "Test Install";
    begin
        if IsInitialized then
            exit;
        TestInstall.DisableRequestDebugMode();
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
