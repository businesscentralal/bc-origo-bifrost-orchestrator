namespace Origo.Bifrost.Orchestrator;

/// <summary>
/// Operations role for Bifrost Orchestrator: monitor, run and restart scheduled entries
/// and read the scheduler setup, without being able to change the setup, the credentials
/// or the recurring templates. Assign it together with a Bifröst Foundation permission
/// set; playbook execution is granted separately by <c>BIFROST PlaybVw ori</c>.
/// </summary>
permissionset 10035537 "BIFROST OrchMgt ori"
{
    Assignable = true;
    Caption = 'Bifrost Orchestrator Mgt.', MaxLength = 30, Comment = 'is-IS=Stjórnun Bifröst stjórnanda';

    Permissions =
        tabledata "Scheduled Entry ori" = RIMD,
        tabledata "Scheduler Setup ori" = R,
        tabledata "Recurring Template ori" = R,
        tabledata "Client Credentials ori" = R,
        tabledata "JQ Parameter ori" = RIMD,
        page "Scheduled Entry Card ori" = X,
        page "Sched. Entry Subform ori" = X,
        page "Scheduler Status ori" = X,
        page "Recurring Templates ori" = X,
        page "Recurring Template ori" = X,
        page "Log Entry ori" = X,
        page "Categories ori" = X,
        page "Entries API ori" = X,
        page "Scheduled Entry API ori" = X,
        codeunit "Scheduler Mgt ori" = X,
        codeunit "Scheduler Handler ori" = X,
        codeunit "Scheduler Events ori" = X,
        codeunit "Scheduler Manual Evt ori" = X,
        codeunit "Schedule Calc ori" = X,
        codeunit "Email Send ori" = X,
        codeunit "Email Notification ori" = X,
        codeunit "None Notification ori" = X,
        codeunit "Telegram Send ori" = X,
        codeunit "Telegram Notif. ori" = X;
}
