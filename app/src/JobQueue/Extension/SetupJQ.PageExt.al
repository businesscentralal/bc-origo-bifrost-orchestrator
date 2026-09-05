/// <summary>
/// Extends the Bifrost Setup page with navigation to the Job Queue Orchestrator Setup
/// and shows a notification when HTTP is blocked or the orchestrator job queue is not running.
/// </summary>
namespace Origo.Bifrost.Nornir;

using Origo.Bifrost;

pageextension 10035537 "Setup JQ ori" extends "Setup ori"
{
    actions
    {
        addlast(Navigation)
        {
            group(Orchestrator)
            {
                Caption = 'Orchestrator', Comment = 'is-IS=Stjórnandi';
                action(JQOrchestratorSetup)
                {
                    ApplicationArea = All;
                    Caption = 'Job Queue Orchestrator Setup', Comment = 'is-IS=Uppsetning vinnsluraðara';
                    Image = Setup;
                    RunObject = page "Scheduler Setup ori";
                    ToolTip = 'Configure job queue scheduling, monitoring, and restart policies.', Comment = 'is-IS=Stilla tímasetningu vinnsluraðar, eftirlit og endurræsingarstefnur.';
                }
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
            }
        }
    }

    trigger OnOpenPage()
    begin
        ShowSetupWizardNotification();
    end;

    local procedure ShowSetupWizardNotification()
    var
        OrchestratorMgt: Codeunit "Scheduler Mgt ori";
        SetupNotification: Notification;
        JobQueueStatus: Text;
        JobQueueStyle: Text;
        HttpEnabled: Boolean;
        JQRunning: Boolean;
    begin
        HttpEnabled := OrchestratorMgt.IsHttpClientEnabled();
        JQRunning := OrchestratorMgt.GetJobQueueStatus(JobQueueStatus, JobQueueStyle);

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

    var
        HttpBlockedAndJQNotRunningMsg: Label 'HTTP client requests are blocked and the Orchestrator job queue is not running. Run the setup wizard to fix.', Comment = 'is-IS=HTTP-biðlarabeiðnir eru lokaðar og vinnsluröð stjórnanda er ekki í gangi. Keyrðu uppsetningarleiðsögnina til að laga.';
        HttpBlockedMsg: Label 'HTTP client requests are not enabled for this extension. Run the setup wizard to enable.', Comment = 'is-IS=HTTP-biðlarabeiðnir eru ekki virkar fyrir þessa viðbót. Keyrðu uppsetningarleiðsögnina til að virkja.';
        JQNotRunningMsg: Label 'The Orchestrator job queue is not running. Run the setup wizard to start it.', Comment = 'is-IS=Vinnsluröð stjórnanda er ekki í gangi. Keyrðu uppsetningarleiðsögnina til að ræsa hana.';
        RunSetupWizardLbl: Label 'Run Setup Wizard', Comment = 'is-IS=Keyra uppsetningarleiðsögn';
}
