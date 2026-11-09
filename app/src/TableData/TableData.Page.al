namespace Origo.Bifrost.Orchestrator;

using System.Reflection;

/// <summary>Filtered, paged table-data browser with guarded JSON file actions.</summary>
page 10035569 "Table Data ori"
{
    PageType = Worksheet;
    SourceTable = "Table Data Row ori";
    SourceTableTemporary = true;
    Caption = 'Table Data', Comment = 'is-IS=Töflugögn';
    ApplicationArea = All;
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;
    ContextSensitiveHelpPage = 'table-data';

    layout
    {
        area(Content)
        {
            group(Selection)
            {
                Caption = 'Selection', Comment = 'is-IS=Val';
                field(TableNo; SelectedTableNo)
                {
                    Caption = 'Table No.', Comment = 'is-IS=Töflunr.';
                    ToolTip = 'Specifies the table to browse under your current permissions.', Comment = 'is-IS=Tilgreinir töfluna sem á að skoða með núverandi heimildum þínum.';
                    ApplicationArea = All;
                    TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
                    trigger OnValidate()
                    begin
                        PageNo := 1;
                        Reload();
                    end;
                }
                field(TableName; SelectedTableName)
                {
                    Caption = 'Table Name', Comment = 'is-IS=Heiti töflu';
                    ToolTip = 'Shows the selected table name.', Comment = 'is-IS=Sýnir heiti valinnar töflu.';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(TableView; SelectedView)
                {
                    Caption = 'Table View', Comment = 'is-IS=Töflusýn';
                    ToolTip = 'Specifies the filter and sort order. Filters on restricted fields are refused.', Comment = 'is-IS=Tilgreinir síu og röðun. Síur á lokaða reiti eru ekki leyfðar.';
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        PageNo := 1;
                        Reload();
                    end;
                }
                field(PageSize; SelectedPageSize)
                {
                    Caption = 'Page Size', Comment = 'is-IS=Síðustærð';
                    ToolTip = 'Specifies how many rows to show, from 1 to 500.', Comment = 'is-IS=Tilgreinir fjölda færslna á síðu, frá 1 til 500.';
                    ApplicationArea = All;
                    MinValue = 1;
                    MaxValue = 500;
                    trigger OnValidate()
                    begin
                        PageNo := 1;
                        Reload();
                    end;
                }
                field(CurrentPage; PageNo)
                {
                    Caption = 'Page', Comment = 'is-IS=Síða';
                    ToolTip = 'Shows the current page number.', Comment = 'is-IS=Sýnir núverandi síðunúmer.';
                    ApplicationArea = All;
                    Editable = false;
                }
            }
            repeater(Rows)
            {
                Editable = false;
                field("Primary Key"; Rec."Primary Key")
                {
                    ApplicationArea = All;
                    ToolTip = 'Shows the primary key values of the row.', Comment = 'is-IS=Sýnir gildi aðallykils færslunnar.';
                }
                field(Summary; Rec.Summary)
                {
                    ApplicationArea = All;
                    ToolTip = 'Shows the first eight readable fields.', Comment = 'is-IS=Sýnir fyrstu átta lesanlegu reitina.';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(PreviousPage)
            {
                Caption = 'Previous Page', Comment = 'is-IS=Fyrri síða';
                ToolTip = 'Shows the previous page of rows.', Comment = 'is-IS=Sýnir fyrri síðu færslna.';
                ApplicationArea = All;
                Image = PreviousRecord;
                Enabled = PageNo > 1;
                trigger OnAction()
                begin
                    PageNo -= 1;
                    Reload();
                end;
            }
            action(NextPage)
            {
                Caption = 'Next Page', Comment = 'is-IS=Næsta síða';
                ToolTip = 'Shows the next page of rows.', Comment = 'is-IS=Sýnir næstu síðu færslna.';
                ApplicationArea = All;
                Image = NextRecord;
                Enabled = HasNext;
                trigger OnAction()
                begin
                    PageNo += 1;
                    Reload();
                end;
            }
            action(OpenRecord)
            {
                Caption = 'Open Record', Comment = 'is-IS=Opna færslu';
                ToolTip = 'Opens readable fields and allows only permitted changes.', Comment = 'is-IS=Opnar lesanlega reiti og leyfir aðeins heimilaðar breytingar.';
                ApplicationArea = All;
                Image = View;
                trigger OnAction()
                begin
                    OpenSelectedRecord();
                end;
            }
            action(ExportJSON)
            {
                Caption = 'Export JSON', Comment = 'is-IS=Flytja út JSON';
                ToolTip = 'Downloads the filtered table as TableData.json.', Comment = 'is-IS=Hleður niður síuðum töflugögnum sem TableData.json.';
                ApplicationArea = All;
                Image = Export;
                trigger OnAction()
                begin
                    Mgt.DownloadTable(SelectedTableNo, SelectedView);
                end;
            }
            action(ImportJSON)
            {
                Caption = 'Import JSON', Comment = 'is-IS=Flytja inn JSON';
                ToolTip = 'Validates a table-data file before asking you to import it.', Comment = 'is-IS=Staðfestir töflugagnaskrá áður en þú ert spurð(ur) um innflutning.';
                ApplicationArea = All;
                Image = Import;
                AccessByPermission = tabledata "Playbook ori" = M;
                trigger OnAction()
                begin
                    Mgt.UploadTable();
                    Reload();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'is-IS=Vinna';
                actionref(PreviousPagePromoted; PreviousPage) { }
                actionref(NextPagePromoted; NextPage) { }
                actionref(OpenRecordPromoted; OpenRecord) { }
                actionref(ExportJSONPromoted; ExportJSON) { }
                actionref(ImportJSONPromoted; ImportJSON) { }
            }
        }
    }
    trigger OnOpenPage()
    begin
        SelectedPageSize := 50;
        PageNo := 1;
    end;

    var
        Mgt: Codeunit "Table Data Mgt ori";
        SelectedTableNo: Integer;
        SelectedTableName: Text;
        SelectedView: Text;
        SelectedPageSize: Integer;
        PageNo: Integer;
        HasNext: Boolean;

    local procedure Reload()
    var
        TableObject: Record AllObjWithCaption;
    begin
        if SelectedTableNo = 0 then
            exit;
        TableObject.SetLoadFields("Object Caption");
        TableObject.Get(TableObject."Object Type"::Table, SelectedTableNo);
        SelectedTableName := TableObject."Object Caption";
        HasNext := Mgt.LoadPage(SelectedTableNo, SelectedView, PageNo, SelectedPageSize, Rec);
        CurrPage.Update(false);
    end;

    local procedure OpenSelectedRecord()
    var
        FieldsPage: Page "Table Data Fields ori";
    begin
        if Rec."Row No." = 0 then
            exit;
        FieldsPage.SetRecordContext(SelectedTableNo, Rec.GetRow());
        FieldsPage.RunModal();
        Reload();
    end;
}
