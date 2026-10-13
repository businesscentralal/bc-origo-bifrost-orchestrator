namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

/// <summary>
/// Enriches the Bifrost <c>Help.WhoAmI.Get</c> response with the calling user's Telegram chat id
/// so playbooks can address Telegram notifications with <c>@_who.telegramChatId</c>.
/// </summary>
codeunit 10035585 "WhoAmI Subscriber ori"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnAfterBuildWhoAmIResponse, '', false, false)]
    local procedure AddTelegramChatId(var ResponseJson: JsonObject; BifrostUserSetup: Record "User Setup ori")
    begin
        ResponseJson.Add('telegramChatId', BifrostUserSetup."Telegram Chat ID ori");
    end;
    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnAfterGetWhoAmIContract, '', false, false)]
    local procedure DescribeTelegramChatId(var Contract: JsonObject)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        ResponseToken: JsonToken;
        FieldsToken: JsonToken;
        Fields: JsonArray;
    begin
        // AddToChapterArray is internal in Foundation; modify only the public event's response fields.
        if not Contract.Get('response', ResponseToken) then
            exit;
        if not ResponseToken.IsObject() then
            exit;
        if not ResponseToken.AsObject().Get('fields', FieldsToken) then
            exit;
        if not FieldsToken.IsArray() then
            exit;
        Fields := FieldsToken.AsArray();
        Fields.Add(ContractMgt.ResponseField('telegramChatId', 'string',
            'Telegram chat ID from the calling user''s Bifrost user setup; an empty string when none is set. Present only while Bifrost Orchestrator is installed. Playbooks read it as @_who.telegramChatId.'));
    end;
}
