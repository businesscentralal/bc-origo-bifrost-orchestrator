/// <summary>
/// Extends the Job Queue Entries list page with the Bifrost Orchestrator scheduling actions.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using System.Threading;

pageextension 10035536 "JobQueueEntries.PageExt ori" extends "Job Queue Entries"
{
    ContextSensitiveHelpPage = 'job-queue-entries';

    layout
    {
        addbefore("No. of Minutes between Runs")
        {
            field("Scheduler Enabled ori"; Rec."Scheduler Enabled ori")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether Bifrost Orchestrator monitors this job queue entry.', Comment = 'is-IS=Tilgreinir hvort Bifröst stjórnandinn fylgist með þessari vinnsluraðarfærslu.';
            }
        }
    }

    actions
    {
        addafter(ShowRecord)
        {
            action("AddToScheduler ori")
            {
                ApplicationArea = All;
                Caption = 'Add to Bifrost Orchestrator', Comment = 'is-IS=Bæta við Bifröst stjórnandann';
                Image = RefreshPlanningLine;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Add the selected job queue entry to Bifrost Orchestrator so that it monitors the entry and restarts it when it fails.', Comment = 'is-IS=Bæta valinni vinnsluraðarfærslu við Bifröst stjórnandann svo hann fylgist með færslunni og endurræsi hana ef hún bregst.';
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
