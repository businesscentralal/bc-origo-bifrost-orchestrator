namespace Origo.Bifrost.Orchestrator.Test;

using Microsoft.Sales.Customer;
using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.Environment;
using System.Threading;

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
        Assert.IsTrue(ResponseJson.Get('nextStep', HintToken), 'nextStep missing');
        Assert.AreEqual(ExpectedHint, HintToken.AsValue().AsText(), 'dedicated hint');
    end;

    /// <summary>
    /// Keeps ordinary Job Queue Entry writes denied while exposing Foundation's Force guidance and direct companion hints.
    /// </summary>
    [Test]
    procedure JobQueueEntry_WriteHint()
    begin
        VerifyJobQueueEntry_WriteHint(1033);
    end;

    /// <summary>
    /// Verifies the same refusal and companion-hint contract in Icelandic.
    /// </summary>
    [Test]
    procedure JobQueueEntry_WriteHint_Icelandic()
    begin
        VerifyJobQueueEntry_WriteHint(1039);
    end;

    local procedure VerifyJobQueueEntry_WriteHint(LanguageId: Integer)
    var
        TempArgument: Record "Message Argument ori" temporary;
        ResponseJson: JsonObject;
        ResponseToken: JsonToken;
        PreviousLanguage: Integer;
        TableName: Text;
        BaseError: Text;
        ExpectedError: Text;
        ExpectedNextStep: Text;
        ExpectedWriteAccess: Text;
        ForceErrorTxt: Label 'Table %1 (%2) is a force-openable setup table. Writing requires force and the appropriate permission.', Locked = true;
        ForceErrorIsTxt: Label 'Tafla %1 (%2) er uppsetningartafla sem hægt er að opna með force. Skrif krefjast force og viðeigandi heimildar.', Locked = true;
        ForceNextStepIsTxt: Label 'Þessi tafla opnast fyrir skrif með force sem true í Data.Records.Set; notandinn þarf heimildasamstæðuna BIFROST Force ori. Tengingar- og auðkennisreitir eru áfram lokaðir. Skrifvörn breytingaskrár leyfir þvingun aðeins í hamnum Með þvingunarheimild.', Locked = true;
        WriteExpectedIsTxt: Label 'tafla sem notandinn má skrifa í með almennu Data-gerðunum', Locked = true;
        ForceNextStepTxt: Label 'This table opens for writing with force set to true in Data.Records.Set; the user needs the BIFROST Force ori permission set. Connection and credential fields stay closed. The change log write guard allows force only in Via force mode.', Locked = true;
        WriteExpectedTxt: Label 'a table the user may write through the generic data types', Locked = true;
    begin
        // [SCENARIO] Foundation's Force tier changes shared refusal guidance, preserving direct Orchestrator hints.
        // PR #67 alignment | Time: independent of Today/WorkDate | Risk: Foundation #901 Force-tier contract.
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        TempArgument.Init();
        TempArgument.Insert();

        Assert.IsTrue(TempArgument.IsTableWriteRestrictedForDataRecords(Database::"Job Queue Entry", false), 'Job Queue Entry write-restricted');
        Assert.AreEqual(JobQueueEntryWriteHintTxt, TempArgument.GetDedicatedMessageTypeHintForWrite(Database::"Job Queue Entry"), 'write companion hint');
        Assert.AreEqual(JobQueueEntryWriteHintTxt, TempArgument.GetDedicatedMessageTypeHintForField(Database::"Job Queue Entry", 1), 'field companion hint');

        TableName := TempArgument.GetTableName(Database::"Job Queue Entry");
        // The caller's old internal-table text must be replaced by the current Force-tier refusal.
        BaseError := BaseRefusal(Database::"Job Queue Entry", TableName, true, LanguageId);
        if LanguageId = 1039 then begin
            ExpectedError := StrSubstNo(ForceErrorIsTxt, Database::"Job Queue Entry", TableName);
            ExpectedNextStep := ForceNextStepIsTxt;
            ExpectedWriteAccess := WriteExpectedIsTxt;
        end else begin
            ExpectedError := StrSubstNo(ForceErrorTxt, Database::"Job Queue Entry", TableName);
            ExpectedNextStep := ForceNextStepTxt;
            ExpectedWriteAccess := WriteExpectedTxt;
        end;
        Assert.AreEqual(ExpectedError, TempArgument.GetRestrictedTableErrorText(Database::"Job Queue Entry", BaseError, true), 'Force-tier error has no companion suffix');

        TempArgument.RespondWithRestrictedTableError(Database::"Job Queue Entry", BaseError, true);
        ResponseJson := TempArgument.GetResponseJson();
        AssertErrorAndHint(ResponseJson, ExpectedError, ExpectedNextStep);
        Assert.IsTrue(ResponseJson.Get('code', ResponseToken), 'code missing');
        Assert.AreEqual('PermissionDenied', ResponseToken.AsValue().AsText(), 'ordinary write refusal code');
        Assert.IsTrue(ResponseJson.Get('expected', ResponseToken), 'expected missing');
        Assert.AreEqual(ExpectedWriteAccess, ResponseToken.AsValue().AsText(), 'expected write access');
        GlobalLanguage(PreviousLanguage);
    end;

    /// <summary>
    /// Verifies Scheduled Task write denial and the Orchestrator.Status.Restart companion hint.
    /// </summary>
    [Test]
    procedure ScheduledTask_WriteHint()
    begin
        VerifyScheduledTask_WriteHint(1033);
    end;

    /// <summary>
    /// Verifies the same refusal and companion-hint contract in Icelandic.
    /// </summary>
    [Test]
    procedure ScheduledTask_WriteHint_Icelandic()
    begin
        VerifyScheduledTask_WriteHint(1039);
    end;

    local procedure VerifyScheduledTask_WriteHint(LanguageId: Integer)
    var
        TempArgument: Record "Message Argument ori" temporary;
        PreviousLanguage: Integer;
        TableName: Text;
        BaseError: Text;
        ExpectedError: Text;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        // [SCENARIO] Scheduled Task write block names Orchestrator.Status.Restart (no generic write)
        TempArgument.Init();
        TempArgument.Insert();

        Assert.IsTrue(TempArgument.IsTableWriteRestrictedForDataRecords(Database::"Scheduled Task", false), 'Scheduled Task write-restricted');
        Assert.AreEqual(ScheduledTaskWriteHintTxt, TempArgument.GetDedicatedMessageTypeHintForWrite(Database::"Scheduled Task"), 'write companion hint');
        Assert.AreEqual(ScheduledTaskWriteHintTxt, TempArgument.GetDedicatedMessageTypeHintForField(Database::"Scheduled Task", 1), 'field companion hint');

        TableName := TempArgument.GetTableName(Database::"Scheduled Task");
        if TableName = '' then
            TableName := 'Scheduled Task';
        BaseError := BaseRefusal(Database::"Scheduled Task", TableName, true, LanguageId);
        ExpectedError := WithCompanion(BaseError, ScheduledTaskWriteHintTxt, LanguageId);
        Assert.AreEqual(ExpectedError, TempArgument.GetRestrictedTableErrorText(Database::"Scheduled Task", BaseError, true), 'error text suffix');

        TempArgument.RespondWithRestrictedTableError(Database::"Scheduled Task", BaseError, true);
        AssertErrorAndHint(TempArgument.GetResponseJson(), ExpectedError, ScheduledTaskWriteHintTxt);
        GlobalLanguage(PreviousLanguage);
    end;

    /// <summary>
    /// Verifies report preset read and write denials and their dedicated report companion hints.
    /// </summary>
    [Test]
    procedure ReportRequestPreset_ReadWriteHint()
    begin
        VerifyReportRequestPreset_ReadWriteHint(1033);
    end;

    /// <summary>
    /// Verifies the same refusal and companion-hint contract in Icelandic.
    /// </summary>
    [Test]
    procedure ReportRequestPreset_ReadWriteHint_Icelandic()
    begin
        VerifyReportRequestPreset_ReadWriteHint(1039);
    end;

    local procedure VerifyReportRequestPreset_ReadWriteHint(LanguageId: Integer)
    var
        TempArgument: Record "Message Argument ori" temporary;
        TempArgumentWrite: Record "Message Argument ori" temporary;
        PreviousLanguage: Integer;
        TableName: Text;
        BaseRead: Text;
        BaseWrite: Text;
        ExpectedRead: Text;
        ExpectedWrite: Text;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        // [SCENARIO] Report Request Preset ori read/write name Orchestrator.Report.Get/Run/SaveAs
        TempArgument.Init();
        TempArgument.Insert();

        Assert.IsTrue(TempArgument.IsTableReadRestrictedForDataRecords(Database::"Report Request Preset ori"), 'Preset read-restricted');
        Assert.IsTrue(TempArgument.IsTableWriteRestrictedForDataRecords(Database::"Report Request Preset ori", false), 'Preset write-restricted');
        Assert.AreEqual(ReportPresetHintTxt, TempArgument.GetDedicatedMessageTypeHintForRead(Database::"Report Request Preset ori"), 'read companion hint');
        Assert.AreEqual(ReportPresetHintTxt, TempArgument.GetDedicatedMessageTypeHintForWrite(Database::"Report Request Preset ori"), 'write companion hint');
        Assert.AreEqual(ReportPresetHintTxt, TempArgument.GetDedicatedMessageTypeHintForField(Database::"Report Request Preset ori", 1), 'field companion hint');

        TableName := TempArgument.GetTableName(Database::"Report Request Preset ori");
        BaseRead := BaseRefusal(Database::"Report Request Preset ori", TableName, false, LanguageId);
        ExpectedRead := WithCompanion(BaseRead, ReportPresetHintTxt, LanguageId);
        Assert.AreEqual(ExpectedRead, TempArgument.GetRestrictedTableErrorText(Database::"Report Request Preset ori", BaseRead, false), 'read error text suffix');
        TempArgument.RespondWithRestrictedTableError(Database::"Report Request Preset ori", BaseRead, false);
        AssertErrorAndHint(TempArgument.GetResponseJson(), ExpectedRead, ReportPresetHintTxt);

        // Separate temp record: Response Content blob does not reliably replace after
        // GetResponseJson/CalcFields, and a second Insert on the same temp table collides
        // on empty ID PK.
        TempArgumentWrite.Init();
        TempArgumentWrite.Insert();

        BaseWrite := BaseRefusal(Database::"Report Request Preset ori", TableName, true, LanguageId);
        ExpectedWrite := WithCompanion(BaseWrite, ReportPresetHintTxt, LanguageId);
        Assert.AreEqual(ExpectedWrite, TempArgumentWrite.GetRestrictedTableErrorText(Database::"Report Request Preset ori", BaseWrite, true), 'write error text suffix');
        TempArgumentWrite.RespondWithRestrictedTableError(Database::"Report Request Preset ori", BaseWrite, true);
        AssertErrorAndHint(TempArgumentWrite.GetResponseJson(), ExpectedWrite, ReportPresetHintTxt);
        GlobalLanguage(PreviousLanguage);
    end;

    /// <summary>
    /// Verifies unrelated Customer records have no Orchestrator companion hints.
    /// </summary>
    [Test]
    procedure Customer_NoCompanionHints()
    begin
        VerifyCustomer_NoCompanionHints(1033);
    end;

    /// <summary>
    /// Verifies the same refusal and companion-hint contract in Icelandic.
    /// </summary>
    [Test]
    procedure Customer_NoCompanionHints_Icelandic()
    begin
        VerifyCustomer_NoCompanionHints(1039);
    end;

    local procedure VerifyCustomer_NoCompanionHints(LanguageId: Integer)
    var
        TempArgument: Record "Message Argument ori" temporary;
        PreviousLanguage: Integer;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        // [SCENARIO] Companion hints must not fire for unrelated tables (Customer)
        TempArgument.Init();
        TempArgument.Insert();

        Assert.AreEqual('', TempArgument.GetDedicatedMessageTypeHintForRead(Database::Customer), 'no read companion hint');
        Assert.AreEqual('', TempArgument.GetDedicatedMessageTypeHintForWrite(Database::Customer), 'no write companion hint');
        Assert.AreEqual('', TempArgument.GetDedicatedMessageTypeHintForField(Database::Customer, 1), 'no field companion hint');
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure BaseRefusal(TableNo: Integer; TableName: Text; IsWrite: Boolean; LanguageId: Integer): Text
    var
        WriteErr: Label 'Table %1 (%2) cannot be written via Data.Records.Set. This is an internal table.', Locked = true;
        ReadErr: Label 'Table %1 (%2) cannot be read via Data.Records.Get. This is an internal table.', Locked = true;
        WriteIsErr: Label 'Ekki er hægt að skrifa í töflu %1 (%2) með Data.Records.Set. Þetta er innri tafla.', Locked = true;
        ReadIsErr: Label 'Ekki er hægt að lesa töflu %1 (%2) með Data.Records.Get. Þetta er innri tafla.', Locked = true;
    begin
        if LanguageId = 1039 then begin
            if IsWrite then
                exit(StrSubstNo(WriteIsErr, TableNo, TableName));
            exit(StrSubstNo(ReadIsErr, TableNo, TableName));
        end;
        if IsWrite then
            exit(StrSubstNo(WriteErr, TableNo, TableName));
        exit(StrSubstNo(ReadErr, TableNo, TableName));
    end;

    local procedure WithCompanion(BaseError: Text; Hint: Text; LanguageId: Integer): Text
    begin
        if LanguageId = 1039 then
            exit(BaseError + ' Notaðu ' + Hint + '.');
        exit(BaseError + ' Use ' + Hint + '.');
    end;

}
