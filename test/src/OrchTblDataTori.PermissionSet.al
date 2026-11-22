namespace Origo.Bifrost.Orchestrator.Test;

/// <summary>Grants the owned Test Run Marker table to the lowered-permission table data management tests (#261).</summary>
permissionset 96493 "Orch TblDataT ori"
{
    Assignable = true;
    Caption = 'Orchestrator table data test', Locked = true;
    Permissions = tabledata "Test Run Marker" = RIMD;
}
