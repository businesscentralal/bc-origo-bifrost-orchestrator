namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.Reflection;

/// <summary>
/// Imports a Bifrost table data file written by "Table JSON Export ori" (#155, Phase 1). Every row is applied through
/// Foundation's public "Serializer ori" (DeserializeFromJson) and persisted with Insert(true) or Modify(true).
/// A row is matched first by its id (SystemId), then by its primaryKey object; a row that matches nothing is inserted.
/// The import runs in two passes. The first pass reads every row without writing: a value the serializer cannot read
/// (its aggregated error), a restricted field or an insert the Foundation insert guard refuses becomes a failure of that
/// row and the other rows continue, unless StopOnError is true, which stops the import with that error and writes
/// nothing. The second pass, skipped by a dry run, persists only the rows that passed. An error raised by a table
/// trigger while persisting stops the import and the transaction is rolled back.
/// The Foundation table write guard is called first, with Force = false; a restricted table is refused and nothing
/// is read or written.
/// </summary>
codeunit 10035563 "Table JSON Import ori"
{
    Access = Internal;

    var
        TableNotFoundErr: Label 'Table %1 does not exist.', Comment = '%1 = table number, is-IS=Tafla %1 er ekki til.';
        TableWriteRestrictedErr: Label 'Table %1 (%2) cannot be written by the table data import.', Comment = '%1 = table number, %2 = table name, is-IS=Innflutningur töflugagna getur ekki skrifað í töflu %1 (%2).';
        InsertRestrictedErr: Label 'A new row cannot be inserted into table %1 (%2).', Comment = '%1 = table number, %2 = table name, is-IS=Ekki er hægt að bæta nýrri línu í töflu %1 (%2).';
        FormatErr: Label 'The file is not a Bifrost table data file (format %1, version %2 expected).', Comment = '%1 = format name, %2 = version number, is-IS=Skráin er ekki Bifröst töflugagnaskrá (vænst var sniðs %1, útgáfu %2).';
        TableNoMissingErr: Label 'The file does not name a table (tableNo).', Comment = 'is-IS=Skráin tilgreinir ekki töflu (tableNo).';
        RowsMissingErr: Label 'The file has no rows array.', Comment = 'is-IS=Skráin hefur engan línulista (rows).';
        RowNotObjectErr: Label 'The row is not a JSON object.', Comment = 'is-IS=Línan er ekki JSON-hlutur.';
        RowKeyMissingErr: Label 'The row has neither an id nor a primaryKey.', Comment = 'is-IS=Línan hefur hvorki id né primaryKey.';
        RowStopErr: Label 'Row %1 failed: %2', Comment = '%1 = row number, %2 = error text, is-IS=Lína %1 mistókst: %2';

    /// <summary>
    /// Imports the rows of a table data file envelope.
    /// </summary>
    /// <param name="Envelope">The file envelope (format, version, tableNo, rows).</param>
    /// <param name="DryRun">True to check every row and write nothing.</param>
    /// <param name="StopOnError">True to stop at the first failed row with its error; nothing is written then.</param>
    /// <returns>Result: tableNo, dryRun, rows, inserted, modified, failed and errors (row number and error text). In a
    /// dry run inserted and modified count the rows that would be inserted or modified.</returns>
    internal procedure ImportTable(Envelope: JsonObject; DryRun: Boolean; StopOnError: Boolean) Result: JsonObject
    var
        Rows: JsonArray;
        Errors: JsonArray;
        RowToken: JsonToken;
        PassedRows: List of [Integer];
        IsNew: Boolean;
        TableNo: Integer;
        RowNo: Integer;
        Inserted: Integer;
        Modified: Integer;
    begin
        ReadEnvelope(Envelope, TableNo, Rows);
        AssertTableWritable(TableNo);
        for RowNo := 1 to Rows.Count() do begin
            Rows.Get(RowNo - 1, RowToken);
            ClearLastError();
            if TryCheckRow(TableNo, RowToken, IsNew) then begin
                PassedRows.Add(RowNo);
                if IsNew then
                    Inserted += 1
                else
                    Modified += 1;
            end else begin
                if StopOnError then
                    Error(ErrorInfo.Create(StrSubstNo(RowStopErr, RowNo, GetLastErrorText())));
                AddRowError(Errors, RowNo, GetLastErrorText());
            end;
        end;
        if not DryRun then
            foreach RowNo in PassedRows do begin
                Rows.Get(RowNo - 1, RowToken);
                PersistRow(TableNo, RowToken.AsObject());
            end;
        Result.Add('tableNo', TableNo);
        Result.Add('dryRun', DryRun);
        Result.Add('rows', Rows.Count());
        Result.Add('inserted', Inserted);
        Result.Add('modified', Modified);
        Result.Add('failed', Errors.Count());
        Result.Add('errors', Errors);
    end;

    /// <summary>
    /// Raises an error when the table does not exist or Foundation restricts it for writing (Force = false).
    /// </summary>
    /// <param name="TableNo">Number of the table.</param>
    internal procedure AssertTableWritable(TableNo: Integer)
    var
        TempArgument: Record "Message Argument ori" temporary;
        AllObj: Record AllObjWithCaption;
    begin
        AllObj.SetLoadFields("Object Name");
        if not AllObj.Get(AllObj."Object Type"::Table, TableNo) then
            Error(ErrorInfo.Create(StrSubstNo(TableNotFoundErr, TableNo)));
        if TempArgument.IsTableWriteRestrictedForDataRecords(TableNo, false) then
            Error(ErrorInfo.Create(TempArgument.GetRestrictedTableErrorText(TableNo, StrSubstNo(TableWriteRestrictedErr, TableNo, AllObj."Object Name"), true)));
    end;

    local procedure ReadEnvelope(Envelope: JsonObject; var TableNo: Integer; var Rows: JsonArray)
    var
        TableJSONExport: Codeunit "Table JSON Export ori";
        Token: JsonToken;
        FormatName: Text;
        Version: Integer;
    begin
        if Envelope.Get('format', Token) then
            if Token.IsValue() then
                FormatName := Token.AsValue().AsText();
        if Envelope.Get('version', Token) then
            if Token.IsValue() then
                Version := Token.AsValue().AsInteger();
        if (FormatName <> TableJSONExport.GetFormatName()) or (Version <> TableJSONExport.GetFormatVersion()) then
            Error(ErrorInfo.Create(StrSubstNo(FormatErr, TableJSONExport.GetFormatName(), TableJSONExport.GetFormatVersion())));
        if not Envelope.Get('tableNo', Token) then
            Error(ErrorInfo.Create(TableNoMissingErr));
        if not Token.IsValue() then
            Error(ErrorInfo.Create(TableNoMissingErr));
        TableNo := Token.AsValue().AsInteger();
        if not Envelope.Get('rows', Token) then
            Error(ErrorInfo.Create(RowsMissingErr));
        if not Token.IsArray() then
            Error(ErrorInfo.Create(RowsMissingErr));
        Rows := Token.AsArray();
    end;

    [TryFunction]
    local procedure TryCheckRow(TableNo: Integer; RowToken: JsonToken; var IsNew: Boolean)
    var
        RecRef: RecordRef;
    begin
        if not RowToken.IsObject() then
            Error(ErrorInfo.Create(RowNotObjectErr));
        PrepareRow(TableNo, RowToken.AsObject(), RecRef, IsNew);
        RecRef.Close();
    end;

    local procedure PersistRow(TableNo: Integer; Row: JsonObject)
    var
        RecRef: RecordRef;
        IsNew: Boolean;
    begin
        PrepareRow(TableNo, Row, RecRef, IsNew);
        if IsNew then
            RecRef.Insert(true)
        else
            RecRef.Modify(true);
        RecRef.Close();
    end;

    local procedure PrepareRow(TableNo: Integer; Row: JsonObject; var RecRef: RecordRef; var IsNew: Boolean)
    var
        TempArgument: Record "Message Argument ori" temporary;
        Serializer: Codeunit "Serializer ori";
        Token: JsonToken;
    begin
        RecRef.Open(TableNo);
        LocateRow(Row, RecRef, IsNew);
        if IsNew then
            if TempArgument.IsTableInsertRestrictedForDataRecords(TableNo, RecRef, false, false) then
                Error(ErrorInfo.Create(TempArgument.GetRestrictedTableErrorText(TableNo, StrSubstNo(InsertRestrictedErr, TableNo, RecRef.Name()), true)));
        if Row.Get('fields', Token) then
            if Token.IsObject() then
                RecRef := Serializer.DeserializeFromJson(RecRef, Token.AsObject());
    end;

    local procedure LocateRow(Row: JsonObject; var RecRef: RecordRef; var IsNew: Boolean)
    var
        Serializer: Codeunit "Serializer ori";
        Token: JsonToken;
        RowSystemId: Guid;
        HasKey: Boolean;
    begin
        IsNew := false;
        if Row.Get('id', Token) then
            if Token.IsValue() then
                if Evaluate(RowSystemId, Token.AsValue().AsText()) then
                    if RecRef.GetBySystemId(RowSystemId) then
                        exit;
        RecRef.Init();
        if Row.Get('primaryKey', Token) then
            if Token.IsObject() then
                if Token.AsObject().Keys().Count() > 0 then begin
                    RecRef := Serializer.DeserializeFromJson(RecRef, Token.AsObject());
                    HasKey := true;
                end;
        if not HasKey then
            Error(ErrorInfo.Create(RowKeyMissingErr));
        IsNew := not RecRef.Find('=');
    end;

    local procedure AddRowError(var Errors: JsonArray; RowNo: Integer; ErrorText: Text)
    var
        RowError: JsonObject;
    begin
        RowError.Add('row', RowNo);
        RowError.Add('error', ErrorText);
        Errors.Add(RowError);
    end;
}
