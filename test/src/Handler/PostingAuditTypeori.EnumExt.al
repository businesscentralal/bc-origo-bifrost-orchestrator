namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;

/// <summary>Registers a test-only Ask stand-in. It never claims the production LLM.Prompt.Ask name.</summary>
enumextension 96459 "Posting Audit Type ori" extends "Message Type ori"
{
    value(96459; "Test.Orchestrator.PostingAudit")
    {
        Caption = 'Test.Orchestrator.PostingAudit', Locked = true;
        Implementation = "Msg Interface ori" = "Posting Audit Ask Msg ori",
                         "Msg Contract ori" = "Posting Audit Ask Msg ori";
    }
}
