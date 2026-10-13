namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;
using System.Threading;

/// <summary>Checks headless registration and the explicit interactive card flow for issue 10.</summary>
codeunit 96407 "Entry Registration Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        ExpectedEntryId: Guid;

    /// <summary>Fresh headless registration never calls a confirmation or page handler.</summary>
    [Test]
    procedure NewEntryHidesDialogs()
    var
        TempJobQueueEntry: Record "Job Queue Entry" temporary;
        ScheduledEntry: Record "Scheduled Entry ori";
    begin
        CreateSource(TempJobQueueEntry);
        ScheduledEntry.InsertFromJobQueueEntry(TempJobQueueEntry, true);
        Assert.IsTrue(ScheduledEntry.Get(TempJobQueueEntry.ID), 'Headless registration creates the fresh entry');
        Assert.AreEqual(TempJobQueueEntry.Description, ScheduledEntry.Description, 'Description copied');
        ScheduledEntry.Delete(true);
    end;

    /// <summary>Headless repeat registration preserves the existing overwrite behavior.</summary>
    [Test]
    procedure ExistingEntryHidesDialogs()
    var
        TempJobQueueEntry: Record "Job Queue Entry" temporary;
        ScheduledEntry: Record "Scheduled Entry ori";
    begin
        CreateSource(TempJobQueueEntry);
        ScheduledEntry.InsertFromJobQueueEntry(TempJobQueueEntry, true);
        TempJobQueueEntry.Description := 'XUPDATED';
        ScheduledEntry.InsertFromJobQueueEntry(TempJobQueueEntry, true);
        ScheduledEntry.Get(TempJobQueueEntry.ID);
        Assert.AreEqual('XUPDATED', ScheduledEntry.Description, 'Existing entry is refreshed');
        ScheduledEntry.Delete(true);
    end;

    /// <summary>Interactive registration still confirms and opens the created entry.</summary>
    [Test]
    [HandlerFunctions('AcceptOpenCard,VerifyEntryCard')]
    procedure InteractiveEntryOpensCard()
    var
        TempJobQueueEntry: Record "Job Queue Entry" temporary;
        ScheduledEntry: Record "Scheduled Entry ori";
    begin
        CreateSource(TempJobQueueEntry);
        ExpectedEntryId := TempJobQueueEntry.ID;
        ScheduledEntry.InsertFromJobQueueEntry(TempJobQueueEntry, false);
        ScheduledEntry.Get(TempJobQueueEntry.ID);
        ScheduledEntry.Delete(true);
    end;

    /// <summary>Confirms the new-entry question, proving the interactive branch was reached.</summary>
    [ConfirmHandler]
    procedure AcceptOpenCard(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(Question.Contains('created'), 'New entry confirmation');
        Reply := true;
    end;

    /// <summary>Checks that the interactive flow opens the exact disposable entry.</summary>
    [PageHandler]
    procedure VerifyEntryCard(var EntryCard: TestPage "Scheduled Entry Card ori")
    var
        ScheduledEntry: Record "Scheduled Entry ori";
    begin
        ScheduledEntry.Get(ExpectedEntryId);
        Assert.AreEqual(ScheduledEntry.Description, EntryCard.Description.Value(), 'Created entry card');
        EntryCard.Close();
    end;

    local procedure CreateSource(var TempJobQueueEntry: Record "Job Queue Entry" temporary)
    begin
        TempJobQueueEntry.Init();
        TempJobQueueEntry.ID := CreateGuid();
        TempJobQueueEntry."Object Type to Run" := TempJobQueueEntry."Object Type to Run"::Codeunit;
        TempJobQueueEntry."Object ID to Run" := Codeunit::"Ok Sample";
        TempJobQueueEntry.Description := 'XHEADLESS';
        TempJobQueueEntry.Insert();
    end;
}
