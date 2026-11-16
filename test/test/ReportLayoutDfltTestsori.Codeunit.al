namespace Origo.Bifrost.Orchestrator.Test;

using Microsoft.Foundation.Reporting;
using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.Environment.Configuration;
using System.Reflection;
using System.TestLibraries.Utilities;

/// <summary>
/// Checks setAsDefault and clearDefault on Orchestrator.ReportLayout.Set (#197) on the owned sample report.
/// Every test creates its own user layouts and removes them and the sample report's default selection again.
/// </summary>
codeunit 96494 "Report Layout Dflt Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        DispatchHelper: Codeunit "Orch Dispatch Helper ori";
        Assert: Codeunit "Library Assert";

    /// <summary>An imported layout sent with setAsDefault becomes the company default (AC01).</summary>
    [Test]
    procedure ImportWithSetAsDefaultMakesLayoutDefault()
    var
        TenantSelection: Record "Tenant Report Layout Selection";
        LayoutSelection: Record "Report Layout Selection";
        Fixture: Record "Report Layout List";
        Request: JsonObject;
        Response: JsonObject;
        LayoutName: Text[250];
        EmptyGuid: Guid;
    begin
        // [GIVEN] The sample report with its built-in default and no company selection
        ResetDefault();
        FindFixture(Fixture);
        LayoutName := NewName('XDEF-IMP-');
        // [WHEN] A user layout is imported with setAsDefault
        Request := ImportRequest(LayoutName);
        Request.Add('setAsDefault', true);
        Response := Execute(Request);
        // [THEN] It is created, reported as default, and the previous default is the built-in one
        Assert.AreEqual('Created', GetText(Response, 'action'), 'Created');
        Assert.IsTrue(GetBool(Response, 'isDefault'), 'isDefault');
        Assert.AreEqual(Fixture.Name, GetText(Response, 'previousDefault'), 'Previous default is the built-in layout');
        Assert.AreEqual(Format(Fixture."Application ID", 0, 4), GetText(Response, 'previousDefaultAppId'), 'Previous default app');
        // [THEN] The same selection rows the Report Layouts page writes exist for the current company
        Assert.IsTrue(TenantSelection.Get(Report::"Layout Sample Report ori", CompanyName(), EmptyGuid), 'Company selection row');
        Assert.AreEqual(LayoutName, TenantSelection."Layout Name", 'Selected layout');
        Assert.IsTrue(IsNullGuid(TenantSelection."App ID"), 'User-defined layout has no app');
        Assert.IsTrue(LayoutSelection.Get(Report::"Layout Sample Report ori", CompanyName()), 'Report Layout Selection row');
        Assert.AreEqual(LayoutSelection.Type::"RDLC (built-in)", LayoutSelection.Type, 'RDLC selection type');
        // [THEN] List agrees
        Assert.IsTrue(ListIsDefault(LayoutName, EmptyGuid), 'List marks the new layout default');
        Assert.IsFalse(ListIsDefault(Fixture.Name, Fixture."Application ID"), 'Built-in layout no longer default');
        Cleanup(LayoutName);
    end;

    /// <summary>Without a layout file, setAsDefault selects an existing extension layout by name and appId (AC01).</summary>
    [Test]
    procedure SetAsDefaultSelectsExistingExtensionLayout()
    var
        Fixture: Record "Report Layout List";
        Request: JsonObject;
        Response: JsonObject;
        LayoutName: Text[250];
        EmptyGuid: Guid;
    begin
        // [GIVEN] A user layout that is the company default
        ResetDefault();
        FindFixture(Fixture);
        LayoutName := NewName('XDEF-SEL-');
        Request := ImportRequest(LayoutName);
        Request.Add('setAsDefault', true);
        Execute(Request);
        // [WHEN] The extension layout is selected again without a file or layoutFormat
        Clear(Request);
        Request.Add('reportId', Report::"Layout Sample Report ori");
        Request.Add('name', Fixture.Name);
        Request.Add('appId', Format(Fixture."Application ID", 0, 4));
        Request.Add('setAsDefault', true);
        Response := Execute(Request);
        // [THEN] DefaultSet, previous default is the user layout, and List agrees
        Assert.AreEqual('DefaultSet', GetText(Response, 'action'), 'DefaultSet');
        Assert.AreEqual('RDLC', GetText(Response, 'layoutFormat'), 'Format of the selected layout');
        Assert.AreEqual(LayoutName, GetText(Response, 'previousDefault'), 'Previous default');
        Assert.AreEqual(Format(EmptyGuid, 0, 4), GetText(Response, 'previousDefaultAppId'), 'Previous default is user-defined');
        Assert.IsTrue(ListIsDefault(Fixture.Name, Fixture."Application ID"), 'Extension layout default');
        Assert.IsFalse(ListIsDefault(LayoutName, EmptyGuid), 'User layout no longer default');
        // [THEN] The name alone is enough when it is unique on the report
        Request.Remove('appId');
        Request.Replace('name', LayoutName);
        Response := Execute(Request);
        Assert.AreEqual('DefaultSet', GetText(Response, 'action'), 'Unique name without appId');
        Assert.IsTrue(ListIsDefault(LayoutName, EmptyGuid), 'User layout default again');
        Cleanup(LayoutName);
    end;

    /// <summary>clearDefault removes the company selection so the built-in default applies; a second call changes nothing (AC02).</summary>
    [Test]
    procedure ClearDefaultFallsBackToBuiltInDefault()
    var
        TenantSelection: Record "Tenant Report Layout Selection";
        Fixture: Record "Report Layout List";
        Request: JsonObject;
        Response: JsonObject;
        LayoutName: Text[250];
        EmptyGuid: Guid;
    begin
        // [GIVEN] A user layout that is the company default
        ResetDefault();
        FindFixture(Fixture);
        LayoutName := NewName('XDEF-CLR-');
        Request := ImportRequest(LayoutName);
        Request.Add('setAsDefault', true);
        Execute(Request);
        // [WHEN] The default is cleared with reportId only
        Clear(Request);
        Request.Add('reportId', Report::"Layout Sample Report ori");
        Request.Add('clearDefault', true);
        Response := Execute(Request);
        // [THEN] The selection row is gone and the built-in layout is reported and listed as default
        Assert.AreEqual('DefaultCleared', GetText(Response, 'action'), 'DefaultCleared');
        Assert.AreEqual(Fixture.Name, GetText(Response, 'name'), 'Built-in default named');
        Assert.AreEqual(LayoutName, GetText(Response, 'previousDefault'), 'Previous default');
        Assert.IsFalse(TenantSelection.Get(Report::"Layout Sample Report ori", CompanyName(), EmptyGuid), 'Selection removed');
        Assert.IsTrue(ListIsDefault(Fixture.Name, Fixture."Application ID"), 'Built-in default applies');
        Assert.IsTrue(LayoutExists(LayoutName), 'The layout itself is kept');
        // [THEN] Clearing again is a no-op
        Response := Execute(Request);
        Assert.AreEqual('NoChange', GetText(Response, 'action'), 'Nothing to clear');
        Cleanup(LayoutName);
    end;

    /// <summary>Invalid combinations and unknown layouts are refused and change no selection (invalid input).</summary>
    [Test]
    procedure InvalidDefaultRequestsAreRefusedWithoutChange()
    var
        TenantSelection: Record "Tenant Report Layout Selection";
        Request: JsonObject;
        LayoutName: Text[250];
        EmptyGuid: Guid;
        NestedValue: JsonObject;
    begin
        ResetDefault();
        LayoutName := NewName('XDEF-BAD-');
        // Both flags
        Request := SelectRequest(LayoutName);
        Request.Add('clearDefault', true);
        asserterror Execute(Request);
        Assert.ExpectedError('not both');
        // clearDefault with a file
        Request := ImportRequest(LayoutName);
        Request.Add('clearDefault', true);
        asserterror Execute(Request);
        Assert.ExpectedError('without "layoutBase64" or "stagingId"');
        // appId with a file
        Request := ImportRequest(LayoutName);
        Request.Add('appId', Format(EmptyGuid, 0, 4));
        Request.Add('setAsDefault', true);
        asserterror Execute(Request);
        Assert.ExpectedError('only with "setAsDefault" and no layout file');
        // Unknown layout
        asserterror Execute(SelectRequest(LayoutName));
        Assert.ExpectedError('not found on report');
        // Malformed appId
        Request := SelectRequest(LayoutName);
        Request.Add('appId', 'not-a-guid');
        asserterror Execute(Request);
        Assert.ExpectedError('is not a valid GUID');
        // Not a boolean
        Request := SelectRequest(LayoutName);
        Request.Replace('setAsDefault', NestedValue);
        asserterror Execute(Request);
        Assert.ExpectedError('must be true or false');
        // Nothing changed
        Assert.IsFalse(TenantSelection.Get(Report::"Layout Sample Report ori", CompanyName(), EmptyGuid), 'No selection written');
        Assert.IsFalse(LayoutExists(LayoutName), 'Nothing imported');
    end;

    /// <summary>A layout limited to another company cannot become the default here; nothing is imported (edge case).</summary>
    [Test]
    procedure OtherCompanyLayoutCannotBecomeDefault()
    var
        TenantSelection: Record "Tenant Report Layout Selection";
        Request: JsonObject;
        LayoutName: Text[250];
        EmptyGuid: Guid;
    begin
        ResetDefault();
        LayoutName := NewName('XDEF-CMP-');
        Request := ImportRequest(LayoutName);
        Request.Add('companyName', 'XDEF OTHER COMPANY');
        Request.Add('setAsDefault', true);
        asserterror Execute(Request);
        Assert.ExpectedError('belongs to company XDEF OTHER COMPANY');
        Assert.IsFalse(LayoutExists(LayoutName), 'Nothing imported');
        Assert.IsFalse(TenantSelection.Get(Report::"Layout Sample Report ori", CompanyName(), EmptyGuid), 'No selection written');
    end;

    /// <summary>Without setAsDefault an import leaves the default alone and reports isDefault false (unchanged behaviour).</summary>
    [Test]
    procedure ImportWithoutSetAsDefaultKeepsDefault()
    var
        Fixture: Record "Report Layout List";
        Response: JsonObject;
        LayoutName: Text[250];
    begin
        ResetDefault();
        FindFixture(Fixture);
        LayoutName := NewName('XDEF-KEEP-');
        Response := Execute(ImportRequest(LayoutName));
        Assert.AreEqual('Created', GetText(Response, 'action'), 'Created');
        Assert.IsFalse(GetBool(Response, 'isDefault'), 'Not default');
        Assert.IsFalse(Response.Contains('previousDefault'), 'No previous default without setAsDefault');
        Assert.IsTrue(ListIsDefault(Fixture.Name, Fixture."Application ID"), 'Built-in default unchanged');
        Cleanup(LayoutName);
    end;

    /// <summary>An all-companies selection (blank Company Name) is the default when the company has none; clearDefault falls back to it (edge case).</summary>
    [Test]
    procedure AllCompaniesSelectionIsTheFallbackDefault()
    var
        TenantSelection: Record "Tenant Report Layout Selection";
        Fixture: Record "Report Layout List";
        Request: JsonObject;
        Response: JsonObject;
        LayoutName: Text[250];
        EmptyGuid: Guid;
    begin
        // [GIVEN] A user layout chosen for all companies, no company selection
        ResetDefault();
        FindFixture(Fixture);
        LayoutName := NewName('XDEF-ALL-');
        Execute(ImportRequest(LayoutName));
        TenantSelection.Init();
        TenantSelection."Report ID" := Report::"Layout Sample Report ori";
        TenantSelection."Company Name" := '';
        TenantSelection."User ID" := EmptyGuid;
        TenantSelection."Layout Name" := LayoutName;
        TenantSelection.Insert();
        // [THEN] List reports it as default
        Assert.IsTrue(ListIsDefault(LayoutName, EmptyGuid), 'All-companies selection is the default');
        // [WHEN] The extension layout is chosen for this company, then cleared again
        Request := SelectRequest(Fixture.Name);
        Request.Add('appId', Format(Fixture."Application ID", 0, 4));
        Response := Execute(Request);
        Assert.AreEqual(LayoutName, GetText(Response, 'previousDefault'), 'Previous default is the all-companies selection');
        Clear(Request);
        Request.Add('reportId', Report::"Layout Sample Report ori");
        Request.Add('clearDefault', true);
        Response := Execute(Request);
        // [THEN] The all-companies selection applies again and is kept
        Assert.AreEqual('DefaultCleared', GetText(Response, 'action'), 'Company selection cleared');
        Assert.AreEqual(LayoutName, GetText(Response, 'name'), 'All-companies selection applies');
        Assert.IsTrue(TenantSelection.Get(Report::"Layout Sample Report ori", '', EmptyGuid), 'All-companies row kept');
        TenantSelection.Delete();
        Cleanup(LayoutName);
    end;

    /// <summary>The refusal and the effect help are translated in 1039 and stay English in 1033 (AC03).</summary>
    [Test]
    procedure DefaultTextsInEnglishAndIcelandic()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Layout Handler ori";
        ContractType: Interface "Msg Contract ori";
        Contract: JsonObject;
        Token: JsonToken;
        Request: JsonObject;
        LayoutName: Text[250];
        OriginalLanguage: Integer;
    begin
        ResetDefault();
        OriginalLanguage := GlobalLanguage();
        LayoutName := NewName('XDEF-LNG-');
        Request := SelectRequest(LayoutName);
        Request.Add('clearDefault', true);
        TempArgument.Init();
        TempArgument.Insert();
        TempArgument.SetRequestJson(Request);
        // The dispatcher applies the request's lcid; the handler is called directly so GlobalLanguage decides.
        GlobalLanguage(1033);
        asserterror Handler.ExecuteSet(TempArgument);
        Assert.ExpectedError('Send either "setAsDefault" or "clearDefault", not both.');
        ContractType := "Message Type ori"::"Orchestrator.ReportLayout.Set";
        Assert.IsTrue(ContractType.GetEffect(Contract), 'Effect chapter 1033');
        Contract.Get('changes', Token);
        Assert.IsTrue(Token.AsValue().AsText().Contains('With setAsDefault, the layout becomes the default'), 'English effect text');
        GlobalLanguage(1039);
        asserterror Handler.ExecuteSet(TempArgument);
        Assert.ExpectedError('Sendu annaðhvort "setAsDefault" eða "clearDefault", ekki bæði.');
        Clear(Contract);
        Assert.IsTrue(ContractType.GetEffect(Contract), 'Effect chapter 1039');
        Contract.Get('changes', Token);
        Assert.IsTrue(Token.AsValue().AsText().Contains('Með setAsDefault verður útlitið sjálfgefið'), 'Icelandic effect text');
        GlobalLanguage(OriginalLanguage);
    end;

    local procedure ImportRequest(LayoutName: Text) Request: JsonObject
    begin
        Request.Add('reportId', Report::"Layout Sample Report ori");
        Request.Add('name', LayoutName);
        Request.Add('layoutFormat', 'RDLC');
        Request.Add('layoutBase64', ExportFixture());
    end;

    local procedure SelectRequest(LayoutName: Text) Request: JsonObject
    begin
        Request.Add('reportId', Report::"Layout Sample Report ori");
        Request.Add('name', LayoutName);
        Request.Add('setAsDefault', true);
    end;

    local procedure Execute(Request: JsonObject): JsonObject
    var
        TempArgument: Record "Message Argument ori" temporary;
    begin
        TempArgument.Init();
        TempArgument.Insert();
        TempArgument.SetRequestJson(Request);
        DispatchHelper.Execute("Message Type ori"::"Orchestrator.ReportLayout.Set", TempArgument);
        exit(TempArgument.GetResponseJson());
    end;

    local procedure FindFixture(var Fixture: Record "Report Layout List")
    begin
        Fixture.SetRange("Report ID", Report::"Layout Sample Report ori");
        Fixture.SetRange("User Defined", false);
        Fixture.SetLoadFields(Name, "Application ID");
        Assert.IsTrue(Fixture.FindFirst(), 'Own installed sample report layout exists');
    end;

    local procedure ExportFixture(): Text
    var
        Fixture: Record "Report Layout List";
        TempArgument: Record "Message Argument ori" temporary;
        Request: JsonObject;
        Value: JsonToken;
    begin
        FindFixture(Fixture);
        Request.Add('reportId', Report::"Layout Sample Report ori");
        Request.Add('name', Fixture.Name);
        Request.Add('appId', Format(Fixture."Application ID", 0, 4));
        TempArgument.Init();
        TempArgument.Insert();
        TempArgument.SetRequestJson(Request);
        DispatchHelper.Execute("Message Type ori"::"Orchestrator.ReportLayout.Get", TempArgument);
        Assert.IsTrue(TempArgument.GetResponseJson().Get('layoutBase64', Value), 'Exported layout');
        exit(Value.AsValue().AsText());
    end;

    local procedure ListIsDefault(LayoutName: Text; AppId: Guid): Boolean
    var
        TempArgument: Record "Message Argument ori" temporary;
        Request: JsonObject;
        Layouts: JsonToken;
        Item: JsonToken;
        Value: JsonToken;
        AppValue: JsonToken;
    begin
        Request.Add('reportId', Report::"Layout Sample Report ori");
        TempArgument.Init();
        TempArgument.Insert();
        TempArgument.SetRequestJson(Request);
        DispatchHelper.Execute("Message Type ori"::"Orchestrator.ReportLayout.List", TempArgument);
        Assert.IsTrue(TempArgument.GetResponseJson().Get('layouts', Layouts), 'Layouts listed');
        foreach Item in Layouts.AsArray() do begin
            Item.AsObject().Get('name', Value);
            Item.AsObject().Get('appId', AppValue);
            if (Value.AsValue().AsText() = LayoutName) and (AppValue.AsValue().AsText() = Format(AppId, 0, 4)) then begin
                Item.AsObject().Get('isDefault', Value);
                exit(Value.AsValue().AsBoolean());
            end;
        end;
        Assert.Fail('Layout ' + LayoutName + ' not listed');
    end;

    local procedure NewName(Prefix: Text): Text[250]
    begin
        exit(CopyStr(Prefix + Format(CreateGuid(), 0, 4), 1, 250));
    end;

    local procedure GetText(Response: JsonObject; KeyName: Text): Text
    var
        Value: JsonToken;
    begin
        Assert.IsTrue(Response.Get(KeyName, Value), KeyName + ' present in ' + Format(Response));
        exit(Value.AsValue().AsText());
    end;

    local procedure GetBool(Response: JsonObject; KeyName: Text): Boolean
    var
        Value: JsonToken;
    begin
        Assert.IsTrue(Response.Get(KeyName, Value), KeyName + ' present in ' + Format(Response));
        exit(Value.AsValue().AsBoolean());
    end;

    local procedure LayoutExists(LayoutName: Text): Boolean
    var
        TenantLayout: Record "Tenant Report Layout";
        EmptyGuid: Guid;
    begin
        exit(TenantLayout.Get(Report::"Layout Sample Report ori", CopyStr(LayoutName, 1, MaxStrLen(TenantLayout.Name)), EmptyGuid));
    end;

    local procedure ResetDefault()
    var
        TenantSelection: Record "Tenant Report Layout Selection";
        LayoutSelection: Record "Report Layout Selection";
        EmptyGuid: Guid;
    begin
        if TenantSelection.Get(Report::"Layout Sample Report ori", CompanyName(), EmptyGuid) then
            TenantSelection.Delete();
        if LayoutSelection.Get(Report::"Layout Sample Report ori", CompanyName()) then
            LayoutSelection.Delete();
    end;

    local procedure Cleanup(LayoutName: Text)
    var
        TenantLayout: Record "Tenant Report Layout";
        EmptyGuid: Guid;
    begin
        ResetDefault();
        if TenantLayout.Get(Report::"Layout Sample Report ori", CopyStr(LayoutName, 1, MaxStrLen(TenantLayout.Name)), EmptyGuid) then
            TenantLayout.Delete(true);
    end;
}
