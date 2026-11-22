namespace Origo.Bifrost.Orchestrator;

using Microsoft.Utilities;
using System.IO;
using System.Reflection;
using System.Security.AccessControl;
using System.Utilities;

/// <summary>
/// JSON export and import of the Table Data Management main page (#261). Port of "Tools JSON Mgt" from Tools for Power Users.
/// The file is the original's shape, { "TableName": [ { "RecordSystemId", "PrimaryKeyFields", "Fields" } ] }, so files move
/// between the two tools. Values are written and read through Foundation's "Serializer ori" by "Table JSON Export ori"
/// and "Table JSON Import ori", which apply the table read and write guards, field access and write-once rules. A file in
/// the Orchestrator table data envelope is read as well.
/// </summary>
codeunit 10035604 "Table Data JSON Mgt ori"
{
    Access = Internal;

    var
        FileNameTok: Label 'TableData.json', Locked = true;
        NotJsonErr: Label 'The file is not a JSON file.', Comment = 'is-IS=Skráin er ekki JSON-skrá.';
        TableMissingErr: Label 'The file has no records for table %1.', Comment = '%1 = table name, is-IS=Skráin inniheldur engar færslur fyrir töflu %1.';
        ImportedMsg: Label '%1 record(s) inserted\%2 record(s) modified\%3 record(s) with errors', Comment = '%1 = inserted record count, %2 = modified record count, %3 = error record count, is-IS=%1 færslur settar inn\%2 færslum breytt\%3 færslur með villum';

    /// <summary>Exports the selected tables to one JSON file.</summary>
    /// <param name="SelectedObjects">The selected tables.</param>
    /// <param name="ShowAuditFields">Whether the audit fields are written.</param>
    /// <param name="TempFilter">The four date and time filters.</param>
    /// <param name="HideDialog">True to export every record, false to ask for filters per table.</param>
    internal procedure ExportRecords(var SelectedObjects: Record "Table Metadata"; ShowAuditFields: Boolean; var TempFilter: Record "Table Data Edit ori"; HideDialog: Boolean)
    var
        TempFilterStorage: Record "Name/Value Buffer" temporary;
        FilterMgt: Codeunit "Table Data Filter Mgt ori";
        JObject: JsonObject;
    begin
        AssertReadAccess();
        if SelectedObjects.FindSet() then
            repeat
                if FilterMgt.SetSelectionCriteria(SelectedObjects.ID, HideDialog, TempFilterStorage) then
                    JObject.Add(GetFileKey(SelectedObjects.ID), ExportRows(SelectedObjects.ID, ShowAuditFields, TempFilterStorage.GetValue(), TempFilter));
            until SelectedObjects.Next() = 0;
        ExportToFile(JObject);
    end;

    /// <summary>Imports the selected tables from one JSON file.</summary>
    /// <param name="SelectedObjects">The selected tables.</param>
    /// <param name="HideDialog">True to skip tables the file does not hold, false to refuse such a file.</param>
    internal procedure ImportRecords(var SelectedObjects: Record "Table Metadata"; HideDialog: Boolean)
    var
        FileMgt: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        Source: JsonObject;
        Inserted: Integer;
        Modified: Integer;
        Failed: Integer;
        TotalInserted: Integer;
        TotalModified: Integer;
        TotalFailed: Integer;
    begin
        AssertModifyAccess();
        if FileMgt.BLOBImport(TempBlob, FileNameTok) = '' then
            exit;
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        if not Source.ReadFrom(InStr) then
            Error(ErrorInfo.Create(NotJsonErr));
        if SelectedObjects.FindSet() then
            repeat
                if ImportRows(SelectedObjects.ID, Source, Inserted, Modified, Failed) then begin
                    TotalInserted += Inserted;
                    TotalModified += Modified;
                    TotalFailed += Failed;
                end else
                    if not HideDialog then
                        Error(ErrorInfo.Create(StrSubstNo(TableMissingErr, SelectedObjects.Name)));
            until SelectedObjects.Next() = 0;
        Message(ImportedMsg, TotalInserted, TotalModified, TotalFailed);
    end;

    /// <summary>Serializes the filtered records of a table in the original tool's row shape.</summary>
    /// <param name="TableNo">The table number.</param>
    /// <param name="ShowAuditFields">Whether the audit fields are written.</param>
    /// <param name="FilterText">The filter dialog text; blank exports every record.</param>
    /// <param name="TempFilter">The four date and time filters.</param>
    /// <returns>One object per record: RecordSystemId, PrimaryKeyFields, Fields and optionally the audit fields.</returns>
    internal procedure ExportRows(TableNo: Integer; ShowAuditFields: Boolean; FilterText: Text; var TempFilter: Record "Table Data Edit ori") Rows: JsonArray
    var
        TableJSONExport: Codeunit "Table JSON Export ori";
        FilterMgt: Codeunit "Table Data Filter Mgt ori";
        RecRef: RecordRef;
        FieldNos: List of [Integer];
        Row: JsonObject;
        FileRow: JsonObject;
        Token: JsonToken;
    begin
        AssertReadAccess();
        TableJSONExport.OpenForRead(TableNo, '', FieldNos, RecRef);
        FilterMgt.GetFilteredRecord(RecRef, FilterText);
        FilterMgt.ApplyFilterToRecRef(RecRef, TempFilter);
        if RecRef.FindSet() then
            repeat
                Row := TableJSONExport.SerializeRow(RecRef, FieldNos);
                Clear(FileRow);
                if Row.Get('id', Token) then
                    FileRow.Add('RecordSystemId', Token.Clone());
                if Row.Get('primaryKey', Token) then
                    FileRow.Add('PrimaryKeyFields', Token.Clone());
                if Row.Get('fields', Token) then
                    FileRow.Add('Fields', Token.Clone());
                if ShowAuditFields then
                    AddAuditFields(RecRef, FileRow);
                Rows.Add(FileRow);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    /// <summary>Imports the rows of one table from a file object through the Foundation guards.</summary>
    /// <param name="TableNo">The table number.</param>
    /// <param name="Source">The file: the original shape or an Orchestrator table data file.</param>
    /// <param name="Inserted">Returns the number of inserted records.</param>
    /// <param name="Modified">Returns the number of modified records.</param>
    /// <param name="Failed">Returns the number of refused records.</param>
    /// <returns>False when the file holds nothing for the table.</returns>
    internal procedure ImportRows(TableNo: Integer; Source: JsonObject; var Inserted: Integer; var Modified: Integer; var Failed: Integer): Boolean
    var
        TableJSONExport: Codeunit "Table JSON Export ori";
        TableJSONImport: Codeunit "Table JSON Import ori";
        Envelope: JsonObject;
        Rows: JsonArray;
        Result: JsonObject;
        Token: JsonToken;
        RowToken: JsonToken;
        FileRow: JsonObject;
        Row: JsonObject;
    begin
        AssertModifyAccess();
        Inserted := 0;
        Modified := 0;
        Failed := 0;
        if Source.Get('format', Token) then
            if Token.IsValue() then
                if Token.AsValue().AsText() = TableJSONExport.GetFormatName() then begin
                    if Source.Get('tableNo', Token) then
                        if Token.AsValue().AsInteger() <> TableNo then
                            exit(false);
                    Result := TableJSONImport.ImportTable(Source, false, false);
                    ReadCounts(Result, Inserted, Modified, Failed);
                    exit(true);
                end;
        if not Source.Get(GetFileKey(TableNo), Token) then
            exit(false);
        if not Token.IsArray() then
            exit(false);
        foreach RowToken in Token.AsArray() do begin
            Clear(Row);
            if RowToken.IsObject() then begin
                FileRow := RowToken.AsObject();
                if FileRow.Get('RecordSystemId', Token) then
                    Row.Add('id', Token.Clone());
                if FileRow.Get('PrimaryKeyFields', Token) then
                    Row.Add('primaryKey', Token.Clone());
                if FileRow.Get('Fields', Token) then
                    Row.Add('fields', Token.Clone());
            end;
            Rows.Add(Row);
        end;
        Envelope.Add('format', TableJSONExport.GetFormatName());
        Envelope.Add('version', TableJSONExport.GetFormatVersion());
        Envelope.Add('tableNo', TableNo);
        Envelope.Add('rows', Rows);
        Result := TableJSONImport.ImportTable(Envelope, false, false);
        ReadCounts(Result, Inserted, Modified, Failed);
        exit(true);
    end;

    /// <summary>The key of a table in the file: its name without characters other than letters, digits and underscores.</summary>
    /// <param name="TableNo">The table number.</param>
    /// <returns>The key, as the original tool writes it.</returns>
    internal procedure GetFileKey(TableNo: Integer): Text
    var
        TableDataMgt: Codeunit "Table Data Mgt ori";
        AllObj: Record AllObjWithCaption;
    begin
        AllObj.SetLoadFields("Object Name");
        AllObj.Get(AllObj."Object Type"::Table, TableNo);
        exit(TableDataMgt.GetJsonKey(AllObj."Object Name"));
    end;

    local procedure ReadCounts(Result: JsonObject; var Inserted: Integer; var Modified: Integer; var Failed: Integer)
    begin
        Inserted := GetCount(Result, 'inserted');
        Modified := GetCount(Result, 'modified');
        Failed := GetCount(Result, 'failed');
    end;

    local procedure GetCount(Result: JsonObject; KeyName: Text): Integer
    var
        Token: JsonToken;
    begin
        if Result.Get(KeyName, Token) then
            if Token.IsValue() then
                exit(Token.AsValue().AsInteger());
    end;

    local procedure AddAuditFields(RecRef: RecordRef; var FileRow: JsonObject)
    begin
        FileRow.Add('CreatedAt', Format(RecRef.Field(RecRef.SystemCreatedAtNo).Value(), 0, 9));
        FileRow.Add('CreatedBy', GetUserName(RecRef.Field(RecRef.SystemCreatedByNo).Value()));
        FileRow.Add('ModifiedAt', Format(RecRef.Field(RecRef.SystemModifiedAtNo).Value(), 0, 9));
        FileRow.Add('ModifiedBy', GetUserName(RecRef.Field(RecRef.SystemModifiedByNo).Value()));
    end;

    local procedure GetUserName(UserSecurityId: Guid): Text
    var
        User: Record User;
    begin
        User.SetLoadFields("Full Name", "User Name");
        if User.Get(UserSecurityId) then begin
            if User."Full Name" <> '' then
                exit(User."Full Name");
            exit(User."User Name");
        end;
        exit(Format(UserSecurityId, 0, 4));
    end;

    local procedure ExportToFile(var JObject: JsonObject)
    var
        FileMgt: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        JObject.WriteTo(OutStr);
        FileMgt.BLOBExport(TempBlob, FileNameTok, true);
    end;

    local procedure AssertReadAccess()
    var
        TableDataAccess: Record "Table Data Access ori";
    begin
        TableDataAccess.AssertReadAccess();
    end;

    local procedure AssertModifyAccess()
    var
        TableDataAccess: Record "Table Data Access ori";
    begin
        TableDataAccess.AssertModifyAccess();
    end;
}
