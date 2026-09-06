namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.Security.Encryption;

/// <summary>
/// Single access point for every secret Bifrost Orchestrator keeps in the Bifröst Foundation secret
/// store (codeunit <c>Secret Store ori</c>). The application registers its secret codes on install
/// and on upgrade, the administrator enters the values once through the shared masked dialog, and
/// the application reads them back with <c>TryGet</c>. Values live in IsolatedStorage under the
/// Bifröst Foundation module and never reach a table, a log, an error message or telemetry.
/// The secret codes are <c>TELEGRAM-BOT-TOKEN</c> for the Telegram bot token and
/// <c>CREDENTIAL-&lt;Code&gt;-CLIENT-ID</c> / <c>CREDENTIAL-&lt;Code&gt;-CLIENT-SECRET</c> for the client id and
/// client secret of a <c>Client Credentials ori</c> record. Every one of them uses scope Company.
/// </summary>
codeunit 10035606 "Secrets ori"
{
    Access = Internal;

    var
        SecretStore: Codeunit "Secret Store ori";
        BotTokenNotSetErr: Label 'The Telegram Bot Token has not been entered yet. Open Bifrost Orchestrator Setup and set it.', Comment = 'is-IS=Telegram-vélmennislykill hefur ekki verið skráður. Opnaðu uppsetningu Bifröst stjórnandans og skráðu hann.';
        ClientIdDescriptionLbl: Label 'OAuth 2.0 client id of client credentials %1.', Comment = '%1 = client credentials code, is-IS=OAuth 2.0 biðlaraauðkenni fyrir auðkenni biðlara %1.';
        ClientSecretDescriptionLbl: Label 'OAuth 2.0 client secret of client credentials %1.', Comment = '%1 = client credentials code, is-IS=OAuth 2.0 leyniorð biðlara fyrir auðkenni biðlara %1.';
        TelegramBotTokenDescriptionLbl: Label 'Telegram bot token used to send Bifrost Orchestrator notifications.', Comment = 'is-IS=Telegram-vélmennislykill sem notaður er til að senda tilkynningar Bifröst stjórnandans.';
        ClientIdSuffixTok: Label '-CLIENT-ID', Locked = true;
        ClientSecretSuffixTok: Label '-CLIENT-SECRET', Locked = true;
        CredentialPrefixTok: Label 'CREDENTIAL-', Locked = true;
        HashSeparatorTok: Label '-', Locked = true;
        TelegramBotTokenCodeTok: Label 'TELEGRAM-BOT-TOKEN', Locked = true;

    /// <summary>
    /// Returns the application id of Bifrost Orchestrator, the owner of every secret handled here.
    /// </summary>
    /// <returns>Guid. The current module id.</returns>
    procedure GetAppId(): Guid
    var
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        exit(AppInfo.Id());
    end;

    /// <summary>
    /// Returns the secret code of the Telegram bot token.
    /// </summary>
    /// <returns>Code[50]. The constant <c>TELEGRAM-BOT-TOKEN</c>.</returns>
    procedure TelegramBotTokenCode(): Code[50]
    begin
        exit(CopyStr(TelegramBotTokenCodeTok, 1, 50));
    end;

    /// <summary>
    /// Returns the secret code holding the client id of a client credentials record.
    /// </summary>
    /// <param name="CredentialCode">The primary key of the <c>Client Credentials ori</c> record.</param>
    /// <returns>Code[50]. <c>CREDENTIAL-&lt;Code&gt;-CLIENT-ID</c>.</returns>
    procedure ClientIdCode(CredentialCode: Code[50]): Code[50]
    begin
        exit(CopyStr(CredentialPrefixTok + NormalizeCredentialCode(CredentialCode) + ClientIdSuffixTok, 1, 50));
    end;

    /// <summary>
    /// Returns the secret code holding the client secret of a client credentials record.
    /// </summary>
    /// <param name="CredentialCode">The primary key of the <c>Client Credentials ori</c> record.</param>
    /// <returns>Code[50]. <c>CREDENTIAL-&lt;Code&gt;-CLIENT-SECRET</c>.</returns>
    procedure ClientSecretCode(CredentialCode: Code[50]): Code[50]
    begin
        exit(CopyStr(CredentialPrefixTok + NormalizeCredentialCode(CredentialCode) + ClientSecretSuffixTok, 1, 50));
    end;

    /// <summary>
    /// Registers every secret the application needs: the Telegram bot token and the client id and
    /// client secret of each existing client credentials record. Idempotent, so install and upgrade
    /// can both call it.
    /// </summary>
    procedure RegisterAll()
    var
        ClientCredentials: Record "Client Credentials ori";
    begin
        RegisterTelegramBotToken();

        ClientCredentials.SetLoadFields(Code);
        if not ClientCredentials.FindSet() then
            exit;
        repeat
            RegisterCredential(ClientCredentials.Code);
        until ClientCredentials.Next() = 0;
    end;

    /// <summary>
    /// Registers the Telegram bot token secret. Idempotent.
    /// </summary>
    procedure RegisterTelegramBotToken()
    begin
        SecretStore.Register(
            GetAppId(), TelegramBotTokenCode(),
            CopyStr(TelegramBotTokenDescriptionLbl, 1, 100), "Secret Scope ori"::Company);
    end;

    /// <summary>
    /// Registers the client id and client secret of one client credentials record. Idempotent.
    /// </summary>
    /// <param name="CredentialCode">The primary key of the <c>Client Credentials ori</c> record.</param>
    procedure RegisterCredential(CredentialCode: Code[50])
    begin
        if CredentialCode = '' then
            exit;

        SecretStore.Register(
            GetAppId(), ClientIdCode(CredentialCode),
            CopyStr(StrSubstNo(ClientIdDescriptionLbl, CredentialCode), 1, 100), "Secret Scope ori"::Company);
        SecretStore.Register(
            GetAppId(), ClientSecretCode(CredentialCode),
            CopyStr(StrSubstNo(ClientSecretDescriptionLbl, CredentialCode), 1, 100), "Secret Scope ori"::Company);
    end;

    /// <summary>
    /// Removes the stored client id and client secret of one client credentials record.
    /// The registrations are kept so the administrator still sees which secrets the application knows.
    /// </summary>
    /// <param name="CredentialCode">The primary key of the <c>Client Credentials ori</c> record.</param>
    procedure ClearCredential(CredentialCode: Code[50])
    begin
        if CredentialCode = '' then
            exit;

        SecretStore.Clear(GetAppId(), ClientIdCode(CredentialCode));
        SecretStore.Clear(GetAppId(), ClientSecretCode(CredentialCode));
    end;

    /// <summary>
    /// Moves the client id and client secret of a renamed client credentials record onto the secret
    /// codes of the new record code and clears the values stored under the old codes.
    /// </summary>
    /// <param name="OldCredentialCode">The primary key before the rename.</param>
    /// <param name="NewCredentialCode">The primary key after the rename.</param>
    [NonDebuggable]
    procedure RenameCredential(OldCredentialCode: Code[50]; NewCredentialCode: Code[50])
    var
        Value: SecretText;
    begin
        if OldCredentialCode = NewCredentialCode then
            exit;

        RegisterCredential(NewCredentialCode);

        if SecretStore.TryGet(GetAppId(), ClientIdCode(OldCredentialCode), Value) then
            SecretStore.Set(GetAppId(), ClientIdCode(NewCredentialCode), Value);
        if SecretStore.TryGet(GetAppId(), ClientSecretCode(OldCredentialCode), Value) then
            SecretStore.Set(GetAppId(), ClientSecretCode(NewCredentialCode), Value);

        ClearCredential(OldCredentialCode);
    end;

    /// <summary>
    /// Reports whether a Telegram bot token has been entered.
    /// </summary>
    /// <returns>Boolean. True when a value is stored.</returns>
    procedure IsTelegramBotTokenSet(): Boolean
    begin
        exit(SecretStore.IsSet(GetAppId(), TelegramBotTokenCode()));
    end;

    /// <summary>
    /// Reads the Telegram bot token and stamps the registry row as used.
    /// </summary>
    /// <returns>SecretText. The stored bot token.</returns>
    [NonDebuggable]
    procedure GetTelegramBotToken() BotToken: SecretText
    begin
        if not SecretStore.TryGet(GetAppId(), TelegramBotTokenCode(), BotToken) then
            Error(BotTokenNotSetErr);
        SecretStore.MarkUsed(GetAppId(), TelegramBotTokenCode());
    end;

    /// <summary>
    /// Opens the shared masked dialog so the administrator can enter the Telegram bot token.
    /// </summary>
    /// <returns>Boolean. True when a value was stored.</returns>
    procedure SetTelegramBotTokenFromDialog(): Boolean
    begin
        RegisterTelegramBotToken();
        exit(SecretStore.SetFromDialog(GetAppId(), TelegramBotTokenCode()));
    end;

    /// <summary>
    /// Removes the stored Telegram bot token.
    /// </summary>
    procedure ClearTelegramBotToken()
    begin
        SecretStore.Clear(GetAppId(), TelegramBotTokenCode());
    end;

    /// <summary>
    /// Reports whether the client id of a client credentials record has been entered.
    /// </summary>
    /// <param name="CredentialCode">The primary key of the <c>Client Credentials ori</c> record.</param>
    /// <returns>Boolean. True when a value is stored.</returns>
    procedure IsClientIdSet(CredentialCode: Code[50]): Boolean
    begin
        if CredentialCode = '' then
            exit(false);
        exit(SecretStore.IsSet(GetAppId(), ClientIdCode(CredentialCode)));
    end;

    /// <summary>
    /// Reports whether the client secret of a client credentials record has been entered.
    /// </summary>
    /// <param name="CredentialCode">The primary key of the <c>Client Credentials ori</c> record.</param>
    /// <returns>Boolean. True when a value is stored.</returns>
    procedure IsClientSecretSet(CredentialCode: Code[50]): Boolean
    begin
        if CredentialCode = '' then
            exit(false);
        exit(SecretStore.IsSet(GetAppId(), ClientSecretCode(CredentialCode)));
    end;

    /// <summary>
    /// Reads the client id of a client credentials record and stamps the registry row as used.
    /// </summary>
    /// <param name="CredentialCode">The primary key of the <c>Client Credentials ori</c> record.</param>
    /// <param name="Value">Receives the client id when one is stored.</param>
    /// <returns>Boolean. True when a value was found.</returns>
    [NonDebuggable]
    procedure TryGetClientId(CredentialCode: Code[50]; var Value: SecretText): Boolean
    begin
        if CredentialCode = '' then
            exit(false);
        if not SecretStore.TryGet(GetAppId(), ClientIdCode(CredentialCode), Value) then
            exit(false);
        SecretStore.MarkUsed(GetAppId(), ClientIdCode(CredentialCode));
        exit(true);
    end;

    /// <summary>
    /// Reads the client secret of a client credentials record and stamps the registry row as used.
    /// </summary>
    /// <param name="CredentialCode">The primary key of the <c>Client Credentials ori</c> record.</param>
    /// <param name="Value">Receives the client secret when one is stored.</param>
    /// <returns>Boolean. True when a value was found.</returns>
    [NonDebuggable]
    procedure TryGetClientSecret(CredentialCode: Code[50]; var Value: SecretText): Boolean
    begin
        if CredentialCode = '' then
            exit(false);
        if not SecretStore.TryGet(GetAppId(), ClientSecretCode(CredentialCode), Value) then
            exit(false);
        SecretStore.MarkUsed(GetAppId(), ClientSecretCode(CredentialCode));
        exit(true);
    end;

    /// <summary>
    /// Opens the shared masked dialog so the administrator can enter the client id.
    /// </summary>
    /// <param name="CredentialCode">The primary key of the <c>Client Credentials ori</c> record.</param>
    /// <returns>Boolean. True when a value was stored.</returns>
    procedure SetClientIdFromDialog(CredentialCode: Code[50]): Boolean
    begin
        RegisterCredential(CredentialCode);
        exit(SecretStore.SetFromDialog(GetAppId(), ClientIdCode(CredentialCode)));
    end;

    /// <summary>
    /// Opens the shared masked dialog so the administrator can enter the client secret.
    /// </summary>
    /// <param name="CredentialCode">The primary key of the <c>Client Credentials ori</c> record.</param>
    /// <returns>Boolean. True when a value was stored.</returns>
    procedure SetClientSecretFromDialog(CredentialCode: Code[50]): Boolean
    begin
        RegisterCredential(CredentialCode);
        exit(SecretStore.SetFromDialog(GetAppId(), ClientSecretCode(CredentialCode), true, false));
    end;

    /// <summary>
    /// Counts the secrets Bifrost Orchestrator has registered that still have no value.
    /// Used to warn the administrator that secret values do not migrate from the published
    /// Origo Cloud Events Orchestrator application and must be entered once.
    /// </summary>
    /// <returns>Integer. The number of registered secrets without a stored value.</returns>
    procedure CountMissingSecrets() MissingCount: Integer
    var
        AppSecret: Record "App Secret ori";
    begin
        AppSecret.SetLoadFields("Secret Code");
        AppSecret.SetRange("App Id", GetAppId());
        if not AppSecret.FindSet() then
            exit(0);
        repeat
            if not SecretStore.IsSet(GetAppId(), AppSecret."Secret Code") then
                MissingCount += 1;
        until AppSecret.Next() = 0;
    end;

    /// <summary>
    /// Opens the Bifröst App Secrets list filtered to Bifrost Orchestrator. Used as the action of the
    /// "secrets missing" notification on the setup page.
    /// </summary>
    /// <param name="SecretsNotification">The notification that carried the action.</param>
    procedure OpenAppSecrets(SecretsNotification: Notification)
    var
        AppSecretsPage: Page "App Secrets ori";
    begin
        AppSecretsPage.SetAppFilter(GetAppId());
        AppSecretsPage.Run();
    end;

    /// <summary>
    /// Keeps the credential part of a composed secret code within the 25 characters that are left
    /// after the <c>CREDENTIAL-</c> prefix and the longest suffix (<c>-CLIENT-SECRET</c>).
    /// A code of 25 characters or less is used as it is, uppercased. A longer code is shortened
    /// deterministically to its first 16 characters, a hyphen and the first 8 hexadecimal digits of
    /// the SHA256 hash of the full uppercased code, so two long codes sharing a prefix never
    /// collapse onto the same secret.
    /// </summary>
    local procedure NormalizeCredentialCode(CredentialCode: Code[50]) NormalizedCode: Text
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
        UpperCode: Text;
    begin
        UpperCode := UpperCase(CredentialCode);
        if StrLen(UpperCode) <= MaxCredentialCodeLength() then
            exit(UpperCode);

        NormalizedCode :=
            CopyStr(UpperCode, 1, 16) + HashSeparatorTok +
            CopyStr(UpperCase(CryptographyManagement.GenerateHash(UpperCode, HashAlgorithmType::SHA256)), 1, 8);
    end;

    local procedure MaxCredentialCodeLength(): Integer
    begin
        exit(50 - StrLen(CredentialPrefixTok) - StrLen(ClientSecretSuffixTok));
    end;
}
