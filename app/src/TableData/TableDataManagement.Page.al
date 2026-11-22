namespace Origo.Bifrost.Orchestrator;

using Microsoft.Utilities;
using System.Reflection;
using System.Security.AccessControl;


/// <summary>
/// Main entry page of the table data management (#261): lists the tables and offers edit, view, JSON export and import and Excel
/// export and import. Port of "Tools Table Data Mgt" from Tools for Power Users with the same layout, captions and actions.
/// JSON goes through Foundation's "Serializer ori", every write passes the Foundation guards, and the actions need access on
/// "Table Data Access ori". The original's Data Update reports and Isolated Storage Lookup are not ported.
/// </summary>
page 10035627 "Table Data Management ori"
{
    ApplicationArea = All;
    Caption = 'Table Data Management', Comment = 'is-IS=Vinna með töflugögn';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    Extensible = false;
    InsertAllowed = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,JSON,Excel', Comment = 'is-IS=Nýtt,Vinnsla,Skýrsla,JSON,Excel';
    SourceTable = "Table Metadata";
    SourceTableView = where(TableType = const(Normal), ObsoleteState = filter(No | Pending));
    UsageCategory = None;
    ContextSensitiveHelpPage = 'playbooks';

    layout
    {
        area(Content)
        {
            group(Options)
            {
                Caption = 'Options', Comment = 'is-IS=Valkostir';
                field(ShowAuditFieldsField; ShowAuditFields)
                {
                    ApplicationArea = All;
                    Caption = 'Show Audit Fields', Comment = 'is-IS=Sýna eftirlitsreiti';
                    ToolTip = 'Specifies the value of the Show Audit Fields field.', Comment = 'is-IS=Tilgreinir að sýna reiti fyrir eftirlitsgögn';
                }
            }
            group(Filters)
            {
                Caption = 'Edit/Export Filters', Comment = 'is-IS=Breytingar-/Útflutningsafmörkun';
                field(TempFilterCreatedAfterField; TempFilter."Record Created After")
                {
                    ApplicationArea = All;
                    Caption = 'Created After Date & Time', Comment = 'is-IS=Stofnað eftir dags. og tíma';
                    ToolTip = 'Specifies the value of the Created After Date & Time field.', Comment = 'is-IS=Tilgreinir gildi afmörkunar fyrir stofnað eftir dag og tíma.';
                }
                field(TempFilterCreatedUpToField; TempFilter."Record Created Up To")
                {
                    ApplicationArea = All;
                    Caption = 'Created Up To Date & Time', Comment = 'is-IS=Stofnað að dags. og tíma';
                    ToolTip = 'Specifies the value of the Created Up To Date & Time field.', Comment = 'is-IS=Tilgreinir gildi afmörkunar fyrir stofnað að dag og tíma.';
                }
                field(TempFilterModifiedAfterField; TempFilter."Record Modified After")
                {
                    ApplicationArea = All;
                    Caption = 'Modified After Date & Time', Comment = 'is-IS=Breytt eftir dags. og tíma';
                    ToolTip = 'Specifies the value of the Modified After Date & Time field.', Comment = 'is-IS=Tilgreinir gildi afmörkunar fyrir breytt eftir dag og tíma.';
                }
                field(TempFilterModifiedUpToField; TempFilter."Record Modified Up To")
                {
                    ApplicationArea = All;
                    Caption = 'Modified Up To Date & Time', Comment = 'is-IS=Breytt að dags. og tíma';
                    ToolTip = 'Specifies the value of the Modified Up To Date & Time field.', Comment = 'is-IS=Tilgreinir gildi afmörkunar fyrir breytt að dag og tíma.';
                }
            }
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field(ID; Rec.ID)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'ID', Comment = 'is-IS=Kenni';
                    ToolTip = 'Specifies the object ID.', Comment = 'is-IS=Tilgreinir kenni hlutarins.';
                }
                field(Caption; Rec.Caption)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name', Comment = 'is-IS=Heiti';
                    ToolTip = 'Specifies the name of the table object.', Comment = 'is-IS=Tilgreinir heiti töfluhlutarins.';
                }
            }
        }
        area(FactBoxes)
        {
            part(DataPermission; "Table Data Permissions ori")
            {
                ApplicationArea = All;
                Caption = 'Permissions', Comment = 'is-IS=Heimildir';
                SubPageLink = ID = field(ID);
                Visible = false;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EditRecords)
            {
                ApplicationArea = All;
                Caption = 'Edit records', Comment = 'is-IS=Breyta færslum';
                Enabled = isEditRecordsEnabled;
                Image = EditLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Executes the Edit records action.', Comment = 'is-IS=Opnar töflugögn í breytingarham';
                trigger OnAction()
                begin
                    ShowRecords();
                end;
            }
            group(JSONGroup)
            {
                Caption = 'JSON Format', Comment = 'is-IS=JSON Snið';

                action(ExportRecordsJSONAction)
                {
                    ApplicationArea = All;
                    Caption = 'Export Records', Comment = 'is-IS=Flytja út færslur';
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Executes the Export Records action.', Comment = 'is-IS=Keyrir útflutning á gögnum.';
                    AccessByPermission = tabledata "Table Data Access ori" = R;
                    trigger OnAction()
                    begin
                        ExportRecordsToJSON(true);
                    end;
                }
                action(ExportFilteredRecordsJSONAction)
                {
                    ApplicationArea = All;
                    Caption = 'Export Filtered Records', Comment = 'is-IS=Flytja út afmarkaðar færslur';
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Executes the Export Filtered Records action.', Comment = 'is-IS=Keyrir útflutning á gögnum með afmörkun';
                    AccessByPermission = tabledata "Table Data Access ori" = R;
                    trigger OnAction()
                    begin
                        ExportRecordsToJSON(false);
                    end;
                }
                action(ImportFilteredRecordsJSONAction)
                {
                    ApplicationArea = All;
                    Caption = 'Import Filtered Records', Comment = 'is-IS=Flytja inn afmarkaðar færslur';
                    Enabled = isEditRecordsEnabled;
                    Image = Import;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Executes the Import Filtered Records action.', Comment = 'is-IS=Keyrir innflutning á gögnum með afmörkun.';
                    AccessByPermission = tabledata "Table Data Access ori" = M;
                    trigger OnAction()
                    begin
                        ImportRecordsFromJSON(false);
                        CurrPage.Update(false);
                    end;
                }
                action(ImportRecordsJSONAction)
                {
                    ApplicationArea = All;
                    Caption = 'Import Records', Comment = 'is-IS=Flytja inn færslur';
                    Enabled = isEditRecordsEnabled;
                    Image = Import;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Executes the Import Records action.', Comment = 'is-IS=Keyrir innflutning á gögnum.';
                    AccessByPermission = tabledata "Table Data Access ori" = M;
                    trigger OnAction()
                    begin
                        ImportRecordsFromJSON(true);
                        CurrPage.Update(false);
                    end;
                }
            }
            group(ExcelGroup)
            {
                Caption = 'Excel Format', Comment = 'is-IS=Excel snið';
                action(ExportRecordsExcelAction)
                {
                    ApplicationArea = All;
                    Caption = 'Export Records', Comment = 'is-IS=Flytja út færslur';
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Executes the Export Records action.', Comment = 'is-IS=Keyrir útflutning á gögnum.';
                    AccessByPermission = tabledata "Table Data Access ori" = R;
                    trigger OnAction()
                    begin
                        ExportRecordsToExcel(true);
                    end;
                }
                action(ExportFilteredRecordsExcelAction)
                {
                    ApplicationArea = All;
                    Caption = 'Export Filtered Records', Comment = 'is-IS=Flytja út afmarkaðar færslur';
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Executes the Export Filtered Records action.', Comment = 'is-IS=Keyrir útflutning á gögnum með afmörkun';
                    AccessByPermission = tabledata "Table Data Access ori" = R;
                    trigger OnAction()
                    begin
                        ExportRecordsToExcel(false);
                    end;
                }
                action(ImportRecordsExcelAction)
                {
                    ApplicationArea = All;
                    Caption = 'Import Records', Comment = 'is-IS=Flytja inn færslur';
                    Enabled = isEditRecordsEnabled;
                    Image = Import;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Executes the Import Records action.', Comment = 'is-IS=Keyrir innflutning á gögnum.';
                    AccessByPermission = tabledata "Table Data Access ori" = M;
                    trigger OnAction()
                    begin
                        ImportRecordsFromExcel(true);
                        CurrPage.Update(false);
                    end;
                }
            }
            action(Run)
            {
                ApplicationArea = All;
                Caption = 'View records', Comment = 'is-IS=Skoða færslur';
                Image = NextRecord;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Executes the View records action.', Comment = 'is-IS=Keyrir upp töflugögn í nýjum flipa.';
                AccessByPermission = tabledata "Table Data Access ori" = R;
                trigger OnAction()
                begin
                    Hyperlink(GetUrl(ClientType::Current, CompanyName(), ObjectType::Table, Rec.ID));
                end;
            }
        }
    }

    var
        TempFilter: Record "Table Data Edit ori" temporary;
        isEditRecordsEnabled: Boolean;
        ShowAuditFields: Boolean;

    trigger OnOpenPage()
    begin
        if IsSuperUser() then exit;
        Rec.FilterGroup(2);
        Rec.SetRange(ID, 1, 2000000000);
        Rec.FilterGroup(0);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetEnabled();
    end;

    local procedure ExportRecordsToExcel(HideDialog: Boolean)
    var
        SelectedObjects: Record "Table Metadata";
        ExcelExportMgt: Codeunit "Table Data Excel Export ori";
    begin
        CurrPage.SetSelectionFilter(SelectedObjects);
        ExcelExportMgt.ExportRecords(SelectedObjects, ShowAuditFields, TempFilter, HideDialog);
    end;

    local procedure ExportRecordsToJSON(HideDialog: Boolean)
    var
        SelectedObjects: Record "Table Metadata";
        JSONMgt: Codeunit "Table Data JSON Mgt ori";
    begin
        CurrPage.SetSelectionFilter(SelectedObjects);
        JSONMgt.ExportRecords(SelectedObjects, ShowAuditFields, TempFilter, HideDialog);
    end;

    local procedure ImportRecordsFromExcel(HideDialog: Boolean)
    var
        ExcelImportMgt: Codeunit "Table Data Excel Import ori";
    begin
        ExcelImportMgt.ImportRecords(Rec, HideDialog);
    end;

    local procedure ImportRecordsFromJSON(HideDialog: Boolean)
    var
        SelectedObjects: Record "Table Metadata";
        JSONMgt: Codeunit "Table Data JSON Mgt ori";
    begin
        CurrPage.SetSelectionFilter(SelectedObjects);
        JSONMgt.ImportRecords(SelectedObjects, HideDialog);
    end;

    local procedure IsSuperUser(): Boolean
    var
        AccessTo: Record "Access Control";
    begin
        AccessTo.SetRange("User Security ID", UserSecurityId());
        AccessTo.SetRange("Role ID", 'SUPER');
        exit(not AccessTo.IsEmpty());
    end;

    local procedure SetEnabled()
    var
        EditMgt: Codeunit "Table Data Edit Mgt ori";
    begin
        isEditRecordsEnabled := EditMgt.CheckIfWritePermissionsExistForTheUser(Rec.ID);
    end;

    local procedure SetSelectionCriteria(TableID: Integer; var TempFilterStorage: Record "Name/Value Buffer"; HideDialog: Boolean): Boolean
    var
        FilterMgt: Codeunit "Table Data Filter Mgt ori";
    begin
        exit(FilterMgt.SetSelectionCriteria(TableID, HideDialog, TempFilterStorage));
    end;

    local procedure ShowRecords()
    var
        TempFilterStorage: Record "Name/Value Buffer" temporary;
        TableRecords: Page "Table Data Editor ori";
    begin
        if Rec.ID = 0 then
            exit;

        if not SetSelectionCriteria(Rec.ID, TempFilterStorage, false) then exit;

        Clear(TableRecords);
        TableRecords.LookupMode(false);
        TableRecords.SetTableNo(Rec.ID, Rec.Caption);
        TableRecords.SetShowAuditFields(ShowAuditFields);
        TableRecords.LoadColumnCaptions();
        TableRecords.LoadRecordColumnReadOnly();
        TableRecords.InitRecords(TempFilterStorage.GetValue(), TempFilter);
        TableRecords.RunModal();
    end;
}
