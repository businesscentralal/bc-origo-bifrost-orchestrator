namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.Reflection;

codeunit 96416 "Report Msg Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    // --- Preset Table Tests ---

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

    [Test]
    procedure PresetTableIsBlockedFromDataRecordsWrite()
    var
        TempArgument: Record "Message Argument ori" temporary;
    begin
        // [SCENARIO] Bifrost Report Request Preset is restricted from generic Data.Records.Set
        Assert.IsTrue(
            TempArgument.IsTableWriteRestrictedForDataRecords(Database::"Report Request Preset ori"),
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
