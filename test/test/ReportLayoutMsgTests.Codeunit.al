namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.Environment.Configuration;
using System.Reflection;

codeunit 96424 "Report Layout Msg Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure SetErrorsWhenReportIdMissing()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Layout Handler ori";
    begin
        // [SCENARIO] ReportLayout.Set requires reportId
        CreateArgument(TempArgument, '{"name":"x","layoutFormat":"Word","layoutBase64":"QQ=="}');

        asserterror Handler.ExecuteSet(TempArgument);
        Assert.ExpectedError('reportId');
    end;

    [Test]
    procedure SetErrorsWhenNameMissing()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Layout Handler ori";
        ReportId: Integer;
    begin
        // [SCENARIO] ReportLayout.Set requires name
        ReportId := FindAnyReportId();
        CreateArgument(TempArgument,
            '{"reportId": ' + Format(ReportId) + ', "layoutFormat":"Word","layoutBase64":"QQ=="}');

        asserterror Handler.ExecuteSet(TempArgument);
        Assert.ExpectedError('name');
    end;

    [Test]
    procedure SetErrorsForUnknownReport()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Layout Handler ori";
    begin
        // [SCENARIO] Unknown reportId fails with Report not found
        CreateArgument(TempArgument,
            '{"reportId": 999999999, "name":"origo test","layoutFormat":"Word","layoutBase64":"QQ=="}');

        asserterror Handler.ExecuteSet(TempArgument);
        Assert.ExpectedError('Report 999999999 not found');
    end;

    [Test]
    procedure SetErrorsForInvalidLayoutFormat()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Layout Handler ori";
        ReportId: Integer;
    begin
        // [SCENARIO] Invalid layoutFormat names the format and report
        ReportId := FindAnyReportId();
        CreateArgument(TempArgument,
            '{"reportId": ' + Format(ReportId) +
            ', "name":"origo test","layoutFormat":"BANANA","layoutBase64":"QQ=="}');

        asserterror Handler.ExecuteSet(TempArgument);
        Assert.ExpectedError('Layout format BANANA is not valid');
    end;

    [Test]
    procedure SetErrorsWhenLayoutBase64Missing()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Layout Handler ori";
        ReportId: Integer;
    begin
        // [SCENARIO] Empty/missing layoutBase64 is rejected before import
        ReportId := FindAnyReportId();
        CreateArgument(TempArgument,
            '{"reportId": ' + Format(ReportId) +
            ', "name":"origo test","layoutFormat":"Word","layoutBase64":""}');

        asserterror Handler.ExecuteSet(TempArgument);
        Assert.ExpectedError('layoutBase64');
    end;

    [Test]
    procedure MessageTypeIsRegistered()
    var
        MessageType: Enum "Message Type ori";
        Ordinal: Integer;
    begin
        // [SCENARIO] Orchestrator.ReportLayout.Set is registered on the message type enum
        MessageType := "Message Type ori"::"Orchestrator.ReportLayout.Set";
        Ordinal := MessageType.AsInteger();
        Assert.AreEqual(10035599, Ordinal, 'ReportLayout.Set enum ordinal');
    end;

    local procedure CreateArgument(var TempArgument: Record "Message Argument ori" temporary; RequestJsonText: Text)
    var
        RequestJson: JsonObject;
    begin
        RequestJson.ReadFrom(RequestJsonText);
        TempArgument.Init();
        TempArgument.Insert();
        TempArgument.SetRequestJson(RequestJson);
    end;

    local procedure FindAnyReportId(): Integer
    var
        ReportMeta: Record "Report Metadata";
    begin
        ReportMeta.SetLoadFields(ID);
        ReportMeta.FindFirst();
        exit(ReportMeta.ID);
    end;
}
