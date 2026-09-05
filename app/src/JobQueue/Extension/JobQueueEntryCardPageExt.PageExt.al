/// <summary>
/// Extends the Job Queue Entry Card page with orchestrator actions.
/// </summary>
namespace Origo.Bifrost.Nornir;

using System.Threading;

pageextension 10035535 "JobQueueEntryCard.PageExt ori" extends "Job Queue Entry Card"
{
    ContextSensitiveHelpPage = 'JobQueueEntryCard.html';

    layout
    {
        addbefore("No. of Minutes between Runs")
        {
            field("Orchestrator Enabled ori"; Rec."Orchestrator Enabled ori")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies if the Job Queue Orchestrator is monitoring this Job Queue Entry.', Comment = 'is-IS=Tilgreinir hvort vinnsluraðari ér á eftirliti með þssarri vinnsluraðafærslu.';
            }
        }
        modify(Recurrence)
        {
            Editable = not Rec."Orchestrator Enabled ori";
        }
    }

    actions
    {
        addafter(ShowRecord)
        {
            action("AddToJobQueueOrchestrator ori")
            {
                ApplicationArea = All;
                Caption = 'Add to Job Queue Orchestrator', Comment = 'is-IS=Bæta við vinnsluraðara';
                Image = RefreshPlanningLine;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Add the selected Job Queue Entry to Job Queue Orchestrator to have the Job Queue Orchestrator monitor and restart the Job Queue Entry when it fails.', Comment = 'is-IS=Bæta valdin vinnsluraðafærslu við vinnsluraðara til að vinnsluraðakti géti eftirlitið og endurrásað vinnsluraðafærslunni ef hún bilst.';
                trigger OnAction()
                var
                    "Scheduled Entry ori": Record "Scheduled Entry ori";
                begin
                    "Scheduled Entry ori".InsertFromJobQueueEntry(Rec, false);
                end;
            }
        }
    }

    var
        UIEvents: Codeunit "Scheduler Manual Evt ori";

    trigger OnOpenPage()
    begin
        if BindSubscription(UIEvents) then;
    end;

    trigger OnClosePage()
    begin
        if UnbindSubscription(UIEvents) then;
    end;

}
