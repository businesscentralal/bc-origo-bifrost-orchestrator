/// <summary>
/// The lookups Orchestrator.Playbook.Verify needs from outside this app, without depending on the apps that own
/// the data: whether a record exists (read through the lightweight dispatch of Foundation, so a language model
/// role can be checked without a dependency on Bifrost Bragi) and the field names of a table.
/// A lookup that cannot be answered, for example because the caller may not read the table, answers "not
/// determinable" and the check stays silent.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.Reflection;

codeunit 10035619 "Playbook Verify Lookup ori"
{
    Access = Internal;
    Permissions = tabledata AllObjWithCaption = R,
                  tabledata Field = R;

    /// <summary>
    /// Tells whether a language model with the given role code exists in this company. The language models belong
    /// to Bifrost Bragi, which this app does not depend on, so the table is read as <c>Bifrost Language Model ori</c>
    /// through Data.Records.Get. An integration event lets a caller answer before the read.
    /// </summary>
    /// <param name="RoleCode">The roleCode of the step template.</param>
    /// <param name="Exists">Receives true when a language model has that code.</param>
    /// <returns>True when the question could be answered; false when it is not determinable.</returns>
    internal procedure TryGetRoleExists(RoleCode: Text; var Exists: Boolean): Boolean
    var
        Handled: Boolean;
    begin
        OnBeforeCheckLanguageModelRole(RoleCode, Handled, Exists);
        if Handled then
            exit(true);
        // A role code is a Code[20]; a longer one cannot exist and is refused by the type itself.
        if StrLen(RoleCode) > 20 then begin
            Exists := false;
            exit(true);
        end;
        exit(TryLookupRecord(LanguageModelTableTok, CodeFieldTok, RoleCode, Exists));
    end;

    /// <summary>
    /// Tells whether a record with a value in one field exists, by reading it through Data.Records.Get.
    /// </summary>
    /// <param name="TableName">The AL name of the table.</param>
    /// <param name="FieldName">The English name of the field to filter on.</param>
    /// <param name="FieldValue">The value to look for. A value with filter characters is not determinable.</param>
    /// <param name="Found">Receives true when a record has that value.</param>
    /// <returns>True when the read was answered with Success; false when it is not determinable.</returns>
    internal procedure TryLookupRecord(TableName: Text; FieldName: Text; FieldValue: Text; var Found: Boolean): Boolean
    var
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        Token: JsonToken;
        RequestText: Text;
        ResponseText: Text;
    begin
        Found := false;
        if not IsPlainFilterValue(FieldValue) then
            exit(false);

        RequestJson.Add('tableName', TableName);
        RequestJson.Add('tableView', StrSubstNo(TableViewTok, FieldName, FieldValue));
        RequestJson.Add('take', 1);
        RequestJson.WriteTo(RequestText);

        if not TryRead(RequestText, ResponseText) then
            exit(false);
        if not ResponseJson.ReadFrom(ResponseText) then
            exit(false);
        if not ResponseJson.Get('status', Token) then
            exit(false);
        if Token.AsValue().AsText() <> 'Success' then
            exit(false);
        if not ResponseJson.Get('noOfRecords', Token) then
            exit(false);
        Found := Token.AsValue().AsInteger() > 0;
        exit(true);
    end;

    [TryFunction]
    local procedure TryRead(RequestText: Text; var ResponseText: Text)
    var
        Dispatcher: Codeunit "Dispatcher ori";
        RequestContent: BigText;
        ResponseContent: BigText;
        ResponseContentType: Text[100];
    begin
        RequestContent.AddText(RequestText);
        // The lightweight dispatch (OmitCommit) neither persists a message nor commits: a verification must not
        // leave a trace. The playbook runner keeps using Msg Executor ori for the steps themselves.
        Dispatcher.Execute("Message Type ori"::"Data.Records.Get", "Message Version ori"::"1.0", '', SourceTok, 'application/json',
            RequestContent, ResponseContent, ResponseContentType, true);
        if ResponseContent.Length() > 0 then
            ResponseContent.GetSubText(ResponseText, 1);
    end;

    /// <summary>
    /// Collects the JSON names of the fields of a table, the way the data message types name them: letters and digits
    /// are kept, % . " \ / ' become _, every other character is dropped (Sell-to Customer No. becomes SelltoCustomerNo_).
    /// The names are lower case so a comparison does not depend on case.
    /// </summary>
    /// <param name="TableName">The AL name or the caption of the table, as a step template writes it.</param>
    /// <param name="FieldNames">Receives the lower-case JSON names.</param>
    /// <param name="ResolvedTableName">Receives the AL name of the table.</param>
    /// <returns>True when the table and its fields could be read; false when it is not determinable.</returns>
    internal procedure TryGetFieldNames(TableName: Text; var FieldNames: Dictionary of [Text, Boolean]; var ResolvedTableName: Text): Boolean
    var
        TableId: Integer;
    begin
        Clear(FieldNames);
        if not TryFindTable(TableName, TableId, ResolvedTableName) then
            exit(false);
        exit(TryReadFieldNames(TableId, FieldNames));
    end;

    [TryFunction]
    local procedure TryFindTable(TableName: Text; var TableId: Integer; var ResolvedTableName: Text)
    var
        AllObjWithCaption: Record AllObjWithCaption;
        Number: Integer;
    begin
        if TableName = '' then
            Error('');
        AllObjWithCaption.SetLoadFields("Object ID", "Object Name");
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        if Evaluate(Number, TableName) then
            AllObjWithCaption.SetRange("Object ID", Number)
        else
            AllObjWithCaption.SetRange("Object Name", CopyStr(TableName, 1, MaxStrLen(AllObjWithCaption."Object Name")));
        if not AllObjWithCaption.FindFirst() then begin
            AllObjWithCaption.SetRange("Object Name");
            AllObjWithCaption.SetRange("Object Caption", CopyStr(TableName, 1, MaxStrLen(AllObjWithCaption."Object Caption")));
            AllObjWithCaption.FindFirst();
        end;
        TableId := AllObjWithCaption."Object ID";
        ResolvedTableName := AllObjWithCaption."Object Name";
    end;

    [TryFunction]
    local procedure TryReadFieldNames(TableId: Integer; var FieldNames: Dictionary of [Text, Boolean])
    var
        TableField: Record Field;
        JsonName: Text;
    begin
        TableField.SetLoadFields(FieldName);
        TableField.SetRange(TableNo, TableId);
        TableField.FindSet();
        repeat
            JsonName := ToJsonName(TableField.FieldName);
            if not FieldNames.ContainsKey(JsonName) then
                FieldNames.Add(JsonName, true);
        until TableField.Next() = 0;
    end;

    /// <summary>
    /// Converts a field name to its lower-case JSON name.
    /// </summary>
    /// <param name="FieldName">The field name, for example "Sell-to Customer No.".</param>
    /// <returns>The lower-case JSON name, for example "selltocustomerno_".</returns>
    internal procedure ToJsonName(FieldName: Text): Text
    var
        Result: TextBuilder;
        Ch: Char;
        Index: Integer;
    begin
        for Index := 1 to StrLen(FieldName) do begin
            Ch := FieldName[Index];
            if IsLetterOrDigit(Ch) then
                Result.Append(Format(Ch))
            else
                if Ch in ['%', '.', '"', '\', '/', ''''] then
                    Result.Append('_');
        end;
        exit(Result.ToText().ToLower());
    end;

    local procedure IsLetterOrDigit(Ch: Char): Boolean
    begin
        exit(((Ch >= 'a') and (Ch <= 'z')) or ((Ch >= 'A') and (Ch <= 'Z')) or ((Ch >= '0') and (Ch <= '9')));
    end;

    /// <summary>
    /// A value is safe to put in a table view when it holds only letters, digits, space, hyphen, underscore and dot.
    /// </summary>
    local procedure IsPlainFilterValue(FieldValue: Text): Boolean
    var
        Ch: Char;
        Index: Integer;
    begin
        if FieldValue = '' then
            exit(false);
        for Index := 1 to StrLen(FieldValue) do begin
            Ch := FieldValue[Index];
            if not (IsLetterOrDigit(Ch) or (Ch in [' ', '-', '_', '.'])) then
                exit(false);
        end;
        exit(true);
    end;

    /// <summary>
    /// Lets a subscriber answer whether a language model role exists, instead of the read through Data.Records.Get.
    /// </summary>
    /// <param name="RoleCode">The roleCode of the step template.</param>
    /// <param name="Handled">Set to true by the subscriber that answers.</param>
    /// <param name="Exists">Set to true when the role exists.</param>
    [IntegrationEvent(false, false)]
    internal procedure OnBeforeCheckLanguageModelRole(RoleCode: Text; var Handled: Boolean; var Exists: Boolean)
    begin
    end;

    var
        LanguageModelTableTok: Label 'Bifrost Language Model ori', Locked = true;
        CodeFieldTok: Label 'Code', Locked = true;
        TableViewTok: Label 'WHERE(%1=CONST(%2))', Locked = true;
        SourceTok: Label 'Bifrost Orchestrator Playbook Verify', Locked = true;
}
