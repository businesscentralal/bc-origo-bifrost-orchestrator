/// <summary>
/// Executes the Orchestrator.JobQueueEntry.* message types: restart a Job Queue Entry
/// unconditionally or only when it is in a failed/held state.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.Threading;

codeunit 10035566 "Entry Msg Handler ori"
{
    Access = Internal;
    Permissions = tabledata "Job Queue Entry" = RM;

    /// <summary>
    /// Restarts a Job Queue Entry by setting its status to Ready, regardless of current state.
    /// </summary>
    /// <param name="Argument">Message argument carrying the request and receiving the response.</param>
    procedure ExecuteRestart(var Argument: Record "Message Argument ori")
    var
        JQEntry: Record "Job Queue Entry";
    begin
        FindEntry(Argument, JQEntry);
        JQEntry.SetStatus(JQEntry.Status::Ready);
        RespondWithEntry(Argument, JQEntry, RestartedMsg);
    end;

    /// <summary>
    /// Restarts a Job Queue Entry only if it is in Error, On Hold, or On Hold with
    /// Inactivity Timeout; otherwise responds without action.
    /// </summary>
    /// <param name="Argument">Message argument carrying the request and receiving the response.</param>
    procedure ExecuteRestartIfNeeded(var Argument: Record "Message Argument ori")
    var
        JQEntry: Record "Job Queue Entry";
    begin
        FindEntry(Argument, JQEntry);
        if not (JQEntry.Status in [JQEntry.Status::Error, JQEntry.Status::"On Hold", JQEntry.Status::"On Hold with Inactivity Timeout"]) then
            RespondWithEntry(Argument, JQEntry, NoRestartNeededMsg)
        else begin
            JQEntry.SetStatus(JQEntry.Status::Ready);
            RespondWithEntry(Argument, JQEntry, RestartedMsg);
        end;
    end;

    local procedure FindEntry(var Argument: Record "Message Argument ori"; var JQEntry: Record "Job Queue Entry")
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
        JQEntry.SetLoadFields(Status, Description, "Object Type to Run", "Object ID to Run");
        if not JQEntry.GetBySystemId(EntryId) then
            RaiseParameterError(Argument, "Bifrost Error Code ori"::RecordNotFound, StrSubstNo(NotFoundErr, Format(EntryId, 0, 4)), 'id', Format(EntryId, 0, 4), GuidExpectedTok, NotFoundNextStepTok);
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

    local procedure RespondWithEntry(var Argument: Record "Message Argument ori"; JQEntry: Record "Job Queue Entry"; Message: Text)
    var
        ResponseJson: JsonObject;
    begin
        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('id', Format(JQEntry.SystemId, 0, 4));
        ResponseJson.Add('entryStatus', Format(JQEntry.Status));
        ResponseJson.Add('description', JQEntry.Description);
        ResponseJson.Add('message', Message);
        Argument.SetResponseJson(ResponseJson);
    end;

    var
        MissingIdErr: Label 'Request must include "id" (GUID) in the data payload or as the subject.', Comment = 'is-IS=Beiðni verður að innihalda "id" (GUID) í gagnahleðslunni eða sem viðfang.';
        GuidExpectedTok: Label 'a GUID', Comment = 'is-IS=GUID-auðkenni';
        MissingIdNextStepTok: Label 'Send the SystemId of the Job Queue Entry in data.id or as the subject.', Comment = 'is-IS=Sendu SystemId vinnsluraðarfærslunnar í data.id eða sem viðfang.';
        NotFoundErr: Label 'No Job Queue Entry has the SystemId %1.', Comment = '%1 = the GUID received, is-IS=Engin vinnsluraðarfærsla hefur SystemId %1.';
        NotFoundNextStepTok: Label 'Send the SystemId of an existing Job Queue Entry; its ID is not accepted.', Comment = 'is-IS=Sendu SystemId vinnsluraðarfærslu sem er til; auðkenni hennar er ekki tekið gilt.';
        RestartedMsg: Label 'Job Queue Entry restarted.', Comment = 'is-IS=Vinnsluraðafærsla endurræst.';
        NoRestartNeededMsg: Label 'No restart needed.', Comment = 'is-IS=Engin endurræsing nauðsynleg.';
}
