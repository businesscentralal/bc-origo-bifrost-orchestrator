/// <summary>
/// Adds the single Bifrost Nornir entry point to the Bifröst Setup page. Everything else the
/// application offers - playbooks, client credentials, execution log, secrets and the setup
/// notification - lives on the application's own setup page, page "Scheduler Setup ori".
/// </summary>
namespace Origo.Bifrost.Nornir;

using Origo.Bifrost;

pageextension 10035537 "Setup JQ ori" extends "Setup ori"
{
    actions
    {
        addlast(Apps)
        {
            action(NornirSetup)
            {
                ApplicationArea = All;
                Caption = 'Bifrost Nornir Setup', Comment = 'is-IS=Uppsetning Bifröst Nornir';
                Image = Setup;
                RunObject = page "Scheduler Setup ori";
                ToolTip = 'Configure Bifrost Nornir: job queue scheduling, playbooks, client credentials and secrets.', Comment = 'is-IS=Stilla Bifröst Nornir: tímasetningu vinnsluraða, keðjur, auðkenni biðlara og leyndarmál.';
            }
        }
        addlast(Category_Apps)
        {
            actionref(NornirSetup_Promoted; NornirSetup)
            {
            }
        }
    }
}
