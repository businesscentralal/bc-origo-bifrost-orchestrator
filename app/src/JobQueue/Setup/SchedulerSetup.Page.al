namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.Environment;
using System.Threading;
using System.Utilities;

/// <summary>
/// Setup page of the Bifrost Orchestrator application. It is the single entry point the application adds
/// to the Bifröst Setup page and carries everything the administrator needs: the job queue
/// orchestrator configuration, the Telegram bot token, and navigation to playbooks, client
/// credentials, the playbook execution log and the Bifröst secret list filtered to this application.
/// </summary>
page 10035536 "Scheduler Setup ori"
{
    AdditionalSearchTerms = 'Manage Job Queues,Job Queue Management,Job Queue Restarted,Job Queue Notification';
    ApplicationArea = All;
    Caption = 'Bifrost Orchestrator Setup', Comment = 'is-IS=Uppsetning Bifröst stjórnanda';
    ContextSensitiveHelpPage = 'nornir-setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Scheduler Setup ori";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General', Comment = 'is-IS=Almennt';
                field("Job Queue Category Code"; Rec."Job Queue Category Code")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the value of the Job Queue Category Code field.', Comment = 'is-IS=Tilgreinir gildi reitsins Flokkunarkóði vinnsluraða.';
                }
                field("Log Job Queue Activity"; Rec."Log Job Queue Activity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Log Job Queue Activity field.', Comment = 'is-IS=Tilgreinir gildi reitsins Skrá verkvirkni vinnsluraða.';
                }
                field("Job Queue User ID"; Rec."Job Queue User ID")
                {
                    ApplicationArea = All;
                    Enabled = JobQueueUserEnabled;
                    ToolTip = 'Specifies the User ID that will own the management job queue entry. This user must have permission to run the job queue entries. If no user is specified, the current user will be used.', Comment = 'is-IS=Tilgreinir notendaauðkenni sem á stjórnunarvinnsluraðafærsluna. Þessi notandi verður að hafa heimildir til að keyra vinnsluraðafærslurnar. Ef enginn notandi er tilgreindur er núverandi notandi notaður.';
                    Visible = JobQueueUserEnabled;
                }
                field(JobQueueStatusField; JobQueueStatus)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Job Queue Orchestrator Status', Comment = 'is-IS=Staða vinnsluraðara';
                    Editable = false;
                    QuickEntry = false;
                    StyleExpr = JobQueueStyleExpr;
                    ToolTip = 'Specifies the job queue status that is required for Job Queue Orchestrator', Comment = 'is-IS=Tilgreinir stöðu vinnsluraða sem krafist er fyrir vinnsluraðara';
                    trigger OnDrillDown()
                    begin
                        JobQueueManagement.ShowJobQueueEntry(Rec);
                        JobQueueManagement.GetJobQueueStatus(JobQueueStatus, JobQueueStyleExpr);
                    end;
                }
                field("Emit Telemetry"; Rec."Emit Telemetry")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if Telemetry is emitted for every execution.', Comment = 'is-IS=Tilgreinir hvort fjarmælingar eru sendar á hverri keyrslu.';
                }
            }
            group(TelegramGroup)
            {
                Caption = 'Telegram', Comment = 'is-IS=Telegram';
                field(TelegramBotTokenStatusField; TelegramBotTokenStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Telegram Bot Token', Comment = 'is-IS=Telegram-vélmennislykill';
                    Editable = false;
                    StyleExpr = TelegramBotTokenStyleExpr;
                    ToolTip = 'Specifies whether the Telegram Bot API token used to send notifications has been entered. Use Set Telegram Bot Token to enter it.', Comment = 'is-IS=Tilgreinir hvort Telegram-vélmennislykill sem notaður er til að senda tilkynningar hafi verið skráður. Notaðu Skrá Telegram-vélmennislykil til að skrá hann.';
                }
            }
            part("Job Queues"; "Sched. Entry Subform ori")
            {
                ApplicationArea = All;
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action(Playbooks)
            {
                ApplicationArea = All;
                Caption = 'Bifrost Playbooks', Comment = 'is-IS=Bifröst keðjur';
                Image = Relationship;
                RunObject = page "Playbooks ori";
                ToolTip = 'View and configure Bifrost message playbooks.', Comment = 'is-IS=Skoða og stilla keðjur Bifröst skilaboða.';
            }
            action(JQCredentials)
            {
                ApplicationArea = All;
                Caption = 'Client Credentials', Comment = 'is-IS=Auðkenni biðlara';
                Image = EncryptionKeys;
                RunObject = page "Credentials List ori";
                ToolTip = 'Manage client credentials for external service authentication.', Comment = 'is-IS=Stjórna auðkennum biðlara fyrir ytri þjónustuvottun.';
            }
            action(PlaybookInstances)
            {
                ApplicationArea = All;
                Caption = 'Playbook Execution Log', Comment = 'is-IS=Keyrsluskrá keðju';
                Image = Log;
                RunObject = page "Playbook Instances ori";
                ToolTip = 'View the execution log for playbook runs.', Comment = 'is-IS=Skoða keyrsluskrá keðjukeyrslna.';
            }
            action(AppSecrets)
            {
                ApplicationArea = All;
                Caption = 'App Secrets', Comment = 'is-IS=Leyndarmál forrits';
                Image = EncryptionKeys;
                ToolTip = 'Show the secrets Bifrost Orchestrator needs and whether a value has been entered for each of them.', Comment = 'is-IS=Sýna leyndarmálin sem Bifröst stjórnandinn þarf og hvort gildi hafi verið skráð fyrir hvert þeirra.';

                trigger OnAction()
                var
                    AppSecretsPage: Page "App Secrets ori";
                begin
                    AppSecretsPage.SetAppFilter(Secrets.GetAppId());
                    AppSecretsPage.Run();
                end;
            }
            action(JobQueueEntries)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Job Queue Entries', Comment = 'is-IS=Vinnsluraðafærslur';
                Image = TaskList;
                RunObject = page "Job Queue Entries";
                ToolTip = 'See the job queue entries.', Comment = 'is-IS=Sjá vinnsluraðafærslurnar.';
            }
            action(RecurringTemplates)
            {
                ApplicationArea = All;
                Caption = 'Recurring Templates', Comment = 'is-IS=Endurtekningarsniðmát';
                Image = Template;
                RunObject = page "Recurring Templates ori";
                ToolTip = 'Manage recurring schedule templates for job queue entries.', Comment = 'is-IS=Stjórna endurtekningarsniðmátum fyrir vinnsluraðafærslur.';
            }
        }
        area(Processing)
        {
            action(RestartJobQueue)
            {
                ApplicationArea = All;
                Caption = 'Restart Job Queue', Comment = 'is-IS=Endurræsa vinnsluröð';
                Image = ResetStatus;
                ToolTip = 'Restart the management job queue.', Comment = 'is-IS=Endurræsa stjórnunarvinnsluröð.';
                trigger OnAction()
                begin
                    Rec.RestartManagementJobQueue();
                end;
            }
            action(SetTelegramBotToken)
            {
                ApplicationArea = All;
                Caption = 'Set Telegram Bot Token', Comment = 'is-IS=Skrá Telegram-vélmennislykil';
                Image = EncryptionKeys;
                ToolTip = 'Enter the Telegram Bot API token. The value is stored in the Bifrost secret store and is never shown again.', Comment = 'is-IS=Skrá Telegram-vélmennislykil. Gildið er geymt í leyndarmálageymslu Bifröst og er aldrei sýnt aftur.';

                trigger OnAction()
                begin
                    if Secrets.SetTelegramBotTokenFromDialog() then
                        RefreshSecretStatus();
                end;
            }
            action(ClearTelegramBotToken)
            {
                ApplicationArea = All;
                Caption = 'Clear Telegram Bot Token', Comment = 'is-IS=Hreinsa Telegram-vélmennislykil';
                Image = ClearLog;
                ToolTip = 'Remove the stored Telegram Bot API token.', Comment = 'is-IS=Fjarlægja geymdan Telegram-vélmennislykil.';

                trigger OnAction()
                var
                    ConfirmManagement: Codeunit "Confirm Management";
                begin
                    if not ConfirmManagement.GetResponseOrDefault(ConfirmClearBotTokenQst, false) then
                        exit;
                    Secrets.ClearTelegramBotToken();
                    RefreshSecretStatus();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'is-IS=Vinna';

                actionref(RestartJobQueue_Promoted; RestartJobQueue) { }
                actionref(SetTelegramBotToken_Promoted; SetTelegramBotToken) { }
            }
            group(Category_Category4)
            {
                Caption = 'Setup', Comment = 'is-IS=Uppsetning';

                actionref(JQCredentials_Promoted; JQCredentials) { }
                actionref(AppSecrets_Promoted; AppSecrets) { }
                actionref(RecurringTemplates_Promoted; RecurringTemplates) { }
            }
            group(Category_Category5)
            {
                Caption = 'Playbooks', Comment = 'is-IS=Keðjur';

                actionref(Playbooks_Promoted; Playbooks) { }
                actionref(PlaybookInstances_Promoted; PlaybookInstances) { }
            }
        }
    }

    var
        EnvironmentMgt: Codeunit "Environment Information";
        JobQueueManagement: Codeunit "Scheduler Mgt ori";
        Secrets: Codeunit "Secrets ori";
        JobQueueUserEnabled: Boolean;
        JobQueueStatus: Text;
        JobQueueStyleExpr: Text;
        TelegramBotTokenStatus: Text;
        TelegramBotTokenStyleExpr: Text;
        AttentionStyleTok: Label 'Unfavorable', Locked = true;
        ConfirmClearBotTokenQst: Label 'Remove the stored Telegram Bot Token?', Comment = 'is-IS=Fjarlægja geymdan Telegram-vélmennislykil?';
        FavorableStyleTok: Label 'Favorable', Locked = true;
        HttpBlockedAndJQNotRunningMsg: Label 'HTTP client requests are blocked and the Orchestrator job queue is not running. Run the setup wizard to fix.', Comment = 'is-IS=HTTP-biðlarabeiðnir eru lokaðar og vinnsluröð stjórnanda er ekki í gangi. Keyrðu uppsetningarleiðsögnina til að laga.';
        HttpBlockedMsg: Label 'HTTP client requests are not enabled for this extension. Run the setup wizard to enable.', Comment = 'is-IS=HTTP-biðlarabeiðnir eru ekki virkar fyrir þessa viðbót. Keyrðu uppsetningarleiðsögnina til að virkja.';
        JQNotRunningMsg: Label 'The Orchestrator job queue is not running. Run the setup wizard to start it.', Comment = 'is-IS=Vinnsluröð stjórnanda er ekki í gangi. Keyrðu uppsetningarleiðsögnina til að ræsa hana.';
        NotSetLbl: Label 'Not set', Comment = 'is-IS=Ekki skráð';
        OpenAppSecretsLbl: Label 'Open App Secrets', Comment = 'is-IS=Opna leyndarmál forrits';
        RunSetupWizardLbl: Label 'Run Setup Wizard', Comment = 'is-IS=Keyra uppsetningarleiðsögn';
        SecretsMissingMsg: Label '%1 Bifrost Orchestrator secrets have no value yet. Secret values are not copied from the published Origo Cloud Events Orchestrator application - enter them once.', Comment = '%1 = number of secrets without a value, is-IS=%1 leyndarmál Bifröst stjórnandans hafa ekkert gildi enn. Gildi leyndarmála eru ekki afrituð úr útgefna forritinu Origo Cloud Events Orchestrator - skráðu þau einu sinni.';
        SetLbl: Label 'Set', Comment = 'is-IS=Skráð';

    trigger OnInit()
    begin
        JobQueueUserEnabled := EnvironmentMgt.IsOnPrem();
    end;

    trigger OnOpenPage()
    begin
        Rec.OnOpenEmptyRec();
        Secrets.RegisterAll();
        ShowSetupWizardNotification();
        ShowSecretsMissingNotification();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        JobQueueManagement.GetJobQueueStatus(JobQueueStatus, JobQueueStyleExpr);
        RefreshSecretStatus();
    end;

    local procedure RefreshSecretStatus()
    begin
        if Secrets.IsTelegramBotTokenSet() then begin
            TelegramBotTokenStatus := SetLbl;
            TelegramBotTokenStyleExpr := FavorableStyleTok;
            exit;
        end;
        TelegramBotTokenStatus := NotSetLbl;
        TelegramBotTokenStyleExpr := AttentionStyleTok;
    end;

    local procedure ShowSetupWizardNotification()
    var
        OrchestratorMgt: Codeunit "Scheduler Mgt ori";
        SetupNotification: Notification;
        JobQueueStatusText: Text;
        JobQueueStyleText: Text;
        HttpEnabled: Boolean;
        JQRunning: Boolean;
    begin
        HttpEnabled := OrchestratorMgt.IsHttpClientEnabled();
        JQRunning := OrchestratorMgt.GetJobQueueStatus(JobQueueStatusText, JobQueueStyleText);

        if HttpEnabled and JQRunning then
            exit;

        SetupNotification.Id := 'a7c3e5d1-2f8b-4e9a-b6d4-3c8f1a9e2b07';
        SetupNotification.Scope := NotificationScope::LocalScope;
        if not HttpEnabled and not JQRunning then
            SetupNotification.Message := HttpBlockedAndJQNotRunningMsg
        else
            if not HttpEnabled then
                SetupNotification.Message := HttpBlockedMsg
            else
                SetupNotification.Message := JQNotRunningMsg;
        SetupNotification.AddAction(RunSetupWizardLbl, Codeunit::"Scheduler Wizard Reg. ori", 'OpenSetupWizard');
        SetupNotification.Send();
    end;

    local procedure ShowSecretsMissingNotification()
    var
        SecretsNotification: Notification;
        MissingCount: Integer;
    begin
        MissingCount := Secrets.CountMissingSecrets();
        if MissingCount = 0 then
            exit;

        SecretsNotification.Id := 'c1f0a4b6-8d52-4a0d-9d61-2b7a4e9f3c88';
        SecretsNotification.Scope := NotificationScope::LocalScope;
        SecretsNotification.Message := StrSubstNo(SecretsMissingMsg, MissingCount);
        SecretsNotification.AddAction(OpenAppSecretsLbl, Codeunit::"Secrets ori", 'OpenAppSecrets');
        SecretsNotification.Send();
    end;
}
