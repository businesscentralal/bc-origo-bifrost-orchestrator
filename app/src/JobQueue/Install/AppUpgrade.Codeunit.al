/// <summary>
/// Handles data upgrades for the Job Queue Orchestrator extension.
/// Each data action is skipped when the upgrading context lacks the tabledata grant.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.DataAdministration;
using System.Environment.Configuration;
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
    begin
        // "Allow HttpClient Requests" is deliberately NOT set here. It is the administrator's
        // consent switch for outbound HTTP; an upgrade that silently turned it back on would undo
        // a decision the administrator made on purpose, without a dialog and without a trace.
        // The setup page and the setup wizard both detect the disabled state and offer to enable
        // it, and every outbound caller checks it before use.
        CreateJobqueueOrchestratorSetup();
        SetDefaultTypeToCodeunit();
        RegisterRetentionPolicies();
        DropLegacySecretKeys();
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
        if not SchedulerSetup.InsertPermission() then
            exit;
        if not JobQueueCategory.ReadPermission() then
            exit;
        if not JobQueueCategory.InsertPermission() then
            exit;

        SchedulerSetup.OnOpenEmptyRec();
    end;

    local procedure SetDefaultTypeToCodeunit()
    var
        ScheduledEntry: Record "Scheduled Entry ori";
    begin
        if not ScheduledEntry.ReadPermission() then
            exit;

        ScheduledEntry.SetRange("Object Type to Run", 0);
        if ScheduledEntry.IsEmpty() then
            exit;
        if not ScheduledEntry.ModifyPermission() then
            exit;

        ScheduledEntry.ModifyAll("Object Type to Run", ScheduledEntry."Object Type to Run"::Codeunit);
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
        if not AppSecret.InsertPermission() then
            exit;
        if not ClientCredentials.ReadPermission() then
            exit;

        Secrets.RegisterAll();
    end;

    /// <summary>
    /// Best-effort cleanup of the values earlier pre-release builds wrote into this extension's own
    /// IsolatedStorage under a random GUID key held in "Scheduler Setup ori"."Telegram Bot Token ID"
    /// (field 60) and "Client Credentials ori"."Client ID" / "Client Secret" (fields 30 and 40).
    /// Those fields were removed when the secrets moved into the Bifröst secret store, so the keys
    /// are only reachable while the platform still exposes the dropped columns; every access is
    /// guarded with <c>FieldExist</c> and the routine is a no-op once the columns are gone.
    /// </summary>
    local procedure DropLegacySecretKeys()
    begin
        DeleteLegacyKeys(Database::"Scheduler Setup ori", 60);
        DeleteLegacyKeys(Database::"Client Credentials ori", 30);
        DeleteLegacyKeys(Database::"Client Credentials ori", 40);
    end;

    local procedure DeleteLegacyKeys(TableId: Integer; FieldNo: Integer)
    var
        RecRef: RecordRef;
        KeyFieldRef: FieldRef;
        StorageKey: Guid;
    begin
        RecRef.Open(TableId);
        if not RecRef.ReadPermission() then begin
            RecRef.Close();
            exit;
        end;
        if not RecRef.WritePermission() then begin
            RecRef.Close();
            exit;
        end;
        if not RecRef.FieldExist(FieldNo) then begin
            RecRef.Close();
            exit;
        end;

        if RecRef.FindSet() then
            repeat
                KeyFieldRef := RecRef.Field(FieldNo);
                StorageKey := KeyFieldRef.Value();
                if not IsNullGuid(StorageKey) then begin
                    // The removed code wrote the key with the default GUID format, braces included.
                    if IsolatedStorage.Delete(Format(StorageKey), DataScope::Company) then;
                    if IsolatedStorage.Delete(Format(StorageKey, 0, 4), DataScope::Company) then;
                end;
            until RecRef.Next() = 0;
        RecRef.Close();
    end;
}
