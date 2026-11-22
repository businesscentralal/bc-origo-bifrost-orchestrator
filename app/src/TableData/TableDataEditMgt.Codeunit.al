namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.Reflection;

/// <summary>
/// Reads and writes the rows of the Table Data Management edit page (#261). Port of "Tools Edit Mgt" from Tools for Power Users
/// without its built-in elevated permissions. Every value shown comes from Foundation's "Serializer ori" through
/// "Table JSON Export ori", so a restricted table or field is never shown; every change and delete passes the
/// Foundation write guards and the Table Data Management modify access.
/// </summary>
codeunit 10035602 "Table Data Edit Mgt ori"
{
    Access = Internal;

    var
        ProcessTok: Label 'Reading records #1######## of #2########', Comment = '#1 = No. of records read; #2 = Total no. of records;is-IS=Les færslur #1######## af #2########';
        RecordNotFoundErr: Label 'The record no longer exists in table %1.', Comment = '%1 = table number, is-IS=Færslan er ekki lengur til í töflu %1.';

    /// <summary>Whether the user may write to the table and Foundation does not restrict it for writing.</summary>
    /// <param name="TableId">The table number.</param>
    /// <returns>True when the table exists, the user has write permission and the table is not write restricted.</returns>
    internal procedure CheckIfWritePermissionsExistForTheUser(TableId: Integer): Boolean
    var
        TempArgument: Record "Message Argument ori" temporary;
        RecRef: RecordRef;
    begin
        if not TableExists(TableId) then
            exit(false);
        if TempArgument.IsTableWriteRestrictedForDataRecords(TableId, false) then
            exit(false);
        RecRef.Open(TableId);
        exit(RecRef.WritePermission);
    end;

    /// <summary>Returns the field captions of the grid columns.</summary>
    /// <param name="TableId">The table number.</param>
    /// <param name="ShowAuditFields">Whether the system audit fields are columns.</param>
    /// <returns>One caption per column.</returns>
    internal procedure GetColumnCaptions(TableId: Integer; ShowAuditFields: Boolean) MatrixColumnCaptionsOut: array[1000] of Text[100]
    var
        Field: Record Field;
        i: Integer;
    begin
        i := 1;
        SetFilterOnFields(Field, TableId, ShowAuditFields);
        Field.SetLoadFields("Field Caption");
        if Field.FindSet() then
            repeat
                MatrixColumnCaptionsOut[i] := Field."Field Caption";
                i := i + 1;
            until Field.Next() = 0;
    end;

    /// <summary>Reads the values of one grid row through the Foundation serializer.</summary>
    /// <param name="MatrixColumnOrdinal">Returns the number of columns.</param>
    /// <param name="MatrixCellData">Returns the cell text per column; a field Foundation hides is blank.</param>
    /// <param name="RecordColumnField">Returns the field number per column.</param>
    /// <param name="TempTableEdit">The grid row.</param>
    /// <param name="ShowAuditFields">Whether the system audit fields are columns.</param>
    internal procedure GetColumnValues(var MatrixColumnOrdinal: Integer; var MatrixCellData: array[1000] of Text[250]; var RecordColumnField: array[1000] of Integer; var TempTableEdit: Record "Table Data Edit ori"; ShowAuditFields: Boolean)
    var
        Field: Record Field;
        TableJSONExport: Codeunit "Table JSON Export ori";
        TableDataMgt: Codeunit "Table Data Mgt ori";
        RecRef: RecordRef;
        Row: JsonObject;
        FieldNos: List of [Integer];
        CellText: Text;
    begin
        MatrixColumnOrdinal := 0;
        Clear(MatrixCellData);
        TableJSONExport.AssertTableReadable(TempTableEdit."Table ID");
        RecRef.Open(TempTableEdit."Table ID");
        if not RecRef.GetBySystemId(TempTableEdit."Record System Id") then
            Error(ErrorInfo.Create(StrSubstNo(RecordNotFoundErr, TempTableEdit."Table ID")));
        Row := TableJSONExport.SerializeRow(RecRef, FieldNos);
        SetFilterOnFields(Field, TempTableEdit."Table ID", ShowAuditFields);
        Field.SetLoadFields("No.", FieldName);
        if Field.FindSet() then
            repeat
                MatrixColumnOrdinal := MatrixColumnOrdinal + 1;
                if Field."No." >= 2000000000 then
                    CellText := Format(RecRef.Field(Field."No.").Value(), 0, 9)
                else
                    CellText := GetRowValue(Row, TableDataMgt.GetJsonKey(Field.FieldName));
                MatrixCellData[MatrixColumnOrdinal] := CopyStr(CellText, 1, 250);
                RecordColumnField[MatrixColumnOrdinal] := Field."No.";
            until Field.Next() = 0;
        RecRef.Close();
    end;

    /// <summary>The number of grid columns.</summary>
    /// <param name="TableId">The table number.</param>
    /// <param name="ShowAuditFields">Whether the system audit fields are columns.</param>
    /// <returns>The field count.</returns>
    internal procedure GetFieldsCount(TableId: Integer; ShowAuditFields: Boolean): Integer
    var
        Field: Record Field;
    begin
        SetFilterOnFields(Field, TableId, ShowAuditFields);
        exit(Field.Count);
    end;

    /// <summary>Marks the grid columns that cannot be edited: primary key and system fields.</summary>
    /// <param name="TableId">The table number.</param>
    /// <param name="ShowAuditFields">Whether the system audit fields are columns.</param>
    /// <returns>True per read-only column.</returns>
    internal procedure GetIfRecordColumnReadOnly(TableId: Integer; ShowAuditFields: Boolean) RecordColumnReadOnly: array[1000] of Boolean
    var
        Field: Record Field;
        i: Integer;
    begin
        i := 1;
        SetFilterOnFields(Field, TableId, ShowAuditFields);
        Field.SetLoadFields("No.", IsPartOfPrimaryKey);
        if Field.FindSet() then
            repeat
                RecordColumnReadOnly[i] := Field.IsPartOfPrimaryKey or (Field."No." >= 2000000000);
                i := i + 1;
            until Field.Next() = 0;
    end;

    /// <summary>Loads the grid rows of a table, after the Foundation table read guard.</summary>
    /// <param name="TableId">The table number.</param>
    /// <param name="Filters">The filter dialog text; blank loads all rows.</param>
    /// <param name="TempFilter">The four date and time filters.</param>
    /// <param name="TempTableEdit">Receives one row per record.</param>
    internal procedure InitRecords(TableId: Integer; Filters: Text; var TempFilter: Record "Table Data Edit ori"; var TempTableEdit: Record "Table Data Edit ori")
    var
        TableJSONExport: Codeunit "Table JSON Export ori";
        FilterMgt: Codeunit "Table Data Filter Mgt ori";
        RecRef: RecordRef;
        FieldNos: List of [Integer];
        Window: Dialog;
        Counter: Integer;
        Total: Integer;
    begin
        AssertReadAccess();
        TableJSONExport.OpenForRead(TableId, '', FieldNos, RecRef);
        FilterMgt.GetFilteredRecord(RecRef, Filters);
        FilterMgt.ApplyFilterToRecRef(RecRef, TempFilter);
        if GuiAllowed() then begin
            Window.Open(ProcessTok);
            Total := RecRef.Count;
            Window.Update(1, 0);
            Window.Update(2, Total);
        end;
        if RecRef.FindSet() then
            repeat
                Counter += 1;
                TempTableEdit.Init();
                TempTableEdit."Table ID" := TableId;
                TempTableEdit."Entry No." := Counter;
                TempTableEdit."Record System Id" := RecRef.Field(RecRef.SystemIdNo).Value();
                TempTableEdit.Insert();
                if GuiAllowed() then
                    if Counter mod 100 = 0 then
                        Window.Update(1, Counter);
            until RecRef.Next() = 0;
        if GuiAllowed() then
            Window.Close();
        RecRef.Close();
    end;

    /// <summary>Sets the filters that select the fields of the grid and the exports.</summary>
    /// <param name="Field">The field record to filter.</param>
    /// <param name="TableId">The table number.</param>
    /// <param name="ShowAuditFields">Whether the system audit fields are included.</param>
    internal procedure SetFilterOnFields(var Field: Record Field; TableId: Integer; ShowAuditFields: Boolean)
    begin
        Field.SetRange(TableNo, TableId);
        Field.SetRange(ObsoleteState, Field.ObsoleteState::No, Field.ObsoleteState::Pending);
        if not ShowAuditFields then
            Field.SetRange("No.", 1, 1999999999);
        Field.SetRange(Class, Field.Class::Normal);
    end;

    /// <summary>Whether the table exists.</summary>
    /// <param name="TableId">The table number.</param>
    /// <returns>True when a table object with the number exists.</returns>
    internal procedure TableExists(TableId: Integer): Boolean
    var
        AllObj: Record AllObj;
    begin
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object ID", TableId);
        exit(not AllObj.IsEmpty());
    end;

    /// <summary>Saves one edited cell through the Foundation guards.</summary>
    /// <param name="TableId">The table number.</param>
    /// <param name="RecordSystemId">SystemId of the record.</param>
    /// <param name="FieldNo">The field number.</param>
    /// <param name="NewValue">The new value in the serializer's text form.</param>
    internal procedure SaveCell(TableId: Integer; RecordSystemId: Guid; FieldNo: Integer; NewValue: Text)
    var
        TableDataMgt: Codeunit "Table Data Mgt ori";
    begin
        AssertModifyAccess();
        TableDataMgt.SaveField(TableId, RecordSystemId, FieldNo, NewValue);
    end;

    /// <summary>Raises an error when the user may not delete rows of the table.</summary>
    /// <param name="TableId">The table number.</param>
    internal procedure AssertCanDelete(TableId: Integer)
    var
        TableJSONImport: Codeunit "Table JSON Import ori";
    begin
        AssertModifyAccess();
        TableJSONImport.AssertTableWritable(TableId);
    end;

    /// <summary>Deletes one record after the Table Data Management modify access check and the Foundation table write guard.</summary>
    /// <param name="TableId">The table number.</param>
    /// <param name="RecordSystemId">SystemId of the record.</param>
    internal procedure DeleteRecord(TableId: Integer; RecordSystemId: Guid)
    var
        RecRef: RecordRef;
    begin
        AssertCanDelete(TableId);
        RecRef.Open(TableId);
        if not RecRef.GetBySystemId(RecordSystemId) then
            Error(ErrorInfo.Create(StrSubstNo(RecordNotFoundErr, TableId)));
        RecRef.Delete(true);
        RecRef.Close();
    end;

    /// <summary>Raises an error unless the user has Table Data Management read access.</summary>
    internal procedure AssertReadAccess()
    var
        TableDataAccess: Record "Table Data Access ori";
    begin
        TableDataAccess.AssertReadAccess();
    end;

    /// <summary>Raises an error unless the user has Table Data Management modify access.</summary>
    internal procedure AssertModifyAccess()
    var
        TableDataAccess: Record "Table Data Access ori";
    begin
        TableDataAccess.AssertModifyAccess();
    end;

    /// <summary>Reads the text of one field from a serializer row (primaryKey or fields object).</summary>
    /// <param name="Row">The serializer row.</param>
    /// <param name="JsonKey">The JSON key of the field.</param>
    /// <returns>The value text; blank when the row does not hold the field.</returns>
    internal procedure GetRowValue(Row: JsonObject; JsonKey: Text) Result: Text
    var
        Part: JsonObject;
        Token: JsonToken;
        PartToken: JsonToken;
        PartName: Text;
    begin
        foreach PartName in GetPartNames() do
            if Row.Get(PartName, PartToken) then
                if PartToken.IsObject() then begin
                    Part := PartToken.AsObject();
                    if Part.Get(JsonKey, Token) then begin
                        if Token.IsValue() then begin
                            if not Token.AsValue().IsNull() then
                                Result := Token.AsValue().AsText();
                        end else
                            Token.WriteTo(Result);
                        exit;
                    end;
                end;
    end;

    local procedure GetPartNames() Names: List of [Text]
    begin
        Names.Add('primaryKey');
        Names.Add('fields');
    end;
}
