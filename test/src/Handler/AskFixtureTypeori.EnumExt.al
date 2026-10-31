namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;

/// <summary>Registers a test-only type; it never claims the production LLM.Prompt.Ask enum name.</summary>
enumextension 96444 "Ask Fixture Type ori" extends "Message Type ori"
{
    value(96444; "Test.Orchestrator.Ask")
    {
        Caption = 'Test.Orchestrator.Ask', Locked = true;
        Implementation = "Msg Interface ori" = "Ask Fixture Msg ori";
    }
}
