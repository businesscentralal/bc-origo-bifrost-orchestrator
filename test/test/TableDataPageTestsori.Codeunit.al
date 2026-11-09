namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost.Orchestrator;

/// <summary>Exercises the user-facing Table Data filter and navigation controls.</summary>
codeunit 96448 "Table Data Page Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;
    var
        Assert: Codeunit Assert;

    /// <summary>AC2.1: the page preserves the chosen table and filtered page when navigating.</summary>
    [Test]
    procedure Scenario_AC21_PageNavigationRetainsFilter()
    var
        Marker: Record "Test Run Marker";
        Browser: TestPage "Table Data ori";
        Scope: Text[50];
        Index: Integer;
        FirstKey: Text;
    begin
        // [GIVEN] 120 owned rows, spanning three pages.
        Scope := CopyStr(Format(CreateGuid(), 0, 4), 1, MaxStrLen(Scope));
        for Index := 1 to 120 do begin
            Marker.Init();
            Marker."Entry No." := 0;
            Marker.Source := Scope;
            Marker.Insert(true);
        end;
        Marker.SetRange(Source, Scope);
        // [WHEN] Selecting the table and filter, then navigating forward and back.
        Browser.OpenEdit();
        Browser.TableNo.SetValue(Database::"Test Run Marker");
        Browser.TableView.SetValue(Marker.GetView(false));
        Browser.First();
        FirstKey := Browser."Primary Key".Value();
        Browser.NextPage.Invoke();
        Browser.CurrentPage.AssertEquals(2);
        Assert.IsTrue(Browser.NextPage.Enabled(), 'Third page available');
        Browser.NextPage.Invoke();
        Browser.CurrentPage.AssertEquals(3);
        Assert.IsFalse(Browser.NextPage.Enabled(), 'No fourth page');
        Browser.PreviousPage.Invoke();
        Browser.CurrentPage.AssertEquals(2);
        Browser.PreviousPage.Invoke();
        Browser.First();
        // [THEN] The first page is stable and filtered.
        Browser.CurrentPage.AssertEquals(1);
        Browser."Primary Key".AssertEquals(FirstKey);
        Assert.IsTrue(Browser.Summary.Value().Contains(Scope), 'Filter retained');
        Browser.Close();
        Marker.DeleteAll(true);
    end;
}
