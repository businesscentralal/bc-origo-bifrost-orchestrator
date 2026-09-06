namespace Origo.Bifrost.Orchestrator;

using System.DataAdministration;

/// <summary>
/// Handles fresh installation of the Bifrost Orchestrator extension: takes the data of the published
/// Origo Cloud Events Orchestrator app over, initialises the setup record, lets subscribers register
/// their job queue codeunits and registers the retention policies.
/// </summary>
codeunit 10035537 "App Install ori"
{
    Access = Internal;
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        SchedulerSetup: Record "Scheduler Setup ori";
        JobQueueManagement: Codeunit "Scheduler Mgt ori";
        AppTakeover: Codeunit "App Takeover ori";
        Secrets: Codeunit "Secrets ori";
    begin
        // The take-over must run before the setup singleton is created, otherwise the target table
        // is no longer empty and the published app's setup would not be copied.
        AppTakeover.TakeOverAll();
        SchedulerSetup.OnOpenEmptyRec();
        JobQueueManagement.RegisterJobQueues();
        RegisterRetentionPolicies();
        // Runs after the take-over so the client credentials copied from the published app are
        // registered too. Secret values themselves cannot be copied - see CHANGELOG 28.0.0.0.
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
