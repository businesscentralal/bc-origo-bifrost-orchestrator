namespace Origo.Bifrost.Nornir;

using Origo.Bifrost;

codeunit 10035584 "Playbook Enqueue Msg ori" implements "Msg Interface ori"
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
        DescriptionLbl: Label 'Enqueue a Bifrost Playbook for one-time execution via Job Queue with custom request data.', Comment = 'is-IS=Setja Bifröst keðju í biðröð til einskiptiskeyrslu með sérsniðnum gögnum.';
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
        Argument.SetResponseMarkdown(Help.GetHelp('Orchestrator.Playbook.Enqueue'));
    end;

    internal procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteEnqueue(Argument);
    end;

    var
        Handler: Codeunit "Playbook Msg Handler ori";
}
