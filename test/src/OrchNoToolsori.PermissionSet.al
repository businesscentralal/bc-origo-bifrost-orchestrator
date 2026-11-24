namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>
/// Opens the Playbooks parent for negative tool-action tests without granting either tool.
/// Library Assert remains executable while product permissions are lowered.
/// BC 29 checks the parent table read permission before exposing its actions to TestPage.
/// </summary>
permissionset 96448 "Orch NoTools ori"
{
    Assignable = true;
    Caption = 'Playbooks without tools test', Locked = true;
    Permissions = tabledata "Playbook ori" = R,
                  page "Playbooks ori" = X,
                  codeunit "Library Assert" = X;
}
