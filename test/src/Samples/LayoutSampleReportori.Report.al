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
            DataItemTableView = where(Number = const(1));
            column(RowNumber; Number) { }
            column(SelectedLayoutName; Selection.GetSelectedLayout()) { }
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
