namespace Origo.Bifrost.Nornir;

/// <summary>
/// Retry policy enum for Job Queue Orchestrator entries.
/// Controls whether and how many times a failed job queue entry is automatically restarted.
/// </summary>
enum 10035536 "Retry Policy ori"
{
    Extensible = false;

    value(0; Always)
    {
        Caption = 'Always', Comment = 'is-IS=Alltaf';
    }
    value(1; "Three Times")
    {
        Caption = 'Three Times', Comment = 'is-IS=Þrjú sinni';
    }
    value(2; Never)
    {
        Caption = 'Never', Comment = 'is-IS=Aldrei';
    }
}
