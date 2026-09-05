/// <summary>
/// Extends the Job Queue Entry Card page with the Bifrost Nornir scheduling actions.
/// </summary>
namespace Origo.Bifrost.Nornir;

using System.Threading;

pageextension 10035535 "JobQueueEntryCard.PageExt ori" extends "Job Queue Entry Card"
{
    ContextSensitiveHelpPage = 'job-queue-entry-card.html';

    layout
    {
        addbefore("No. of Minutes between Runs")
        {
            field("Scheduler Enabled ori"; Rec."Scheduler Enabled ori")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether Bifrost Nornir monitors this job queue entry.', Comment = 'is-IS=Tilgreinir hvort Bifröst Nornir fylgist með þessari vinnsluraðarfærslu.';
            }
        }
        modify(Recurrence)
        {
            Editable = not Rec."Scheduler Enabled ori";
        }
    }

    actions
    {
        addafter(ShowRecord)
        {
            action("AddToScheduler ori")
            {
                ApplicationArea = All;
                Caption = 'Add to Bifrost Nornir', Comment = 'is-IS=Bæta við Bifröst Nornir';
                Image = RefreshPlanningLine;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Add the selected job queue entry to Bifrost Nornir so that it monitors the entry and restarts it when it fails.', Comment = 'is-IS=Bæta valinni vinnsluraðarfærslu við Bifröst Nornir svo hún fylgist með færslunni og endurræsi hana ef hún bregst.';
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
