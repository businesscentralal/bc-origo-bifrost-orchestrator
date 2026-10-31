namespace Origo.Bifrost.Orchestrator;

/// <summary>Removes model traces before any Orchestrator response consumer or persistence point sees them.</summary>
codeunit 10035620 "Playbook Response Scrub ori"
{
    Access = Internal;
    SingleInstance = true;

    var
        AdditionalTypeNames: List of [Text];
        ScrubbedTypeNamesTok: Label 'LLM.Prompt.Ask', Locked = true;

    /// <summary>Removes only the top-level trace property; responses that need no change retain their exact bytes.</summary>
    /// <param name="TypeName">The invariant dispatched type name.</param>
    /// <param name="ResponseText">The response returned to all Orchestrator consumers.</param>
    internal procedure Scrub(TypeName: Text; var ResponseText: Text)
    var
        ResponseJson: JsonObject;
        TypeNames: List of [Text];
    begin
        TypeNames := ScrubbedTypeNamesTok.Split(',');
        if not TypeNames.Contains(TypeName) and not AdditionalTypeNames.Contains(TypeName) then
            exit;
        if not ResponseJson.ReadFrom(ResponseText) then
            exit;
        if not ResponseJson.Contains('trace') then
            exit;
        ResponseJson.Remove('trace');
        ResponseJson.WriteTo(ResponseText);
    end;

    /// <summary>Adds a dependency-free test message type to the scrub list for the current test session.</summary>
    /// <param name="TypeName">The invariant test message type name.</param>
    internal procedure AddTestType(TypeName: Text)
    begin
        if not AdditionalTypeNames.Contains(TypeName) then
            AdditionalTypeNames.Add(TypeName);
    end;

    /// <summary>Clears session test types without changing the production scrub list.</summary>
    internal procedure ClearTestTypes()
    begin
        Clear(AdditionalTypeNames);
    end;
}
