namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.Apps;
using System.Environment.Configuration;

codeunit 10035588 "Telegram Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;
    /// <summary>Reports whether the caller can read their Telegram setup and has a configured destination.</summary>
    /// <returns>True when the bot token and caller chat ID are available.</returns>
    procedure IsEnabled(): Boolean
    var
        UserSetup: Record "User Setup ori";
        Secrets: Codeunit "Secrets ori";
    begin
        if not Secrets.IsTelegramBotTokenSet() then
            exit(false);
        if not UserSetup.ReadPermission() then
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
        Parameters.Add(ContractMgt.Parameter('message', 'string', true, 'Text sent to the current user''s Telegram chat, with parse mode HTML: Telegram''s HTML tags format it. There is no chat ID parameter.'));
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Fields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'status', 'string', 'Success.');
        Parts.AddResponseField(Fields, 'chatId', 'string', 'Telegram Chat ID of the calling user that the message went to.');
        Response := Parts.Response(Fields, 'text/json');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Parts.AddError(Errors, 'HTTP client requests are not enabled for this extension. Enable Allow HttpClient Requests in Extension Settings before sending Telegram messages.', 'Allow HttpClient Requests is off for Bifrost Orchestrator.', 'Enable it in Extension Settings (page 2500).');
        Parts.AddError(Errors, 'Telegram Bot Token is not configured in Orchestrator Setup.', 'No bot token is stored.', 'Set the Telegram Bot Token in the Orchestrator setup.');
        Parts.AddRuntimeError(Errors, 'The calling user has no User Setup ori record (Business Central''s record-not-found text).', 'Create the user''s Bifrost User Setup with a Telegram Chat ID.');
        Parts.AddError(Errors, 'No Telegram Chat ID configured for the current user. Set it in Bifrost User Setup.', 'The calling user''s Telegram Chat ID is empty.', 'Set the Telegram Chat ID in Bifrost User Setup.');
        Parts.AddError(Errors, '"message" is required in the request data.', 'data.message is missing.', 'Send the text in data.message.');
        Parts.AddError(Errors, 'Failed to send Telegram message to Chat ID <chatId>. Response: <Telegram response>', 'Telegram rejected the request.', 'Read the Telegram response and correct the message or the configuration.');
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
        Notes := 'Sending needs three things: Allow HttpClient Requests for the extension (Extension Settings, page 2500), the Telegram Bot Token in the Orchestrator setup, and a Telegram Chat ID on the calling user''s Bifrost User Setup. The chat ID always comes from the caller''s setup.' +
            ' The type is listed for a user only when the bot token is set and that user has a Telegram Chat ID. Allow HttpClient Requests is not part of that check; it is checked when the message is sent.';
        exit(true);
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Inbound);
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
