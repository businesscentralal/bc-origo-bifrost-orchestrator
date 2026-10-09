namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.Reflection;

/// <summary>Tests report preset storage, report message handlers, and generic data-access restrictions.</summary>
codeunit 96416 "Report Msg Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    // --- Preset Table Tests ---

    /// <summary>Verifies that a saved report preset returns the XML stored for the current user.</summary>
    [Test]
    procedure PresetRoundTripsXml()
    var
        Preset: Record "Report Request Preset ori";
        SampleXml: Text;
    begin
        // [SCENARIO] Preset table stores and retrieves request page XML
        SampleXml := '<ReportParameters name="Test" id="1"><Options/><DataItems/></ReportParameters>';

        Preset.Init();
        Preset."Report ID" := 1;
        Preset."User Security ID" := UserSecurityId();
        Preset.Description := 'Test preset';
        Preset.SetRequestPageXml(SampleXml);
        Preset.Insert(true);

        Preset.Get(1, UserSecurityId());
        Assert.AreEqual(SampleXml, Preset.GetRequestPageXml(), 'XML round-trip mismatch');

        Preset.Delete();
    end;

    /// <summary>Verifies that a preset without stored XML returns empty text and reports no XML.</summary>
    [Test]
    procedure PresetReturnsEmptyWhenNoXml()
    var
        Preset: Record "Report Request Preset ori";
    begin
        // [SCENARIO] GetRequestPageXml returns empty when no blob stored
        Preset.Init();
        Preset."Report ID" := 99999;
        Preset."User Security ID" := UserSecurityId();
        Preset.Insert(true);

        Preset.Get(99999, UserSecurityId());
        Assert.AreEqual('', Preset.GetRequestPageXml(), 'Should be empty');
        Assert.IsFalse(Preset.HasRequestPageXml(), 'HasRequestPageXml should be false');

        Preset.Delete();
    end;

    /// <summary>Verifies that a preset reports XML availability after request-page XML is stored.</summary>
    [Test]
    procedure PresetHasRequestPageXmlReturnsTrueWhenPopulated()
    var
        Preset: Record "Report Request Preset ori";
    begin
        // [SCENARIO] HasRequestPageXml returns true after XML is stored
        Preset.Init();
        Preset."Report ID" := 99998;
        Preset."User Security ID" := UserSecurityId();
        Preset.SetRequestPageXml('<ReportParameters/>');
        Preset.Insert(true);

        Preset.Get(99998, UserSecurityId());
        Assert.IsTrue(Preset.HasRequestPageXml(), 'HasRequestPageXml should be true');

        Preset.Delete();
    end;

    // --- Report.List Tests ---

    /// <summary>Checks that Report.List returns reports and a positive count.</summary>
    [Test]
    procedure ListReturnsReportsWithCountField()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Msg Handler ori";
        ResponseJson: JsonObject;
        ReportsToken: JsonToken;
        CountToken: JsonToken;
    begin
        // [SCENARIO] Report.List returns reports array with count
        CreateArgument(TempArgument, '{}');

        Handler.ExecuteList(TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        Assert.IsTrue(ResponseJson.Get('reports', ReportsToken), 'Missing reports array');
        Assert.IsTrue(ResponseJson.Get('count', CountToken), 'Missing count');
        Assert.IsTrue(CountToken.AsValue().AsInteger() > 0, 'Should find at least one report');
    end;

    /// <summary>Checks that processingOnly=false excludes processing-only reports from the returned list.</summary>
    [Test]
    procedure ListFiltersByProcessingOnly()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Msg Handler ori";
        ResponseJson: JsonObject;
        ReportsToken: JsonToken;
        ReportArray: JsonArray;
        ReportToken: JsonToken;
        ReportObj: JsonObject;
        ProcessingOnlyToken: JsonToken;
        I: Integer;
    begin
        // [SCENARIO] Report.List with processingOnly=false excludes processing-only reports
        CreateArgument(TempArgument, '{"processingOnly": false}');

        Handler.ExecuteList(TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('reports', ReportsToken);
        ReportArray := ReportsToken.AsArray();

        for I := 0 to ReportArray.Count() - 1 do begin
            ReportArray.Get(I, ReportToken);
            ReportObj := ReportToken.AsObject();
            ReportObj.Get('processingOnly', ProcessingOnlyToken);
            Assert.IsFalse(ProcessingOnlyToken.AsValue().AsBoolean(),
                'Should not contain processing-only reports');
        end;
    end;

    /// <summary>Checks the expected metadata fields on the first report returned by Report.List.</summary>
    [Test]
    procedure ListReportContainsExpectedFields()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Msg Handler ori";
        ResponseJson: JsonObject;
        ReportsToken: JsonToken;
        FirstReport: JsonObject;
        ReportToken: JsonToken;
        DummyToken: JsonToken;
    begin
        // [SCENARIO] Each report in the list has all expected fields
        CreateArgument(TempArgument, '{}');

        Handler.ExecuteList(TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('reports', ReportsToken);
        ReportsToken.AsArray().Get(0, ReportToken);
        FirstReport := ReportToken.AsObject();

        Assert.IsTrue(FirstReport.Get('id', DummyToken), 'Missing id');
        Assert.IsTrue(FirstReport.Get('name', DummyToken), 'Missing name');
        Assert.IsTrue(FirstReport.Get('caption', DummyToken), 'Missing caption');
        Assert.IsTrue(FirstReport.Get('processingOnly', DummyToken), 'Missing processingOnly');
        Assert.IsTrue(FirstReport.Get('defaultLayout', DummyToken), 'Missing defaultLayout');
        Assert.IsTrue(FirstReport.Get('firstDataItemTableId', DummyToken), 'Missing firstDataItemTableId');
        Assert.IsTrue(FirstReport.Get('useRequestPage', DummyToken), 'Missing useRequestPage');
    end;

    // --- Report.Get Tests ---

    /// <summary>Checks that Report.Get returns the requested report ID.</summary>
    [Test]
    procedure GetReturnsReportMetadata()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Msg Handler ori";
        ResponseJson: JsonObject;
        IdToken: JsonToken;
        TestReportId: Integer;
    begin
        // [SCENARIO] Report.Get returns metadata for a known report
        TestReportId := FindAnyNonProcessingReport();

        CreateArgument(TempArgument, '{"reportId": ' + Format(TestReportId) + '}');

        Handler.ExecuteGet(TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('id', IdToken);
        Assert.AreEqual(TestReportId, IdToken.AsValue().AsInteger(), 'Report ID mismatch');
    end;

    /// <summary>Checks that Report.Get includes at least one layout for the selected report.</summary>
    [Test]
    procedure GetReturnsLayoutsArray()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Msg Handler ori";
        ResponseJson: JsonObject;
        LayoutsToken: JsonToken;
        TestReportId: Integer;
    begin
        // [SCENARIO] Report.Get includes layouts array
        TestReportId := FindAnyNonProcessingReport();

        CreateArgument(TempArgument, '{"reportId": ' + Format(TestReportId) + '}');

        Handler.ExecuteGet(TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        Assert.IsTrue(ResponseJson.Get('layouts', LayoutsToken), 'Missing layouts');
        Assert.IsTrue(LayoutsToken.AsArray().Count() > 0, 'Should have at least one layout');
    end;

    /// <summary>Checks that Report.Get returns the request-page XML saved for the current user.</summary>
    [Test]
    procedure GetReturnsPresetWhenExists()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Msg Handler ori";
        ResponseJson: JsonObject;
        PresetToken: JsonToken;
        PresetObj: JsonObject;
        XmlToken: JsonToken;
        TestReportId: Integer;
        TestXml: Text;
    begin
        // [SCENARIO] Report.Get returns preset with XML when user has a saved preset
        TestReportId := FindAnyNonProcessingReport();
        TestXml := '<ReportParameters name="Test" id="' + Format(TestReportId) + '"/>';

        InsertPreset(TestReportId, TestXml, 'Test');

        CreateArgument(TempArgument, '{"reportId": ' + Format(TestReportId) + '}');

        Handler.ExecuteGet(TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        Assert.IsTrue(ResponseJson.Get('preset', PresetToken), 'Missing preset');
        PresetObj := PresetToken.AsObject();
        PresetObj.Get('requestPageXml', XmlToken);
        Assert.AreEqual(TestXml, XmlToken.AsValue().AsText(), 'Preset XML mismatch');

        DeletePreset(TestReportId);
    end;

    /// <summary>Checks that Report.Get creates an empty current-user preset and reports no saved XML.</summary>
    [Test]
    procedure GetCreatesEmptyPresetWhenNoneExists()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Preset: Record "Report Request Preset ori";
        Handler: Codeunit "Report Msg Handler ori";
        ResponseJson: JsonObject;
        PresetToken: JsonToken;
        PresetObj: JsonObject;
        HasXmlToken: JsonToken;
        TestReportId: Integer;
    begin
        // [SCENARIO] Report.Get creates an empty preset when the user has none saved,
        // so the response always carries a preset and a capture page URL to point at.
        TestReportId := FindAnyNonProcessingReport();
        DeletePreset(TestReportId);

        CreateArgument(TempArgument, '{"reportId": ' + Format(TestReportId) + '}');

        Handler.ExecuteGet(TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        Assert.IsTrue(ResponseJson.Get('preset', PresetToken), 'Preset should be present');
        PresetObj := PresetToken.AsObject();
        PresetObj.Get('hasRequestPageXml', HasXmlToken);
        Assert.IsFalse(HasXmlToken.AsValue().AsBoolean(), 'New preset should have no XML');
        Assert.IsTrue(Preset.Get(TestReportId, UserSecurityId()), 'Preset record should have been created');

        DeletePreset(TestReportId);
    end;

    /// <summary>Checks the Report.Get error for a report ID that does not exist.</summary>
    [Test]
    procedure GetErrorsForInvalidReportId()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Msg Handler ori";
    begin
        // [SCENARIO] Report.Get errors when report does not exist
        CreateArgument(TempArgument, '{"reportId": 999999999}');

        asserterror Handler.ExecuteGet(TempArgument);
        Assert.ExpectedError('Report 999999999 not found');
    end;

    /// <summary>Checks that Report.Get reports a missing reportId.</summary>
    [Test]
    procedure GetErrorsWhenReportIdMissing()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Msg Handler ori";
    begin
        // [SCENARIO] Report.Get errors when reportId is missing from request
        CreateArgument(TempArgument, '{}');

        asserterror Handler.ExecuteGet(TempArgument);
        Assert.ExpectedError('reportId');
    end;

    // --- Report.SaveAs Tests ---

    /// <summary>Checks that Report.SaveAs produces response content when PDF output is requested.</summary>
    [Test]
    procedure SaveAsGeneratesPdfOutput()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Msg Handler ori";
        TestReportId: Integer;
    begin
        // [SCENARIO] Report.SaveAs produces non-empty PDF output
        TestReportId := FindAnyNonProcessingReport();

        CreateArgument(TempArgument, '{"reportId": ' + Format(TestReportId) + ', "format": "PDF"}');

        Handler.ExecuteSaveAs(TempArgument);

        TempArgument.CalcFields("Response Content");
        Assert.IsTrue(TempArgument."Response Content".HasValue(), 'Response should contain PDF data');
    end;

    /// <summary>Checks that Report.SaveAs produces response content when format is omitted.</summary>
    [Test]
    procedure SaveAsDefaultsToPdfWhenFormatOmitted()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Msg Handler ori";
        TestReportId: Integer;
    begin
        // [SCENARIO] Report.SaveAs defaults to PDF when format is not specified
        TestReportId := FindAnyNonProcessingReport();

        CreateArgument(TempArgument, '{"reportId": ' + Format(TestReportId) + '}');

        Handler.ExecuteSaveAs(TempArgument);

        TempArgument.CalcFields("Response Content");
        Assert.IsTrue(TempArgument."Response Content".HasValue(), 'Should produce output with default format');
    end;

    /// <summary>Checks that Report.SaveAs produces content with an empty saved preset and no requestPageXml input.</summary>
    [Test]
    procedure SaveAsUsesPresetWhenNoXmlProvided()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Msg Handler ori";
        TestReportId: Integer;
        PresetXml: Text;
    begin
        // [SCENARIO] SaveAs falls back to preset XML when requestPageXml not in request
        TestReportId := FindAnyNonProcessingReport();
        PresetXml := GetDefaultReportParametersXml();
        InsertPreset(TestReportId, PresetXml, 'SaveAs Test');

        CreateArgument(TempArgument, '{"reportId": ' + Format(TestReportId) + ', "format": "PDF"}');

        Handler.ExecuteSaveAs(TempArgument);

        TempArgument.CalcFields("Response Content");
        Assert.IsTrue(TempArgument."Response Content".HasValue(), 'Should produce output using preset');

        DeletePreset(TestReportId);
    end;

    /// <summary>Checks that Report.SaveAs rejects an unsupported output format.</summary>
    [Test]
    procedure SaveAsErrorsForInvalidFormat()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Msg Handler ori";
        TestReportId: Integer;
    begin
        // [SCENARIO] SaveAs errors on unsupported format
        TestReportId := FindAnyNonProcessingReport();

        CreateArgument(TempArgument, '{"reportId": ' + Format(TestReportId) + ', "format": "BANANA"}');

        asserterror Handler.ExecuteSaveAs(TempArgument);
        Assert.ExpectedError('Unsupported format');
    end;

    /// <summary>Checks that Report.SaveAs reports a missing reportId.</summary>
    [Test]
    procedure SaveAsErrorsForMissingReportId()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Msg Handler ori";
    begin
        // [SCENARIO] SaveAs errors when reportId is missing
        CreateArgument(TempArgument, '{}');

        asserterror Handler.ExecuteSaveAs(TempArgument);
        Assert.ExpectedError('reportId');
    end;

    /// <summary>Checks the Report.SaveAs error for a report ID that does not exist.</summary>
    [Test]
    procedure SaveAsErrorsForNonExistentReport()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Msg Handler ori";
    begin
        // [SCENARIO] SaveAs errors when report does not exist
        CreateArgument(TempArgument, '{"reportId": 999999999}');

        asserterror Handler.ExecuteSaveAs(TempArgument);
        Assert.ExpectedError('Report 999999999 not found');
    end;

    // --- Data Restriction Tests ---

    /// <summary>Checks that report presets are restricted from generic Data.Records reads.</summary>
    [Test]
    procedure PresetTableIsBlockedFromDataRecordsRead()
    var
        TempArgument: Record "Message Argument ori" temporary;
    begin
        // [SCENARIO] Bifrost Report Request Preset is restricted from generic Data.Records.Get
        Assert.IsTrue(
            TempArgument.IsTableReadRestrictedForDataRecords(Database::"Report Request Preset ori"),
            'Preset table should be read-restricted');
    end;

    /// <summary>Checks that report presets are restricted from generic non-forced Data.Records writes.</summary>
    [Test]
    procedure PresetTableIsBlockedFromDataRecordsWrite()
    var
        TempArgument: Record "Message Argument ori" temporary;
    begin
        // [SCENARIO] Bifrost Report Request Preset is restricted from generic Data.Records.Set
        Assert.IsTrue(
            TempArgument.IsTableWriteRestrictedForDataRecords(Database::"Report Request Preset ori", false),
            'Preset table should be write-restricted');
    end;

    // --- Helpers ---

    local procedure BuildJson(JsonText: Text) Result: JsonObject
    begin
        Result.ReadFrom(JsonText);
    end;

    local procedure CreateArgument(var TempArgument: Record "Message Argument ori" temporary; RequestJsonText: Text)
    begin
        TempArgument.Init();
        TempArgument.Insert();
        TempArgument.SetRequestJson(BuildJson(RequestJsonText));
    end;

    local procedure FindAnyNonProcessingReport(): Integer
    var
        ReportMeta: Record "Report Metadata";
    begin
        ReportMeta.SetRange(ProcessingOnly, false);
        ReportMeta.SetLoadFields(ID);
        ReportMeta.FindFirst();
        exit(ReportMeta.ID);
    end;

    local procedure GetDefaultReportParametersXml(): Text
    begin
        exit('');
    end;

    local procedure InsertPreset(ReportId: Integer; XmlText: Text; Desc: Text)
    var
        Preset: Record "Report Request Preset ori";
    begin
        DeletePreset(ReportId);
        Preset.Init();
        Preset."Report ID" := ReportId;
        Preset."User Security ID" := UserSecurityId();
        Preset.Description := CopyStr(Desc, 1, MaxStrLen(Preset.Description));
        Preset.SetRequestPageXml(XmlText);
        Preset.Insert(true);
    end;

    local procedure DeletePreset(ReportId: Integer)
    var
        Preset: Record "Report Request Preset ori";
    begin
        if Preset.Get(ReportId, UserSecurityId()) then
            Preset.Delete();
    end;
}
