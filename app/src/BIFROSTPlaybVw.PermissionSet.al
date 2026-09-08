/// <summary>
/// Read-only view permissions for Bifrost playbooks and execution logs: the "BIFROST PlaybVw ori" /
/// "BIFROST PlaybAdm ori" pair implements a view-vs-run split for the Playbook feature.
///
/// This set (PlaybVw) grants the same playbook pages as PlaybAdm - so a viewer can open playbook
/// definitions, steps, conditions, instances and step logs - except "Schedule Playbook ori", which is
/// a run-only wizard: it exists solely to create a recurring Orchestrator Entry, so there is no
/// "view" use for it and Business Central checks page permission whenever a page is opened
/// (including a wizard opened by another page's action), so withholding it concretely blocks
/// scheduling. Tabledata is Read-only on every playbook-related table. No codeunit is granted:
/// "Playbook Runner ori", "Playbook Step Executor ori", "Msg Executor ori" and
/// "Playbook JQ Dispatcher ori" execute or dispatch a playbook and must stay on PlaybAdm only; and
/// "Playbook Log Mgt ori" - though it looks like a logging/reporting helper - only exposes write
/// procedures (CreateInstance, CompleteInstance, LogStep) and elevates its own permission to RIMD on
/// "Playbook Instance ori" / "Playbook Step Log ori", so granting it here would let a "view" user
/// write log data through the codeunit's own elevated permission. All log/instance viewing already
/// works through the plain table Read grants below, feeding the pages directly - no codeunit needed.
///
/// Known residual risk (documented, not fixed here): "Playbook Card ori" (granted below, since it is
/// the main definition view, not exclusively a run page) has a "Run Now" action that calls
/// "Playbook Runner ori" through a plain procedure call, not Codeunit.Run/PAGE.Run. Business Central's
/// codeunit Execute-permission gate is only enforced on those two call shapes, so a PlaybVw user who
/// has page access to "Playbook Card ori" may still be able to trigger Run Now in practice, even
/// though PlaybVw withholds "Playbook Runner ori" execute permission. The codeunit grant is still
/// withheld (least-privilege intent, and it blocks any other call path such as the Job Queue,
/// Codeunit.Run, or a future API/automation entry point). A real UI-level backstop - hiding/disabling
/// Run Now and Schedule for non-admins, or an explicit permission check inside Run Now's OnAction -
/// is out of scope for this permission fix and is flagged as a follow-up.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

permissionset 10035539 "BIFROST PlaybVw ori"
{
    Caption = 'Bifrost Playbook View', Comment = 'is-IS=Bifröst keðjuskoðun';
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
        tabledata "JQ Parameter ori" = R,
        tabledata "Playbook ori" = R,
        tabledata "Playbook Condition ori" = R,
        tabledata "Playbook Step ori" = R,
        tabledata "Playbook Instance ori" = R,
        tabledata "Playbook Step Log ori" = R,
        tabledata "Report Request Preset ori" = R;
}
