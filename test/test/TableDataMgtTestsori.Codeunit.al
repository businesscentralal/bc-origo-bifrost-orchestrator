namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost.Orchestrator;

/// <summary>Checks bounded paging, filters and refusals of the Table Data browser.</summary>
codeunit 96426 "Table Data Mgt Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;
    var
        Assert: Codeunit Assert;

    /// <summary>AC2.1: 120 owned rows page 50, 50 and 20 with stable backward navigation.</summary>
    [Test]
    procedure Scenario_AC21_PagesAndFilters120OwnedRows()
    var
        Marker: Record "Test Run Marker";
        TempRows: Record "Table Data Row ori" temporary;
        Mgt: Codeunit "Table Data Mgt ori";
        Scope: Text[50];
        Index: Integer;
        FirstKey: Text;
    begin
        // [GIVEN] Exactly 120 rows under a unique source filter.
        Scope := CopyStr(Format(CreateGuid(), 0, 4), 1, MaxStrLen(Scope));
        for Index := 1 to 120 do begin
            Marker.Init();
            Marker."Entry No." := 0;
            Marker.Source := Scope;
            Marker.Insert(true);
        end;
        Marker.SetRange(Source, Scope);
        // [WHEN] Loading three pages and returning to the first.
        Assert.IsTrue(Mgt.LoadPage(Database::"Test Run Marker", Marker.GetView(false), 1, 50, TempRows), 'First page has next');
        Assert.AreEqual(50, TempRows.Count(), 'First page count');
        TempRows.FindFirst();
        FirstKey := TempRows."Primary Key";
        Assert.IsTrue(Mgt.LoadPage(Database::"Test Run Marker", Marker.GetView(false), 2, 50, TempRows), 'Second page has next');
        Assert.AreEqual(50, TempRows.Count(), 'Second page count');
        Assert.IsFalse(Mgt.LoadPage(Database::"Test Run Marker", Marker.GetView(false), 3, 50, TempRows), 'Last page has no next');
        Assert.AreEqual(20, TempRows.Count(), 'Last page count');
        Mgt.LoadPage(Database::"Test Run Marker", Marker.GetView(false), 1, 50, TempRows);
        TempRows.FindFirst();
        // [THEN] Backward navigation starts on the same row and only own rows were read.
        Assert.AreEqual(FirstKey, TempRows."Primary Key", 'Stable previous page');
        Assert.IsTrue(TempRows.Summary.Contains(Scope), 'Source filter preserved');
        Marker.DeleteAll(true);
    end;

    /// <summary>AC2.2: restricted tables are refused before browsing.</summary>
    [Test]
    procedure Scenario_AC22_RestrictedTableCannotOpen()
    var
        TempRows: Record "Table Data Row ori" temporary;
        Mgt: Codeunit "Table Data Mgt ori";
    begin
        // [WHEN] Browsing a Foundation-protected table.
        asserterror Mgt.LoadPage(2000000120, '', 1, 50, TempRows);
        // [THEN] No temporary row was exposed.
        Assert.IsTrue(TempRows.IsEmpty(), 'Restricted table produces no rows');
    end;

    /// <summary>AC2.1: invalid page sizes cannot request an unbounded read.</summary>
    [Test]
    procedure Scenario_AC21_PageSizeIsBounded()
    var
        TempRows: Record "Table Data Row ori" temporary;
        Mgt: Codeunit "Table Data Mgt ori";
    begin
        asserterror Mgt.LoadPage(Database::"Test Run Marker", '', 1, 501, TempRows);
        Assert.ExpectedError('between 1 and 500');
        asserterror Mgt.LoadPage(Database::"Test Run Marker", '', 0, 50, TempRows);
        Assert.ExpectedError('page number');
    end;
}
