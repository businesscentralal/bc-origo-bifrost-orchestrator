namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035594 "Report Get Msg ori" implements "Msg Interface ori"
{
    Access = Internal;
    Permissions =
        tabledata "Report Request Preset ori" = R;

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
        DescriptionLbl: Label 'Returns report metadata, available layouts, and saved request page preset.', Comment = 'is-IS=Skilar lÃ½sigÃ¶gnum skÃ½rslu, tiltÃ¦kum Ãºtlitum og vistuÃ°um forsendum beiÃ°nisÃ­Ã°u.';
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
        Argument.SetResponseMarkdown(Help.GetHelp('Orchestrator.Report.Get'));
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteGet(Argument);
    end;

    var
        Handler: Codeunit "Report Msg Handler ori";
}
