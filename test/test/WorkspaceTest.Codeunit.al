namespace Origo.Bifrost.Nornir.Test;

using Origo.Bifrost.Nornir;
using System.TestTools.TestRunner;

codeunit 96401 "Workspace Test"
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
    procedure SetValueAndGetValue()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        Result: Text;
    begin
        Initialize();
        Workspace.Reset();
        Workspace.SetValue('name', 'hello');
        Assert.IsTrue(Workspace.GetValue('name', Result), 'GetValue should return true');
        Assert.AreEqual('hello', Result, 'Value mismatch');
    end;

    [Test]
    procedure SetTokenAtNestedPath()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        JValue: JsonValue;
        Result: Text;
    begin
        Initialize();
        Workspace.Reset();
        JValue.SetValue('test-value');
        Workspace.SetToken('a.b.c', JValue.AsToken());
        Assert.IsTrue(Workspace.GetValue('a.b.c', Result), 'Nested path should resolve');
        Assert.AreEqual('test-value', Result, 'Nested value mismatch');
    end;

    [Test]
    procedure SetTokenPreservesArray()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        Arr: JsonArray;
        Token: JsonToken;
    begin
        Initialize();
        Workspace.Reset();
        Arr.Add('one');
        Arr.Add('two');
        Workspace.SetToken('items', Arr.AsToken());
        Assert.IsTrue(Workspace.GetToken('items', Token), 'Should get token');
        Assert.IsTrue(Token.IsArray(), 'Token should be array');
        Assert.AreEqual(2, Token.AsArray().Count(), 'Array should have 2 elements');
    end;

    [Test]
    procedure WriteFromResponseWithRename()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        Result: Text;
    begin
        Initialize();
        Workspace.Reset();
        Workspace.WriteFromResponse(10, 0, false,
            '{"result":[{"name":"A"}],"count":1}',
            'result>data,count>total');
        Assert.IsTrue(Workspace.GetValue('10.data', Result), 'Should have 10.data');
        Assert.IsTrue(Workspace.GetValue('10.total', Result), 'Should have 10.total');
        Assert.AreEqual('1', Result, 'Total should be 1');
    end;

    [Test]
    procedure WriteFromResponseIteratedKeying()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        Result: Text;
    begin
        Initialize();
        Workspace.Reset();
        Workspace.WriteFromResponse(20, 0, true, '{"valid":true}', 'valid');
        Workspace.WriteFromResponse(20, 1, true, '{"valid":false}', 'valid');
        Assert.IsTrue(Workspace.GetValue('20.0.valid', Result), 'Iteration 0');
        Assert.AreEqual('true', Result, 'First should be true');
        Assert.IsTrue(Workspace.GetValue('20.1.valid', Result), 'Iteration 1');
        Assert.AreEqual('false', Result, 'Second should be false');
    end;

    [Test]
    procedure WriteFromResponseFirstElement()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        Token: JsonToken;
    begin
        Initialize();
        Workspace.Reset();
        Workspace.WriteFromResponse(10, 0, false,
            '{"result":[{"id":"rec1","fields":{"Name":"Test"}}]}',
            'result[0]>record');
        Assert.IsTrue(Workspace.GetToken('10.record', Token), 'Should have 10.record');
        Assert.IsTrue(Token.IsObject(), 'Should be object, not array');
    end;

    [Test]
    procedure CollectGathersIterations()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        Arr: JsonArray;
    begin
        Initialize();
        Workspace.Reset();
        Workspace.WriteFromResponse(30, 0, true, '{"code":"EA"}', 'code');
        Workspace.WriteFromResponse(30, 1, true, '{"code":"KG"}', 'code');
        Workspace.WriteFromResponse(30, 2, true, '{"code":"HR"}', 'code');
        Assert.IsTrue(Workspace.Collect('30', Arr), 'Collect should succeed');
        Assert.AreEqual(3, Arr.Count(), 'Should have 3 items');
    end;

    [Test]
    procedure ToFilteredTextOnlyIncludesRequestedKeys()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        Filtered: Text;
    begin
        Initialize();
        Workspace.Reset();
        Workspace.SetValue('a', '1');
        Workspace.SetValue('b', '2');
        Workspace.SetValue('c', '3');
        Filtered := Workspace.ToFilteredText('a,c');
        Assert.IsTrue(Filtered.Contains('"a"'), 'Should contain key a');
        Assert.IsTrue(Filtered.Contains('"c"'), 'Should contain key c');
        Assert.IsFalse(Filtered.Contains('"b"'), 'Should not contain key b');
    end;

    [Test]
    procedure ResetClearsAllData()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        Result: Text;
    begin
        Initialize();
        Workspace.Reset();
        Workspace.SetValue('keep', 'data');
        Initialize();
        Workspace.Reset();
        Assert.IsFalse(Workspace.GetValue('keep', Result), 'Data should be cleared after Reset');
    end;
}
