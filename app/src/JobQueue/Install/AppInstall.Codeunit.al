namespace Origo.Bifrost.Orchestrator;

using System.DataAdministration;

/// <summary>
/// Handles fresh installation of the Bifrost Orchestrator extension: initialises the setup record,
/// lets subscribers register their job queue codeunits and registers the retention policies.
/// </summary>
codeunit 10035537 "App Install ori"
{
    Access = Internal;
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        SchedulerSetup: Record "Scheduler Setup ori";
        JobQueueManagement: Codeunit "Scheduler Mgt ori";
        Secrets: Codeunit "Secrets ori";
    begin
        SchedulerSetup.OnOpenEmptyRec();
        JobQueueManagement.RegisterJobQueues();
        RegisterRetentionPolicies();
        Secrets.RegisterAll();
    end;

    local procedure RegisterRetentionPolicies()
    var
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
    begin
        // field 30 = "Started At" on Playbook Instance ori; min 28 days
        RetenPolAllowedTables.AddAllowedTable(Database::"Playbook Instance ori", 30, 28);
        RetenPolAllowedTables.AddAllowedTable(Database::"Playbook Step Log ori");
    end;
}
