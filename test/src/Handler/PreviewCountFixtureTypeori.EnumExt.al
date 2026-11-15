namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;

/// <summary>Issue #189: test-only type that answers like an irreversible Foundation type, without touching business data.</summary>
enumextension 96488 "Preview Count Fixture Type ori" extends "Message Type ori"
{
    value(96488; "Test.Orchestrator.PreviewCount")
    {
        Caption = 'Test.Orchestrator.PreviewCount', Locked = true;
        Implementation = "Msg Interface ori" = "Preview Count Fixture Msg ori";
    }
}
