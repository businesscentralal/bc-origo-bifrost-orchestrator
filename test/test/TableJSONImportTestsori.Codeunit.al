namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.Diagnostics;

/// <summary>Checks isolated upsert, failed-row continuation and rollback-only dry runs on owned markers.</summary>
codeunit 96425 "Table JSON Import Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;
    EventSubscriberInstance = Manual;

    var
        TempOriginalCoverage: Record "Change Log Setup (Table)" temporary;
        Assert: Codeunit Assert;
        RestrictRead: Boolean;
        RestrictWriteOnce: Boolean;
        HadCoverage: Boolean;
        WasActivated: Boolean;

    /// <summary>AC1.3 and AC1.5: two repeated imports modify the same primary key.</summary>
    [Test]
    procedure Scenario_AC15_RoundTripTwicePreservesPrimaryKey()
    var
        Marker: Record "Test Run Marker";
        Importer: Codeunit "Table JSON Import ori";
        Envelope: JsonObject;
        Result: JsonObject;
        Index: Integer;
    begin
        // [GIVEN] An owned marker with normal change-log coverage.
        Initialize(Marker);
        Envelope := FileFor(Marker."Entry No.", 'Imported marker');
        // [WHEN] Applying the same file twice in independent transactions.
        for Index := 1 to 2 do begin
            Result := Importer.ImportTable(Envelope, false);
            // [THEN] Each pass modifies that same row without an insert or failure.
            AssertCount(Result, 'modified', 1);
            AssertCount(Result, 'inserted', 0);
            AssertCount(Result, 'failed', 0);
            Marker.Get(Marker."Entry No.");
            Assert.AreEqual('Imported marker', Marker.Source, 'Round trip value');
        end;
        Cleanup(Marker);
    end;

    /// <summary>AC1.6: dry-run validation leaves the stored row unchanged.</summary>
    [Test]
    procedure Scenario_AC16_DryRunRollsBackExistingRow()
    var
        Marker: Record "Test Run Marker";
        Importer: Codeunit "Table JSON Import ori";
        Result: JsonObject;
    begin
        // [GIVEN] An owned stored row.
        Initialize(Marker);
        // [WHEN] Validating a changed value without saving.
        Result := Importer.ImportTable(FileFor(Marker."Entry No.", 'Dry run change'), true);
        // [THEN] Validation succeeds and the original value remains.
        AssertCount(Result, 'modified', 1);
        AssertCount(Result, 'failed', 0);
        Marker.Get(Marker."Entry No.");
        Assert.AreEqual('Before import', Marker.Source, 'Dry run must roll back');
        Cleanup(Marker);
    end;

    /// <summary>AC1.3: a failed first row does not suppress a following valid row.</summary>
    [Test]
    procedure Scenario_AC13_BadRowContinuesWithoutPartialWrite()
    var
        Marker: Record "Test Run Marker";
        Importer: Codeunit "Table JSON Import ori";
        Envelope: JsonObject;
        Rows: JsonArray;
        Value: JsonToken;
        Row: JsonObject;
        PrimaryKey: JsonObject;
        Result: JsonObject;
    begin
        // [GIVEN] An unreadable decimal followed by a valid row.
        Initialize(Marker);
        Envelope := FileFor(Marker."Entry No.", 'After bad row');
        Envelope.Get('rows', Value);
        Value.AsArray().Get(0, Value);
        Row := Value.AsObject().Clone().AsObject();
        PrimaryKey.Add('Source', 'Must roll back');
        PrimaryKey.Add('Amount', 'abc');
        Row.Replace('fields', PrimaryKey);
        Rows.Add(Row);
        Rows.Add(Value);
        Envelope.Replace('rows', Rows);
        // [WHEN] Importing with the default continue-on-error behavior.
        Result := Importer.ImportTable(Envelope, false);
        // [THEN] Only the valid row persists, and the rejected row is counted.
        AssertCount(Result, 'failed', 1);
        AssertCount(Result, 'modified', 1);
        Marker.Get(Marker."Entry No.");
        Assert.AreEqual('After bad row', Marker.Source, 'Valid row continues');
        Cleanup(Marker);
    end;

    /// <summary>AC1.3: StopOnError stops before the second row.</summary>
    [Test]
    procedure Scenario_AC13_StopOnErrorLeavesFollowingRowUnchanged()
    var
        Marker: Record "Test Run Marker";
        Importer: Codeunit "Table JSON Import ori";
        Envelope: JsonObject;
        Rows: JsonArray;
        Value: JsonToken;
        Result: JsonObject;
    begin
        // [GIVEN] A malformed row before an otherwise valid row.
        Initialize(Marker);
        Envelope := FileFor(Marker."Entry No.", 'Must not apply');
        Envelope.Get('rows', Value);
        Value.AsArray().Get(0, Value);
        Rows.Add('invalid row');
        Rows.Add(Value);
        Envelope.Replace('rows', Rows);
        // [WHEN] Stopping at the first error.
        Result := Importer.ImportTable(Envelope, false, true);
        // [THEN] No later row is modified.
        AssertCount(Result, 'failed', 1);
        AssertCount(Result, 'modified', 0);
        Marker.Get(Marker."Entry No.");
        Assert.AreEqual('Before import', Marker.Source, 'Following row unchanged');
        Cleanup(Marker);
    end;

    /// <summary>AC1.4: restricted imports use Foundation's table refusal.</summary>
    [Test]
    procedure Scenario_AC14_RestrictedImportIsRefused()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Importer: Codeunit "Table JSON Import ori";
        Envelope: JsonObject;
        Expected: Text;
    begin
        // [GIVEN] A valid envelope targeting the protected User table.
        Envelope := FileFor(1, 'Never written');
        Envelope.Replace('tableNo', 2000000120);
        Expected := TempArgument.GetRestrictedTableErrorText(2000000120, 'Table 2000000120 cannot be written.', true);
        // [WHEN] Importing it.
        asserterror Importer.ImportTable(Envelope, false);
        // [THEN] The Foundation refusal occurs before a row transaction.
        Assert.ExpectedError(Expected);
    end;

    /// <summary>AC1.6: a dry-run insert never leaves a new row.</summary>
    [Test]
    procedure Scenario_AC16_DryRunInsertLeavesNoRow()
    var
        Marker: Record "Test Run Marker";
        Importer: Codeunit "Table JSON Import ori";
        Result: JsonObject;
        EntryNo: Integer;
    begin
        // [GIVEN] An allocated owned key that is no longer stored.
        Initialize(Marker);
        EntryNo := Marker."Entry No.";
        Marker.Delete(true);
        Commit();
        // [WHEN] Dry-running an insert at that key.
        Result := Importer.ImportTable(FileFor(EntryNo, 'Dry insert'), true);
        // [THEN] It validates as an insert and leaves no record.
        AssertCount(Result, 'inserted', 1);
        AssertCount(Result, 'failed', 0);
        Assert.IsFalse(Marker.Get(EntryNo), 'No dry-run row persisted');
        // Complete the normal cleanup on a recreated owned marker.
        Result := Importer.ImportTable(FileFor(EntryNo, 'Actual insert'), false);
        AssertCount(Result, 'inserted', 1);
        AssertCount(Result, 'failed', 0);
        Marker.Get(EntryNo);
        Cleanup(Marker);
    end;

    /// <summary>AC2.3: the editor changes a field and rolls back an invalid decimal.</summary>
    [Test]
    procedure Scenario_AC23_EditorValidatesAndRejectsBadValue()
    var
        Marker: Record "Test Run Marker";
        Serializer: Codeunit "Serializer ori";
        Mgt: Codeunit "Table Data Mgt ori";
        Row: JsonObject;
        FieldNos: List of [Integer];
    begin
        // [GIVEN] An owned marker under normal change-log coverage.
        Initialize(Marker);
        Row := Serializer.SerializeToJson(Marker, FieldNos);
        // [WHEN] Editing the source then attempting an unreadable decimal.
        Mgt.SaveField(Database::"Test Run Marker", Row, 2, 'Editor change');
        Marker.Get(Marker."Entry No.");
        Assert.AreEqual('Editor change', Marker.Source, 'Editor saved the field');
        asserterror Mgt.SaveField(Database::"Test Run Marker", Row, 3, 'abc');
        // [THEN] The invalid edit leaves both values unchanged.
        Marker.Get(Marker."Entry No.");
        Assert.AreEqual(0, Marker.Amount, 'Invalid decimal not assigned');
        Assert.AreEqual('Editor change', Marker.Source, 'Previous committed edit retained');
        Cleanup(Marker);
    end;

    /// <summary>AC2.2 and AC2.4: the metadata route hides restricted fields and prevents a write-once edit.</summary>
    [Test]
    procedure Scenario_AC24_CurrentRestrictionsControlEditor()
    var
        Marker: Record "Test Run Marker";
        TempFields: Record "Table Data Field ori" temporary;
        Guard: Codeunit "Table JSON Import Tests ori";
        Serializer: Codeunit "Serializer ori";
        Mgt: Codeunit "Table Data Mgt ori";
        Row: JsonObject;
        FieldNos: List of [Integer];
    begin
        // [GIVEN] An owned row and a scoped manually bound Foundation restriction subscriber.
        Initialize(Marker);
        Row := Serializer.SerializeToJson(Marker, FieldNos);
        Guard.SetRestrictions(true, false);
        BindSubscription(Guard);
        // [WHEN] Reading the editor's current field list.
        Mgt.LoadRecord(Database::"Test Run Marker", Row, TempFields);
        // [THEN] A read-restricted Source is omitted.
        Assert.IsFalse(TempFields.Get(2), 'Read-restricted source omitted');
        UnbindSubscription(Guard);
        Guard.SetRestrictions(false, true);
        BindSubscription(Guard);
        Mgt.LoadRecord(Database::"Test Run Marker", Row, TempFields);
        TempFields.Get(2);
        Assert.IsFalse(TempFields."Can Edit", 'Populated write-once field is read-only');
        asserterror Mgt.SaveField(Database::"Test Run Marker", Row, 2, 'Forbidden');
        Assert.ExpectedError('read-only');
        UnbindSubscription(Guard);
        Marker.Get(Marker."Entry No.");
        Assert.AreEqual('Before import', Marker.Source, 'Write-once value unchanged');
        Cleanup(Marker);
    end;

    /// <summary>Sets the two restrictions used only by this manually bound test subscriber.</summary>
    procedure SetRestrictions(ReadRestricted: Boolean; WriteOnce: Boolean)
    begin
        RestrictRead := ReadRestricted;
        RestrictWriteOnce := WriteOnce;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", 'OnAfterIsFieldReadRestrictedForDataRecords', '', false, false)]
    local procedure RestrictSourceRead(TableNo: Integer; FieldNo: Integer; var IsRestricted: Boolean)
    begin
        if RestrictRead and (TableNo = Database::"Test Run Marker") and (FieldNo = 2) then
            IsRestricted := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", 'OnAfterIsFieldWriteOnceForDataRecords', '', false, false)]
    local procedure RestrictSourceWriteOnce(TableNo: Integer; FieldNo: Integer; Force: Boolean; var IsWriteOnce: Boolean)
    begin
        if RestrictWriteOnce and (TableNo = Database::"Test Run Marker") and (FieldNo = 2) then
            IsWriteOnce := true;
    end;

    local procedure FileFor(EntryNo: Integer; NewSource: Text) Envelope: JsonObject
    var
        PrimaryKey: JsonObject;
        Fields: JsonObject;
        Row: JsonObject;
        Rows: JsonArray;
    begin
        PrimaryKey.Add('EntryNo_', EntryNo);
        Fields.Add('Source', NewSource);
        Row.Add('primaryKey', PrimaryKey);
        Row.Add('fields', Fields);
        Rows.Add(Row);
        Envelope.Add('format', 'bifrost-table-data');
        Envelope.Add('version', 1);
        Envelope.Add('tableNo', Database::"Test Run Marker");
        Envelope.Add('rows', Rows);
    end;

    local procedure AssertCount(Result: JsonObject; Name: Text; Expected: Integer)
    var
        Value: JsonToken;
    begin
        Assert.IsTrue(Result.Get(Name, Value), Name + ' count present');
        Assert.AreEqual(Expected, Value.AsValue().AsInteger(), Name);
    end;

    local procedure Initialize(var Marker: Record "Test Run Marker")
    var
        ChangeLogSetup: Record "Change Log Setup";
        Coverage: Record "Change Log Setup (Table)";
    begin
        Clear(TempOriginalCoverage);
        HadCoverage := Coverage.Get(Database::"Test Run Marker");
        if HadCoverage then
            TempOriginalCoverage := Coverage
        else begin
            Coverage.Init();
            Coverage."Table No." := Database::"Test Run Marker";
            Coverage.Insert(true);
        end;
        Coverage."Log Modification" := Coverage."Log Modification"::"All Fields";
        Coverage.Modify(true);
        ChangeLogSetup.Get();
        WasActivated := ChangeLogSetup."Change Log Activated";
        ChangeLogSetup."Change Log Activated" := true;
        ChangeLogSetup.Modify(true);
        Clear(Marker);
        Marker.Source := 'Before import';
        Marker.Insert(true);
        Commit();
    end;

    local procedure Cleanup(var Marker: Record "Test Run Marker")
    var
        ChangeLogSetup: Record "Change Log Setup";
        Coverage: Record "Change Log Setup (Table)";
    begin
        Marker.Delete(true);
        Coverage.Get(Database::"Test Run Marker");
        if HadCoverage then begin
            Coverage."Log Modification" := TempOriginalCoverage."Log Modification";
            Coverage.Modify(true);
        end else
            Coverage.Delete(true);
        ChangeLogSetup.Get();
        ChangeLogSetup."Change Log Activated" := WasActivated;
        ChangeLogSetup.Modify(true);
        Commit();
    end;
}
