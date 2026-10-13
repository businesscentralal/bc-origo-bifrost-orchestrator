namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;

/// <summary>Own contract fixture; dispatch always fails so guard tests cannot perform work.</summary>
codeunit 96430 "Effect Contract Fixture ori" implements "Msg Interface ori", "Msg Contract ori"
{
    SingleInstance = true;

    var
        EffectJson: Text;
        HasEffect: Boolean;

    /// <summary>Sets the complete effect chapter for the next guard call.</summary>
    procedure Configure(NewEffectJson: Text; NewHasEffect: Boolean)
    begin
        EffectJson := NewEffectJson;
        HasEffect := NewHasEffect;
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    begin
        Clear(Effect);
        if EffectJson <> '' then
            Effect.ReadFrom(EffectJson);
        exit(HasEffect);
    end;

    procedure IsEnabled(): Boolean
    begin
        exit(false);
    end;

    procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    procedure GetDescription(): Text[250]
    begin
        exit('Test-only effect contract');
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Outbound);
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Clear(Argument);
        Error('The effect-contract fixture must never dispatch.');
    end;

    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    begin
        Clear(Envelope);
        exit(false);
    end;

    procedure GetTarget(var Target: JsonArray): Boolean
    begin
        Clear(Target);
        exit(false);
    end;

    procedure GetParameters(var Parameters: JsonArray): Boolean
    begin
        Clear(Parameters);
        exit(false);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    begin
        Clear(Response);
        exit(false);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    begin
        Clear(Errors);
        exit(false);
    end;

    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        Clear(Metering);
        exit(false);
    end;

    procedure GetRelated(var Related: JsonArray): Boolean
    begin
        Clear(Related);
        exit(false);
    end;

    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        Clear(Workflow);
        exit(false);
    end;

    procedure GetExamples(var Examples: JsonArray): Boolean
    begin
        Clear(Examples);
        exit(false);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Clear(Overview);
        exit(false);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Clear(Notes);
        exit(false);
    end;
}
