namespace Origo.Bifrost.Orchestrator.Test;

using Microsoft.Foundation.Reporting;
using System.Utilities;

/// <summary>Own installed RDLC layout fixture for report layout discovery and export tests.</summary>
report 96455 "Layout Sample Report ori"
{
    Caption = 'Layout sample report', Locked = true;
    UseRequestPage = true;
    UsageCategory = None;
    DefaultRenderingLayout = Fixture;

    dataset
    {
        dataitem(Loop; Integer)
        {
            DataItemTableView = where(Number = filter(1..2));
            column(RowNumber; Number) { }
            column(ObservedText; SampleText) { }
            column(ObservedFlag; SampleFlag) { }
            column(ObservedDate; Format(SampleDate, 0, 9)) { }
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

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(FixtureText; SampleText) { ApplicationArea = All; Caption = 'Fixture text', Locked = true; ToolTip = 'Specifies the owned fixture text.', Locked = true; }
                field(FixtureFlag; SampleFlag) { ApplicationArea = All; Caption = 'Fixture flag', Locked = true; ToolTip = 'Specifies the owned fixture flag.', Locked = true; }
                field(FixtureDate; SampleDate) { ApplicationArea = All; Caption = 'Fixture date', Locked = true; ToolTip = 'Specifies the owned fixture date.', Locked = true; }
            }
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
        SampleText: Text;
        SampleFlag: Boolean;
        SampleDate: Date;
}
