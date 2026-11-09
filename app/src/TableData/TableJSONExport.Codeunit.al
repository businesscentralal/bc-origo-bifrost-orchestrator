namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

/// <summary>Exports readable table rows using Foundation's public serializer and table guards.</summary>
codeunit 10035558 "Table JSON Export ori"
{
    Access = Internal;

    /// <summary>Exports a filtered table with the standard serializer envelope for each row.</summary>
    /// <param name="TableNo">Source table number.</param>
    /// <param name="TableView">Optional Business Central table view.</param>
    /// <param name="FieldNos">Selected fields; an empty list selects all eligible fields.</param>
    /// <returns>A versioned table-data file envelope.</returns>
    procedure ExportTable(TableNo: Integer; TableView: Text; FieldNos: List of [Integer]) Envelope: JsonObject
    var
        TempArgument: Record "Message Argument ori" temporary;
        Serializer: Codeunit "Serializer ori";
        SourceRef: RecordRef;
        Rows: JsonArray;
        Request: JsonObject;
        TableReadErr: Label 'Table %1 cannot be read.', Comment = '%1 = table number, is-IS=Ekki er hægt að lesa töflu %1.';
    begin
        if TempArgument.IsTableReadRestrictedForDataRecords(TableNo) then
            Error(TempArgument.GetRestrictedTableErrorText(TableNo, StrSubstNo(TableReadErr, TableNo), false));
        SourceRef.Open(TableNo);
        SourceRef.ReadIsolation := IsolationLevel::ReadCommitted;
        if TableView <> '' then
            SourceRef.SetView(TableView);
        Request.Add('tableView', SourceRef.GetView(true));
        if not TempArgument.ApplyTableView(Request, SourceRef) then
            Error(TempArgument.GetResponseText());
        if SourceRef.FindSet() then
            repeat
                Rows.Add(Serializer.SerializeToJson(SourceRef, FieldNos));
            until SourceRef.Next() = 0;
        Envelope.Add('format', 'bifrost-table-data');
        Envelope.Add('version', 1);
        Envelope.Add('tableNo', TableNo);
        Envelope.Add('tableName', SourceRef.Name());
        Envelope.Add('rows', Rows);
        SourceRef.Close();
    end;
}
