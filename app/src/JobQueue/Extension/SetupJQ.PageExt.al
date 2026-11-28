/// <summary>Adds the Orchestrator configuration entry to Bifrost Setup.</summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

pageextension 10035537 "Setup JQ ori" extends "Setup ori"
{
    actions
    {
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
