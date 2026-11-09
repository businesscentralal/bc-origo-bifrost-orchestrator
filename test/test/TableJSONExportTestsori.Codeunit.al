namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>Story #155 Phase 1 (AC1.1, AC1.2, AC1.4): table data export through Foundation's "Serializer ori".</summary>
codeunit 96406 "Table JSON Export Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        TableJSONExport: Codeunit "Table JSON Export ori";

    /// <summary>AC1.1: the envelope names the format, version and table and holds one row per filtered record.</summary>
    [Test]
    procedure AC11_ExportWritesEnvelopeForFilteredRows()
    var
        Marker: Record "Test Run Marker";
        Envelope: JsonObject;
        FieldNos: List of [Integer];
    begin
        // [GIVEN] Three owned markers, two of them with the TJX- prefix
        DeleteMarkers();
        InsertMarker('TJX-A');
        InsertMarker('TJX-B');
        InsertMarker('TJY-C');
        Marker.SetFilter(Source, 'TJX-*');
        // [WHEN] The table is exported with a view that filters on the prefix and an empty field list
        Envelope := TableJSONExport.ExportTable(Database::"Test Run Marker", Marker.GetView(false), FieldNos);
        // [THEN] The envelope names the format and table, and holds only the two filtered rows
        Assert.AreEqual('bifrost-table-data', GetText(Envelope, 'format'), 'format');
        Assert.AreEqual(1, GetInteger(Envelope, 'version'), 'version');
        Assert.AreEqual(Database::"Test Run Marker", GetInteger(Envelope, 'tableNo'), 'tableNo');
        Assert.AreNotEqual('', GetText(Envelope, 'tableName'), 'tableName');
        Assert.AreEqual(2, GetRows(Envelope).Count(), 'Only the rows in the view are exported');
        DeleteMarkers();
    end;

    /// <summary>AC1.2: every exported row is exactly the "Serializer ori".SerializeToJson output for that record.</summary>
    [Test]
    procedure AC12_RowEqualsSerializerOutput()
    var
        Marker: Record "Test Run Marker";
        Serializer: Codeunit "Serializer ori";
        Envelope: JsonObject;
        RowToken: JsonToken;
        FieldNos: List of [Integer];
        Expected: Text;
        Actual: Text;
    begin
        // [GIVEN] One owned marker
        DeleteMarkers();
        InsertMarker('TJX-ONE');
        Marker.SetRange(Source, 'TJX-ONE');
        Marker.FindFirst();
        // [WHEN] It is exported
        Envelope := TableJSONExport.ExportTable(Database::"Test Run Marker", Marker.GetView(false), FieldNos);
        // [THEN] The row is the serializer envelope for the record
        GetRows(Envelope).Get(0, RowToken);
        RowToken.WriteTo(Actual);
        Serializer.SerializeToJson(Marker, FieldNos).WriteTo(Expected);
        Assert.AreEqual(Expected, Actual, 'Row is the Serializer ori output');
        DeleteMarkers();
    end;

    /// <summary>AC1.1: a field list limits the fields object of each row.</summary>
    [Test]
    procedure AC11_FieldListLimitsFields()
    var
        Marker: Record "Test Run Marker";
        Envelope: JsonObject;
        RowToken: JsonToken;
        FieldsToken: JsonToken;
        FieldNos: List of [Integer];
    begin
        // [GIVEN] One owned marker and a field list with only Source
        DeleteMarkers();
        InsertMarker('TJX-FLD');
        Marker.SetRange(Source, 'TJX-FLD');
        FieldNos.Add(Marker.FieldNo(Source));
        // [WHEN] It is exported with that field list
        Envelope := TableJSONExport.ExportTable(Database::"Test Run Marker", Marker.GetView(false), FieldNos);
        // [THEN] The fields object holds Source only and the primary key is separate
        GetRows(Envelope).Get(0, RowToken);
        RowToken.AsObject().Get('fields', FieldsToken);
        Assert.AreEqual(1, FieldsToken.AsObject().Keys().Count(), 'Only the listed field is written');
        Assert.IsTrue(FieldsToken.AsObject().Contains('Source'), 'Source is written');
        Assert.IsTrue(RowToken.AsObject().Contains('primaryKey'), 'The primary key is written separately');
        DeleteMarkers();
    end;

    /// <summary>AC1.4: a read-restricted table is refused with the Foundation restricted-table text.</summary>
    [Test]
    procedure AC14_RestrictedTableIsRefused()
    var
        TempArgument: Record "Message Argument ori" temporary;
        FieldNos: List of [Integer];
        ReadRefusedTxt: Label 'Table %1 (%2) cannot be read by the table data export.', Locked = true;
    begin
        // [GIVEN] The User table, which Foundation closes for the generic Data types
        Assert.IsTrue(TempArgument.IsTableReadRestrictedForDataRecords(Database::User), 'Precondition: User is read-restricted');
        // [WHEN] It is exported
        asserterror TableJSONExport.ExportTable(Database::User, '', FieldNos);
        // [THEN] The export is refused with the Foundation text
        Assert.ExpectedError(TempArgument.GetRestrictedTableErrorText(Database::User, StrSubstNo(ReadRefusedTxt, Database::User, 'User'), false));
    end;

    /// <summary>An unknown table and an invalid view are refused.</summary>
    [Test]
    procedure UnknownTableAndInvalidViewAreRefused()
    var
        FieldNos: List of [Integer];
    begin
        asserterror TableJSONExport.ExportTable(1999999998, '', FieldNos);
        Assert.ExpectedError('Table 1999999998 does not exist.');
        asserterror TableJSONExport.ExportTable(Database::"Test Run Marker", 'WHERE(NoSuchField=CONST(1))', FieldNos);
        Assert.AreNotEqual('', GetLastErrorText(), 'An invalid view is refused');
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
        Marker.SetFilter(Source, 'TJ*');
        Marker.DeleteAll(true);
    end;

    local procedure GetRows(Envelope: JsonObject): JsonArray
    var
        Token: JsonToken;
    begin
        Envelope.Get('rows', Token);
        exit(Token.AsArray());
    end;

    local procedure GetText(Envelope: JsonObject; KeyName: Text): Text
    var
        Token: JsonToken;
    begin
        Envelope.Get(KeyName, Token);
        exit(Token.AsValue().AsText());
    end;

    local procedure GetInteger(Envelope: JsonObject; KeyName: Text): Integer
    var
        Token: JsonToken;
    begin
        Envelope.Get(KeyName, Token);
        exit(Token.AsValue().AsInteger());
    end;
}
