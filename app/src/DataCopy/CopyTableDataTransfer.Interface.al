namespace Origo.Bifrost.Orchestrator;

/// <summary>
/// A copy method for Copy Table Data. Extend the "Copy Table Data Transfer ori" enum to add one
/// (port of Tools for Power Users "Copy Table Data Transfer").
/// </summary>
interface "Copy Table Data Transfer ori"
{
    /// <summary>Called before a copy run starts.</summary>
    /// <param name="Progress">The progress dialog of the run.</param>
    procedure StartDataTransfer(var Progress: Codeunit "Copy Table Progress Dialog ori");

    /// <summary>Copies the data of one table mapping.</summary>
    /// <param name="TableMapping">The table mapping to copy.</param>
    /// <param name="Progress">The progress dialog of the run.</param>
    /// <param name="UpdateCopyCount">True to count every copied record in the progress dialog.</param>
    procedure TransferTableData(var TableMapping: Record "Copy Table Mapping ori"; var Progress: Codeunit "Copy Table Progress Dialog ori"; UpdateCopyCount: Boolean);
}
