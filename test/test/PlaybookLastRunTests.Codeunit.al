namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;
using System.Threading;

/// <summary>
/// Issue #107: every run type (Orchestrator.Playbook.Run, Orchestrator.Playbook.Enqueue and a scheduled
/// run) leaves the same trace on the playbook header: LastRunInstanceID, LastRunAt and LastRunStatus,
/// Running while in flight and Completed or Failed when the run ends. Each scenario runs in en-US
/// (1033) and is-IS (1039) and asserts the localized status caption.
/// </summary>
codeunit 96432 "Playbook Last Run Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        Lib: Codeunit "Playbook Test Library ori";
        RequestFormat1Tok: Label '{"playbookCode":"%1","ignoreWarnings":true}', Locked = true;
        RequestFormat2Tok: Label '{"tableName":"Playbook ori","tableView":"WHERE(Code=CONST(%1))"}', Locked = true;
        RequestFormat3Tok: Label '{"playbookCode":"%1","initialRequest":{"marker":"enqueued"}}', Locked = true;
        RequestFormat4Tok: Label '{"reportId":%1}', Locked = true;
        PlaybookCodeTok: Label 'LASTRUN-107', Locked = true;
        CompletedTxt: Label 'Completed', Locked = true;
        CompletedIsTxt: Label 'Lokið', Locked = true;
        FailedTxt: Label 'Failed', Locked = true;
        FailedIsTxt: Label 'Mistókst', Locked = true;

    [Test]
    procedure PlaybookRun_StampsHeader()
    begin
        VerifyRunStampsHeader(1033, CompletedTxt);
    end;

    [Test]
    procedure PlaybookRun_StampsHeader_Icelandic()
    begin
        VerifyRunStampsHeader(1039, CompletedIsTxt);
    end;

    [Test]
    procedure PlaybookEnqueue_ThenJobQueueRun_StampsHeader()
    begin
        VerifyEnqueueStampsHeader(1033, CompletedTxt);
    end;

    [Test]
    procedure PlaybookEnqueue_ThenJobQueueRun_StampsHeader_Icelandic()
    begin
        VerifyEnqueueStampsHeader(1039, CompletedIsTxt);
    end;

    [Test]
    procedure ScheduledRun_StampsHeader()
    begin
        VerifyScheduledStampsHeader(1033, CompletedTxt);
    end;

    [Test]
    procedure ScheduledRun_StampsHeader_Icelandic()
    begin
        VerifyScheduledStampsHeader(1039, CompletedIsTxt);
    end;

    [Test]
    procedure FailedRun_StampsHeaderFailed()
    begin
        VerifyFailedRunStampsHeader(1033, FailedTxt);
    end;

    [Test]
    procedure FailedRun_StampsHeaderFailed_Icelandic()
    begin
        VerifyFailedRunStampsHeader(1039, FailedIsTxt);
    end;

    /// <summary>A second run replaces the first run's instance on the header (edge case).</summary>
    [Test]
    procedure SecondRun_ReplacesTheFirst()
    var
        Playbook: Record "Playbook ori";
        FirstInstanceId: Guid;
        SecondInstanceId: Guid;
    begin
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Help.Implementation.Get", HelpRequest(), 0, '', 0);

        Lib.RunPlaybook(PlaybookCodeTok, FirstInstanceId);
        Lib.RunPlaybook(PlaybookCodeTok, SecondInstanceId);

        Playbook.Get(PlaybookCodeTok);
        Assert.AreNotEqual(FirstInstanceId, SecondInstanceId, 'Two runs, two instances');
        Assert.AreEqual(SecondInstanceId, Playbook."Last Run Instance ID", 'The header points at the latest run');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    /// <summary>A playbook without steps still stamps its header (edge case).</summary>
    [Test]
    procedure EmptyPlaybook_StampsHeaderCompleted()
    var
        Playbook: Record "Playbook ori";
        InstanceId: Guid;
    begin
        Lib.CreatePlaybook(PlaybookCodeTok);

        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);

        Playbook.Get(PlaybookCodeTok);
        Assert.AreEqual(InstanceId, Playbook."Last Run Instance ID", 'Instance on the header');
        Assert.AreEqual(Playbook."Last Run Status"::Completed, Playbook."Last Run Status", 'Completed');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    /// <summary>
    /// While a run is in flight the header says Running and points at that instance, so a run that is
    /// abandoned mid-flight never leaves the previous run's Completed behind (AC2). A step reads the header
    /// through Data.Records.Get while the run is still going.
    /// </summary>
    [Test]
    procedure HeaderIsRunningWhileTheRunIsInFlight()
    var
        Playbook: Record "Playbook ori";
        StepLog: Record "Playbook Step Log ori";
        InstanceId: Guid;
        PreviousInstanceId: Guid;
        Response: Text;
    begin
        // [GIVEN] A playbook whose header still shows an earlier, completed run, and whose only step reads that header
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Data.Records.Get",
            StrSubstNo(RequestFormat2Tok, PlaybookCodeTok), 0, '', 0);
        PreviousInstanceId := CreateGuid();
        Playbook.Get(PlaybookCodeTok);
        Playbook."Last Run Status" := Playbook."Last Run Status"::Completed;
        Playbook."Last Run Instance ID" := PreviousInstanceId;
        Playbook.Modify();
        // [WHEN] It runs; the step reads the header mid-run
        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);
        // [THEN] The step saw Running and its own instance, not the earlier Completed
        StepLog.Get(InstanceId, 10, 0);
        Response := StepLog.GetResponseReceived();
        Assert.IsTrue(Response.Contains('Running'), 'The header reads Running in flight: ' + Response);
        Assert.IsFalse(Response.ToLower().Contains(Format(PreviousInstanceId, 0, 4).ToLower()), 'The earlier instance is gone from the header');
        Assert.IsTrue(Response.ToLower().Contains(Format(InstanceId, 0, 4).ToLower()), 'The header points at the run in flight');
        // [THEN] After the run the header says Completed
        Playbook.Get(PlaybookCodeTok);
        Assert.AreEqual(Playbook."Last Run Status"::Completed, Playbook."Last Run Status", 'Completed after the run');
        Lib.Cleanup(PlaybookCodeTok);
    end;

    local procedure VerifyRunStampsHeader(LanguageId: Integer; ExpectedCaption: Text)
    var
        Playbook: Record "Playbook ori";
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Playbook Msg Handler ori";
        ResponseJson: JsonObject;
        Token: JsonToken;
        StartedAt: DateTime;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] Orchestrator.Playbook.Run leaves instance, status and time on the header
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Help.Implementation.Get", HelpRequest(), 0, '', 0);
        Commit();
        CreateArgument(TempArgument, StrSubstNo(RequestFormat1Tok, PlaybookCodeTok));
        StartedAt := CurrentDateTime();

        Handler.ExecuteRun(TempArgument);

        ResponseJson := TempArgument.GetResponseJson();
        ResponseJson.Get('instanceId', Token);
        Playbook.Get(PlaybookCodeTok);
        AssertHeader(Playbook, Token.AsValue().AsText(), StartedAt, ExpectedCaption);
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyEnqueueStampsHeader(LanguageId: Integer; ExpectedCaption: Text)
    var
        Playbook: Record "Playbook ori";
        JQEntry: Record "Job Queue Entry";
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Playbook Msg Handler ori";
        LibraryOrchestrator: Codeunit "Library Orchestrator";
        ResponseJson: JsonObject;
        Token: JsonToken;
        StartedAt: DateTime;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] Orchestrator.Playbook.Enqueue followed by the Job Queue run leaves the same trace
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Help.Implementation.Get", HelpRequest(), 0, '', 0);
        Commit();
        CreateArgument(TempArgument, StrSubstNo(RequestFormat3Tok, PlaybookCodeTok));

        // [GIVEN] The playbook is enqueued (the enqueue itself is intercepted; no real job is scheduled)
        LibraryOrchestrator.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryOrchestrator);
        Handler.ExecuteEnqueue(TempArgument);
        UnbindSubscription(LibraryOrchestrator);
        ResponseJson := TempArgument.GetResponseJson();
        Assert.IsTrue(ResponseJson.Get('jobQueueEntryId', Token), 'The enqueue answers with the Job Queue Entry');
        Playbook.Get(PlaybookCodeTok);
        JQEntry.SetRange("Record ID to Process", Playbook.RecordId());
        JQEntry.FindFirst();
        Commit();
        StartedAt := CurrentDateTime();

        // [WHEN] The Job Queue fires the dispatcher for that entry
        Codeunit.Run(Codeunit::"Playbook JQ Dispatcher ori", JQEntry);

        // [THEN] The header points at the instance of that run
        Playbook.Get(PlaybookCodeTok);
        AssertHeader(Playbook, Format(Playbook."Last Run Instance ID", 0, 4), StartedAt, ExpectedCaption);
        AssertInstanceOfPlaybook(Playbook);
        JQEntry.Delete(true);
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyScheduledStampsHeader(LanguageId: Integer; ExpectedCaption: Text)
    var
        Playbook: Record "Playbook ori";
        JQEntry: Record "Job Queue Entry";
        StartedAt: DateTime;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] A scheduled run (the Job Queue entry of the orchestrator entry, with no parameter row) leaves the same trace
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Help.Implementation.Get", HelpRequest(), 0, '', 0);
        Playbook.Get(PlaybookCodeTok);
        JQEntry.Init();
        JQEntry.ID := CreateGuid();
        JQEntry."Object Type to Run" := JQEntry."Object Type to Run"::Codeunit;
        JQEntry."Object ID to Run" := Codeunit::"Playbook JQ Dispatcher ori";
        JQEntry."Record ID to Process" := Playbook.RecordId();
        Commit();
        StartedAt := CurrentDateTime();

        Codeunit.Run(Codeunit::"Playbook JQ Dispatcher ori", JQEntry);

        Playbook.Get(PlaybookCodeTok);
        AssertHeader(Playbook, Format(Playbook."Last Run Instance ID", 0, 4), StartedAt, ExpectedCaption);
        AssertInstanceOfPlaybook(Playbook);
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifyFailedRunStampsHeader(LanguageId: Integer; ExpectedCaption: Text)
    var
        Playbook: Record "Playbook ori";
        Instance: Record "Playbook Instance ori";
        InstanceId: Guid;
        StartedAt: DateTime;
        PreviousLanguage: Integer;
    begin
        // [SCENARIO] A run that fails leaves Failed on the header
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Lib.CreatePlaybook(PlaybookCodeTok);
        Lib.AddStep(PlaybookCodeTok, 10, "Playbook Step Type ori"::Action, "Message Type ori"::"Orchestrator.Report.Run",
            StrSubstNo(RequestFormat4Tok, Report::"Test Failing Report"), 0, '', 0);
        Lib.AddSuccessCondition(PlaybookCodeTok, 10, 'status', 'Success');
        StartedAt := CurrentDateTime();

        Lib.RunPlaybook(PlaybookCodeTok, InstanceId);

        Instance.Get(InstanceId);
        Assert.AreEqual(Instance.Status::Failed, Instance.Status, 'The run failed');
        Playbook.Get(PlaybookCodeTok);
        Assert.AreEqual(InstanceId, Playbook."Last Run Instance ID", 'Instance on the header');
        Assert.AreEqual(Playbook."Last Run Status"::Failed, Playbook."Last Run Status", 'Failed on the header');
        Assert.AreEqual(ExpectedCaption, Format(Playbook."Last Run Status"), 'Localized caption');
        Assert.IsTrue(Playbook."Last Run At" >= StartedAt - 1000, 'Last Run At is set');
        Lib.Cleanup(PlaybookCodeTok);
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure AssertHeader(Playbook: Record "Playbook ori"; ExpectedInstanceId: Text; StartedAt: DateTime; ExpectedCaption: Text)
    var
        Instance: Record "Playbook Instance ori";
    begin
        Assert.AreEqual(ExpectedInstanceId.ToLower(), Format(Playbook."Last Run Instance ID", 0, 4).ToLower(), 'LastRunInstanceID points at the run');
        Assert.AreEqual(Playbook."Last Run Status"::Completed, Playbook."Last Run Status", 'LastRunStatus is the instance status');
        Assert.AreEqual(ExpectedCaption, Format(Playbook."Last Run Status"), 'LastRunStatus caption is localized');
        Assert.IsTrue(Playbook."Last Run At" >= StartedAt - 1000, 'LastRunAt is set by the run');
        Instance.Get(Playbook."Last Run Instance ID");
        Assert.AreEqual(Instance.Status, Playbook."Last Run Status", 'Header and instance agree');
    end;

    local procedure AssertInstanceOfPlaybook(Playbook: Record "Playbook ori")
    var
        Instance: Record "Playbook Instance ori";
    begin
        Instance.Get(Playbook."Last Run Instance ID");
        Assert.AreEqual(Playbook.Code, Instance."Playbook Code", 'The instance belongs to the playbook');
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

    local procedure HelpRequest(): Text
    begin
        exit('{"messageTypes":["Orchestrator.Playbook.Schedule"],"chapters":["parameters"]}');
    end;
}
