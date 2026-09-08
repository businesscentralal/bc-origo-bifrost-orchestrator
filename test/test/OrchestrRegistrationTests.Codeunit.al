namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;

/// <summary>
/// Covers the registration of Bifrost Orchestrator in the Bifröst Foundation application registry.
/// Setup notifications live on the Bifröst Setup page only, so Foundation has to find this
/// application - and its setup page - through <c>App Registry ori</c>.
/// </summary>
codeunit 96423 "Orchestr Registration Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Secrets: Codeunit "Secrets ori";
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        TestInstall: Codeunit "Test Install";
    begin
        if IsInitialized then
            exit;
        TestInstall.DisableRequestDebugMode();
        IsInitialized := true;
    end;

    [Test]
    procedure OrchestratorIsRegisteredInTheAppRegistry()
    var
        TempRegisteredApp: Record "Registered App ori" temporary;
        AppRegistry: Codeunit "App Registry ori";
    begin
        // [SCENARIO] Bifrost Orchestrator raises no setup notification of its own; Foundation
        // aggregates them on Bifröst Setup and finds this application through the registry

        // [GIVEN] the installed application
        Initialize();

        // [WHEN] the registry is built
        AppRegistry.GetApps(TempRegisteredApp);

        // [THEN] Bifrost Orchestrator is in it, under its own module id
        Assert.IsTrue(TempRegisteredApp.Get(Secrets.GetAppId()), 'Bifrost Orchestrator must register itself in the Bifrost application registry');
        Assert.AreNotEqual('', TempRegisteredApp."App Name", 'A registered application must carry a name');

        // [THEN] and it points at its own setup page, not at the Bifröst Setup page
        Assert.AreEqual(Page::"Scheduler Setup ori", TempRegisteredApp."Setup Page Id", 'The registry must point at the Bifrost Orchestrator setup page');
        Assert.AreNotEqual(AppRegistry.GetFoundationAppId(), TempRegisteredApp."App Id", 'Bifrost Orchestrator must register under its own module id, not under the Foundation one');
    end;
}
