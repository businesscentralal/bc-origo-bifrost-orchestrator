/// <summary>
/// Executes the Orchestrator.Status.* message types: report orchestrator health and restart
/// the orchestrator management Job Queue Entry unconditionally or only when needed.
/// </summary>
namespace Origo.Bifrost.Nornir;

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
        Mgt: Codeunit "Scheduler Mgt ori";
        ResponseJson: JsonObject;
        MgtJQId: Guid;
    begin
        Setup.GetRecordOnce();
        MgtJQId := Mgt.GetManagementJobQueueId();
        if not IsNullGuid(MgtJQId) then begin
            JQEntry.SetLoadFields(Status);
            if JQEntry.GetBySystemId(MgtJQId) then
                if JQEntry.Status in [JQEntry.Status::Ready, JQEntry.Status::"In Process"] then begin
                    ResponseJson.Add('status', 'Success');
                    ResponseJson.Add('message', AlreadyRunningMsg);
                    ResponseJson.Add('restarted', false);
                    Argument.SetResponseJson(ResponseJson);
                    exit;
                end;
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
        AlreadyRunningMsg: Label 'Orchestrator is already running.', Comment = 'is-IS=Áætlari er þegar í gangi.';
}
