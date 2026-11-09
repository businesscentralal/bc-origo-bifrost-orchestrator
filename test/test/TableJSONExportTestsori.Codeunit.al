namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;

/// <summary>Checks the table-data export envelope, selection and Foundation read boundary.</summary>
codeunit 96406 "Table JSON Export Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    /// <summary>AC1.1 and AC1.2: selected rows are exactly the public serializer output.</summary>
    [Test]
    procedure Scenario_AC11_FilteredExportUsesSerializerEnvelope()
    var
        Marker: Record "Test Run Marker";
        Exporter: Codeunit "Table JSON Export ori";
        Serializer: Codeunit "Serializer ori";
        Fields: List of [Integer];
        Envelope: JsonObject;
        Expected: JsonObject;
        Value: JsonToken;
        ActualText: Text;
        ExpectedText: Text;
    begin
        // [GIVEN] A private marker selected by its allocated entry number.
        Marker.Source := CopyStr(Format(CreateGuid(), 0, 4), 1, MaxStrLen(Marker.Source));
        Marker.Insert(true);
        Marker.SetRange("Entry No.", Marker."Entry No.");
        // [WHEN] Exporting all eligible fields through a filtered view.
        Envelope := Exporter.ExportTable(Database::"Test Run Marker", Marker.GetView(false), Fields);
        // [THEN] The file header is versioned and the only row is Foundation's exact envelope.
        Envelope.Get('format', Value);
        Assert.AreEqual('bifrost-table-data', Value.AsValue().AsText(), 'File format');
        Envelope.Get('version', Value);
        Assert.AreEqual(1, Value.AsValue().AsInteger(), 'File version');
        Envelope.Get('rows', Value);
        Assert.AreEqual(1, Value.AsArray().Count(), 'Only selected row');
        Value.AsArray().Get(0, Value);
        Value.WriteTo(ActualText);
        // Reload the persisted row: SQL rounds system timestamps beyond the insert buffer precision.
        Marker.Get(Marker."Entry No.");
        Expected := Serializer.SerializeToJson(Marker, Fields);
        Expected.WriteTo(ExpectedText);
        Assert.AreEqual(ExpectedText, ActualText, 'No local serializer changes');
        Marker.Delete(true);
    end;

    /// <summary>AC1.1: a nonempty field selection is passed through unchanged.</summary>
    [Test]
    procedure Scenario_AC11_FieldSelectionOmitsUnselectedFields()
    var
        Marker: Record "Test Run Marker";
        Exporter: Codeunit "Table JSON Export ori";
        Fields: List of [Integer];
        Envelope: JsonObject;
        Value: JsonToken;
    begin
        // [GIVEN] A private row and selection containing only its key field.
        Marker.Source := 'Selected export';
        Marker.Insert(true);
        Marker.SetRange("Entry No.", Marker."Entry No.");
        Fields.Add(1);
        // [WHEN] Exporting with that selection.
        Envelope := Exporter.ExportTable(Database::"Test Run Marker", Marker.GetView(false), Fields);
        // [THEN] The unselected Source field is absent.
        Envelope.Get('rows', Value);
        Value.AsArray().Get(0, Value);
        Value.AsObject().Get('fields', Value);
        Assert.IsFalse(Value.AsObject().Contains('Source'), 'Unselected field omitted');
        Marker.Delete(true);
    end;

    /// <summary>AC1.4: a restricted table is refused before a record is opened.</summary>
    [Test]
    procedure Scenario_AC14_RestrictedExportUsesFoundationError()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Exporter: Codeunit "Table JSON Export ori";
        Fields: List of [Integer];
        Expected: Text;
    begin
        // [GIVEN] User is a Foundation restricted table, even under SUPER.
        Expected := TempArgument.GetRestrictedTableErrorText(2000000120, 'Table 2000000120 cannot be read.', false);
        // [WHEN] Requesting its export.
        asserterror Exporter.ExportTable(2000000120, '', Fields);
        // [THEN] Foundation's refusal text is preserved.
        Assert.ExpectedError(Expected);
    end;
}
