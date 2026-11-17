namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;

/// <summary>Test-only nested response contract; never calls Iceland or an external provider.</summary>
enumextension 96491 "Condition Response Type ori" extends "Message Type ori"
{
    value(96491; "Test.Orchestrator.ConditionResponse")
    {
        Caption = 'Test.Orchestrator.ConditionResponse', Locked = true;
        Implementation = "Msg Interface ori" = "Condition Response Msg ori",
                         "Msg Contract ori" = "Condition Response Msg ori";
    }
}
