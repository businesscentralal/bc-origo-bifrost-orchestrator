namespace Origo.Bifrost.Orchestrator.Test;

using Microsoft.Foundation.Reporting;
using Origo.Bifrost;
using System.Environment.Configuration;
using System.Reflection;
using System.TestLibraries.Utilities;
using System.Text;
using System.Utilities;

/// <summary>Checks Orchestrator.ReportLayout.Set with a Foundation blob staging row (#129) using self-created staging rows and layouts.</summary>
codeunit 96458 "Report Layout Stage Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        DispatchHelper: Codeunit "Orch Dispatch Helper ori";
        BlobStaging: Codeunit "Blob Staging ori";
        Assert: Codeunit "Library Assert";

    /// <summary>A staged layout is imported exactly like the same bytes sent as base64, and the row is consumed (AC01).</summary>
    [Test]
    procedure StagingIdImportsLikeBase64AndConsumesRow()
    var
        Request: JsonObject;
        Response: JsonObject;
        StagedResponse: JsonObject;
        Exported: Text;
        Base64Name: Text[250];
        StagedName: Text[250];
        StagingId: Guid;
    begin
        // [GIVEN] Layout bytes in a self-created staging row
        Exported := ExportSampleLayout();
        StagingId := CreateStagingRow(Exported);
        Base64Name := CopyStr('XSTG-B64-' + Format(CreateGuid(), 0, 4), 1, MaxStrLen(Base64Name));
        StagedName := CopyStr('XSTG-ROW-' + Format(CreateGuid(), 0, 4), 1, MaxStrLen(StagedName));
        // [WHEN] The same bytes are imported once as base64 and once by stagingId
        Request := SetRequest(Base64Name);
        Request.Add('layoutBase64', Exported);
        Response := Execute(Request);
        Request := SetRequest(StagedName);
        Request.Add('stagingId', Format(StagingId, 0, 4));
        StagedResponse := Execute(Request);
        // [THEN] Same response shape and bytes; the row no longer exists
        Assert.AreEqual('Success', GetText(StagedResponse, 'status'), 'Staged import succeeds');
        Assert.AreEqual(GetText(Response, 'action'), GetText(StagedResponse, 'action'), 'Same action');
        Assert.AreEqual(GetText(Response, 'layoutFormat'), GetText(StagedResponse, 'layoutFormat'), 'Same format');
        Assert.AreEqual(GetLayoutBase64(Base64Name), GetLayoutBase64(StagedName), 'Same stored bytes');
        Assert.AreEqual(Exported, GetLayoutBase64(StagedName), 'Stored bytes equal staged bytes');
        Assert.IsFalse(BlobStaging.Exists(StagingId), 'Staging row consumed');
        DeleteLayout(Base64Name);
        DeleteLayout(StagedName);
    end;

    /// <summary>The id is accepted without braces and a staged import replaces an existing user layout (AC01).</summary>
    [Test]
    procedure StagingIdWithoutBracesReplacesExistingLayout()
    var
        Request: JsonObject;
        Response: JsonObject;
        Exported: Text;
        LayoutName: Text[250];
        StagingId: Guid;
    begin
        Exported := ExportSampleLayout();
        LayoutName := CopyStr('XSTG-REP-' + Format(CreateGuid(), 0, 4), 1, MaxStrLen(LayoutName));
        Request := SetRequest(LayoutName);
        Request.Add('layoutBase64', Exported);
        Execute(Request);
        StagingId := CreateStagingRow(Exported);
        Request := SetRequest(LayoutName);
        Request.Add('stagingId', Format(StagingId, 0, 3));
        Response := Execute(Request);
        Assert.AreEqual('Replaced', GetText(Response, 'action'), 'Existing user layout replaced');
        Assert.IsFalse(BlobStaging.Exists(StagingId), 'Staging row consumed');
        DeleteLayout(LayoutName);
    end;

    /// <summary>An unknown id and an already taken id are refused and import nothing (AC02).</summary>
    [Test]
    procedure UnknownOrTakenStagingIdIsRefused()
    var
        Request: JsonObject;
        LayoutName: Text[250];
        StagingId: Guid;
        Exported: Text;
    begin
        Exported := ExportSampleLayout();
        LayoutName := CopyStr('XSTG-UNK-' + Format(CreateGuid(), 0, 4), 1, MaxStrLen(LayoutName));
        Request := SetRequest(LayoutName);
        Request.Add('stagingId', Format(CreateGuid(), 0, 4));
        asserterror Execute(Request);
        Assert.ExpectedError('was not found or has already been taken');
        Assert.IsFalse(LayoutExists(LayoutName), 'Nothing imported');
        // Taken: the first call consumes the row, the second is refused
        StagingId := CreateStagingRow(Exported);
        Request := SetRequest(LayoutName);
        Request.Add('stagingId', Format(StagingId, 0, 4));
        Execute(Request);
        DeleteLayout(LayoutName);
        asserterror Execute(Request);
        Assert.ExpectedError('was not found or has already been taken');
        Assert.IsFalse(LayoutExists(LayoutName), 'Nothing imported for a taken id');
    end;

    /// <summary>Exclusive keys and a malformed id are refused before anything is taken (AC03).</summary>
    [Test]
    procedure KeyCombinationsAndInvalidGuidAreRefusedWithoutTaking()
    var
        Request: JsonObject;
        LayoutName: Text[250];
        StagingId: Guid;
        Exported: Text;
    begin
        Exported := ExportSampleLayout();
        StagingId := CreateStagingRow(Exported);
        LayoutName := CopyStr('XSTG-KEY-' + Format(CreateGuid(), 0, 4), 1, MaxStrLen(LayoutName));
        // Both keys
        Request := SetRequest(LayoutName);
        Request.Add('layoutBase64', Exported);
        Request.Add('stagingId', Format(StagingId, 0, 4));
        asserterror Execute(Request);
        Assert.ExpectedError('not both');
        // Neither key
        asserterror Execute(SetRequest(LayoutName));
        Assert.ExpectedError('or "stagingId".');
        // Not a GUID
        Request := SetRequest(LayoutName);
        Request.Add('stagingId', 'not-a-guid');
        asserterror Execute(Request);
        Assert.ExpectedError('is not a valid GUID');
        Assert.IsFalse(LayoutExists(LayoutName), 'Nothing imported');
        Assert.IsTrue(BlobStaging.Exists(StagingId), 'Nothing taken');
        TakeAndDiscard(StagingId);
    end;

    /// <summary>A failing import of a staged layout leaves the staging row in place (AC04).</summary>
    [Test]
    procedure FailedImportKeepsStagingRow()
    var
        Base64Convert: Codeunit "Base64 Convert";
        Request: JsonObject;
        LayoutName: Text[250];
        StagingId: Guid;
    begin
        // [GIVEN] A staging row whose bytes are not a valid .docx
        StagingId := CreateStagingRow(Base64Convert.ToBase64('this is not a docx'));
        LayoutName := CopyStr('XSTG-BAD-' + Format(CreateGuid(), 0, 4), 1, MaxStrLen(LayoutName));
        Request := SetRequest(LayoutName);
        Request.Replace('layoutFormat', 'Word');
        Request.Add('stagingId', Format(StagingId, 0, 4));
        // [WHEN] The staged import is attempted
        asserterror Execute(Request);
        // [THEN] It is refused, nothing is created and the row still exists
        Assert.ExpectedError('corrupted');
        Assert.IsFalse(LayoutExists(LayoutName), 'No layout created');
        Assert.IsTrue(BlobStaging.Exists(StagingId), 'Staging row survives a failed import');
        TakeAndDiscard(StagingId);
    end;

    /// <summary>Orchestrator depends on no Attachments app (AC06).</summary>
    [Test]
    procedure OrchestratorHasNoAttachmentsDependency()
    var
        ModuleInfo: ModuleInfo;
        Dependency: ModuleDependencyInfo;
    begin
        NavApp.GetModuleInfo('7da3f512-5c19-47cd-bbe4-4c2bc713f1db', ModuleInfo);
        foreach Dependency in ModuleInfo.Dependencies() do
            Assert.IsFalse(Dependency.Name().ToLower().Contains('attachment'), 'No Attachments dependency: ' + Dependency.Name());
    end;

    local procedure SetRequest(LayoutName: Text) Request: JsonObject
    begin
        Request.Add('reportId', Report::"Layout Sample Report ori");
        Request.Add('name', LayoutName);
        Request.Add('layoutFormat', 'RDLC');
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

    local procedure ExportSampleLayout(): Text
    var
        Layout: Record "Report Layout List";
        TempArgument: Record "Message Argument ori" temporary;
        Request: JsonObject;
        Response: JsonObject;
        Value: JsonToken;
    begin
        Layout.SetRange("Report ID", Report::"Layout Sample Report ori");
        Layout.SetRange("User Defined", false);
        Layout.SetLoadFields(Name, "Application ID");
        Assert.IsTrue(Layout.FindFirst(), 'Own installed sample report layout exists');
        Request.Add('reportId', Report::"Layout Sample Report ori");
        Request.Add('name', Layout.Name);
        Request.Add('appId', Format(Layout."Application ID", 0, 4));
        TempArgument.Init();
        TempArgument.Insert();
        TempArgument.SetRequestJson(Request);
        DispatchHelper.Execute("Message Type ori"::"Orchestrator.ReportLayout.Get", TempArgument);
        Response := TempArgument.GetResponseJson();
        Assert.IsTrue(Response.Get('layoutBase64', Value), 'Exported layout');
        exit(Value.AsValue().AsText());
    end;

    local procedure CreateStagingRow(Base64Bytes: Text): Guid
    var
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        OutStr: OutStream;
        InStr: InStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        Base64Convert.FromBase64(Base64Bytes, OutStr);
        TempBlob.CreateInStream(InStr);
        exit(BlobStaging.Create(InStr, 'layout.bin', 'application/octet-stream', 'Orchestrator tests'));
    end;

    local procedure TakeAndDiscard(StagingId: Guid)
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        Assert.IsTrue(BlobStaging.Take(StagingId, TempBlob), 'Owned staging row cleaned up');
    end;

    local procedure GetText(Response: JsonObject; KeyName: Text): Text
    var
        Value: JsonToken;
    begin
        Assert.IsTrue(Response.Get(KeyName, Value), KeyName + ' present in ' + Format(Response));
        exit(Value.AsValue().AsText());
    end;

    local procedure LayoutExists(LayoutName: Text): Boolean
    var
        TenantLayout: Record "Tenant Report Layout";
        EmptyGuid: Guid;
    begin
        exit(TenantLayout.Get(Report::"Layout Sample Report ori", CopyStr(LayoutName, 1, MaxStrLen(TenantLayout.Name)), EmptyGuid));
    end;

    local procedure GetLayoutBase64(LayoutName: Text): Text
    var
        TempArgument: Record "Message Argument ori" temporary;
        EmptyGuid: Guid;
        Request: JsonObject;
        Response: JsonObject;
        Value: JsonToken;
    begin
        Request.Add('reportId', Report::"Layout Sample Report ori");
        Request.Add('name', LayoutName);
        Request.Add('appId', Format(EmptyGuid, 0, 4));
        TempArgument.Init();
        TempArgument.Insert();
        TempArgument.SetRequestJson(Request);
        DispatchHelper.Execute("Message Type ori"::"Orchestrator.ReportLayout.Get", TempArgument);
        Response := TempArgument.GetResponseJson();
        Response.Get('layoutBase64', Value);
        exit(Value.AsValue().AsText());
    end;

    local procedure DeleteLayout(LayoutName: Text)
    var
        TenantLayout: Record "Tenant Report Layout";
        EmptyGuid: Guid;
    begin
        if TenantLayout.Get(Report::"Layout Sample Report ori", CopyStr(LayoutName, 1, MaxStrLen(TenantLayout.Name)), EmptyGuid) then
            TenantLayout.Delete(true);
    end;
}
