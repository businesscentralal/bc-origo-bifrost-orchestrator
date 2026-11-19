namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.Environment.Configuration;
using System.Reflection;
using System.Text;
using System.Utilities;

/// <summary>Lists and exports layouts from the same virtual layout list used by the BC Report Layouts page.</summary>
codeunit 10035611 "Report Layout Read Handler ori"
{
    Access = Internal;

    /// <summary>Lists report layouts, optionally limiting results to user-defined layouts.</summary>
    /// <param name="Argument">Request and JSON response.</param>
    procedure ExecuteList(var Argument: Record "Message Argument ori")
    var
        ReportMeta: Record "Report Metadata";
        LayoutList: Record "Report Layout List";
        TenantLayout: Record "Tenant Report Layout";
        Request: JsonObject;
        Response: JsonObject;
        Layout: JsonObject;
        Layouts: JsonArray;
        Value: JsonToken;
        ReportId: Integer;
    begin
        Request := Argument.GetRequestJson();
        ReportId := GetReport(Request, ReportMeta);
        LayoutList.SetRange("Report ID", ReportId);
        if Request.Get('includeExtensionLayouts', Value) then
            if not Value.AsValue().AsBoolean() then
                LayoutList.SetRange("User Defined", true);
        LayoutList.SetLoadFields(Name, Caption, "Layout Format", "User Defined", "Application ID", Description, "Layout Status");
        if LayoutList.FindSet() then
            repeat
                Clear(Layout);
                Layout.Add('name', LayoutList.Name);
                Layout.Add('caption', LayoutList.Caption);
                Layout.Add('format', FormatName(LayoutList."Layout Format"));
                Layout.Add('userDefined', LayoutList."User Defined");
                if LayoutList."User Defined" then
                    Layout.Add('source', 'UserDefined')
                else
                    Layout.Add('source', 'Extension');
                Layout.Add('appId', Format(LayoutList."Application ID", 0, 4));
                TenantLayout.SetLoadFields("Company Name");
                if LayoutList."User Defined" and TenantLayout.Get(ReportId, LayoutList.Name, LayoutList."Application ID") then
                    Layout.Add('companyName', TenantLayout."Company Name")
                else
                    Layout.Add('companyName', '');
                Layout.Add('description', LayoutList.Description);
                Layout.Add('layoutStatus', LayoutList."Layout Status".Names().Get(LayoutList."Layout Status".Ordinals().IndexOf(LayoutList."Layout Status".AsInteger())));
                Layout.Add('isDefault', IsDefaultLayout(LayoutList, ReportMeta));
                Layouts.Add(Layout);
            until LayoutList.Next() = 0;
        Response.Add('status', 'Success');
        Response.Add('reportId', ReportId);
        Response.Add('layouts', Layouts);
        Argument.SetResponseJson(Response);
    end;

    /// <summary>Exports the selected extension or user-defined layout without updating it.</summary>
    /// <param name="Argument">Request and JSON response containing base64 layout bytes.</param>
    procedure ExecuteGet(var Argument: Record "Message Argument ori")
    var
        ReportMeta: Record "Report Metadata";
        LayoutList: Record "Report Layout List";
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        Request: JsonObject;
        Response: JsonObject;
        Value: JsonToken;
        LayoutName: Text;
        ReportId: Integer;
        AppId: Guid;
        Content: InStream;
        Output: OutStream;
    begin
        Request := Argument.GetRequestJson();
        ReportId := GetReport(Request, ReportMeta);
        if not Request.Get('name', Value) then begin
            Argument.AddError("Bifrost Error Code ori"::MissingParameter, MissingNameErr, 'name', '', NameExpectedLbl, NameNextStepLbl);
            Argument.RaiseCollectedErrors("Bifrost Error Code ori"::MissingParameter, MissingNameErr);
        end;
        LayoutName := Value.AsValue().AsText();
        if (LayoutName = '') or (StrLen(LayoutName) > MaxStrLen(LayoutList.Name)) then
            Error(LayoutNotFoundErr, LayoutName, ReportId);
        if Request.Get('appId', Value) then
            if not Evaluate(AppId, Value.AsValue().AsText()) then
                Error(InvalidAppIdErr);
        LayoutList.SetRange("Report ID", ReportId);
        LayoutList.SetRange(Name, LayoutName);
        LayoutList.SetRange("Application ID", AppId);
        LayoutList.SetLoadFields(Name, "Layout Format", "MIME Type", Layout);
        if not LayoutList.FindFirst() then
            Error(LayoutNotFoundErr, LayoutName, ReportId);
        TempBlob.CreateOutStream(Output);
        LayoutList.Layout.ExportStream(Output);
        TempBlob.CreateInStream(Content);
        Response.Add('status', 'Success');
        Response.Add('reportId', ReportId);
        Response.Add('name', LayoutName);
        Response.Add('appId', Format(AppId, 0, 4));
        Response.Add('format', FormatName(LayoutList."Layout Format"));
        Response.Add('mimeType', LayoutMimeType(LayoutList));
        Response.Add('layoutBase64', Base64Convert.ToBase64(Content));
        Argument.SetResponseJson(Response);
    end;

    local procedure GetReport(Request: JsonObject; var ReportMeta: Record "Report Metadata") ReportId: Integer
    var
        Value: JsonToken;
    begin
        if not Request.Get('reportId', Value) then
            Error(MissingReportIdErr);
        ReportId := Value.AsValue().AsInteger();
        ReportMeta.SetLoadFields("DefaultLayoutName", "App ID");
        if not ReportMeta.Get(ReportId) then
            Error(ReportNotFoundErr, ReportId);
    end;

    local procedure IsDefaultLayout(LayoutList: Record "Report Layout List"; ReportMeta: Record "Report Metadata"): Boolean
    var
        Selection: Record "Tenant Report Layout Selection";
        EmptyGuid: Guid;
    begin
        // Current-company selection, then the all-companies selection (blank Company Name), else the
        // built-in default; without writing selection records (#197).
        Selection.SetLoadFields("Layout Name", "App ID");
        // AL evaluates both operands of "or", so the two Gets are separate: the company row must win.
        if not Selection.Get(LayoutList."Report ID", CompanyName(), EmptyGuid) then
            if not Selection.Get(LayoutList."Report ID", '', EmptyGuid) then
                exit((ReportMeta."DefaultLayoutName" = LayoutList.Name) and (ReportMeta."App ID" = LayoutList."Application ID"));
        exit((Selection."Layout Name" = LayoutList.Name) and (Selection."App ID" = LayoutList."Application ID"));
    end;

    local procedure LayoutMimeType(LayoutList: Record "Report Layout List"): Text
    begin
        case LayoutList."Layout Format" of
            LayoutList."Layout Format"::Word:
                exit('application/vnd.openxmlformats-officedocument.wordprocessingml.document');
            LayoutList."Layout Format"::Excel:
                exit('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
            LayoutList."Layout Format"::RDLC:
                exit('application/xml');
        end;
        exit(LayoutList."MIME Type");
    end;

    local procedure FormatName(LayoutFormat: Option RDLC,Word,Excel,Custom): Text
    begin
        case LayoutFormat of
            LayoutFormat::RDLC:
                exit('RDLC');
            LayoutFormat::Word:
                exit('Word');
            LayoutFormat::Excel:
                exit('Excel');
            LayoutFormat::Custom:
                exit('Custom');
        end;
    end;

    var
        MissingReportIdErr: Label 'Request must include "reportId".', Comment = 'is-IS=Beiðni verður að innihalda "reportId".';
        NameExpectedLbl: Label 'A report layout name.', Comment = 'is-IS=Heiti skýrsluútlits.';
        NameNextStepLbl: Label 'Send name from Orchestrator.ReportLayout.List.', Comment = 'is-IS=Sendu name úr Orchestrator.ReportLayout.List.';
        MissingNameErr: Label 'Request must include "name".', Comment = 'is-IS=Beiðni verður að innihalda "name".';
        ReportNotFoundErr: Label 'Report %1 not found.', Comment = 'is-IS=Skýrsla %1 fannst ekki.';
        LayoutNotFoundErr: Label 'Layout %1 not found on report %2.', Comment = 'is-IS=Útlit %1 fannst ekki fyrir skýrslu %2.';
        InvalidAppIdErr: Label 'appId must be a valid GUID.', Comment = 'is-IS=appId verður að vera gilt GUID.';
}
