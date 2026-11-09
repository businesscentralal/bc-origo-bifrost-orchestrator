namespace Origo.Bifrost.Orchestrator;

using System.Reflection;
using System.Utilities;

/// <summary>
/// Table data viewer and editor (#155, Phase 2): pick a table, filter it with a table view and page through its rows.
/// Rows come from "Table Data Mgt ori" through Foundation's "Serializer ori"; restricted tables are refused and
/// restricted fields are not shown. Open record shows and edits the fields of one row. Export JSON and Import JSON
/// use the table data file of "Table JSON Export ori" and "Table JSON Import ori"; an import runs a dry run first.
/// </summary>
page 10035569 "Table Data ori"
{
    ContextSensitiveHelpPage = 'playbooks';
    Extensible = false;
    Caption = 'Table Data', Comment = 'is-IS=Töflugögn';
    PageType = Worksheet;
    ApplicationArea = All;
    UsageCategory = Tasks;
    SourceTable = "Table Data Row ori";
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            group(Selection)
            {
                Caption = 'Table', Comment = 'is-IS=Tafla';

                field(TableNoField; TableNo)
                {
                    ApplicationArea = All;
                    Caption = 'Table No.', Comment = 'is-IS=Töflunr.';
                    ToolTip = 'Specifies the number of the table to view.', Comment = 'is-IS=Tilgreinir númer töflunnar sem á að skoða.';
                    TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));

                    trigger OnValidate()
                    begin
                        PageNo := 1;
                        LoadRows();
                    end;
                }
                field(TableNameField; TableName)
                {
                    ApplicationArea = All;
                    Caption = 'Table Name', Comment = 'is-IS=Heiti töflu';
                    ToolTip = 'Specifies the name of the selected table.', Comment = 'is-IS=Tilgreinir heiti valdrar töflu.';
                    Editable = false;
                }
                field(TableViewField; TableView)
                {
                    ApplicationArea = All;
                    Caption = 'Table View', Comment = 'is-IS=Töflusýn';
                    ToolTip = 'Specifies an optional table view, for example WHERE(Source=FILTER(A*)). It is validated before it is applied.', Comment = 'is-IS=Tilgreinir valfrjálsa töflusýn, til dæmis WHERE(Source=FILTER(A*)). Hún er staðfest áður en henni er beitt.';

                    trigger OnValidate()
                    begin
                        PageNo := 1;
                        LoadRows();
                    end;
                }
                field(PageSizeField; PageSize)
                {
                    ApplicationArea = All;
                    Caption = 'Page Size', Comment = 'is-IS=Síðustærð';
                    ToolTip = 'Specifies how many rows are shown at a time, 1 to 500.', Comment = 'is-IS=Tilgreinir hve margar línur eru sýndar í einu, 1 til 500.';
                    MinValue = 1;
                    MaxValue = 500;

                    trigger OnValidate()
                    begin
                        PageNo := 1;
                        LoadRows();
                    end;
                }
                field(PageNoField; PageNo)
                {
                    ApplicationArea = All;
                    Caption = 'Page', Comment = 'is-IS=Síða';
                    ToolTip = 'Specifies the page of rows that is shown.', Comment = 'is-IS=Tilgreinir síðu línanna sem er sýnd.';
                    Editable = false;
                }
            }
            repeater(Rows)
            {
                Editable = false;

                field("Primary Key"; Rec."Primary Key")
                {
                    ApplicationArea = All;
                }
                field(Summary; Rec.Summary)
                {
                    ApplicationArea = All;
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
                ApplicationArea = All;
                Caption = 'Previous Page', Comment = 'is-IS=Fyrri síða';
                ToolTip = 'Shows the previous page of rows.', Comment = 'is-IS=Sýnir fyrri síðu línanna.';
                Image = PreviousSet;
                Enabled = PageNo > 1;

                trigger OnAction()
                begin
                    PageNo -= 1;
                    LoadRows();
                end;
            }
            action(NextPage)
            {
                ApplicationArea = All;
                Caption = 'Next Page', Comment = 'is-IS=Næsta síða';
                ToolTip = 'Shows the next page of rows.', Comment = 'is-IS=Sýnir næstu síðu línanna.';
                Image = NextSet;
                Enabled = HasMore;

                trigger OnAction()
                begin
                    PageNo += 1;
                    LoadRows();
                end;
            }
            action(OpenRecord)
            {
                ApplicationArea = All;
                Caption = 'Open Record', Comment = 'is-IS=Opna færslu';
                ToolTip = 'Shows the fields of the selected row and lets you edit them.', Comment = 'is-IS=Sýnir reiti valinnar línu og gerir þér kleift að breyta þeim.';
                Image = EditLines;
                Scope = Repeater;

                trigger OnAction()
                var
                    TableDataFields: Page "Table Data Fields ori";
                begin
                    TableDataFields.SetRecord(TableNo, Rec."Record SystemId");
                    TableDataFields.RunModal();
                    LoadRows();
                end;
            }
            action(ExportJson)
            {
                ApplicationArea = All;
                Caption = 'Export JSON', Comment = 'is-IS=Flytja út JSON';
                ToolTip = 'Downloads the rows in the table view as a table data file.', Comment = 'is-IS=Sækir línurnar í töflusýninni sem töflugagnaskrá.';
                Image = Export;

                trigger OnAction()
                begin
                    ExportFile();
                end;
            }
            action(ImportJson)
            {
                ApplicationArea = All;
                Caption = 'Import JSON', Comment = 'is-IS=Flytja inn JSON';
                ToolTip = 'Uploads a table data file, checks it with a dry run and imports it after you confirm.', Comment = 'is-IS=Hleður upp töflugagnaskrá, prófar hana með prufukeyrslu og flytur hana inn eftir staðfestingu.';
                Image = Import;

                trigger OnAction()
                begin
                    ImportFile();
                end;
            }
        }
        area(Promoted)
        {
            actionref(PreviousPage_Promoted; PreviousPage) { }
            actionref(NextPage_Promoted; NextPage) { }
            actionref(OpenRecord_Promoted; OpenRecord) { }
            actionref(ExportJson_Promoted; ExportJson) { }
            actionref(ImportJson_Promoted; ImportJson) { }
        }
    }

    trigger OnOpenPage()
    begin
        PageSize := 50;
        PageNo := 1;
        if TableNo <> 0 then
            LoadRows();
    end;

    var
        TableDataMgt: Codeunit "Table Data Mgt ori";
        TableNo: Integer;
        PageSize: Integer;
        PageNo: Integer;
        HasMore: Boolean;
        TableName: Text;
        TableView: Text;
        FileNameTxt: Label 'TableData.json', Locked = true;
        DownloadTitleTxt: Label 'Export table data', Comment = 'is-IS=Flytja út töflugögn';
        UploadTitleTxt: Label 'Import table data', Comment = 'is-IS=Flytja inn töflugögn';
        NotJsonErr: Label 'The file is not valid JSON.', Comment = 'is-IS=Skráin er ekki gilt JSON.';
        DryRunQst: Label 'Dry run of %1 rows: %2 to insert, %3 to modify, %4 failed. Import the rows that passed?', Comment = '%1 = rows, %2 = inserted, %3 = modified, %4 = failed, is-IS=Prufukeyrsla %1 lína: %2 til að bæta við, %3 til að breyta, %4 mistókust. Flytja inn línurnar sem stóðust?';
        ImportedMsg: Label '%1 rows inserted, %2 rows modified, %3 rows failed.', Comment = '%1 = inserted, %2 = modified, %3 = failed, is-IS=%1 línum bætt við, %2 línum breytt, %3 línur mistókust.';

    /// <summary>Opens the page on a table (used by tests and other pages).</summary>
    /// <param name="NewTableNo">Number of the table.</param>
    /// <param name="NewTableView">Optional table view.</param>
    internal procedure SetTable(NewTableNo: Integer; NewTableView: Text)
    begin
        TableNo := NewTableNo;
        TableView := NewTableView;
    end;

    local procedure LoadRows()
    var
        AllObj: Record AllObjWithCaption;
    begin
        TableName := '';
        HasMore := false;
        if PageSize = 0 then
            PageSize := 50;
        if PageNo < 1 then
            PageNo := 1;
        if TableNo = 0 then begin
            Rec.Reset();
            Rec.DeleteAll();
            exit;
        end;
        AllObj.SetLoadFields("Object Name");
        if AllObj.Get(AllObj."Object Type"::Table, TableNo) then
            TableName := AllObj."Object Name";
        HasMore := TableDataMgt.LoadPage(TableNo, TableView, PageNo, PageSize, Rec);
        CurrPage.Update(false);
    end;

    local procedure ExportFile()
    var
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        FileName: Text;
    begin
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        ExportTableData().WriteTo(OutStr);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        FileName := FileNameTxt;
        DownloadFromStream(InStr, DownloadTitleTxt, '', '', FileName);
    end;

    local procedure ImportFile()
    var
        InStr: InStream;
        Envelope: JsonObject;
        FileName: Text;
    begin
        if not UploadIntoStream(UploadTitleTxt, '', '', FileName, InStr) then
            exit;
        if not Envelope.ReadFrom(InStr) then
            Error(ErrorInfo.Create(NotJsonErr));
        if ImportTableData(Envelope) then
            LoadRows();
    end;

    /// <summary>Exports the selected table view through the Phase 1 serializer-backed engine.</summary>
    /// <returns>The Bifrost table data file envelope.</returns>
    internal procedure ExportTableData(): JsonObject
    var
        TableJSONExport: Codeunit "Table JSON Export ori";
        FieldNos: List of [Integer];
    begin
        exit(TableJSONExport.ExportTable(TableNo, TableView, FieldNos));
    end;

    /// <summary>Checks the uploaded file without writes, then imports only after explicit confirmation.</summary>
    /// <param name="Envelope">Uploaded Bifrost table data file.</param>
    /// <returns>True when the user confirmed the import.</returns>
    internal procedure ImportTableData(Envelope: JsonObject): Boolean
    var
        TableJSONImport: Codeunit "Table JSON Import ori";
        Result: JsonObject;
    begin
        Result := TableJSONImport.ImportTable(Envelope, true, false);
        if not Confirm(DryRunQst, false, GetCount(Result, 'rows'), GetCount(Result, 'inserted'), GetCount(Result, 'modified'), GetCount(Result, 'failed')) then
            exit(false);
        Result := TableJSONImport.ImportTable(Envelope, false, false);
        Message(ImportedMsg, GetCount(Result, 'inserted'), GetCount(Result, 'modified'), GetCount(Result, 'failed'));
        exit(true);
    end;

    local procedure GetCount(Result: JsonObject; KeyName: Text): Integer
    var
        Token: JsonToken;
    begin
        if Result.Get(KeyName, Token) then
            exit(Token.AsValue().AsInteger());
    end;
}
