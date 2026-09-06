/// <summary>
/// Implements the Help.Orchestrator.Get message type, returning an AI-friendly overview of all
/// Job Queue and Playbook Workflow message types. Delegates the document to codeunit "Help ori".
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

codeunit 10035570 "Help Get Impl ori" implements "Msg Interface ori"
{
    Access = Internal;

    /// <summary>
    /// Determines whether this message type is enabled.
    /// </summary>
    /// <returns>True; this message type is always enabled.</returns>
    internal procedure IsEnabled(): Boolean
    begin
        exit(true);
    end;

    /// <summary>
    /// Returns the table ID used to filter records for this message type.
    /// </summary>
    /// <returns>Zero; this message type is not bound to a table.</returns>
    internal procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    /// <summary>
    /// Returns a human-readable description of this message type.
    /// </summary>
    /// <returns>Description text.</returns>
    internal procedure GetDescription(): Text[250]
    var
        DescriptionLbl: Label 'AI-friendly overview of all Job Queue + Playbook Workflow message types with setup guide via Data.Records.Set/Get.', Comment = 'is-IS=Yfirlit fyrir gervigreind yfir allar Job Queue + keðjuvinnslu skilaboðategundir með uppsetningarleiðbeiningum um Data.Records.Set/Get.';
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>
    /// Returns the message direction for this message type.
    /// </summary>
    /// <returns>Outbound direction.</returns>
    internal procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Outbound);
    end;

    /// <summary>
    /// Returns the Markdown overview document as the message help.
    /// </summary>
    /// <param name="Argument">Message argument that receives the help text as response.</param>
    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Help ori";
    begin
        Argument.SetResponseMarkdown(Help.GetOverview());
    end;

    /// <summary>
    /// Executes the message type, returning the overview document as a JSON result.
    /// </summary>
    /// <param name="Argument">Message argument carrying the request and receiving the response.</param>
    internal procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Help ori";
        ResponseJson: JsonObject;
        ResultJson: JsonObject;
    begin
        Argument.AssertVersion1();

        ResultJson.Add('messageType', 'Help.Orchestrator.Get');
        ResultJson.Add('format', 'markdown');
        ResultJson.Add('markdown', Help.GetOverview());

        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('result', ResultJson);
        Argument.SetResponseJson(ResponseJson);
        Argument."Content Type" := 'text/json';
    end;
}
