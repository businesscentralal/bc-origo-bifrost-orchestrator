/// <summary>
/// Adds Bifrost Orchestrator to the Bifröst Setup page. The Apps action opens the application setup
/// page. The Navigate area opens the playbook list and the playbook execution log directly; both
/// pages stay reachable from page "Scheduler Setup ori" as well.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

pageextension 10035537 "Setup JQ ori" extends "Setup ori"
{
    actions
    {
        addlast(Navigation)
        {
            action(Playbooks)
            {
                ApplicationArea = All;
                Caption = 'Bifrost Playbooks', Comment = 'is-IS=Bifröst keðjur';
                Image = Relationship;
                RunObject = page "Playbooks ori";
                ToolTip = 'View and configure Bifrost message playbooks.', Comment = 'is-IS=Skoða og stilla keðjur Bifröst skilaboða.';
            }
            action(PlaybookInstances)
            {
                ApplicationArea = All;
                Caption = 'Playbook Execution Log', Comment = 'is-IS=Keyrsluskrá keðju';
                Image = Log;
                RunObject = page "Playbook Instances ori";
                ToolTip = 'View the execution log for playbook runs.', Comment = 'is-IS=Skoða keyrsluskrá keðjukeyrslna.';
            }
        }
        addlast(Apps)
        {
            action(OrchestratorSetup)
            {
                ApplicationArea = All;
                Caption = 'Bifrost Orchestrator Setup', Comment = 'is-IS=Uppsetning Bifröst stjórnanda';
                Image = Setup;
                RunObject = page "Scheduler Setup ori";
                ToolTip = 'Configure Bifrost Orchestrator: job queue scheduling, playbooks, client credentials and secrets.', Comment = 'is-IS=Stilla Bifröst stjórnandann: tímasetningu vinnsluraða, keðjur, auðkenni biðlara og leyndarmál.';
            }
        }
        addlast(Category_Apps)
        {
            actionref(OrchestratorSetup_Promoted; OrchestratorSetup)
            {
            }
        }
    }
}
