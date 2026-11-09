namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

/// <summary>Imports a table-data file with isolated row transactions and rollback-only dry runs.</summary>
codeunit 10035563 "Table JSON Import ori"
{
    Access = Internal;
    SingleInstance = true;

    trigger OnRun()
    begin
        ApplyRow();
        RowValidated := true;
        if RowDryRun then
            Error(DryRunRollbackTok);
    end;

    var
        RowObject: JsonObject;
        RowTableNo: Integer;
        RowDryRun: Boolean;
        RowValidated: Boolean;
        RowInserted: Boolean;
        RowMustExist: Boolean;
        RowSystemId: Guid;
        DryRunRollbackTok: Label 'BIFROST_TABLE_IMPORT_DRY_RUN_ROLLBACK', Locked = true;
        InvalidEnvelopeErr: Label 'The file must contain format bifrost-table-data, version 1, a table number and a rows array.', Comment = 'is-IS=Skráin verður að innihalda sniðið bifrost-table-data, útgáfu 1, töflunúmer og fylkið rows.';
        InvalidRowErr: Label 'Each row must contain a complete primaryKey object and a fields object. Key fields cannot also appear in fields.', Comment = 'is-IS=Hver færsla verður að innihalda fullbúinn primaryKey-hlut og fields-hlut. Lykilreitir mega ekki einnig vera í fields.';
        TableWriteErr: Label 'Table %1 cannot be written.', Comment = '%1 = table number, is-IS=Ekki er hægt að skrifa í töflu %1.';

    /// <summary>Imports rows independently, or validates them with every row transaction rolled back.</summary>
    /// <param name="Envelope">The versioned table-data file.</param>
    /// <param name="DryRun">True to roll back every row including validation-trigger writes.</param>
    /// <returns>Inserted, modified and failed counts and per-row errors.</returns>
    procedure ImportTable(Envelope: JsonObject; DryRun: Boolean): JsonObject
    begin
        exit(ImportTable(Envelope, DryRun, false));
    end;

    /// <summary>Imports each row with Foundation guards and validation; successful rows commit independently.</summary>
    /// <param name="Envelope">The versioned table-data file.</param>
    /// <param name="DryRun">True to roll back all row changes.</param>
    /// <param name="StopOnError">True to stop after the first refused or invalid row.</param>
    /// <returns>Counts of validated or persisted rows, plus per-row errors.</returns>
    procedure ImportTable(Envelope: JsonObject; DryRun: Boolean; StopOnError: Boolean) Result: JsonObject
    var
        TempArgument: Record "Message Argument ori" temporary;
        RowRunner: Codeunit "Table JSON Import ori";
        Rows: JsonArray;
        Errors: JsonArray;
        RowToken: JsonToken;
        ErrorRow: JsonObject;
        TableNo: Integer;
        RowNo: Integer;
        Inserted: Integer;
        Modified: Integer;
        Failed: Integer;
        Succeeded: Boolean;
    begin
        TableNo := ValidateEnvelope(Envelope, Rows);
        if TempArgument.IsTableWriteRestrictedForDataRecords(TableNo, false) then
            Error(TempArgument.GetRestrictedTableErrorText(TableNo, StrSubstNo(TableWriteErr, TableNo), true));
        foreach RowToken in Rows do begin
            RowNo += 1;
            RowMustExist := false;
            RowTableNo := TableNo;
            RowDryRun := DryRun;
            RowValidated := false;
            RowInserted := false;
            Clear(RowObject);
            ClearLastError();
            Succeeded := false;
            if RowToken.IsObject() then begin
                RowObject := RowToken.AsObject();
                Succeeded := RowRunner.Run();
                if DryRun then
                    Succeeded := RowValidated and (GetLastErrorText() = DryRunRollbackTok);
            end;
            if Succeeded then begin
                if RowInserted then
                    Inserted += 1
                else
                    Modified += 1;
            end else begin
                Failed += 1;
                Clear(ErrorRow);
                ErrorRow.Add('row', RowNo);
                if GetLastErrorText() = '' then
                    ErrorRow.Add('error', InvalidRowErr)
                else
                    ErrorRow.Add('error', GetLastErrorText());
                Errors.Add(ErrorRow);
                if StopOnError then
                    break;
            end;
        end;
        Clear(RowObject);
        Result.Add('dryRun', DryRun);
        Result.Add('inserted', Inserted);
        Result.Add('modified', Modified);
        Result.Add('failed', Failed);
        Result.Add('errors', Errors);
    end;

    /// <summary>Modifies one existing SystemId, never recreating a row deleted since the editor opened it.</summary>
    /// <param name="TableNo">The selected table.</param>
    /// <param name="Row">A fresh serializer envelope identifying the row.</param>
    /// <param name="Fields">The one-field edit object.</param>
    procedure ModifyRecord(TableNo: Integer; Row: JsonObject; Fields: JsonObject)
    var
        RowRunner: Codeunit "Table JSON Import ori";
        Value: JsonToken;
    begin
        Row.Get('id', Value);
        Evaluate(RowSystemId, Value.AsValue().AsText());
        RowMustExist := true;
        RowTableNo := TableNo;
        RowDryRun := false;
        RowValidated := false;
        RowInserted := false;
        RowObject := Row.Clone().AsObject();
        RowObject.Replace('fields', Fields);
        if not RowRunner.Run() then
            Error(GetLastErrorText());
        Clear(RowObject);
    end;

    local procedure ValidateEnvelope(Envelope: JsonObject; var Rows: JsonArray): Integer
    var
        Value: JsonToken;
    begin
        if not Envelope.Get('format', Value) then
            Error(InvalidEnvelopeErr);
        if not Value.IsValue() then
            Error(InvalidEnvelopeErr);
        if Value.AsValue().AsText() <> 'bifrost-table-data' then
            Error(InvalidEnvelopeErr);
        if not Envelope.Get('version', Value) then
            Error(InvalidEnvelopeErr);
        if not Value.IsValue() then
            Error(InvalidEnvelopeErr);
        if Value.AsValue().AsInteger() <> 1 then
            Error(InvalidEnvelopeErr);
        if not Envelope.Get('rows', Value) then
            Error(InvalidEnvelopeErr);
        if not Value.IsArray() then
            Error(InvalidEnvelopeErr);
        Rows := Value.AsArray();
        if not Envelope.Get('tableNo', Value) then
            Error(InvalidEnvelopeErr);
        if not Value.IsValue() then
            Error(InvalidEnvelopeErr);
        exit(Value.AsValue().AsInteger());
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure ApplyRow()
    var
        TempArgument: Record "Message Argument ori" temporary;
        Serializer: Codeunit "Serializer ori";
        RecordKey: RecordId;
        KeyRef: RecordRef;
        TargetRef: RecordRef;
        PrimaryKey: JsonObject;
        Fields: JsonObject;
        Shape: JsonObject;
        KeyShape: JsonToken;
        ActualKey: JsonToken;
        Value: JsonToken;
        FieldNos: List of [Integer];
        KeyName: Text;
    begin
        if not RowObject.Get('primaryKey', Value) then
            Error(InvalidRowErr);
        if not Value.IsObject() then
            Error(InvalidRowErr);
        PrimaryKey := Value.AsObject();
        if not RowObject.Get('fields', Value) then
            Error(InvalidRowErr);
        if not Value.IsObject() then
            Error(InvalidRowErr);
        Fields := Value.AsObject();
        if TempArgument.IsTableWriteRestrictedForDataRecords(RowTableNo, false) then
            Error(TempArgument.GetRestrictedTableErrorText(RowTableNo, StrSubstNo(TableWriteErr, RowTableNo), true));
        KeyRef.Open(RowTableNo, true);
        KeyRef.Init();
        Shape := Serializer.SerializeToJson(KeyRef, FieldNos);
        Shape.Get('primaryKey', KeyShape);
        if KeyShape.AsObject().Keys().Count() <> KeyRef.KeyIndex(1).FieldCount() then
            Error(InvalidRowErr);
        if (PrimaryKey.Keys().Count() = 0) or (PrimaryKey.Keys().Count() <> KeyShape.AsObject().Keys().Count()) then
            Error(InvalidRowErr);
        foreach KeyName in KeyShape.AsObject().Keys() do
            if not PrimaryKey.Contains(KeyName) or Fields.Contains(KeyName) then
                Error(InvalidRowErr);
        KeyRef := Serializer.DeserializeFromJson(KeyRef, PrimaryKey);
        Shape := Serializer.SerializeToJson(KeyRef, FieldNos);
        Shape.Get('primaryKey', KeyShape);
        foreach KeyName in PrimaryKey.Keys() do begin
            PrimaryKey.Get(KeyName, Value);
            KeyShape.AsObject().Get(KeyName, ActualKey);
            if Value.AsValue().AsText() <> ActualKey.AsValue().AsText() then
                Error(InvalidRowErr);
        end;
        RecordKey := KeyRef.RecordId();
        TargetRef.Open(RowTableNo);
        TargetRef.ReadIsolation := IsolationLevel::UpdLock;
        if RowMustExist then begin
            if not TargetRef.GetBySystemId(RowSystemId) then
                Error(InvalidRowErr);
            RowInserted := false;
        end else
            RowInserted := not TargetRef.Get(RecordKey);
        if RowInserted then begin
            TargetRef.Init();
            TargetRef := Serializer.DeserializeFromJson(TargetRef, PrimaryKey);
            if TempArgument.IsTableInsertRestrictedForDataRecords(RowTableNo, TargetRef, false, false) then
                Error(TempArgument.GetRestrictedTableErrorText(RowTableNo, StrSubstNo(TableWriteErr, RowTableNo), true));
        end;
        TargetRef := Serializer.DeserializeFromJson(TargetRef, Fields);
        if RowInserted then
            TargetRef.Insert(true)
        else
            TargetRef.Modify(true);
        TargetRef.Close();
        KeyRef.Close();
    end;
}
