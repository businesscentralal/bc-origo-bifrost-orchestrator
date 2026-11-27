namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.Reflection;
using System.TestLibraries.Utilities;

/// <summary>Issue #273: bilingual Bifröst navigation and configuration-only Setup.</summary>
codeunit 96467 "Overview Navigation Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    /// <summary>AC01/AC03: every Related action opens its destination in both languages.</summary>
    [Test]
    procedure AC01_RelatedActionsOpenTheirPages()
    begin
        VerifyNavigation(1033);
        VerifyNavigation(1039);
    end;

    /// <summary>AC01/AC03: Setup retains its configuration entry and contains no moved actions or Tools group.</summary>
    [Test]
    procedure AC03_SetupContainsOnlyConfiguration()
    var
        PageAction: Record "Page Action";
        Setup: TestPage "Setup ori";
        OrchestratorSetup: TestPage "Scheduler Setup ori";
    begin
        PageAction.SetRange("Page ID", Page::"Setup ori");
        PageAction.SetFilter(Name, 'Playbooks|Tools|PlaybookInstances|TableData|TableDataWorksheet|CopyTablesMapping|CopyPlans');
        Assert.IsTrue(PageAction.IsEmpty(), 'Moved operational actions must be absent from Setup metadata');
        Setup.OpenView();
        Assert.IsTrue(Setup.OrchestratorSetup.Enabled(), 'Setup retains its Orchestrator configuration entry');
        OrchestratorSetup.Trap();
        Setup.OrchestratorSetup.Invoke();
        Assert.IsTrue(OrchestratorSetup.Editable(), 'The configuration page opens');
        OrchestratorSetup.Close();
        Setup.Close();
    end;

    /// <summary>AC01/AC02: placement, captions and tooltips remain correct in both locales.</summary>
    [Test]
    procedure AC02_RelatedMetadataIsBilingualAndOrdered()
    begin
        VerifyMetadata(1033);
        VerifyMetadata(1039);
    end;

    /// <summary>AC01: a read user cannot bypass the existing setup permission through the new action.</summary>
    [Test]
    [TestPermissions(TestPermissions::Restrictive)]
    procedure AC01_ReadRoleCannotOpenSetup()
    var
        LowerPermissions: Codeunit "Library - Lower Permissions";
        Overview: TestPage "Bifrost ori";
    begin
        LowerPermissions.StartLoggingNAVPermissions();
        LowerPermissions.SetExactPermissionSet('LOGIN');
        LowerPermissions.AddPermissionSet('BIFROST Read ori');
        LowerPermissions.AddPermissionSet('Orch NoTools ori');
        Assert.IsTrue(LowerPermissions.HasChangedPermissions(), 'Test uses restricted permissions');
        Overview.OpenView();
        asserterror Overview.OrchestratorSetup.Invoke();
        Assert.IsTrue(GetLastErrorText() <> '', 'Setup permission is enforced');
        ClearLastError();
        Overview.Close();
        LowerPermissions.StopLoggingNAVPermissions();
    end;

    /// <summary>AC02: runtime help uses Bifröst for operations and preserves the setup path.</summary>
    [Test]
    procedure AC02_HelpDescribesNewNavigation()
    var
        Help: Codeunit "Help ori";
        Overview: Text;
        PreviousLanguage: Integer;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        Overview := Help.GetOverview();
        Assert.IsTrue(Overview.Contains('On **Bifröst**'), 'English overview entry');
        Assert.IsTrue(Overview.Contains('**Related > Bifrost Orchestrator Setup**'), 'English setup entry');
        Assert.IsFalse(Overview.Contains('On **Bifrost Setup**, open **Related > Bifrost Playbooks**'), 'No obsolete English path');
        GlobalLanguage(1039);
        Overview := Help.GetOverview();
        Assert.IsTrue(Overview.Contains('Á síðunni **Bifröst**'), 'Icelandic overview entry');
        Assert.IsTrue(Overview.Contains('**Tengt > Uppsetning Bifröst stjórnanda**'), 'Icelandic setup entry');
        Assert.IsFalse(Overview.Contains('Á síðunni **Uppsetning Bifröst** skaltu opna **Tengt > Bifröst keðjur**'), 'No obsolete Icelandic path');
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyNavigation(LanguageId: Integer)
    var
        Overview: TestPage "Bifrost ori";
        Setup: TestPage "Scheduler Setup ori";
        Playbooks: TestPage "Playbooks ori";
        Instances: TestPage "Playbook Instances ori";
        Management: TestPage "Table Data Management ori";
        Worksheet: TestPage "Table Data ori";
        Mapping: TestPage "Copy Tables Mapping ori";
        Plans: TestPage "Copy Plans ori";
        PreviousLanguage: Integer;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Overview.OpenView();
        Assert.IsFalse(Overview.Editable(), 'Overview remains read-only');
        Setup.Trap();
        Overview.OrchestratorSetup.Invoke();
        if LanguageId = 1033 then
            Assert.AreEqual('Bifrost Orchestrator Setup', Setup.Caption(), 'English setup caption')
        else
            Assert.AreEqual('Uppsetning Bifröst stjórnanda', Setup.Caption(), 'Icelandic setup caption');
        Setup.Close();
        Playbooks.Trap();
        Overview.Playbooks.Invoke();
        Playbooks.Filter.SetFilter(Code, 'X273-NO-PLAYBOOK');
        Assert.IsFalse(Playbooks.First(), 'Empty-list navigation does not require a playbook');
        Playbooks.Close();
        Instances.Trap();
        Overview.PlaybookInstances.Invoke();
        Instances.Close();
        Management.Trap();
        Overview.TableData.Invoke();
        Assert.IsTrue(Management.ShowAuditFieldsField.Visible(), 'Table Data opens the management page');
        Management.Close();
        Worksheet.Trap();
        Overview.TableDataWorksheet.Invoke();
        Worksheet.PageSizeField.AssertEquals(50);
        Worksheet.Close();
        Mapping.Trap();
        Overview.CopyTablesMapping.Invoke();
        Mapping.Close();
        Plans.Trap();
        Overview.CopyPlans.Invoke();
        Assert.IsFalse(Plans.Editable(), 'Copy Plans opens its read-only list');
        Plans.Close();
        Overview.Close();
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyMetadata(LanguageId: Integer)
    var
        FoundationSetupAction: Record "Page Action";
        SetupAction: Record "Page Action";
        PlaybooksAction: Record "Page Action";
        ToolsAction: Record "Page Action";
        PreviousLanguage: Integer;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        GetAction(FoundationSetupAction, 'BifrostSetup');
        GetAction(SetupAction, 'OrchestratorSetup');
        GetAction(PlaybooksAction, 'Playbooks');
        GetAction(ToolsAction, 'Tools');
        Assert.IsTrue(FoundationSetupAction."Action Index" < SetupAction."Action Index", 'Orchestrator setup follows Foundation setup');
        Assert.IsTrue(SetupAction."Action Index" < PlaybooksAction."Action Index", 'Playbooks follows Orchestrator setup');
        Assert.IsTrue(PlaybooksAction."Action Index" < ToolsAction."Action Index", 'Tools follows Playbooks');
        Assert.AreEqual(FoundationSetupAction."Parent Action ID", SetupAction."Parent Action ID", 'Both setup entries are in Related');
        Assert.AreEqual(SetupAction."Parent Action ID", PlaybooksAction."Parent Action ID", 'Playbooks is in the same menu');
        Assert.AreEqual(SetupAction."Parent Action ID", ToolsAction."Parent Action ID", 'Tools is in the same menu');
        Assert.AreEqual(Page::"Scheduler Setup ori", SetupAction.RunObjectID, 'Setup RunObject');
        if LanguageId = 1033 then begin
            Assert.AreEqual('Bifrost Orchestrator Setup', SetupAction.Caption, 'English setup action');
            Assert.AreEqual('Bifrost Playbooks', PlaybooksAction.Caption, 'English playbooks action');
            Assert.AreEqual('Tools', ToolsAction.Caption, 'English tools group');
            Assert.IsTrue(SetupAction.ToolTip1.StartsWith('Configure Bifrost Orchestrator:'), 'English setup tooltip');
        end else begin
            Assert.AreEqual('Uppsetning Bifröst stjórnanda', SetupAction.Caption, 'Icelandic setup action');
            Assert.AreEqual('Bifröst keðjur', PlaybooksAction.Caption, 'Icelandic playbooks action');
            Assert.AreEqual('Verkfæri', ToolsAction.Caption, 'Icelandic tools group');
            Assert.IsTrue(SetupAction.ToolTip1.StartsWith('Stilla Bifröst stjórnandann:'), 'Icelandic setup tooltip');
        end;
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure GetAction(var PageAction: Record "Page Action"; ActionName: Text)
    begin
        PageAction.SetRange("Page ID", Page::"Bifrost ori");
        PageAction.SetRange(Name, ActionName);
        Assert.IsTrue(PageAction.FindFirst(), 'Related action exists: ' + ActionName);
    end;
}
