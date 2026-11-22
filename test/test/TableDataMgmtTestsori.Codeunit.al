namespace Origo.Bifrost.Orchestrator.Test;

using Microsoft.Utilities;
using Origo.Bifrost.Orchestrator;
using System.Diagnostics;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;
using System.Utilities;

/// <summary>
/// Story #261 (Table Data Management port of Tools for Power Users): the original JSON file shape both ways (AC03), Excel
/// export and import (AC04), the Foundation guards on edit, delete and import (AC05) and the access gating (AC06).
/// </summary>
codeunit 96449 "Table Data Mgmt Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        WasActivated: Boolean;
        CoverageAdded: Boolean;
        ChildCoverageAdded: Boolean;

    /// <summary>AC03: an export has the original shape, { "TableName": [ { RecordSystemId, PrimaryKeyFields, Fields } ] }.</summary>
    [Test]
    procedure AC03_ExportUsesOriginalFileShape()
    var
        TempFilter: Record "Table Data Edit ori" temporary;
        JsonMgt: Codeunit "Table Data JSON Mgt ori";
        Rows: JsonArray;
        Row: JsonObject;
        Token: JsonToken;
    begin
        Setup();
        InsertMarker('TJD-A');
        Rows := JsonMgt.ExportRows(Database::"Test Run Marker", false, '', TempFilter);
        Assert.AreEqual('TestRunMarker', JsonMgt.GetFileKey(Database::"Test Run Marker"), 'File key');
        Assert.AreEqual(1, Rows.Count(), 'One row');
        Rows.Get(0, Token);
        Row := Token.AsObject();
        Assert.IsTrue(Row.Contains('RecordSystemId'), 'RecordSystemId');
        Assert.IsTrue(Row.Contains('PrimaryKeyFields'), 'PrimaryKeyFields');
        Assert.IsTrue(Row.Contains('Fields'), 'Fields');
        Assert.IsFalse(Row.Contains('CreatedAt'), 'No audit fields without Show Audit Fields');
        Assert.IsTrue(Row.AsToken().AsObject().SelectToken('Fields.Source', Token), 'Source field');
        Assert.AreEqual('TJD-A', Token.AsValue().AsText(), 'Source value');
        Rows := JsonMgt.ExportRows(Database::"Test Run Marker", true, '', TempFilter);
        Rows.Get(0, Token);
        Assert.IsTrue(Token.AsObject().Contains('ModifiedAt'), 'Audit fields with Show Audit Fields');
        TearDown();
    end;

    /// <summary>AC03: a file in the original's format (fixture) imports, and the Orchestrator export imports back after a delete.</summary>
    [Test]
    procedure AC03_OriginalFixtureAndRoundTripImport()
    var
        TempFilter: Record "Table Data Edit ori" temporary;
        Child: Record "Test Copy Child ori";
        JsonMgt: Codeunit "Table Data JSON Mgt ori";
        Source: JsonObject;
        Rows: JsonArray;
        Inserted: Integer;
        Modified: Integer;
        Failed: Integer;
    begin
        Setup();
        // [GIVEN] A file as the original tool writes it
        Source.ReadFrom(FixtureText());
        // [WHEN] It is imported
        Assert.IsTrue(JsonMgt.ImportRows(Database::"Test Copy Child ori", Source, Inserted, Modified, Failed), 'The file holds the table');
        // [THEN] The record is inserted
        Assert.AreEqual(1, Inserted, 'Inserted');
        Assert.AreEqual(0, Failed, 'Failed');
        Child.Get('TJD-FIXTURE');
        Assert.AreEqual(12, Child.Amount, 'Fixture value');
        // [WHEN] The file is imported again with a changed value, the record is modified
        Source.ReadFrom(FixtureText().Replace(':12', ':15'));
        JsonMgt.ImportRows(Database::"Test Copy Child ori", Source, Inserted, Modified, Failed);
        Assert.AreEqual(1, Modified, 'Modified');
        Child.Get('TJD-FIXTURE');
        Assert.AreEqual(15, Child.Amount, 'Changed value');
        // [WHEN] Our own export is written back after the record was deleted
        Rows := JsonMgt.ExportRows(Database::"Test Copy Child ori", false, '', TempFilter);
        Clear(Source);
        Source.Add(JsonMgt.GetFileKey(Database::"Test Copy Child ori"), Rows);
        Child.Delete(true);
        JsonMgt.ImportRows(Database::"Test Copy Child ori", Source, Inserted, Modified, Failed);
        // [THEN] It is recreated
        Assert.AreEqual(1, Inserted, 'Re-inserted');
        Assert.IsTrue(Child.Get('TJD-FIXTURE'), 'Round trip');
        Child.Delete(true);
        TearDown();
    end;

    /// <summary>AC04: a table exported to Excel imports again through the preview-less path.</summary>
    [Test]
    procedure AC04_ExcelExportAndImport()
    var
        TempFilter: Record "Table Data Edit ori" temporary;
        Marker: Record "Test Run Marker";
        ExcelExport: Codeunit "Table Data Excel Export ori";
        ExcelImport: Codeunit "Table Data Excel Import ori";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        Inserted: Integer;
        Modified: Integer;
        Failed: Integer;
    begin
        Setup();
        InsertMarker('TJD-XLS');
        ExcelExport.BuildWorkbook(Database::"Test Run Marker", false, '', TempFilter, TempBlob, false);
        Assert.IsTrue(TempBlob.HasValue(), 'A workbook is written');
        Marker.SetRange(Source, 'TJD-XLS');
        Marker.FindFirst();
        Marker.Delete();
        TempBlob.CreateInStream(InStr);
        ExcelImport.ImportStream(Database::"Test Run Marker", 'Marker', InStr, false, Inserted, Modified, Failed);
        Assert.AreEqual(1, Inserted, 'Inserted from Excel');
        Assert.AreEqual(0, Failed, 'No refused rows');
        Marker.Reset();
        Marker.SetRange(Source, 'TJD-XLS');
        Assert.AreEqual(1, Marker.Count(), 'The row is back');
        TearDown();
    end;

    /// <summary>AC05: a write-restricted table refuses a cell save, a delete and a JSON or Excel import; nothing is written.</summary>
    [Test]
    procedure AC05_WriteRestrictedTableRefusesEveryWrite()
    var
        TempFilter: Record "Table Data Edit ori" temporary;
        Marker: Record "Test Run Marker";
        EditMgt: Codeunit "Table Data Edit Mgt ori";
        JsonMgt: Codeunit "Table Data JSON Mgt ori";
        ExcelExport: Codeunit "Table Data Excel Export ori";
        ExcelImport: Codeunit "Table Data Excel Import ori";
        Restrictions: Codeunit "Library Orchestrator";
        TempBlob: Codeunit "Temp Blob";
        Source: JsonObject;
        InStr: InStream;
        Inserted: Integer;
        Modified: Integer;
        Failed: Integer;
    begin
        Setup();
        InsertMarker('TJD-GUARD');
        Marker.SetRange(Source, 'TJD-GUARD');
        Marker.FindFirst();
        ExcelExport.BuildWorkbook(Database::"Test Run Marker", false, '', TempFilter, TempBlob, false);
        Commit();
        Restrictions.SetTableDataRestrictions(false, true);
        BindSubscription(Restrictions);
        Assert.IsFalse(EditMgt.CheckIfWritePermissionsExistForTheUser(Database::"Test Run Marker"), 'Edit is disabled');
        asserterror EditMgt.SaveCell(Database::"Test Run Marker", Marker.SystemId, Marker.FieldNo(Source), 'TJD-CHANGED');
        Assert.ExpectedError('cannot be written by the table data import');
        asserterror EditMgt.DeleteRecord(Database::"Test Run Marker", Marker.SystemId);
        Assert.ExpectedError('cannot be written by the table data import');
        Source.ReadFrom(MarkerFixtureText());
        asserterror JsonMgt.ImportRows(Database::"Test Run Marker", Source, Inserted, Modified, Failed);
        Assert.ExpectedError('cannot be written by the table data import');
        TempBlob.CreateInStream(InStr);
        asserterror ExcelImport.ImportStream(Database::"Test Run Marker", 'Marker', InStr, false, Inserted, Modified, Failed);
        Assert.ExpectedError('cannot be written by the table data import');
        UnbindSubscription(Restrictions);
        Marker.Get(Marker."Entry No.");
        Assert.AreEqual('TJD-GUARD', Marker.Source, 'The record is unchanged');
        Assert.IsFalse(Marker.Get(9001), 'The imported row was not written');
        TearDown();
        Commit();
    end;

    /// <summary>AC05: a read-restricted field is blank in the grid and refused as a save.</summary>
    [Test]
    procedure AC05_ReadRestrictedFieldIsBlankInGrid()
    var
        Marker: Record "Test Run Marker";
        TempEdit: Record "Table Data Edit ori" temporary;
        EditMgt: Codeunit "Table Data Edit Mgt ori";
        Restrictions: Codeunit "Library Orchestrator";
        CellData: array[1000] of Text[250];
        ColumnField: array[1000] of Integer;
        Ordinal: Integer;
        Index: Integer;
    begin
        Setup();
        InsertMarker('TJD-HIDDEN');
        Marker.SetRange(Source, 'TJD-HIDDEN');
        Marker.FindFirst();
        TempEdit."Table ID" := Database::"Test Run Marker";
        TempEdit."Entry No." := 1;
        TempEdit."Record System Id" := Marker.SystemId;
        TempEdit.Insert();
        Restrictions.SetTableDataRestrictions(true, false);
        BindSubscription(Restrictions);
        EditMgt.GetColumnValues(Ordinal, CellData, ColumnField, TempEdit, false);
        for Index := 1 to Ordinal do begin
            Assert.AreNotEqual('TJD-HIDDEN', CellData[Index], 'Restricted value is not shown');
            if ColumnField[Index] = Marker.FieldNo(Source) then
                Assert.AreEqual('', CellData[Index], 'The restricted cell is blank');
        end;
        asserterror EditMgt.SaveCell(Database::"Test Run Marker", Marker.SystemId, Marker.FieldNo(Source), 'TJD-X');
        UnbindSubscription(Restrictions);
        TearDown();
    end;

    /// <summary>AC05: an allowed edit and delete work through the guards.</summary>
    [Test]
    procedure AC05_AllowedEditAndDeleteWork()
    var
        Marker: Record "Test Run Marker";
        EditMgt: Codeunit "Table Data Edit Mgt ori";
    begin
        Setup();
        InsertMarker('TJD-EDIT');
        Marker.SetRange(Source, 'TJD-EDIT');
        Marker.FindFirst();
        EditMgt.SaveCell(Database::"Test Run Marker", Marker.SystemId, Marker.FieldNo(Source), 'TJD-EDITED');
        Marker.Get(Marker."Entry No.");
        Assert.AreEqual('TJD-EDITED', Marker.Source, 'Edited');
        EditMgt.DeleteRecord(Database::"Test Run Marker", Marker.SystemId);
        Assert.IsFalse(Marker.Get(Marker."Entry No."), 'Deleted');
        TearDown();
    end;

    /// <summary>AC06: read access exports but cannot edit, delete or import; modify access can do both.</summary>
    [Test]
    procedure AC06_AccessGating()
    var
        TempFilter: Record "Table Data Edit ori" temporary;
        Marker: Record "Test Run Marker";
        TableDataAccess: Record "Table Data Access ori";
        Child: Record "Test Copy Child ori";
        EditMgt: Codeunit "Table Data Edit Mgt ori";
        JsonMgt: Codeunit "Table Data JSON Mgt ori";
        LowerPermissions: Codeunit "Library - Lower Permissions";
        Source: JsonObject;
        Rows: JsonArray;
        Inserted: Integer;
        Modified: Integer;
        Failed: Integer;
    begin
        Setup();
        InsertMarker('TJD-ACCESS');
        Marker.SetRange(Source, 'TJD-ACCESS');
        Marker.FindFirst();
        Source.ReadFrom(FixtureText());
        Commit();
        // [GIVEN] Read-only access
        LowerPermissions.StartLoggingNAVPermissions();
        LowerPermissions.SetO365Basic();
        LowerPermissions.AddPermissionSet('BIFROST TblRead ori');
        LowerPermissions.AddPermissionSet('Orch TblDataT ori');
        // [THEN] Export works; edit, delete and import are refused
        TableDataAccess.AssertReadAccess();
        Rows := JsonMgt.ExportRows(Database::"Test Run Marker", false, '', TempFilter);
        Assert.IsTrue(Rows.Count() >= 1, 'Read access exports');
        asserterror TableDataAccess.AssertModifyAccess();
        Assert.ExpectedError('modify access');
        asserterror EditMgt.SaveCell(Database::"Test Run Marker", Marker.SystemId, Marker.FieldNo(Source), 'TJD-X');
        Assert.ExpectedError('modify access');
        asserterror EditMgt.DeleteRecord(Database::"Test Run Marker", Marker.SystemId);
        Assert.ExpectedError('modify access');
        asserterror JsonMgt.ImportRows(Database::"Test Copy Child ori", Source, Inserted, Modified, Failed);
        Assert.ExpectedError('modify access');
        LowerPermissions.StopLoggingNAVPermissions();
        // [GIVEN] Modify access
        LowerPermissions.SetO365Basic();
        LowerPermissions.AddPermissionSet('BIFROST PlaybAdm ori');
        LowerPermissions.AddPermissionSet('Orch TblDataT ori');
        // [THEN] Edit and import work
        TableDataAccess.AssertModifyAccess();
        EditMgt.SaveCell(Database::"Test Run Marker", Marker.SystemId, Marker.FieldNo(Source), 'TJD-MODIFIED');
        Assert.IsTrue(JsonMgt.ImportRows(Database::"Test Copy Child ori", Source, Inserted, Modified, Failed), 'Import is allowed');
        Child.Get('TJD-FIXTURE');
        Child.Delete(true);
        LowerPermissions.StopLoggingNAVPermissions();
        TearDown();
    end;

    local procedure MarkerFixtureText(): Text
    begin
        exit('{"TestRunMarker":[{"PrimaryKeyFields":{"Entry_No_":9001},"Fields":{"Source":"TJD-X"}}]}');
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
        ChildCoverageAdded := not Coverage.Get(Database::"Test Copy Child ori");
        if ChildCoverageAdded then begin
            Coverage."Table No." := Database::"Test Copy Child ori";
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
        if ChildCoverageAdded then
            if Coverage.Get(Database::"Test Copy Child ori") then
                Coverage.Delete(true);
        ChangeLogSetup.Get();
        ChangeLogSetup."Change Log Activated" := WasActivated;
        ChangeLogSetup.Modify(true);
        Commit();
    end;

    local procedure FixtureText(): Text
    begin
        // A file as the original Tools for Power Users writes it: typed values, keys without periods.
        exit('{"TestCopyChildori":[{"RecordSystemId":"7f1b6a2e-0a9d-4c3e-9f54-2a1d8c0b7e11","PrimaryKeyFields":{"Code":"TJD-FIXTURE"},"Fields":{"Amount":12}}]}');
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
        Marker.Reset();
        Marker.DeleteAll(true);
    end;
}
