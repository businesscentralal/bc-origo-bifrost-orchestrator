namespace Origo.Bifrost.Orchestrator;

/// <summary>
/// Raises the events around the use of table mappings and around a data copy
/// (port of Tools for Power Users "Copy Table Events").
/// </summary>
codeunit 10035623 "Copy Table Events ori"
{
    Access = Public;

    /// <summary>Raised when a table mapping list or job opens, before any mapping is used.</summary>
    /// <param name="Progress">The progress dialog of the run.</param>
    procedure BeforeUsingTableMapping(var Progress: Codeunit "Copy Table Progress Dialog ori")
    begin
        OnBeforeBeforeUsingTableMapping(Progress);
    end;

    /// <summary>Raised before a data copy starts.</summary>
    procedure BeforeDataCopy()
    begin
        OnBeforeDataCopy();
    end;

    /// <summary>Raised after a data copy finishes.</summary>
    procedure AfterDataCopy()
    begin
        OnAfterDataCopy();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBeforeUsingTableMapping(var Progress: Codeunit "Copy Table Progress Dialog ori")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDataCopy()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDataCopy()
    begin
    end;
}
