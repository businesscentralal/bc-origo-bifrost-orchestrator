namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;

codeunit 96422 "Misc Msg Smoke Tests"
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
    procedure HelpGetReturnsNonEmptyMarkdown()
    var
        TempArgument: Record "Message Argument ori" temporary;
        HelpImpl: Codeunit "Help Get Impl ori";
        ResponseJson: JsonObject;
        Token: JsonToken;
        ResultObj: JsonObject;
    begin
        // [SCENARIO] Help.Orchestrator.Get returns a non-empty markdown document
        Initialize();
        CreateArgument(TempArgument, '{}');

        HelpImpl.ExecuteBifrostTask(TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('status', Token);
        Assert.AreEqual('Success', Token.AsValue().AsText(), 'Status should be Success');

        ResponseJson.Get('result', Token);
        ResultObj := Token.AsObject();
        ResultObj.Get('markdown', Token);
        Assert.AreNotEqual('', Token.AsValue().AsText(), 'Markdown should not be empty');
    end;

    [Test]
    procedure WorkspacePreviewReturnsSysNamespace()
    var
        TempArgument: Record "Message Argument ori" temporary;
        PreviewMsg: Codeunit "Workspace Preview Msg ori";
        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] Workspace.Preview returns seeded workspace with _sys namespace
        Initialize();
        CreateArgument(TempArgument, '{}');

        PreviewMsg.ExecuteBifrostTask(TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('status', Token);
        Assert.AreEqual('Success', Token.AsValue().AsText(), 'Status should be Success');
        Assert.IsTrue(ResponseJson.Contains('_sys'), 'Missing _sys namespace');
    end;

    [Test]
    procedure WorkspacePreviewPassesThroughInitialRequest()
    var
        TempArgument: Record "Message Argument ori" temporary;
        PreviewMsg: Codeunit "Workspace Preview Msg ori";
        ResponseJson: JsonObject;
        InitialToken: JsonToken;
    begin
        // [SCENARIO] Workspace.Preview injects initialRequest into _initial
        Initialize();
        CreateArgument(TempArgument, '{"initialRequest": {"customerId": "C001"}}');

        PreviewMsg.ExecuteBifrostTask(TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        Assert.IsTrue(ResponseJson.Get('_initial', InitialToken), 'Missing _initial from initialRequest');
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
}
