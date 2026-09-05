namespace Origo.Bifrost.Nornir.Test;

using Origo.Bifrost;
using Origo.Bifrost.Nornir;
using System.TestTools.TestRunner;

codeunit 96300 "Test Install"
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

    procedure SetupTestSuite()
    var
        ALTestSuite: Record "AL Test Suite";
        TestSuiteMgt: Codeunit "Test Suite Mgt.";
        SuiteName: Code[10];
    begin
        SuiteName := 'DEFAULT';
        if ALTestSuite.Get(SuiteName) then
            ALTestSuite.DELETE(true);

        TestSuiteMgt.CreateTestSuite(SuiteName);
        Commit();
        ALTestSuite.Get(SuiteName);
        TestSuiteMgt.SelectTestMethodsByRange(ALTestSuite, '50000..99999');
    end;
}
