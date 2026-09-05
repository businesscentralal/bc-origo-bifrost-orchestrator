namespace Origo.Bifrost.Nornir;

using Origo.Bifrost;

codeunit 10035593 "Report List Msg ori" implements "Msg Interface ori"
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
        DescriptionLbl: Label 'Lists available reports with metadata, excluding obsolete reports.', Comment = 'is-IS=Listar tiltækar skýrslur með lýsigögnum, útilokar úreltar skýrslur.';
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
        Argument.SetResponseMarkdown(Help.GetHelp('Orchestrator.Report.List'));
    end;

    internal procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteList(Argument);
    end;

    var
        Handler: Codeunit "Report Msg Handler ori";
}
