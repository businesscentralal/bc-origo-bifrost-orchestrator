/// <summary>
/// Handles data upgrades for the Job Queue Orchestrator extension.
/// Each data action is skipped when the upgrading context lacks the tabledata grant.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.DataAdministration;
using System.Threading;

codeunit 10035538 "App Upgrade ori"
{
    Access = Internal;
    Subtype = Upgrade;

    trigger OnCheckPreconditionsPerCompany()
    var
        JobQueueManagement: Codeunit "Scheduler Mgt ori";
    begin
        // Raises OnRegisterJobQueueCodeunits only. This app writes no rows on that event;
        // subscribers register their own entries and must not be skipped.
        JobQueueManagement.RegisterJobQueues();
    end;

    trigger OnUpgradePerCompany()
    var
        DeferredUpgrade: Codeunit "Deferred Upgrade ori";
    begin
        // "Allow HttpClient Requests" is deliberately NOT set here. It is the administrator's
        // consent switch for outbound HTTP; an upgrade that silently turned it back on would undo
        // a decision the administrator made on purpose, without a dialog and without a trace.
        // The setup page and the setup wizard both detect the disabled state and offer to enable
        // it, and every outbound caller checks it before use.
        CreateJobqueueOrchestratorSetup();
        // No upgrade tag is set for these two steps, so the next upgrade retries a permission skip.
        // Scheduler Setup also calls EnsureDeferredUpgradeData when the page opens.
        DeferredUpgrade.EnsureDeferredUpgradeData();
        RegisterRetentionPolicies();
        RegisterSecrets();
    end;

    local procedure CreateJobqueueOrchestratorSetup()
    var
        SchedulerSetup: Record "Scheduler Setup ori";
        JobQueueCategory: Record "Job Queue Category";
    begin
        // OnOpenEmptyRec: IsEmpty + Insert on Scheduler Setup ori, and Get + Insert on Job Queue Category.
        if not SchedulerSetup.ReadPermission() then
            exit;
        if not SchedulerSetup.WritePermission() then
            exit;
        if not JobQueueCategory.ReadPermission() then
            exit;
        if not JobQueueCategory.WritePermission() then
            exit;

        SchedulerSetup.OnOpenEmptyRec();
    end;

    local procedure RegisterRetentionPolicies()
    var
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
    begin
        // "Retention Policy Allowed Table" is Access = Internal, so this app cannot name it
        // to probe ReadPermission. AddAllowedTable is the public registration API.
        RetenPolAllowedTables.AddAllowedTable(Database::"Playbook Instance ori", 30, 28);
        RetenPolAllowedTables.AddAllowedTable(Database::"Playbook Step Log ori");
    end;

    /// <summary>
    /// Registers every secret of this application in the Bifröst Foundation secret store, so an
    /// environment that was upgraded from a build predating the secret store still lists them.
    /// Skips when the upgrading context cannot read client credentials or write the secret registry.
    /// </summary>
    local procedure RegisterSecrets()
    var
        ClientCredentials: Record "Client Credentials ori";
        AppSecret: Record "App Secret ori";
        Secrets: Codeunit "Secrets ori";
    begin
        // RegisterAll writes App Secret ori, then FindSet on Client Credentials ori.
        if not AppSecret.ReadPermission() then
            exit;
        if not AppSecret.WritePermission() then
            exit;
        if not ClientCredentials.ReadPermission() then
            exit;

        Secrets.RegisterAll();
    end;
}
