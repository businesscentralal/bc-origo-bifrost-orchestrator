namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.Environment;
using System.Threading;
using Microsoft.Sales.Customer;

/// <summary>
/// Unit tests for Orchestrator Data.Records companion hints (#19).
/// One test per owned restricted table. Exercises Foundation's public
/// Message Argument ori hint APIs + RespondWithRestrictedTableError (same
/// shared path Data.Records.Get/Set use). Message ori / Message Task are
/// Foundation-internal and not visible to this test app.
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

    local procedure AssertErrorAndHint(ResponseJson: JsonObject; ExpectedError: Text; ExpectedHint: Text)
    var
        StatusToken: JsonToken;
        ErrorToken: JsonToken;
        HintToken: JsonToken;
    begin
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
        ExpectedError: Text;
    begin
        // [SCENARIO] Job Queue Entry write block names Orchestrator Entry/Schedule/Restart types
        TempArgument.Init();
        TempArgument.Insert();

        Assert.IsTrue(TempArgument.IsTableWriteRestrictedForDataRecords(Database::"Job Queue Entry"), 'Job Queue Entry write-restricted');
        Assert.AreEqual(JobQueueEntryWriteHintTxt, TempArgument.GetDedicatedMessageTypeHintForWrite(Database::"Job Queue Entry"), 'write companion hint');
        Assert.AreEqual(JobQueueEntryWriteHintTxt, TempArgument.GetDedicatedMessageTypeHintForField(Database::"Job Queue Entry", 1), 'field companion hint');

        TableName := TempArgument.GetTableName(Database::"Job Queue Entry");
        BaseError := StrSubstNo(SetRestrictedErr, Database::"Job Queue Entry", TableName);
        ExpectedError := BaseError + ' Use ' + JobQueueEntryWriteHintTxt + '.';
        Assert.AreEqual(ExpectedError, TempArgument.GetRestrictedTableErrorText(Database::"Job Queue Entry", BaseError, true), 'error text suffix');

        TempArgument.RespondWithRestrictedTableError(Database::"Job Queue Entry", BaseError, true);
        AssertErrorAndHint(TempArgument.GetResponseJson(), ExpectedError, JobQueueEntryWriteHintTxt);
    end;

    [Test]
    procedure ScheduledTask_WriteHint()
    var
        TempArgument: Record "Message Argument ori" temporary;
        TableName: Text;
        BaseError: Text;
        ExpectedError: Text;
    begin
        // [SCENARIO] Scheduled Task write block names Orchestrator.Status.Restart (no generic write)
        TempArgument.Init();
        TempArgument.Insert();

        Assert.IsTrue(TempArgument.IsTableWriteRestrictedForDataRecords(Database::"Scheduled Task"), 'Scheduled Task write-restricted');
        Assert.AreEqual(ScheduledTaskWriteHintTxt, TempArgument.GetDedicatedMessageTypeHintForWrite(Database::"Scheduled Task"), 'write companion hint');
        Assert.AreEqual(ScheduledTaskWriteHintTxt, TempArgument.GetDedicatedMessageTypeHintForField(Database::"Scheduled Task", 1), 'field companion hint');

        TableName := TempArgument.GetTableName(Database::"Scheduled Task");
        if TableName = '' then
            TableName := 'Scheduled Task';
        BaseError := StrSubstNo(SetRestrictedErr, Database::"Scheduled Task", TableName);
        ExpectedError := BaseError + ' Use ' + ScheduledTaskWriteHintTxt + '.';
        Assert.AreEqual(ExpectedError, TempArgument.GetRestrictedTableErrorText(Database::"Scheduled Task", BaseError, true), 'error text suffix');

        TempArgument.RespondWithRestrictedTableError(Database::"Scheduled Task", BaseError, true);
        AssertErrorAndHint(TempArgument.GetResponseJson(), ExpectedError, ScheduledTaskWriteHintTxt);
    end;

    [Test]
    procedure ReportRequestPreset_ReadWriteHint()
    var
        TempArgument: Record "Message Argument ori" temporary;
        TempArgumentWrite: Record "Message Argument ori" temporary;
        TableName: Text;
        BaseRead: Text;
        BaseWrite: Text;
        ExpectedRead: Text;
        ExpectedWrite: Text;
    begin
        // [SCENARIO] Report Request Preset ori read/write name Orchestrator.Report.Get/Run/SaveAs
        TempArgument.Init();
        TempArgument.Insert();

        Assert.IsTrue(TempArgument.IsTableReadRestrictedForDataRecords(Database::"Report Request Preset ori"), 'Preset read-restricted');
        Assert.IsTrue(TempArgument.IsTableWriteRestrictedForDataRecords(Database::"Report Request Preset ori"), 'Preset write-restricted');
        Assert.AreEqual(ReportPresetHintTxt, TempArgument.GetDedicatedMessageTypeHintForRead(Database::"Report Request Preset ori"), 'read companion hint');
        Assert.AreEqual(ReportPresetHintTxt, TempArgument.GetDedicatedMessageTypeHintForWrite(Database::"Report Request Preset ori"), 'write companion hint');
        Assert.AreEqual(ReportPresetHintTxt, TempArgument.GetDedicatedMessageTypeHintForField(Database::"Report Request Preset ori", 1), 'field companion hint');

        TableName := TempArgument.GetTableName(Database::"Report Request Preset ori");
        BaseRead := StrSubstNo(GetRestrictedErr, Database::"Report Request Preset ori", TableName);
        ExpectedRead := BaseRead + ' Use ' + ReportPresetHintTxt + '.';
        Assert.AreEqual(ExpectedRead, TempArgument.GetRestrictedTableErrorText(Database::"Report Request Preset ori", BaseRead, false), 'read error text suffix');
        TempArgument.RespondWithRestrictedTableError(Database::"Report Request Preset ori", BaseRead, false);
        AssertErrorAndHint(TempArgument.GetResponseJson(), ExpectedRead, ReportPresetHintTxt);

        // Separate temp record: Response Content blob does not reliably replace after
        // GetResponseJson/CalcFields, and a second Insert on the same temp table collides
        // on empty ID PK.
        TempArgumentWrite.Init();
        TempArgumentWrite.Insert();

        BaseWrite := StrSubstNo(SetRestrictedErr, Database::"Report Request Preset ori", TableName);
        ExpectedWrite := BaseWrite + ' Use ' + ReportPresetHintTxt + '.';
        Assert.AreEqual(ExpectedWrite, TempArgumentWrite.GetRestrictedTableErrorText(Database::"Report Request Preset ori", BaseWrite, true), 'write error text suffix');
        TempArgumentWrite.RespondWithRestrictedTableError(Database::"Report Request Preset ori", BaseWrite, true);
        AssertErrorAndHint(TempArgumentWrite.GetResponseJson(), ExpectedWrite, ReportPresetHintTxt);
    end;

    [Test]
    procedure Customer_NoCompanionHints()
    var
        TempArgument: Record "Message Argument ori" temporary;
    begin
        // [SCENARIO] Companion hints must not fire for unrelated tables (Customer)
        TempArgument.Init();
        TempArgument.Insert();

        Assert.AreEqual('', TempArgument.GetDedicatedMessageTypeHintForRead(Database::Customer), 'no read companion hint');
        Assert.AreEqual('', TempArgument.GetDedicatedMessageTypeHintForWrite(Database::Customer), 'no write companion hint');
        Assert.AreEqual('', TempArgument.GetDedicatedMessageTypeHintForField(Database::Customer, 1), 'no field companion hint');
    end;

}
