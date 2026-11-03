namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;

codeunit 96422 "Misc Msg Smoke Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        DispatchHelper: Codeunit "Orch Dispatch Helper ori";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
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
        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] Workspace.Preview returns seeded workspace with _sys namespace
        Initialize();
        CreateArgument(TempArgument, '{}');

        DispatchHelper.Execute("Message Type ori"::"Orchestrator.Workspace.Preview", TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('status', Token);
        Assert.AreEqual('Success', Token.AsValue().AsText(), 'Status should be Success');
        Assert.IsTrue(ResponseJson.Contains('_sys'), 'Missing _sys namespace');
    end;

    [Test]
    procedure WorkspacePreviewPassesThroughInitialRequest()
    var
        TempArgument: Record "Message Argument ori" temporary;
        ResponseJson: JsonObject;
        InitialToken: JsonToken;
    begin
        // [SCENARIO] Workspace.Preview injects initialRequest into _initial
        Initialize();
        CreateArgument(TempArgument, '{"initialRequest": {"customerId": "C001"}}');

        DispatchHelper.Execute("Message Type ori"::"Orchestrator.Workspace.Preview", TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        Assert.IsTrue(ResponseJson.Get('_initial', InitialToken), 'Missing _initial from initialRequest');
    end;

    [Test]
    procedure EveryOrchestratorMessageTypeRefusesAnUnlicensedDirectCall()
    begin
        // [SCENARIO] AssertVersion1 then AssertIsLicensed run before any business work in every Orchestrator message type (#148)
        // [GIVEN] A call that did not come through Foundation's dispatcher is never marked as licensed
        // [WHEN/THEN] Each implementation refuses with the licence error before touching its handler
        Initialize();
        AssertDirectCallRefused("Message Type ori"::"Orchestrator.Entry.Run");
        AssertDirectCallRefused("Message Type ori"::"Orchestrator.Entry.Restart");
        AssertDirectCallRefused("Message Type ori"::"Orchestrator.Status.Get");
        AssertDirectCallRefused("Message Type ori"::"Orchestrator.Status.Restart");
        AssertDirectCallRefused("Message Type ori"::"Orchestrator.Status.RestartIfNeeded");
        AssertDirectCallRefused("Message Type ori"::"Orchestrator.Playbook.Run");
        AssertDirectCallRefused("Message Type ori"::"Orchestrator.JobQueueEntry.Restart");
        AssertDirectCallRefused("Message Type ori"::"Orchestrator.JobQueueEntry.RestartIfNeeded");
        AssertDirectCallRefused("Message Type ori"::"Orchestrator.Playbook.Schedule");
        AssertDirectCallRefused("Message Type ori"::"Orchestrator.Entry.Register");
        AssertDirectCallRefused("Message Type ori"::"Orchestrator.Entry.Schedule");
        AssertDirectCallRefused("Message Type ori"::"Orchestrator.Email.Send");
        AssertDirectCallRefused("Message Type ori"::"Orchestrator.Playbook.Enqueue");
        AssertDirectCallRefused("Message Type ori"::"Orchestrator.Telegram.Message");
        AssertDirectCallRefused("Message Type ori"::"Orchestrator.Report.List");
        AssertDirectCallRefused("Message Type ori"::"Orchestrator.Report.Get");
        AssertDirectCallRefused("Message Type ori"::"Orchestrator.Report.SaveAs");
        AssertDirectCallRefused("Message Type ori"::"Orchestrator.Report.Run");
        AssertDirectCallRefused("Message Type ori"::"Orchestrator.Workspace.Preview");
        AssertDirectCallRefused("Message Type ori"::"Orchestrator.ReportLayout.Set");
        AssertDirectCallRefused("Message Type ori"::"Orchestrator.ReportLayout.List");
        AssertDirectCallRefused("Message Type ori"::"Orchestrator.ReportLayout.Get");
        AssertDirectCallRefused("Message Type ori"::"Orchestrator.Playbook.Verify");
    end;

    local procedure AssertDirectCallRefused(MessageType: Enum "Message Type ori")
    var
        TempArgument: Record "Message Argument ori" temporary;
        Implementation: Interface "Msg Interface ori";
        LicenceErr: Label 'This operation requires a valid license.', Locked = true;
    begin
        CreateArgument(TempArgument, '{}');
        Implementation := MessageType;
        asserterror Implementation.ExecuteBifrostTask(TempArgument);
        Assert.ExpectedError(LicenceErr);
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
