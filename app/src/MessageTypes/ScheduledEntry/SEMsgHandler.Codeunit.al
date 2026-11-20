/// <summary>
/// Executes the Orchestrator.Entry.* message types: run, restart, register,
/// and schedule for orchestrator entries.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.Threading;

codeunit 10035550 "SE Msg Handler ori"
{
    Access = Internal;
    Permissions =
        tabledata "Scheduled Entry ori" = RIMD,
        tabledata "Job Queue Entry" = RM;

    /// <summary>
    /// Executes the orchestrator entry once, right now, with no confirmation dialog. A throwaway
    /// non-recurring Job Queue Entry is used, so the entry's own schedule is left alone. The
    /// response is Success only when the dispatcher returns true. Otherwise the status is Error
    /// and the message is this run's error text. The entry is identified by the <c>id</c>
    /// request property or, failing that, by a GUID subject.
    /// </summary>
    /// <param name="Argument">Message argument carrying the request and receiving the response.</param>
    procedure ExecuteRun(var Argument: Record "Message Argument ori")
    var
        Entry: Record "Scheduled Entry ori";
        Mgt: Codeunit "Scheduler Mgt ori";
        Success: Boolean;
        ErrorText: Text;
    begin
        FindEntry(Argument, Entry);
        Mgt.RunJobQueueEntryOnceHeadless(Entry, Success, ErrorText);
        if Success then
            RespondWithEntry(Argument, Entry, ExecutedMsg)
        else
            RespondWithError(Argument, Entry, ErrorText);
    end;

    /// <summary>
    /// Puts the orchestrator entry's Job Queue Entry back on the schedule, applying the retry
    /// policy and the notification rules for an entry that stopped in Error or On Hold. The entry
    /// is identified by the <c>id</c> request property or, failing that, by a GUID subject.
    /// </summary>
    /// <param name="Argument">Message argument carrying the request and receiving the response.</param>
    procedure ExecuteRestart(var Argument: Record "Message Argument ori")
    var
        Entry: Record "Scheduled Entry ori";
        Handler: Codeunit "Scheduler Handler ori";
    begin
        FindEntry(Argument, Entry);
        Handler.ScheduleTask(Entry);
        RespondWithEntry(Argument, Entry, RestartedMsg);
    end;

    /// <summary>
    /// Brings an existing Job Queue Entry under orchestrator control by creating the matching
    /// orchestrator entry from it. The Job Queue Entry is identified by the
    /// <c>jobQueueEntryId</c> request property or, failing that, by a GUID subject.
    /// </summary>
    /// <param name="Argument">Message argument carrying the request and receiving the response.</param>
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
                RaiseParameterError(Argument, "Bifrost Error Code ori"::MissingParameter, MissingJQIdErr, 'jobQueueEntryId', '', GuidExpectedTok, MissingJQIdNextStepTok);
        if not JQEntry.Get(EntryId) then
            RaiseParameterError(Argument, "Bifrost Error Code ori"::RecordNotFound, StrSubstNo(JQEntryNotFoundErr, Format(EntryId, 0, 4)), 'jobQueueEntryId', Format(EntryId, 0, 4), GuidExpectedTok, JQEntryNotFoundNextStepTok);
        Entry.InsertFromJobQueueEntry(JQEntry, true);
        Entry.Get(EntryId);
        RespondWithEntry(Argument, Entry, RegisteredMsg);
    end;

    /// <summary>
    /// Rebuilds the schedule of an orchestrator entry from its current recurring settings. When the
    /// entry has client credentials the update is delegated to the scheduling API; otherwise the
    /// Job Queue Entry is dropped and created again locally. A blocked entry is refused. The entry
    /// is identified by the <c>id</c> request property or, failing that, by a GUID subject.
    /// </summary>
    /// <param name="Argument">Message argument carrying the request and receiving the response.</param>
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
            Handler.ScheduleTask(Entry, true);
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
                RaiseParameterError(Argument, "Bifrost Error Code ori"::MissingParameter, MissingIdErr, 'id', '', GuidExpectedTok, MissingIdNextStepTok);
        Entry.SetLoadFields(
            Blocked, "Notification Type", "Notification Recipient",
            "Object Type to Run", "Object ID to Run", "Record ID to Process", Description);
        if not Entry.GetBySystemId(EntryId) then
            if not Entry.Get(EntryId) then
                RaiseParameterError(Argument, "Bifrost Error Code ori"::RecordNotFound, StrSubstNo(EntryNotFoundErr, Format(EntryId, 0, 4)), 'id', Format(EntryId, 0, 4), GuidExpectedTok, EntryNotFoundNextStepTok);
    end;

    /// <summary>
    /// Raises one structured parameter error: the answer carries this code, the parameter, the received value,
    /// what was expected and the next step, instead of BusinessCentralError.
    /// </summary>
    local procedure RaiseParameterError(var Argument: Record "Message Argument ori"; ErrorCode: Enum "Bifrost Error Code ori"; Message: Text; Parameter: Text; Received: Text; Expected: Text; NextStep: Text)
    begin
        Argument.AddError(ErrorCode, Message, Parameter, Received, Expected, NextStep);
        Argument.RaiseCollectedErrors(ErrorCode, Message);
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

    local procedure RespondWithError(var Argument: Record "Message Argument ori"; Entry: Record "Scheduled Entry ori"; ErrorText: Text)
    var
        ResponseJson: JsonObject;
    begin
        ResponseJson.Add('status', 'Error');
        ResponseJson.Add('id', Format(Entry.SystemId, 0, 4));
        ResponseJson.Add('blocked', Entry.Blocked);
        ResponseJson.Add('message', ErrorText);
        Argument.SetResponseJson(ResponseJson);
    end;

    var
        MissingIdErr: Label 'Request must include "id" (GUID) in the data payload or as the subject.', Comment = 'is-IS=Beiðni verður að innihalda "id" (GUID) í gagnahleðslunni eða sem viðfang.';
        MissingJQIdErr: Label 'Request must include "jobQueueEntryId" (GUID) in the data payload or the Job Queue Entry ID as the subject.', Comment = 'is-IS=Beiðni verður að innihalda "jobQueueEntryId" (GUID) í gagnahleðslunni eða auðkenni vinnsluraðarfærslu sem viðfang.';
        GuidExpectedTok: Label 'a GUID', Comment = 'is-IS=GUID-auðkenni';
        MissingIdNextStepTok: Label 'Send the SystemId of the orchestrator entry in data.id or as the subject.', Comment = 'is-IS=Sendu SystemId áætlunarfærslunnar í data.id eða sem viðfang.';
        MissingJQIdNextStepTok: Label 'Send the ID of the Job Queue Entry in data.jobQueueEntryId or as the subject.', Comment = 'is-IS=Sendu auðkenni vinnsluraðarfærslunnar í data.jobQueueEntryId eða sem viðfang.';
        EntryNotFoundErr: Label 'No orchestrator entry has the ID %1.', Comment = '%1 = the GUID received, is-IS=Engin áætlunarfærsla hefur auðkennið %1.';
        EntryNotFoundNextStepTok: Label 'Send the SystemId or ID of an existing orchestrator entry.', Comment = 'is-IS=Sendu SystemId eða auðkenni áætlunarfærslu sem er til.';
        JQEntryNotFoundErr: Label 'No Job Queue Entry has the ID %1.', Comment = '%1 = the GUID received, is-IS=Engin vinnsluraðarfærsla hefur auðkennið %1.';
        JQEntryNotFoundNextStepTok: Label 'Send the ID of an existing Job Queue Entry.', Comment = 'is-IS=Sendu auðkenni vinnsluraðarfærslu sem er til.';
        ExecutedMsg: Label 'Job queue entry executed.', Comment = 'is-IS=Vinnsluraðafærsla keyrð.';
        RestartedMsg: Label 'Orchestrator entry restarted.', Comment = 'is-IS=Áætlunarfærsla endurræst.';
        RegisteredMsg: Label 'Job Queue Entry registered with orchestrator.', Comment = 'is-IS=Vinnsluraðarfærsla skráð hjá vinnsluraðara.';
        ScheduledMsg: Label 'Orchestrator entry scheduled.', Comment = 'is-IS=Áætlunarfærsla tímasett.';
}
