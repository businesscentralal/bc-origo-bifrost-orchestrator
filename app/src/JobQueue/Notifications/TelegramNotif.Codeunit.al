namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.Apps;
using System.Environment;
using System.Environment.Configuration;
using System.Threading;

codeunit 10035587 "Telegram Notif. ori" implements "Notification ori"
{
    Access = Internal;

    procedure IsNotificationReceipientMandatory() IsMandatory: Boolean
    begin
        IsMandatory := true;
    end;

    procedure SendExecutionCompletedNotification("Scheduled Entry ori": Record "Scheduled Entry ori"; JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    procedure SendHeartbeatNotification("Scheduled Entry ori": Record "Scheduled Entry ori")
    begin
    end;

    procedure SendRestartNotification("Scheduled Entry ori": Record "Scheduled Entry ori"; JobQueueEntry: Record "Job Queue Entry")
    var
        Secrets: Codeunit "Secrets ori";
        TelegramSend: Codeunit "Telegram Send ori";
        ChatIds: List of [Text];
        ChatId: Text;
        MessageText: Text;
    begin
        if "Scheduled Entry ori"."Notification Recipient" = '' then
            exit;

        if not Secrets.IsTelegramBotTokenSet() then
            exit;

        MessageText := BuildRestartMessage("Scheduled Entry ori", JobQueueEntry);
        ChatIds := "Scheduled Entry ori"."Notification Recipient".Split(';');
        foreach ChatId in ChatIds do
            if ChatId.Trim() <> '' then
                if not TelegramSend.SendMessage(Secrets.GetTelegramBotToken(), ChatId.Trim(), MessageText) then
                    LogSendError("Scheduled Entry ori", ChatId);
    end;

    procedure SendTestNotification("Scheduled Entry ori": Record "Scheduled Entry ori")
    var
        Secrets: Codeunit "Secrets ori";
        TelegramSend: Codeunit "Telegram Send ori";
        ChatIds: List of [Text];
        ChatId: Text;
        MessageText: Text;
    begin
        VerifyHttpClientEnabled();
        "Scheduled Entry ori".TestField("Notification Recipient");
        if not Secrets.IsTelegramBotTokenSet() then
            Error(BotTokenNotConfiguredErr);

        MessageText := StrSubstNo(TestMessageLbl, "Scheduled Entry ori".Description);
        ChatIds := "Scheduled Entry ori"."Notification Recipient".Split(';');
        foreach ChatId in ChatIds do
            if ChatId.Trim() <> '' then
                if not TelegramSend.SendMessage(Secrets.GetTelegramBotToken(), ChatId.Trim(), MessageText) then
                    Error(SendFailedErr, ChatId);
    end;

    procedure ValidateNotificationReceipient("Scheduled Entry ori": Record "Scheduled Entry ori")
    var
        ChatIds: List of [Text];
        ChatId: Text;
    begin
        if "Scheduled Entry ori"."Notification Recipient" = '' then
            exit;

        ChatIds := "Scheduled Entry ori"."Notification Recipient".Split(';');
        foreach ChatId in ChatIds do
            if (ChatId.Trim() <> '') and not IsValidChatId(ChatId.Trim()) then
                Error(InvalidChatIdErr, ChatId);
    end;

    local procedure IsValidChatId(ChatId: Text): Boolean
    var
        i: Integer;
        c: Char;
    begin
        if ChatId = '' then
            exit(false);
        for i := 1 to StrLen(ChatId) do begin
            c := ChatId[i];
            if not ((i = 1) and (c = '-')) then
                if (c < '0') or (c > '9') then
                    exit(false);
        end;
        exit(true);
    end;

    local procedure VerifyHttpClientEnabled()
    var
        NavAppSetting: Record "NAV App Setting";
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        if not NavAppSetting.Get(AppInfo.Id()) or not NavAppSetting."Allow HttpClient Requests" then
            Error(HttpClientNotEnabledErr);
    end;

    local procedure BuildRestartMessage("Scheduled Entry ori": Record "Scheduled Entry ori"; JobQueueEntry: Record "Job Queue Entry") MessageText: Text
    var
        EnvironmentInformation: Codeunit "Environment Information";
        Builder: TextBuilder;
    begin
        Builder.Append('âš ï¸ <b>');
        Builder.Append(JobRestartedLbl);
        Builder.AppendLine('</b>');
        Builder.AppendLine();
        Builder.Append('ðŸ“‹ ');
        Builder.AppendLine("Scheduled Entry ori".Description);
        Builder.AppendLine();
        if JobQueueEntry."Error Message" <> '' then begin
            Builder.Append('âŒ ');
            Builder.AppendLine(JobQueueEntry."Error Message");
            Builder.AppendLine();
        end;
        Builder.Append('ðŸ¢ ');
        Builder.AppendLine(CompanyName());
        if EnvironmentInformation.IsProduction() then
            Builder.AppendLine('ðŸ”´ Production');
        Builder.AppendLine();
        MessageText := Builder.ToText();
    end;

#pragma warning disable AA0137
    local procedure LogSendError("Scheduled Entry ori": Record "Scheduled Entry ori"; ChatId: Text)
#pragma warning restore AA0137
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('Category', 'BifrostOrchestrator');
        // The chat id is a per-person identifier (CustomerContent on "User Setup ori") and is
        // deliberately not a telemetry dimension. EntryDescription already says which notification
        // failed.
        Dimensions.Add('EntryDescription', "Scheduled Entry ori".Description);
        Session.LogMessage(
            'CETEL0001',
            SendFailedTelemetryLbl,
            Verbosity::Error,
            DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher,
            Dimensions);
    end;

    var
        BotTokenNotConfiguredErr: Label 'Telegram Bot Token is not configured in Orchestrator Setup.', Comment = 'is-IS=Telegram-vÃ©lmennislykill er ekki stilltur Ã­ uppsetningu vinnsluraÃ°ara.';
        HttpClientNotEnabledErr: Label 'HTTP client requests are not enabled for this extension. Enable Allow HttpClient Requests in Extension Settings before sending Telegram notifications.', Comment = 'is-IS=HTTP-biÃ°larabeiÃ°nir eru ekki virkar fyrir Ã¾essa viÃ°bÃ³t. VirkjaÃ°u Leyfa HttpClient-beiÃ°nir Ã­ stillingum viÃ°bÃ³tar Ã¡Ã°ur en Telegram-tilkynningar eru sendar.';
        InvalidChatIdErr: Label 'Invalid Telegram Chat ID: %1. Must be numeric.', Comment = '%1 = the invalid chat id, is-IS=Ã“gilt Telegram-spjallauÃ°kenni: %1. VerÃ°ur aÃ° vera tala.';
        JobRestartedLbl: Label 'Job has been restarted', Comment = 'is-IS=Verk hefur veriÃ° endurrÃ¦st';
        SendFailedErr: Label 'Failed to send Telegram message to Chat ID %1.', Comment = '%1 = chat id, is-IS=Ekki tÃ³kst aÃ° senda Telegram-skilaboÃ° Ã¡ spjallauÃ°kenni %1.';
        SendFailedTelemetryLbl: Label 'Telegram send failed', Locked = true;
        TestMessageLbl: Label 'âœ… Test notification for: %1', Comment = '%1 = Job Description, is-IS=âœ… PrÃ³funartilkynning fyrir: %1';
}
