namespace Origo.Bifrost.Orchestrator;

/// <summary>
/// Shows the readable fields of one record from the "Table Data ori" page and saves a changed value through
/// "Table Data Mgt ori" (Foundation's "Serializer ori" and Modify(true)) (#155, Phase 2). Primary key fields, and all
/// fields of a table that Foundation restricts for writing, are read-only.
/// </summary>
page 10035573 "Table Data Fields ori"
{
    ContextSensitiveHelpPage = 'playbooks';
    Extensible = false;
    Caption = 'Table Data Fields', Comment = 'is-IS=Reitir töflugagna';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Table Data Field ori";
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;

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
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Value; Rec.Value)
                {
                    ApplicationArea = All;
                    Editable = CanEdit and not Rec."Part of Primary Key";

                    trigger OnValidate()
                    var
                        TempSaved: Record "Table Data Field ori" temporary;
                    begin
                        TableDataMgt.SaveField(TableNo, RecordSystemId, Rec."Field No.", Rec.Value);
                        TableDataMgt.LoadRecord(TableNo, RecordSystemId, TempSaved);
                        if TempSaved.Get(Rec."Field No.") then
                            Rec.Value := TempSaved.Value;
                    end;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Part of Primary Key"; Rec."Part of Primary Key")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        TableDataMgt.LoadRecord(TableNo, RecordSystemId, Rec);
    end;

    trigger OnAfterGetRecord()
    begin
        CanEdit := TableDataMgt.CanEditField(TableNo, RecordSystemId, Rec."Field No.");
    end;

    var
        TableDataMgt: Codeunit "Table Data Mgt ori";
        RecordSystemId: Guid;
        TableNo: Integer;
        CanEdit: Boolean;

    /// <summary>Sets the record to show.</summary>
    /// <param name="NewTableNo">Number of the table.</param>
    /// <param name="NewRecordSystemId">SystemId of the record.</param>
    internal procedure SetRecord(NewTableNo: Integer; NewRecordSystemId: Guid)
    begin
        TableNo := NewTableNo;
        RecordSystemId := NewRecordSystemId;
    end;
}
