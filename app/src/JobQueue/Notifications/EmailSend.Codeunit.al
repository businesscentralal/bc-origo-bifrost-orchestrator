/// <summary>
/// Codeunit that sends an email item using the Job Queue Orchestrator email scenario.
/// </summary>
namespace Origo.Bifrost.Nornir;

using System.EMail;

codeunit 10035543 "Email Send ori"
{
    TableNo = "Email Item";

    trigger OnRun()
    begin
        Rec.Send(true, "Email Scenario"::"Scheduler ori");
    end;
}
