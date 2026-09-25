namespace Origo.Bifrost.Orchestrator;

using System.Environment;
using System.Environment.Configuration;

/// <summary>
/// Re-runs the upgrade steps that nothing else recreates: blank object type on scheduled
/// entries, and legacy isolated-storage key cleanup. Idempotent. A missing tabledata grant
/// skips that step with a warning. No upgrade tag is set, so the next upgrade retries it,
/// and Scheduler Setup calls <c>EnsureDeferredUpgradeData</c> when the page opens.
/// </summary>
codeunit 10035609 "Deferred Upgrade ori"
{
    Access = Internal;

    /// <summary>
    /// Repairs a blank Object Type to Run and deletes legacy isolated-storage keys.
    /// Skips either step, with a warning, when the caller lacks the tabledata grant.
    /// </summary>
    internal procedure EnsureDeferredUpgradeData()
    begin
        SetDefaultTypeToCodeunit();
        DropLegacySecretKeys();
    end;

    local procedure SetDefaultTypeToCodeunit()
    var
        ScheduledEntry: Record "Scheduled Entry ori";
        ObjectTypeSkippedMsg: Label 'Bifrost Orchestrator skipped setting a blank Object Type to Run to Codeunit on Scheduled Entry ori: missing TableData permission. The step runs again on the next upgrade, because no upgrade tag is set, and when Scheduler Setup is opened.', Locked = true;
        ObjectTypeSkippedTok: Label 'O4NJQS-0014', Locked = true;
    begin
        if not ScheduledEntry.ReadPermission() then begin
            LogPermissionSkip(ObjectTypeSkippedTok, Database::"Scheduled Entry ori", 'Read', ObjectTypeSkippedMsg);
            exit;
        end;

        ScheduledEntry.SetRange("Object Type to Run", 0);
        if ScheduledEntry.IsEmpty() then
            exit;
        if not ScheduledEntry.WritePermission() then begin
            LogPermissionSkip(ObjectTypeSkippedTok, Database::"Scheduled Entry ori", 'Write', ObjectTypeSkippedMsg);
            exit;
        end;

        ScheduledEntry.ModifyAll("Object Type to Run", ScheduledEntry."Object Type to Run"::Codeunit);
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
    var
        SchedulerSetup: Record "Scheduler Setup ori";
        ClientCredentials: Record "Client Credentials ori";
        LegacyKeySkippedMsg: Label 'Bifrost Orchestrator skipped deleting legacy isolated storage keys: missing TableData permission. The step runs again on the next upgrade, because no upgrade tag is set, and when Scheduler Setup is opened.', Locked = true;
        LegacyKeySkippedTok: Label 'O4NJQS-0015', Locked = true;
    begin
        // Probe on the record before RecordRef.Open so a missing grant never reaches Open.
        if not SchedulerSetup.ReadPermission() then
            LogPermissionSkip(LegacyKeySkippedTok, Database::"Scheduler Setup ori", 'Read', LegacyKeySkippedMsg)
        else
            if not SchedulerSetup.WritePermission() then
                LogPermissionSkip(LegacyKeySkippedTok, Database::"Scheduler Setup ori", 'Write', LegacyKeySkippedMsg)
            else
                DeleteLegacyKeys(Database::"Scheduler Setup ori", 60);

        if not ClientCredentials.ReadPermission() then begin
            LogPermissionSkip(LegacyKeySkippedTok, Database::"Client Credentials ori", 'Read', LegacyKeySkippedMsg);
            exit;
        end;
        if not ClientCredentials.WritePermission() then begin
            LogPermissionSkip(LegacyKeySkippedTok, Database::"Client Credentials ori", 'Write', LegacyKeySkippedMsg);
            exit;
        end;
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

    local procedure LogPermissionSkip(EventId: Text; TableId: Integer; DeniedPermission: Text; SkipMessage: Text)
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        CustomDimensions.Add('tableId', Format(TableId, 0, 9));
        CustomDimensions.Add('deniedPermission', DeniedPermission);
        Session.LogMessage(EventId, SkipMessage, Verbosity::Warning,
            DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CustomDimensions);
    end;
}
