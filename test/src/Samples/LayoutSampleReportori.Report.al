namespace Origo.Bifrost.Orchestrator.Test;

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
            DataItemTableView = where(Number = const(1));
            column(RowNumber; Number) { }
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
}
