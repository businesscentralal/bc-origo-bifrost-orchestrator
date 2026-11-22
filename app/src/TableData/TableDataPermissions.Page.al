namespace Origo.Bifrost.Orchestrator;

using System.Reflection;

/// <summary>
/// FactBox list part showing read and write permission status for the currently selected table.
/// </summary>
page 10035631 "Table Data Permissions ori"
{
    ApplicationArea = All;
    Caption = 'Permissions', Comment = 'is-IS=Heimildir';
    PageType = ListPart;
    SourceTable = "Table Metadata";
    UsageCategory = None;
    Editable = false;
    Extensible = false;
    ContextSensitiveHelpPage = 'playbooks';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(ID; Rec.ID)
                {
                    ToolTip = 'Specifies the object ID.', Comment = 'is-IS=Tilgreinir hlutarkenni.';
                }
                field(Name; Rec.Name)
                {
                    ToolTip = 'Specifies the names of the available Windows languages.', Comment = 'is-IS=Tilgreinir heiti tiltækra Windows-tungumála.';
                }
                field("Has Read Permission"; TableHasReadPermission())
                {
                    Caption = 'Has Read Permission', Comment = 'is-IS=Hefur lesheimildir';
                    ToolTip = 'Specifies whether the user has read permission for the table.', Comment = 'is-IS=Tilgreinir hvort að notandi hefur lesheimildir í töfluna.';
                }
                field("Has Write Permission"; TableHasWritePermission())
                {
                    Caption = 'Has Write Permission', Comment = 'is-IS=Hefur skrifheimildir';
                    ToolTip = 'Specifies whether the user has write permission for the table.', Comment = 'is-IS=Tilgreinir hvort að notandi hefur skrifheimildir í töfluna.';
                }
            }
        }
    }

    local procedure TableHasReadPermission(): Boolean
    var
        RecRef: RecordRef;
    begin
        if Rec.ID = 0 then
            exit(false);
        if not TryOpenTable(Rec.ID, RecRef) then
            exit(false);
        exit(RecRef.ReadPermission());
    end;

    local procedure TableHasWritePermission(): Boolean
    var
        RecRef: RecordRef;
    begin
        if Rec.ID = 0 then
            exit(false);
        if not TryOpenTable(Rec.ID, RecRef) then
            exit(false);
        exit(RecRef.WritePermission());
    end;

    [TryFunction]
    local procedure TryOpenTable(TableId: Integer; var RecRef: RecordRef)
    begin
        RecRef.Open(TableId);
    end;
}
