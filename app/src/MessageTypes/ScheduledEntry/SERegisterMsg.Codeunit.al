/// <summary>
/// Implements the Orchestrator.Entry.Register message type: registers a Job Queue Entry
/// as a new orchestrator entry.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035579 "SE Register Msg ori" implements "Msg Interface ori"
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
        DescriptionLbl: Label 'Register a Job Queue Entry as an orchestrator entry.', Comment = 'is-IS=SkrÃ¡ vinnsluraÃ°arfÃ¦rslu sem Ã¡Ã¦tlunarfÃ¦rslu.';
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
        Argument.SetResponseMarkdown(Help.GetHelp('Orchestrator.Entry.Register'));
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteRegister(Argument);
    end;

    var
        Handler: Codeunit "SE Msg Handler ori";
}
