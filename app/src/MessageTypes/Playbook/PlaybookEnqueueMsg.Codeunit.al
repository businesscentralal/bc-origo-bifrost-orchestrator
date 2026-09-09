namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035584 "Playbook Enqueue Msg ori" implements "Msg Interface ori"
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
        DescriptionLbl: Label 'Enqueue a Bifrost Playbook for one-time execution via Job Queue with custom request data.', Comment = 'is-IS=Setja BifrÃ¶st keÃ°ju Ã­ biÃ°rÃ¶Ã° til einskiptiskeyrslu meÃ° sÃ©rsniÃ°num gÃ¶gnum.';
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
        Argument.SetResponseMarkdown(Help.GetHelp('Orchestrator.Playbook.Enqueue'));
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteEnqueue(Argument);
    end;

    var
        Handler: Codeunit "Playbook Msg Handler ori";
}
