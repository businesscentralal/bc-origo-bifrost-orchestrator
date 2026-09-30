namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.Apps;
using System.Environment.Configuration;

codeunit 10035588 "Telegram Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
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

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'send Telegram, Telegram message, notify user, chat message, bot notification', Comment = 'is-IS=senda Telegram, Telegram-skilaboð, tilkynna notanda, spjallskilaboð, tilkynning frá Telegram-botni';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Send a Telegram message to the current user. Irreversible. Use Orchestrator.Email.Send for email delivery.', Comment = 'is-IS=Sendu Telegram-skilaboð til núverandi notanda. Óafturkræft. Notaðu Orchestrator.Email.Send fyrir tölvupóstsendingu.';
    begin
        exit(SelectionLbl);
    end;

    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Forms: List of [Text];
    begin
        Envelope := Parts.Envelope(Forms, 'No subject is used.', true);
        exit(true);
    end;

    procedure GetTarget(var Target: JsonArray): Boolean
    begin
        exit(false);
    end;

    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('message', 'string', true, 'Text sent to the current user''s configured Telegram chat.'));
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Fields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'status', 'string', 'Success.');
        Parts.AddResponseField(Fields, 'chatId', 'string', 'Configured Telegram chat identifier.');
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.AddRuntimeError(Errors, 'The Telegram bot token, HTTP permission, chat ID or message is missing.', 'Configure the token and current user chat ID, enable HTTP requests, and send message.');
        Parts.AddRuntimeError(Errors, 'Telegram rejected the request.', 'Inspect the returned Telegram response and correct the message or configuration.');
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Preconditions: JsonArray;
    begin
        Effect := Parts.Effect('irreversible', 'Sends a message to the current user through Telegram.', false, '', Preconditions);
        exit(true);
    end;

    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    procedure GetRelated(var Related: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.Related(Related, 'Orchestrator.Email.Send', 'Use this when the notification should be delivered by email.');
        exit(true);
    end;

    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        exit(false);
    end;

    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.Example(Examples, 'Send Telegram message', '{"type":"Orchestrator.Telegram.Message","data":{"message":"Job completed."}}', '{"status":"Success","chatId":"<chatId>"}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Sends a message to the current user''s Telegram chat using the configured Bifröst bot.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'The token, current user chat ID and Allow HttpClient Requests setting must all be configured before sending.';
        exit(true);
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
        NoChatIdErr: Label 'No Telegram Chat ID configured for the current user. Set it in Bifrost User Setup.', Comment = 'is-IS=Ekkert Telegram-spjallauðkenni stillt fyrir núverandi notanda. Stilltu það í uppsetningu Bifröst notanda.';
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
