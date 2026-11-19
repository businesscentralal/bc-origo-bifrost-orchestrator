namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.Reflection;

/// <summary>
/// Exports the rows of one table as a Bifrost table data file (#155, Phase 1). Every row is written by Foundation's
/// public "Serializer ori" (SerializeToJson), so a row has exactly the Data.Records.Get shape: primaryKey, id and fields.
/// The table-level read guard of Foundation is called first; a restricted table is refused and nothing is read.
/// File envelope: { "format": "bifrost-table-data", "version": 1, "tableNo", "tableName", "rows": [ ... ] }.
/// </summary>
codeunit 10035558 "Table JSON Export ori"
{
    Access = Internal;

    var
        TableNotFoundErr: Label 'Table %1 does not exist.', Comment = '%1 = table number, is-IS=Tafla %1 er ekki til.';
        TableReadRestrictedErr: Label 'Table %1 (%2) cannot be read by the table data export.', Comment = '%1 = table number, %2 = table name, is-IS=Útflutningur töflugagna getur ekki lesið töflu %1 (%2).';
        PlaybookNotFoundErr: Label 'Playbook %1 does not exist.', Comment = '%1 = playbook code, is-IS=Keðjan %1 er ekki til.';
        TableViewInvalidErr: Label 'The table view is not valid for table %1.', Comment = '%1 = table number, is-IS=Töflusýnin er ekki gild fyrir töflu %1.';

    /// <summary>
    /// Builds the table data file envelope for a table.
    /// </summary>
    /// <param name="TableNo">Number of the table to export.</param>
    /// <param name="TableView">Optional table view (filters and sort order); validated before it is applied. Empty exports every row.</param>
    /// <param name="FieldNos">Optional field numbers to write in each row's fields object. An empty list writes every eligible field.</param>
    /// <returns>The file envelope with one serializer row per record.</returns>
    internal procedure ExportTable(TableNo: Integer; TableView: Text; FieldNos: List of [Integer]) Envelope: JsonObject
    var
        RecRef: RecordRef;
        Rows: JsonArray;
    begin
        OpenForRead(TableNo, TableView, FieldNos, RecRef);
        if RecRef.FindSet() then
            repeat
                Rows.Add(SerializeRow(RecRef, FieldNos));
            until RecRef.Next() = 0;
        Envelope.Add('format', GetFormatName());
        Envelope.Add('version', GetFormatVersion());
        Envelope.Add('tableNo', TableNo);
        Envelope.Add('tableName', RecRef.Name());
        Envelope.Add('rows', Rows);
        RecRef.Close();
    end;

    /// <summary>
    /// Serializes one record through Foundation's "Serializer ori"; the result is the Data.Records.Get row shape.
    /// </summary>
    /// <param name="RecRef">The record to serialize, positioned on a row.</param>
    /// <param name="FieldNos">Optional field numbers; an empty list writes every eligible field.</param>
    /// <returns>The serializer envelope (primaryKey, id, fields).</returns>
    internal procedure SerializeRow(RecRef: RecordRef; FieldNos: List of [Integer]): JsonObject
    var
        Serializer: Codeunit "Serializer ori";
        Row: JsonObject;
    begin
        Row := Serializer.SerializeToJson(RecRef, FieldNos);
        RemoveBlankOptionValues(RecRef, Row);
        exit(Row);
    end;

    /// <summary>
    /// Builds a Bifrost playbook file (#223): the playbook, its steps, its conditions and the Transform mapping rows of its
    /// steps, each as a regular table data file. A playbook that does not exist is refused.
    /// File envelope: { "format": "bifrost-playbook", "version": 1, "playbookCode", "tables": [ table data files ] }.
    /// </summary>
    /// <param name="PlaybookCode">Code of the playbook to export.</param>
    /// <returns>The playbook file envelope.</returns>
    internal procedure ExportPlaybook(PlaybookCode: Code[20]) Envelope: JsonObject
    var
        Playbook: Record "Playbook ori";
        Tables: JsonArray;
        TableNo: Integer;
    begin
        if not Playbook.Get(PlaybookCode) then
            Error(ErrorInfo.Create(StrSubstNo(PlaybookNotFoundErr, PlaybookCode)));
        foreach TableNo in GetPlaybookTables() do
            Tables.Add(ExportPlaybookTable(TableNo, PlaybookCode));
        Envelope.Add('format', GetPlaybookFormatName());
        Envelope.Add('version', GetFormatVersion());
        Envelope.Add('playbookCode', PlaybookCode);
        Envelope.Add('tables', Tables);
    end;

    /// <summary>The format name written to and expected in a playbook file.</summary>
    /// <returns>bifrost-playbook</returns>
    internal procedure GetPlaybookFormatName(): Text
    begin
        exit('bifrost-playbook');
    end;

    /// <summary>The tables of a playbook file in the order they are exported and imported (parents before children).</summary>
    /// <returns>Playbook, Playbook Step, Playbook Condition and Playbook Transform table numbers.</returns>
    internal procedure GetPlaybookTables() TableNos: List of [Integer]
    begin
        TableNos.Add(Database::"Playbook ori");
        TableNos.Add(Database::"Playbook Step ori");
        TableNos.Add(Database::"Playbook Condition ori");
        TableNos.Add(Database::"Playbook Transform ori");
    end;

    /// <summary>
    /// Removes an option or enum value that is the unnamed ordinal 0 from a serialized row. An enum such as Message Type
    /// has no member with ordinal 0, so Foundation writes "0" for it and refuses "0" and "" when it reads the row back
    /// (#223, for example Message Type on a Transform step); leaving the key out is what an import can read.
    /// </summary>
    /// <param name="RecRef">The record that was serialized.</param>
    /// <param name="Row">The serialized envelope (primaryKey, id, fields); its fields object is changed.</param>
    internal procedure RemoveBlankOptionValues(RecRef: RecordRef; var Row: JsonObject)
    var
        TableDataMgt: Codeunit "Table Data Mgt ori";
        FieldRef: FieldRef;
        Fields: JsonObject;
        Token: JsonToken;
        JsonKey: Text;
        Index: Integer;
    begin
        if not Row.Get('fields', Token) then
            exit;
        if not Token.IsObject() then
            exit;
        Fields := Token.AsObject();
        for Index := 1 to RecRef.FieldCount() do begin
            FieldRef := RecRef.FieldIndex(Index);
            if (FieldRef.Class() = FieldClass::Normal) and (FieldRef.Type() = FieldType::Option) then begin
                JsonKey := TableDataMgt.GetJsonKey(FieldRef.Name());
                if Fields.Get(JsonKey, Token) then
                    if Token.IsValue() then
                        if IsUnnamedZero(FieldRef, Token.AsValue().AsText()) then
                            Fields.Remove(JsonKey);
            end;
        end;
        Row.Replace('fields', Fields);
    end;

    /// <summary>
    /// True when a serialized option or enum value is the unnamed ordinal 0: the text is "0" or empty and the first
    /// member of the field is not blank (a blank first member is an ordinary value Foundation reads back).
    /// </summary>
    /// <param name="FieldRef">The option or enum field.</param>
    /// <param name="JsonText">The serialized value.</param>
    /// <returns>True for the unnamed ordinal 0.</returns>
    internal procedure IsUnnamedZero(FieldRef: FieldRef; JsonText: Text): Boolean
    begin
        if not (JsonText in ['', '0']) then
            exit(false);
        exit(not FieldRef.OptionMembers().StartsWith(','));
    end;

    local procedure ExportPlaybookTable(TableNo: Integer; PlaybookCode: Code[20]) TableFile: JsonObject
    var
        RecRef: RecordRef;
        FieldNos: List of [Integer];
        Rows: JsonArray;
    begin
        OpenForRead(TableNo, '', FieldNos, RecRef);
        RecRef.Field(1).SetRange(PlaybookCode);
        if RecRef.FindSet() then
            repeat
                Rows.Add(SerializeRow(RecRef, FieldNos));
            until RecRef.Next() = 0;
        TableFile.Add('format', GetFormatName());
        TableFile.Add('version', GetFormatVersion());
        TableFile.Add('tableNo', TableNo);
        TableFile.Add('tableName', RecRef.Name());
        TableFile.Add('rows', Rows);
        RecRef.Close();
    end;

    /// <summary>
    /// Opens a table for reading after the Foundation table read guard, applies a validated table view and limits the
    /// loaded fields. Raises an error for an unknown table, a read-restricted table or an invalid view.
    /// </summary>
    /// <param name="TableNo">Number of the table.</param>
    /// <param name="TableView">Optional table view; validated by "Message Argument ori".ApplyTableView.</param>
    /// <param name="FieldNos">Optional field numbers to load (the primary key is always loaded).</param>
    /// <param name="RecRef">Returns the opened RecordRef.</param>
    internal procedure OpenForRead(TableNo: Integer; TableView: Text; FieldNos: List of [Integer]; var RecRef: RecordRef)
    var
        FieldNo: Integer;
    begin
        AssertTableReadable(TableNo);
        RecRef.Open(TableNo);
        ApplyView(TableView, RecRef);
        if FieldNos.Count() > 0 then
            foreach FieldNo in FieldNos do
                if RecRef.FieldExist(FieldNo) then
                    RecRef.AddLoadFields(FieldNo);
        RecRef.ReadIsolation := IsolationLevel::ReadCommitted;
    end;

    /// <summary>
    /// Raises an error when the table does not exist or Foundation restricts it for reading.
    /// </summary>
    /// <param name="TableNo">Number of the table.</param>
    internal procedure AssertTableReadable(TableNo: Integer)
    var
        TempArgument: Record "Message Argument ori" temporary;
        AllObj: Record AllObjWithCaption;
    begin
        AllObj.SetLoadFields("Object Name");
        if not AllObj.Get(AllObj."Object Type"::Table, TableNo) then
            Error(ErrorInfo.Create(StrSubstNo(TableNotFoundErr, TableNo)));
        if TempArgument.IsTableReadRestrictedForDataRecords(TableNo) then
            Error(ErrorInfo.Create(TempArgument.GetRestrictedTableErrorText(TableNo, StrSubstNo(TableReadRestrictedErr, TableNo, AllObj."Object Name"), false)));
    end;

    /// <summary>The format name written to and expected in a table data file.</summary>
    /// <returns>bifrost-table-data</returns>
    internal procedure GetFormatName(): Text
    begin
        exit('bifrost-table-data');
    end;

    /// <summary>The format version written to and expected in a table data file.</summary>
    /// <returns>1</returns>
    internal procedure GetFormatVersion(): Integer
    begin
        exit(1);
    end;

    local procedure ApplyView(TableView: Text; var RecRef: RecordRef)
    var
        TempArgument: Record "Message Argument ori" temporary;
        Request: JsonObject;
        Response: JsonObject;
        ErrorToken: JsonToken;
    begin
        if TableView = '' then
            exit;
        TempArgument.Insert();
        Request.Add('tableView', TableView);
        if not TempArgument.ApplyTableView(Request, RecRef) then begin
            Response := TempArgument.GetResponseJson();
            if Response.Get('error', ErrorToken) then
                Error(ErrorInfo.Create(ErrorToken.AsValue().AsText()));
            Error(ErrorInfo.Create(StrSubstNo(TableViewInvalidErr, RecRef.Number())));
        end;
    end;
}
