namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035595 "Report SaveAs Msg ori" implements "Msg Interface ori"
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
        DescriptionLbl: Label 'Generates report output (PDF, Excel, Word, XML) using saved preset or provided parameters.', Comment = 'is-IS=Býr til skýrsluúttak (PDF, Excel, Word, XML) út frá vistuðum forsendum eða uppgefnum breytum.';
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
        Argument.SetResponseMarkdown(Help.GetHelp('Orchestrator.Report.SaveAs'));
    end;

    internal procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteSaveAs(Argument);
    end;

    var
        Handler: Codeunit "Report Msg Handler ori";
}
