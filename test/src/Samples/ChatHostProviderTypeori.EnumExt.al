namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;

/// <summary>Registers the test chat provider used by Playbook Card host tests.</summary>
enumextension 96476 "Chat Host Provider Type ori" extends "Chat Provider Type ori"
{
    value(96476; "Orch Test Chat")
    {
        Caption = 'Orch Test Chat', Locked = true;
        Implementation = "Chat Provider ori" = "Chat Host Provider ori";
    }
}
