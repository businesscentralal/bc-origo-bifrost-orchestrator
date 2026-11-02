namespace Origo.Bifrost.Orchestrator.Test;

using System.Environment.Configuration;

/// <summary>
/// Platform-only baseline for the restricted licence-admin setup regression (#127).
/// It grants no Bifrost or Orchestrator object permission.
/// </summary>
permissionset 96423 "Orch Test Plat ori"
{
    Assignable = true;
    Caption = 'Orchestrator test platform', Locked = true;
    IncludedPermissionSets = "Guided Experience - View";
    Permissions = tabledata "NAV App Setting" = r;
}
