/// <summary>
/// Extends the Email Scenario enum with the Job Queue Orchestrator scenario.
/// </summary>
namespace Origo.Bifrost.Nornir;

using System.Email;

enumextension 10035535 "EmailScenario.EnumExt ori" extends "Email Scenario"
{
    value(10035535; "Scheduler ori")
    {
        Caption = 'Bifrost Nornir', Comment = 'is-IS=Bifröst Nornir';
    }
}
