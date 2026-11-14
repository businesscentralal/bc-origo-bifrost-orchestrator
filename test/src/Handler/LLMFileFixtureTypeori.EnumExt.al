namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;

/// <summary>Issue #180: test-only file source and inline-file reader. They never claim a production LLM type name.</summary>
enumextension 96483 "LLM File Fixture Type ori" extends "Message Type ori"
{
    value(96482; "Test.Orchestrator.FileSource")
    {
        Caption = 'Test.Orchestrator.FileSource', Locked = true;
        Implementation = "Msg Interface ori" = "LLM File Fixture Msg ori",
                         "Msg Contract ori" = "LLM File Fixture Msg ori";
    }
    value(96483; "Test.Orchestrator.FileReader")
    {
        Caption = 'Test.Orchestrator.FileReader', Locked = true;
        Implementation = "Msg Interface ori" = "LLM File Fixture Msg ori",
                         "Msg Contract ori" = "LLM File Fixture Msg ori";
    }
}
