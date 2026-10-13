namespace Origo.Bifrost.Orchestrator.Test;

using Microsoft.Foundation.Reporting;
using System.Utilities;

/// <summary>Own installed RDLC layout fixture for report layout discovery and export tests.</summary>
report 96455 "Layout Sample Report ori"
{
    Caption = 'Layout sample report', Locked = true;
    UseRequestPage = false;
    UsageCategory = None;
    DefaultRenderingLayout = Fixture;

    dataset
    {
        dataitem(Loop; Integer)
        {
            DataItemTableView = where(Number = filter(1..2));
            column(RowNumber; Number) { }
            column(SelectedLayoutName; Selection.GetSelectedLayout()) { }

            trigger OnAfterGetRecord()
            var
                DeliberateErr: Label 'Deliberate layout sample rendering failure.', Locked = true;
            begin
                if Number = 2 then
                    Error(DeliberateErr);
            end;
        }
    }

    rendering
    {
        layout(Fixture)
        {
            Type = RDLC;
            LayoutFile = 'src/Samples/LayoutSample.rdlc';
            Caption = 'Fixture', Locked = true;
            Summary = 'Owned layout export test fixture', Locked = true;
        }
    }

    var
        Selection: Codeunit "Design-time Report Selection";
}
