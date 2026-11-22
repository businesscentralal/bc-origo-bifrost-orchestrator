namespace Origo.Bifrost.Orchestrator;

using Microsoft.Utilities;
using System.Automation;
using System.Utilities;

/// <summary>
/// Filter handling of the Table Data Management pages (#261): the filter dialog and the four date and time filters.
/// Port of "Tools Filter Mgt" from Tools for Power Users. Only filters are set here; nothing is read or written.
/// </summary>
codeunit 10035601 "Table Data Filter Mgt ori"
{
    Access = Internal;

    /// <summary>Applies the stored filter dialog text and the date and time filters to a RecordRef.</summary>
    /// <param name="RecRef">The RecordRef to filter.</param>
    /// <param name="TempFilterStorage">The stored filter text of the table; blank applies no dialog filter.</param>
    /// <param name="TempFilter">The four date and time filters.</param>
    internal procedure ApplyFilterToRecRef(var RecRef: RecordRef; TempFilterStorage: Record "Name/Value Buffer"; var TempFilter: Record "Table Data Edit ori")
    begin
        if TempFilterStorage.GetValue() <> '' then
            GetFilteredRecord(RecRef, TempFilterStorage.GetValue());
        ApplyFilterToRecRef(RecRef, TempFilter);
    end;

    /// <summary>Applies the date and time filters to the creation and modification time of a RecordRef.</summary>
    /// <param name="RecRef">The RecordRef to filter.</param>
    /// <param name="TempFilter">The four date and time filters.</param>
    internal procedure ApplyFilterToRecRef(var RecRef: RecordRef; var TempFilter: Record "Table Data Edit ori")
    var
        SystemCreatedField: FieldRef;
        SystemModifiedField: FieldRef;
    begin
        case true of
            (TempFilter."Record Created Up To" <> 0DT) and (TempFilter."Record Created After" <> 0DT):
                TempFilter.SetRange("Record Created Filter", TempFilter."Record Created After", TempFilter."Record Created Up To");
            (TempFilter."Record Created Up To" <> 0DT):
                TempFilter.SetRange("Record Created Filter", 0DT, TempFilter."Record Created Up To");
            (TempFilter."Record Created After" <> 0DT):
                TempFilter.SetRange("Record Created Filter", TempFilter."Record Created After", CreateDateTime(DMY2Date(31, 12, 9999), 235959T));
            else
                TempFilter.SetRange("Record Created Filter");
        end;
        case true of
            (TempFilter."Record Modified Up To" <> 0DT) and (TempFilter."Record Modified After" <> 0DT):
                TempFilter.SetRange("Record Modified Filter", TempFilter."Record Modified After", TempFilter."Record Modified Up To");
            (TempFilter."Record Modified Up To" <> 0DT):
                TempFilter.SetRange("Record Modified Filter", 0DT, TempFilter."Record Modified Up To");
            (TempFilter."Record Modified After" <> 0DT):
                TempFilter.SetRange("Record Modified Filter", TempFilter."Record Modified After", CreateDateTime(DMY2Date(31, 12, 9999), 235959T));
            else
                TempFilter.SetRange("Record Modified Filter");
        end;
        SystemCreatedField := RecRef.Field(RecRef.SystemCreatedAtNo);
        SystemCreatedField.SetFilter(TempFilter.GetFilter("Record Created Filter"));
        SystemModifiedField := RecRef.Field(RecRef.SystemModifiedAtNo);
        SystemModifiedField.SetFilter(TempFilter.GetFilter("Record Modified Filter"));
    end;

    /// <summary>Applies the filters of a filter dialog (request page parameters) to a RecordRef.</summary>
    /// <param name="RecordRef">The RecordRef to filter.</param>
    /// <param name="Filters">The filter dialog text; blank applies nothing.</param>
    internal procedure GetFilteredRecord(var RecordRef: RecordRef; Filters: Text)
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        TempBlob: Codeunit "Temp Blob";
        FiltersOutStream: OutStream;
    begin
        if Filters = '' then
            exit;
        TempBlob.CreateOutStream(FiltersOutStream);
        FiltersOutStream.Write(Filters);
        RequestPageParametersHelper.ConvertParametersToFilters(RecordRef, TempBlob);
    end;

    /// <summary>Runs the filter dialog of a table and stores the filter text.</summary>
    /// <param name="TableID">The table to filter.</param>
    /// <param name="HideDialog">When true no dialog is shown and the table is used as is.</param>
    /// <param name="TempFilterStorage">Holds the filter text per table.</param>
    /// <returns>False when the user cancelled or the table is empty and no dialog is shown.</returns>
    internal procedure SetSelectionCriteria(TableID: Integer; HideDialog: Boolean; var TempFilterStorage: Record "Name/Value Buffer"): Boolean
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        RecRef: RecordRef;
        FilterPageBuilder: FilterPageBuilder;
        DefineFiltersTxt: Label 'Define filters...', Comment = 'is-IS=Skilgr. afmörkun...';
        ExistingFilters: Text;
        NewFilters: Text;
    begin
        if HideDialog then begin
            RecRef.Open(TableID);
            exit(RecRef.Count > 0);
        end;
        if TempFilterStorage.Get(TableID) then
            ExistingFilters := TempFilterStorage.GetValue();

        if not RequestPageParametersHelper.BuildDynamicRequestPage(FilterPageBuilder, DefineFiltersTxt, TableID) then
            exit(false);

        if ExistingFilters <> '' then
            if not RequestPageParametersHelper.SetViewOnDynamicRequestPage(FilterPageBuilder, ExistingFilters, DefineFiltersTxt, TableID) then
                exit(false);

        FilterPageBuilder.PageCaption := DefineFiltersTxt;
        if not FilterPageBuilder.RunModal() then
            exit(false);

        NewFilters := RequestPageParametersHelper.GetViewFromDynamicRequestPage(FilterPageBuilder, DefineFiltersTxt, TableID);

        if not TempFilterStorage.Get(TableID) then begin
            TempFilterStorage.Init();
            TempFilterStorage.ID := TableID;
            TempFilterStorage.Insert();
        end;
        TempFilterStorage.SetValue(NewFilters);
        exit(true);
    end;
}
