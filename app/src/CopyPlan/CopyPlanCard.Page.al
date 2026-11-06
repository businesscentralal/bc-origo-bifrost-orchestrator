namespace Origo.Bifrost.Orchestrator;

using System.Reflection;

/// <summary>Maintains the copy plan definition used by the guarded copy generator.</summary>
page 10035604 "Copy Plan Card ori"
{
    Caption = 'Copy Plan', Comment = 'is-IS=Afritunaráætlun';
    PageType = Card;
    SourceTable = "Copy Plan ori";
    ApplicationArea = All;
    ContextSensitiveHelpPage = 'playbooks';
    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                }
                field("Description"; Rec."Description")
                {
                    ApplicationArea = All;
                }
                field("Source Table No."; Rec."Source Table No.")
                {
                    ApplicationArea = All;
                }
                field("Destination Table No."; Rec."Destination Table No.")
                {
                    ApplicationArea = All;
                }
                field("Source View"; Rec."Source View")
                {
                    ApplicationArea = All;
                }
                field("Page Size"; Rec."Page Size")
                {
                    ApplicationArea = All;
                }
                field("Parent Plan Code"; Rec."Parent Plan Code")
                {
                    ApplicationArea = All;
                }
                field("Sequence No."; Rec."Sequence No.")
                {
                    ApplicationArea = All;
                }
                field("Generated Playbook Code"; Rec."Generated Playbook Code")
                {
                    ApplicationArea = All;
                }
            }
            part(Fields; "Copy Plan Fields ori")
            {
                ApplicationArea = All;
                SubPageLink = "Plan Code" = field(Code);
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(GeneratePlaybook)
            {
                Caption = 'Generate Playbook', Comment = 'is-IS=Mynda keðju';
                ToolTip = 'Creates the copy playbook or replaces its previously generated steps.', Comment = 'is-IS=Býr til afritunarkeðju eða skiptir út áður mynduðum skrefum hennar.';
                ApplicationArea = All;
                Image = CreateDocument;
                AccessByPermission = tabledata "Playbook Step ori" = M;
                trigger OnAction()
                var
                    Generator: Codeunit "Copy Plan Generator ori";
                begin
                    CurrPage.SaveRecord();
                    Generator.Generate(Rec.Code);
                    CurrPage.Update(false);
                end;
            }
            action(OpenPlaybook)
            {
                Caption = 'Open Playbook', Comment = 'is-IS=Opna keðju';
                ToolTip = 'Opens the generated playbook to verify, run or schedule it.', Comment = 'is-IS=Opnar mynduðu keðjuna til að staðfesta, keyra eða tímasetja hana.';
                ApplicationArea = All;
                Image = View;
                RunObject = page "Playbook Card ori";
                RunPageLink = Code = field("Generated Playbook Code");
            }
        }
    }
}
