/// <summary>
/// List page for Bifrost Playbook definitions.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

page 10035551 "Playbooks ori"
{
    Extensible = false;
    Caption = 'Bifrost Playbooks', Comment = 'is-IS=Bifröst keðjur';
    ContextSensitiveHelpPage = 'playbooks';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Playbook ori";
    CardPageId = "Playbook Card ori";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Playbooks)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique code for this playbook.', Comment = 'is-IS=Tilgreinir einstakan kóða fyrir þessa keðju.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the playbook.', Comment = 'is-IS=Tilgreinir lýsingu keðjunnar.';
                }
                field("Last Run Status"; Rec."Last Run Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the status of the last execution.', Comment = 'is-IS=Tilgreinir stöðu síðustu keyrslu.';
                }
                field("Last Run At"; Rec."Last Run At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the playbook was last executed.', Comment = 'is-IS=Tilgreinir hvenær keðjan var síðast keyrð.';
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            group(Tools)
            {
                Caption = 'Tools', Comment = 'is-IS=Verkfæri';
                ToolTip = 'Open playbook and table data tools.', Comment = 'is-IS=Opna verkfæri fyrir keðjur og töflugögn.';
                Image = Tools;
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
            action(Instances)
            {
                Caption = 'Execution Log', Comment = 'is-IS=Keyrsluskrá';
                ApplicationArea = All;
                ToolTip = 'View execution history for this playbook.', Comment = 'is-IS=Skoða keyrsluskrá fyrir þessa keðju.';
                Image = Log;
                RunObject = page "Playbook Instances ori";
                RunPageLink = "Playbook Code" = field(Code);
            }
        }
    }
}
