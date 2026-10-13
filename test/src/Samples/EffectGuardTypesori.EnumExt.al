namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;

/// <summary>Stable test-only contract and no-contract types for fail-closed validation.</summary>
enumextension 96406 "Effect Guard Types ori" extends "Message Type ori"
{
    value(96406; "Test.Effect.Missing")
    {
        Caption = 'Test.Effect.Missing', Locked = true;
        Implementation = "Msg Interface ori" = "Effect Contract Fixture ori";
    }
    value(96407; "Test.Effect.Contract")
    {
        Caption = 'Test.Effect.Contract', Locked = true;
        Implementation = "Msg Interface ori" = "Effect Contract Fixture ori", "Msg Contract ori" = "Effect Contract Fixture ori";
    }
}
