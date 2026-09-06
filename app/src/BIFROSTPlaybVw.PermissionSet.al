/// <summary>
/// Read-only view permissions for Bifrost playbooks and execution logs.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

permissionset 10035539 "BIFROST PlaybVw ori"
{
    Caption = 'Bifrost Playbook View', Comment = 'is-IS=Bifröst Keðja Skoðun';
    Assignable = true;

    Permissions =
        tabledata "JQ Parameter ori" = R,
        tabledata "Playbook ori" = R,
        tabledata "Playbook Condition ori" = R,
        tabledata "Playbook Step ori" = R,
        tabledata "Playbook Instance ori" = R,
        tabledata "Playbook Step Log ori" = R,
        tabledata "Report Request Preset ori" = R;
}
