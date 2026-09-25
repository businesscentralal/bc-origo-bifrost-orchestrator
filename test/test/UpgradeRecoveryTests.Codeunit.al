namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>
/// Permitted path for the deferred upgrade: a blank Object Type to Run becomes Codeunit.
/// Legacy key cleanup is a no-op once the dropped columns are gone; this test still calls it.
/// </summary>
codeunit 96430 "Upgrade Recovery Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        GuardDescriptionTok: Label 'UPG-GUARD', Locked = true;

    [Test]
    procedure DeferredUpgrade_WithPermission_SetsBlankObjectTypeToCodeunit()
    var
        ScheduledEntry: Record "Scheduled Entry ori";
        DeferredUpgrade: Codeunit "Deferred Upgrade ori";
        EntryId: Guid;
    begin
        // [GIVEN] a scheduled entry whose object type is the blank option (ordinal 0)
        DeleteGuardEntries();
        EntryId := CreateBlankObjectTypeEntry();
        ScheduledEntry.Get(EntryId);
        Assert.AreNotEqual(ScheduledEntry."Object Type to Run"::Codeunit, ScheduledEntry."Object Type to Run", 'The fixture must not already be a codeunit.');
        Assert.AreNotEqual(ScheduledEntry."Object Type to Run"::Report, ScheduledEntry."Object Type to Run", 'The fixture must be the blank object type, not Report.');

        // [WHEN] the same procedure upgrade and Scheduler Setup call runs with permission
        DeferredUpgrade.EnsureDeferredUpgradeData();

        // [THEN] the blank type is Codeunit, and running it again does not error
        ScheduledEntry.Get(EntryId);
        Assert.AreEqual(ScheduledEntry."Object Type to Run"::Codeunit, ScheduledEntry."Object Type to Run", 'A blank Object Type to Run must become Codeunit.');
        DeferredUpgrade.EnsureDeferredUpgradeData();
        ScheduledEntry.Get(EntryId);
        Assert.AreEqual(ScheduledEntry."Object Type to Run"::Codeunit, ScheduledEntry."Object Type to Run", 'The deferred upgrade must be idempotent.');

        ScheduledEntry.Delete();
    end;

    local procedure CreateBlankObjectTypeEntry() EntryId: Guid
    var
        ScheduledEntry: Record "Scheduled Entry ori";
        RecRef: RecordRef;
        ObjectTypeField: FieldRef;
    begin
        EntryId := CreateGuid();
        ScheduledEntry.Init();
        ScheduledEntry.ID := EntryId;
        ScheduledEntry.Description := GuardDescriptionTok;
        ScheduledEntry.Insert();

        RecRef.GetTable(ScheduledEntry);
        ObjectTypeField := RecRef.Field(ScheduledEntry.FieldNo("Object Type to Run"));
        ObjectTypeField.Value(0);
        RecRef.Modify();
    end;

    local procedure DeleteGuardEntries()
    var
        ScheduledEntry: Record "Scheduled Entry ori";
    begin
        ScheduledEntry.SetRange(Description, GuardDescriptionTok);
        if not ScheduledEntry.IsEmpty() then
            ScheduledEntry.DeleteAll();
    end;
}
