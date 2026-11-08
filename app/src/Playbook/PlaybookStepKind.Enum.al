namespace Origo.Bifrost.Orchestrator;

/// <summary>Distinguishes dispatched messages from local workspace transformations; zero preserves existing steps.</summary>
enum 10035623 "Playbook Step Kind ori"
{
    Extensible = true;
    /// <summary>Calls an existing Foundation message type.</summary>
    value(0; Message)
    {
        Caption = 'Message', Comment = 'is-IS=Skilaboð';
    }
    /// <summary>Maps JSON fields locally without dispatching a message.</summary>
    value(1; Transform)
    {
        Caption = 'Transform', Comment = 'is-IS=Umbreyting';
    }
}
