namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>Exercises the user-facing plan card and Generate action without granting base-table access.</summary>
codeunit 96466 "Copy Plan Page Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    /// <summary>AC31 CardCreatesMappedPlaybook.</summary>
    [Test]
    procedure AC31_CardCreatesMappedPlaybook()
    var
        Plan: Record "Copy Plan ori";
        Mapping: Record "Copy Plan Field ori";
        Step: Record "Playbook Step ori";
        Assert: Codeunit "Library Assert";
        Lib: Codeunit "Playbook Test Library ori";
        Card: TestPage "Copy Plan Card ori";
        PlanCode: Code[20];
        FieldNo: Integer;
    begin
        // Assumption: a user builds a plan through the card; generation uses the same action as the Web Client.
        PlanCode := CopyStr('X' + DelChr(Format(CreateGuid(), 0, 4), '=', '{}-'), 1, MaxStrLen(PlanCode));
        Card.OpenNew();
        Card.Code.SetValue(PlanCode);
        Card.Description.SetValue('Page-created copy plan');
        Card."Source Table No.".SetValue(Database::"Test Copy Parent ori");
        Card."Destination Table No.".SetValue(Database::"Test Copy Child ori");
        Card.Close();
        for FieldNo := 1 to 3 do begin
            Mapping.Init();
            Mapping."Plan Code" := PlanCode;
            Mapping."Line No." := FieldNo * 10000;
            Mapping.Validate("Source Field No.", FieldNo);
            Mapping.Validate("Destination Field No.", FieldNo);
            Mapping.Insert(true);
        end;
        Plan.Get(PlanCode);
        Card.OpenEdit();
        Card.GoToRecord(Plan);
        Card.GeneratePlaybook.Invoke();
        Card."Generated Playbook Code".AssertEquals(PlanCode);
        Card.Close();
        Step.Get(PlanCode, 10);
        Assert.IsTrue(Step.Paged, 'The UI generates a paged source');
        Step.Get(PlanCode, 20);
        Assert.AreEqual(10, Step."Iterate Source Step No.", 'The UI generates a foreach destination');
        Lib.Cleanup(PlanCode);
        Plan.Get(PlanCode);
        Plan.Delete(true);
    end;
}
