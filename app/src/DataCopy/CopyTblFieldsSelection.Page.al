namespace Origo.Bifrost.Orchestrator;

using System.Reflection;

/// <summary>
/// Lookup list of the normal, enabled, non-obsolete fields of a table, used for the source and destination
/// field of a field mapping (port of Tools for Power Users "Copy Tbl. Fields Selection").
/// </summary>
page 10035615 "Copy Tbl. Fields Selection ori"
{
    ApplicationArea = All;
    Caption = 'Copy Table Field Selection', Comment = 'is-IS=Velja afritaða reiti';
    Editable = false;
    PageType = List;
    SourceTable = "Field";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(FieldList)
            {
                ShowCaption = false;

                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the value of the No. field', Comment = 'is-IS=Tilgreinir gildi reitsins reitanúmer';
                }
                field(Type; Rec.Type)
                {
                    ToolTip = 'Specifies the value of the Type field', Comment = 'is-IS=Tilgreinir gildi reitsins reitategund';
                }
                field("Field Caption"; Rec."Field Caption")
                {
                    Caption = 'Name', Comment = 'is-IS=Heiti';
                    ToolTip = 'Specifies the name of the field.', Comment = 'is-IS=Tilgreinir heiti reitsins.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange(Class, Rec.Class::Normal);
        Rec.SetRange("No.", 0, 1999999999);
        Rec.SetRange(Enabled, true);
        Rec.SetRange(ObsoleteState, Rec.ObsoleteState::No, Rec.ObsoleteState::Pending);
        Rec.FilterGroup(0);
    end;

    /// <summary>Returns the fields the user selected on this page.</summary>
    /// <param name="TableField">Receives the selected Field records.</param>
    procedure GetSelection(var TableField: Record "Field")
    begin
        CurrPage.SetSelectionFilter(TableField);
    end;

    /// <summary>Hides primary key fields so that they cannot be selected.</summary>
    procedure SetExcludePrimaryKeyFields()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange(IsPartOfPrimaryKey, false);
        Rec.FilterGroup(0);
    end;

    /// <summary>Shows only the fields of the given table.</summary>
    /// <param name="TableID">The table whose fields are shown.</param>
    procedure SetTableId(TableID: Integer)
    begin
        Rec.FilterGroup(2);
        Rec.SetRange(TableNo, TableID);
        Rec.FilterGroup(0);
    end;
}
