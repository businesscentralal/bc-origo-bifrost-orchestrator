namespace Origo.Bifrost.Orchestrator.Test;

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
        Request.Add('reportId', Report::"Test Output Report ori");
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
        Request.Add('reportId', Report::"Test Output Report ori");
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
        Request.Add('reportId', Report::"Test Output Report ori");
        Request.Add('includeExtensionLayouts', false);
        Response := Execute("Message Type ori"::"Orchestrator.ReportLayout.List", Request);
        Response.Get('layouts', Value);
        foreach Item in Value.AsArray() do begin
            Item.AsObject().Get('name', NameValue);
            if NameValue.AsValue().AsText() = FixtureName then
                Found := true;
        end;
        Assert.IsTrue(Found, 'Own user layout listed');
        TenantLayout.Get(Report::"Test Output Report ori", FixtureName, EmptyGuid);
        TenantLayout.Delete(true);
        Assert.IsFalse(TenantLayout.Get(Report::"Test Output Report ori", FixtureName, EmptyGuid), 'Owned fixture deleted');
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

    local procedure FindSampleLayout(var Layout: Record "Report Layout List")
    begin
        Layout.SetRange("Report ID", Report::"Test Output Report ori");
        Layout.SetRange("User Defined", false);
        Layout.SetLoadFields(Name, "Application ID");
        Assert.IsTrue(Layout.FindFirst(), 'Own installed sample report layout exists');
    end;

    local procedure GetLayoutRequest(LayoutName: Text; AppId: Guid) Request: JsonObject
    begin
        Request.Add('reportId', Report::"Test Output Report ori");
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
