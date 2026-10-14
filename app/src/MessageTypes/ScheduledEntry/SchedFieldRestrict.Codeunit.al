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
        EntryUserHintTxt: Label 'Change Job Queue User ID on the Scheduled Entry card.', Comment = 'is-IS=Breyttu notandakenni verkraðar á spjaldi áætlaðrar færslu.';
        SetupUserHintTxt: Label 'Change Job Queue User ID on the Scheduler Setup page.', Comment = 'is-IS=Breyttu notandakenni verkraðar á síðunni Uppsetning verkstýringar.';
        RecipientHintTxt: Label 'Use Orchestrator.Playbook.Schedule when scheduling a playbook, or change Notification Recipient on the Scheduled Entry card.', Comment = 'is-IS=Notaðu Orchestrator.Playbook.Schedule þegar spilabók er tímasett, eða breyttu viðtakanda tilkynningar á spjaldi áætlaðrar færslu.';

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
