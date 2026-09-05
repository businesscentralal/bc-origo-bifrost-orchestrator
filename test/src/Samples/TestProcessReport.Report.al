namespace Origo.Bifrost.Nornir.Test;

using Origo.Bifrost.Nornir;
using System.Utilities;

/// <summary>
/// A harmless processing-only report used to prove Orchestrator.Report.Run actually
/// executes a batch job. Iterates one Integer row so FirstDataItemTableID is non-zero
/// and the RecordRef branch of ExecuteRun is exercised.
/// </summary>
report 96350 "Test Process Report"
{
    Caption = 'Bifrost Test Process Report';
    ProcessingOnly = true;
    UseRequestPage = false;
    UsageCategory = None;
    ApplicationArea = All;

    dataset
    {
        dataitem(Loop; Integer)
        {
            DataItemTableView = where(Number = const(1));

            trigger OnAfterGetRecord()
            var
                Marker: Record "Test Run Marker";
            begin
                Marker.Init();
                Marker.Source := 'Bifrost Test Process Report';
                Marker.Insert(true);
            end;
        }
    }
}
