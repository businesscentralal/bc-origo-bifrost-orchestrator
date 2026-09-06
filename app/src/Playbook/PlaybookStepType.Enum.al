/// <summary>
/// Whether a false Success condition means the step failed, or is simply the
/// answer to a question.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

enum 10035601 "Playbook Step Type ori"
{
    Extensible = false;

    /// <summary>A false Success condition is a failure and fails the run.</summary>
    value(0; Action)
    {
        Caption = 'Action', Comment = 'is-IS=Aðgerð';
    }
    /// <summary>A false Success condition is a legitimate answer. Routes, but does not fail the run.</summary>
    value(1; Check)
    {
        Caption = 'Check', Comment = 'is-IS=Athugun';
    }
}
