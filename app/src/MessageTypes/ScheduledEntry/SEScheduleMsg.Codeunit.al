/// <summary>
/// Implements the Orchestrator.Entry.Schedule message type: schedules an
/// orchestrator entry for immediate execution.
/// </summary>
namespace Origo.Bifrost.Nornir;

using Origo.Bifrost;

codeunit 10035581 "SE Schedule Msg ori" implements "Msg Interface ori"
{
    Access = Internal;

    internal procedure IsEnabled(): Boolean
    begin
        exit(true);
    end;

    internal procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    internal procedure GetDescription(): Text[250]
    var
        DescriptionLbl: Label 'Reschedule an orchestrator entry for immediate execution.', Comment = 'is-IS=Enduráætla áætlunarfærslu til tafarlausrar keyrslu.';
    begin
        exit(DescriptionLbl);
    end;

    internal procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Help ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp('Orchestrator.Entry.Schedule'));
    end;

    internal procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteSchedule(Argument);
    end;

    var
        Handler: Codeunit "SE Msg Handler ori";
}
