namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.Diagnostics;
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
        ExpectedPlaybookCode: Text;
        TableNotFoundErr: Label 'Table %1 does not exist.', Comment = '%1 = table number, is-IS=Tafla %1 er ekki til.';
        TableWriteRestrictedErr: Label 'Table %1 (%2) cannot be written by the table data import.', Comment = '%1 = table number, %2 = table name, is-IS=Innflutningur töflugagna getur ekki skrifað í töflu %1 (%2).';
        InsertRestrictedErr: Label 'A new row cannot be inserted into table %1 (%2).', Comment = '%1 = table number, %2 = table name, is-IS=Ekki er hægt að bæta nýrri línu við töflu %1 (%2).';
        FormatErr: Label 'The file is not a Bifrost table data file (format %1, version %2 expected).', Comment = '%1 = format name, %2 = version number, is-IS=Skráin er ekki Bifröst-töflugagnaskrá (búist var við sniði %1, útgáfu %2).';
        TableNoMissingErr: Label 'The file does not name a table (tableNo).', Comment = 'is-IS=Skráin tilgreinir ekki töflu (tableNo).';
        RowsMissingErr: Label 'The file has no rows array.', Comment = 'is-IS=Skráin inniheldur engan línulista (rows).';
        RowNotObjectErr: Label 'The row is not a JSON object.', Comment = 'is-IS=Línan er ekki JSON-hlutur.';
        RowKeyMissingErr: Label 'The row has neither an id nor a primaryKey.', Comment = 'is-IS=Línan hefur hvorki id né primaryKey.';
        PlaybookFormatErr: Label 'The file is not a Bifrost playbook file (format %1, version %2 expected).', Comment = '%1 = format name, %2 = version number, is-IS=Skráin er ekki Bifröst-keðjuskrá (búist var við sniði %1, útgáfu %2).';
        PlaybookTablesMissingErr: Label 'The file has no tables array of table data files.', Comment = 'is-IS=Skráin inniheldur engan töflulista með töflugagnaskrám.';
        PlaybookTableRefusedErr: Label 'Table %1 does not belong in a playbook file.', Comment = '%1 = table number, is-IS=Tafla %1 á ekki heima í keðjuskrá.';
        PlaybookCodeMissingErr: Label 'The file does not name the playbook (playbookCode).', Comment = 'is-IS=Skráin tilgreinir ekki keðjuna (playbookCode).';
        PlaybookHeaderMissingErr: Label 'The file has no Playbook row for playbook %1.', Comment = '%1 = playbook code, is-IS=Skráin inniheldur enga keðjulínu fyrir keðjuna %1.';
        PlaybookRowMismatchErr: Label 'A row belongs to playbook %1, not to the playbook %2 named in the file.', Comment = '%1 = playbook code of the row, %2 = playbook code of the file, is-IS=Lína tilheyrir keðjunni %1 en ekki keðjunni %2 sem skráin tilgreinir.';
        RowStopHintErr: Label '%1 The Change Log setup does not cover these playbook tables: %2. If the ChangeLog Write Guard refused the row, turn Change Log on and add all of these tables once (Change Log Setup > Tables, log insertion and modification for all fields), then import again.', Comment = '%1 = error text, %2 = list of table captions, is-IS=%1 Breytingaskráning nær ekki yfir þessar keðjutöflur: %2. Ef ChangeLog-skrifvörnin hafnaði línunni skal kveikja á breytingaskráningu og bæta öllum þessum töflum við einu sinni (Uppsetning breytingaskráar > Töflur, skrá innsetningu og breytingu fyrir alla reiti) og flytja svo inn aftur.';
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
        FieldsJson: JsonObject;
        BlankFieldNos: List of [Integer];
    begin
        RecRef.Open(TableNo);
        LocateRow(Row, RecRef, IsNew);
        AssertRowInPlaybook(RecRef);
        if IsNew then
            if TempArgument.IsTableInsertRestrictedForDataRecords(TableNo, RecRef, false, false) then
                Error(ErrorInfo.Create(TempArgument.GetRestrictedTableErrorText(TableNo, StrSubstNo(InsertRestrictedErr, TableNo, RecRef.Name()), true)));
        if Row.Get('fields', Token) then
            if Token.IsObject() then begin
                FieldsJson := Token.AsObject().Clone().AsObject();
                BlankFieldNos := TakeBlankOptionValues(RecRef, FieldsJson);
                RecRef := Serializer.DeserializeFromJson(RecRef, FieldsJson);
                SetBlankOptionValues(RecRef, BlankFieldNos);
            end;
        AssertRowInPlaybook(RecRef);
    end;

    /// <summary>
    /// Removes option and enum values written as "0" or "" for the unnamed ordinal 0 of a field (a file from before
    /// #223 holds "MessageType": "0" on Transform steps); Foundation refuses those values. The field numbers are
    /// returned so the blank member is assigned after the other fields.
    /// </summary>
    local procedure TakeBlankOptionValues(RecRef: RecordRef; var FieldsJson: JsonObject) BlankFieldNos: List of [Integer]
    var
        TableJSONExport: Codeunit "Table JSON Export ori";
        TableDataMgt: Codeunit "Table Data Mgt ori";
        FieldRef: FieldRef;
        Token: JsonToken;
        JsonKey: Text;
        Index: Integer;
    begin
        for Index := 1 to RecRef.FieldCount() do begin
            FieldRef := RecRef.FieldIndex(Index);
            if (FieldRef.Class() = FieldClass::Normal) and (FieldRef.Type() = FieldType::Option) then begin
                JsonKey := TableDataMgt.GetJsonKey(FieldRef.Name());
                if FieldsJson.Get(JsonKey, Token) then
                    if Token.IsValue() then
                        if TableJSONExport.IsUnnamedZero(FieldRef, Token.AsValue().AsText()) then begin
                            FieldsJson.Remove(JsonKey);
                            BlankFieldNos.Add(FieldRef.Number());
                        end;
            end;
        end;
    end;

    local procedure SetBlankOptionValues(var RecRef: RecordRef; BlankFieldNos: List of [Integer])
    var
        FieldNo: Integer;
    begin
        foreach FieldNo in BlankFieldNos do
            RecRef.Field(FieldNo).Value := 0;
    end;

    /// <summary>
    /// Imports a playbook file written by "Table JSON Export ori".ExportPlaybook (#223): the playbook, its steps, its
    /// conditions and its Transform rows, parents first, through the same row import as a table data file. Existing rows
    /// with the same key are modified, others inserted; rows of the playbook that are not in the file stay. The first
    /// failed row stops the import with its error, so the caller's transaction writes nothing.
    /// </summary>
    /// <param name="Envelope">The playbook file envelope.</param>
    /// <returns>Result: playbookCode and tables (tableNo, rows, inserted, modified).</returns>
    internal procedure ImportPlaybook(Envelope: JsonObject) Result: JsonObject
    var
        TableJSONExport: Codeunit "Table JSON Export ori";
        Tables: JsonArray;
        TableResults: JsonArray;
        TableFile: JsonObject;
        TableResult: JsonObject;
        Token: JsonToken;
        TableNo: Integer;
        Index: Integer;
        PlaybookCode: Text;
    begin
        ReadPlaybookEnvelope(Envelope, PlaybookCode, Tables);
        ExpectedPlaybookCode := PlaybookCode;
        foreach TableNo in TableJSONExport.GetPlaybookTables() do
            for Index := 1 to Tables.Count() do begin
                Tables.Get(Index - 1, Token);
                TableFile := Token.AsObject();
                if GetTableNo(TableFile) = TableNo then begin
                    Clear(TableResult);
                    ClearLastError();
                    if not TryImportTable(TableFile, TableResult) then
                        ThrowPlaybookImportError(GetLastErrorText());
                    TableResult.Remove('dryRun');
                    TableResult.Remove('failed');
                    TableResult.Remove('errors');
                    TableResults.Add(TableResult);
                end;
            end;
        ExpectedPlaybookCode := '';
        Result.Add('playbookCode', PlaybookCode);
        Result.Add('tables', TableResults);
    end;

    [TryFunction]
    local procedure TryImportTable(TableFile: JsonObject; var TableResult: JsonObject)
    begin
        TableResult := ImportTable(TableFile, false, true);
    end;

    /// <summary>
    /// Raises the import error. When the Change Log setup does not cover the playbook tables, the error also names every
    /// such table and the one-time setup, because Foundation's write guard reports only the first field it meets (#231).
    /// </summary>
    local procedure ThrowPlaybookImportError(ErrorText: Text)
    var
        ChangeLogSetup: Record "Change Log Setup";
        Coverage: Record "Change Log Setup (Table)";
        TableJSONExport: Codeunit "Table JSON Export ori";
        AllObj: Record AllObjWithCaption;
        TableNo: Integer;
        Uncovered: Text;
        LogActive: Boolean;
    begin
        if ChangeLogSetup.Get() then
            LogActive := ChangeLogSetup."Change Log Activated";
        foreach TableNo in TableJSONExport.GetPlaybookTables() do
            if not LogActive or not Coverage.Get(TableNo) or
               (Coverage."Log Insertion" = Coverage."Log Insertion"::" ") or (Coverage."Log Modification" = Coverage."Log Modification"::" ")
            then begin
                AllObj.SetLoadFields("Object Caption");
                if AllObj.Get(AllObj."Object Type"::Table, TableNo) then;
                if Uncovered <> '' then
                    Uncovered += ', ';
                Uncovered += AllObj."Object Caption";
                Clear(AllObj);
            end;
        if Uncovered = '' then
            Error(ErrorInfo.Create(ErrorText));
        Error(ErrorInfo.Create(StrSubstNo(RowStopHintErr, ErrorText, Uncovered)));
    end;

    local procedure AssertRowInPlaybook(RecRef: RecordRef)
    var
        RowPlaybookCode: Text;
    begin
        if ExpectedPlaybookCode = '' then
            exit;
        RowPlaybookCode := Format(RecRef.Field(1).Value());
        if RowPlaybookCode <> ExpectedPlaybookCode then
            Error(ErrorInfo.Create(StrSubstNo(PlaybookRowMismatchErr, RowPlaybookCode, ExpectedPlaybookCode)));
    end;

    local procedure AssertPlaybookHeader(Tables: JsonArray; PlaybookCode: Text)
    var
        Token: JsonToken;
        RowToken: JsonToken;
        FieldsToken: JsonToken;
        KeyToken: JsonToken;
        RowsToken: JsonToken;
        Index: Integer;
        RowIndex: Integer;
    begin
        for Index := 1 to Tables.Count() do begin
            Tables.Get(Index - 1, Token);
            if GetTableNo(Token.AsObject()) = Database::"Playbook ori" then
                if Token.AsObject().Get('rows', RowsToken) then
                    if RowsToken.IsArray() then
                        for RowIndex := 1 to RowsToken.AsArray().Count() do begin
                            RowsToken.AsArray().Get(RowIndex - 1, RowToken);
                            if RowToken.IsObject() then
                                if RowToken.AsObject().Get('primaryKey', KeyToken) then
                                    if KeyToken.IsObject() then
                                        if KeyToken.AsObject().Keys().Count() > 0 then
                                            if KeyToken.AsObject().Get(KeyToken.AsObject().Keys().Get(1), FieldsToken) then
                                                if FieldsToken.IsValue() then
                                                    if FieldsToken.AsValue().AsText() = PlaybookCode then
                                                        exit;
                        end;
        end;
        Error(ErrorInfo.Create(StrSubstNo(PlaybookHeaderMissingErr, PlaybookCode)));
    end;

    local procedure ReadPlaybookEnvelope(Envelope: JsonObject; var PlaybookCode: Text; var Tables: JsonArray)
    var
        TableJSONExport: Codeunit "Table JSON Export ori";
        TableNos: List of [Integer];
        Token: JsonToken;
        TableToken: JsonToken;
        FormatName: Text;
        Version: Integer;
        Index: Integer;
    begin
        if Envelope.Get('format', Token) then
            if Token.IsValue() then
                FormatName := Token.AsValue().AsText();
        if Envelope.Get('version', Token) then
            if Token.IsValue() then
                Version := Token.AsValue().AsInteger();
        if (FormatName <> TableJSONExport.GetPlaybookFormatName()) or (Version <> TableJSONExport.GetFormatVersion()) then
            Error(ErrorInfo.Create(StrSubstNo(PlaybookFormatErr, TableJSONExport.GetPlaybookFormatName(), TableJSONExport.GetFormatVersion())));
        if Envelope.Get('playbookCode', Token) then
            if Token.IsValue() then
                PlaybookCode := Token.AsValue().AsText();
        if not Envelope.Get('tables', Token) then
            Error(ErrorInfo.Create(PlaybookTablesMissingErr));
        if not Token.IsArray() then
            Error(ErrorInfo.Create(PlaybookTablesMissingErr));
        Tables := Token.AsArray();
        if PlaybookCode = '' then
            Error(ErrorInfo.Create(PlaybookCodeMissingErr));
        TableNos := TableJSONExport.GetPlaybookTables();
        for Index := 1 to Tables.Count() do begin
            Tables.Get(Index - 1, TableToken);
            if not TableToken.IsObject() then
                Error(ErrorInfo.Create(PlaybookTablesMissingErr));
            if not TableNos.Contains(GetTableNo(TableToken.AsObject())) then
                Error(ErrorInfo.Create(StrSubstNo(PlaybookTableRefusedErr, GetTableNo(TableToken.AsObject()))));
        end;
        AssertPlaybookHeader(Tables, PlaybookCode);
    end;

    local procedure GetTableNo(TableFile: JsonObject) TableNo: Integer
    var
        Token: JsonToken;
    begin
        if TableFile.Get('tableNo', Token) then
            if Token.IsValue() then
                TableNo := Token.AsValue().AsInteger();
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
