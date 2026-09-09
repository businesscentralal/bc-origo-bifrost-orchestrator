namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035597 "Report Run Msg ori" implements "Msg Interface ori"
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
        DescriptionLbl: Label 'Runs a processing-only report (batch job) using saved preset or provided parameters.', Comment = 'is-IS=Keyrir vinnsluskÃ½rslu (runuvinnslu) Ãºt frÃ¡ vistuÃ°um forsendum eÃ°a uppgefnum breytum.';
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
        Argument.SetResponseMarkdown(Help.GetHelp('Orchestrator.Report.Run'));
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteRun(Argument);
    end;

    var
        Handler: Codeunit "Report Msg Handler ori";
}
