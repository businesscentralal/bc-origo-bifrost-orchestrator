namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035595 "Report SaveAs Msg ori" implements "Msg Interface ori"
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
        DescriptionLbl: Label 'Generates report output (PDF, Excel, Word, XML) using saved preset or provided parameters.', Comment = 'is-IS=BÃ½r til skÃ½rsluÃºttak (PDF, Excel, Word, XML) Ãºt frÃ¡ vistuÃ°um forsendum eÃ°a uppgefnum breytum.';
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
        Argument.SetResponseMarkdown(Help.GetHelp('Orchestrator.Report.SaveAs'));
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteSaveAs(Argument);
    end;

    var
        Handler: Codeunit "Report Msg Handler ori";
}
