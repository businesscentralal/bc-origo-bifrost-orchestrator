namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;
using System.Diagnostics;

/// <summary>Copy-plan acceptance: real generated steps, metadata failures, replacement isolation and repeatable execution.</summary>
codeunit 96465 "Copy Plan Generator Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Generator: Codeunit "Copy Plan Generator ori";
        Lib: Codeunit "Playbook Test Library ori";

    /// <summary>AC32 GeneratedPlaybookHasNoErrors.</summary>
    [Test]
    procedure AC32_GeneratedPlaybookHasNoErrors()
    var
        Plan: Record "Copy Plan ori";
        Verify: Codeunit "Playbook Verify ori";
        Findings: JsonArray;
        Finding: JsonToken;
        Severity: JsonToken;
    begin
        // Assumption: Foundation's public Data.Records contracts are enabled in this owned CRONUS test company.
        CreatePlan(Plan);
        Generator.Generate(Plan.Code);
        Verify.GetFindings(Plan.Code, Findings);
        foreach Finding in Findings do begin
            Finding.AsObject().Get('severity', Severity);
            Assert.AreNotEqual('error', Severity.AsValue().AsText().ToLower(), Format(Finding));
        end;
        Cleanup(Plan.Code);
    end;

    /// <summary>AC33 CopyTwicePreservesKeysAndValues.</summary>
    [Test]
    procedure AC33_CopyTwicePreservesKeysAndValues()
    begin
        // Story #155, AC3.3 | Time: independent of Today/WorkDate | Risk: Foundation change-log guards
        RunCopyTwice(false);
    end;

    /// <summary>Runs a generated paged Get/Transform/Set playbook twice, preserving keys and transformed values.</summary>
    [Test]
    procedure Scenario_AC45_TransformedCopyRunsTwice()
    begin
        // Story #155, AC4.5 | Time: independent of Today/WorkDate | Risk: Foundation change-log guards
        RunCopyTwice(true);
    end;

    local procedure RunCopyTwice(TransformAmount: Boolean)
    var
        Plan: Record "Copy Plan ori";
        Parent: Record "Test Copy Parent ori";
        Child: Record "Test Copy Child ori";
        Mapping: Record "Copy Plan Field ori";
        Instance: Record "Playbook Instance ori";
        ChangeLogSetup: Record "Change Log Setup";
        ChangeLogTable: Record "Change Log Setup (Table)";
        Runner: Codeunit "Playbook Runner ori";
        InitialRequest: BigText;
        Response: BigText;
        InstanceId: Guid;
        Attempt: Integer;
        WasActivated: Boolean;
    begin
        // Assumption: the generated playbook uses the production dispatcher, with no test licensing or guard bypass.
        CreatePlan(Plan);
        if TransformAmount then begin
            Mapping.Get(Plan.Code, 30000);
            Mapping.Operation := Mapping.Operation::Negate;
            Mapping.Modify(true);
        end;
        // The happy path has real change-log coverage for this owned scratch table.
        ChangeLogSetup.Get();
        WasActivated := ChangeLogSetup."Change Log Activated";
        ChangeLogSetup."Change Log Activated" := true;
        ChangeLogSetup.Modify(true);
        ChangeLogTable.Init();
        ChangeLogTable."Table No." := Database::"Test Copy Child ori";
        ChangeLogTable."Log Modification" := ChangeLogTable."Log Modification"::"All Fields";
        ChangeLogTable.Insert(true);
        Parent.Code := Plan.Code;
        Parent.Description := 'Copy test';
        Parent.Amount := -123.45;
        Parent.Insert(true);
        Parent.SetRange(Code, Plan.Code);
        Plan."Source View" := CopyStr(Parent.GetView(false), 1, MaxStrLen(Plan."Source View"));
        Plan.Modify(true);
        Generator.Generate(Plan.Code);
        Commit();
        for Attempt := 1 to 2 do begin
            Clear(Response);
            Runner.Run(Plan.Code, InitialRequest, Response, InstanceId);
            Assert.IsTrue(Child.Get(Plan.Code), Format(Response));
            Assert.AreEqual(Parent.Description, Child.Description, 'Mapped description');
            if TransformAmount then
                Assert.AreEqual(-Parent.Amount, Child.Amount, 'Transformed decimal')
            else
                Assert.AreEqual(Parent.Amount, Child.Amount, 'Mapped decimal');
            Instance.Get(InstanceId);
            Assert.AreEqual(Instance.Status::Completed, Instance.Status, 'The full copy run succeeds');
            Child.SetRange(Code, Plan.Code);
            Assert.AreEqual(1, Child.Count(), 'Regenerated key updates the same destination row');
            // Separate public Run invocations have separate transactions. Commit the first run before its repeat.
            Commit();
        end;
        ChangeLogTable.Delete(true);
        ChangeLogSetup."Change Log Activated" := WasActivated;
        ChangeLogSetup.Modify(true);
        Child.DeleteAll(true);
        Parent.DeleteAll(true);
        Cleanup(Plan.Code);
        Commit();
    end;

    /// <summary>AC34 ParentBeforeOrderedChildren.</summary>
    [Test]
    procedure AC34_ParentBeforeOrderedChildren()
    var
        Root: Record "Copy Plan ori";
        FirstChild: Record "Copy Plan ori";
        LastChild: Record "Copy Plan ori";
        Step: Record "Playbook Step ori";
    begin
        // Assumption: child sequence applies only among siblings, and a parent always precedes descendants.
        CreatePlan(Root);
        CreatePlan(LastChild);
        LastChild."Parent Plan Code" := Root.Code;
        LastChild."Sequence No." := 20;
        LastChild.Description := 'last child';
        LastChild.Modify(true);
        CreatePlan(FirstChild);
        FirstChild."Parent Plan Code" := Root.Code;
        FirstChild."Sequence No." := 10;
        FirstChild.Description := 'first child';
        FirstChild.Modify(true);
        Generator.Generate(Root.Code);
        Step.Get(Root.Code, 10);
        Assert.AreEqual(Root.Description, Step.Description, 'Root first');
        Step.Get(Root.Code, 30);
        Assert.AreEqual('first child', Step.Description, 'Lower sequence first');
        Step.Get(Root.Code, 50);
        Assert.AreEqual('last child', Step.Description, 'Higher sequence last');
        Cleanup(FirstChild.Code);
        Cleanup(LastChild.Code);
        Cleanup(Root.Code);
    end;

    /// <summary>AC36 RegenerationPreservesUnrelatedPlaybook.</summary>
    [Test]
    procedure AC36_RegenerationPreservesUnrelatedPlaybook()
    var
        Plan: Record "Copy Plan ori";
        Other: Record "Copy Plan ori";
        Step: Record "Playbook Step ori";
    begin
        // Assumption: regeneration may replace only the explicitly recorded generated playbook.
        CreatePlan(Plan);
        CreatePlan(Other);
        Generator.Generate(Plan.Code);
        Generator.Generate(Other.Code);
        Generator.Generate(Plan.Code);
        Step.SetRange("Playbook Code", Plan.Code);
        Assert.AreEqual(2, Step.Count(), 'Generated steps replaced, not appended');
        Step.Get(Other.Code, 10);
        Assert.AreEqual(Other.Description, Step.Description, 'Unrelated playbook unchanged');
        Cleanup(Plan.Code);
        Cleanup(Other.Code);
    end;

    /// <summary>AC36 ExistingUnrelatedCodeIsRefused.</summary>
    [Test]
    procedure AC36_ExistingUnrelatedCodeIsRefused()
    var
        Plan: Record "Copy Plan ori";
        Playbook: Record "Playbook ori";
    begin
        // Assumption: a new plan cannot acquire an existing playbook merely by sharing its code.
        CreatePlan(Plan);
        Lib.CreatePlaybook(Plan.Code);
        Commit();
        asserterror Generator.Generate(Plan.Code);
        Assert.ExpectedError('already exists');
        Playbook.Get(Plan.Code);
        Assert.AreEqual('Test playbook', Playbook.Description, 'No takeover');
        Cleanup(Plan.Code);
    end;

    /// <summary>AC31 InvalidFieldRefusedAtGeneration.</summary>
    [Test]
    procedure AC31_InvalidFieldRefusedAtGeneration()
    var
        Plan: Record "Copy Plan ori";
        Mapping: Record "Copy Plan Field ori";
    begin
        // Assumption: data entered outside the page must be revalidated at generation.
        CreatePlan(Plan);
        Mapping.Get(Plan.Code, 20000);
        Mapping."Source Field No." := 999999;
        Mapping.Modify(true);
        asserterror Generator.Generate(Plan.Code);
        Assert.ExpectedError('does not exist');
        Cleanup(Plan.Code);
    end;

    /// <summary>AC31 DuplicateDestinationRefused.</summary>
    [Test]
    procedure AC31_DuplicateDestinationRefused()
    var
        Plan: Record "Copy Plan ori";
        Mapping: Record "Copy Plan Field ori";
    begin
        // Assumption: multiple mappings cannot silently overwrite one destination property.
        CreatePlan(Plan);
        Mapping.Get(Plan.Code, 30000);
        Mapping."Destination Field No." := 2;
        Mapping.Modify(true);
        asserterror Generator.Generate(Plan.Code);
        Assert.ExpectedError('mapped more than once');
        Cleanup(Plan.Code);
    end;

    /// <summary>AC31 SkippedKeyCannotCreateUnnamedRows.</summary>
    [Test]
    procedure AC31_SkippedKeyCannotCreateUnnamedRows()
    var
        Plan: Record "Copy Plan ori";
        Mapping: Record "Copy Plan Field ori";
    begin
        // Assumption: destination keys must be explicitly mapped; source SystemId is never copied.
        CreatePlan(Plan);
        Mapping.Get(Plan.Code, 10000);
        Mapping.Skip := true;
        Mapping.Modify(true);
        asserterror Generator.Generate(Plan.Code);
        Assert.ExpectedError('primary-key');
        Cleanup(Plan.Code);
    end;

    /// <summary>AC35 Foundation refusals remain visible in the generated playbook's run and step log.</summary>
    [Test]
    procedure AC35_RestrictedSourceFailsVisibly()
    var
        Plan: Record "Copy Plan ori";
        Mapping: Record "Copy Plan Field ori";
        Instance: Record "Playbook Instance ori";
        StepLog: Record "Playbook Step Log ori";
        Runner: Codeunit "Playbook Runner ori";
        InitialRequest: BigText;
        Response: BigText;
        InstanceId: Guid;
    begin
        // Assumption: User is Foundation-restricted even for a SUPER user; no permissions are elevated here.
        CreatePlan(Plan);
        Plan."Source Table No." := 2000000120;
        Plan.Modify(true);
        Mapping.SetRange("Plan Code", Plan.Code);
        Mapping.SetFilter("Line No.", '>%1', 10000);
        Mapping.DeleteAll(true);
        Generator.Generate(Plan.Code);
        Commit();
        Runner.Run(Plan.Code, InitialRequest, Response, InstanceId);
        Instance.Get(InstanceId);
        Assert.AreEqual(Instance.Status::Failed, Instance.Status, 'Restricted read fails the run');
        StepLog.SetRange("Instance ID", InstanceId);
        StepLog.SetRange(Status, StepLog.Status::Failed);
        Assert.IsFalse(StepLog.IsEmpty(), 'The refusal is recorded in the step log');
        Cleanup(Plan.Code);
        Commit();
    end;

    /// <summary>AC35 A destination without change-log coverage refuses the copy and leaves no row.</summary>
    [Test]
    procedure AC35_UncoveredDestinationFailsVisibly()
    var
        Plan: Record "Copy Plan ori";
        Parent: Record "Test Copy Parent ori";
        Child: Record "Test Copy Child ori";
        Instance: Record "Playbook Instance ori";
        StepLog: Record "Playbook Step Log ori";
        Coverage: Record "Change Log Setup (Table)";
        Runner: Codeunit "Playbook Runner ori";
        InitialRequest: BigText;
        Response: BigText;
        InstanceId: Guid;
    begin
        // Assumption: this owned scratch table has no configured coverage; the production guard remains enabled.
        Assert.IsFalse(Coverage.Get(Database::"Test Copy Parent ori"), 'This negative fixture destination has never been given coverage');
        CreatePlan(Plan);
        Plan."Source Table No." := Database::"Test Copy Child ori";
        Plan."Destination Table No." := Database::"Test Copy Parent ori";
        Child.Code := Plan.Code;
        Child.Description := 'Must not be copied';
        Child.Insert(true);
        Child.SetRange(Code, Plan.Code);
        Plan."Source View" := CopyStr(Child.GetView(false), 1, MaxStrLen(Plan."Source View"));
        Plan.Modify(true);
        Generator.Generate(Plan.Code);
        Commit();
        Runner.Run(Plan.Code, InitialRequest, Response, InstanceId);
        Instance.Get(InstanceId);
        Assert.AreEqual(Instance.Status::Failed, Instance.Status, 'The uncovered write fails the run');
        Assert.IsFalse(Parent.Get(Plan.Code), 'Refused destination remains absent');
        StepLog.SetRange("Instance ID", InstanceId);
        StepLog.SetRange("Step No.", 20);
        StepLog.SetRange(Status, StepLog.Status::Failed);
        Assert.IsTrue(StepLog.FindFirst(), 'The refusal is recorded in the step log');
        Assert.IsTrue(StepLog.GetResponseReceived().Contains('BlockedByWriteGuard'), 'The actual Foundation refusal is retained');
        Child.DeleteAll(true);
        Cleanup(Plan.Code);
        Commit();
    end;

    local procedure CreatePlan(var Plan: Record "Copy Plan ori")
    var
        Mapping: Record "Copy Plan Field ori";
        FieldNo: Integer;
    begin
        Clear(Plan);
        Plan.Init();
        Plan.Code := CopyStr('X' + DelChr(Format(CreateGuid(), 0, 4), '=', '{}-'), 1, MaxStrLen(Plan.Code));
        Plan.Description := 'Owned copy fixture';
        Plan."Source Table No." := Database::"Test Copy Parent ori";
        Plan."Destination Table No." := Database::"Test Copy Child ori";
        Plan."Page Size" := 1;
        Plan.Insert(true);
        for FieldNo := 1 to 3 do begin
            Mapping.Init();
            Mapping."Plan Code" := Plan.Code;
            Mapping."Line No." := FieldNo * 10000;
            Mapping.Validate("Source Field No.", FieldNo);
            Mapping.Validate("Destination Field No.", FieldNo);
            Mapping.Insert(true);
        end;
    end;

    local procedure Cleanup(PlanCode: Code[20])
    var
        Plan: Record "Copy Plan ori";
    begin
        Lib.Cleanup(PlanCode);
        if Plan.Get(PlanCode) then
            Plan.Delete(true);
    end;
}
