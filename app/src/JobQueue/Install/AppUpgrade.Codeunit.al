/// <summary>
/// Handles data upgrades for the Job Queue Orchestrator extension.
/// </summary>
namespace Origo.Bifrost.Nornir;

using System.DataAdministration;
using System.Environment.Configuration;

codeunit 10035538 "App Upgrade ori"
{
    Access = Internal;
    Subtype = Upgrade;

    trigger OnCheckPreconditionsPerCompany()
    var
        JobQueueManagement: Codeunit "Scheduler Mgt ori";
    begin
        JobQueueManagement.RegisterJobQueues();
    end;

    trigger OnUpgradePerCompany()
    begin
        CreateJobqueueOrchestratorSetup();
        SetDefaultTypeToCodeunit();
        EnableHttpClientRequests();
        RegisterRetentionPolicies();
        DropLegacySecretKeys();
        RegisterSecrets();
    end;

    local procedure CreateJobqueueOrchestratorSetup()
    var
        "Scheduler Setup ori": Record "Scheduler Setup ori";
    begin
        "Scheduler Setup ori".OnOpenEmptyRec();
    end;

    local procedure SetDefaultTypeToCodeunit()
    var
        "Scheduled Entry ori": Record "Scheduled Entry ori";
    begin
        "Scheduled Entry ori".SetRange("Object Type to Run", 0);
        if "Scheduled Entry ori".IsEmpty() then exit;
        "Scheduled Entry ori".ModifyAll("Object Type to Run", "Scheduled Entry ori"."Object Type to Run"::Codeunit);
    end;

    local procedure EnableHttpClientRequests()
    var
        NAVAppSetting: Record "NAV App Setting";
        Info: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        if NAVAppSetting.Get(Info.Id) then
            if not NAVAppSetting."Allow HttpClient Requests" then begin
                NAVAppSetting."Allow HttpClient Requests" := true;
                NAVAppSetting.Modify();
            end;
    end;

    local procedure RegisterRetentionPolicies()
    var
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
    begin
        RetenPolAllowedTables.AddAllowedTable(Database::"Playbook Instance ori", 30, 28);
        RetenPolAllowedTables.AddAllowedTable(Database::"Playbook Step Log ori");
    end;

    /// <summary>
    /// Registers every secret of this application in the Bifröst Foundation secret store, so an
    /// environment that was upgraded from a build predating the secret store still lists them.
    /// </summary>
    local procedure RegisterSecrets()
    var
        Secrets: Codeunit "Secrets ori";
    begin
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
