namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost.Orchestrator;
/// <summary>
/// A processing-only report that always fails, so tests can prove ExecuteRun returns
/// {status: Error} instead of throwing.
/// </summary>
report 96451 "Test Failing Report"
{
    Caption = 'Bifrost Test Failing Report';
    ProcessingOnly = true;
    UseRequestPage = false;
    UsageCategory = None;
    ApplicationArea = All;

    trigger OnPreReport()
    var
        DeliberateErr: Label 'Deliberate failure from the test report.', Locked = true;
    begin
        Error(DeliberateErr);
    end;
}
