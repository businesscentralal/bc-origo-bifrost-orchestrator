/// <summary>
/// Implements the Orchestrator.Playbook.Schedule message type: creates an Orchestrator Entry
/// for a Bifrost Playbook using a recurring template and optional notification settings.
/// </summary>
namespace Origo.Bifrost.Nornir;

using Origo.Bifrost;

codeunit 10035574 "Playbook Schedule Msg ori" implements "Msg Interface ori"
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
        DescriptionLbl: Label 'Schedule a Bifrost Playbook as an Orchestrator Entry with a recurring template.', Comment = 'is-IS=Áætla Bifröst keðju sem vinnsluraðarstjórafærslu með endurtekningarsniðmáti.';
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
    /// Returns Markdown help documentation for this message type.
    /// </summary>
    /// <param name="Argument">Message argument that receives the help text as response.</param>
    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "Message Argument ori")
    var
        Help: Codeunit "Help ori";
    begin
        Argument.SetResponseMarkdown(Help.GetHelp('Orchestrator.Playbook.Schedule'));
    end;

    /// <summary>
    /// Executes the message type.
    /// </summary>
    /// <param name="Argument">Message argument carrying the request and receiving the response.</param>
    internal procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Handler.ExecuteSchedule(Argument);
    end;

    var
        Handler: Codeunit "Playbook Msg Handler ori";
}
