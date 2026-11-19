namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.Reflection;
using System.TestLibraries.Utilities;

/// <summary>
/// Issue #244: a missing or unknown parameter of the Entry, JobQueueEntry, Playbook and Report types answers
/// MissingParameter, RecordNotFound, InvalidParameter or InvalidParameterFormat with the parameter name and a
/// nextStep, not the generic BusinessCentralError.
/// </summary>
codeunit 96447 "Orch Param Error Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    /// <summary>Playbook.Run without playbookCode or subject answers MissingParameter on playbookCode.</summary>
    [Test]
    procedure Scenario_PlaybookRun_MissingCode_AnswersMissingParameter()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Playbook Msg Handler ori";
    begin
        // [GIVEN] A request with no playbookCode and no subject.
        CreateArgument(TempArgument, '{}');
        // [WHEN] Playbook.Run executes.
        asserterror Handler.ExecuteRun(TempArgument);
        // [THEN] One structured MissingParameter error names playbookCode and says what to do.
        AssertSingleError(TempArgument, 'MissingParameter', 'playbookCode', '');
    end;

    /// <summary>Playbook.Run with a code that no playbook has answers RecordNotFound with the code received.</summary>
    [Test]
    procedure Scenario_PlaybookRun_UnknownCode_AnswersRecordNotFound()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Playbook Msg Handler ori";
    begin
        // [GIVEN] A playbook code that does not exist.
        CreateArgument(TempArgument, '{"playbookCode":"NOSUCH-244"}');
        // [WHEN] Playbook.Run executes.
        asserterror Handler.ExecuteRun(TempArgument);
        // [THEN] RecordNotFound on playbookCode, with the received code.
        AssertSingleError(TempArgument, 'RecordNotFound', 'playbookCode', 'NOSUCH-244');
    end;

    /// <summary>Playbook.Verify with an unknown code answers RecordNotFound too.</summary>
    [Test]
    procedure Scenario_PlaybookVerify_UnknownCode_AnswersRecordNotFound()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Verify: Codeunit "Playbook Verify ori";
    begin
        // [GIVEN] A playbook code that does not exist, sent as the subject.
        CreateArgument(TempArgument, '{}');
        TempArgument.Subject := 'NOSUCH-244';
        TempArgument.Modify();
        // [WHEN] Playbook.Verify executes.
        asserterror Verify.ExecuteVerify(TempArgument);
        // [THEN] RecordNotFound on playbookCode.
        AssertSingleError(TempArgument, 'RecordNotFound', 'playbookCode', 'NOSUCH-244');
    end;

    /// <summary>Entry.Run without an id answers MissingParameter on id.</summary>
    [Test]
    procedure Scenario_EntryRun_MissingId_AnswersMissingParameter()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "SE Msg Handler ori";
    begin
        // [GIVEN] A request without id and without a GUID subject.
        CreateArgument(TempArgument, '{}');
        // [WHEN] Entry.Run executes.
        asserterror Handler.ExecuteRun(TempArgument);
        // [THEN] MissingParameter on id.
        AssertSingleError(TempArgument, 'MissingParameter', 'id', '');
    end;

    /// <summary>Entry.Restart with a GUID that no orchestrator entry has answers RecordNotFound (edge: well-formed but unknown).</summary>
    [Test]
    procedure Scenario_EntryRestart_UnknownId_AnswersRecordNotFound()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "SE Msg Handler ori";
        UnknownId: Guid;
    begin
        // [GIVEN] A new GUID that no entry has.
        UnknownId := CreateGuid();
        CreateArgument(TempArgument, '{"id":"' + Format(UnknownId, 0, 4) + '"}');
        // [WHEN] Entry.Restart executes.
        asserterror Handler.ExecuteRestart(TempArgument);
        // [THEN] RecordNotFound on id, with the GUID received.
        AssertSingleError(TempArgument, 'RecordNotFound', 'id', Format(UnknownId, 0, 4));
    end;

    /// <summary>JobQueueEntry.Restart with an unknown SystemId answers RecordNotFound.</summary>
    [Test]
    procedure Scenario_JobQueueEntryRestart_UnknownId_AnswersRecordNotFound()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Entry Msg Handler ori";
        UnknownId: Guid;
    begin
        // [GIVEN] A new GUID that no Job Queue Entry has.
        UnknownId := CreateGuid();
        CreateArgument(TempArgument, '{"id":"' + Format(UnknownId, 0, 4) + '"}');
        // [WHEN] JobQueueEntry.Restart executes.
        asserterror Handler.ExecuteRestart(TempArgument);
        // [THEN] RecordNotFound on id.
        AssertSingleError(TempArgument, 'RecordNotFound', 'id', Format(UnknownId, 0, 4));
    end;

    /// <summary>Report.Get without reportId answers MissingParameter on reportId.</summary>
    [Test]
    procedure Scenario_ReportGet_MissingReportId_AnswersMissingParameter()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Msg Handler ori";
    begin
        CreateArgument(TempArgument, '{}');
        asserterror Handler.ExecuteGet(TempArgument);
        AssertSingleError(TempArgument, 'MissingParameter', 'reportId', '');
    end;

    /// <summary>Report.Get with a report ID that does not exist answers RecordNotFound.</summary>
    [Test]
    procedure Scenario_ReportGet_UnknownReport_AnswersRecordNotFound()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Msg Handler ori";
    begin
        CreateArgument(TempArgument, '{"reportId":999999999}');
        asserterror Handler.ExecuteGet(TempArgument);
        AssertSingleError(TempArgument, 'RecordNotFound', 'reportId', '999999999');
        Assert.ExpectedError('Report 999999999 not found');
    end;

    /// <summary>Report.Get with a reportId that is not a number answers InvalidParameterFormat (invalid input).</summary>
    [Test]
    procedure Scenario_ReportGet_TextReportId_AnswersInvalidParameterFormat()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Msg Handler ori";
    begin
        CreateArgument(TempArgument, '{"reportId":"abc"}');
        asserterror Handler.ExecuteGet(TempArgument);
        AssertSingleError(TempArgument, 'InvalidParameterFormat', 'reportId', '"abc"');
    end;

    /// <summary>Report.SaveAs with an unknown format answers InvalidParameter on format.</summary>
    [Test]
    procedure Scenario_ReportSaveAs_UnknownFormat_AnswersInvalidParameter()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Msg Handler ori";
    begin
        CreateArgument(TempArgument, '{"reportId":' + Format(FindAnyNonProcessingReport()) + ',"format":"BANANA"}');
        asserterror Handler.ExecuteSaveAs(TempArgument);
        AssertSingleError(TempArgument, 'InvalidParameter', 'format', 'BANANA');
    end;

    /// <summary>In is-IS (1039) the error and nextStep of a missing parameter are Icelandic.</summary>
    [Test]
    procedure Scenario_PlaybookRun_MissingCode_Icelandic()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Playbook Msg Handler ori";
        Entry: JsonObject;
        PreviousLanguage: Integer;
    begin
        // [GIVEN] The session language is Icelandic.
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(1039);
        CreateArgument(TempArgument, '{}');
        // [WHEN] Playbook.Run executes without playbookCode.
        asserterror Handler.ExecuteRun(TempArgument);
        Entry := AssertSingleError(TempArgument, 'MissingParameter', 'playbookCode', '');
        GlobalLanguage(PreviousLanguage);
        // [THEN] The texts are the Icelandic ones.
        Assert.AreEqual('Beiðni verður að innihalda "playbookCode" í gagnahleðslunni eða sem viðfang.', GetText(Entry, 'error'), 'is-IS error');
        Assert.AreEqual('Sendu kóða verkáætlunarinnar í data.playbookCode eða sem viðfang.', GetText(Entry, 'nextStep'), 'is-IS nextStep');
    end;

    local procedure AssertSingleError(var TempArgument: Record "Message Argument ori" temporary; ExpectedCode: Text; ExpectedParameter: Text; ExpectedReceived: Text) Entry: JsonObject
    var
        Errors: JsonArray;
        Token: JsonToken;
    begin
        Errors := TempArgument.GetCollectedErrorsJson();
        Assert.AreEqual(1, Errors.Count(), 'Exactly one structured error is collected');
        Errors.Get(0, Token);
        Entry := Token.AsObject();
        Assert.AreEqual(ExpectedCode, GetText(Entry, 'code'), 'Error code');
        Assert.AreEqual(ExpectedParameter, GetText(Entry, 'parameter'), 'Parameter name');
        Assert.AreEqual(ExpectedReceived, GetText(Entry, 'received'), 'Received value');
        Assert.AreNotEqual('', GetText(Entry, 'nextStep'), 'A nextStep is given');
        Assert.AreNotEqual('', GetText(Entry, 'expected'), 'The expected value is described');
    end;

    local procedure GetText(Entry: JsonObject; KeyName: Text): Text
    var
        Token: JsonToken;
    begin
        if Entry.Get(KeyName, Token) then
            if Token.IsValue() then
                exit(Token.AsValue().AsText());
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
}
