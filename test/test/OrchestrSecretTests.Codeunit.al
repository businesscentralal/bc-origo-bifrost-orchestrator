namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;

/// <summary>
/// Covers the move of the Bifrost Orchestrator secrets into the Bifröst Foundation secret store:
/// the composed secret codes, the registration done by install and upgrade, the set / is-set /
/// clear round trip of the Telegram bot token and of a client credentials pair, the cleanup when a
/// credential record is deleted or renamed, and the reduced Bifröst Setup page extension.
/// </summary>
codeunit 96403 "Orchestr Secret Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        SecretStore: Codeunit "Secret Store ori";
        Secrets: Codeunit "Secrets ori";
        CredentialCodeTok: Label 'BIFT-SEC-A', Locked = true;
        LongCredentialCodeATok: Label 'BIFT-SEC-LONG-CODE-THAT-OVERFLOWS-A', Locked = true;
        LongCredentialCodeBTok: Label 'BIFT-SEC-LONG-CODE-THAT-OVERFLOWS-B', Locked = true;
        RenamedCredentialCodeTok: Label 'BIFT-SEC-B', Locked = true;
        SecretValueTok: Label 'bift-secret-value', Locked = true;
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        TestInstall: Codeunit "Test Install";
    begin
        CleanUpCredential(CopyStr(CredentialCodeTok, 1, 50));
        CleanUpCredential(CopyStr(RenamedCredentialCodeTok, 1, 50));
        Secrets.ClearTelegramBotToken();

        if IsInitialized then
            exit;
        TestInstall.DisableRequestDebugMode();
        IsInitialized := true;
    end;

    // ---------- secret codes ----------

    [Test]
    procedure SecretCodesFollowTheDocumentedPattern()
    begin
        // [SCENARIO] The secret codes are the published contract of the application

        // [GIVEN] a client credentials code
        Initialize();

        // [THEN] the composed codes are the documented ones and the credential code is uppercased
        Assert.AreEqual('TELEGRAM-BOT-TOKEN', Secrets.TelegramBotTokenCode(), 'Unexpected Telegram bot token secret code');
        Assert.AreEqual('CREDENTIAL-BIFT-SEC-A-CLIENT-ID', Secrets.ClientIdCode(CopyStr(CredentialCodeTok, 1, 50)), 'Unexpected client id secret code');
        Assert.AreEqual('CREDENTIAL-BIFT-SEC-A-CLIENT-SECRET', Secrets.ClientSecretCode(CopyStr(CredentialCodeTok, 1, 50)), 'Unexpected client secret secret code');
        Assert.AreEqual('CREDENTIAL-BIFT-SEC-A-CLIENT-ID', Secrets.ClientIdCode('bift-sec-a'), 'A lowercase credential code must produce the same secret code');
    end;

    [Test]
    procedure LongCredentialCodesFitCode50AndStayDistinct()
    var
        FirstIdCode: Code[50];
        SecondIdCode: Code[50];
    begin
        // [SCENARIO] Two long codes sharing a 16 character prefix must not collapse onto one secret

        // [GIVEN] two credential codes longer than the 25 characters the composed code allows
        Initialize();

        // [WHEN] the client id secret codes are composed
        FirstIdCode := Secrets.ClientIdCode(CopyStr(LongCredentialCodeATok, 1, 50));
        SecondIdCode := Secrets.ClientIdCode(CopyStr(LongCredentialCodeBTok, 1, 50));

        // [THEN] both fit Code[50], stay distinct and are deterministic
        Assert.IsTrue(StrLen(Secrets.ClientSecretCode(CopyStr(LongCredentialCodeATok, 1, 50))) <= 50, 'A composed secret code must fit Code[50]');
        Assert.AreNotEqual(FirstIdCode, SecondIdCode, 'Two long credential codes must not share a secret code');
        Assert.AreEqual(FirstIdCode, Secrets.ClientIdCode(CopyStr(LongCredentialCodeATok, 1, 50)), 'The composed secret code must be deterministic');
    end;

    // ---------- registration ----------

    [Test]
    procedure RegisterAllRegistersTheTelegramBotToken()
    var
        AppSecret: Record "App Secret ori";
    begin
        // [SCENARIO] Install and upgrade register the Telegram bot token so the administrator sees it

        // [GIVEN] a company where the registration row does not exist
        Initialize();
        DeleteRegistration(Secrets.TelegramBotTokenCode());

        // [WHEN] the application registers its secrets
        Secrets.RegisterAll();

        // [THEN] the registry row exists with scope Company
        Assert.IsTrue(AppSecret.Get(Secrets.GetAppId(), Secrets.TelegramBotTokenCode()), 'The Telegram bot token must be registered');
        Assert.AreEqual("Secret Scope ori"::Company.AsInteger(), AppSecret.Scope.AsInteger(), 'The Telegram bot token must use scope Company');
        Assert.AreNotEqual('', AppSecret.Description, 'A registered secret must carry a description');
    end;

    [Test]
    procedure RegisterAllRegistersBothSecretsOfEveryCredential()
    var
        AppSecret: Record "App Secret ori";
        CredentialCode: Code[50];
    begin
        // [SCENARIO] The take-over copies credential records without values, so upgrade must register them

        // [GIVEN] a client credentials record whose registrations were removed
        Initialize();
        CredentialCode := CopyStr(CredentialCodeTok, 1, 50);
        CreateCredential(CredentialCode);
        DeleteRegistration(Secrets.ClientIdCode(CredentialCode));
        DeleteRegistration(Secrets.ClientSecretCode(CredentialCode));

        // [WHEN] the application registers its secrets
        Secrets.RegisterAll();

        // [THEN] both registry rows exist again
        Assert.IsTrue(AppSecret.Get(Secrets.GetAppId(), Secrets.ClientIdCode(CredentialCode)), 'The client id must be registered');
        Assert.IsTrue(AppSecret.Get(Secrets.GetAppId(), Secrets.ClientSecretCode(CredentialCode)), 'The client secret must be registered');
    end;

    [Test]
    procedure RegisterAllIsIdempotent()
    var
        AppSecret: Record "App Secret ori";
        FirstCount: Integer;
    begin
        // [SCENARIO] Install, upgrade and every opening of the setup page call RegisterAll

        // [GIVEN] the secrets are registered once
        Initialize();
        Secrets.RegisterAll();
        AppSecret.SetRange("App Id", Secrets.GetAppId());
        FirstCount := AppSecret.Count();

        // [WHEN] the registration runs again
        Secrets.RegisterAll();

        // [THEN] no duplicate rows are created
        Assert.AreEqual(FirstCount, AppSecret.Count(), 'Registering the secrets twice must not create duplicate rows');
    end;

    // ---------- Telegram bot token round trip ----------

    [Test]
    procedure TelegramBotTokenSetIsSetAndClearRoundTrip()
    var
        Value: SecretText;
    begin
        // [SCENARIO] The administrator enters the bot token once and can remove it again

        // [GIVEN] a registered but empty Telegram bot token
        Initialize();
        Secrets.RegisterTelegramBotToken();
        Assert.IsFalse(Secrets.IsTelegramBotTokenSet(), 'A freshly registered secret must have no value');

        // [WHEN] a value is stored
        StoreSecret(Secrets.TelegramBotTokenCode());

        // [THEN] the secret reads back
        Assert.IsTrue(Secrets.IsTelegramBotTokenSet(), 'The bot token must be reported as set');
        Assert.IsTrue(SecretStore.TryGet(Secrets.GetAppId(), Secrets.TelegramBotTokenCode(), Value), 'The bot token must read back');
        Assert.IsFalse(Value.IsEmpty(), 'The bot token must not read back empty');

        // [WHEN] the value is cleared
        Secrets.ClearTelegramBotToken();

        // [THEN] nothing is stored any more, but the registration survives
        Assert.IsFalse(Secrets.IsTelegramBotTokenSet(), 'The bot token must be reported as not set after Clear');
        Assert.IsFalse(SecretStore.TryGet(Secrets.GetAppId(), Secrets.TelegramBotTokenCode(), Value), 'The bot token must not read back after Clear');
        Assert.IsTrue(Secrets.CountMissingSecrets() > 0, 'The cleared bot token must be counted as a missing secret');
    end;

    // ---------- client credentials round trip ----------

    [Test]
    procedure CredentialClientIdAndSecretRoundTrip()
    var
        ClientCredentials: Record "Client Credentials ori";
        Value: SecretText;
        CredentialCode: Code[50];
    begin
        // [SCENARIO] Both halves of a credential pair are entered through the secret store

        // [GIVEN] a new client credentials record
        Initialize();
        CredentialCode := CopyStr(CredentialCodeTok, 1, 50);
        CreateCredential(CredentialCode);
        ClientCredentials.SetLoadFields(Code);
        ClientCredentials.Get(CredentialCode);
        Assert.IsFalse(ClientCredentials.IsComplete(), 'A new credential pair must start incomplete');

        // [WHEN] both values are stored
        StoreSecret(Secrets.ClientIdCode(CredentialCode));
        StoreSecret(Secrets.ClientSecretCode(CredentialCode));

        // [THEN] the pair is complete and both values read back
        Assert.IsTrue(Secrets.IsClientIdSet(CredentialCode), 'The client id must be reported as set');
        Assert.IsTrue(Secrets.IsClientSecretSet(CredentialCode), 'The client secret must be reported as set');
        Assert.IsTrue(ClientCredentials.IsComplete(), 'A credential pair with both values must be complete');
        Assert.IsTrue(Secrets.TryGetClientId(CredentialCode, Value), 'The client id must read back');
        Assert.IsTrue(Secrets.TryGetClientSecret(CredentialCode, Value), 'The client secret must read back');
    end;

    [Test]
    procedure DeletingACredentialClearsItsSecrets()
    var
        AppSecret: Record "App Secret ori";
        ClientCredentials: Record "Client Credentials ori";
        CredentialCode: Code[50];
    begin
        // [SCENARIO] Removing a credential pair must leave behind neither its values nor its
        // registry rows. Foundation's "Secret Store ori".Unregister is documented as the call
        // belonging in the OnDelete trigger of the record that owns the registration.

        // [GIVEN] a client credentials record with both values stored
        Initialize();
        CredentialCode := CopyStr(CredentialCodeTok, 1, 50);
        CreateCredential(CredentialCode);
        StoreSecret(Secrets.ClientIdCode(CredentialCode));
        StoreSecret(Secrets.ClientSecretCode(CredentialCode));

        // [WHEN] the record is deleted
        ClientCredentials.SetLoadFields(Code);
        ClientCredentials.Get(CredentialCode);
        ClientCredentials.Delete(true);

        // [THEN] both values are gone
        Assert.IsFalse(Secrets.IsClientIdSet(CredentialCode), 'The client id must be cleared with the record');
        Assert.IsFalse(Secrets.IsClientSecretSet(CredentialCode), 'The client secret must be cleared with the record');

        // [THEN] and so are both registry rows - the credential no longer exists, so nobody could
        // ever enter a value for them and they would count as missing secrets for ever
        Assert.IsFalse(AppSecret.Get(Secrets.GetAppId(), Secrets.ClientIdCode(CredentialCode)), 'The client id registration must be removed with the record');
        Assert.IsFalse(AppSecret.Get(Secrets.GetAppId(), Secrets.ClientSecretCode(CredentialCode)), 'The client secret registration must be removed with the record');
    end;

    [Test]
    procedure DeletingACredentialLeavesNoMissingSecretsBehind()
    var
        ClientCredentials: Record "Client Credentials ori";
        CredentialCode: Code[50];
        MissingAfter: Integer;
        MissingBefore: Integer;
    begin
        // [SCENARIO] The "secrets missing" notification on the setup page must not keep firing for a
        // credential the administrator has deleted - there would be no way left to clear it

        // [GIVEN] the number of registered secrets without a value before anything is created
        Initialize();
        CredentialCode := CopyStr(CredentialCodeTok, 1, 50);
        MissingBefore := Secrets.CountMissingSecrets();

        // [WHEN] a credential is created without values and then deleted again
        CreateCredential(CredentialCode);
        ClientCredentials.SetLoadFields(Code);
        ClientCredentials.Get(CredentialCode);
        ClientCredentials.Delete(true);

        // [THEN] the missing-secret count is back where it started
        MissingAfter := Secrets.CountMissingSecrets();
        Assert.AreEqual(MissingBefore, MissingAfter, 'Deleting a credential must not leave registered secrets nobody can enter');
    end;

    [Test]
    procedure RenamingACredentialMovesItsSecrets()
    var
        AppSecret: Record "App Secret ori";
        ClientCredentials: Record "Client Credentials ori";
        NewCredentialCode: Code[50];
        OldCredentialCode: Code[50];
    begin
        // [SCENARIO] The secret codes contain the record code, so a rename must move the values

        // [GIVEN] a client credentials record with both values stored
        Initialize();
        OldCredentialCode := CopyStr(CredentialCodeTok, 1, 50);
        NewCredentialCode := CopyStr(RenamedCredentialCodeTok, 1, 50);
        CreateCredential(OldCredentialCode);
        StoreSecret(Secrets.ClientIdCode(OldCredentialCode));
        StoreSecret(Secrets.ClientSecretCode(OldCredentialCode));

        // [WHEN] the record is renamed
        ClientCredentials.SetLoadFields(Code);
        ClientCredentials.Get(OldCredentialCode);
        ClientCredentials.Rename(NewCredentialCode);

        // [THEN] the values follow the new code and the old codes are empty
        Assert.IsTrue(Secrets.IsClientIdSet(NewCredentialCode), 'The client id must follow the renamed record');
        Assert.IsTrue(Secrets.IsClientSecretSet(NewCredentialCode), 'The client secret must follow the renamed record');
        Assert.IsFalse(Secrets.IsClientIdSet(OldCredentialCode), 'The client id must be cleared from the old code');
        Assert.IsFalse(Secrets.IsClientSecretSet(OldCredentialCode), 'The client secret must be cleared from the old code');

        // [THEN] the old registrations are gone too - the old code no longer names any record, so
        // keeping them would count as missing secrets for ever
        Assert.IsFalse(AppSecret.Get(Secrets.GetAppId(), Secrets.ClientIdCode(OldCredentialCode)), 'The old client id registration must be removed by the rename');
        Assert.IsFalse(AppSecret.Get(Secrets.GetAppId(), Secrets.ClientSecretCode(OldCredentialCode)), 'The old client secret registration must be removed by the rename');
    end;

    // ---------- pages ----------

    [Test]
    procedure AppSetupPageReportsTheTelegramSecretStatus()
    var
        SetupPage: TestPage "Scheduler Setup ori";
    begin
        // [SCENARIO] The application setup page tells the administrator whether the value is entered

        // [GIVEN] a registered but empty Telegram bot token
        Initialize();
        Secrets.RegisterTelegramBotToken();

        // [WHEN] the application setup page is opened
        SetupPage.OpenEdit();

        // [THEN] the status field reports the missing value
        Assert.AreEqual('Not set', SetupPage.TelegramBotTokenStatusField.Value(), 'The setup page must report a missing bot token');
        SetupPage.Close();

        // [WHEN] a value is stored and the page is reopened
        StoreSecret(Secrets.TelegramBotTokenCode());
        SetupPage.OpenEdit();

        // [THEN] the status field reports the stored value
        Assert.AreEqual('Set', SetupPage.TelegramBotTokenStatusField.Value(), 'The setup page must report a stored bot token');
        SetupPage.Close();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,SchedulerSetupPageHandler')]
    procedure BifrostSetupExposesTheSingleOrchestratorAppsAction()
    var
        BifrostSetup: TestPage "Setup ori";
    begin
        // [SCENARIO] The Bifröst Setup page carries exactly one Bifrost Orchestrator action, in group Apps.
        // The three navigation actions moved onto the application setup page; referencing any of
        // them here would no longer compile. The setup notifications live on Bifröst Setup, raised
        // by Foundation for every application in the registry.

        // [GIVEN] the Bifröst Setup page
        Initialize();

        // [WHEN] the page is opened
        BifrostSetup.OpenView();

        // [THEN] the single Apps action is available and opens the application setup page
        Assert.IsTrue(BifrostSetup.OrchestratorSetup.Enabled(), 'The Bifrost Orchestrator Setup action must be available on Bifrost Setup');
        BifrostSetup.OrchestratorSetup.Invoke();
        BifrostSetup.Close();
    end;

    // ---------- handlers ----------

    [SendNotificationHandler]
    procedure SendNotificationHandler(var TheNotification: Notification): Boolean
    begin
        exit(true);
    end;

    [PageHandler]
    procedure SchedulerSetupPageHandler(var SchedulerSetup: TestPage "Scheduler Setup ori")
    begin
        SchedulerSetup.Close();
    end;

    // ---------- helpers ----------

    local procedure CreateCredential(CredentialCode: Code[50])
    var
        ClientCredentials: Record "Client Credentials ori";
    begin
        ClientCredentials.Init();
        ClientCredentials.Code := CredentialCode;
        ClientCredentials.Description := CopyStr(CredentialCode, 1, MaxStrLen(ClientCredentials.Description));
        ClientCredentials.Insert(true);
    end;

    local procedure CleanUpCredential(CredentialCode: Code[50])
    var
        ClientCredentials: Record "Client Credentials ori";
    begin
        Secrets.ClearCredential(CredentialCode);
        ClientCredentials.SetLoadFields(Code);
        if ClientCredentials.Get(CredentialCode) then
            ClientCredentials.Delete(true);
    end;

    local procedure DeleteRegistration(SecretCode: Code[50])
    var
        AppSecret: Record "App Secret ori";
    begin
        SecretStore.Clear(Secrets.GetAppId(), SecretCode);
        if AppSecret.Get(Secrets.GetAppId(), SecretCode) then
            AppSecret.Delete(true);
    end;

    local procedure StoreSecret(SecretCode: Code[50])
    var
        Value: SecretText;
        ValueText: Text;
    begin
        ValueText := SecretValueTok;
        Value := ValueText;
        SecretStore.Set(Secrets.GetAppId(), SecretCode, Value);
    end;
}
