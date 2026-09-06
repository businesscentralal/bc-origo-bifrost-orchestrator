namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035596 "Workspace Preview Msg ori" implements "Msg Interface ori"
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
        DescriptionLbl: Label 'Returns the seeded workspace (_sys dates, _who user context) without running any steps.', Comment = 'is-IS=Skilar forsendum vinnusvæðis (_sys dagsetningar, _who notandaupplýsingar) án þess að keyra skref.';
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
        Argument.SetResponseMarkdown(Help.GetHelp('Orchestrator.Workspace.Preview'));
    end;

    internal procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        Workspace: Codeunit "Playbook Workspace ori";
        InitialToken: JsonToken;
        InitialJson: JsonObject;
        ResponseJson: JsonObject;
    begin
        Workspace.Reset();

        if Argument.GetRequestJson().Get('initialRequest', InitialToken) then
            if InitialToken.IsObject() then
                Workspace.SetToken('_initial', InitialToken)
            else
                if InitialJson.ReadFrom(InitialToken.AsValue().AsText()) then
                    Workspace.SetToken('_initial', InitialJson.AsToken());

        ResponseJson := Workspace.GetData();
        ResponseJson.Add('status', 'Success');
        Argument.SetResponseJson(ResponseJson);
    end;
}
