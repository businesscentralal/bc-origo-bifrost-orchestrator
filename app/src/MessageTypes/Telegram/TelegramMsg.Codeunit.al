namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.Apps;
using System.Environment.Configuration;

codeunit 10035588 "Telegram Msg ori" implements "Msg Interface ori"
{
    Access = Internal;
    Permissions =
        tabledata "User Setup ori" = R;

    internal procedure IsEnabled(): Boolean
    var
        UserSetup: Record "User Setup ori";
        Secrets: Codeunit "Secrets ori";
    begin
        if not Secrets.IsTelegramBotTokenSet() then
            exit(false);
        if not UserSetup.Get(UserSecurityId()) then
            exit(false);
        exit(UserSetup."Telegram Chat ID ori" <> '');
    end;

    internal procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    internal procedure GetDescription(): Text[250]
    var
        DescriptionLbl: Label 'Send a Telegram message to the current user.', Comment = 'is-IS=Senda Telegram-skilaboð á núverandi notanda.';
    begin
        exit(DescriptionLbl);
    end;

    internal procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Inbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Help ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp('Orchestrator.Telegram.Message'));
    end;

    internal procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        UserSetup: Record "User Setup ori";
        Secrets: Codeunit "Secrets ori";
        TelegramSend: Codeunit "Telegram Send ori";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        ChatId: Text;
        MessageText: Text;
        JsonToken: JsonToken;
    begin
        VerifyHttpClientEnabled();
        if not Secrets.IsTelegramBotTokenSet() then
            Error(BotTokenNotConfiguredErr);

        UserSetup.Get(UserSecurityId());
        ChatId := UserSetup."Telegram Chat ID ori";
        if ChatId = '' then
            Error(NoChatIdErr);

        RequestJson := Argument.GetRequestJson();

        if not RequestJson.Get('message', JsonToken) then
            Error(MissingMessageErr);
        MessageText := JsonToken.AsValue().AsText();

        if not TelegramSend.SendMessage(Secrets.GetTelegramBotToken(), ChatId, MessageText) then
            Error(SendFailedErr, ChatId, TelegramSend.GetLastResponse());

        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('chatId', ChatId);
        Argument.SetResponseJson(ResponseJson);
    end;

    var
        BotTokenNotConfiguredErr: Label 'Telegram Bot Token is not configured in Orchestrator Setup.', Comment = 'is-IS=Telegram-vélmennislykill er ekki stilltur í uppsetningu vinnsluraðara.';
        HttpClientNotEnabledErr: Label 'HTTP client requests are not enabled for this extension. Enable Allow HttpClient Requests in Extension Settings before sending Telegram messages.', Comment = 'is-IS=HTTP-biðlarabeiðnir eru ekki virkar fyrir þessa viðbót. Virkjaðu Leyfa HttpClient-beiðnir í stillingum viðbótar áður en Telegram-skilaboð eru send.';
        MissingMessageErr: Label '"message" is required in the request data.', Comment = 'is-IS="message" er nauðsynlegt í beiðnigögnum.';
        NoChatIdErr: Label 'No Telegram Chat ID configured for the current user. Set it in Bifrost User Setup.', Comment = 'is-IS=Ekkert Telegram-spjallauðkenni stillt fyrir núverandi notanda. Stilltu það í Bifröst notandauppsetningu.';
        SendFailedErr: Label 'Failed to send Telegram message to Chat ID %1. Response: %2', Comment = '%1 = chat id, %2 = API response, is-IS=Ekki tókst að senda Telegram-skilaboð á spjallauðkenni %1. Svar: %2';

    local procedure VerifyHttpClientEnabled()
    var
        NavAppSetting: Record "NAV App Setting";
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        if not NavAppSetting.Get(AppInfo.Id()) or not NavAppSetting."Allow HttpClient Requests" then
            Error(HttpClientNotEnabledErr);
    end;
}
