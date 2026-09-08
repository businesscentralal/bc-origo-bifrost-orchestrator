namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

/// <summary>
/// Makes Bifrost Orchestrator known to the Bifröst Foundation application registry.
/// Setup notifications live on the Bifröst Setup page only: Foundation aggregates the HTTP client
/// status and the missing secrets of every registered application there and offers a single
/// "Start setup wizard" action. This application therefore raises no notification of its own, it
/// only answers <c>OnRegisterApps</c> with its module id, its name and its setup page.
/// </summary>
codeunit 10035607 "Orchestrator Registration ori"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"App Registry ori", OnRegisterApps, '', false, false)]
    local procedure RegisterApp(var Apps: Record "Registered App ori" temporary)
    var
        AppRegistry: Codeunit "App Registry ori";
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        AppRegistry.AddApp(Apps, AppInfo.Id(), CopyStr(AppInfo.Name(), 1, 250), Page::"Scheduler Setup ori");
    end;
}
