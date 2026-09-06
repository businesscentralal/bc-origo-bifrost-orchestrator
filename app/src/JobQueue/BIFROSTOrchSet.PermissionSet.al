namespace Origo.Bifrost.Orchestrator;

/// <summary>
/// Setup role for Bifrost Orchestrator: full access to the scheduler setup, the client
/// credentials and the recurring templates, plus the pages and codeunits needed to run
/// the setup wizard and register secrets. Assign it together with a Bifröst Foundation
/// permission set; playbook authoring is granted separately by
/// <c>BIFROST PlaybAdm ori</c>.
/// </summary>
permissionset 10035536 "BIFROST OrchSet ori"
{
    Assignable = true;
    Caption = 'Bifrost Orchestrator Setup', MaxLength = 30, Comment = 'is-IS=Uppsetning Bifröst stjórnanda';

    Permissions =
        tabledata "Scheduled Entry ori" = RIMD,
        tabledata "Scheduler Setup ori" = RIMD,
        tabledata "Recurring Template ori" = RIMD,
        tabledata "Client Credentials ori" = RIMD,
        tabledata "JQ Parameter ori" = RIMD,
        page "Scheduler Setup ori" = X,
        page "Scheduler Setup Wizard ori" = X,
        page "Scheduler Status ori" = X,
        page "Credentials Card ori" = X,
        page "Credentials List ori" = X,
        page "Recurring Templates ori" = X,
        page "Recurring Template ori" = X,
        page "Scheduled Entry Card ori" = X,
        page "Sched. Entry Subform ori" = X,
        codeunit "Secrets ori" = X,
        codeunit "Scheduler Wizard Reg. ori" = X,
        codeunit "Scheduler Mgt ori" = X,
        codeunit "Scheduler Handler ori" = X,
        codeunit "Scheduler Events ori" = X,
        codeunit "Scheduler Manual Evt ori" = X,
        codeunit "Scheduler API Client ori" = X,
        codeunit "Schedule Calc ori" = X,
        codeunit "Email Send ori" = X,
        codeunit "Email Notification ori" = X,
        codeunit "None Notification ori" = X,
        codeunit "Telegram Send ori" = X,
        codeunit "Telegram Notif. ori" = X;
}
