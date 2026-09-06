namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.Reflection;
using System.Utilities;

codeunit 10035592 "Report Msg Handler ori"
{
    Access = Internal;
    Permissions =
        tabledata "Report Request Preset ori" = RIMD;

    procedure ExecuteList(var Argument: Record "Message Argument ori")
    var
        ReportMeta: Record "Report Metadata";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        ReportsArray: JsonArray;
        ReportJson: JsonObject;
        ProcessingOnlyFilter: Boolean;
        HasProcessingOnlyFilter: Boolean;
        ProcessingOnlyToken: JsonToken;
    begin
        RequestJson := Argument.GetRequestJson();
        if RequestJson.Get('processingOnly', ProcessingOnlyToken) then begin
            HasProcessingOnlyFilter := true;
            ProcessingOnlyFilter := ProcessingOnlyToken.AsValue().AsBoolean();
        end;

        ReportMeta.SetLoadFields(ID, Name, Caption, ProcessingOnly, DefaultLayout, FirstDataItemTableID, UseRequestPage);
        if ReportMeta.FindSet() then
            repeat
                if not HasProcessingOnlyFilter or (ReportMeta.ProcessingOnly = ProcessingOnlyFilter) then begin
                    Clear(ReportJson);
                    ReportJson.Add('id', ReportMeta.ID);
                    ReportJson.Add('name', ReportMeta.Name);
                    ReportJson.Add('caption', ReportMeta.Caption);
                    ReportJson.Add('processingOnly', ReportMeta.ProcessingOnly);
                    ReportJson.Add('defaultLayout', Format(ReportMeta.DefaultLayout));
                    ReportJson.Add('firstDataItemTableId', ReportMeta.FirstDataItemTableID);
                    ReportJson.Add('useRequestPage', ReportMeta.UseRequestPage);
                    ReportsArray.Add(ReportJson);
                end;
            until ReportMeta.Next() = 0;

        ResponseJson.Add('reports', ReportsArray);
        ResponseJson.Add('count', ReportsArray.Count());
        Argument.SetResponseJson(ResponseJson);
    end;

    procedure ExecuteGet(var Argument: Record "Message Argument ori")
    var
        ReportMeta: Record "Report Metadata";
        LayoutList: Record "Report Layout List";
        Preset: Record "Report Request Preset ori";
        AllObj: Record AllObjWithCaption;
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        LayoutsArray: JsonArray;
        LayoutJson: JsonObject;
        PresetJson: JsonObject;
        ReportId: Integer;
        TableName: Text;
    begin
        RequestJson := Argument.GetRequestJson();
        ReportId := GetReportId(RequestJson);

        ReportMeta.SetLoadFields(ID, Name, Caption, ProcessingOnly, DefaultLayout, FirstDataItemTableID, UseRequestPage);
        if not ReportMeta.Get(ReportId) then
            Error(ReportNotFoundErr, ReportId);

        AllObj.SetLoadFields("Object Caption");
        if AllObj.Get(AllObj."Object Type"::Table, ReportMeta.FirstDataItemTableID) then
            TableName := AllObj."Object Caption";

        ResponseJson.Add('id', ReportMeta.ID);
        ResponseJson.Add('name', ReportMeta.Name);
        ResponseJson.Add('caption', ReportMeta.Caption);
        ResponseJson.Add('processingOnly', ReportMeta.ProcessingOnly);
        ResponseJson.Add('defaultLayout', Format(ReportMeta.DefaultLayout));
        ResponseJson.Add('firstDataItemTableId', ReportMeta.FirstDataItemTableID);
        ResponseJson.Add('firstDataItemTableName', TableName);
        ResponseJson.Add('useRequestPage', ReportMeta.UseRequestPage);
        ResponseJson.Add('requestPageUrl', GetUrl(ClientType::Web, CompanyName, ObjectType::Report, ReportId));

        LayoutList.SetRange("Report ID", ReportId);
        LayoutList.SetLoadFields(Name, Caption, "Layout Format", "User Defined");
        if LayoutList.FindSet() then
            repeat
                Clear(LayoutJson);
                LayoutJson.Add('name', LayoutList.Name);
                LayoutJson.Add('caption', LayoutList.Caption);
                LayoutJson.Add('format', Format(LayoutList."Layout Format"));
                LayoutJson.Add('userDefined', LayoutList."User Defined");
                LayoutsArray.Add(LayoutJson);
            until LayoutList.Next() = 0;
        ResponseJson.Add('layouts', LayoutsArray);

        if not Preset.Get(ReportId, UserSecurityId()) then begin
            Preset.Init();
            Preset."Report ID" := ReportId;
            Preset."User Security ID" := UserSecurityId();
            Preset.Description := CopyStr(ReportMeta.Caption, 1, MaxStrLen(Preset.Description));
            Preset.Insert();
        end;

        PresetJson.Add('description', Preset.Description);
        PresetJson.Add('requestPageXml', Preset.GetRequestPageXml());
        PresetJson.Add('hasRequestPageXml', Preset.HasRequestPageXml());
        ResponseJson.Add('preset', PresetJson);
        ResponseJson.Add('presetCapturePageUrl',
            GetUrl(ClientType::Web, CompanyName, ObjectType::Page, Page::"Report Preset Card ori", Preset));

        Argument.SetResponseJson(ResponseJson);
    end;

    procedure ExecuteSaveAs(var Argument: Record "Message Argument ori")
    var
        Preset: Record "Report Request Preset ori";
        ReportMeta: Record "Report Metadata";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        RequestJson: JsonObject;
        OutStr: OutStream;
        ReportId: Integer;
        XmlParams: Text;
        TableView: Text;
        OutputFormat: ReportFormat;
        XmlToken: JsonToken;
        TableViewToken: JsonToken;
    begin
        RequestJson := Argument.GetRequestJson();
        ReportId := GetReportId(RequestJson);

        ReportMeta.SetLoadFields(ProcessingOnly, FirstDataItemTableID);
        if not ReportMeta.Get(ReportId) then
            Error(ReportNotFoundErr, ReportId);
        if ReportMeta.ProcessingOnly then
            Error(ProcessingOnlyErr, ReportId);

        if RequestJson.Get('requestPageXml', XmlToken) then
            XmlParams := XmlToken.AsValue().AsText()
        else
            if Preset.Get(ReportId, UserSecurityId()) then
                XmlParams := Preset.GetRequestPageXml();

        OutputFormat := ParseFormat(RequestJson);

        if ReportMeta.FirstDataItemTableID <> 0 then begin
            RecRef.Open(ReportMeta.FirstDataItemTableID);
            if RequestJson.Get('tableView', TableViewToken) then begin
                TableView := TableViewToken.AsValue().AsText();
                if TableView <> '' then
                    RecRef.SetView(TableView);
            end;
        end;

        TempBlob.CreateOutStream(OutStr);
        Report.SaveAs(ReportId, XmlParams, OutputFormat, OutStr, RecRef);
        if RecRef.Number <> 0 then
            RecRef.Close();

        Argument.SetResponsePdf(TempBlob);
    end;

    procedure ExecuteRun(var Argument: Record "Message Argument ori")
    var
        Preset: Record "Report Request Preset ori";
        ReportMeta: Record "Report Metadata";
        Runner: Codeunit "Report Run Exec ori";
        RecRef: RecordRef;
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        StartTime: DateTime;
        ReportId: Integer;
        XmlParams: Text;
        TableView: Text;
        UsedPreset: Boolean;
        XmlToken: JsonToken;
        TableViewToken: JsonToken;
    begin
        RequestJson := Argument.GetRequestJson();
        ReportId := GetReportId(RequestJson);

        ReportMeta.SetLoadFields(ProcessingOnly, FirstDataItemTableID, Name, Caption);
        if not ReportMeta.Get(ReportId) then
            Error(ReportNotFoundErr, ReportId);
        if not ReportMeta.ProcessingOnly then
            Error(NotProcessingOnlyErr, ReportId);

        if RequestJson.Get('requestPageXml', XmlToken) then
            XmlParams := XmlToken.AsValue().AsText()
        else
            if Preset.Get(ReportId, UserSecurityId()) then begin
                XmlParams := Preset.GetRequestPageXml();
                UsedPreset := XmlParams <> '';
            end;

        if ReportMeta.FirstDataItemTableID <> 0 then begin
            RecRef.Open(ReportMeta.FirstDataItemTableID);
            if RequestJson.Get('tableView', TableViewToken) then begin
                TableView := TableViewToken.AsValue().AsText();
                if TableView <> '' then
                    RecRef.SetView(TableView);
            end;
        end;

        StartTime := CurrentDateTime();

        // Codeunit.Run so a failing report is reported as {status: Error}, not thrown.
        // Work the report already committed survives — see the help text.
        Runner.SetParameters(ReportId, XmlParams, RecRef);
        if Runner.Run() then begin
            ResponseJson.Add('status', 'Success');
            ResponseJson.Add('reportId', ReportMeta.ID);
            ResponseJson.Add('reportName', ReportMeta.Name);
            ResponseJson.Add('caption', ReportMeta.Caption);
            ResponseJson.Add('usedPreset', UsedPreset);
            ResponseJson.Add('tableView', TableView);
            ResponseJson.Add('startedAt', Format(StartTime, 0, 9));
            ResponseJson.Add('durationMs', CurrentDateTime() - StartTime);
        end else begin
            ResponseJson.Add('status', 'Error');
            ResponseJson.Add('reportId', ReportMeta.ID);
            ResponseJson.Add('error', GetLastErrorText());
            ResponseJson.Add('callstack', GetLastErrorCallStack());
            ClearLastError();
        end;

        if RecRef.Number <> 0 then
            RecRef.Close();

        Argument.SetResponseJson(ResponseJson);
    end;

    local procedure GetReportId(RequestJson: JsonObject) ReportId: Integer
    var
        ReportIdToken: JsonToken;
        MissingReportIdErr: Label 'Request must include "reportId".', Comment = 'is-IS=Beiðni verður að innihalda "reportId".';
    begin
        if not RequestJson.Get('reportId', ReportIdToken) then
            Error(MissingReportIdErr);
        ReportId := ReportIdToken.AsValue().AsInteger();
    end;

    local procedure ParseFormat(RequestJson: JsonObject): ReportFormat
    var
        FormatToken: JsonToken;
        FormatText: Text;
    begin
        if not RequestJson.Get('format', FormatToken) then
            exit(ReportFormat::Pdf);

        FormatText := FormatToken.AsValue().AsText().ToUpper();
        case FormatText of
            'PDF':
                exit(ReportFormat::Pdf);
            'EXCEL':
                exit(ReportFormat::Excel);
            'WORD':
                exit(ReportFormat::Word);
            'XML':
                exit(ReportFormat::Xml);
            else
                Error(UnsupportedFormatErr, FormatText);
        end;
    end;

    var
        ReportNotFoundErr: Label 'Report %1 not found.', Comment = 'is-IS=Skýrsla %1 finnst ekki.';
        ProcessingOnlyErr: Label 'Report %1 is processing-only and cannot be saved.', Comment = 'is-IS=Skýrsla %1 er eingöngu keyrsluskýrsla og ekki hægt að vista hana.';
        NotProcessingOnlyErr: Label 'Report %1 produces output and cannot be run as a batch job. Use Orchestrator.Report.SaveAs instead.', Comment = 'is-IS=Skýrsla %1 skilar úttaki og er ekki hægt að keyra sem runuvinnslu. Notaðu Orchestrator.Report.SaveAs í staðinn.';
        UnsupportedFormatErr: Label 'Unsupported format "%1". Use PDF, Excel, Word, or XML.', Comment = 'is-IS=Óstutt snið "%1". Notaðu PDF, Excel, Word eða XML.';
}
