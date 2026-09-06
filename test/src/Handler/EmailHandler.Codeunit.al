namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost.Orchestrator;
using System.EMail;
using System.Threading;

/// <summary>
/// Test handler codeunit that captures email items sent by the scheduler notification system.
/// </summary>
codeunit 96412 "Email Handler"
{
    EventSubscriberInstance = Manual;

    var
        EmailItem: Record "Email Item";
        EmailBodyText: Text;

    internal procedure GetEMailItem(): Record "Email Item"
    begin
        exit(EmailItem);
    end;

    internal procedure GetEMailBodyText(): Text
    begin
        exit(EmailBodyText);
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Email Notification ori", 'OnAfterPreparingEmailItemBeforeSend', '', false, false)]
    local procedure OnAfterPreparingEmailItemBeforeSend("Scheduled Entry ori": Record "Scheduled Entry ori"; JobQueueEntry: Record "Job Queue Entry"; var TempEmailItem: Record "Email Item" temporary; var BodyText: Text; var IsHandled: Boolean);
    begin
        EmailItem.Init();
        EmailItem.TransferFields(TempEmailItem);
        EmailBodyText := bodyText;
        IsHandled := true;
    end;


}
