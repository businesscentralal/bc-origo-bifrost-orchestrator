namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.DataAdministration;
using System.Threading;

/// <summary>
/// Handles fresh installation of the Bifrost Orchestrator extension: initialises the setup record,
/// lets subscribers register their job queue codeunits and registers the retention policies.
/// Each data action is skipped when the installing context lacks the tabledata grant, so a
/// republish that re-runs install without those permissions does not raise.
/// </summary>
codeunit 10035537 "App Install ori"
{
    Access = Internal;
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        JobQueueManagement: Codeunit "Scheduler Mgt ori";
    begin
        InitializeSchedulerSetup();
        // Raises OnRegisterJobQueueCodeunits only. This app writes no rows on that event;
        // subscribers register their own entries and must not be skipped.
        JobQueueManagement.RegisterJobQueues();
        RegisterRetentionPolicies();
        RegisterSecrets();
    end;

    local procedure InitializeSchedulerSetup()
    var
        SchedulerSetup: Record "Scheduler Setup ori";
        JobQueueCategory: Record "Job Queue Category";
    begin
        // OnOpenEmptyRec: IsEmpty + Insert on Scheduler Setup ori, and Get + Insert on Job Queue Category.
        if not SchedulerSetup.ReadPermission() then
            exit;
        if not SchedulerSetup.InsertPermission() then
            exit;
        if not JobQueueCategory.ReadPermission() then
            exit;
        if not JobQueueCategory.InsertPermission() then
            exit;

        SchedulerSetup.OnOpenEmptyRec();
    end;

    local procedure RegisterRetentionPolicies()
    var
        RetentionPolicyAllowedTable: Record "Retention Policy Allowed Table";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
    begin
        if not RetentionPolicyAllowedTable.ReadPermission() then
            exit;
        if not RetentionPolicyAllowedTable.InsertPermission() then
            exit;

        // field 30 = "Started At" on Playbook Instance ori; min 28 days
        RetenPolAllowedTables.AddAllowedTable(Database::"Playbook Instance ori", 30, 28);
        RetenPolAllowedTables.AddAllowedTable(Database::"Playbook Step Log ori");
    end;

    local procedure RegisterSecrets()
    var
        ClientCredentials: Record "Client Credentials ori";
        AppSecret: Record "App Secret ori";
        Secrets: Codeunit "Secrets ori";
    begin
        // RegisterAll writes App Secret ori, then FindSet on Client Credentials ori.
        if not AppSecret.ReadPermission() then
            exit;
        if not AppSecret.InsertPermission() then
            exit;
        if not ClientCredentials.ReadPermission() then
            exit;

        Secrets.RegisterAll();
    end;
}
