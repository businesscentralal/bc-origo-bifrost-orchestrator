namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.Environment;
using System.Threading;

/// <summary>
/// Unit tests for Orchestrator Data.Records companion hints (#19).
/// One test per owned restricted table — mirrors Foundation core PR #45 pattern.
/// </summary>
codeunit 96428 "Data Records Hint Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        JobQueueEntryWriteHintTxt: Label 'Orchestrator.Entry.Register / Orchestrator.Entry.Schedule / Orchestrator.JobQueueEntry.Restart', Locked = true;
        ScheduledTaskWriteHintTxt: Label 'Orchestrator.Status.Restart', Locked = true;
        ReportPresetHintTxt: Label 'Orchestrator.Report.Get / Orchestrator.Report.Run / Orchestrator.Report.SaveAs', Locked = true;
        SetRestrictedErr: Label 'Table %1 (%2) cannot be written via Data.Records.Set. This is an internal table.', Locked = true;
        GetRestrictedErr: Label 'Table %1 (%2) cannot be read via Data.Records.Get. This is an internal table.', Locked = true;

    local procedure RunMessageType(MessageType: Enum "Message Type ori"; RequestJson: Text) ResponseText: Text
    var
        MessageQueue: Record "Message ori";
        RequestData: BigText;
        ResponseBigText: BigText;
    begin
        MessageQueue.Init();
        MessageQueue.Type := MessageType;
        RequestData.AddText(RequestJson);
        MessageQueue.SetRequestData(RequestData);
        MessageQueue."Date & Time" := CurrentDateTime() + 10000;
        MessageQueue.Insert(true);
        Commit();
        Codeunit.Run(Codeunit::"Message Task ori", MessageQueue);
        ResponseBigText := MessageQueue.GetResponseData(0);
        ResponseBigText.GetSubText(ResponseText, 1);
    end;

    local procedure AssertErrorAndHint(ResponseText: Text; ExpectedError: Text; ExpectedHint: Text)
    var
        ResponseJson: JsonObject;
        StatusToken: JsonToken;
        ErrorToken: JsonToken;
        HintToken: JsonToken;
    begin
        Assert.IsTrue(ResponseJson.ReadFrom(ResponseText), 'Response should be valid JSON');
        Assert.IsTrue(ResponseJson.Get('status', StatusToken), 'status missing');
        Assert.AreEqual('Error', StatusToken.AsValue().AsText(), 'status');
        Assert.IsTrue(ResponseJson.Get('error', ErrorToken), 'error missing');
        Assert.AreEqual(ExpectedError, ErrorToken.AsValue().AsText(), 'error text');
        Assert.IsTrue(ResponseJson.Get('hint', HintToken), 'hint missing');
        Assert.AreEqual(ExpectedHint, HintToken.AsValue().AsText(), 'dedicated hint');
    end;

    [Test]
    procedure JobQueueEntry_WriteHint()
    var
        TempArgument: Record "Message Argument ori" temporary;
        TableName: Text;
        BaseError: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] Data.Records.Set on Job Queue Entry names Orchestrator Entry/Schedule/Restart types
        TempArgument.Init();
        Assert.IsTrue(TempArgument.IsTableWriteRestrictedForDataRecords(Database::"Job Queue Entry"), 'Job Queue Entry write-restricted');
        Assert.AreEqual(JobQueueEntryWriteHintTxt, TempArgument.GetDedicatedMessageTypeHintForWrite(Database::"Job Queue Entry"), 'write companion hint');
        Assert.AreEqual(JobQueueEntryWriteHintTxt, TempArgument.GetDedicatedMessageTypeHintForField(Database::"Job Queue Entry", 1), 'field companion hint');

        TableName := TempArgument.GetTableName(Database::"Job Queue Entry");
        BaseError := StrSubstNo(SetRestrictedErr, Database::"Job Queue Entry", TableName);
        ResponseText := RunMessageType(
            "Message Type ori"::"Data.Records.Set",
            '{"tableName":"Job Queue Entry","data":[{"primaryKey":{"ID":"00000000-0000-0000-0000-000000000001"},"fields":{}}]}');
        AssertErrorAndHint(ResponseText, BaseError + ' Use ' + JobQueueEntryWriteHintTxt + '.', JobQueueEntryWriteHintTxt);
    end;

    [Test]
    procedure ScheduledTask_WriteHint()
    var
        TempArgument: Record "Message Argument ori" temporary;
        TableName: Text;
        BaseError: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] Data.Records.Set on Scheduled Task names Orchestrator.Status.Restart (no generic write)
        TempArgument.Init();
        Assert.IsTrue(TempArgument.IsTableWriteRestrictedForDataRecords(Database::"Scheduled Task"), 'Scheduled Task write-restricted');
        Assert.AreEqual(ScheduledTaskWriteHintTxt, TempArgument.GetDedicatedMessageTypeHintForWrite(Database::"Scheduled Task"), 'write companion hint');
        Assert.AreEqual(ScheduledTaskWriteHintTxt, TempArgument.GetDedicatedMessageTypeHintForField(Database::"Scheduled Task", 1), 'field companion hint');

        TableName := TempArgument.GetTableName(Database::"Scheduled Task");
        if TableName = '' then
            TableName := 'Scheduled Task';
        BaseError := StrSubstNo(SetRestrictedErr, Database::"Scheduled Task", TableName);
        ResponseText := RunMessageType(
            "Message Type ori"::"Data.Records.Set",
            '{"tableName":"Scheduled Task","data":[{"primaryKey":{"ID":"00000000-0000-0000-0000-000000000001"},"fields":{}}]}');
        AssertErrorAndHint(ResponseText, BaseError + ' Use ' + ScheduledTaskWriteHintTxt + '.', ScheduledTaskWriteHintTxt);
    end;

    [Test]
    procedure ReportRequestPreset_ReadWriteHint()
    var
        TempArgument: Record "Message Argument ori" temporary;
        TableName: Text;
        BaseRead: Text;
        BaseWrite: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] Report Request Preset ori read/write name Orchestrator.Report.Get/Run/SaveAs
        TempArgument.Init();
        Assert.IsTrue(TempArgument.IsTableReadRestrictedForDataRecords(Database::"Report Request Preset ori"), 'Preset read-restricted');
        Assert.IsTrue(TempArgument.IsTableWriteRestrictedForDataRecords(Database::"Report Request Preset ori"), 'Preset write-restricted');
        Assert.AreEqual(ReportPresetHintTxt, TempArgument.GetDedicatedMessageTypeHintForRead(Database::"Report Request Preset ori"), 'read companion hint');
        Assert.AreEqual(ReportPresetHintTxt, TempArgument.GetDedicatedMessageTypeHintForWrite(Database::"Report Request Preset ori"), 'write companion hint');
        Assert.AreEqual(ReportPresetHintTxt, TempArgument.GetDedicatedMessageTypeHintForField(Database::"Report Request Preset ori", 1), 'field companion hint');

        TableName := TempArgument.GetTableName(Database::"Report Request Preset ori");
        BaseRead := StrSubstNo(GetRestrictedErr, Database::"Report Request Preset ori", TableName);
        ResponseText := RunMessageType("Message Type ori"::"Data.Records.Get", '{"tableName":"Report Request Preset ori","take":1}');
        AssertErrorAndHint(ResponseText, BaseRead + ' Use ' + ReportPresetHintTxt + '.', ReportPresetHintTxt);

        BaseWrite := StrSubstNo(SetRestrictedErr, Database::"Report Request Preset ori", TableName);
        ResponseText := RunMessageType(
            "Message Type ori"::"Data.Records.Set",
            '{"tableName":"Report Request Preset ori","data":[{"primaryKey":{"Report ID":1,"User Security ID":"00000000-0000-0000-0000-000000000001"},"fields":{}}]}');
        AssertErrorAndHint(ResponseText, BaseWrite + ' Use ' + ReportPresetHintTxt + '.', ReportPresetHintTxt);
    end;
}
