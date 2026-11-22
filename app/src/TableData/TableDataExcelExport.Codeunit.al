namespace Origo.Bifrost.Orchestrator;

using Microsoft.Utilities;
using System.IO;
using System.Reflection;
using System.Utilities;

/// <summary>
/// Excel export of the Table Data Management main page (#261). Port of "Tools Excel Export Mgt" from Tools for Power Users:
/// one workbook per table, the field names in the first row; several tables go into one zip file. Every cell value is read
/// through Foundation's "Serializer ori" (a restricted table is refused, a restricted field is blank).
/// </summary>
codeunit 10035605 "Table Data Excel Export ori"
{
    Access = Internal;

    var
        DataCompression: Codeunit "Data Compression";
        UseDataCompression: Boolean;
        WindowUpdateTok: Label '%1: (%2/%3)', Locked = true;
        ExcelFileExtensionTok: Label '.xlsx', Locked = true;
        ZipFileNameTok: Label 'TableExport.zip', Locked = true;

    /// <summary>Exports the selected tables to Excel.</summary>
    /// <param name="SelectedObjects">The selected tables.</param>
    /// <param name="ShowAuditFields">Whether the audit fields are columns.</param>
    /// <param name="TempFilter">The four date and time filters.</param>
    /// <param name="HideDialog">True to export every record, false to ask for filters per table.</param>
    internal procedure ExportRecords(var SelectedObjects: Record "Table Metadata"; ShowAuditFields: Boolean; var TempFilter: Record "Table Data Edit ori"; HideDialog: Boolean)
    var
        TempFilterStorage: Record "Name/Value Buffer" temporary;
        TableDataAccess: Record "Table Data Access ori";
        FilterMgt: Codeunit "Table Data Filter Mgt ori";
        TempBlob: Codeunit "Temp Blob";
        Window: Dialog;
        Counter: Integer;
        Total: Integer;
    begin
        TableDataAccess.AssertReadAccess();
        if SelectedObjects.IsEmpty() then
            exit;
        Total := SelectedObjects.Count();
        UseDataCompression := Total > 1;
        if UseDataCompression then
            DataCompression.CreateZipArchive();
        Window.Open('#1#######################################');
        SelectedObjects.FindSet();
        repeat
            Counter += 1;
            if FilterMgt.SetSelectionCriteria(SelectedObjects.ID, HideDialog, TempFilterStorage) then begin
                Window.Update(1, StrSubstNo(WindowUpdateTok, SelectedObjects.Name, Counter, Total));
                BuildWorkbook(SelectedObjects.ID, ShowAuditFields, TempFilterStorage.GetValue(), TempFilter, TempBlob, false);
                SaveWorkbook(SelectedObjects.Name, TempBlob);
            end;
        until SelectedObjects.Next() = 0;
        Window.Close();
        if UseDataCompression then
            SaveZipArchive();
    end;

    /// <summary>Builds the workbook of one table: field names in row 1, one row per record.</summary>
    /// <param name="TableNo">The table number.</param>
    /// <param name="ShowAuditFields">Whether the audit fields are columns.</param>
    /// <param name="FilterText">The filter dialog text; blank exports every record.</param>
    /// <param name="TempFilter">The four date and time filters.</param>
    /// <param name="TempBlob">Receives the .xlsx file.</param>
    /// <param name="SkipAccessCheck">Not used by the pages; reserved false.</param>
    internal procedure BuildWorkbook(TableNo: Integer; ShowAuditFields: Boolean; FilterText: Text; var TempFilter: Record "Table Data Edit ori"; var TempBlob: Codeunit "Temp Blob"; SkipAccessCheck: Boolean)
    var
        TableField: Record "Field";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TableDataAccess: Record "Table Data Access ori";
        EditMgt: Codeunit "Table Data Edit Mgt ori";
        TableJSONExport: Codeunit "Table JSON Export ori";
        FilterMgt: Codeunit "Table Data Filter Mgt ori";
        RecRef: RecordRef;
        FieldNos: List of [Integer];
        OutStr: OutStream;
        SheetName: Text[250];
    begin
        if not SkipAccessCheck then
            TableDataAccess.AssertReadAccess();
        TableJSONExport.OpenForRead(TableNo, '', FieldNos, RecRef);
        SheetName := CopyStr(RecRef.Name, 1, MaxStrLen(SheetName));
        EditMgt.SetFilterOnFields(TableField, TableNo, ShowAuditFields);
        TableField.SetLoadFields("No.", FieldName, Type);
        CreateHeaderRow(TempExcelBuffer, TableField);
        FilterMgt.GetFilteredRecord(RecRef, FilterText);
        FilterMgt.ApplyFilterToRecRef(RecRef, TempFilter);
        if RecRef.FindSet() then
            repeat
                CreateDataRow(TempExcelBuffer, TableField, RecRef, TableJSONExport.SerializeRow(RecRef, FieldNos));
            until RecRef.Next() = 0;
        RecRef.Close();
        TempExcelBuffer.CreateNewBook(SheetName);
        TempExcelBuffer.WriteSheet(SheetName, CompanyName(), UserId());
        TempExcelBuffer.CloseBook();
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr);
        TempExcelBuffer.SaveToStream(OutStr, true);
    end;

    local procedure SaveWorkbook(SheetName: Text; var TempBlob: Codeunit "Temp Blob")
    var
        FileMgt: Codeunit "Table Data Mgt ori";
        InStr: InStream;
        FileName: Text;
    begin
        FileName := FileMgt.GetJsonKey(SheetName) + ExcelFileExtensionTok;
        TempBlob.CreateInStream(InStr);
        if UseDataCompression then
            DataCompression.AddEntry(InStr, FileName)
        else
            DownloadFromStream(InStr, '', '', '', FileName);
    end;

    local procedure CreateHeaderRow(var TempExcelBuffer: Record "Excel Buffer"; var TableField: Record "Field")
    var
        FieldIndex: Integer;
    begin
        if TableField.FindSet() then
            repeat
                FieldIndex += 1;
                EnterCell(TempExcelBuffer, 1, FieldIndex, TableField.FieldName, true, TempExcelBuffer."Cell Type"::Text);
            until TableField.Next() = 0;
    end;

    local procedure CreateDataRow(var TempExcelBuffer: Record "Excel Buffer"; var TableField: Record "Field"; RecRef: RecordRef; Row: JsonObject)
    var
        EditMgt: Codeunit "Table Data Edit Mgt ori";
        TableDataMgt: Codeunit "Table Data Mgt ori";
        FieldIndex: Integer;
        RowNo: Integer;
        CellText: Text;
    begin
        RowNo := GetLastRowNo(TempExcelBuffer) + 1;
        if TableField.FindSet() then
            repeat
                FieldIndex += 1;
                if TableField."No." >= 2000000000 then
                    CellText := Format(RecRef.Field(TableField."No.").Value(), 0, 9)
                else
                    CellText := EditMgt.GetRowValue(Row, TableDataMgt.GetJsonKey(TableField.FieldName));
                if TableField.Type in [TableField.Type::Integer, TableField.Type::BigInteger, TableField.Type::Decimal] then
                    EnterCell(TempExcelBuffer, RowNo, FieldIndex, CellText, false, TempExcelBuffer."Cell Type"::Number)
                else
                    EnterCell(TempExcelBuffer, RowNo, FieldIndex, CellText, false, TempExcelBuffer."Cell Type"::Text);
            until TableField.Next() = 0;
    end;

    local procedure GetLastRowNo(var TempExcelBuffer: Record "Excel Buffer"): Integer
    begin
        TempExcelBuffer.Reset();
        if TempExcelBuffer.FindLast() then
            exit(TempExcelBuffer."Row No.");
    end;

    local procedure EnterCell(var TempExcelBuffer: Record "Excel Buffer"; RowNo: Integer; ColumnNo: Integer; CellValue: Text; Bold: Boolean; CellType: Option)
    begin
        TempExcelBuffer.Init();
        TempExcelBuffer.Validate("Row No.", RowNo);
        TempExcelBuffer.Validate("Column No.", ColumnNo);
        TempExcelBuffer."Cell Value as Text" := CopyStr(CellValue, 1, MaxStrLen(TempExcelBuffer."Cell Value as Text"));
        TempExcelBuffer.Formula := '';
        TempExcelBuffer.Bold := Bold;
        TempExcelBuffer."Cell Type" := CellType;
        TempExcelBuffer.Insert();
    end;

    local procedure SaveZipArchive()
    var
        FileMgt: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        DataCompression.SaveZipArchive(OutStr);
        FileMgt.BLOBExport(TempBlob, ZipFileNameTok, true);
    end;
}
