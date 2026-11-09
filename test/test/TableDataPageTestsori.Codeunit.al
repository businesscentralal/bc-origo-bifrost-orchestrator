namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost.Orchestrator;
using System.Diagnostics;
using System.TestLibraries.Utilities;

/// <summary>Story #155 Phase 2 (AC2.1, AC2.3): the "Table Data ori" and "Table Data Fields ori" pages.</summary>
codeunit 96448 "Table Data Page Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        NewSourceValue: Text;

    /// <summary>AC2.1: open the page on a table, page forward and back.</summary>
    [Test]
    procedure AC21_PageForwardAndBack()
    var
        Marker: Record "Test Run Marker";
        TableData: TestPage "Table Data ori";
        Index: Integer;
    begin
        // [GIVEN] 60 owned markers
        DeleteMarkers();
        for Index := 1 to 60 do
            InsertMarker(CopyStr('TJP-' + Format(Index), 1, 50));
        Marker.SetFilter(Source, 'TJP-*');
        // [WHEN] The page is opened on the table with a view on the owned rows
        TableData.OpenEdit();
        TableData.TableViewField.SetValue(Marker.GetView(true));
        TableData.TableNoField.SetValue(Database::"Test Run Marker");
        // [THEN] Page 1 is shown, Next moves to page 2 and Previous back to page 1
        Assert.AreEqual('1', TableData.PageNoField.Value(), 'Page 1');
        Assert.IsTrue(TableData.NextPage.Enabled(), 'A next page exists');
        TableData.NextPage.Invoke();
        Assert.AreEqual('2', TableData.PageNoField.Value(), 'Page 2');
        Assert.IsTrue(TableData.First(), 'Page 2 has rows');
        TableData.PreviousPage.Invoke();
        Assert.AreEqual('1', TableData.PageNoField.Value(), 'Back on page 1');
        TableData.Close();
        DeleteMarkers();
    end;

    /// <summary>AC2.3: Open Record shows the fields and an edit of Source is saved.</summary>
    [Test]
    [HandlerFunctions('EditSourceHandler')]
    procedure AC23_OpenRecordAndEdit()
    var
        Marker: Record "Test Run Marker";
        ChangeLogSetup: Record "Change Log Setup";
        Coverage: Record "Change Log Setup (Table)";
        TableData: TestPage "Table Data ori";
        WasActivated: Boolean;
        CoverageAdded: Boolean;
    begin
        // [GIVEN] One owned marker and change log coverage for its table
        DeleteMarkers();
        InsertMarker('TJP-EDIT');
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
            Coverage."Log Modification" := Coverage."Log Modification"::"All Fields";
            Coverage.Insert(true);
        end;
        Marker.SetRange(Source, 'TJP-EDIT');
        TableData.OpenEdit();
        TableData.TableViewField.SetValue(Marker.GetView(true));
        TableData.TableNoField.SetValue(Database::"Test Run Marker");
        TableData.First();
        // [WHEN] The record is opened and Source is edited in the fields page
        NewSourceValue := 'TJP-EDITED';
        TableData.OpenRecord.Invoke();
        TableData.Close();
        // [THEN] The record holds the new value
        Marker.SetRange(Source, 'TJP-EDITED');
        Assert.IsFalse(Marker.IsEmpty(), 'The edit is saved');
        DeleteMarkers();
        if CoverageAdded then
            if Coverage.Get(Database::"Test Run Marker") then
                Coverage.Delete(true);
        ChangeLogSetup.Get();
        ChangeLogSetup."Change Log Activated" := WasActivated;
        ChangeLogSetup.Modify(true);
    end;

    [ModalPageHandler]
    procedure EditSourceHandler(var TableDataFields: TestPage "Table Data Fields ori")
    begin
        Assert.IsTrue(TableDataFields.FindFirstField("Field Name", 'Source'), 'Source is listed');
        TableDataFields.Value.SetValue(NewSourceValue);
        TableDataFields.OK().Invoke();
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
        Marker.SetFilter(Source, 'TJP*');
        Marker.DeleteAll(true);
    end;
}
