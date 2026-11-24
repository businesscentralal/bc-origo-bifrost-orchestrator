/// <summary>
/// Adds Bifrost Orchestrator to the Bifröst Setup page. The Apps action opens the application setup
/// page. Bifrost Playbooks stands directly before the Tools group, which holds the execution log, Table Data and Copy Plans without
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
            action(Playbooks)
            {
                ApplicationArea = All;
                Caption = 'Bifrost Playbooks', Comment = 'is-IS=Bifröst keðjur';
                Image = Relationship;
                RunObject = page "Playbooks ori";
                AccessByPermission = page "Playbooks ori" = X;
                ToolTip = 'View and configure Bifrost message playbooks.', Comment = 'is-IS=Skoða og stilla keðjur Bifröst skilaboða.';
            }
            group(Tools)
            {
                Caption = 'Tools', Comment = 'is-IS=Verkfæri';
                ToolTip = 'Open playbook and table data tools.', Comment = 'is-IS=Opna verkfæri fyrir keðjur og töflugögn.';
                Image = Tools;
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
                    ToolTip = 'Open Table Data Management to view, filter and export tables, or edit and import with write access.', Comment = 'is-IS=Opna Vinna með töflugögn til að skoða, afmarka og flytja út töflur eða breyta og flytja inn með skrifheimildum.';
                    Image = Table;
                    RunObject = page "Table Data Management ori";
                    AccessByPermission = page "Table Data Management ori" = X;
                }
                action(TableDataWorksheet)
                {
                    ApplicationArea = All;
                    Caption = 'Table Data Worksheet', Comment = 'is-IS=Vinnublað töflugagna';
                    ToolTip = 'Open the single-table worksheet to browse and edit records within your permissions.', Comment = 'is-IS=Opna vinnublað fyrir eina töflu til að skoða og breyta færslum innan heimilda þinna.';
                    Image = Worksheet;
                    RunObject = page "Table Data ori";
                    AccessByPermission = page "Table Data ori" = X;
                }
                action(CopyTablesMapping)
                {
                    ApplicationArea = All;
                    Caption = 'Copy Tables Mapping', Comment = 'is-IS=Töfluafritun - vörpun';
                    ToolTip = 'Map source tables to destination tables and copy their data through the Bifrost write guards.', Comment = 'is-IS=Varpa upprunatöflum á viðtökutöflur og afrita gögn þeirra í gegnum skrifvarnir Bifrastar.';
                    Image = CopyFromTask;
                    RunObject = page "Copy Tables Mapping ori";
                    AccessByPermission = page "Copy Tables Mapping ori" = X;
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
