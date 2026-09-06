/// <summary>
/// Full administration permissions for Bifrost playbooks.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

permissionset 10035538 "BIFROST PlaybAdm ori"
{
    Caption = 'Bifrost Playbook Admin', Comment = 'is-IS=Bifröst Keðja Stjórnandi';
    Assignable = true;

    Permissions =
        tabledata "JQ Parameter ori" = RIMD,
        tabledata "Playbook ori" = RIMD,
        tabledata "Playbook Condition ori" = RIMD,
        tabledata "Playbook Step ori" = RIMD,
        tabledata "Playbook Instance ori" = RIMD,
        tabledata "Playbook Step Log ori" = RIMD,
        tabledata "Report Request Preset ori" = RIMD;
}
