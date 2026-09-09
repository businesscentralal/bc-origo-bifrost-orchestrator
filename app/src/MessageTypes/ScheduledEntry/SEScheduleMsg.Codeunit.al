/// <summary>
/// Implements the Orchestrator.Entry.Schedule message type: schedules an
/// orchestrator entry for immediate execution.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035581 "SE Schedule Msg ori" implements "Msg Interface ori"
{
    Access = Internal;

    procedure IsEnabled(): Boolean
    begin
        exit(true);
    end;

    procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    procedure GetDescription(): Text[250]
    var
        DescriptionLbl: Label 'Reschedule an orchestrator entry for immediate execution.', Comment = 'is-IS=EndurÃ¡Ã¦tla Ã¡Ã¦tlunarfÃ¦rslu til tafarlausrar keyrslu.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Outbound);
    end;

    procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Help ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp('Orchestrator.Entry.Schedule'));
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteSchedule(Argument);
    end;

    var
        Handler: Codeunit "SE Msg Handler ori";
}
