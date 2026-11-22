namespace Origo.Bifrost.Orchestrator;

using Microsoft.Utilities;
using System.IO;
using System.Reflection;
using System.Utilities;

/// <summary>
/// Excel import of the Table Data Management main page (#261). Port of "Tool Excel Import Mgt" from Tools for Power Users:
/// the first row names the fields, the preview page ("Table Data Import ori") edits the sheet, and the rows are written
/// through "Table JSON Import ori", so the Foundation table, insert and field guards and Foundation's value validation apply.
/// Rows that are refused stay in the sheet with their cells marked, as in the original. Without a Skip Record Validation option.
/// </summary>
codeunit 10035608 "Table Data Excel Import ori"
{
    Access = Internal;

    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TempFieldErrors: Record "Excel Buffer" temporary;
        TempFieldValidateBuffer: Record "Integer" temporary;
        TempFieldMapping: Record "Line Number Buffer" temporary;
        Excel2007FileTypeTok: Label 'Excel Files (*.xlsx;*.xls)|*.xlsx;*.xls', Locked = true;
        ExcelFileExtensionTok: Label '.xlsx', Locked = true;
        ImportedTok: Label '%1 record(s) imported\%2 record(s) modified\%3 record(s) with errors', Comment = '%1 = inserted record count, %2 = modified record count, %3 = error record count, is-IS=%1 færslur fluttar inn\%2 færslum breytt\%3 færslur með villum';
        ImportExcelFileTxt: Label 'Import Excel File ', Comment = 'is-IS=Flytja inn Excel-skrá ';
        ImportTok: Label 'Importing #1#################################', Comment = '%1 = table caption;is-IS=Flyt inn #1#################################';

    /// <summary>Asks for an Excel file and imports it into the table.</summary>
    /// <param name="SelectedObject">The table to import into.</param>
    /// <param name="HideDialog">Not used; kept for the original's signature.</param>
    internal procedure ImportRecords(SelectedObject: Record "Table Metadata"; HideDialog: Boolean)
    var
        FileMgt: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        Inserted: Integer;
        Modified: Integer;
        Failed: Integer;
    begin
        if FileMgt.BLOBImportWithFilter(TempBlob, ImportExcelFileTxt, '', Excel2007FileTypeTok, ExcelFileExtensionTok) = '' then
            exit;
        TempBlob.CreateInStream(InStr);
        ImportStream(SelectedObject.ID, SelectedObject.Caption, InStr, true, Inserted, Modified, Failed);
    end;

    /// <summary>Reads an Excel stream, lets the user edit the rows in the preview and imports them.</summary>
    /// <param name="TableID">The table to import into.</param>
    /// <param name="TableCaption">The caption shown in the preview.</param>
    /// <param name="InStr">The .xlsx file.</param>
    /// <param name="ShowPreview">True to open the preview page before each import; false imports at once.</param>
    /// <param name="Inserted">Returns the number of inserted records.</param>
    /// <param name="Modified">Returns the number of modified records.</param>
    /// <param name="Failed">Returns the number of refused rows.</param>
    internal procedure ImportStream(TableID: Integer; TableCaption: Text; InStr: InStream; ShowPreview: Boolean; var Inserted: Integer; var Modified: Integer; var Failed: Integer)
    var
        TableDataAccess: Record "Table Data Access ori";
        TableJSONImport: Codeunit "Table JSON Import ori";
        SheetName: Text;
    begin
        TableDataAccess.AssertModifyAccess();
        TableJSONImport.AssertTableWritable(TableID);
        Inserted := 0;
        Modified := 0;
        Failed := 0;
        SheetName := TempExcelBuffer.SelectSheetsNameStream(InStr);
        TempExcelBuffer.OpenBookStream(InStr, SheetName);
        TempExcelBuffer.ReadSheetContinous(SheetName, true);
        ReadHeaderLine(TableID);
        while GetLastRowNo() > 1 do begin
            if ShowPreview then
                if not EditImportData(TableID, TableCaption) then
                    exit;
            TempFieldErrors.DeleteAll();
            if not ImportData(TableID, TableCaption, ShowPreview, Inserted, Modified, Failed) then
                exit;
        end;
    end;

    local procedure EditImportData(TableID: Integer; TableCaption: Text) LookupOK: Boolean
    var
        ImportTable: Page "Table Data Import ori";
    begin
        ImportTable.LookupMode(true);
        ImportTable.LoadColumnCaptions(TableID, TempFieldMapping);
        ImportTable.LoadFactbox(TableID, TempFieldMapping, TempFieldValidateBuffer);
        ImportTable.LoadRows(TempExcelBuffer, TempFieldErrors, CopyStr(TableCaption, 1, 1024), GetLastRowNo());
        LookupOK := ImportTable.RunModal() = Action::LookupOK;
    end;

    local procedure GetLastRowNo(): Integer
    begin
        TempExcelBuffer.Reset();
        if TempExcelBuffer.FindLast() then
            exit(TempExcelBuffer."Row No.");
    end;

    local procedure ImportData(TableID: Integer; TableCaption: Text; ShowPreview: Boolean; var Inserted: Integer; var Modified: Integer; var Failed: Integer): Boolean
    var
        TableJSONImport: Codeunit "Table JSON Import ori";
        Window: Dialog;
        Envelope: JsonObject;
        Result: JsonObject;
        RowNo: Integer;
        LastRowNo: Integer;
        Progress: Boolean;
        NoOfImported: Integer;
        NoOfModified: Integer;
        NoOfErrors: Integer;
    begin
        LastRowNo := GetLastRowNo();
        if GuiAllowed() then begin
            Window.Open(ImportTok);
            Window.Update(1, TableCaption);
        end;
        for RowNo := 2 to LastRowNo do begin
            Envelope := BuildEnvelope(TableID, RowNo);
            if HasCells(RowNo) then begin
                Result := TableJSONImport.ImportTable(Envelope, true, false);
                if GetCount(Result, 'failed') = 0 then begin
                    Result := TableJSONImport.ImportTable(Envelope, false, false);
                    NoOfImported += GetCount(Result, 'inserted');
                    NoOfModified += GetCount(Result, 'modified');
                    TempExcelBuffer.SetRange("Row No.", RowNo);
                    TempExcelBuffer.DeleteAll();
                    TempExcelBuffer.SetRange("Row No.");
                    Progress := true;
                    Commit();
                end else begin
                    NoOfErrors += 1;
                    MarkRowAsError(RowNo);
                end;
            end;
        end;
        TempExcelBuffer.SetRange("Row No.");
        if GuiAllowed() then
            Window.Close();
        Inserted += NoOfImported;
        Modified += NoOfModified;
        Failed += NoOfErrors;
        if GuiAllowed() and ShowPreview then
            Message(ImportedTok, NoOfImported, NoOfModified, NoOfErrors);
        // Rows that stay (errors) are shown again by the preview; without a preview the import ends.
        exit(ShowPreview and (Progress or (NoOfErrors > 0)) and (GetLastRowNo() > 1));
    end;

    local procedure HasCells(RowNo: Integer): Boolean
    begin
        TempExcelBuffer.SetRange("Row No.", RowNo);
        exit(not TempExcelBuffer.IsEmpty());
    end;

    local procedure MarkRowAsError(RowNo: Integer)
    begin
        TempExcelBuffer.SetRange("Row No.", RowNo);
        if TempExcelBuffer.FindSet() then
            repeat
                if TempFieldMapping.Get(TempExcelBuffer."Column No.") then begin
                    TempFieldErrors.TransferFields(TempExcelBuffer);
                    TempFieldErrors.Insert();
                end;
            until TempExcelBuffer.Next() = 0;
        TempExcelBuffer.SetRange("Row No.");
    end;

    local procedure BuildEnvelope(TableID: Integer; RowNo: Integer) Envelope: JsonObject
    var
        TableField: Record "Field";
        TableJSONExport: Codeunit "Table JSON Export ori";
        TableDataMgt: Codeunit "Table Data Mgt ori";
        PrimaryKey: JsonObject;
        FieldsJson: JsonObject;
        Row: JsonObject;
        Rows: JsonArray;
    begin
        TempExcelBuffer.SetRange("Row No.", RowNo);
        if TempExcelBuffer.FindSet() then
            repeat
                if TempFieldMapping.Get(TempExcelBuffer."Column No.") then begin
                    TableField.SetLoadFields(FieldName, IsPartOfPrimaryKey, Type);
                    TableField.Get(TableID, TempFieldMapping."New Line Number");
                    if (TempExcelBuffer."Cell Value as Text" <> '') or (TableField.Type in [TableField.Type::Text, TableField.Type::Code]) then
                        if TableField.IsPartOfPrimaryKey then
                            PrimaryKey.Add(TableDataMgt.GetJsonKey(TableField.FieldName), TempExcelBuffer."Cell Value as Text")
                        else
                            FieldsJson.Add(TableDataMgt.GetJsonKey(TableField.FieldName), TempExcelBuffer."Cell Value as Text");
                end;
            until TempExcelBuffer.Next() = 0;
        TempExcelBuffer.SetRange("Row No.");
        Row.Add('primaryKey', PrimaryKey);
        Row.Add('fields', FieldsJson);
        Rows.Add(Row);
        Envelope.Add('format', TableJSONExport.GetFormatName());
        Envelope.Add('version', TableJSONExport.GetFormatVersion());
        Envelope.Add('tableNo', TableID);
        Envelope.Add('rows', Rows);
    end;

    local procedure GetCount(Result: JsonObject; KeyName: Text): Integer
    var
        Token: JsonToken;
    begin
        if Result.Get(KeyName, Token) then
            if Token.IsValue() then
                exit(Token.AsValue().AsInteger());
    end;

    local procedure IsValidFieldType(TableField: Record "Field"): Boolean
    begin
        exit(TableField.Type in [
            TableField.Type::Integer,
            TableField.Type::BigInteger,
            TableField.Type::Decimal,
            TableField.Type::Date,
            TableField.Type::Boolean,
            TableField.Type::GUID,
            TableField.Type::Text,
            TableField.Type::Code,
            TableField.Type::Option,
            TableField.Type::Duration,
            TableField.Type::Time,
            TableField.Type::DateTime,
            TableField.Type::DateFormula]);
    end;

    local procedure ReadHeaderLine(TableID: Integer)
    var
        TableField: Record "Field";
    begin
        TableField.SetRange(TableNo, TableID);
        TableField.SetRange(Class, TableField.Class::Normal);
        TableField.SetRange(Enabled, true);
        TableField.SetRange(ObsoleteState, TableField.ObsoleteState::No);
        TempExcelBuffer.SetRange("Row No.", 1);
        if TempExcelBuffer.FindSet() then
            repeat
                if TableField.FindSet() then
                    repeat
                        if IsValidFieldType(TableField) then
                            if UpperCase(TableField.FieldName) = UpperCase(TempExcelBuffer."Cell Value as Text") then begin
                                TempFieldMapping.Init();
                                TempFieldMapping."Old Line Number" := TempExcelBuffer."Column No.";
                                TempFieldMapping."New Line Number" := TableField."No.";
                                TempFieldMapping.Insert();
                                // Foundation validates every imported field, so every mapped field is shown as validated.
                                TempFieldValidateBuffer.Number := TableField."No.";
                                TempFieldValidateBuffer.Insert();
                                break;
                            end;
                    until TableField.Next() = 0;
            until TempExcelBuffer.Next() = 0;
        TempExcelBuffer.SetRange("Row No.");
    end;
}
