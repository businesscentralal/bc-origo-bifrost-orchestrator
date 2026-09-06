namespace Origo.Bifrost.Orchestrator.Test;

/// <summary>
/// Refreshes the ORCHESTRAT test suite when the test app is republished, so a new or renamed
/// test codeunit is picked up without uninstalling the app first.
/// </summary>
codeunit 96404 "Test Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
        TestInstall: Codeunit "Test Install";
    begin
        TestInstall.SetupTestSuite();
    end;
}
