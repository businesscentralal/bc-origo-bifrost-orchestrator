namespace Origo.Bifrost.Orchestrator;

/// <summary>Edits a single visible field through Foundation's current guard and validation paths.</summary>
page 10035573 "Table Data Fields ori"
{
    PageType = List;
    SourceTable = "Table Data Field ori";
    SourceTableTemporary = true;
    Caption = 'Table Data Fields', Comment = 'is-IS=Gagnareitir töflu';
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;
    ContextSensitiveHelpPage = 'table-data';
    layout
    {
        area(Content)
        {
            repeater(Fields)
            {
                field("Field No."; Rec."Field No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Shows the field number.', Comment = 'is-IS=Sýnir reitarnúmer.';
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Shows the field caption.', Comment = 'is-IS=Sýnir yfirskrift reits.';
                }
                field(Value; Rec.Value)
                {
                    ApplicationArea = All;
                    Editable = CanEdit;
                    ToolTip = 'Specifies a new value. Foundation permissions and validation apply.', Comment = 'is-IS=Tilgreinir nýtt gildi. Heimildir og staðfesting Foundation gilda.';
                    trigger OnValidate()
                    begin
                        Mgt.SaveField(TableNo, Row, Rec."Field No.", Rec.Value);
                    end;
                }
                field("Type"; Rec."Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Shows the field value type.', Comment = 'is-IS=Sýnir gagnagerð reits.';
                }
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        CanEdit := Rec."Can Edit";
    end;
    trigger OnAfterGetCurrRecord()
    begin
        CanEdit := Rec."Can Edit";
    end;
    var
        Mgt: Codeunit "Table Data Mgt ori";
        Row: JsonObject;
        TableNo: Integer;
        CanEdit: Boolean;

    /// <summary>Loads fresh field values and permissions for the selected source row.</summary>
    procedure SetRecordContext(NewTableNo: Integer; NewRow: JsonObject)
    begin
        TableNo := NewTableNo;
        Row := NewRow;
        Mgt.LoadRecord(TableNo, Row, Rec);
    end;
}
