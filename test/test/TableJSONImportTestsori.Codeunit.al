namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.Diagnostics;
using System.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>Story #155 Phase 1 (AC1.3 to AC1.6): table data import through Foundation's "Serializer ori".</summary>
codeunit 96425 "Table JSON Import Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        TableJSONExport: Codeunit "Table JSON Export ori";
        TableJSONImport: Codeunit "Table JSON Import ori";
        WasActivated: Boolean;
        CoverageAdded: Boolean;

    /// <summary>AC1.5: export, change a row in the file, import; the table equals the file, twice in a row.</summary>
    [Test]
    procedure AC15_RoundTripModifiesFromFile()
    var
        Envelope: JsonObject;
        Result: JsonObject;
        Pass: Integer;
    begin
        // [GIVEN] Two owned markers, exported, and the file changed in its first row
        Setup();
        InsertMarker('TJI-A');
        InsertMarker('TJI-B');
        Envelope := ExportOwned();
        SetRowSource(Envelope, 0, 'TJI-A2');
        for Pass := 1 to 2 do begin
            // [WHEN] The file is imported
            Result := TableJSONImport.ImportTable(Envelope, false, false);
            // [THEN] Both rows are modified in place and the table equals the file
            Assert.AreEqual(0, GetInteger(Result, 'inserted'), 'No row is inserted');
            Assert.AreEqual(2, GetInteger(Result, 'modified'), 'Both rows are modified');
            Assert.AreEqual(0, GetInteger(Result, 'failed'), 'No row fails');
            Assert.AreEqual(1, CountSource('TJI-A2'), 'The changed value is imported');
            Assert.AreEqual(0, CountSource('TJI-A'), 'The old value is gone');
            Assert.AreEqual(1, CountSource('TJI-B'), 'The unchanged row stays');
        end;
        TearDown();
    end;

    /// <summary>A row that matches no record by id or primary key is inserted.</summary>
    [Test]
    procedure RowWithoutMatchIsInserted()
    var
        Marker: Record "Test Run Marker";
        Envelope: JsonObject;
        Result: JsonObject;
    begin
        // [GIVEN] An exported owned marker that is then deleted
        Setup();
        InsertMarker('TJI-NEW');
        Envelope := ExportOwned();
        Marker.SetRange(Source, 'TJI-NEW');
        Marker.DeleteAll(true);
        // [WHEN] The file is imported
        Result := TableJSONImport.ImportTable(Envelope, false, false);
        // [THEN] The row is inserted again
        Assert.AreEqual(1, GetInteger(Result, 'inserted'), 'The row is inserted');
        Assert.AreEqual(1, CountSource('TJI-NEW'), 'The inserted row is in the table');
        TearDown();
    end;

    /// <summary>AC1.3: an unreadable value fails that row with the serializer's error; the other rows continue.</summary>
    [Test]
    procedure AC13_BadValueFailsOnlyThatRow()
    var
        Envelope: JsonObject;
        Result: JsonObject;
        Errors: JsonArray;
        ErrorToken: JsonToken;
        RowToken: JsonToken;
    begin
        // [GIVEN] Two exported markers; the file gives the first a text longer than the field
        Setup();
        InsertMarker('TJI-A');
        InsertMarker('TJI-B');
        Envelope := ExportOwned();
        SetRowSource(Envelope, 0, PadStr('TJI-', 60, 'X'));
        SetRowSource(Envelope, 1, 'TJI-B2');
        // [WHEN] The file is imported with Stop On Error false
        Result := TableJSONImport.ImportTable(Envelope, false, false);
        // [THEN] The first row fails with a row error and the second row is applied
        Assert.AreEqual(1, GetInteger(Result, 'failed'), 'One row fails');
        Assert.AreEqual(1, GetInteger(Result, 'modified'), 'The other row is modified');
        Result.Get('errors', ErrorToken);
        Errors := ErrorToken.AsArray();
        Errors.Get(0, ErrorToken);
        ErrorToken.AsObject().Get('row', RowToken);
        Assert.AreEqual(1, RowToken.AsValue().AsInteger(), 'The first row is reported');
        ErrorToken.AsObject().Get('error', RowToken);
        Assert.AreNotEqual('', RowToken.AsValue().AsText(), 'The serializer error text is reported');
        Assert.AreEqual(1, CountSource('TJI-A'), 'The failed row is unchanged');
        Assert.AreEqual(1, CountSource('TJI-B2'), 'The good row is applied');
        TearDown();
    end;

    /// <summary>AC1.3: with Stop On Error the import stops at the failed row and writes nothing.</summary>
    [Test]
    procedure AC13_StopOnErrorWritesNothing()
    var
        Envelope: JsonObject;
    begin
        // [GIVEN] Two exported markers; the second row in the file is unreadable, the first is changed
        Setup();
        InsertMarker('TJI-A');
        InsertMarker('TJI-B');
        Envelope := ExportOwned();
        SetRowSource(Envelope, 0, 'TJI-A2');
        SetRowSource(Envelope, 1, PadStr('TJI-', 60, 'X'));
        // [WHEN] The file is imported with Stop On Error
        asserterror TableJSONImport.ImportTable(Envelope, false, true);
        // [THEN] The import names the failed row and nothing is written
        Assert.ExpectedError('Row 2 failed:');
        Assert.AreEqual(1, CountSource('TJI-A'), 'The first row is not written');
        Assert.AreEqual(0, CountSource('TJI-A2'), 'The changed value is not imported');
        TearDown();
    end;

    /// <summary>AC1.6: a dry run checks every row and leaves the table unchanged.</summary>
    [Test]
    procedure AC16_DryRunLeavesTableUnchanged()
    var
        Envelope: JsonObject;
        Result: JsonObject;
        DryRunToken: JsonToken;
    begin
        // [GIVEN] Two exported markers and a changed file
        Setup();
        InsertMarker('TJI-A');
        InsertMarker('TJI-B');
        Envelope := ExportOwned();
        SetRowSource(Envelope, 0, 'TJI-A2');
        // [WHEN] The file is imported as a dry run
        Result := TableJSONImport.ImportTable(Envelope, true, false);
        // [THEN] The result counts the rows that would change, and the table is unchanged
        Result.Get('dryRun', DryRunToken);
        Assert.IsTrue(DryRunToken.AsValue().AsBoolean(), 'dryRun is reported');
        Assert.AreEqual(2, GetInteger(Result, 'modified'), 'Both rows would be modified');
        Assert.AreEqual(1, CountSource('TJI-A'), 'The table is unchanged');
        Assert.AreEqual(0, CountSource('TJI-A2'), 'Nothing is written');
        TearDown();
    end;

    /// <summary>AC1.4: a write-restricted table is refused with the Foundation text; nothing is read or written.</summary>
    [Test]
    procedure AC14_RestrictedTableIsRefused()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Envelope: JsonObject;
        Rows: JsonArray;
        WriteRefusedTxt: Label 'Table %1 (%2) cannot be written by the table data import.', Locked = true;
    begin
        // [GIVEN] A file for the User table
        Assert.IsTrue(TempArgument.IsTableWriteRestrictedForDataRecords(Database::User, false), 'Precondition: User is write-restricted');
        Envelope.Add('format', 'bifrost-table-data');
        Envelope.Add('version', 1);
        Envelope.Add('tableNo', Database::User);
        Envelope.Add('rows', Rows);
        // [WHEN] It is imported
        asserterror TableJSONImport.ImportTable(Envelope, true, false);
        // [THEN] It is refused with the Foundation text
        Assert.ExpectedError(TempArgument.GetRestrictedTableErrorText(Database::User, StrSubstNo(WriteRefusedTxt, Database::User, 'User'), true));
    end;

    /// <summary>A file that is not a table data file is refused.</summary>
    [Test]
    procedure WrongFormatIsRefused()
    var
        Envelope: JsonObject;
    begin
        Envelope.Add('format', 'something-else');
        Envelope.Add('version', 1);
        asserterror TableJSONImport.ImportTable(Envelope, true, false);
        Assert.ExpectedError('The file is not a Bifrost table data file');
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

    local procedure ExportOwned(): JsonObject
    var
        Marker: Record "Test Run Marker";
        FieldNos: List of [Integer];
    begin
        Marker.SetFilter(Source, 'TJI-*');
        exit(TableJSONExport.ExportTable(Database::"Test Run Marker", Marker.GetView(false), FieldNos));
    end;

    local procedure SetRowSource(var Envelope: JsonObject; RowIndex: Integer; NewSource: Text)
    var
        RowsToken: JsonToken;
        RowToken: JsonToken;
        FieldsToken: JsonToken;
        FieldsObject: JsonObject;
    begin
        Envelope.Get('rows', RowsToken);
        RowsToken.AsArray().Get(RowIndex, RowToken);
        RowToken.AsObject().Get('fields', FieldsToken);
        FieldsObject := FieldsToken.AsObject();
        FieldsObject.Replace('Source', NewSource);
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
        Marker.SetFilter(Source, 'TJI*');
        Marker.DeleteAll(true);
    end;

    local procedure CountSource(Source: Text): Integer
    var
        Marker: Record "Test Run Marker";
    begin
        Marker.SetRange(Source, Source);
        exit(Marker.Count());
    end;

    local procedure GetInteger(Result: JsonObject; KeyName: Text): Integer
    var
        Token: JsonToken;
    begin
        Result.Get(KeyName, Token);
        exit(Token.AsValue().AsInteger());
    end;
}
