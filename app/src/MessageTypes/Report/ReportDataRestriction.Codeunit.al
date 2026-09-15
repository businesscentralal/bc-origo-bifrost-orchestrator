namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.Environment;
using System.Threading;

/// <summary>
/// Restricts Data.Records access to Report Request Preset ori and supplies dedicated
/// message-type companion hints for Orchestrator-owned restricted tables (#19 / core#20).
/// Job Queue Entry and Scheduled Task are write-restricted by Foundation; this app names
/// the Orchestrator.* types to use instead. Report Request Preset ori is restricted here.
/// </summary>
codeunit 10035590 "Report Data Restriction ori"
{
    Access = Internal;
    SingleInstance = true;

    var
        JobQueueEntryWriteHintTxt: Label 'Orchestrator.Entry.Register / Orchestrator.Entry.Schedule / Orchestrator.JobQueueEntry.Restart', Locked = true;
        ScheduledTaskWriteHintTxt: Label 'Orchestrator.Status.Restart', Locked = true;
        ReportPresetHintTxt: Label 'Orchestrator.Report.Get / Orchestrator.Report.Run / Orchestrator.Report.SaveAs', Locked = true;

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnAfterIsTableReadRestrictedForDataRecords, '', false, false)]
    local procedure RestrictPresetTableRead(TableNo: Integer; var IsRestricted: Boolean)
    begin
        if TableNo = Database::"Report Request Preset ori" then
            IsRestricted := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnAfterIsTableWriteRestrictedForDataRecords, '', false, false)]
    local procedure RestrictPresetTableWrite(TableNo: Integer; var IsRestricted: Boolean)
    begin
        if TableNo = Database::"Report Request Preset ori" then
            IsRestricted := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnGetDedicatedMessageTypeHintForRead, '', false, false)]
    local procedure HintPresetTableRead(TableNo: Integer; var Hint: Text)
    begin
        if TableNo = Database::"Report Request Preset ori" then
            Hint := ReportPresetHintTxt;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnGetDedicatedMessageTypeHintForWrite, '', false, false)]
    local procedure HintOwnedTablesWrite(TableNo: Integer; var Hint: Text)
    begin
        case TableNo of
            Database::"Job Queue Entry":
                Hint := JobQueueEntryWriteHintTxt;
            Database::"Scheduled Task":
                Hint := ScheduledTaskWriteHintTxt;
            Database::"Report Request Preset ori":
                Hint := ReportPresetHintTxt;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnGetDedicatedMessageTypeHintForField, '', false, false)]
    local procedure HintOwnedTablesField(TableNo: Integer; FieldNo: Integer; var Hint: Text)
    begin
        // Field-level blocks fall back to table write hint when blank; supply the same
        // dedicated types so a future field restriction on these tables stays consistent.
        if FieldNo < 0 then
            exit;
        case TableNo of
            Database::"Job Queue Entry":
                Hint := JobQueueEntryWriteHintTxt;
            Database::"Scheduled Task":
                Hint := ScheduledTaskWriteHintTxt;
            Database::"Report Request Preset ori":
                Hint := ReportPresetHintTxt;
        end;
    end;
}
