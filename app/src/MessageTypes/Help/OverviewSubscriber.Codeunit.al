/// <summary>
/// Adds the Help.Orchestrator.Get entry to the global Bifrost message type overview.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035571 "Overview Subscriber ori"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Message Events ori", 'OnAfterCreatingOverview', '', false, false)]
    local procedure OnAfterCreatingOverview(Overview: TextBuilder)
    begin
        Overview.AppendLine('| `Help.Orchestrator.Get` | Job Queue Orchestrator, Playbook Workflow Engine, and Report Services — scheduling, monitoring, declarative workflows with forEach/paging/branching, LLM steps, report generation (PDF/Excel/Word), and Telegram/Email notifications. |');
    end;
}
