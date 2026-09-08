/// <summary>
/// Full administration permissions for Bifrost playbooks: the "BIFROST PlaybAdm ori" / "BIFROST
/// PlaybVw ori" pair implements a view-vs-run split for the Playbook feature.
///
/// This set (PlaybAdm) grants every playbook page, read/insert/modify/delete on every
/// playbook-related table, and execute on every codeunit that runs or dispatches a playbook:
/// "Playbook Runner ori" (foreground Run Now and the Job Queue path), "Playbook Step Executor ori"
/// and "Msg Executor ori" (per-step dispatch into Bifrost Foundation), "Playbook JQ Dispatcher ori"
/// (the Job Queue entry point) and "Playbook Log Mgt ori" (writes instance/step log records during
/// a run). Assign it to users who configure, schedule and execute playbooks.
///
/// See "BIFROST PlaybVw ori" for the read-only counterpart and why it withholds every one of these
/// codeunits plus the "Schedule Playbook ori" page.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

permissionset 10035538 "BIFROST PlaybAdm ori"
{
    Caption = 'Bifrost Playbook Admin', Comment = 'is-IS=Bifröst keðjustjórnandi';
    Assignable = true;

    Permissions =
        page "Playbook Card ori" = X,
        page "Playbook Cond. Subpage ori" = X,
        page "Playbook Instance Card ori" = X,
        page "Playbook Instances ori" = X,
        page "Playbook Last Run FB ori" = X,
        page "Playbooks ori" = X,
        page "Playbook Step Log Dtl. FB ori" = X,
        page "Playbook Step Logs Sub. ori" = X,
        page "Playbook Steps Subpage ori" = X,
        page "Playbook Step Template FB ori" = X,
        page "Playbook Template Editor ori" = X,
        page "Schedule Playbook ori" = X,
        tabledata "JQ Parameter ori" = RIMD,
        tabledata "Playbook ori" = RIMD,
        tabledata "Playbook Condition ori" = RIMD,
        tabledata "Playbook Step ori" = RIMD,
        tabledata "Playbook Instance ori" = RIMD,
        tabledata "Playbook Step Log ori" = RIMD,
        tabledata "Report Request Preset ori" = RIMD,
        codeunit "Playbook Runner ori" = X,
        codeunit "Playbook Step Executor ori" = X,
        codeunit "Msg Executor ori" = X,
        codeunit "Playbook JQ Dispatcher ori" = X,
        codeunit "Playbook Log Mgt ori" = X;
}
