namespace Origo.Bifrost.Orchestrator;

using System.Reflection;

/// <summary>Maintains the copy plans definition used by the guarded copy generator.</summary>
page 10035580 "Copy Plans ori"
{
    Caption = 'Copy Plans', Comment = 'is-IS=Afritunaráætlanir';
    PageType = List;
    SourceTable = "Copy Plan ori";
    ApplicationArea = All;
    ContextSensitiveHelpPage = 'playbooks';
    UsageCategory = Lists;
    CardPageId = "Copy Plan Card ori";
    Editable = false;
    layout
    {
        area(Content)
        {
            repeater(Lines)
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
                field("Generated Playbook Code"; Rec."Generated Playbook Code")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
