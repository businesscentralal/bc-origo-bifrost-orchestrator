/// <summary>
/// Manual event subscriber codeunit for handling Job Queue Entry deletion prompts.
/// </summary>
namespace Origo.Bifrost.Nornir;

using System.Threading;
using System.Utilities;

codeunit 10035542 "Scheduler Manual Evt ori"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteJobQueueEntry(var Rec: Record "Job Queue Entry"; RunTrigger: Boolean)
    var
        "Scheduled Entry ori": Record "Scheduled Entry ori";
        ConfirmManagement: Codeunit "Confirm Management";
        JobQueueEntryDeletedQst: Label 'Job Queue Orchestrator Entry has been created for this Job Queue Entry. If it is not deleted, the Job Queue Orchestrator will continue to run this Job Queue Entry. Do you want to delete the Job Queue Orchestrator Entry?', Comment = 'is-IS=Vinnsluraðarafærsla hefur verið stofnuð fyrir þessa vinnsluraðafærslu. Ef henni er ekki eyðt mun vinnsluraðarinn halda áfram að keyra þessa vinnsluraðafærslu. Viltu eyða vinnsluraðarafærslunni?';
    begin
        if not RunTrigger then
            exit;

        if not "Scheduled Entry ori".Get(Rec.ID) then
            exit;

        if ConfirmManagement.GetResponseOrDefault(JobQueueEntryDeletedQst, true) then
            "Scheduled Entry ori".Delete();
    end;
}
