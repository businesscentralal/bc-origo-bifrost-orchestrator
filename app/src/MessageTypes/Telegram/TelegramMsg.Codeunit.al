namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.Apps;
using System.Environment.Configuration;

codeunit 10035588 "Telegram Msg ori" implements "Msg Interface ori"
{
    Access = Internal;
    Permissions =
        tabledata "User Setup ori" = R;

    procedure IsEnabled(): Boolean
    var
        UserSetup: Record "User Setup ori";
        Secrets: Codeunit "Secrets ori";
    begin
        if not Secrets.IsTelegramBotTokenSet() then
            exit(false);
        UserSetup.SetLoadFields("Telegram Chat ID ori");
        if not UserSetup.Get(UserSecurityId()) then
            exit(false);
        exit(UserSetup."Telegram Chat ID ori" <> '');
    end;

    procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    procedure GetDescription(): Text[250]
    var
        DescriptionLbl: Label 'Send a Telegram message to the current user.', Comment = 'is-IS=Senda Telegram-skilaboÃ° Ã¡ nÃºverandi notanda.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Inbound);
    end;

    procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Help ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp('Orchestrator.Telegram.Message'));
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
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

        UserSetup.SetLoadFields("Telegram Chat ID ori");
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
        BotTokenNotConfiguredErr: Label 'Telegram Bot Token is not configured in Orchestrator Setup.', Comment = 'is-IS=Telegram-vÃ©lmennislykill er ekki stilltur Ã­ uppsetningu vinnsluraÃ°ara.';
        HttpClientNotEnabledErr: Label 'HTTP client requests are not enabled for this extension. Enable Allow HttpClient Requests in Extension Settings before sending Telegram messages.', Comment = 'is-IS=HTTP-biÃ°larabeiÃ°nir eru ekki virkar fyrir Ã¾essa viÃ°bÃ³t. VirkjaÃ°u Leyfa HttpClient-beiÃ°nir Ã­ stillingum viÃ°bÃ³tar Ã¡Ã°ur en Telegram-skilaboÃ° eru send.';
        MissingMessageErr: Label '"message" is required in the request data.', Comment = 'is-IS="message" er nauÃ°synlegt Ã­ beiÃ°nigÃ¶gnum.';
        NoChatIdErr: Label 'No Telegram Chat ID configured for the current user. Set it in Bifrost User Setup.', Comment = 'is-IS=Ekkert Telegram-spjallauÃ°kenni stillt fyrir nÃºverandi notanda. Stilltu Ã¾aÃ° Ã­ BifrÃ¶st notandauppsetningu.';
        SendFailedErr: Label 'Failed to send Telegram message to Chat ID %1. Response: %2', Comment = '%1 = chat id, %2 = API response, is-IS=Ekki tÃ³kst aÃ° senda Telegram-skilaboÃ° Ã¡ spjallauÃ°kenni %1. Svar: %2';

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
