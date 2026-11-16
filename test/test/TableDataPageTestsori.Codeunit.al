namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
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
        ConfirmImport: Boolean;
        ImportMarkerId: Guid;
        ReadOnlyFieldName: Text;

    /// <summary>Tools open the intended pages from Setup in both supported languages.</summary>
    [Test]
    procedure Scenario_AC01_SetupTools_OpenTargetPages()
    begin
        // Story #199, AC01 | Time: independent of Today/WorkDate | Risk: Foundation setup UI.
        VerifyToolsNavigation(1033, true);
        VerifyToolsNavigation(1039, true);
    end;

    /// <summary>Tools remain usable on an empty Playbooks list in both supported languages.</summary>
    [Test]
    procedure Scenario_AC02_EmptyPlaybooks_OpenTargetPages()
    begin
        // Story #199, AC02 | Time: independent of Today/WorkDate | Risk: None.
        VerifyToolsNavigation(1033, false);
        VerifyToolsNavigation(1039, false);
    end;

    /// <summary>The view role can reach Copy Plans but has no Table Data action.</summary>
    [Test]
    procedure Scenario_AC03_Viewer_HidesTableDataAndOpensCopyPlans()
    var
        LowerPermissions: Codeunit "Library - Lower Permissions";
        Playbooks: TestPage "Playbooks ori";
        CopyPlans: TestPage "Copy Plans ori";
    begin
        // Story #199, AC03 | Time: independent of Today/WorkDate | Risk: Permission mock must be active.
        // [GIVEN] The exact read-only playbook role, without SUPER or an admin role.
        LowerPermissions.StartLoggingNAVPermissions();
        LowerPermissions.SetExactPermissionSet('BIFROST PlaybVw ori');
        Assert.IsTrue(LowerPermissions.HasChangedPermissions(), 'Permissions must be lowered');
        // [WHEN] The viewer opens Playbooks.
        Playbooks.OpenView();
        // [THEN] Only the permitted tool is offered and can be opened.
        Assert.IsFalse(Playbooks.TableData.Visible(), 'Table Data must not be a dead action for viewers');
        Assert.IsTrue(Playbooks.CopyPlans.Visible(), 'Copy Plans remains available to viewers');
        CopyPlans.Trap();
        Playbooks.CopyPlans.Invoke();
        Assert.IsFalse(CopyPlans.Editable(), 'Copy Plans list remains read-only');
        CopyPlans.Close();
        Playbooks.Close();
        LowerPermissions.StopLoggingNAVPermissions();
    end;

    /// <summary>The admin role retains access to both tools.</summary>
    [Test]
    procedure Scenario_AC03_Admin_OpensBothTools()
    var
        LowerPermissions: Codeunit "Library - Lower Permissions";
    begin
        // Story #199, AC03 | Time: independent of Today/WorkDate | Risk: Permission mock must be active.
        LowerPermissions.StartLoggingNAVPermissions();
        LowerPermissions.SetExactPermissionSet('BIFROST PlaybAdm ori');
        Assert.IsTrue(LowerPermissions.HasChangedPermissions(), 'Permissions must be lowered');
        VerifyToolsNavigation(1033, false);
        LowerPermissions.StopLoggingNAVPermissions();
    end;

    local procedure VerifyToolsNavigation(LanguageId: Integer; FromSetup: Boolean)
    var
        Setup: TestPage "Setup ori";
        Playbooks: TestPage "Playbooks ori";
        TableData: TestPage "Table Data ori";
        CopyPlans: TestPage "Copy Plans ori";
        Instances: TestPage "Playbook Instances ori";
        PreviousLanguage: Integer;
    begin
        // [GIVEN] No selected playbook is needed for a table tool.
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        // [WHEN] Each action is invoked through the real page surface.
        if FromSetup then begin
            Setup.OpenView();
            TableData.Trap();
            Setup.TableData.Invoke();
            TableData.PageSizeField.AssertEquals(50);
            TableData.Close();
            CopyPlans.Trap();
            Setup.CopyPlans.Invoke();
            Assert.IsFalse(CopyPlans.Editable(), 'Copy Plans list opens');
            CopyPlans.Close();
            Playbooks.Trap();
            Setup.Playbooks.Invoke();
            Playbooks.Close();
            Instances.Trap();
            Setup.PlaybookInstances.Invoke();
            Instances.Close();
            Setup.Close();
        end else begin
            Playbooks.OpenView();
            Playbooks.Filter.SetFilter(Code, 'X199-NO-PLAYBOOK');
            Assert.IsFalse(Playbooks.First(), 'The navigation test uses an empty list');
            TableData.Trap();
            Playbooks.TableData.Invoke();
            // [THEN] The target starts with its normal empty table selection and default page size.
            TableData.PageSizeField.AssertEquals(50);
            TableData.Close();
            CopyPlans.Trap();
            Playbooks.CopyPlans.Invoke();
            Assert.IsFalse(CopyPlans.Editable(), 'Copy Plans list opens');
            CopyPlans.Close();
            Playbooks.Close();
        end;
        GlobalLanguage(PreviousLanguage);
    end;

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

    /// <summary>AC2.1: changing page size preserves navigation when exactly one row remains.</summary>
    [Test]
    procedure AC21_PageWithOneRemainingRow()
    var
        Marker: Record "Test Run Marker";
        TableData: TestPage "Table Data ori";
    begin
        DeleteMarkers();
        InsertMarker('TJP-ONE');
        InsertMarker('TJP-TWO');
        InsertMarker('TJP-THREE');
        Marker.SetFilter(Source, 'TJP-*');
        TableData.OpenEdit();
        TableData.TableViewField.SetValue(Marker.GetView(true));
        TableData.PageSizeField.SetValue(2);
        TableData.TableNoField.SetValue(Database::"Test Run Marker");
        Assert.IsTrue(TableData.NextPage.Enabled(), 'Exactly one row remains');
        TableData.NextPage.Invoke();
        Assert.AreEqual('2', TableData.PageNoField.Value(), 'Final page');
        Assert.IsTrue(TableData.First(), 'The final row is visible');
        Assert.IsFalse(TableData.NextPage.Enabled(), 'No further page');
        TableData.PreviousPage.Invoke();
        Assert.AreEqual('1', TableData.PageNoField.Value(), 'Return to first page');
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

    /// <summary>AC2.4: the fields page renders a write-restricted table read-only.</summary>
    [Test]
    [HandlerFunctions('ReadOnlyFieldHandler')]
    procedure AC24_RestrictedTablePageIsReadOnly()
    var
        Marker: Record "Test Run Marker";
        Restrictions: Codeunit "Library Orchestrator";
        FieldsPage: Page "Table Data Fields ori";
    begin
        DeleteMarkers();
        InsertMarker('TJP-READONLY');
        Marker.SetRange(Source, 'TJP-READONLY');
        Marker.FindFirst();
        Restrictions.SetTableDataRestrictions(false, true);
        BindSubscription(Restrictions);
        ReadOnlyFieldName := 'Source';
        FieldsPage.SetRecord(Database::"Test Run Marker", Marker.SystemId);
        FieldsPage.RunModal();
        UnbindSubscription(Restrictions);
        DeleteMarkers();
    end;

    /// <summary>AC2.4: the fields page renders a filled write-once field read-only.</summary>
    [Test]
    [HandlerFunctions('ReadOnlyFieldHandler')]
    procedure AC24_WriteOncePageIsReadOnly()
    var
        Child: Record "Test Copy Child ori";
        ChangeLogSetup: Record "Change Log Setup";
        Coverage: Record "Change Log Setup (Table)";
        Restrictions: Codeunit "Library Orchestrator";
        FieldsPage: Page "Table Data Fields ori";
        WasActivated: Boolean;
        CoverageAdded: Boolean;
    begin
        if not ChangeLogSetup.Get() then begin
            ChangeLogSetup.Init();
            ChangeLogSetup.Insert(true);
        end;
        WasActivated := ChangeLogSetup."Change Log Activated";
        ChangeLogSetup."Change Log Activated" := true;
        ChangeLogSetup.Modify(true);
        CoverageAdded := not Coverage.Get(Database::"Test Copy Child ori");
        if CoverageAdded then begin
            Coverage."Table No." := Database::"Test Copy Child ori";
            Coverage."Log Modification" := Coverage."Log Modification"::"All Fields";
            Coverage.Insert(true);
        end;
        Child.Code := 'TJP-ONCE';
        Child.Amount := 12;
        Child.Insert(true);
        Restrictions.SetCopyAmountWriteOnce(true);
        BindSubscription(Restrictions);
        ReadOnlyFieldName := 'Amount';
        FieldsPage.SetRecord(Database::"Test Copy Child ori", Child.SystemId);
        FieldsPage.RunModal();
        UnbindSubscription(Restrictions);
        Child.Delete(true);
        if CoverageAdded then
            Coverage.Delete(true);
        ChangeLogSetup.Get();
        ChangeLogSetup."Change Log Activated" := WasActivated;
        ChangeLogSetup.Modify(true);
    end;

    [ModalPageHandler]
    procedure ReadOnlyFieldHandler(var FieldsPage: TestPage "Table Data Fields ori")
    begin
        if ReadOnlyFieldName = 'Amount' then begin
            Assert.IsTrue(FieldsPage.FindFirstField("Field Name", 'Description'), 'Ordinary field is shown');
            Assert.IsTrue(FieldsPage.Value.Editable(), 'The table is writable; only the filled write-once field is closed');
        end;
        Assert.IsTrue(FieldsPage.FindFirstField("Field Name", ReadOnlyFieldName), 'Readable field is shown');
        Assert.IsFalse(FieldsPage.Value.Editable(), 'Restricted field is read-only');
        FieldsPage.OK().Invoke();
    end;

    /// <summary>AC2.5: page export and import share the Phase 1 envelope; dry run leaves data unchanged until confirmation.</summary>
    [Test]
    [HandlerFunctions('ImportConfirmHandler,ImportMessageHandler')]
    procedure AC25_PageImportConfirmsAfterDryRun()
    begin
        VerifyPageImport(true);
    end;

    /// <summary>AC2.5: declining the page import confirmation leaves the exported row unchanged.</summary>
    [Test]
    [HandlerFunctions('ImportConfirmHandler')]
    procedure AC25_PageImportCancellationDoesNotWrite()
    begin
        VerifyPageImport(false);
    end;

    [ConfirmHandler]
    procedure ImportConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        Marker: Record "Test Run Marker";
    begin
        Assert.IsTrue(Question.Contains('Dry run of 1 rows: 0 to insert, 1 to modify, 0 failed'), 'Dry-run counts are shown before import: ' + Question);
        Marker.GetBySystemId(ImportMarkerId);
        Assert.AreEqual('TJP-FILE', Marker.Source, 'No write before confirmation');
        Reply := ConfirmImport;
    end;

    [MessageHandler]
    procedure ImportMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(Message.Contains('0 rows inserted, 1 rows modified, 0 rows failed'), 'Import result is shown');
    end;

    local procedure VerifyPageImport(Confirmed: Boolean)
    var
        Marker: Record "Test Run Marker";
        ChangeLogSetup: Record "Change Log Setup";
        Coverage: Record "Change Log Setup (Table)";
        TableData: Page "Table Data ori";
        Envelope: JsonObject;
        Row: JsonObject;
        Fields: JsonObject;
        Rows: JsonArray;
        Token: JsonToken;
        WasActivated: Boolean;
        CoverageAdded: Boolean;
    begin
        DeleteMarkers();
        InsertMarker('TJP-FILE');
        Marker.SetRange(Source, 'TJP-FILE');
        Marker.FindFirst();
        ImportMarkerId := Marker.SystemId;
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
        TableData.SetTable(Database::"Test Run Marker", Marker.GetView(true));
        Envelope := TableData.ExportTableData();
        Envelope.Get('format', Token);
        Assert.AreEqual('bifrost-table-data', Token.AsValue().AsText(), 'Phase 1 export format');
        Envelope.Get('rows', Token);
        Rows := Token.AsArray();
        Assert.AreEqual(1, Rows.Count(), 'One exported row');
        Rows.Get(0, Token);
        Row := Token.AsObject();
        Row.Get('fields', Token);
        Fields := Token.AsObject();
        Fields.Replace('Source', 'TJP-IMPORTED');
        Row.Replace('fields', Fields);
        Rows.Set(0, Row);
        Envelope.Replace('rows', Rows);
        ConfirmImport := Confirmed;
        Assert.AreEqual(Confirmed, TableData.ImportTableData(Envelope), 'Confirmation controls import');
        Marker.GetBySystemId(ImportMarkerId);
        if Confirmed then
            Assert.AreEqual('TJP-IMPORTED', Marker.Source, 'Confirmed import persisted')
        else
            Assert.AreEqual('TJP-FILE', Marker.Source, 'Cancelled import did not persist');
        DeleteMarkers();
        if CoverageAdded then
            if Coverage.Get(Database::"Test Run Marker") then
                Coverage.Delete(true);
        ChangeLogSetup.Get();
        ChangeLogSetup."Change Log Activated" := WasActivated;
        ChangeLogSetup.Modify(true);
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
