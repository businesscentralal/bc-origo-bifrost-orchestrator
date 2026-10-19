namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;

/// <summary>PR #67 report input and error-response regressions through the actual message implementations.</summary>
codeunit 96454 "Report Boundary Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        DebugWarningSeen: Boolean;

    /// <summary>Rejects UnknownField before Run executes a report.</summary>
    [Test]
    procedure Run_UnknownField_ReturnsErrorWithoutExecution()
    begin
        // PR #67 B4 | Time: independent of Today/WorkDate | Risk: Foundation view validation.
        // [GIVEN] A report with a known data item and an invalid caller view.
        // [WHEN/THEN] The message responds with a structured error and no report marker.
        AssertRejectedView(false, 'WHERE(XUnknown=CONST(1))', 'InvalidFilterField', false);
    end;

    /// <summary>Rejects MalformedView before Run executes a report.</summary>
    [Test]
    procedure Run_MalformedView_ReturnsErrorWithoutExecution()
    begin
        // PR #67 B4 | Time: independent of Today/WorkDate | Risk: Foundation view validation.
        // [GIVEN] A report with a known data item and an invalid caller view.
        // [WHEN/THEN] The message responds with a structured error and no report marker.
        AssertRejectedView(false, 'WHERE(Number=CONST(1)', 'InvalidFilterField', false);
    end;

    /// <summary>Rejects NonString before Run executes a report.</summary>
    [Test]
    procedure Run_NonString_ReturnsErrorWithoutExecution()
    begin
        // PR #67 B4 | Time: independent of Today/WorkDate | Risk: Foundation view validation.
        // [GIVEN] A report with a known data item and an invalid caller view.
        // [WHEN/THEN] The message responds with a structured error and no report marker.
        AssertRejectedView(false, '{}', 'InvalidParameterFormat', true);
    end;

    /// <summary>Rejects UnknownField before SaveAs executes a report.</summary>
    [Test]
    procedure SaveAs_UnknownField_ReturnsErrorWithoutExecution()
    begin
        // PR #67 B4 | Time: independent of Today/WorkDate | Risk: Foundation view validation.
        // [GIVEN] A report with a known data item and an invalid caller view.
        // [WHEN/THEN] The message responds with a structured error and no report marker.
        AssertRejectedView(true, 'WHERE(XUnknown=CONST(1))', 'InvalidFilterField', false);
    end;

    /// <summary>Rejects an unknown filter field before rendering Pdf output and retains recovery guidance.</summary>
    [Test]
    procedure Scenario_AC01_PdfInvalidField_ReturnsError()
    begin
        // Issue #85, AC01 | Time: independent of Today/WorkDate | Risk: Foundation error serialization.
        // [GIVEN] A report with a known data item and an invalid caller view.
        // [WHEN/THEN] Format selection must not turn a validation error into empty binary success.
        AssertRejectedView(true, 'WHERE(XUnknown=CONST(1))', 'InvalidFilterField', false, 'PDF');
    end;

    /// <summary>Rejects an unknown filter field before rendering DefaultPdf output and retains recovery guidance.</summary>
    [Test]
    procedure Scenario_AC01_DefaultPdfInvalidField_ReturnsError()
    begin
        // Issue #85, AC01 | Time: independent of Today/WorkDate | Risk: Foundation error serialization.
        // [GIVEN] A report with a known data item and an invalid caller view.
        // [WHEN/THEN] Format selection must not turn a validation error into empty binary success.
        AssertRejectedView(true, 'WHERE(XUnknown=CONST(1))', 'InvalidFilterField', false, '');
    end;

    /// <summary>Rejects an unknown filter field before rendering Excel output and retains recovery guidance.</summary>
    [Test]
    procedure Scenario_AC01_ExcelInvalidField_ReturnsError()
    begin
        // Issue #85, AC01 | Time: independent of Today/WorkDate | Risk: Foundation error serialization.
        // [GIVEN] A report with a known data item and an invalid caller view.
        // [WHEN/THEN] Format selection must not turn a validation error into empty binary success.
        AssertRejectedView(true, 'WHERE(XUnknown=CONST(1))', 'InvalidFilterField', false, 'Excel');
    end;

    /// <summary>Rejects an unknown filter field before rendering Word output and retains recovery guidance.</summary>
    [Test]
    procedure Scenario_AC01_WordInvalidField_ReturnsError()
    begin
        // Issue #85, AC01 | Time: independent of Today/WorkDate | Risk: Foundation error serialization.
        // [GIVEN] A report with a known data item and an invalid caller view.
        // [WHEN/THEN] Format selection must not turn a validation error into empty binary success.
        AssertRejectedView(true, 'WHERE(XUnknown=CONST(1))', 'InvalidFilterField', false, 'Word');
    end;

    /// <summary>Rejects MalformedView before SaveAs executes a report.</summary>
    [Test]
    procedure SaveAs_MalformedView_ReturnsErrorWithoutExecution()
    begin
        // PR #67 B4 | Time: independent of Today/WorkDate | Risk: Foundation view validation.
        // [GIVEN] A report with a known data item and an invalid caller view.
        // [WHEN/THEN] The message responds with a structured error and no report marker.
        AssertRejectedView(true, 'WHERE(Number=CONST(1)', 'InvalidFilterField', false);
    end;

    /// <summary>Rejects NonString before SaveAs executes a report.</summary>
    [Test]
    procedure SaveAs_NonString_ReturnsErrorWithoutExecution()
    begin
        // PR #67 B4 | Time: independent of Today/WorkDate | Risk: Foundation view validation.
        // [GIVEN] A report with a known data item and an invalid caller view.
        // [WHEN/THEN] The message responds with a structured error and no report marker.
        AssertRejectedView(true, '{}', 'InvalidParameterFormat', true);
    end;

    /// <summary>A valid filter limits the XML report data set to one row.</summary>
    [Test]
    procedure SaveAs_ValidView_ExecutesOnlySelectedRow()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Marker: Record "Test Run Marker";
        MessageImpl: Codeunit "Report SaveAs Msg ori";
        BeforeCount: Integer;
    begin
        // PR #67 B4 | Time: independent of Today/WorkDate | Risk: Report.SaveAs filters.
        // [GIVEN] A two-row output report and a view selecting only row 1.
        BeforeCount := Marker.Count();
        CreateArgument(TempArgument, true, 'WHERE(Number=CONST(1))', false);
        Commit();
        // [WHEN] The public message implementation renders the report.
        MessageImpl.ExecuteBifrostTask(TempArgument);
        // [THEN] Exactly one row ran and output was returned.
        Assert.AreEqual(BeforeCount + 1, Marker.Count(), 'The view must not widen the report data set.');
        TempArgument.CalcFields("Response Content");
        Assert.IsTrue(TempArgument."Response Content".HasValue(), 'A valid view must produce report output.');
    end;

    /// <summary>A valid processing report filter runs exactly one selected row.</summary>
    [Test]
    procedure Run_ValidView_ExecutesSelectedRow()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Marker: Record "Test Run Marker";
        MessageImpl: Codeunit "Report Run Msg ori";
        ResponseJson: JsonObject;
        Token: JsonToken;
        BeforeCount: Integer;
    begin
        // PR #67 B4 | Time: independent of Today/WorkDate | Risk: Report.Run filters.
        BeforeCount := Marker.Count();
        CreateArgument(TempArgument, false, 'WHERE(Number=CONST(1))', false);
        Commit();
        MessageImpl.ExecuteBifrostTask(TempArgument);
        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('status', Token);
        Assert.AreEqual('Success', Token.AsValue().AsText(), 'Expected successful report execution.');
        Assert.AreEqual(BeforeCount + 1, Marker.Count(), 'Exactly the selected row must run.');
        ResponseJson.Get('tableView', Token);
        Assert.AreEqual('WHERE(Number=CONST(1))', Token.AsValue().AsText(), 'Preserve the accepted request echo.');
    end;

    /// <summary>An empty selection must not run the processing report data item.</summary>
    [Test]
    procedure Run_EmptySelection_DoesNotWidenDataSet()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Marker: Record "Test Run Marker";
        MessageImpl: Codeunit "Report Run Msg ori";
        BeforeCount: Integer;
    begin
        // PR #67 B4 | Time: independent of Today/WorkDate | Risk: empty view selection.
        BeforeCount := Marker.Count();
        CreateArgument(TempArgument, false, 'WHERE(Number=FILTER(1&2))', false);
        Commit();
        MessageImpl.ExecuteBifrostTask(TempArgument);
        Assert.AreEqual(BeforeCount, Marker.Count(), 'An empty selection must not become an unfiltered report.');
    end;

    /// <summary>Report errors never expose call stacks in either request-debug state.</summary>
    [Test]
    [HandlerFunctions('DebugWarningHandler')]
    procedure Run_BothDebugStates_FailureHasNoCallstack()
    begin
        // PR #67 B4 | Time: independent of Today/WorkDate | Risk: request logging state.
        DebugWarningSeen := false;
        AssertFailureHasNoCallstack(false);
        AssertFailureHasNoCallstack(true);
        Assert.IsTrue(DebugWarningSeen, 'Enabling request debugging must raise the real warning notification.');
    end;

    /// <summary>Validates debug and known unprovisioned-setup notifications without changing external permissions.</summary>
    /// <param name="DebugNotification">The setup-page warning notification.</param>
    /// <returns>False to keep the warning local to the test handler.</returns>
    [SendNotificationHandler]
    procedure DebugWarningHandler(var DebugNotification: Notification): Boolean
    begin
        case LowerCase(Format(DebugNotification.Id, 0, 4)) of
            'b8e2a714-5c3f-4d91-ae07-6f9d1c4b8e25':
                begin
                    Assert.IsTrue(StrPos(DebugNotification.Message, 'Request Debug Mode') = 1, 'Expected the debug warning text.');
                    DebugWarningSeen := true;
                end;
            'a7b3c91d-4e8f-4a2b-9c6d-1f5e8a3b7d02':
                Assert.IsTrue(StrPos(DebugNotification.Message, 'HTTP client requests are not enabled for:') = 1, 'Expected the disposable setup HTTP warning.');
            'd8e7f6a5-4b3c-4d2e-9f1a-8c7b6a5d4e3f':
                Assert.IsTrue(StrPos(DebugNotification.Message, 'The Bifrost End-User License Agreement has not been approved') = 1, 'Expected the disposable setup EULA warning.');
            else
                Assert.Fail('Unexpected setup notification: ' + DebugNotification.Message);
        end;
        exit(false);
    end;

    local procedure AssertFailureHasNoCallstack(DebugMode: Boolean)
    var
        Setup: Record "Setup ori";
        TempArgument: Record "Message Argument ori" temporary;
        MessageImpl: Codeunit "Report Run Msg ori";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        Token: JsonToken;
        OriginalDebugMode: Boolean;
        SetupPage: TestPage "Setup ori";
    begin
        OriginalDebugMode := Setup.GetRequestDebugMode();
        SetupPage.OpenEdit();
        SetupPage."Request Debug Mode".SetValue(DebugMode);
        SetupPage.Close();
        Commit();
        Assert.AreEqual(DebugMode, Setup.GetRequestDebugMode(), 'The debug state must actually be applied.');
        RequestJson.Add('reportId', Report::"Test Failing Report");
        TempArgument.Init();
        TempArgument.Insert();
        TempArgument.SetRequestJson(RequestJson);
        MessageImpl.ExecuteBifrostTask(TempArgument);
        ResponseJson := TempArgument.GetResponseJson();
        SetupPage.OpenEdit();
        SetupPage."Request Debug Mode".SetValue(OriginalDebugMode);
        SetupPage.Close();
        Commit();
        ResponseJson.Get('status', Token);
        Assert.AreEqual('Error', Token.AsValue().AsText(), 'The failing report must return an error.');
        ResponseJson.Get('error', Token);
        Assert.AreEqual('Deliberate failure from the test report.', Token.AsValue().AsText(), 'Retain the report failure text.');
        Assert.IsFalse(ResponseJson.Contains('callstack'), 'Debug mode must never expose the call stack.');
    end;

    local procedure AssertRejectedView(SaveAs: Boolean; ViewText: Text; ExpectedCode: Text; ObjectView: Boolean)
    begin
        AssertRejectedView(SaveAs, ViewText, ExpectedCode, ObjectView, 'XML');
    end;

    local procedure AssertRejectedView(SaveAs: Boolean; ViewText: Text; ExpectedCode: Text; ObjectView: Boolean; OutputFormat: Text)
    var
        TempArgument: Record "Message Argument ori" temporary;
        Marker: Record "Test Run Marker";
        MessageImpl: Interface "Msg Interface ori";
        ResponseJson: JsonObject;
        Token: JsonToken;
        BeforeCount: Integer;
    begin
        BeforeCount := Marker.Count();
        CreateArgument(TempArgument, SaveAs, ViewText, ObjectView, OutputFormat);
        if SaveAs then
            MessageImpl := "Message Type ori"::"Orchestrator.Report.SaveAs"
        else
            MessageImpl := "Message Type ori"::"Orchestrator.Report.Run";
        Commit();
        MessageImpl.ExecuteBifrostTask(TempArgument);
        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('status', Token);
        Assert.AreEqual('Error', Token.AsValue().AsText(), 'Invalid views must return structured errors.');
        ResponseJson.Get('code', Token);
        Assert.AreEqual(ExpectedCode, Token.AsValue().AsText(), 'Expected a specific view-validation error.');
        Assert.AreEqual(TempArgument.GetContentTypeJson(), TempArgument."Content Type", 'Validation errors must remain JSON, not empty binary output.');
        Assert.IsTrue(ResponseJson.Get('parameter', Token), 'Identify the invalid request parameter.');
        Assert.AreEqual('tableView', Token.AsValue().AsText(), 'The error must identify tableView.');
        Assert.IsTrue(ResponseJson.Get('nextStep', Token), 'Provide a recovery step.');
        Assert.AreNotEqual('', Token.AsValue().AsText(), 'Recovery guidance must not be empty.');
        Assert.IsTrue(ResponseJson.Get('hint', Token), 'Provide message contract help.');
        Assert.IsTrue(Token.AsValue().AsText().Contains('Help.Implementation.Get'), 'The hint must name the contract discovery message.');
        Assert.IsFalse(ResponseJson.Contains('callstack'), 'Validation responses must never expose call stacks.');
        Assert.AreEqual(BeforeCount, Marker.Count(), 'Validation must precede report execution.');
    end;

    local procedure CreateArgument(var TempArgument: Record "Message Argument ori" temporary; SaveAs: Boolean; ViewText: Text; ObjectView: Boolean)
    begin
        CreateArgument(TempArgument, SaveAs, ViewText, ObjectView, 'XML');
    end;

    local procedure CreateArgument(var TempArgument: Record "Message Argument ori" temporary; SaveAs: Boolean; ViewText: Text; ObjectView: Boolean; OutputFormat: Text)
    var
        RequestJson: JsonObject;
        EmptyObject: JsonObject;
    begin
        if SaveAs then begin
            RequestJson.Add('reportId', Report::"Test Output Report ori");
            if OutputFormat <> '' then
                RequestJson.Add('format', OutputFormat);
        end else
            RequestJson.Add('reportId', Report::"Test Process Report");
        if ObjectView then
            RequestJson.Add('tableView', EmptyObject)
        else
            RequestJson.Add('tableView', ViewText);
        TempArgument.Init();
        if SaveAs then
            TempArgument.Type := "Message Type ori"::"Orchestrator.Report.SaveAs"
        else
            TempArgument.Type := "Message Type ori"::"Orchestrator.Report.Run";
        TempArgument.Insert();
        TempArgument.SetRequestJson(RequestJson);
    end;
}
