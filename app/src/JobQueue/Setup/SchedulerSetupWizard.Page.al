namespace Origo.Bifrost.Nornir;

using System.Apps;
using System.Environment.Configuration;

page 10035589 "Scheduler Setup Wizard ori"
{
    PageType = NavigatePage;
    Caption = 'Bifrost Nornir Setup', Comment = 'is-IS=Uppsetning Bifröst stjórnanda';
    ApplicationArea = All;
    Editable = true;
    ContextSensitiveHelpPage = 'scheduler-setup-wizard.html';

    layout
    {
        area(Content)
        {
            group(Step1Welcome)
            {
                Visible = (CurrentStep = 1);
                group(WelcomeHeader)
                {
                    Caption = 'Welcome to Bifrost Nornir', Comment = 'is-IS=Velkomin í Bifröst stjórnanda';
                    ShowCaption = true;
                    InstructionalText = 'This wizard helps you set up the Job Queue Orchestrator for Bifrost. The extension provides automated job queue scheduling, monitoring, restart and error handling, plus a declarative message playbook runner for executing sequences of Bifrost message types.', Comment = 'is-IS=Þessi leiðsögn hjálpar þér að setja upp vinnsluraðara Bifröst. Viðbótin býður upp á sjálfvirka tímasetningu vinnsluraðar, eftirlit, endurræsingu og villameðhöndlun, auk leiðbeinandi keðjukeyrslu til að framkvæma runur af Bifröst skilaboðategundum.';
                }
                group(WelcomeNote)
                {
                    Caption = 'Note', Comment = 'is-IS=Athugasemd';
                    InstructionalText = 'The orchestrator requires a management job queue entry to be running for monitoring and restart capabilities.', Comment = 'is-IS=Stjórnandinn þarf keyrslu stjórnunarvinnsluraðar til eftirlits og endurræsinga.';
                }
            }
            group(Step2Http)
            {
                Visible = (CurrentStep = 2);
                group(HttpHeader)
                {
                    Caption = 'Enable HTTP Client Requests', Comment = 'is-IS=Virkja HTTP-biðlarabeiðnir';
                    InstructionalText = 'The Bifrost Nornir requires outbound HTTP to send notifications and communicate with external services. Please enable Allow HttpClient Requests for this extension.', Comment = 'is-IS=Bifröst stjórnandinn þarf útleið HTTP til að senda tilkynningar og eiga samskipti við ytri þjónustur. Vinsamlegast virkjaðu Leyfa HttpClient-beiðnir fyrir þessa viðbót.';
                }
                group(HttpStatus)
                {
                    Caption = 'Status', Comment = 'is-IS=Staða';
                    field(HttpEnabledField; HttpStatusTxt)
                    {
                        Caption = 'HTTP Client Requests', Comment = 'is-IS=HTTP-biðlarabeiðnir';
                        ToolTip = 'Shows whether HTTP client requests are currently enabled for this extension.', Comment = 'is-IS=Sýnir hvort HTTP-biðlarabeiðnir séu virkar fyrir þessa viðbót.';
                        Editable = false;
                        StyleExpr = HttpStatusStyle;
                    }
                }
            }
            group(Step3JobQueue)
            {
                Visible = (CurrentStep = 3);
                group(JobQueueHeader)
                {
                    Caption = 'Job Queue Orchestrator', Comment = 'is-IS=Vinnsluraðari';
                    InstructionalText = 'The management job queue entry monitors and restarts scheduled jobs. Use the buttons below to start it or open the full setup page for detailed configuration.', Comment = 'is-IS=Stjórnunarvinnsluraðafærslan fylgist með og endurræsir tímasett verk. Notaðu hnappana hér fyrir neðan til að ræsa hana eða opna uppsetningarsíðuna fyrir ítarlega stillingu.';
                }
                group(JobQueueStatusGroup)
                {
                    Caption = 'Status', Comment = 'is-IS=Staða';
                    field(JobQueueStatusField; JobQueueStatusTxt)
                    {
                        Caption = 'Job Queue Orchestrator Status', Comment = 'is-IS=Staða vinnsluraðara';
                        ToolTip = 'Shows whether the management job queue entry is running.', Comment = 'is-IS=Sýnir hvort stjórnunarvinnsluraðafærslan sé í gangi.';
                        Editable = false;
                        StyleExpr = JobQueueStatusStyle;
                    }
                }
            }
            group(Step4Finish)
            {
                Visible = (CurrentStep = 4);
                group(FinishHeader)
                {
                    Caption = 'Setup Complete', Comment = 'is-IS=Uppsetningu lokið';
                    InstructionalText = 'The Bifrost Nornir setup is complete. You can always change these settings later from the Orchestrator Setup page accessible via Bifrost Setup.', Comment = 'is-IS=Uppsetning Bifröst stjórnanda er lokið. Þú getur alltaf breytt þessum stillingum síðar á uppsetningarsíðu stjórnandans sem er aðgengileg í gegnum Bifröst uppsetningu.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionBack)
            {
                Caption = 'Back', Comment = 'is-IS=Til baka';
                Image = PreviousRecord;
                InFooterBar = true;
                Enabled = BackEnabled;

                trigger OnAction()
                begin
                    CurrentStep -= 1;
                    UpdateControls();
                end;
            }
            action(ActionNext)
            {
                Caption = 'Next', Comment = 'is-IS=Áfram';
                Image = NextRecord;
                InFooterBar = true;
                Enabled = NextEnabled;
                Visible = (CurrentStep < 4);

                trigger OnAction()
                begin
                    CurrentStep += 1;
                    OnStepEnter();
                    UpdateControls();
                end;
            }
            action(ActionFinish)
            {
                Caption = 'Finish', Comment = 'is-IS=Ljúka';
                Image = Approve;
                InFooterBar = true;
                Visible = (CurrentStep = 4);

                trigger OnAction()
                begin
                    FinishWizard();
                    CurrPage.Close();
                end;
            }
            action(ActionEnableHttp)
            {
                Caption = 'Enable HTTP Client Requests', Comment = 'is-IS=Virkja HTTP-biðlarabeiðnir';
                Image = Setup;
                InFooterBar = true;
                Visible = (CurrentStep = 2) and (not HttpEnabled) and CanWriteAppSetting;

                trigger OnAction()
                begin
                    EnableHttpClientRequests();
                    CheckHttpEnabled();
                    UpdateControls();
                end;
            }
            action(ActionOpenExtSettings)
            {
                Caption = 'Open Extension Settings', Comment = 'is-IS=Opna stillingar viðbótar';
                Image = Setup;
                InFooterBar = true;
                Visible = (CurrentStep = 2) and (not HttpEnabled) and (not CanWriteAppSetting);

                trigger OnAction()
                begin
                    Hyperlink(GetUrl(ClientType::Web, CompanyName, ObjectType::Page, 2500));
                end;
            }
            action(ActionRefreshHttp)
            {
                Caption = 'Verify', Comment = 'is-IS=Staðfesta';
                Image = Refresh;
                InFooterBar = true;
                Visible = (CurrentStep = 2);

                trigger OnAction()
                begin
                    CheckHttpEnabled();
                    UpdateControls();
                end;
            }
            action(ActionStartJobQueue)
            {
                Caption = 'Start Job Queue', Comment = 'is-IS=Ræsa vinnsluröð';
                Image = Start;
                InFooterBar = true;
                Visible = (CurrentStep = 3) and (not JobQueueRunning);

                trigger OnAction()
                begin
                    StartManagementJobQueue();
                    CheckJobQueueStatus();
                    UpdateControls();
                end;
            }
            action(ActionOpenSetup)
            {
                Caption = 'Open Orchestrator Setup', Comment = 'is-IS=Opna uppsetningu stjórnanda';
                Image = Setup;
                InFooterBar = true;
                Visible = (CurrentStep = 3);

                trigger OnAction()
                begin
                    Page.Run(Page::"Scheduler Setup ori");
                end;
            }
            action(ActionRefreshJQ)
            {
                Caption = 'Verify', Comment = 'is-IS=Staðfesta';
                Image = Refresh;
                InFooterBar = true;
                Visible = (CurrentStep = 3);

                trigger OnAction()
                begin
                    CheckJobQueueStatus();
                    UpdateControls();
                end;
            }
        }
    }

    var
        HttpStatusTxt: Text;
        HttpStatusStyle: Text;
        JobQueueStatusTxt: Text;
        JobQueueStatusStyle: Text;
        HttpEnabled: Boolean;
        JobQueueRunning: Boolean;
        CanWriteAppSetting: Boolean;
        NextEnabled: Boolean;
        BackEnabled: Boolean;
        CurrentStep: Integer;
        HttpEnabledTok: Label 'Enabled', Comment = 'is-IS=Virkt';
        HttpDisabledTok: Label 'Not Enabled - Please enable Allow HttpClient Requests', Comment = 'is-IS=Ekki virkt - Vinsamlegast virkjaðu Leyfa HttpClient-beiðnir';

    trigger OnOpenPage()
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        CurrentStep := 1;
        InitializeData();
        if GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Scheduler Setup Wizard ori") then
            CurrentStep := 4;
        UpdateControls();
    end;

    local procedure InitializeData()
    var
        NavAppSetting: Record "NAV App Setting";
    begin
        CanWriteAppSetting := NavAppSetting.WritePermission();
        CheckHttpEnabled();
        CheckJobQueueStatus();
    end;

    local procedure OnStepEnter()
    begin
        case CurrentStep of
            2:
                CheckHttpEnabled();
            3:
                CheckJobQueueStatus();
        end;
    end;

    local procedure UpdateControls()
    begin
        BackEnabled := CurrentStep > 1;
        case CurrentStep of
            2:
                NextEnabled := HttpEnabled;
            else
                NextEnabled := true;
        end;
    end;

    local procedure CheckHttpEnabled()
    var
        NavAppSetting: Record "NAV App Setting";
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        HttpEnabled := NavAppSetting.Get(AppInfo.Id()) and NavAppSetting."Allow HttpClient Requests";
        if HttpEnabled then begin
            HttpStatusTxt := HttpEnabledTok;
            HttpStatusStyle := 'Favorable';
        end else begin
            HttpStatusTxt := HttpDisabledTok;
            HttpStatusStyle := 'Unfavorable';
        end;
    end;

    local procedure EnableHttpClientRequests()
    var
        NavAppSetting: Record "NAV App Setting";
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        if not NavAppSetting.Get(AppInfo.Id()) then begin
            NavAppSetting.Init();
            NavAppSetting."App ID" := AppInfo.Id();
            NavAppSetting.Insert();
        end;
        NavAppSetting."Allow HttpClient Requests" := true;
        NavAppSetting.Modify();
    end;

    local procedure CheckJobQueueStatus()
    var
        OrchestratorMgt: Codeunit "Scheduler Mgt ori";
    begin
        JobQueueRunning := OrchestratorMgt.GetJobQueueStatus(JobQueueStatusTxt, JobQueueStatusStyle);
    end;

    local procedure StartManagementJobQueue()
    var
        OrchestratorSetup: Record "Scheduler Setup ori";
    begin
        OrchestratorSetup.OnOpenEmptyRec();
        OrchestratorSetup.RestartManagementJobQueue();
    end;

    local procedure FinishWizard()
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"Scheduler Setup Wizard ori");
    end;
}
