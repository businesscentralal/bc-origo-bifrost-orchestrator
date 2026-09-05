/// <summary>
/// What a playbook condition governs. Start gates entry, Success classifies the
/// outcome and picks the branch, Error fails the run without changing the branch.
/// </summary>
namespace Origo.Bifrost.Nornir;

enum 10035600 "Playbook Cond. Type ori"
{
    Extensible = false;

    /// <summary>Evaluated against the workspace before the step runs. False = step is Cancelled.</summary>
    value(0; Start)
    {
        Caption = 'Start', Comment = 'is-IS=Upphaf';
    }
    /// <summary>Evaluated against the step response. Picks the success or failure branch.</summary>
    value(1; Success)
    {
        Caption = 'Success', Comment = 'is-IS=Árangur';
    }
    /// <summary>Evaluated after the step. True = mark the run failed, branch unchanged.</summary>
    value(2; Error)
    {
        Caption = 'Error', Comment = 'is-IS=Villa';
    }
}
