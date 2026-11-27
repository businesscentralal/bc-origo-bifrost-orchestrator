namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>Issue #275: deleting a playbook cascades to its steps, conditions and Transform rows; orphans can be cleaned.</summary>
codeunit 96450 "Playbook Delete Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Lib: Codeunit "Playbook Test Library ori";

    /// <summary>AC01: delete with steps, conditions and transforms removes all children and leaves other playbooks alone.</summary>
    [Test]
    procedure Scenario_AC01_DeleteCascadesAndKeepsOthers()
    var
        Playbook: Record "Playbook ori";
        Step: Record "Playbook Step ori";
        Cond: Record "Playbook Condition ori";
        Transform: Record "Playbook Transform ori";
    begin
        // Story #275 AC01 | Time: independent | Risk: None
        Seed('T275A');
        Seed('T275B');
        Playbook.Get('T275A');
        Playbook.Delete(true);
        Step.SetRange("Playbook Code", 'T275A');
        Assert.RecordIsEmpty(Step);
        Cond.SetRange("Playbook Code", 'T275A');
        Assert.RecordIsEmpty(Cond);
        Transform.SetRange("Playbook Code", 'T275A');
        Assert.RecordIsEmpty(Transform);
        Step.SetRange("Playbook Code", 'T275B');
        Assert.AreEqual(2, Step.Count(), 'other playbook steps untouched');
        Cond.SetRange("Playbook Code", 'T275B');
        Assert.AreEqual(1, Cond.Count(), 'other playbook conditions untouched');
        Transform.SetRange("Playbook Code", 'T275B');
        Assert.AreEqual(1, Transform.Count(), 'other playbook transforms untouched');
        Lib.Cleanup('T275B');
    end;

    /// <summary>AC01: deleting a playbook with no children raises no error.</summary>
    [Test]
    procedure Scenario_AC01_DeleteWithoutChildren()
    var
        Playbook: Record "Playbook ori";
    begin
        Lib.CreatePlaybook('T275C');
        Playbook.Get('T275C');
        Playbook.Delete(true);
        Assert.IsFalse(Playbook.Get('T275C'), 'deleted');
    end;

    /// <summary>AC01: execution history is kept when the playbook is deleted.</summary>
    [Test]
    procedure Scenario_AC01_HistoryIsKept()
    var
        Playbook: Record "Playbook ori";
        Instance: Record "Playbook Instance ori";
        InstanceId: Guid;
    begin
        Lib.CreatePlaybook('T275H');
        Instance.Init();
        Instance.ID := CreateGuid();
        Instance."Playbook Code" := 'T275H';
        Instance.Insert();
        InstanceId := Instance.ID;
        Playbook.Get('T275H');
        Playbook.Delete(true);
        Assert.IsTrue(Instance.Get(InstanceId), 'instance history kept');
        Instance.Delete();
    end;

    /// <summary>AC02: orphan cleanup removes children without header and spares those with one.</summary>
    [Test]
    procedure Scenario_AC02_DeleteOrphanChildren()
    var
        Playbook: Record "Playbook ori";
        Step: Record "Playbook Step ori";
        Cond: Record "Playbook Condition ori";
        Transform: Record "Playbook Transform ori";
        Removed: Integer;
    begin
        // Story #275 AC02
        Seed('T275D');
        Seed('T275E');
        // simulate pre-fix orphans: remove header only
        Playbook.Get('T275D');
        Playbook.Delete(false);
        Removed := Playbook.DeleteOrphanChildren();
        Assert.AreEqual(4, Removed, 'two orphan steps, one condition and one transform are counted');
        Cond.SetRange("Playbook Code", 'T275D');
        Assert.RecordIsEmpty(Cond);
        Transform.SetRange("Playbook Code", 'T275D');
        Assert.RecordIsEmpty(Transform);
        Step.SetRange("Playbook Code", 'T275D');
        Assert.RecordIsEmpty(Step);
        Step.SetRange("Playbook Code", 'T275E');
        Assert.AreEqual(2, Step.Count(), 'playbook with header untouched');
        Assert.AreEqual(0, Playbook.DeleteOrphanChildren(), 'second run finds nothing');
        Lib.Cleanup('T275E');
    end;

    local procedure Seed(PlaybookCode: Code[20])
    var
        Cond: Record "Playbook Condition ori";
        Transform: Record "Playbook Transform ori";
    begin
        Lib.CreatePlaybook(PlaybookCode);
        Lib.AddStep(PlaybookCode, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Orchestrator.Report.Run", '{}', 0, '', 0);
        Lib.AddStep(PlaybookCode, 20, "Playbook Step Type ori"::Action, "Message Type ori"::"Orchestrator.Report.Run", '{}', 0, '', 0);
        Cond.Init();
        Cond."Playbook Code" := PlaybookCode;
        Cond."Step No." := 10;
        Cond."Line No." := 10000;
        Cond.Insert();
        Transform.Init();
        Transform."Playbook Code" := PlaybookCode;
        Transform."Step No." := 10;
        Transform."Line No." := 10000;
        Transform.Insert();
    end;
}
