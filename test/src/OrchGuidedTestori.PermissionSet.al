namespace Origo.Bifrost.Orchestrator.Test;

using System.Environment.Configuration;
using System.Security.AccessControl;

/// <summary>
/// Standard BC basic-read identity with metadata registration rights for the real Assisted Setup publisher (#139).
/// No Orchestrator, Foundation business, SUPER, wizard or HTTP-setting write permission is added.
/// </summary>
permissionset 96446 "Orch Guided Test ori"
{
    Assignable = true;
    Caption = 'Assisted setup test identity', Locked = true;
    IncludedPermissionSets = "D365 Basic - Read", "Guided Experience - View";
    ExcludedPermissionSets = "Orch Meta Excl ori";
}
