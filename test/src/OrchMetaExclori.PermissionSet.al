namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.Environment.Configuration;

/// <summary>
/// Removes direct callback Execute and scheduler business grants from the platform baseline for #139.
/// Registration must rely on inherent Execute; metadata rights never imply permission to run the wizard.
/// </summary>
permissionset 96447 "Orch Meta Excl ori"
{
    Assignable = false;
    Permissions = codeunit "Scheduler Wizard Reg. ori" = X,
                  codeunit "Scheduler Mgt ori" = X,
                  page "Scheduler Setup Wizard ori" = X,
                  tabledata "Scheduler Setup ori" = RIMD,
                  tabledata "Scheduled Entry ori" = RIMD,
                  tabledata "Client Credentials ori" = RIMD,
                  tabledata "Setup ori" = RIMD,
                  tabledata "NAV App Setting" = IMD;
}
