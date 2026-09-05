namespace Origo.Bifrost.Nornir;

/// <summary>
/// Runs a processing-only report inside its own transaction scope so the caller can
/// catch the error instead of failing the whole message.
/// </summary>
/// <remarks>
/// A [TryFunction] cannot be used here: it forbids Commit, and most BC batch reports
/// commit internally. Codeunit.Run is the only isolation that tolerates those commits —
/// which is also why work already committed survives a caught error.
/// Do not add a TableNo; it would remove the parameterless Run() this relies on.
/// </remarks>
codeunit 10035598 "Report Run Exec ori"
{
    Access = Internal;

    var
        DataItemRecRef: RecordRef;
        ReportId: Integer;
        XmlParams: Text;

    trigger OnRun()
    begin
        if DataItemRecRef.Number() <> 0 then
            Report.Execute(ReportId, XmlParams, DataItemRecRef)
        else
            Report.Execute(ReportId, XmlParams);
    end;

    procedure SetParameters(NewReportId: Integer; NewXmlParams: Text; var NewRecRef: RecordRef)
    begin
        ReportId := NewReportId;
        XmlParams := NewXmlParams;
        DataItemRecRef := NewRecRef;
    end;
}
