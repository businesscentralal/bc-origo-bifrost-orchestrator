namespace Origo.Bifrost.Nornir;

using Origo.Bifrost;

codeunit 10035594 "Report Get Msg ori" implements "Msg Interface ori"
{
    Access = Internal;
    Permissions =
        tabledata "Report Request Preset ori" = R;

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
        DescriptionLbl: Label 'Returns report metadata, available layouts, and saved request page preset.', Comment = 'is-IS=Skilar lýsigögnum skýrslu, tiltækum útlitum og vistuðum forsendum beiðnisíðu.';
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
        Argument.SetResponseMarkdown(Help.GetHelp('Orchestrator.Report.Get'));
    end;

    internal procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteGet(Argument);
    end;

    var
        Handler: Codeunit "Report Msg Handler ori";
}
