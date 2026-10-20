/// <summary>
/// Reads a playbook and reports the configuration mistakes the engine accepts silently.
/// The warnings are returned in the language of the calling session.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035616 "Playbook Verify ori"
{
    Access = Internal;
    Permissions = tabledata "Playbook ori" = R,
                  tabledata "Playbook Step ori" = R;

    /// <summary>
    /// Verifies the playbook named in the request and answers with the warnings found.
    /// </summary>
    /// <param name="Argument">Message argument carrying the request and receiving the response.</param>
    procedure ExecuteVerify(var Argument: Record "Message Argument ori")
    var
        Playbook: Record "Playbook ori";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        Warnings: JsonArray;
    begin
        RequestJson := Argument.GetRequestJson();
        Playbook.SetLoadFields(Code);
        Playbook.Get(GetPlaybookCode(Argument, RequestJson));

        GetWarnings(Playbook.Code, Warnings);

        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('playbookCode', Playbook.Code);
        ResponseJson.Add('warningCount', Warnings.Count());
        ResponseJson.Add('warnings', Warnings);
        Argument.SetResponseJson(ResponseJson);
    end;

    /// <summary>
    /// Collects the warnings for one playbook. Warning <c>UnsafeForEachWrite</c>: a forEach step with
    /// a write-type message type iterates the same array as an earlier, enabled forEach Check step
    /// and has <c>Skip If Step Failed = 0</c>. The Next Step edges of a forEach step apply once for
    /// the whole step, never per item, so only <c>Skip If Step Failed</c> gates the write per item.
    /// </summary>
    /// <param name="PlaybookCode">The playbook to verify.</param>
    /// <param name="Warnings">Receives one object per warning: code, stepNo, checkStepNo and the localized message.</param>
    procedure GetWarnings(PlaybookCode: Code[20]; var Warnings: JsonArray)
    var
        WriteStep: Record "Playbook Step ori";
        CheckStep: Record "Playbook Step ori";
        Workspace: Codeunit "Playbook Workspace ori";
        Warning: JsonObject;
        MessageTypeName: Text;
    begin
        Clear(Warnings);
        WriteStep.SetLoadFields("Step No.", Description, "Message Type", "Iterate Array Path", "Iterate Source Step No.", "Skip If Step Failed", Disabled);
        WriteStep.SetRange("Playbook Code", PlaybookCode);
        WriteStep.SetRange(Disabled, false);
        WriteStep.SetFilter("Iterate Array Path", '<>%1', '');
        if WriteStep.FindSet() then
            repeat
                MessageTypeName := Workspace.MessageTypeToText(WriteStep."Message Type");
                if IsWriteMessageType(MessageTypeName) and (WriteStep."Skip If Step Failed" = 0) then begin
                    CheckStep.Reset();
                    CheckStep.SetLoadFields("Step No.");
                    CheckStep.SetRange("Playbook Code", PlaybookCode);
                    CheckStep.SetRange("Step Type", CheckStep."Step Type"::Check);
                    CheckStep.SetRange(Disabled, false);
                    CheckStep.SetFilter("Step No.", '<%1', WriteStep."Step No.");
                    CheckStep.SetRange("Iterate Source Step No.", WriteStep."Iterate Source Step No.");
                    CheckStep.SetRange("Iterate Array Path", WriteStep."Iterate Array Path");
                    if CheckStep.FindLast() then begin
                        Clear(Warning);
                        Warning.Add('code', 'UnsafeForEachWrite');
                        Warning.Add('stepNo', WriteStep."Step No.");
                        Warning.Add('checkStepNo', CheckStep."Step No.");
                        Warning.Add('message', StrSubstNo(UnsafeForEachWriteMsg, WriteStep."Step No.", MessageTypeName, CheckStep."Step No."));
                        Warnings.Add(Warning);
                    end;
                end;
            until WriteStep.Next() = 0;
    end;

    /// <summary>
    /// Tells whether a message type name is a write: its last segment is one of the verbs that
    /// change data or send something out (Set, Post, Delete, Create, Update, Send, ...).
    /// </summary>
    /// <param name="MessageTypeName">The invariant dotted message type name, for example "Data.Records.Set".</param>
    /// <returns>True when the message type writes.</returns>
    procedure IsWriteMessageType(MessageTypeName: Text): Boolean
    var
        Verb: Text;
        Verbs: List of [Text];
        Segments: List of [Text];
    begin
        Segments := MessageTypeName.Split('.');
        if Segments.Count() < 2 then
            exit(false);
        Verb := Segments.Get(Segments.Count());

        Verbs.AddRange('Set', 'Post', 'Delete', 'Create', 'Update', 'Insert', 'Modify', 'Cancel', 'Correct',
            'Send', 'MakeOrder', 'Release', 'Reopen', 'Approve', 'Reject', 'Register', 'Schedule', 'Enqueue');
        exit(Verbs.Contains(Verb));
    end;

    local procedure GetPlaybookCode(var Argument: Record "Message Argument ori"; RequestJson: JsonObject): Code[20]
    var
        PlaybookCodeToken: JsonToken;
    begin
        if RequestJson.Get('playbookCode', PlaybookCodeToken) then
            exit(CopyStr(PlaybookCodeToken.AsValue().AsText(), 1, 20));
        if Argument.Subject <> '' then
            exit(CopyStr(Argument.Subject, 1, 20));
        Error(MissingPlaybookCodeErr);
    end;

    var
        MissingPlaybookCodeErr: Label 'Request must include "playbookCode" in the data payload or as the subject.', Comment = 'is-IS=Beiðni verður að innihalda "playbookCode" í gagnahleðslunni eða sem viðfang.';
        UnsafeForEachWriteMsg: Label 'Step %1 (%2) writes for every item of an array that an earlier forEach Check step %3 decides on, but Skip If Step Failed is not set to %3. Next Step edges apply once per step, not per item, so this step runs for all items, also those the check answered no. Set Skip If Step Failed to %3 on step %1.', Comment = '%1 = step no, %2 = message type, %3 = check step no, is-IS=Skref %1 (%2) skrifar fyrir öll atriði fylkis sem forEach-athugunarskref %3 á undan tekur ákvörðun um, en Sleppa ef skref mistókst er ekki stillt á %3. Næsta skref gildir einu sinni fyrir skrefið, ekki fyrir hvert atriði, svo þetta skref keyrir fyrir öll atriði, líka þau sem athugunin svaraði nei. Stilltu Sleppa ef skref mistókst á %3 í skrefi %1.';
}
