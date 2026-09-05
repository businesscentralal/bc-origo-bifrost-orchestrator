namespace Origo.Bifrost.Nornir.Test;

using Origo.Bifrost.Nornir;
using System.TestTools.TestRunner;

codeunit 96302 "Resolver Test"
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
    procedure StandaloneRefResolvesString()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        JsonHelper: Codeunit "Playbook JSON Helper ori";
        RequestJson: JsonObject;
        Token: JsonToken;
    begin
        Initialize();
        Workspace.Reset();
        Workspace.SetValue('10.name', 'CRONUS Ltd.');
        RequestJson.Add('company', '@10.name');
        JsonHelper.ResolveWorkspaceRefs(RequestJson);
        RequestJson.Get('company', Token);
        Assert.AreEqual('CRONUS Ltd.', Token.AsValue().AsText(), 'Should resolve to string value');
    end;

    [Test]
    procedure StandaloneRefResolvesNumericAsNumber()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        JsonHelper: Codeunit "Playbook JSON Helper ori";
        RequestJson: JsonObject;
        Token: JsonToken;
    begin
        Initialize();
        Workspace.Reset();
        Workspace.SetValue('10.amount', '50280');
        RequestJson.Add('total', '@10.amount');
        JsonHelper.ResolveWorkspaceRefs(RequestJson);
        RequestJson.Get('total', Token);
        Assert.IsTrue(Token.IsValue(), 'Should be a value');
        Assert.AreEqual(50280, Token.AsValue().AsDecimal(), 'Should be numeric 50280');
    end;

    [Test]
    procedure StandaloneRefResolvesObject()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        JsonHelper: Codeunit "Playbook JSON Helper ori";
        RequestJson: JsonObject;
        ChildObj: JsonObject;
        Token: JsonToken;
    begin
        Initialize();
        Workspace.Reset();
        ChildObj.Add('city', 'Reykjavik');
        Workspace.SetToken('20.address', ChildObj.AsToken());
        RequestJson.Add('location', '@20.address');
        JsonHelper.ResolveWorkspaceRefs(RequestJson);
        RequestJson.Get('location', Token);
        Assert.IsTrue(Token.IsObject(), 'Should inject as object');
    end;

    [Test]
    procedure StandaloneRefResolvesArray()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        JsonHelper: Codeunit "Playbook JSON Helper ori";
        RequestJson: JsonObject;
        Arr: JsonArray;
        Token: JsonToken;
    begin
        Initialize();
        Workspace.Reset();
        Arr.Add(1);
        Arr.Add(2);
        Workspace.SetToken('30.items', Arr.AsToken());
        RequestJson.Add('data', '@30.items');
        JsonHelper.ResolveWorkspaceRefs(RequestJson);
        RequestJson.Get('data', Token);
        Assert.IsTrue(Token.IsArray(), 'Should inject as array');
        Assert.AreEqual(2, Token.AsArray().Count(), 'Array should have 2 elements');
    end;

    [Test]
    procedure EmbeddedRefResolvesInString()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        JsonHelper: Codeunit "Playbook JSON Helper ori";
        RequestJson: JsonObject;
        Token: JsonToken;
    begin
        Initialize();
        Workspace.Reset();
        Workspace.SetValue('_initial.id', '103002');
        RequestJson.Add('filter', 'WHERE(No.=CONST(@_initial.id))');
        JsonHelper.ResolveWorkspaceRefs(RequestJson);
        RequestJson.Get('filter', Token);
        Assert.AreEqual('WHERE(No.=CONST(103002))', Token.AsValue().AsText(), 'Should interpolate within string');
    end;

    [Test]
    procedure CollectDirective()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        JsonHelper: Codeunit "Playbook JSON Helper ori";
        RequestJson: JsonObject;
        Token: JsonToken;
    begin
        Initialize();
        Workspace.Reset();
        Workspace.SetValue('25.0.code', 'EA');
        Workspace.SetValue('25.1.code', 'KG');
        RequestJson.Add('lines', '@collect:25');
        JsonHelper.ResolveWorkspaceRefs(RequestJson);
        RequestJson.Get('lines', Token);
        Assert.IsTrue(Token.IsArray(), 'Collect should produce array');
        Assert.AreEqual(2, Token.AsArray().Count(), 'Should have 2 items');
    end;

    [Test]
    procedure FilteredDumpEscapesAsString()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        JsonHelper: Codeunit "Playbook JSON Helper ori";
        RequestJson: JsonObject;
        Token: JsonToken;
    begin
        Initialize();
        Workspace.Reset();
        Workspace.SetValue('10.name', 'A');
        Workspace.SetValue('20.name', 'B');
        Workspace.SetValue('30.name', 'C');
        RequestJson.Add('prompt', '@10,20');
        JsonHelper.ResolveWorkspaceRefs(RequestJson);
        RequestJson.Get('prompt', Token);
        Assert.IsTrue(Token.IsValue(), 'Filtered dump should be a string');
        Assert.IsTrue(Token.AsValue().AsText().Contains('"10"'), 'Should contain key 10');
        Assert.IsTrue(Token.AsValue().AsText().Contains('"20"'), 'Should contain key 20');
        Assert.IsFalse(Token.AsValue().AsText().Contains('"30"'), 'Should not contain key 30');
    end;

    [Test]
    procedure UnresolvedRefStaysIntact()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        JsonHelper: Codeunit "Playbook JSON Helper ori";
        RequestJson: JsonObject;
        Token: JsonToken;
    begin
        Initialize();
        Workspace.Reset();
        RequestJson.Add('value', '@nonexistent.path');
        JsonHelper.ResolveWorkspaceRefs(RequestJson);
        RequestJson.Get('value', Token);
        Assert.AreEqual('@nonexistent.path', Token.AsValue().AsText(), 'Unresolved ref should stay as-is');
    end;

    [Test]
    procedure MultipleRefsInSameTemplate()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        JsonHelper: Codeunit "Playbook JSON Helper ori";
        RequestJson: JsonObject;
        Token: JsonToken;
    begin
        Initialize();
        Workspace.Reset();
        Workspace.SetValue('10.a', 'first');
        Workspace.SetValue('20.b', 'second');
        RequestJson.Add('field1', '@10.a');
        RequestJson.Add('field2', '@20.b');
        RequestJson.Add('static', 'unchanged');
        JsonHelper.ResolveWorkspaceRefs(RequestJson);
        RequestJson.Get('field1', Token);
        Assert.AreEqual('first', Token.AsValue().AsText(), 'field1');
        RequestJson.Get('field2', Token);
        Assert.AreEqual('second', Token.AsValue().AsText(), 'field2');
        RequestJson.Get('static', Token);
        Assert.AreEqual('unchanged', Token.AsValue().AsText(), 'static should be untouched');
    end;
}
