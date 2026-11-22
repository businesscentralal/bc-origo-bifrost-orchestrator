namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.IO;
using System.Reflection;
using System.Utilities;

/// <summary>
/// Copy method Internal of Copy Table Data (port of Tools for Power Users "Internal Copy Table").
/// Each source record is matched on the destination primary key. A new record gets the data template and the mapped
/// values; an existing record is updated only when a mapped value changed. Every write goes through Bifrost
/// Foundation's Data.Records.Set (JSON from Foundation's Serializer), so the change log write guard, field and
/// write-once restrictions and permissions apply and a refusal stops the copy with Foundation's own error. The
/// codeunit grants no table permissions of its own and never calls Insert or Modify on the destination.
/// </summary>
codeunit 10035624 "Internal Copy Table ori" implements "Copy Table Data Transfer ori"
{
    Access = Internal;

    var
        CopyTableEvents: Codeunit "Copy Table Events ori";
        LastInsertedCount: Integer;
        LastModifiedCount: Integer;
        LastUnchangedCount: Integer;
        RefusedErr: Label 'Bifrost refused to write %1 in table %2: %3', Comment = '%1 = record key, %2 = table caption, %3 = Foundation refusal, is-IS=Bifröst hafnaði því að skrifa %1 í töflu %2: %3';

    /// <summary>Raises BeforeUsingTableMapping.</summary>
    /// <param name="Progress">The progress dialog of the run.</param>
    procedure StartDataTransfer(var Progress: Codeunit "Copy Table Progress Dialog ori")
    begin
        CopyTableEvents.BeforeUsingTableMapping(Progress);
    end;

    /// <summary>Copies every filtered source record of the mapping and stamps Last Copy Time.</summary>
    /// <param name="TableMapping">The table mapping to copy.</param>
    /// <param name="Progress">The progress dialog of the run.</param>
    /// <param name="UpdateCopyCount">True to count every record in the progress dialog.</param>
    procedure TransferTableData(var TableMapping: Record "Copy Table Mapping ori"; var Progress: Codeunit "Copy Table Progress Dialog ori"; UpdateCopyCount: Boolean)
    var
        SourceRecRef: RecordRef;
    begin
        LastInsertedCount := 0;
        LastModifiedCount := 0;
        LastUnchangedCount := 0;
        TableMapping.TestField("Destination Table ID");
        if TableMapping.GetRecRefWithFilters(SourceRecRef) then
            repeat
                if UpdateCopyCount then
                    Progress.UpdateCopyCount();
                CopyEntry(TableMapping, SourceRecRef);
            until SourceRecRef.Next() = 0;

        TableMapping.Get(TableMapping.ID);
        TableMapping."Last Copy Time" := CurrentDateTime();
        TableMapping.Modify(true);
        OnAfterTransferTableData(TableMapping);
    end;

    /// <summary>Returns the counts of the last TransferTableData call in this codeunit instance.</summary>
    /// <param name="Inserted">Records inserted.</param>
    /// <param name="Modified">Records modified.</param>
    /// <param name="Unchanged">Existing records left unchanged.</param>
    internal procedure GetLastCounts(var Inserted: Integer; var Modified: Integer; var Unchanged: Integer)
    begin
        Inserted := LastInsertedCount;
        Modified := LastModifiedCount;
        Unchanged := LastUnchangedCount;
    end;

    local procedure CopyEntry(var TableMapping: Record "Copy Table Mapping ori"; SourceRecRef: RecordRef)
    var
        DestRecRef: RecordRef;
        ExistingRecRef: RecordRef;
        WriteFieldNos: List of [Integer];
        IsHandled: Boolean;
        RecordExists: Boolean;
    begin
        OnBeforeCopyEntry(TableMapping, SourceRecRef, IsHandled);
        if IsHandled then
            exit;

        // The destination record is built in a temporary buffer; only Data.Records.Set writes the real table.
        DestRecRef.Open(TableMapping."Destination Table ID", true);
        DestRecRef.Init();
        CopyFields(TableMapping.ID, SourceRecRef, DestRecRef, true, false, WriteFieldNos);
        RecordExists := FindExisting(DestRecRef, ExistingRecRef);

        if not RecordExists then begin
            DestRecRef.Init();
            Clear(WriteFieldNos);
            CopyFields(TableMapping.ID, SourceRecRef, DestRecRef, true, false, WriteFieldNos);
            ApplyConfigurationPackage(DestRecRef, TableMapping."Data Template Code", WriteFieldNos);
            CopyFields(TableMapping.ID, SourceRecRef, DestRecRef, false, false, WriteFieldNos);
            OnBeforeInsertNewEntry(TableMapping, SourceRecRef, DestRecRef, IsHandled);
            if not IsHandled then begin
                WriteThroughFoundation(DestRecRef, WriteFieldNos);
                LastInsertedCount += 1;
            end;
            OnAfterCopyEntry(true, DestRecRef, TableMapping, SourceRecRef);
        end else begin
            OnBeforeUpdateExistingEntry(TableMapping, SourceRecRef, ExistingRecRef, IsHandled);
            CopyExistingValues(ExistingRecRef, DestRecRef);
            Clear(WriteFieldNos);
            if not IsHandled then
                if CopyFields(TableMapping.ID, SourceRecRef, DestRecRef, false, true, WriteFieldNos) then begin
                    WriteThroughFoundation(DestRecRef, WriteFieldNos);
                    LastModifiedCount += 1;
                end else
                    LastUnchangedCount += 1;
            OnAfterCopyEntry(false, DestRecRef, TableMapping, SourceRecRef);
        end;
    end;

    local procedure FindExisting(DestRecRef: RecordRef; var ExistingRecRef: RecordRef): Boolean
    var
        PrimaryKey: KeyRef;
        Index: Integer;
        FieldNo: Integer;
    begin
        ExistingRecRef.Open(DestRecRef.Number());
        PrimaryKey := DestRecRef.KeyIndex(1);
        for Index := 1 to PrimaryKey.FieldCount() do begin
            FieldNo := PrimaryKey.FieldIndex(Index).Number();
            ExistingRecRef.Field(FieldNo).SetRange(DestRecRef.Field(FieldNo).Value());
        end;
        exit(ExistingRecRef.FindFirst());
    end;

    local procedure CopyExistingValues(ExistingRecRef: RecordRef; var DestRecRef: RecordRef)
    var
        TableField: Record Field;
    begin
        TableField.SetLoadFields(TableNo, "No.");
        TableField.SetRange(TableNo, ExistingRecRef.Number());
        TableField.SetRange(Class, TableField.Class::Normal);
        TableField.SetRange(Enabled, true);
        TableField.SetFilter(ObsoleteState, '<>%1', TableField.ObsoleteState::Removed);
        TableField.SetFilter(Type, '<>%1&<>%2&<>%3', TableField.Type::BLOB, TableField.Type::Media, TableField.Type::MediaSet);
        if TableField.FindSet() then
            repeat
                DestRecRef.Field(TableField."No.").Value(ExistingRecRef.Field(TableField."No.").Value());
            until TableField.Next() = 0;
    end;

    local procedure ApplyConfigurationPackage(var LocalRecRef: RecordRef; DataTemplateCode: Code[10]; var WriteFieldNos: List of [Integer])
    var
        ConfigTemplateLine: Record "Config. Template Line";
        ConfigValidateMgt: Codeunit "Config. Validate Management";
        LocalFieldRef: FieldRef;
    begin
        if DataTemplateCode = '' then
            exit;
        ConfigTemplateLine.SetLoadFields("Field ID", "Default Value", "Language ID");
        ConfigTemplateLine.SetRange("Data Template Code", DataTemplateCode);
        ConfigTemplateLine.SetRange(Type, ConfigTemplateLine.Type::Field);
        ConfigTemplateLine.SetFilter("Field ID", '<>%1', 0);
        if ConfigTemplateLine.FindSet() then
            repeat
                LocalFieldRef := LocalRecRef.Field(ConfigTemplateLine."Field ID");
                // No validation here: Data.Records.Set validates every written field under the guards.
                ConfigValidateMgt.ValidateFieldValue(LocalRecRef, LocalFieldRef, ConfigTemplateLine."Default Value", false, ConfigTemplateLine."Language ID");
                AddFieldNo(WriteFieldNos, ConfigTemplateLine."Field ID");
            until ConfigTemplateLine.Next() = 0;
        OnAfterApplyConfigurationPackage(LocalRecRef, DataTemplateCode);
    end;

    local procedure ApplyTransformationRule(TransformationRuleCode: Code[20]; var FieldValue: Text)
    var
        TransformationRule: Record "Transformation Rule";
        IsHandled: Boolean;
    begin
        OnBeforeApplyTransformationRule(TransformationRuleCode, FieldValue, IsHandled);
        if IsHandled then
            exit;

        TransformationRule.Get(TransformationRuleCode);
        FieldValue := TransformationRule.TransformText(FieldValue);
        OnAfterApplyTransformationRule(TransformationRule, FieldValue);
    end;

    local procedure CopyFields(TableMappingID: Guid; var SourceRecRef: RecordRef; var DestRecRef: RecordRef; PrimaryKeyFields: Boolean; ExistingRecord: Boolean; var WriteFieldNos: List of [Integer]) HasChangedValue: Boolean
    var
        FieldMapping: Record "Copy Field Mapping ori";
        DestFldRef: FieldRef;
        IsHandled: Boolean;
        ValueChanged: Boolean;
    begin
        OnBeforeCopyFields(TableMappingID, SourceRecRef, DestRecRef, IsHandled);
        if IsHandled then
            exit;

        FieldMapping.SetRange("Copy Table Mapping ID", TableMappingID);
        FieldMapping.SetFilter("Destination Field ID", '<>%1', 0);
        FieldMapping.SetRange("Is Part Of Primary Key", PrimaryKeyFields);
        if not FieldMapping.FindSet() then
            exit;
        repeat
            DestFldRef := DestRecRef.Field(FieldMapping."Destination Field ID");
            ValueChanged := CopyValue(FieldMapping, SourceRecRef, DestFldRef);
            if (not ExistingRecord) or ValueChanged then
                AddFieldNo(WriteFieldNos, FieldMapping."Destination Field ID");
            HasChangedValue := HasChangedValue or ValueChanged;
        until FieldMapping.Next() = 0;
        OnAfterCopyFields(TableMappingID, SourceRecRef, DestRecRef, PrimaryKeyFields, ExistingRecord, HasChangedValue);
    end;

    local procedure CopyValue(FieldMapping: Record "Copy Field Mapping ori"; var SourceRecRef: RecordRef; var DestFldRef: FieldRef) HasChangedValue: Boolean
    var
        SourceFldRef: FieldRef;
        OldValueText: Text;
        IsHandled: Boolean;
        SrcFldValueAsText: Text;
    begin
        OnBeforeCopyValue(FieldMapping, SourceRecRef, DestFldRef, IsHandled);
        if IsHandled then
            exit;

        OldValueText := Format(DestFldRef.Value(), 0, 9);
        SourceFldRef := SourceRecRef.Field(FieldMapping."Source Field ID");
        if FieldMapping."Transformation Rule" <> '' then begin
            SrcFldValueAsText := Format(SourceFldRef.Value(), 0, 9);
            ApplyTransformationRule(FieldMapping."Transformation Rule", SrcFldValueAsText);
            EvaluateFieldValue(SrcFldValueAsText, DestFldRef);
        end else begin
            if SourceFldRef.Type() = FieldType::Blob then
                SourceFldRef.CalcField();
            OnBeforeSetDestinationFieldValue(SourceFldRef, DestFldRef, IsHandled);
            if not IsHandled then
                DestFldRef.Value(SourceFldRef.Value());
        end;
        HasChangedValue := Format(DestFldRef.Value(), 0, 9) <> OldValueText;
        OnAfterCopyValue(FieldMapping, SourceRecRef, DestFldRef);
    end;

    local procedure EvaluateFieldValue(Value: Text; var DestFldRef: FieldRef) Success: Boolean
    var
        ConfigValidateMgt: Codeunit "Config. Validate Management";
        IsHandled: Boolean;
    begin
        OnBeforeEvaluateFieldValue(Value, DestFldRef, Success, IsHandled);
        if IsHandled then
            exit;

        Success := ConfigValidateMgt.EvaluateTextToFieldRef(Value, DestFldRef, false);
        OnAfterEvaluateFieldValue(Value, DestFldRef, Success);
    end;

    local procedure AddFieldNo(var FieldNos: List of [Integer]; FieldNo: Integer)
    begin
        if not FieldNos.Contains(FieldNo) then
            FieldNos.Add(FieldNo);
    end;

    /// <summary>
    /// Writes the buffer through Foundation's Data.Records.Set: the primary key plus the listed fields. A refusal
    /// (write guard, restricted or write-once field, permission, validation) stops the copy with Foundation's text.
    /// </summary>
    local procedure WriteThroughFoundation(var DestRecRef: RecordRef; WriteFieldNos: List of [Integer])
    var
        Serializer: Codeunit "Serializer ori";
        MsgExecutor: Codeunit "Msg Executor ori";
        Entry: JsonObject;
        Request: JsonObject;
        Rows: JsonArray;
        Response: JsonObject;
        RequestText: Text;
        ResponseText: Text;
    begin
        Entry := Serializer.SerializeToJson(DestRecRef, WriteFieldNos);
        if Entry.Contains('id') then
            Entry.Remove('id');
        Rows.Add(Entry);
        Request.Add('tableName', DestRecRef.Name());
        Request.Add('data', Rows);
        Request.WriteTo(RequestText);

        MsgExecutor.SetParameters("Message Type ori"::"Data.Records.Set", '', RequestText);
        MsgExecutor.Run();
        ResponseText := MsgExecutor.GetResponseText();
        if Response.ReadFrom(ResponseText) then
            if GetText(Response, 'status') = 'Success' then
                exit;
        Error(RefusedErr, DestRecRef.GetPosition(false), DestRecRef.Caption(), RefusalText(Response, ResponseText));
    end;

    local procedure RefusalText(Response: JsonObject; ResponseText: Text): Text
    var
        Token: JsonToken;
        ErrorText: Text;
    begin
        if Response.Get('error', Token) then
            if Token.IsObject() then begin
                ErrorText := GetText(Token.AsObject(), 'code');
                if GetText(Token.AsObject(), 'message') <> '' then
                    ErrorText := ErrorText + ': ' + GetText(Token.AsObject(), 'message');
            end;
        if Response.Get('errors', Token) then
            if Token.IsArray() then
                if Token.AsArray().Count() > 0 then
                    if Token.AsArray().Get(0, Token) then
                        if Token.IsObject() then begin
                            ErrorText := GetText(Token.AsObject(), 'code');
                            if GetText(Token.AsObject(), 'message') <> '' then
                                ErrorText := ErrorText + ': ' + GetText(Token.AsObject(), 'message');
                        end;
        if ErrorText = '' then
            ErrorText := CopyStr(ResponseText, 1, 1024);
        exit(ErrorText);
    end;

    local procedure GetText(JObject: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        if not JObject.Get(PropertyName, Token) then
            exit('');
        if not Token.IsValue() then
            exit('');
        if Token.AsValue().IsNull() then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyConfigurationPackage(var LocalRecRef: RecordRef; DataTemplateCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyTransformationRule(TransformationRule: Record "Transformation Rule"; var FieldValue: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyEntry(EntryCreated: Boolean; DestRecRef: RecordRef; var TableMapping: Record "Copy Table Mapping ori"; SourceRecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFields(TableMappingID: Guid; var SourceRecRef: RecordRef; var DestRecRef: RecordRef; PrimaryKeyFields: Boolean; ExistingRecord: Boolean; var HasChangedValue: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyValue(FieldMapping: Record "Copy Field Mapping ori"; var SourceRecRef: RecordRef; var DestFldRef: FieldRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterEvaluateFieldValue(Value: Text; var DestFldRef: FieldRef; var Success: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyTransformationRule(TransformationRuleCode: Code[20]; var FieldValue: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyEntry(var TableMapping: Record "Copy Table Mapping ori"; SourceRecRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFields(TableMappingID: Guid; var SourceRecRef: RecordRef; var DestRecRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyValue(FieldMapping: Record "Copy Field Mapping ori"; var SourceRecRef: RecordRef; var DestFldRef: FieldRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEvaluateFieldValue(Value: Text; var DestFldRef: FieldRef; var Success: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertNewEntry(var TableMapping: Record "Copy Table Mapping ori"; SourceRecRef: RecordRef; var DestRecRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetDestinationFieldValue(SourceFldRef: FieldRef; var DestFldRef: FieldRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateExistingEntry(TableMapping: Record "Copy Table Mapping ori"; var SourceRecRef: RecordRef; var ExistingRecRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferTableData(var TableMapping: Record "Copy Table Mapping ori")
    begin
    end;
}
