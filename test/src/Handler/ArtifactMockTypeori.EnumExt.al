namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;

/// <summary>Registers test-only stand-ins for the artifact chain. They never claim a production message type name.</summary>
enumextension 96463 "Artifact Mock Type ori" extends "Message Type ori"
{
    value(96463; "Test.Orchestrator.Artifact.Storage")
    {
        Caption = 'Test.Orchestrator.Artifact.Storage', Locked = true;
        Implementation = "Msg Interface ori" = "Artifact Mock Msg ori",
                         "Msg Contract ori" = "Artifact Mock Msg ori";
    }
    value(96464; "Test.Orchestrator.Artifact.Ask")
    {
        Caption = 'Test.Orchestrator.Artifact.Ask', Locked = true;
        Implementation = "Msg Interface ori" = "Artifact Mock Msg ori",
                         "Msg Contract ori" = "Artifact Mock Msg ori";
    }
    value(96465; "Test.Orchestrator.Artifact.Sanitize")
    {
        Caption = 'Test.Orchestrator.Artifact.Sanitize', Locked = true;
        Implementation = "Msg Interface ori" = "Artifact Mock Msg ori",
                         "Msg Contract ori" = "Artifact Mock Msg ori";
    }
    value(96466; "Test.Orchestrator.Artifact.Email")
    {
        Caption = 'Test.Orchestrator.Artifact.Email', Locked = true;
        Implementation = "Msg Interface ori" = "Artifact Mock Msg ori",
                         "Msg Contract ori" = "Artifact Mock Msg ori";
    }
}
