namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.Reflection;
using System.Utilities;

/// <summary>Browses table data and uses current Foundation metadata and serialization for guarded edits.</summary>
codeunit 10035575 "Table Data Mgt ori"
{
    Access = Internal;

    var
        InvalidPageErr: Label 'The page number must be positive and the page size must be between 1 and 500.', Comment = 'is-IS=Síðunúmer verður að vera jákvætt og síðustærð verður að vera á bilinu 1 til 500.';
        TableReadErr: Label 'Table %1 cannot be read.', Comment = '%1 = table number, is-IS=Ekki er hægt að lesa töflu %1.';
        FieldReadOnlyErr: Label 'Field %1 is read-only for this record and user.', Comment = '%1 = field number, is-IS=Reitur %1 er skrifvarinn fyrir þessa færslu og notanda.';
        ImportConfirmQst: Label 'Dry run validated %1 inserted and %2 modified rows, with %3 failures. Import the valid rows?', Comment = '%1 = inserts, %2 = modifications, %3 = failures, is-IS=Prófun staðfesti %1 nýjar færslur og %2 breyttar færslur, með %3 villum. Flytja inn gildu færslurnar?';
        ImportResultMsg: Label 'Inserted: %1. Modified: %2. Failed: %3.', Comment = '%1 = inserts, %2 = modifications, %3 = failures, is-IS=Nýjar færslur: %1. Breyttar: %2. Villur: %3.';
        MissingRecordErr: Label 'The selected record no longer exists.', Comment = 'is-IS=Valin færsla er ekki lengur til.';
        ImportTitleLbl: Label 'Import Table Data', Comment = 'is-IS=Flytja inn töflugögn';
        JsonFilterLbl: Label 'JSON files (*.json)|*.json', Comment = 'is-IS=JSON-skrár (*.json)|*.json';

    /// <summary>Loads a bounded page after checking table, filter and field visibility.</summary>
    procedure LoadPage(TableNo: Integer; TableView: Text; PageNo: Integer; PageSize: Integer; var TempRows: Record "Table Data Row ori" temporary): Boolean
    var
        TempArgument: Record "Message Argument ori" temporary;
        Serializer: Codeunit "Serializer ori";
        SourceRef: RecordRef;
        Request: JsonObject;
        Row: JsonObject;
        TempFields: List of [Integer];
        Skip: Integer;
        Index: Integer;
        HasRow: Boolean;
    begin
        if (PageNo < 1) or (PageSize < 1) or (PageSize > 500) then
            Error(InvalidPageErr);
        CheckRead(TableNo);
        TempRows.Reset();
        TempRows.DeleteAll();
        SourceRef.Open(TableNo);
        SourceRef.ReadIsolation := IsolationLevel::ReadCommitted;
        if TableView <> '' then
            SourceRef.SetView(TableView);
        Request.Add('tableView', SourceRef.GetView(true));
        if not TempArgument.ApplyTableView(Request, SourceRef) then
            Error(TempArgument.GetResponseText());
        Skip := (PageNo - 1) * PageSize;
        Index := 0;
        HasRow := SourceRef.FindSet();
        if HasRow and (Skip > 0) then
            HasRow := SourceRef.Next(Skip) = Skip;
        while HasRow and (Index < PageSize) do begin
            Index += 1;
            Row := Serializer.SerializeToJson(SourceRef, TempFields);
            TempRows.Init();
            TempRows."Row No." := Index;
            TempRows."Primary Key" := CopyStr(SummaryOf(Row, 'primaryKey', 100), 1, MaxStrLen(TempRows."Primary Key"));
            TempRows.Summary := CopyStr(SummaryOf(Row, 'fields', 8), 1, MaxStrLen(TempRows.Summary));
            TempRows.SetRow(Row);
            TempRows.Insert();
            HasRow := SourceRef.Next() <> 0;
        end;
        SourceRef.Close();
        exit(HasRow);
    end;

    /// <summary>Loads visible fields and current metadata; primary keys and populated write-once fields are read-only.</summary>
    procedure LoadRecord(TableNo: Integer; Row: JsonObject; var TempFields: Record "Table Data Field ori" temporary)
    var
        TempArgument: Record "Message Argument ori" temporary;
        Playbook: Record "Playbook ori";
        Serializer: Codeunit "Serializer ori";
        SourceRef: RecordRef;
        Metadata: JsonArray;
        MetaToken: JsonToken;
        Meta: JsonObject;
        Value: JsonToken;
        Values: JsonObject;
        KeyValues: JsonObject;
        FreshRow: JsonObject;
        FieldNos: List of [Integer];
        Name: Text;
        IsKey: Boolean;
        TableWritable: Boolean;
    begin
        CheckRead(TableNo);
        Metadata := ReadFieldMetadata(TableNo);
        OpenRow(TableNo, Row, SourceRef);
        FreshRow := Serializer.SerializeToJson(SourceRef, FieldNos);
        FreshRow.Get('fields', Value);
        Values := Value.AsObject();
        FreshRow.Get('primaryKey', Value);
        KeyValues := Value.AsObject();
        TempFields.Reset();
        TempFields.DeleteAll();
        TableWritable := not TempArgument.IsTableWriteRestrictedForDataRecords(TableNo, false) and Playbook.WritePermission();
        foreach MetaToken in Metadata do begin
            Meta := MetaToken.AsObject();
            Name := TextValue(Meta, 'jsonName');
            IsKey := BoolValue(Meta, 'isPartOfPrimaryKey');
            if BoolValue(Meta, 'readRestricted') then
                continue;
            if IsKey then begin
                if not KeyValues.Get(Name, Value) then
                    continue;
            end else
                if not Values.Get(Name, Value) then
                    continue;
            if not Value.IsValue() then
                continue;
            if Value.AsValue().IsNull() then
                continue;
            TempFields.Init();
            TempFields."Field No." := IntValue(Meta, 'id');
            TempFields."Field Name" := CopyStr(TextValue(Meta, 'caption'), 1, MaxStrLen(TempFields."Field Name"));
            TempFields."JSON Name" := CopyStr(Name, 1, MaxStrLen(TempFields."JSON Name"));
            TempFields."Type" := CopyStr(TextValue(Meta, 'type'), 1, MaxStrLen(TempFields."Type"));
            TempFields.Value := CopyStr(Value.AsValue().AsText(), 1, MaxStrLen(TempFields.Value));
            TempFields."Can Edit" := TableWritable and not IsKey and not BoolValue(Meta, 'writeRestricted') and
                (TextValue(Meta, 'class') = 'Normal') and (StrLen(Value.AsValue().AsText()) <= MaxStrLen(TempFields.Value));
            if BoolValue(Meta, 'writeOnce') then
                TempFields."Can Edit" := TempFields."Can Edit" and IsBlankField(SourceRef, TempFields."Field No.");
            TempFields.Insert();
        end;
        SourceRef.Close();
    end;

    /// <summary>Re-reads permissions and the current row before applying one field through the import transaction.</summary>
    procedure SaveField(TableNo: Integer; Row: JsonObject; FieldNo: Integer; NewValue: Text)
    var
        TempFields: Record "Table Data Field ori" temporary;
        Importer: Codeunit "Table JSON Import ori";
        Serializer: Codeunit "Serializer ori";
        SourceRef: RecordRef;
        FreshRow: JsonObject;
        NewFields: JsonObject;
        FieldNos: List of [Integer];
    begin
        LoadRecord(TableNo, Row, TempFields);
        if not TempFields.Get(FieldNo) then
            Error(FieldReadOnlyErr, FieldNo);
        if not TempFields."Can Edit" then
            Error(FieldReadOnlyErr, FieldNo);
        OpenRow(TableNo, Row, SourceRef);
        FreshRow := Serializer.SerializeToJson(SourceRef, FieldNos);
        SourceRef.Close();
        NewFields.Add(TempFields."JSON Name", NewValue);
        Importer.ModifyRecord(TableNo, FreshRow, NewFields);
    end;

    /// <summary>Downloads a filtered table as a versioned UTF-8 JSON file.</summary>
    procedure DownloadTable(TableNo: Integer; TableView: Text)
    var
        Exporter: Codeunit "Table JSON Export ori";
        TempBlob: Codeunit "Temp Blob";
        Envelope: JsonObject;
        TempFields: List of [Integer];
        Output: OutStream;
        Input: InStream;
        FileName: Text;
    begin
        Envelope := Exporter.ExportTable(TableNo, TableView, TempFields);
        TempBlob.CreateOutStream(Output, TextEncoding::UTF8);
        Envelope.WriteTo(Output);
        TempBlob.CreateInStream(Input, TextEncoding::UTF8);
        FileName := 'TableData.json';
        DownloadFromStream(Input, '', '', '', FileName);
    end;

    /// <summary>Validates an uploaded file with rollback before asking whether to import.</summary>
    procedure UploadTable()
    var
        Importer: Codeunit "Table JSON Import ori";
        ConfirmMgt: Codeunit "Confirm Management";
        Input: InStream;
        FileName: Text;
        Envelope: JsonObject;
        Result: JsonObject;
    begin
        if not UploadIntoStream(ImportTitleLbl, '', JsonFilterLbl, FileName, Input) then
            exit;
        Envelope.ReadFrom(Input);
        Result := Importer.ImportTable(Envelope, true);
        if not ConfirmMgt.GetResponseOrDefault(StrSubstNo(ImportConfirmQst, IntValue(Result, 'inserted'), IntValue(Result, 'modified'), IntValue(Result, 'failed')), false) then
            exit;
        Result := Importer.ImportTable(Envelope, false);
        Message(ImportResultMsg, IntValue(Result, 'inserted'), IntValue(Result, 'modified'), IntValue(Result, 'failed'));
    end;

    local procedure CheckRead(TableNo: Integer)
    var
        TempArgument: Record "Message Argument ori" temporary;
    begin
        if TempArgument.IsTableReadRestrictedForDataRecords(TableNo) then
            Error(TempArgument.GetRestrictedTableErrorText(TableNo, StrSubstNo(TableReadErr, TableNo), false));
    end;

    local procedure OpenRow(TableNo: Integer; Row: JsonObject; var SourceRef: RecordRef)
    var
        Value: JsonToken;
        Id: Guid;
    begin
        CheckRead(TableNo);
        Row.Get('id', Value);
        Evaluate(Id, Value.AsValue().AsText());
        SourceRef.Open(TableNo);
        SourceRef.ReadIsolation := IsolationLevel::ReadCommitted;
        if not SourceRef.GetBySystemId(Id) then
            Error(MissingRecordErr);
    end;

    local procedure ReadFieldMetadata(TableNo: Integer): JsonArray
    var
        Executor: Codeunit "Msg Executor ori";
        Response: JsonObject;
        Value: JsonToken;
        ResponseText: Text;
    begin
        ResponseText := Executor.ReadFieldMetadata(TableNo);
        Response.ReadFrom(ResponseText);
        if TextValue(Response, 'status') <> 'Success' then
            Error(ResponseText);
        Response.Get('result', Value);
        exit(Value.AsArray());
    end;

    local procedure IsBlankField(SourceRef: RecordRef; FieldNo: Integer): Boolean
    var
        BlankRef: RecordRef;
        Result: Boolean;
    begin
        BlankRef.Open(SourceRef.Number(), true);
        BlankRef.Init();
        Result := SourceRef.Field(FieldNo).Value() = BlankRef.Field(FieldNo).Value();
        BlankRef.Close();
        exit(Result);
    end;

    local procedure SummaryOf(Row: JsonObject; Property: Text; Limit: Integer): Text
    var
        Value: JsonToken;
        FieldValue: JsonToken;
        TempFields: JsonObject;
        Name: Text;
        Result: Text;
        Count: Integer;
    begin
        Row.Get(Property, Value);
        TempFields := Value.AsObject();
        Count := 0;
        foreach Name in TempFields.Keys() do begin
            if Count >= Limit then
                break;
            TempFields.Get(Name, FieldValue);
            if Result <> '' then
                Result += '; ';
            if FieldValue.IsValue() then
                if not FieldValue.AsValue().IsNull() then
                    Result += Name + '=' + FieldValue.AsValue().AsText();
            Count += 1;
        end;
        exit(Result);
    end;

    local procedure TextValue(Value: JsonObject; Name: Text): Text
    var
        Token: JsonToken;
    begin
        Value.Get(Name, Token);
        exit(Token.AsValue().AsText());
    end;

    local procedure IntValue(Value: JsonObject; Name: Text): Integer
    var
        Token: JsonToken;
    begin
        Value.Get(Name, Token);
        exit(Token.AsValue().AsInteger());
    end;

    local procedure BoolValue(Value: JsonObject; Name: Text): Boolean
    var
        Token: JsonToken;
    begin
        Value.Get(Name, Token);
        exit(Token.AsValue().AsBoolean());
    end;
}
