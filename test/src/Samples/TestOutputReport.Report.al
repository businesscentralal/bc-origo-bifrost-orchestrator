namespace Origo.Bifrost.Orchestrator.Test;

using System.Utilities;

/// <summary>Produces an XML data set and markers so report-view tests prove exactly which rows ran.</summary>
report 96454 "Test Output Report ori"
{
    Caption = 'Test output report', Locked = true;
    UseRequestPage = false;
    UsageCategory = None;

    dataset
    {
        dataitem(Loop; Integer)
        {
            DataItemTableView = where(Number = filter(1..2));
            column(RowNumber; Number) { }

            trigger OnAfterGetRecord()
            var
                Marker: Record "Test Run Marker";
            begin
                Marker.Init();
                Marker.Source := 'XOUTPUT';
                Marker.Insert(true);
            end;
        }
    }
}
