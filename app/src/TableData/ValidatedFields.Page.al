namespace Origo.Bifrost.Orchestrator;

using Microsoft.Utilities;
using System.Reflection;
using System.Utilities;

/// <summary>
/// Fact box of the Excel import preview (#261) listing the mapped fields. Foundation validates every imported field, so each is shown as validated;
/// the original's toggle to skip validation of a field is not ported.
/// </summary>
page 10035630 "Validated Fields ori"
{
    ApplicationArea = All;
    Caption = 'Validated Fields', Comment = 'is-IS=Sannvottaðir reitir';
    Editable = false;
    Extensible = false;
    PageType = ListPart;
    SourceTable = "Field";
    SourceTableTemporary = true;
    ContextSensitiveHelpPage = 'playbooks';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    StyleExpr = FieldStyleExpr;
                    ToolTip = 'Specifies the ID number of the field in the table.', Comment = 'is-IS=Tilgreinir númer reitsins í töflunni.';
                }
                field("Field Caption"; Rec."Field Caption")
                {
                    ApplicationArea = All;
                    StyleExpr = FieldStyleExpr;
                    ToolTip = 'Specifies the caption of the field, that is, the name that will be shown in the user interface.', Comment = 'is-IS=Tilgreinir texta reitsins, þ.e. nafnið sem verður sýnt í notandaviðmótinu.';
                }
            }
        }
    }

    var
        TempFieldValidateBuffer: Record "Integer" temporary;
        FieldStyleExpr: Text;

    trigger OnAfterGetRecord()
    begin
        if TempFieldValidateBuffer.Get(Rec."No.") then
            FieldStyleExpr := 'Favorable'
        else
            FieldStyleExpr := '';
    end;

    /// <summary>
    /// Loads the mapped fields for the given table from FieldMapping into the page's temporary source record, and copies the validate buffer for visual highlighting.
    /// </summary>
    /// <param name="TableID">The ID of the table whose fields to display.</param>
    /// <param name="FieldMapping">The Line Number Buffer mapping Excel columns to field numbers.</param>
    /// <param name="FieldValidateBuffer">An Integer record where each entry represents a field number that should be highlighted as validated.</param>
    procedure Load(TableID: Integer; var FieldMapping: Record "Line Number Buffer"; var FieldValidateBuffer: Record "Integer")
    var
        TableField: Record "Field";
    begin
        TableField.SetRange(TableNo, TableID);
        TableField.SetRange(Class, TableField.Class::Normal);
        TableField.SetRange(Enabled, true);
        TableField.SetRange(ObsoleteState, TableField.ObsoleteState::No);
        if FieldMapping.FindSet() then
            repeat
                TableField.SetRange("No.", FieldMapping."New Line Number");
                TableField.FindFirst();
                Rec.TransferFields(TableField);
                Rec.Insert();
            until FieldMapping.Next() = 0;

        TempFieldValidateBuffer.Copy(FieldValidateBuffer, true);
    end;

}
