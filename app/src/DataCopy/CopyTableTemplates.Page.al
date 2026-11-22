namespace Origo.Bifrost.Orchestrator;

using System.IO;

/// <summary>
/// Lookup list of the configuration templates that can be applied as the data template of a copy
/// (port of Tools for Power Users "Copy Table Templates").
/// </summary>
page 10035616 "Copy Table Templates ori"
{
    ApplicationArea = All;
    Caption = 'Copy Table Templates', Comment = 'is-IS=Töfluafritun - sniðmát';
    Editable = false;
    PageType = List;
    SourceTable = "Config. Template Header";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Code"; Rec.Code)
                {
                    ToolTip = 'Specifies the value of the Code field', Comment = 'is-IS=Tilgreinir gildi reitsins kóti';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the value of the Description field', Comment = 'is-IS=Tilgreinir gildi reitsins lýsing';
                }
                field(Enabled; Rec.Enabled)
                {
                    ToolTip = 'Specifies the value of the Enabled field', Comment = 'is-IS=Tilgreinir gildi reitsins virkt';
                }
            }
        }
    }
}
