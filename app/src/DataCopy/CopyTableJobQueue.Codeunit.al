namespace Origo.Bifrost.Orchestrator;

using System.Threading;

/// <summary>
/// Job queue entry point of Copy Table Data. When "Record ID to Process" points to a table mapping, that mapping is
/// copied; otherwise every mapping not marked Manual Copy is copied (port of Tools for Power Users "Copy Table Job Queue").
/// </summary>
codeunit 10035591 "Copy Table Job Queue ori"
{
    Access = Public;
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        CopyTableMapping: Record "Copy Table Mapping ori";
        Progress: Codeunit "Copy Table Progress Dialog ori";
        CopyTask: Codeunit "Copy Table Task ori";
    begin
        TableMappingEvents.BeforeUsingTableMapping(Progress);
        TableMappingEvents.BeforeDataCopy();
        if (Rec."Record ID to Process".TableNo() = Database::"Copy Table Mapping ori") and CopyTableMapping.Get(Rec."Record ID to Process") then
            CopyTableMapping.CopyTableData(true)
        else
            CopyTask.StartDataTransfer();
        TableMappingEvents.AfterDataCopy();
    end;

    var
        TableMappingEvents: Codeunit "Copy Table Events ori";
}
