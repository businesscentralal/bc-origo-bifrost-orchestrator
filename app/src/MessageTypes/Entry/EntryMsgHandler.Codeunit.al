/// <summary>
/// Executes the Orchestrator.JobQueueEntry.* message types: restart a Job Queue Entry
/// unconditionally or only when it is in a failed/held state.
/// </summary>
namespace Origo.Bifrost.Nornir;

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
                Error(MissingIdErr);
        JQEntry.SetLoadFields(Status, Description, "Object Type to Run", "Object ID to Run");
        JQEntry.GetBySystemId(EntryId);
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
        RestartedMsg: Label 'Job Queue Entry restarted.', Comment = 'is-IS=Vinnsluröðarfærsla endurræst.';
        NoRestartNeededMsg: Label 'No restart needed.', Comment = 'is-IS=Engin endurræsing nauðsynleg.';
}
