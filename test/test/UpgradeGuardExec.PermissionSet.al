namespace Origo.Bifrost.Orchestrator.Test;

/// <summary>
/// Lets a restrictive test run <c>App Upgrade ori</c> without tabledata on the tables that
/// upgrade steps read and write. Assignable only so the test library can add it.
/// </summary>
permissionset 96429 "Upgrade Guard Exec"
{
    Assignable = true;
    Caption = 'Upgrade Guard Exec', MaxLength = 30, Comment = 'is-IS=Keyrsla uppfærsluvarnar';

    Permissions =
        codeunit "App Upgrade ori" = X;
}
