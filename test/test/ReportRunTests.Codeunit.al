namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.Reflection;
using System.TestTools.TestRunner;

/// <summary>
/// Tests for Orchestrator.Report.Run. Kept out of "Report Msg Tests" deliberately:
/// ExecuteRun goes through Codeunit.Run, and BC restricts that once the surrounding
/// transaction has written, so these tests must not share a transaction with the
/// preset tests that insert records.
/// </summary>
codeunit 96417 "Report Run Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure RunExecutesProcessingOnlyReport()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Marker: Record "Test Run Marker";
        Handler: Codeunit "Report Msg Handler ori";
        ResponseJson: JsonObject;
        Token: JsonToken;
        CountBefore: Integer;
    begin
        // [SCENARIO] Report.Run executes a processing-only report and reports success
        CountBefore := Marker.Count();

        CreateArgument(TempArgument, StrSubstNo(ReportIdRequestTok, Report::"Test Process Report"));
        Handler.ExecuteRun(TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('status', Token);
        Assert.AreEqual('Success', Token.AsValue().AsText(), 'Status should be Success');
        Assert.AreEqual(CountBefore + 1, Marker.Count(), 'The report should have written one marker');
    end;

    [Test]
    procedure RunEchoesReportMetadata()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Msg Handler ori";
        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] The response identifies which report ran
        CreateArgument(TempArgument, StrSubstNo(ReportIdRequestTok, Report::"Test Process Report"));
        Handler.ExecuteRun(TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('reportId', Token);
        Assert.AreEqual(Report::"Test Process Report", Token.AsValue().AsInteger(), 'reportId echo');
        ResponseJson.Get('usedPreset', Token);
        Assert.IsFalse(Token.AsValue().AsBoolean(), 'No preset was saved, so usedPreset should be false');
        Assert.IsTrue(ResponseJson.Contains('durationMs'), 'Response should report a duration');
    end;

    [Test]
    procedure RunReturnsErrorObjectWhenReportFails()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Msg Handler ori";
        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] A failing report is caught and returned, not thrown - and the call stack is
        // withheld, because it names objects, procedures and line numbers of the base application
        // and of every extension on the stack

        // [GIVEN] Request Debug Mode is off, which is the default
        CreateArgument(TempArgument, StrSubstNo(ReportIdRequestTok, Report::"Test Failing Report"));

        // [WHEN] a report that fails is run
        Handler.ExecuteRun(TempArgument);

        // [THEN] the failure is reported as data, not thrown
        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('status', Token);
        Assert.AreEqual('Error', Token.AsValue().AsText(), 'Status should be Error');
        ResponseJson.Get('error', Token);
        Assert.AreNotEqual('', Token.AsValue().AsText(), 'Error text should be captured');

        // [THEN] but the call stack is not handed to the caller
        Assert.IsFalse(ResponseJson.Contains('callstack'), 'The call stack must not be returned while Request Debug Mode is off');
    end;

    // The mirror case - Request Debug Mode ON, call stack present - is deliberately not a unit
    // test. Switching the flag on makes Foundation's "Request Logger ori" write inside the test
    // transaction, which is exactly the isolation breakage that
    // "Test Install".DisableRequestDebugMode exists to prevent; the run aborts with "An error
    // occurred and the transaction is stopped". Verify that branch through the MCP message-type
    // run instead.

    [Test]
    procedure RunRejectsReportThatProducesOutput()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Msg Handler ori";
    begin
        // [SCENARIO] Report.Run refuses a report with output - the inverse of SaveAs's guard
        CreateArgument(TempArgument, StrSubstNo(ReportIdRequestTok, FindAnyNonProcessingReport()));

        asserterror Handler.ExecuteRun(TempArgument);
        Assert.ExpectedError('produces output');
    end;

    [Test]
    procedure RunErrorsWhenReportIdMissing()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Msg Handler ori";
    begin
        // [SCENARIO] reportId is required
        CreateArgument(TempArgument, '{}');

        asserterror Handler.ExecuteRun(TempArgument);
        Assert.ExpectedError('reportId');
    end;

    [Test]
    procedure RunErrorsForNonExistentReport()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Msg Handler ori";
    begin
        // [SCENARIO] An unknown report ID is reported as not found
        CreateArgument(TempArgument, StrSubstNo(ReportIdRequestTok, 99999999));

        asserterror Handler.ExecuteRun(TempArgument);
        Assert.ExpectedError('not found');
    end;

    local procedure CreateArgument(var TempArgument: Record "Message Argument ori" temporary; RequestJsonText: Text)
    var
        RequestJson: JsonObject;
    begin
        TempArgument.Init();
        TempArgument.Insert();
        RequestJson.ReadFrom(RequestJsonText);
        TempArgument.SetRequestJson(RequestJson);
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

    var
        ReportIdRequestTok: Label '{"reportId": %1}', Locked = true;
}
