namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035593 "Report List Msg ori" implements "Msg Interface ori"
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
        DescriptionLbl: Label 'Lists available reports with metadata, excluding obsolete reports.', Comment = 'is-IS=Listar tiltÃ¦kar skÃ½rslur meÃ° lÃ½sigÃ¶gnum, Ãºtilokar Ãºreltar skÃ½rslur.';
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
        Argument.SetResponseMarkdown(Help.GetHelp('Orchestrator.Report.List'));
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteList(Argument);
    end;

    var
        Handler: Codeunit "Report Msg Handler ori";
}
