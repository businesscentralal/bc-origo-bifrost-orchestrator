namespace Origo.Bifrost.Orchestrator.Test;

using Microsoft.Utilities;
using Origo.Bifrost;

/// <summary>
/// Test-only chat provider. It reports configured only when the host test asks it to,
/// so Playbook Card visibility can follow ShowBifrostChat without a live provider.
/// </summary>
codeunit 96477 "Chat Host Provider ori" implements "Chat Provider ori"
{
    SingleInstance = true;

    var
        ConfiguredValue: Boolean;

    /// <summary>Controls the next IsConfigured answer.</summary>
    procedure SetConfigured(NewConfigured: Boolean)
    begin
        ConfiguredValue := NewConfigured;
    end;

    procedure IsConfigured(): Boolean
    begin
        exit(ConfiguredValue);
    end;

    procedure BuildConfigJson(): Text
    begin
        exit('{}');
    end;

    procedure SaveApiKey(ApiKey: Text)
    begin
        if ApiKey = '' then
            exit;
    end;

    procedure SaveServiceApiKey(ApiKey: Text)
    begin
        if ApiKey = '' then
            exit;
    end;

    procedure SendChatMessage(PayloadJson: Text): Text
    begin
        if PayloadJson = '' then
            exit('');
        exit('');
    end;

    procedure ContinueWithToolResults(ConversationState: Text; ToolResultsJson: Text): Text
    begin
        if (ConversationState = '') and (ToolResultsJson = '') then
            exit('');
        exit('');
    end;

    procedure GetAvailableModels(var TempNameValueBuffer: Record "Name/Value Buffer" temporary): Boolean
    begin
        TempNameValueBuffer.DeleteAll();
        exit(false);
    end;

    procedure ClearCredentials()
    begin
        ConfiguredValue := false;
    end;
}
