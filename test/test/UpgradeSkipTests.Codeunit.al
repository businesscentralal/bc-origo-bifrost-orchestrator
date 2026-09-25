namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>
/// No-permission path for the upgrade steps that nothing else recreates. Kept in its own
/// codeunit because lowered permissions persist for the whole codeunit, not per method.
/// </summary>
codeunit 96429 "Upgrade Skip Tests"
{
    Subtype = Test;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    [TestPermissions(TestPermissions::Restrictive)]
    procedure DeferredUpgrade_WithoutTablePermission_SkipsWithoutError()
    var
        ScheduledEntry: Record "Scheduled Entry ori";
        SchedulerSetup: Record "Scheduler Setup ori";
        ClientCredentials: Record "Client Credentials ori";
        AppUpgrade: Codeunit "App Upgrade ori";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
    begin
        // [GIVEN] a caller who can run the upgrade codeunit but cannot read or write the upgraded tables
        LibraryLowerPermissions.SetO365Basic();
        LibraryLowerPermissions.AddPermissionSet('Upgrade Guard Exec');

        Assert.IsFalse(ScheduledEntry.ReadPermission(), 'O365 Basic plus Upgrade Guard Exec must not grant Read on Scheduled Entry ori.');
        Assert.IsFalse(ScheduledEntry.WritePermission(), 'O365 Basic plus Upgrade Guard Exec must not grant Write on Scheduled Entry ori.');
        Assert.IsFalse(SchedulerSetup.ReadPermission(), 'O365 Basic plus Upgrade Guard Exec must not grant Read on Scheduler Setup ori.');
        Assert.IsFalse(SchedulerSetup.WritePermission(), 'O365 Basic plus Upgrade Guard Exec must not grant Write on Scheduler Setup ori.');
        Assert.IsFalse(ClientCredentials.ReadPermission(), 'O365 Basic plus Upgrade Guard Exec must not grant Read on Client Credentials ori.');
        Assert.IsFalse(ClientCredentials.WritePermission(), 'O365 Basic plus Upgrade Guard Exec must not grant Write on Client Credentials ori.');

        // [WHEN] the deferred upgrade steps run
        AppUpgrade.EnsureDeferredUpgradeData();

        // [THEN] they return without error and log ORI-BIF-0424 / ORI-BIF-0425. The next upgrade and Scheduler Setup retry them.
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;
}
