namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using System.TestTools.TestRunner;

/// <summary>
/// Registers the Bifrost Orchestrator test codeunits in their own AL Test Suite so a test run
/// can select them without touching the shared DEFAULT suite of the container, where several
/// Bifröst and Cloud Events test apps are installed side by side.
/// </summary>
codeunit 96400 "Test Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        DisableRequestDebugMode();
        SetupTestSuite();
    end;

    /// <summary>Prevents session-starting log writes that break test isolation.</summary>
    procedure DisableRequestDebugMode()
    var
        Setup: Record "Setup ori";
    begin
        if not Setup.Get() then begin
            Setup.Init();
            Setup.Insert();
        end;
        if Setup."Request Debug Mode" then begin
            Setup."Request Debug Mode" := false;
            Setup.Modify();
        end;
    end;

    /// <summary>
    /// Rebuilds the <c>ORCHESTRAT</c> test suite from this test app's own object range
    /// (96400-96499). The suite name is the one tools/Run-BifrostTests.ps1 derives from the
    /// test app name. Safe to call repeatedly.
    /// </summary>
    procedure SetupTestSuite()
    var
        ALTestSuite: Record "AL Test Suite";
        TestSuiteMgt: Codeunit "Test Suite Mgt.";
        SuiteName: Code[10];
    begin
        SuiteName := 'ORCHESTRAT';
        if ALTestSuite.Get(SuiteName) then
            ALTestSuite.Delete(true);

        TestSuiteMgt.CreateTestSuite(SuiteName);
        Commit();
        ALTestSuite.Get(SuiteName);
        TestSuiteMgt.SelectTestMethodsByRange(ALTestSuite, '96400..96499');
    end;
}
