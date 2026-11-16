/// <summary>
/// Adds Bifrost Orchestrator to the Bifröst Setup page. The Apps action opens the application setup
/// page. Tools groups the playbook list, execution log, Table Data and Copy Plans without
/// changing the existing action names.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

pageextension 10035537 "Setup JQ ori" extends "Setup ori"
{
    actions
    {
        addlast(Navigation)
        {
            group(Tools)
            {
                Caption = 'Tools', Comment = 'is-IS=Verkfæri';
                ToolTip = 'Open playbook and table data tools.', Comment = 'is-IS=Opna verkfæri fyrir keðjur og töflugögn.';
                Image = Tools;
                action(Playbooks)
                {
                    ApplicationArea = All;
                    Caption = 'Bifrost Playbooks', Comment = 'is-IS=Bifröst keðjur';
                    Image = Relationship;
                    RunObject = page "Playbooks ori";
                    AccessByPermission = page "Playbooks ori" = X;
                    ToolTip = 'View and configure Bifrost message playbooks.', Comment = 'is-IS=Skoða og stilla keðjur Bifröst skilaboða.';
                }
                action(PlaybookInstances)
                {
                    ApplicationArea = All;
                    Caption = 'Playbook Execution Log', Comment = 'is-IS=Keyrsluskrá keðju';
                    Image = Log;
                    RunObject = page "Playbook Instances ori";
                    AccessByPermission = page "Playbook Instances ori" = X;
                    ToolTip = 'View the execution log for playbook runs.', Comment = 'is-IS=Skoða keyrsluskrá keðjukeyrslna.';
                }
                action(TableData)
                {
                    ApplicationArea = All;
                    Caption = 'Table Data', Comment = 'is-IS=Töflugögn';
                    ToolTip = 'View, edit, export and import table data within your permissions.', Comment = 'is-IS=Skoða, breyta, flytja út og flytja inn töflugögn innan heimilda þinna.';
                    Image = Table;
                    RunObject = page "Table Data ori";
                    AccessByPermission = page "Table Data ori" = X;
                }
                action(CopyPlans)
                {
                    ApplicationArea = All;
                    Caption = 'Copy Plans', Comment = 'is-IS=Afritunaráætlanir';
                    ToolTip = 'View copy plans and configure table-to-table playbooks within your permissions.', Comment = 'is-IS=Skoða afritunaráætlanir og stilla keðjur til að afrita milli taflna innan heimilda þinna.';
                    Image = Copy;
                    RunObject = page "Copy Plans ori";
                    AccessByPermission = page "Copy Plans ori" = X;
                }
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
