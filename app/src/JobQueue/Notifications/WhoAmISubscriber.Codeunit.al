namespace Origo.Bifrost.Nornir;

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
}
