namespace Origo.Bifrost.Orchestrator;

/// <summary>
/// Runs Copy Table Data for one mapping, or for every mapping not marked Manual Copy, parents before children
/// (port of Tools for Power Users "Copy Table Task").
/// </summary>
codeunit 10035578 "Copy Table Task ori"
{
    Access = Public;

    trigger OnRun()
    begin
        StartDataTransfer();
    end;

    /// <summary>Copies the data of one table mapping with its copy method.</summary>
    /// <param name="CopyTableMapping">The table mapping to copy.</param>
    /// <param name="Progress">The progress dialog of the run.</param>
    /// <param name="UpdateCopyCount">True to count every copied record.</param>
    procedure CopyTableData(var CopyTableMapping: Record "Copy Table Mapping ori"; var Progress: Codeunit "Copy Table Progress Dialog ori"; UpdateCopyCount: Boolean)
    var
        IsHandled: Boolean;
        CopyTableDataInterface: Interface "Copy Table Data Transfer ori";
    begin
        OnBeforeCopyTableData(CopyTableMapping, Progress, IsHandled);
        if IsHandled then
            exit;

        CopyTableDataInterface := CopyTableMapping."Copy Method";
        CopyTableDataInterface.TransferTableData(CopyTableMapping, Progress, UpdateCopyCount);
        OnAfterCopyTableData(CopyTableDataInterface, CopyTableMapping, Progress);
    end;

    /// <summary>Copies every table mapping not marked Manual Copy, parents before children.</summary>
    procedure StartDataTransfer()
    var
        CopyTableMapping: Record "Copy Table Mapping ori";
        Progress: Codeunit "Copy Table Progress Dialog ori";
        IsHandled: Boolean;
        TableDataTok: Label 'Table Data', Comment = 'is-IS=Töflugögn';
    begin
        OnBeforeStartDataTransfer(IsHandled);
        if IsHandled then
            exit;

        CopyTableMapping.SetRange("Manual Copy", false);
        Progress.OpenCopyCountMax(TableDataTok, CopyTableMapping.Count());
        CopyChildTables(0, Progress);
        OnAfterStartDataTransfer();
    end;

    local procedure CopyChildTables(ParentSourceTableID: Integer; var Progress: Codeunit "Copy Table Progress Dialog ori")
    var
        CopyTableMapping: Record "Copy Table Mapping ori";
    begin
        CopyTableMapping.SetCurrentKey("Parent Source Table ID", "Has Children", "Destination Table ID");
        CopyTableMapping.SetRange("Manual Copy", false);
        CopyTableMapping.SetRange("Parent Source Table ID", ParentSourceTableID);
        CopyTableMapping.SetAutoCalcFields("Source Table Caption");
        if CopyTableMapping.FindSet() then
            repeat
                Progress.UpdateType(CopyTableMapping."Source Table Caption");
                CopyTableData(CopyTableMapping, Progress, false);
                Progress.UpdateCopyCount();
                Commit();
            until CopyTableMapping.Next() = 0;

        if CopyTableMapping.FindSet() then
            repeat
                CopyChildTables(CopyTableMapping."Source Table ID", Progress);
            until CopyTableMapping.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTableData(CopyTableDataInterface: Interface "Copy Table Data Transfer ori"; var CopyTableMapping: Record "Copy Table Mapping ori"; var Progress: Codeunit "Copy Table Progress Dialog ori")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterStartDataTransfer()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyTableData(var CopyTableMapping: Record "Copy Table Mapping ori"; var Progress: Codeunit "Copy Table Progress Dialog ori"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStartDataTransfer(var IsHandled: Boolean)
    begin
    end;
}
