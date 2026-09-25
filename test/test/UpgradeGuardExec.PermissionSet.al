namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost.Orchestrator;

/// <summary>
/// Lets a restrictive test run <c>Deferred Upgrade ori</c> without tabledata on the tables that
/// upgrade steps read and write. Assignable only so the test library can add it.
/// The using is required: without it the compiler reports AL0185 for the internal codeunit.
/// </summary>
permissionset 96429 "Upgrade Guard Exec"
{
    Assignable = true;
    Caption = 'Upgrade Guard Exec', MaxLength = 30, Comment = 'is-IS=Keyrsla uppfærsluvarnar';

    Permissions =
        codeunit "Deferred Upgrade ori" = X;
}
