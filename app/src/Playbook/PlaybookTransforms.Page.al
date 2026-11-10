namespace Origo.Bifrost.Orchestrator;

/// <summary>Edits the ordered mappings for the selected Transform step.</summary>
page 10035626 "Playbook Transforms ori"
{
    Caption = 'Transform Fields', Comment = 'is-IS=Umbreyting reita';
    PageType = ListPart;
    SourceTable = "Playbook Transform ori";
    ApplicationArea = All;
    ContextSensitiveHelpPage = 'playbooks';
    AutoSplitKey = true;
    DelayedInsert = true;
    layout
    {
        area(Content)
        {
            repeater(Mappings)
            {
                field("Target Path"; Rec."Target Path") { ApplicationArea = All; }
                field("Source Path"; Rec."Source Path") { ApplicationArea = All; }
                field("Operation"; Rec."Operation") { ApplicationArea = All; }
                field("Argument 1"; Rec."Argument 1") { ApplicationArea = All; }
                field("Argument 2"; Rec."Argument 2") { ApplicationArea = All; }
            }
        }
    }
}
