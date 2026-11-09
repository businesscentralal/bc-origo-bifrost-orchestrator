namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.Diagnostics;
using System.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>Story #155 Phase 2 (AC2.1 to AC2.3): paging, view, restricted table and editing through "Table Data Mgt ori".</summary>
codeunit 96426 "Table Data Mgt Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        TableDataMgt: Codeunit "Table Data Mgt ori";
        WasActivated: Boolean;
        CoverageAdded: Boolean;

    /// <summary>AC2.1: 120 rows are read 50 at a time; the third page has 20 rows and no further page.</summary>
    [Test]
    procedure AC21_PagesFiftyRowsAtATime()
    var
        TempRow: Record "Table Data Row ori" temporary;
        View: Text;
    begin
        // [GIVEN] 120 owned markers
        DeleteMarkers();
        InsertMarkers(120);
        View := OwnedView();
        // [WHEN/THEN] Pages 1 and 2 hold 50 rows with a further page; page 3 holds 20 and is the last
        Assert.IsTrue(TableDataMgt.LoadPage(Database::"Test Run Marker", View, 1, 50, TempRow), 'Page 1 has a next page');
        Assert.AreEqual(50, TempRow.Count(), 'Page 1 rows');
        Assert.IsTrue(TableDataMgt.LoadPage(Database::"Test Run Marker", View, 2, 50, TempRow), 'Page 2 has a next page');
        Assert.AreEqual(50, TempRow.Count(), 'Page 2 rows');
        Assert.IsFalse(TableDataMgt.LoadPage(Database::"Test Run Marker", View, 3, 50, TempRow), 'Page 3 is the last');
        Assert.AreEqual(20, TempRow.Count(), 'Page 3 rows');
        Assert.IsFalse(TableDataMgt.LoadPage(Database::"Test Run Marker", View, 4, 50, TempRow), 'Past the end');
        Assert.AreEqual(0, TempRow.Count(), 'No rows past the end');
        DeleteMarkers();
    end;

    /// <summary>AC2.1: the table view filters the rows and each row shows its key and a summary.</summary>
    [Test]
    procedure AC21_ViewFiltersAndRowShowsSummary()
    var
        Marker: Record "Test Run Marker";
        TempRow: Record "Table Data Row ori" temporary;
    begin
        // [GIVEN] Owned markers TJD-A and TJD-B
        DeleteMarkers();
        InsertMarker('TJD-A');
        InsertMarker('TJD-B');
        Marker.SetRange(Source, 'TJD-B');
        // [WHEN] A page is loaded with a view on TJD-B
        TableDataMgt.LoadPage(Database::"Test Run Marker", Marker.GetView(false), 1, 50, TempRow);
        // [THEN] Only that row is shown with its SystemId, key and summary
        Assert.AreEqual(1, TempRow.Count(), 'The view filters');
        TempRow.FindFirst();
        Marker.FindFirst();
        Assert.AreEqual(Marker.SystemId, TempRow."Record SystemId", 'SystemId');
        Assert.AreEqual(Format(Marker."Entry No."), TempRow."Primary Key", 'Primary key');
        Assert.IsTrue(TempRow.Summary.Contains('Source=TJD-B'), 'Summary shows Name=Value');
        DeleteMarkers();
    end;

    /// <summary>AC2.2: a restricted table is refused when it is opened.</summary>
    [Test]
    procedure AC22_RestrictedTableIsRefused()
    var
        TempRow: Record "Table Data Row ori" temporary;
    begin
        asserterror TableDataMgt.LoadPage(Database::User, '', 1, 50, TempRow);
        Assert.ExpectedError('cannot be read by the table data export');
    end;

    /// <summary>AC2.3: one field is edited through the serializer and Modify(true).</summary>
    [Test]
    procedure AC23_EditFieldIsSaved()
    var
        Marker: Record "Test Run Marker";
        TempField: Record "Table Data Field ori" temporary;
    begin
        // [GIVEN] An owned marker and change log coverage for its table
        Setup();
        InsertMarker('TJD-OLD');
        Marker.SetRange(Source, 'TJD-OLD');
        Marker.FindFirst();
        TableDataMgt.LoadRecord(Database::"Test Run Marker", Marker.SystemId, TempField);
        Assert.IsTrue(TempField.Get(Marker.FieldNo(Source)), 'Source is shown');
        Assert.IsTrue(TempField.Get(Marker.FieldNo("Entry No.")), 'The key is shown');
        Assert.IsTrue(TempField."Part of Primary Key", 'Entry No. is part of the key');
        // [WHEN] Source is saved with a new value
        TableDataMgt.SaveField(Database::"Test Run Marker", Marker.SystemId, Marker.FieldNo(Source), 'TJD-NEW');
        // [THEN] The record holds the new value
        Marker.Get(Marker."Entry No.");
        Assert.AreEqual('TJD-NEW', Marker.Source, 'The new value is saved');
        TearDown();
    end;

    /// <summary>AC2.3: an invalid value shows the serializer's error and leaves the record unchanged; the key cannot be edited.</summary>
    [Test]
    procedure AC23_InvalidValueAndKeyAreRefused()
    var
        Marker: Record "Test Run Marker";
    begin
        // [GIVEN] An owned marker
        Setup();
        InsertMarker('TJD-KEEP');
        Marker.SetRange(Source, 'TJD-KEEP');
        Marker.FindFirst();
        // [WHEN] A text longer than the field is saved
        asserterror TableDataMgt.SaveField(Database::"Test Run Marker", Marker.SystemId, Marker.FieldNo(Source), PadStr('TJD-', 60, 'X'));
        // [THEN] It is refused and the record is unchanged
        Assert.AreNotEqual('', GetLastErrorText(), 'The serializer error is shown');
        Marker.Get(Marker."Entry No.");
        Assert.AreEqual('TJD-KEEP', Marker.Source, 'Unchanged');
        // [WHEN] The primary key is saved
        asserterror TableDataMgt.SaveField(Database::"Test Run Marker", Marker.SystemId, Marker.FieldNo("Entry No."), '999999');
        // [THEN] It is refused
        Assert.ExpectedError('is part of the primary key');
        TearDown();
    end;

    /// <summary>The JSON key follows the serializer naming.</summary>
    [Test]
    procedure JsonKeyFollowsSerializerNaming()
    begin
        Assert.AreEqual('No_', TableDataMgt.GetJsonKey('No.'), 'No.');
        Assert.AreEqual('CreditLimitLCY', TableDataMgt.GetJsonKey('Credit Limit (LCY)'), 'Credit Limit (LCY)');
        Assert.AreEqual('EntryNo_', TableDataMgt.GetJsonKey('Entry No.'), 'Entry No.');
    end;

    local procedure Setup()
    var
        ChangeLogSetup: Record "Change Log Setup";
        Coverage: Record "Change Log Setup (Table)";
    begin
        DeleteMarkers();
        if not ChangeLogSetup.Get() then begin
            ChangeLogSetup.Init();
            ChangeLogSetup.Insert(true);
        end;
        WasActivated := ChangeLogSetup."Change Log Activated";
        ChangeLogSetup."Change Log Activated" := true;
        ChangeLogSetup.Modify(true);
        CoverageAdded := not Coverage.Get(Database::"Test Run Marker");
        if CoverageAdded then begin
            Coverage."Table No." := Database::"Test Run Marker";
            Coverage."Log Insertion" := Coverage."Log Insertion"::"All Fields";
            Coverage."Log Modification" := Coverage."Log Modification"::"All Fields";
            Coverage.Insert(true);
        end;
    end;

    local procedure TearDown()
    var
        ChangeLogSetup: Record "Change Log Setup";
        Coverage: Record "Change Log Setup (Table)";
    begin
        DeleteMarkers();
        if CoverageAdded then
            if Coverage.Get(Database::"Test Run Marker") then
                Coverage.Delete(true);
        ChangeLogSetup.Get();
        ChangeLogSetup."Change Log Activated" := WasActivated;
        ChangeLogSetup.Modify(true);
    end;

    local procedure OwnedView(): Text
    var
        Marker: Record "Test Run Marker";
    begin
        Marker.SetFilter(Source, 'TJD-*');
        exit(Marker.GetView(false));
    end;

    local procedure InsertMarkers(Count: Integer)
    var
        Index: Integer;
    begin
        for Index := 1 to Count do
            InsertMarker(CopyStr('TJD-' + Format(Index), 1, 50));
    end;

    local procedure InsertMarker(Source: Text[50])
    var
        Marker: Record "Test Run Marker";
    begin
        Marker.Init();
        Marker.Source := Source;
        Marker.Insert(true);
    end;

    local procedure DeleteMarkers()
    var
        Marker: Record "Test Run Marker";
    begin
        Marker.SetFilter(Source, 'TJD*');
        Marker.DeleteAll(true);
    end;
}
