/// <summary>
/// List page for Bifrost Playbook definitions.
/// </summary>
namespace Origo.Bifrost.Nornir;

using Origo.Bifrost;

page 10035551 "Playbooks ori"
{
    Caption = 'Bifrost Playbooks', Comment = 'is-IS=Bifröst keðjur';
    ContextSensitiveHelpPage = 'playbooks.html';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
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
