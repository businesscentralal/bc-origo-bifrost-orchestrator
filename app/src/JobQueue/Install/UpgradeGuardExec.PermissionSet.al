namespace Origo.Bifrost.Orchestrator;

/// <summary>
/// Execute-only grant for <c>Deferred Upgrade ori</c>, with no tabledata. The restrictive
/// upgrade-skip test adds this set. It lives in this app because a permission set in another
/// app cannot name an <c>Access = Internal</c> codeunit (AL0185), even when
/// <c>internalsVisibleTo</c> lets that app call the codeunit.
/// </summary>
permissionset 10035610 "Upg Guard Exec ori"
{
    Assignable = true;
    Caption = 'Upgrade Guard Exec', MaxLength = 30, Comment = 'is-IS=Keyrsla uppfærsluvarnar';

    Permissions =
        codeunit "Deferred Upgrade ori" = X;
}
