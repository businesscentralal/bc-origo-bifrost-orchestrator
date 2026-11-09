namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.Reflection;

/// <summary>
/// Reads and edits the rows of any table that Foundation does not restrict, for the "Table Data ori" and
/// "Table Data Fields ori" pages (#155, Phase 2). Rows are read a page at a time and shown through Foundation's
/// public "Serializer ori", so a read-restricted field is never shown. One field is edited by reading the record fresh,
/// applying a one-key fields object through "Serializer ori".DeserializeFromJson (validation triggers run, field and
/// write-once restrictions apply) and Modify(true). The Foundation table read and write guards are called first,
/// with Force = false.
/// </summary>
codeunit 10035575 "Table Data Mgt ori"
{
    Access = Internal;

    var
        RecordNotFoundErr: Label 'The record no longer exists in table %1.', Comment = '%1 = table number, is-IS=Færslan er ekki lengur til í töflu %1.';
        PrimaryKeyEditErr: Label 'Field %1 is part of the primary key and cannot be edited here.', Comment = '%1 = field name, is-IS=Reiturinn %1 er hluti af aðallyklinum og ekki er hægt að breyta honum hér.';
        FieldNotShownErr: Label 'Field %1 cannot be edited.', Comment = '%1 = field number, is-IS=Ekki er hægt að breyta reit %1.';
        FieldNotChangedErr: Label 'Field %1 was not changed. The field is restricted or can be written only once.', Comment = '%1 = field name, is-IS=Reitnum %1 var ekki breytt. Reiturinn er takmarkaður eða aðeins má skrifa í hann einu sinni.';
        PageSizeErr: Label 'The page size must be between 1 and %1.', Comment = '%1 = maximum page size, is-IS=Síðustærðin verður að vera á bilinu 1 til %1.';

    /// <summary>
    /// Loads one page of rows of a table into the row buffer.
    /// </summary>
    /// <param name="TableNo">Number of the table.</param>
    /// <param name="TableView">Optional table view; validated before it is applied.</param>
    /// <param name="PageNo">Page number, starting at 1.</param>
    /// <param name="PageSize">Rows per page, 1 to 500.</param>
    /// <param name="TempRow">Returns the rows of the page; previous content is deleted.</param>
    /// <returns>True when a further page exists.</returns>
    internal procedure LoadPage(TableNo: Integer; TableView: Text; PageNo: Integer; PageSize: Integer; var TempRow: Record "Table Data Row ori" temporary) HasMore: Boolean
    var
        TableJSONExport: Codeunit "Table JSON Export ori";
        RecRef: RecordRef;
        FieldNos: List of [Integer];
        RowCount: Integer;
        Skip: Integer;
    begin
        TempRow.Reset();
        TempRow.DeleteAll();
        if (PageSize < 1) or (PageSize > GetMaxPageSize()) then
            Error(ErrorInfo.Create(StrSubstNo(PageSizeErr, GetMaxPageSize())));
        if PageNo < 1 then
            PageNo := 1;
        TableJSONExport.OpenForRead(TableNo, TableView, FieldNos, RecRef);
        if not RecRef.FindSet() then
            exit(false);
        Skip := (PageNo - 1) * PageSize;
        if Skip > 0 then
            if RecRef.Next(Skip) < Skip then
                exit(false);
        repeat
            RowCount += 1;
            AddRow(TempRow, RowCount, TableJSONExport.SerializeRow(RecRef, FieldNos));
        until (RowCount = PageSize) or (RecRef.Next() = 0);
        if RowCount = PageSize then
            HasMore := RecRef.Next() <> 0;
        RecRef.Close();
        if TempRow.FindFirst() then;
    end;

    /// <summary>
    /// Loads the readable fields of one record into the field buffer.
    /// </summary>
    /// <param name="TableNo">Number of the table.</param>
    /// <param name="RecordSystemId">SystemId of the record.</param>
    /// <param name="TempField">Returns one line per readable field; previous content is deleted.</param>
    internal procedure LoadRecord(TableNo: Integer; RecordSystemId: Guid; var TempField: Record "Table Data Field ori" temporary)
    var
        TableJSONExport: Codeunit "Table JSON Export ori";
        RecRef: RecordRef;
        Row: JsonObject;
        FieldNos: List of [Integer];
    begin
        TempField.Reset();
        TempField.DeleteAll();
        TableJSONExport.AssertTableReadable(TableNo);
        RecRef.Open(TableNo);
        if not RecRef.GetBySystemId(RecordSystemId) then
            Error(ErrorInfo.Create(StrSubstNo(RecordNotFoundErr, TableNo)));
        Row := TableJSONExport.SerializeRow(RecRef, FieldNos);
        AddFields(TempField, TableNo, Row, 'primaryKey', true);
        AddFields(TempField, TableNo, Row, 'fields', false);
        RecRef.Close();
        if TempField.FindFirst() then;
    end;

    /// <summary>
    /// Saves a new value for one field of one record through "Serializer ori".DeserializeFromJson and Modify(true).
    /// </summary>
    /// <param name="TableNo">Number of the table.</param>
    /// <param name="RecordSystemId">SystemId of the record.</param>
    /// <param name="FieldNo">Number of the field to change; it must be readable and not part of the primary key.</param>
    /// <param name="NewValue">The new value in the serializer's text form.</param>
    internal procedure SaveField(TableNo: Integer; RecordSystemId: Guid; FieldNo: Integer; NewValue: Text)
    var
        TempField: Record "Table Data Field ori" temporary;
        TableJSONImport: Codeunit "Table JSON Import ori";
        Serializer: Codeunit "Serializer ori";
        RecRef: RecordRef;
        FieldsJson: JsonObject;
        OldValue: Text;
    begin
        TableJSONImport.AssertTableWritable(TableNo);
        LoadRecord(TableNo, RecordSystemId, TempField);
        if not TempField.Get(FieldNo) then
            Error(ErrorInfo.Create(StrSubstNo(FieldNotShownErr, FieldNo)));
        if TempField."Part of Primary Key" then
            Error(ErrorInfo.Create(StrSubstNo(PrimaryKeyEditErr, TempField."Field Name")));
        if not CanEditField(TableNo, RecordSystemId, FieldNo) then
            Error(ErrorInfo.Create(StrSubstNo(FieldNotChangedErr, TempField."Field Name")));
        if NewValue = TempField.Value then
            exit;
        RecRef.Open(TableNo);
        RecRef.GetBySystemId(RecordSystemId);
        OldValue := Format(RecRef.Field(FieldNo).Value(), 0, 9);
        FieldsJson.Add(TempField."Json Key", NewValue);
        RecRef := Serializer.DeserializeFromJson(RecRef, FieldsJson);
        if Format(RecRef.Field(FieldNo).Value(), 0, 9) = OldValue then
            Error(ErrorInfo.Create(StrSubstNo(FieldNotChangedErr, TempField."Field Name")));
        RecRef.Modify(true);
        RecRef.Close();
    end;

    /// <summary>Whether a readable, non-key field can be edited on the selected stored row.</summary>
    /// <param name="TableNo">Table number.</param>
    /// <param name="RecordSystemId">Stored row SystemId.</param>
    /// <param name="FieldNo">Field number.</param>
    /// <returns>False for a write-restricted table or an already filled write-once field.</returns>
    internal procedure CanEditField(TableNo: Integer; RecordSystemId: Guid; FieldNo: Integer): Boolean
    var
        TempArgument: Record "Message Argument ori" temporary;
        StoredRecord: RecordRef;
        BlankRecord: RecordRef;
        CanEdit: Boolean;
    begin
        if TempArgument.IsTableWriteRestrictedForDataRecords(TableNo, false) then
            exit(false);
        if not TempArgument.IsFieldWriteOnceForDataRecords(TableNo, FieldNo, false) then
            exit(true);
        StoredRecord.Open(TableNo);
        if not StoredRecord.GetBySystemId(RecordSystemId) then begin
            StoredRecord.Close();
            exit(false);
        end;
        if StoredRecord.Field(FieldNo).Type in [FieldType::BLOB, FieldType::Media, FieldType::MediaSet] then begin
            StoredRecord.Close();
            exit(false);
        end;
        BlankRecord.Open(TableNo);
        CanEdit := Format(StoredRecord.Field(FieldNo).Value(), 0, 9) = Format(BlankRecord.Field(FieldNo).Value(), 0, 9);
        BlankRecord.Close();
        StoredRecord.Close();
        exit(CanEdit);
    end;

    /// <summary>The largest page size the viewer accepts.</summary>
    /// <returns>500</returns>
    internal procedure GetMaxPageSize(): Integer
    begin
        exit(500);
    end;

    /// <summary>
    /// The JSON key the serializer uses for a field name: percent, period, quotes, slash and backslash become underscores;
    /// other characters that are not ASCII letters, digits or underscores are removed.
    /// </summary>
    /// <param name="FieldName">The field name.</param>
    /// <returns>The JSON key.</returns>
    internal procedure GetJsonKey(FieldName: Text) JsonKey: Text
    var
        Character: Char;
        Index: Integer;
    begin
        for Index := 1 to StrLen(FieldName) do begin
            Character := FieldName[Index];
            case true of
                Character in ['%', '.', '"', '''', '/', '\']:
                    JsonKey += '_';
                (Character in ['A' .. 'Z']), (Character in ['a' .. 'z']), (Character in ['0' .. '9']), (Character = '_'):
                    JsonKey += Format(Character);
            end;
        end;
    end;

    local procedure AddRow(var TempRow: Record "Table Data Row ori" temporary; RowNo: Integer; Row: JsonObject)
    var
        Token: JsonToken;
        RowSystemId: Guid;
    begin
        TempRow.Init();
        TempRow."Row No." := RowNo;
        if Row.Get('id', Token) then
            if Evaluate(RowSystemId, Token.AsValue().AsText()) then
                TempRow."Record SystemId" := RowSystemId;
        TempRow."Primary Key" := CopyStr(JoinValues(Row, 'primaryKey', 0, false), 1, MaxStrLen(TempRow."Primary Key"));
        TempRow.Summary := CopyStr(JoinValues(Row, 'fields', 8, true), 1, MaxStrLen(TempRow.Summary));
        TempRow.Insert();
    end;

    local procedure JoinValues(Row: JsonObject; PartName: Text; MaxCount: Integer; WithNames: Boolean) Joined: Text
    var
        Token: JsonToken;
        ValueToken: JsonToken;
        Part: JsonObject;
        KeyName: Text;
        Counted: Integer;
    begin
        if not Row.Get(PartName, Token) then
            exit;
        if not Token.IsObject() then
            exit;
        Part := Token.AsObject();
        Counted := 0;
        foreach KeyName in Part.Keys() do begin
            if (MaxCount > 0) and (Counted = MaxCount) then
                exit;
            Part.Get(KeyName, ValueToken);
            if Joined <> '' then
                Joined += ', ';
            if WithNames then
                Joined += KeyName + '=';
            Joined += TokenText(ValueToken);
            Counted += 1;
        end;
    end;

    local procedure AddFields(var TempField: Record "Table Data Field ori" temporary; TableNo: Integer; Row: JsonObject; PartName: Text; IsPrimaryKey: Boolean)
    var
        TableField: Record Field;
        Token: JsonToken;
        Part: JsonObject;
        JsonKey: Text;
    begin
        if not Row.Get(PartName, Token) then
            exit;
        if not Token.IsObject() then
            exit;
        Part := Token.AsObject();
        TableField.SetRange(TableNo, TableNo);
        TableField.SetLoadFields(TableNo, "No.", FieldName, "Type Name");
        if TableField.FindSet() then
            repeat
                JsonKey := GetJsonKey(TableField.FieldName);
                if Part.Get(JsonKey, Token) then
                    if not TempField.Get(TableField."No.") then begin
                        TempField.Init();
                        TempField."Field No." := TableField."No.";
                        TempField."Field Name" := TableField.FieldName;
                        TempField."Json Key" := CopyStr(JsonKey, 1, MaxStrLen(TempField."Json Key"));
                        TempField.Value := CopyStr(TokenText(Token), 1, MaxStrLen(TempField.Value));
                        TempField.Type := CopyStr(TableField."Type Name", 1, MaxStrLen(TempField.Type));
                        TempField."Part of Primary Key" := IsPrimaryKey;
                        TempField.Insert();
                    end;
            until TableField.Next() = 0;
    end;

    local procedure TokenText(Token: JsonToken) Result: Text
    begin
        if Token.IsValue() then begin
            if Token.AsValue().IsNull() then
                exit('');
            exit(Token.AsValue().AsText());
        end;
        Token.WriteTo(Result);
    end;
}
