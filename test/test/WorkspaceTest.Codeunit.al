namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost.Orchestrator;
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

    // ---------------------------------------------------------------------
    // _sys month boundaries (issue #11). Helpers take an explicit date so
    // SeedSystemConstants (Today) is not required for deterministic coverage.
    // ---------------------------------------------------------------------

    [Test]
    procedure LastMonthEnd_TC001_September31DayMonth()
    begin
        // TC001: 2026-09-10 → lastMonthEnd 2026-08-31
        AssertSysMonthBoundaries(DMY2Date(10, 9, 2026), DMY2Date(1, 8, 2026), DMY2Date(31, 8, 2026), DMY2Date(1, 9, 2026));
    end;

    [Test]
    procedure LastMonthEnd_TC002_LeapYearFebruary()
    begin
        // TC002: 2024-03-01 → lastMonthEnd 2024-02-29
        AssertSysMonthBoundaries(DMY2Date(1, 3, 2024), DMY2Date(1, 2, 2024), DMY2Date(29, 2, 2024), DMY2Date(1, 3, 2024));
    end;

    [Test]
    procedure LastMonthEnd_TC003_JanuaryCrossYear()
    begin
        // TC003: 2026-01-15 → lastMonthEnd 2025-12-31
        AssertSysMonthBoundaries(DMY2Date(15, 1, 2026), DMY2Date(1, 12, 2025), DMY2Date(31, 12, 2025), DMY2Date(1, 1, 2026));
    end;

    [Test]
    procedure LastMonthEnd_TC004_May31ToApril30()
    begin
        // TC004: 2026-05-31 → lastMonthEnd 2026-04-30
        AssertSysMonthBoundaries(DMY2Date(31, 5, 2026), DMY2Date(1, 4, 2026), DMY2Date(30, 4, 2026), DMY2Date(1, 5, 2026));
    end;

    [Test]
    procedure LastMonthStartThisMonthStart_TC005_FormulasUnchanged()
    var
        Workspace: Codeunit "Playbook Workspace ori";
        ReferenceDate: Date;
    begin
        // TC005: lastMonthStart / thisMonthStart still use <-CM-1M> and <-CM>
        Initialize();
        ReferenceDate := DMY2Date(10, 9, 2026);
        Assert.AreEqual(CalcDate('<-CM-1M>', ReferenceDate), Workspace.GetFirstDayOfPreviousMonth(ReferenceDate), 'lastMonthStart formula <-CM-1M>');
        Assert.AreEqual(CalcDate('<-CM>', ReferenceDate), Workspace.GetFirstDayOfThisMonth(ReferenceDate), 'thisMonthStart formula <-CM>');
        ReferenceDate := DMY2Date(1, 3, 2024);
        Assert.AreEqual(CalcDate('<-CM-1M>', ReferenceDate), Workspace.GetFirstDayOfPreviousMonth(ReferenceDate), 'lastMonthStart leap');
        Assert.AreEqual(CalcDate('<-CM>', ReferenceDate), Workspace.GetFirstDayOfThisMonth(ReferenceDate), 'thisMonthStart leap');
        ReferenceDate := DMY2Date(15, 1, 2026);
        Assert.AreEqual(CalcDate('<-CM-1M>', ReferenceDate), Workspace.GetFirstDayOfPreviousMonth(ReferenceDate), 'lastMonthStart Jan');
        Assert.AreEqual(CalcDate('<-CM>', ReferenceDate), Workspace.GetFirstDayOfThisMonth(ReferenceDate), 'thisMonthStart Jan');
        ReferenceDate := DMY2Date(31, 5, 2026);
        Assert.AreEqual(CalcDate('<-CM-1M>', ReferenceDate), Workspace.GetFirstDayOfPreviousMonth(ReferenceDate), 'lastMonthStart May31');
        Assert.AreEqual(CalcDate('<-CM>', ReferenceDate), Workspace.GetFirstDayOfThisMonth(ReferenceDate), 'thisMonthStart May31');
    end;

    local procedure AssertSysMonthBoundaries(ReferenceDate: Date; ExpectedLastMonthStart: Date; ExpectedLastMonthEnd: Date; ExpectedThisMonthStart: Date)
    var
        Workspace: Codeunit "Playbook Workspace ori";
    begin
        Initialize();
        Assert.AreEqual(ExpectedLastMonthEnd, Workspace.GetLastDayOfPreviousMonth(ReferenceDate), 'lastMonthEnd');
        Assert.AreEqual(ExpectedLastMonthStart, Workspace.GetFirstDayOfPreviousMonth(ReferenceDate), 'lastMonthStart');
        Assert.AreEqual(ExpectedThisMonthStart, Workspace.GetFirstDayOfThisMonth(ReferenceDate), 'thisMonthStart');
        // Production formulas for starts (regression): helpers must match CalcDate
        Assert.AreEqual(CalcDate('<-CM-1M>', ReferenceDate), Workspace.GetFirstDayOfPreviousMonth(ReferenceDate), 'lastMonthStart CalcDate');
        Assert.AreEqual(CalcDate('<-CM>', ReferenceDate), Workspace.GetFirstDayOfThisMonth(ReferenceDate), 'thisMonthStart CalcDate');
        Assert.AreEqual(CalcDate('<-CM-1D>', ReferenceDate), Workspace.GetLastDayOfPreviousMonth(ReferenceDate), 'lastMonthEnd CalcDate');
    end;

}
