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
}
