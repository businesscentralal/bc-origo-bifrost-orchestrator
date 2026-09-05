/// <summary>
/// Executes the Orchestrator.Entry.* message types: run, restart, register,
/// and schedule for orchestrator entries.
/// </summary>
namespace Origo.Bifrost.Nornir;

using Origo.Bifrost;
using System.Threading;

codeunit 10035550 "SE Msg Handler ori"
{
    Access = Internal;
    Permissions =
        tabledata "Scheduled Entry ori" = RIMD,
        tabledata "Job Queue Entry" = RM;

    procedure ExecuteRun(var Argument: Record "Message Argument ori")
    var
        Entry: Record "Scheduled Entry ori";
        Mgt: Codeunit "Scheduler Mgt ori";
    begin
        FindEntry(Argument, Entry);
        Mgt.RunJobQueueEntryOnce(Entry);
        RespondWithEntry(Argument, Entry, ExecutedMsg);
    end;

    procedure ExecuteRestart(var Argument: Record "Message Argument ori")
    var
        Entry: Record "Scheduled Entry ori";
        Handler: Codeunit "Scheduler Handler ori";
    begin
        FindEntry(Argument, Entry);
        Handler.ScheduleTask(Entry);
        RespondWithEntry(Argument, Entry, RestartedMsg);
    end;

    procedure ExecuteRegister(var Argument: Record "Message Argument ori")
    var
        JQEntry: Record "Job Queue Entry";
        Entry: Record "Scheduled Entry ori";
        RequestJson: JsonObject;
        EntryId: Guid;
    begin
        RequestJson := Argument.GetRequestJson();
        if not Argument.TryGetGuidFromJson(RequestJson, 'jobQueueEntryId', EntryId) then
            if Argument.SubjectIsGuid() then
                Evaluate(EntryId, Argument.Subject)
            else
                Error(MissingJQIdErr);
        JQEntry.Get(EntryId);
        Entry.InsertFromJobQueueEntry(JQEntry, true);
        Entry.Get(EntryId);
        RespondWithEntry(Argument, Entry, RegisteredMsg);
    end;

    procedure ExecuteSchedule(var Argument: Record "Message Argument ori")
    var
        Entry: Record "Scheduled Entry ori";
        Handler: Codeunit "Scheduler Handler ori";
        ApiClient: Codeunit "Scheduler API Client ori";
    begin
        FindEntry(Argument, Entry);
        Entry.TestField(Blocked, false);
        if ApiClient.Initialize(Entry) then
            ApiClient.CallUpdateJobQueueEntry(Entry)
        else begin
            Entry.DeleteJobQueueEntry();
            Handler.ScheduleTask(Entry);
        end;
        RespondWithEntry(Argument, Entry, ScheduledMsg);
    end;

    local procedure FindEntry(var Argument: Record "Message Argument ori"; var Entry: Record "Scheduled Entry ori")
    var
        RequestJson: JsonObject;
        EntryId: Guid;
    begin
        RequestJson := Argument.GetRequestJson();
        if not Argument.TryGetGuidFromJson(RequestJson, 'id', EntryId) then
            if Argument.SubjectIsGuid() then
                Evaluate(EntryId, Argument.Subject)
            else
                Error(MissingIdErr);
        Entry.SetLoadFields(Blocked, "Notification Type", "Notification Recipient");
        Entry.GetBySystemId(EntryId);
    end;

    local procedure RespondWithEntry(var Argument: Record "Message Argument ori"; Entry: Record "Scheduled Entry ori"; Message: Text)
    var
        ResponseJson: JsonObject;
    begin
        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('id', Format(Entry.SystemId, 0, 4));
        ResponseJson.Add('blocked', Entry.Blocked);
        ResponseJson.Add('message', Message);
        Argument.SetResponseJson(ResponseJson);
    end;

    var
        MissingIdErr: Label 'Request must include "id" (GUID) in the data payload or as the subject.', Comment = 'is-IS=Beiðni verður að innihalda "id" (GUID) í gagnahleðslunni eða sem viðfang.';
        MissingJQIdErr: Label 'Request must include "jobQueueEntryId" (GUID) in the data payload or the Job Queue Entry ID as the subject.', Comment = 'is-IS=Beiðni verður að innihalda "jobQueueEntryId" (GUID) í gagnahleðslunni eða auðkenni vinnsluraðarfærslu sem viðfang.';
        ExecutedMsg: Label 'Job queue entry executed.', Comment = 'is-IS=Vinnsluröðarfærsla keyrð.';
        RestartedMsg: Label 'Orchestrator entry restarted.', Comment = 'is-IS=Áætlunarfærsla endurræst.';
        RegisteredMsg: Label 'Job Queue Entry registered with orchestrator.', Comment = 'is-IS=Vinnsluraðarfærsla skráð hjá vinnsluraðara.';
        ScheduledMsg: Label 'Orchestrator entry scheduled.', Comment = 'is-IS=Áætlunarfærsla áætluð.';
}
