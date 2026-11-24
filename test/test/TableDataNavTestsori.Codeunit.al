namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>Issue #268: Tools navigation, worksheet preservation, read-only access and bilingual help.</summary>
codeunit 96463 "Table Data Nav Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    /// <summary>AC01/AC02: Setup opens the management list and the distinct worksheet in both languages.</summary>
    [Test]
    procedure AC01_SetupOpensManagementAndWorksheet()
    begin
        VerifyNavigation(1033, true);
        VerifyNavigation(1039, true);
    end;

    /// <summary>AC01/AC02: an empty Playbooks list opens both tools without a selected record.</summary>
    [Test]
    procedure AC01_EmptyPlaybooksOpensManagementAndWorksheet()
    begin
        VerifyNavigation(1033, false);
        VerifyNavigation(1039, false);
    end;

    /// <summary>AC03: the table read role opens the action and exports an owned row without admin access.</summary>
    [Test]
    [TestPermissions(TestPermissions::Restrictive)]
    procedure AC03_ReadRoleOpensAndExports()
    var
        Marker: Record "Test Run Marker";
        TempFilter: Record "Table Data Edit ori" temporary;
        AccessTo: Record "Table Data Access ori";
        JsonMgt: Codeunit "Table Data JSON Mgt ori";
        LowerPermissions: Codeunit "Library - Lower Permissions";
        Playbooks: TestPage "Playbooks ori";
        Management: TestPage "Table Data Management ori";
        Rows: JsonArray;
    begin
        LowerPermissions.StartLoggingNAVPermissions();
        LowerPermissions.SetO365Basic();
        LowerPermissions.AddPermissionSet('BIFROST TblRead ori');
        // Parent-page access and the owned export fixture grant no table-management permissions.
        LowerPermissions.AddPermissionSet('Orch NoTools ori');
        LowerPermissions.AddPermissionSet('Orch TblDataT ori');
        Marker.Init();
        Marker.Source := 'X268-READ';
        Marker.Insert(true);
        Marker.SetRange(Source, Marker.Source);
        Assert.IsTrue(LowerPermissions.HasChangedPermissions(), 'Permissions are lowered');
        AccessTo.AssertReadAccess();
        asserterror AccessTo.AssertModifyAccess();
        Assert.ExpectedError('modify access');
        ClearLastError();
        Playbooks.OpenView();
        Assert.IsTrue(Playbooks.TableData.Visible(), 'Read role sees Table Data');
        Management.Trap();
        Playbooks.TableData.Invoke();
        Management.Filter.SetFilter(ID, Format(Database::"Test Run Marker", 0, 9));
        Assert.IsTrue(Management.First(), 'Owned table is listed');
        Assert.IsTrue(Management.ExportRecordsJSONAction.Visible(), 'Read role sees JSON export');
        Assert.IsFalse(Management.EditRecords.Enabled(), 'Read role cannot edit');
        Rows := JsonMgt.ExportRows(Database::"Test Run Marker", false, Marker.GetView(false), TempFilter);
        Assert.AreEqual(1, Rows.Count(), 'Read role exports exactly its owned row');
        Management.Close();
        asserterror Playbooks.TableDataWorksheet.Invoke();
        Assert.ExpectedError('The action with ID');
        ClearLastError();
        Playbooks.Close();
        LowerPermissions.StopLoggingNAVPermissions();
        Marker.Delete(true);
    end;

    /// <summary>AC03: parent-page access alone neither exposes the tool nor permits export.</summary>
    [Test]
    [TestPermissions(TestPermissions::Restrictive)]
    procedure AC03_NoReadRoleRefusesActionAndExport()
    var
        TempFilter: Record "Table Data Edit ori" temporary;
        AccessTo: Record "Table Data Access ori";
        JsonMgt: Codeunit "Table Data JSON Mgt ori";
        LowerPermissions: Codeunit "Library - Lower Permissions";
        Playbooks: TestPage "Playbooks ori";
    begin
        LowerPermissions.StartLoggingNAVPermissions();
        LowerPermissions.SetExactPermissionSet('LOGIN');
        LowerPermissions.AddPermissionSet('Orch NoTools ori');
        Assert.IsTrue(LowerPermissions.HasChangedPermissions(), 'Permissions are lowered');
        Assert.IsFalse(AccessTo.ReadPermission(), 'No table-data access');
        Playbooks.OpenView();
        asserterror Playbooks.TableData.Invoke();
        Assert.ExpectedError('The action with ID');
        ClearLastError();
        Playbooks.Close();
        asserterror JsonMgt.ExportRows(Database::"Test Run Marker", false, '', TempFilter);
        Assert.IsTrue(GetLastErrorText() <> '', 'Export is refused');
        ClearLastError();
        LowerPermissions.StopLoggingNAVPermissions();
    end;

    /// <summary>AC04: both help languages describe the new target, read role and separate worksheet.</summary>
    [Test]
    procedure AC04_HelpDescribesBothToolsAndReadRole()
    var
        Help: Codeunit "Help ori";
        Overview: Text;
        PreviousLanguage: Integer;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        Overview := Help.GetOverview();
        Assert.IsTrue(Overview.Contains('**Table Data** opens **Table Data Management**'), 'English target');
        Assert.IsTrue(Overview.Contains('**BIFROST TblRead ori** grants view and export'), 'English read role');
        Assert.IsTrue(Overview.Contains('**Table Data Worksheet** opens the original single-table worksheet'), 'English worksheet');
        Assert.IsFalse(Overview.Contains('**Table Data** requires **Bifrost Playbook Admin**'), 'No stale English restriction');
        GlobalLanguage(1039);
        Overview := Help.GetOverview();
        Assert.IsTrue(Overview.Contains('**Töflugögn** opna **Vinna með töflugögn**'), 'Icelandic target');
        Assert.IsTrue(Overview.Contains('**BIFROST TblRead ori** veitir skoðunar- og útflutningsheimildir'), 'Icelandic read role');
        Assert.IsTrue(Overview.Contains('**Vinnublað töflugagna** opnar upphaflega vinnublaðið'), 'Icelandic worksheet');
        Assert.IsFalse(Overview.Contains('**Töflugögn** krefjast heimildasamstæðunnar'), 'No stale Icelandic restriction');
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyNavigation(LanguageId: Integer; FromSetup: Boolean)
    var
        Setup: TestPage "Setup ori";
        Playbooks: TestPage "Playbooks ori";
        Management: TestPage "Table Data Management ori";
        Worksheet: TestPage "Table Data ori";
        PreviousLanguage: Integer;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        if FromSetup then
            Setup.OpenView()
        else begin
            Playbooks.OpenView();
            Playbooks.Filter.SetFilter(Code, 'X268-NO-PLAYBOOK');
            Assert.IsFalse(Playbooks.First(), 'Empty-list edge case');
        end;
        Management.Trap();
        if FromSetup then
            Setup.TableData.Invoke()
        else
            Playbooks.TableData.Invoke();
        if LanguageId = 1033 then
            Assert.AreEqual('Table Data Management', Management.Caption(), 'Management page 10035627')
        else
            Assert.AreEqual('Vinna með töflugögn', Management.Caption(), 'Management page 10035627');
        Assert.IsTrue(Management.ShowAuditFieldsField.Visible(), 'Audit option');
        Assert.IsTrue(Management.TempFilterCreatedAfterField.Visible(), 'Created after');
        Assert.IsTrue(Management.TempFilterCreatedUpToField.Visible(), 'Created up to');
        Assert.IsTrue(Management.TempFilterModifiedAfterField.Visible(), 'Modified after');
        Assert.IsTrue(Management.TempFilterModifiedUpToField.Visible(), 'Modified up to');
        Management.Close();
        Worksheet.Trap();
        if FromSetup then
            Setup.TableDataWorksheet.Invoke()
        else
            Playbooks.TableDataWorksheet.Invoke();
        Worksheet.PageSizeField.AssertEquals(50);
        Worksheet.Close();
        if FromSetup then
            Setup.Close()
        else
            Playbooks.Close();
        GlobalLanguage(PreviousLanguage);
    end;
}
