/// <summary>
/// Adds the single Bifrost Orchestrator entry point to the Bifröst Setup page. Everything else the
/// application offers - playbooks, client credentials, execution log, secrets and the setup
/// notification - lives on the application's own setup page, page "Scheduler Setup ori".
/// </summary>
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
