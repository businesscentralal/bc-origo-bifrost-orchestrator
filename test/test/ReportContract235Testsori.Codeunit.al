namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.Environment.Configuration;
using System.Reflection;
using System.TestLibraries.Utilities;
using System.Text;
using System.Utilities;

/// <summary>Issue 235 report/layout contract regressions using owned fixtures and both supported languages.</summary>
codeunit 96499 "Report Contract 235 Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    /// <summary>AC01–AC06 and AC08–AC09 help describes the actual request, response and refusals in English.</summary>
    [Test]
    procedure HelpContractsEnglish()
    begin
        VerifyHelp(1033);
    end;

    /// <summary>The same contract facts and localized guidance exist in Icelandic.</summary>
    [Test]
    procedure HelpContractsIcelandic()
    begin
        VerifyHelp(1039);
    end;

    /// <summary>AC03–AC04 list company scope and export a nonempty RDLC MIME type in English.</summary>
    [Test]
    procedure LayoutMetadataEnglish()
    begin
        VerifyLayoutMetadata(1033);
    end;

    /// <summary>AC03–AC04 retain stable field names and values in Icelandic.</summary>
    [Test]
    procedure LayoutMetadataIcelandic()
    begin
        VerifyLayoutMetadata(1039);
    end;

    /// <summary>AC08–AC09 return stable codes, parameters and recovery steps in English.</summary>
    [Test]
    procedure StructuredErrorsEnglish()
    begin
        VerifyErrors(1033);
    end;

    /// <summary>AC08–AC09 return stable codes and Icelandic recovery steps.</summary>
    [Test]
    procedure StructuredErrorsIcelandic()
    begin
        VerifyErrors(1039);
    end;

    /// <summary>AC07 XML output keeps XML content type and actual bytes.</summary>
    [Test]
    procedure SaveAsXmlContentType()
    begin
        VerifyOutput('XML', 'application/xml', '<?xml');
    end;

    /// <summary>AC07 PDF remains binary PDF for existing callers.</summary>
    [Test]
    procedure SaveAsPdfContentType()
    begin
        VerifyOutput('PDF', 'application/pdf', '%PDF');
    end;

    /// <summary>AC07 Excel declares the spreadsheet MIME type for ZIP document bytes.</summary>
    [Test]
    procedure SaveAsExcelContentType()
    begin
        VerifyOutput('Excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'PK');
    end;

    /// <summary>AC07 Word declares the Word MIME type for ZIP document bytes.</summary>
    [Test]
    procedure SaveAsWordContentType()
    begin
        VerifyOutput('Word', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'PK');
    end;

    /// <summary>AC04 Word and Excel layout exports report their real format MIME types.</summary>
    [Test]
    procedure OfficeLayoutMimeTypes()
    begin
        VerifyOfficeLayoutMime('Word', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 1033);
        VerifyOfficeLayoutMime('Excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 1039);
    end;

    local procedure VerifyOfficeLayoutMime(OutputFormat: Text; ExpectedMime: Text; LanguageId: Integer)
    var
        Argument: Record "Message Argument ori" temporary;
        TenantLayout: Record "Tenant Report Layout";
        DispatchHelper: Codeunit "Orch Dispatch Helper ori";
        Base64Convert: Codeunit "Base64 Convert";
        Request: JsonObject;
        Response: JsonObject;
        Input: InStream;
        LayoutName: Text[250];
        EmptyGuid: Guid;
    begin
        Request.Add('reportId', Report::"Layout Sample Report ori");
        Request.Add('format', OutputFormat);
        Request.Add('tableView', 'WHERE(Number=CONST(1))');
        Argument.Init();
        Argument.Insert();
        Argument.SetRequestJson(Request);
        DispatchHelper.Execute("Message Type ori"::"Orchestrator.Report.SaveAs", Argument);
        Assert.AreEqual(ExpectedMime, Argument."Content Type", 'Render valid Office bytes');
        Argument."Response Content".CreateInStream(Input);
        if OutputFormat = 'Excel' then begin
            Request := LayoutRequest('FixtureExcel');
            Request.Add('appId', '194ecd04-5688-4af6-94bc-732c714251fc');
            Response := Dispatch("Message Type ori"::"Orchestrator.ReportLayout.Get", Request, LanguageId);
            Assert.AreEqual(ExpectedMime, GetText(Response, 'mimeType'), 'Extension Excel MIME type');
        end;
        LayoutName := CopyStr('X235-OFFICE-' + Format(CreateGuid(), 0, 4), 1, MaxStrLen(LayoutName));
        Request := LayoutRequest(LayoutName);
        Request.Add('layoutFormat', OutputFormat);
        if OutputFormat = 'Excel' then
            Request.Add('layoutBase64', GetText(Response, 'layoutBase64'))
        else
            Request.Add('layoutBase64', Base64Convert.ToBase64(Input));
        Response := Dispatch("Message Type ori"::"Orchestrator.ReportLayout.Set", Request, LanguageId);
        Assert.AreEqual('Created', GetText(Response, 'action'), 'Owned Office layout imported');
        Response := Dispatch("Message Type ori"::"Orchestrator.ReportLayout.Get", LayoutRequest(LayoutName), LanguageId);
        Assert.AreEqual(ExpectedMime, GetText(Response, 'mimeType'), 'Layout MIME type follows format');
        TenantLayout.Get(Report::"Layout Sample Report ori", LayoutName, EmptyGuid);
        TenantLayout.Delete(true);
    end;

    local procedure VerifyHelp(LanguageId: Integer)
    var
        SetMsg: Codeunit "Report Layout Set Msg ori";
        GetMsg: Codeunit "Report Layout Get Msg ori";
        ListMsg: Codeunit "Report Layout List Msg ori";
        SaveMsg: Codeunit "Report SaveAs Msg ori";
        Chapter: JsonObject;
        Entries: JsonArray;
        TextValue: Text;
        PreviousLanguage: Integer;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        // Foundation keeps JSON contract chapters English; the MCP catalogue must carry localized guidance.
        TextValue := SetMsg.GetSelectionDescription();
        AssertContains(TextValue, 'setAsDefault');
        AssertContains(TextValue, 'isDefault');
        AssertContains(TextValue, '00000000-0000-0000-0000-000000000000');
        AssertDeletePolicy(TextValue, LanguageId);
        TextValue := ListMsg.GetSelectionDescription();
        AssertDeletePolicy(TextValue, LanguageId);
        TextValue := GetMsg.GetSelectionDescription();
        AssertContains(TextValue, 'application/xml');
        AssertDeletePolicy(TextValue, LanguageId);
        TextValue := SaveMsg.GetSelectionDescription();
        AssertContains(TextValue, 'tableView');
        if LanguageId = 1039 then
            AssertContains(TextValue, 'biðtíma')
        else
            AssertContains(TextValue, 'timeout');
        SetMsg.GetParameters(Entries);
        Entries.WriteTo(TextValue);
        AssertContains(TextValue, 'setAsDefault');
        AssertContains(TextValue, 'isDefault');
        AssertContains(TextValue, '00000000-0000-0000-0000-000000000000');
        Clear(Entries);
        SetMsg.GetExamples(Entries);
        Entries.WriteTo(TextValue);
        AssertContains(TextValue, '"appId":"00000000-0000-0000-0000-000000000000"');
        SetMsg.GetNotes(TextValue);
        AssertDeletePolicy(TextValue, LanguageId);
        GetMsg.GetNotes(TextValue);
        AssertDeletePolicy(TextValue, LanguageId);
        ListMsg.GetNotes(TextValue);
        AssertDeletePolicy(TextValue, LanguageId);
        ListMsg.GetResponse(Chapter);
        Chapter.WriteTo(TextValue);
        AssertContains(TextValue, 'companyName');
        Clear(Chapter);
        GetMsg.GetResponse(Chapter);
        Chapter.WriteTo(TextValue);
        AssertContains(TextValue, 'application/xml');
        AssertContains(TextValue, 'wordprocessingml.document');
        AssertContains(TextValue, 'spreadsheetml.sheet');
        SaveMsg.GetNotes(TextValue);
        AssertContains(TextValue, 'tableView');
        if LanguageId = 1039 then begin
            AssertContains(TextValue, 'beint í svari');
            AssertContains(TextValue, 'biðtíma');
        end else begin
            AssertContains(TextValue, 'inline');
            AssertContains(TextValue, 'timeout');
        end;
        Clear(Entries);
        SetMsg.GetErrors(Entries);
        Entries.WriteTo(TextValue);
        AssertContains(TextValue, 'RecordNotFound');
        AssertContains(TextValue, 'stagingId');
        Clear(Entries);
        GetMsg.GetErrors(Entries);
        Entries.WriteTo(TextValue);
        AssertContains(TextValue, 'MissingParameter');
        AssertContains(TextValue, 'parameter: name');
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyLayoutMetadata(LanguageId: Integer)
    var
        Layout: Record "Report Layout List";
        TenantLayout: Record "Tenant Report Layout";
        Request: JsonObject;
        Response: JsonObject;
        Value: JsonToken;
        Item: JsonToken;
        Layouts: JsonArray;
        EmptyGuid: Guid;
        FixtureName: Text[250];
        Exported: Text;
        Found: Boolean;
    begin
        FindSampleLayout(Layout);
        Request := LayoutRequest(Layout.Name);
        Request.Add('appId', Format(Layout."Application ID", 0, 4));
        Response := Dispatch("Message Type ori"::"Orchestrator.ReportLayout.Get", Request, LanguageId);
        Assert.AreEqual('application/xml', GetText(Response, 'mimeType'), 'Extension RDLC MIME type');
        Exported := GetText(Response, 'layoutBase64');
        FixtureName := CopyStr('X235-' + Format(CreateGuid(), 0, 4), 1, MaxStrLen(FixtureName));
        Request := LayoutRequest(FixtureName);
        Request.Add('layoutFormat', 'RDLC');
        Request.Add('layoutBase64', Exported);
        Request.Add('companyName', CompanyName());
        Response := Dispatch("Message Type ori"::"Orchestrator.ReportLayout.Set", Request, LanguageId);
        Assert.AreEqual('Created', GetText(Response, 'action'), 'Owned layout imported');
        Clear(Request);
        Request.Add('reportId', Report::"Layout Sample Report ori");
        Response := Dispatch("Message Type ori"::"Orchestrator.ReportLayout.List", Request, LanguageId);
        Response.Get('layouts', Value);
        Layouts := Value.AsArray();
        foreach Item in Layouts do
            if GetText(Item.AsObject(), 'name') = FixtureName then begin
                Assert.AreEqual(CompanyName(), GetText(Item.AsObject(), 'companyName'), 'Company scope visible before selection');
                Found := true;
            end;
        Assert.IsTrue(Found, 'Owned layout listed');
        Response := Dispatch("Message Type ori"::"Orchestrator.ReportLayout.Get", LayoutRequest(FixtureName), LanguageId);
        Assert.AreEqual('application/xml', GetText(Response, 'mimeType'), 'User-defined RDLC MIME type');
        Assert.AreEqual(Exported, GetText(Response, 'layoutBase64'), 'Export preserves bytes');
        Request := LayoutRequest(FixtureName);
        Request.Add('layoutFormat', 'RDLC');
        Request.Add('layoutBase64', Exported);
        Request.Add('companyName', '');
        Response := Dispatch("Message Type ori"::"Orchestrator.ReportLayout.Set", Request, LanguageId);
        Assert.AreEqual('Replaced', GetText(Response, 'action'), 'Same layout changed to all companies');
        Clear(Request);
        Request.Add('reportId', Report::"Layout Sample Report ori");
        Response := Dispatch("Message Type ori"::"Orchestrator.ReportLayout.List", Request, LanguageId);
        Response.Get('layouts', Value);
        foreach Item in Value.AsArray() do
            if GetText(Item.AsObject(), 'name') = FixtureName then
                Assert.AreEqual('', GetText(Item.AsObject(), 'companyName'), 'Empty company means all companies');
        TenantLayout.Get(Report::"Layout Sample Report ori", FixtureName, EmptyGuid);
        TenantLayout.Delete(true);
    end;

    local procedure VerifyErrors(LanguageId: Integer)
    var
        BlobStaging: Codeunit "Blob Staging ori";
        TempBlob: Codeunit "Temp Blob";
        Request: JsonObject;
        Response: JsonObject;
        Output: OutStream;
        Input: InStream;
        StagingId: Guid;
    begin
        Request.Add('reportId', Report::"Layout Sample Report ori");
        Response := Dispatch("Message Type ori"::"Orchestrator.ReportLayout.Get", Request, LanguageId);
        AssertStructuredError(Response, 'MissingParameter', 'name');
        Request := LayoutRequest('X235-MISSING');
        Request.Add('layoutFormat', 'RDLC');
        Request.Add('stagingId', Format(CreateGuid(), 0, 4));
        Response := Dispatch("Message Type ori"::"Orchestrator.ReportLayout.Set", Request, LanguageId);
        AssertStructuredError(Response, 'RecordNotFound', 'stagingId');
        TempBlob.CreateOutStream(Output);
        Output.WriteText('owned consumed staging fixture');
        TempBlob.CreateInStream(Input);
        StagingId := BlobStaging.Create(Input, 'X235.rdl', 'application/xml', 'Issue 235 tests');
        Assert.IsTrue(BlobStaging.Take(StagingId, TempBlob), 'Consume own staging row');
        Request.Replace('stagingId', Format(StagingId, 0, 4));
        Response := Dispatch("Message Type ori"::"Orchestrator.ReportLayout.Set", Request, LanguageId);
        AssertStructuredError(Response, 'RecordNotFound', 'stagingId');
        Assert.IsFalse(BlobStaging.Exists(StagingId), 'Consumed row stays absent');
    end;

    local procedure VerifyOutput(OutputFormat: Text; ExpectedMime: Text; Magic: Text)
    var
        Argument: Record "Message Argument ori" temporary;
        DispatchHelper: Codeunit "Orch Dispatch Helper ori";
        Request: JsonObject;
        Input: InStream;
        Prefix: Text;
    begin
        Request.Add('reportId', Report::"Layout Sample Report ori");
        Request.Add('format', OutputFormat);
        Request.Add('tableView', 'WHERE(Number=CONST(1))');
        Argument.Init();
        Argument.Insert();
        Argument.SetRequestJson(Request);
        DispatchHelper.Execute("Message Type ori"::"Orchestrator.Report.SaveAs", Argument);
        Assert.AreEqual(ExpectedMime, Argument."Content Type", 'Content type follows format');
        Argument."Response Content".CreateInStream(Input);
        Input.ReadText(Prefix, StrLen(Magic));
        Assert.AreEqual(Magic, Prefix, 'Actual bytes match declared format');
    end;

    local procedure Dispatch(MessageType: Enum "Message Type ori"; Request: JsonObject; LanguageId: Integer) Response: JsonObject
    var
        Dispatcher: Codeunit "Dispatcher ori";
        RequestContent: BigText;
        ResponseContent: BigText;
        RequestText: Text;
        ResponseText: Text;
        ResponseType: Text[100];
        EmptyTaskId: Guid;
        MessageId: Guid;
        ResponseTime: Duration;
    begin
        Request.WriteTo(RequestText);
        RequestContent.AddText(RequestText);
        Dispatcher.EnqueueAndProcess(MessageType, "Message Version ori"::"1.0", '', '', 'text/json', RequestContent, EmptyTaskId, LanguageId, MessageId, ResponseContent, ResponseType, ResponseTime);
        ResponseContent.GetSubText(ResponseText, 1);
        Assert.IsTrue(Response.ReadFrom(ResponseText), 'JSON response: ' + ResponseText);
    end;

    local procedure LayoutRequest(LayoutName: Text) Request: JsonObject
    begin
        Request.Add('reportId', Report::"Layout Sample Report ori");
        Request.Add('name', LayoutName);
    end;

    local procedure FindSampleLayout(var Layout: Record "Report Layout List")
    begin
        Layout.SetRange("Report ID", Report::"Layout Sample Report ori");
        Layout.SetRange("User Defined", false);
        Layout.SetLoadFields(Name, "Application ID");
        Assert.IsTrue(Layout.FindFirst(), 'Installed own sample layout');
    end;

    local procedure GetText(Value: JsonObject; Name: Text): Text
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(Value.Get(Name, Token), 'Response contains ' + Name);
        exit(Token.AsValue().AsText());
    end;

    local procedure AssertContains(Value: Text; Expected: Text)
    begin
        Assert.IsTrue(Value.Contains(Expected), 'Contract contains ' + Expected);
    end;

    local procedure AssertDeletePolicy(Value: Text; LanguageId: Integer)
    begin
        if LanguageId = 1039 then
            AssertContains(Value, 'samkvæmt hönnun')
        else
            AssertContains(Value, 'by design');
    end;

    local procedure AssertStructuredError(Response: JsonObject; ExpectedCode: Text; Parameter: Text)
    begin
        Assert.AreEqual('Error', GetText(Response, 'status'), 'Failure is structured');
        Assert.AreEqual(ExpectedCode, GetText(Response, 'code'), 'Stable error code');
        Assert.AreEqual(Parameter, GetText(Response, 'parameter'), 'Actionable parameter');
        Assert.AreNotEqual('', GetText(Response, 'nextStep'), 'Recovery step');
    end;
}
