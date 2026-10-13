namespace Origo.Bifrost.Orchestrator.Test;

using Microsoft.Foundation.Reporting;
using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.Environment.Configuration;
using System.Reflection;
using System.TestLibraries.Utilities;

/// <summary>Checks report layout listing and export using an installed sample report and self-created layout data.</summary>
codeunit 96409 "Report Layout Read Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    /// <summary>List returns the sample report's installed layout, with export identity and default metadata.</summary>
    [Test]
    procedure ListIncludesExtensionLayout()
    var
        Response: JsonObject;
        Request: JsonObject;
        Value: JsonToken;
        Layout: JsonToken;
    begin
        Request.Add('reportId', Report::"Layout Sample Report ori");
        Response := Execute("Message Type ori"::"Orchestrator.ReportLayout.List", Request);
        Assert.IsTrue(Response.Get('layouts', Value), 'Layouts array');
        Assert.IsTrue(Value.AsArray().Count() > 0, 'Installed sample layout');
        Value.AsArray().Get(0, Layout);
        Assert.IsTrue(Layout.AsObject().Contains('appId'), 'Export identity');
        Assert.IsTrue(Layout.AsObject().Contains('isDefault'), 'Default metadata');
        Assert.IsTrue(Layout.AsObject().Contains('layoutStatus'), 'Layout status');
    end;

    /// <summary>List can exclude extension layouts without changing report metadata.</summary>
    [Test]
    procedure ListExcludesExtensionLayouts()
    var
        Response: JsonObject;
        Request: JsonObject;
        Value: JsonToken;
        Layout: JsonToken;
        UserDefined: JsonToken;
    begin
        Request.Add('reportId', Report::"Layout Sample Report ori");
        Request.Add('includeExtensionLayouts', false);
        Response := Execute("Message Type ori"::"Orchestrator.ReportLayout.List", Request);
        Response.Get('layouts', Value);
        foreach Layout in Value.AsArray() do begin
            Layout.AsObject().Get('userDefined', UserDefined);
            Assert.IsTrue(UserDefined.AsValue().AsBoolean(), 'Extension layouts excluded');
        end;
    end;

    /// <summary>Exports the extension's actual RDLC bytes through the registered message implementation.</summary>
    [Test]
    procedure GetExportsExtensionBytes()
    var
        Layout: Record "Report Layout List";
        Request: JsonObject;
        Response: JsonObject;
        Value: JsonToken;
    begin
        FindSampleLayout(Layout);
        Request := GetLayoutRequest(Layout.Name, Layout."Application ID");
        Response := Execute("Message Type ori"::"Orchestrator.ReportLayout.Get", Request);
        Assert.IsTrue(Response.Get('layoutBase64', Value), 'Base64 bytes');
        Assert.AreNotEqual('', Value.AsValue().AsText(), 'Nonempty sample layout bytes');
        Response.Get('format', Value);
        Assert.AreEqual('RDLC', Value.AsValue().AsText(), 'Sample format');
    end;

    /// <summary>Creates a user layout through the existing Set path, lists and exports it exactly, then deletes it.</summary>
    [Test]
    procedure OwnUserLayoutRoundTripsBytes()
    var
        Layout: Record "Report Layout List";
        TenantLayout: Record "Tenant Report Layout";
        Request: JsonObject;
        Response: JsonObject;
        Value: JsonToken;
        Item: JsonToken;
        NameValue: JsonToken;
        Exported: Text;
        FixtureName: Text[250];
        EmptyGuid: Guid;
        Found: Boolean;
    begin
        FindSampleLayout(Layout);
        Response := Execute("Message Type ori"::"Orchestrator.ReportLayout.Get", GetLayoutRequest(Layout.Name, Layout."Application ID"));
        Response.Get('layoutBase64', Value);
        Exported := Value.AsValue().AsText();
        FixtureName := CopyStr('XLAYOUT-' + Format(CreateGuid(), 0, 4), 1, MaxStrLen(FixtureName));
        Request := GetLayoutRequest(FixtureName, EmptyGuid);
        Request.Add('layoutFormat', 'RDLC');
        Request.Add('layoutBase64', Exported);
        Execute("Message Type ori"::"Orchestrator.ReportLayout.Set", Request);
        Response := Execute("Message Type ori"::"Orchestrator.ReportLayout.Get", GetLayoutRequest(FixtureName, EmptyGuid));
        Response.Get('layoutBase64', Value);
        Assert.AreEqual(Exported, Value.AsValue().AsText(), 'User layout bytes unchanged');
        Clear(Request);
        Request.Add('reportId', Report::"Layout Sample Report ori");
        Request.Add('includeExtensionLayouts', false);
        Response := Execute("Message Type ori"::"Orchestrator.ReportLayout.List", Request);
        Response.Get('layouts', Value);
        foreach Item in Value.AsArray() do begin
            Item.AsObject().Get('name', NameValue);
            if NameValue.AsValue().AsText() = FixtureName then
                Found := true;
        end;
        Assert.IsTrue(Found, 'Own user layout listed');
        TenantLayout.Get(Report::"Layout Sample Report ori", FixtureName, EmptyGuid);
        TenantLayout.Delete(true);
        Assert.IsFalse(TenantLayout.Get(Report::"Layout Sample Report ori", FixtureName, EmptyGuid), 'Owned fixture deleted');
    end;

    /// <summary>Rejects an unknown report before looking for layouts.</summary>
    [Test]
    procedure ListRejectsUnknownReport()
    var
        Request: JsonObject;
    begin
        Request.Add('reportId', 999999999);
        asserterror Execute("Message Type ori"::"Orchestrator.ReportLayout.List", Request);
        Assert.ExpectedError('999999999');
    end;

    /// <summary>Rejects a missing layout without falling back to the default.</summary>
    [Test]
    procedure GetRejectsUnknownLayout()
    var
        EmptyGuid: Guid;
    begin
        asserterror Execute("Message Type ori"::"Orchestrator.ReportLayout.Get", GetLayoutRequest('XNONEXISTENT', EmptyGuid));
        Assert.ExpectedError('XNONEXISTENT');
    end;

    /// <summary>The selected layout is visible during execution and the prior session and saved preset survive.</summary>
    [Test]
    procedure SaveAsOverrideRestoresSessionAndPreset()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Preset: Record "Report Request Preset ori";
        Layout: Record "Report Layout List";
        Selection: Codeunit "Design-time Report Selection";
        Implementation: Codeunit "Report SaveAs Msg ori";
        Content: InStream;
        XmlText: Text;
        XmlContent: XmlDocument;
        SelectedColumn: XmlNode;
        PriorAppId: Guid;
    begin
        FindSampleLayout(Layout);
        Preset.Init();
        Preset."Report ID" := Report::"Layout Sample Report ori";
        Preset."User Security ID" := UserSecurityId();
        Preset.Insert();
        Preset.SetRequestPageXml('<owned-saved-settings/>');
        Preset.Modify();
        PriorAppId := CreateGuid();
        Selection.ClearLayoutSelection();
        Selection.SetSelectedLayout('OWN-PRIOR', PriorAppId);
        Selection.SetSelectedCustomLayout('OWN-CUSTOM');
        CreateSaveArgument(TempArgument, Layout, 'XML', 1);
        Implementation.ExecuteBifrostTask(TempArgument);
        Assert.AreEqual('OWN-PRIOR', Selection.GetSelectedLayout(), 'Prior platform selection restored');
        Assert.AreEqual(PriorAppId, Selection.GetSelectedAppID(), 'Prior app identity restored');
        Assert.AreEqual('OWN-CUSTOM', Selection.GetSelectedCustomLayout(), 'Prior custom selection restored');
        Selection.ClearLayoutSelection();
        Preset.Get(Report::"Layout Sample Report ori", UserSecurityId());
        Assert.AreEqual('<owned-saved-settings/>', Preset.GetRequestPageXml(), 'Saved preset not rewritten');
        Preset.Delete();
        TempArgument.CalcFields("Response Content");
        TempArgument."Response Content".CreateInStream(Content);
        XmlDocument.ReadFrom(Content, XmlContent);
        XmlContent.WriteTo(XmlText);
        Assert.IsTrue(XmlContent.SelectSingleNode('//*[@name="SelectedLayoutName"]', SelectedColumn), 'Selection column in report XML: ' + XmlText);
        Assert.AreEqual(Layout.Name, SelectedColumn.AsXmlElement().InnerText(), 'Report execution observed the requested layout');
    end;

    /// <summary>A real RDLC render produces PDF bytes while preserving a custom-only prior selection.</summary>
    [Test]
    procedure SaveAsOverrideRendersPdf()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Layout: Record "Report Layout List";
        Selection: Codeunit "Design-time Report Selection";
        Implementation: Codeunit "Report SaveAs Msg ori";
        Content: InStream;
        Header: Text;
    begin
        FindSampleLayout(Layout);
        Selection.ClearLayoutSelection();
        Selection.SetSelectedCustomLayout('OWN-CUSTOM');
        CreateSaveArgument(TempArgument, Layout, 'PDF', 1);
        Implementation.ExecuteBifrostTask(TempArgument);
        Assert.AreEqual('OWN-CUSTOM', Selection.GetSelectedCustomLayout(), 'Custom-only selection restored');
        Selection.SetSelectedCustomLayout('');
        Assert.AreEqual('', Selection.GetSelectedLayout(), 'No spurious platform selection created from custom fallback');
        Selection.ClearLayoutSelection();
        TempArgument.CalcFields("Response Content");
        TempArgument."Response Content".CreateInStream(Content);
        Content.ReadText(Header, 5);
        Assert.AreEqual('%PDF-', Header, 'Platform rendered a PDF');
    end;

    /// <summary>Rendering failure returns the platform error and does not leak the temporary session layout.</summary>
    [Test]
    procedure SaveAsRenderFailureRestoresSession()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Layout: Record "Report Layout List";
        Selection: Codeunit "Design-time Report Selection";
        Implementation: Codeunit "Report SaveAs Msg ori";
        PriorAppId: Guid;
    begin
        FindSampleLayout(Layout);
        PriorAppId := CreateGuid();
        Selection.ClearLayoutSelection();
        Selection.SetSelectedLayout('OWN-PRIOR', PriorAppId);
        CreateSaveArgument(TempArgument, Layout, 'PDF', 2);
        asserterror Implementation.ExecuteBifrostTask(TempArgument);
        Assert.ExpectedError('Deliberate layout sample rendering failure.');
        Assert.AreEqual('OWN-PRIOR', Selection.GetSelectedLayout(), 'Prior selection restored after failure');
        Assert.AreEqual(PriorAppId, Selection.GetSelectedAppID(), 'Prior identity restored after failure');
        Selection.ClearLayoutSelection();
    end;

    /// <summary>An unknown requested layout fails explicitly instead of silently rendering the default.</summary>
    [Test]
    procedure SaveAsRejectsUnknownLayout()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Layout: Record "Report Layout List";
        Implementation: Codeunit "Report SaveAs Msg ori";
    begin
        FindSampleLayout(Layout);
        Layout.Name := 'XNONEXISTENT';
        CreateSaveArgument(TempArgument, Layout, 'PDF', 1);
        asserterror Implementation.ExecuteBifrostTask(TempArgument);
        Assert.ExpectedError('XNONEXISTENT');
    end;

    local procedure CreateSaveArgument(var TempArgument: Record "Message Argument ori" temporary; Layout: Record "Report Layout List"; OutputFormat: Text; RowNumber: Integer)
    var
        Request: JsonObject;
        RowViewLbl: Label 'WHERE(Number=CONST(%1))', Locked = true;
    begin
        Request.Add('reportId', Report::"Layout Sample Report ori");
        Request.Add('format', OutputFormat);
        Request.Add('layoutName', Layout.Name);
        Request.Add('appId', Format(Layout."Application ID", 0, 4));
        Request.Add('requestPageXml', '');
        Request.Add('tableView', StrSubstNo(RowViewLbl, RowNumber));
        TempArgument.Init();
        TempArgument.Insert();
        TempArgument.SetRequestJson(Request);
    end;

    local procedure FindSampleLayout(var Layout: Record "Report Layout List")
    begin
        Layout.SetRange("Report ID", Report::"Layout Sample Report ori");
        Layout.SetRange("User Defined", false);
        Layout.SetLoadFields(Name, "Application ID");
        Assert.IsTrue(Layout.FindFirst(), 'Own installed sample report layout exists');
    end;

    local procedure GetLayoutRequest(LayoutName: Text; AppId: Guid) Request: JsonObject
    begin
        Request.Add('reportId', Report::"Layout Sample Report ori");
        Request.Add('name', LayoutName);
        Request.Add('appId', Format(AppId, 0, 4));
    end;

    local procedure Execute(MessageType: Enum "Message Type ori"; Request: JsonObject): JsonObject
    var
        TempArgument: Record "Message Argument ori" temporary;
        Implementation: Interface "Msg Interface ori";
    begin
        TempArgument.Init();
        TempArgument.Insert();
        TempArgument.SetRequestJson(Request);
        Implementation := MessageType;
        Implementation.ExecuteBifrostTask(TempArgument);
        exit(TempArgument.GetResponseJson());
    end;
}
