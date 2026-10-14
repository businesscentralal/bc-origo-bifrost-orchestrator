namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

/// <summary>
/// Keeps scheduling identities and notification recipients out of generic writes.
/// Dedicated scheduling and page edits remain available; restrictions are only added.
/// </summary>
codeunit 10035557 "Sched Field Restrict ori"
{
    Access = Internal;

    var
        EntryUserHintTxt: Label 'the Scheduled Entry card (Job Queue User ID)', Comment = 'is-IS=spjald áætlaðrar færslu (notandakenni verkraðar)';
        SetupUserHintTxt: Label 'the Scheduler Setup page (Job Queue User ID)', Comment = 'is-IS=síðuna Uppsetning verkstýringar (notandakenni verkraðar)';
        RecipientHintTxt: Label 'Orchestrator.Playbook.Schedule (notificationRecipient) or the Scheduled Entry card (Notification Recipient)', Comment = 'is-IS=Orchestrator.Playbook.Schedule (notificationRecipient) eða spjald áætlaðrar færslu (viðtakandi tilkynningar)';

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnAfterIsFieldWriteRestrictedForDataRecords, '', false, false)]
    local procedure RestrictScheduledFields(TableNo: Integer; FieldNo: Integer; Force: Boolean; var IsRestricted: Boolean)
    var
        Entry: Record "Scheduled Entry ori";
        Setup: Record "Scheduler Setup ori";
    begin
        // Force never reopens these identity and recipient fields.
        case TableNo of
            Database::"Scheduled Entry ori":
                if FieldNo in [Entry.FieldNo("Job Queue User ID"), Entry.FieldNo("Notification Recipient")] then
                    IsRestricted := true;
            Database::"Scheduler Setup ori":
                if FieldNo = Setup.FieldNo("Job Queue User ID") then
                    IsRestricted := true;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnGetDedicatedMessageTypeHintForField, '', false, false)]
    local procedure HintScheduledFields(TableNo: Integer; FieldNo: Integer; var Hint: Text)
    var
        Entry: Record "Scheduled Entry ori";
        Setup: Record "Scheduler Setup ori";
    begin
        case TableNo of
            Database::"Scheduled Entry ori":
                case FieldNo of
                    Entry.FieldNo("Job Queue User ID"):
                        Hint := EntryUserHintTxt;
                    Entry.FieldNo("Notification Recipient"):
                        Hint := RecipientHintTxt;
                end;
            Database::"Scheduler Setup ori":
                if FieldNo = Setup.FieldNo("Job Queue User ID") then
                    Hint := SetupUserHintTxt;
        end;
    end;
}
