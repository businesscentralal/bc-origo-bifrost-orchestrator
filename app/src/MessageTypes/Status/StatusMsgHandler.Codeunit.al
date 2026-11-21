/// <summary>
/// Executes the Orchestrator.Status.* message types: report orchestrator health and restart
/// the orchestrator management Job Queue Entry unconditionally or only when needed.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.Threading;

codeunit 10035551 "Status Msg Handler ori"
{
    Access = Internal;
    Permissions =
        tabledata "Scheduler Setup ori" = R,
        tabledata "Scheduled Entry ori" = R,
        tabledata "Job Queue Entry" = RM;

    /// <summary>
    /// Returns the current health status of the Job Queue Orchestrator and entry counts.
    /// </summary>
    /// <param name="Argument">Message argument carrying the request and receiving the response.</param>
    procedure ExecuteGet(var Argument: Record "Message Argument ori")
    var
        Setup: Record "Scheduler Setup ori";
        Entry: Record "Scheduled Entry ori";
        Mgt: Codeunit "Scheduler Mgt ori";
        ResponseJson: JsonObject;
        EntriesJson: JsonObject;
        StatusText: Text;
        StyleExpr: Text;
    begin
        Setup.GetRecordOnce();

        ResponseJson.Add('status', 'Success');
        Mgt.GetJobQueueStatus(StatusText, StyleExpr);
        ResponseJson.Add('orchestratorStatus', StatusText);
        ResponseJson.Add('jobQueueCategoryCode', Setup."Job Queue Category Code");
        ResponseJson.Add('logJobQueueActivity', Setup."Log Job Queue Activity");

        Entry.SetLoadFields(Blocked);
        EntriesJson.Add('total', Entry.Count());
        Entry.SetRange(Blocked, true);
        EntriesJson.Add('blocked', Entry.Count());
        Entry.SetRange(Blocked, false);
        EntriesJson.Add('active', Entry.Count());
        ResponseJson.Add('entries', EntriesJson);

        Argument.SetResponseJson(ResponseJson);
    end;

    /// <summary>
    /// Unconditionally restarts the orchestrator management Job Queue Entry.
    /// </summary>
    /// <param name="Argument">Message argument carrying the request and receiving the response.</param>
    procedure ExecuteRestart(var Argument: Record "Message Argument ori")
    var
        Setup: Record "Scheduler Setup ori";
        Mgt: Codeunit "Scheduler Mgt ori";
        ResponseJson: JsonObject;
        StatusText: Text;
        StyleExpr: Text;
    begin
        Setup.GetRecordOnce();
        Mgt.CancelJobQueueEntry();
        Mgt.ScheduleJobQueueEntry(Setup."Job Queue Category Code", Setup."Job Queue User ID");
        Mgt.GetJobQueueStatus(StatusText, StyleExpr);
        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('message', RestartedMsg);
        ResponseJson.Add('orchestratorStatus', StatusText);
        Argument.SetResponseJson(ResponseJson);
    end;

    /// <summary>
    /// Restarts the orchestrator only if it is not already running.
    /// </summary>
    /// <param name="Argument">Message argument carrying the request and receiving the response.</param>
    procedure ExecuteRestartIfNeeded(var Argument: Record "Message Argument ori")
    var
        Setup: Record "Scheduler Setup ori";
        JQEntry: Record "Job Queue Entry";
        ConfirmGate: Codeunit "Confirm Gate ori";
        Mgt: Codeunit "Scheduler Mgt ori";
        ResponseJson: JsonObject;
        MgtJQPkId: Guid;
        AlreadyRunning: Boolean;
    begin
        Setup.GetRecordOnce();
        MgtJQPkId := Mgt.GetManagementJobQueueId();
        if not IsNullGuid(MgtJQPkId) then begin
            JQEntry.SetLoadFields(Status);
            if JQEntry.Get(MgtJQPkId) then
                AlreadyRunning := JQEntry.Status in [JQEntry.Status::Ready, JQEntry.Status::"In Process"];
        end;

        // Foundation does not gate a type without a subject, so the count is checked here, before anything changes:
        // 0 when nothing needs a restart, 1 when the management entry would be restarted (issue #254).
        if ConfirmGate.HasExpectedCount(Argument) then
            if AlreadyRunning then begin
                if not ConfirmGate.Confirm(Argument, 0, NoRestartCountMsg) then
                    exit;
            end else
                if not ConfirmGate.Confirm(Argument, 1, RestartCountMsg) then
                    exit;

        if AlreadyRunning then begin
            ResponseJson.Add('status', 'Success');
            ResponseJson.Add('message', AlreadyRunningMsg);
            ResponseJson.Add('restarted', false);
            Argument.SetResponseJson(ResponseJson);
            exit;
        end;

        Mgt.CancelJobQueueEntry();
        Mgt.ScheduleJobQueueEntry(Setup."Job Queue Category Code", Setup."Job Queue User ID");
        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('message', RestartedMsg);
        ResponseJson.Add('restarted', true);
        Argument.SetResponseJson(ResponseJson);
    end;

    var
        RestartedMsg: Label 'Orchestrator restarted.', Comment = 'is-IS=Áætlari endurræstur.';
        NoRestartCountMsg: Label 'no orchestrator management Job Queue Entry (it is already running)', Comment = 'is-IS=engin stjórnunarfærsla áætlara (hann er þegar í gangi)';
        RestartCountMsg: Label 'the orchestrator management Job Queue Entry (it would be restarted)', Comment = 'is-IS=stjórnunarfærsla áætlara (hún yrði endurræst)';
        AlreadyRunningMsg: Label 'Orchestrator is already running.', Comment = 'is-IS=Áætlari er þegar í gangi.';
}
