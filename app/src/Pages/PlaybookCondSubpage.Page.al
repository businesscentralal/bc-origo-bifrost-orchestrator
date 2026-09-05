/// <summary>
/// Conditions for every step in a playbook, in one grid.
/// </summary>
namespace Origo.Bifrost.Nornir;

page 10035602 "Playbook Cond. Subpage ori"
{
    Caption = 'Step Conditions', Comment = 'is-IS=Skilyrði skrefa';
    PageType = ListPart;
    SourceTable = "Playbook Condition ori";
    AutoSplitKey = true;
    DelayedInsert = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                ShowCaption = false;

                field("Step No."; Rec."Step No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'The step this condition belongs to.', Comment = 'is-IS=Skrefið sem skilyrðið tilheyrir.';
                }
                field("Condition Type"; Rec."Condition Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Start gates whether the step runs, Success picks the branch, Error fails the run without changing the branch.', Comment = 'is-IS=Upphaf stýrir hvort skrefið keyrir, Árangur velur leið, Villa merkir keyrsluna sem mistekna án þess að breyta leið.';
                }
                field("Group No."; Rec."Group No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'All conditions in a group must be true. Any group being true is enough.', Comment = 'is-IS=Öll skilyrði í hóp verða að vera sönn. Nægilegt er að einn hópur sé sannur.';
                }
                field(Path; Rec.Path)
                {
                    ApplicationArea = All;
                    ToolTip = 'Workspace path for Start and Error, response path for Success.', Comment = 'is-IS=Slóð í vinnusvæði fyrir Upphaf og Villu, slóð í svari fyrir Árangur.';
                }
                field(Operator; Rec.Operator)
                {
                    ApplicationArea = All;
                    ToolTip = 'How the value at the path is compared.', Comment = 'is-IS=Hvernig gildið á slóðinni er borið saman.';
                }
                field("Value"; Rec."Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'The value to compare against.', Comment = 'is-IS=Gildið sem borið er saman við.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Optional note about what this condition is for.', Comment = 'is-IS=Valfrjáls skýring á tilgangi skilyrðisins.';
                }
            }
        }
    }
}
