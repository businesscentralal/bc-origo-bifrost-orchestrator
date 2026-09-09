namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.Environment.Configuration;
using System.Reflection;
using System.Text;
using System.Utilities;

/// <summary>
/// Implements Orchestrator.ReportLayout.Set.
/// </summary>
/// <remarks>
/// Architecture guard (issue #5): never route through Bifrost Data.Records.Set on
/// Tenant Report Layout (2000000232) or Tenant Report Layout Selection (2000000233).
/// Codeunit 9660 "Report Layouts Impl." is Access=Internal (microsoft/ALAppExtensions#26246),
/// so the supported bytes path available to extensions is Layout.ImportStream on
/// table "Tenant Report Layout" — the same Media import the Report Layouts page uses
/// under the hood for user-defined layouts.
/// setAsDefault is deferred: SetDefaultReportLayoutSelection is also Internal; ship
/// Orchestrator.ReportLayout.SetDefault later if product needs it.
/// </remarks>
codeunit 10035600 "Report Layout Handler ori"
{
    Access = Internal;
    Permissions =
        tabledata "Tenant Report Layout" = RIMD,
        tabledata "Report Metadata" = R;

    procedure ExecuteSet(var Argument: Record "Message Argument ori")
    var
        TenantReportLayout: Record "Tenant Report Layout";
        ReportMeta: Record "Report Metadata";
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        ReportId: Integer;
        LayoutName: Text[250];
        Description: Text[250];
        CompanyNameValue: Text[30];
        LayoutFormatText: Text;
        LayoutBase64: Text;
        ActionText: Text;
        LayoutFormat: Option RDLC,Word,Excel,Custom;
        OutStr: OutStream;
        InStr: InStream;
        EmptyGuid: Guid;
        Replacing: Boolean;
        Token: JsonToken;
    begin
        RequestJson := Argument.GetRequestJson();
        ReportId := GetRequiredInteger(RequestJson, 'reportId');
        LayoutName := CopyStr(GetRequiredText(RequestJson, 'name'), 1, MaxStrLen(LayoutName));
        LayoutFormatText := GetRequiredText(RequestJson, 'layoutFormat');
        LayoutBase64 := GetRequiredText(RequestJson, 'layoutBase64');
        LayoutFormat := ParseLayoutFormat(LayoutFormatText, ReportId);

        if RequestJson.Get('description', Token) then
            Description := CopyStr(Token.AsValue().AsText(), 1, MaxStrLen(Description))
        else
            Description := LayoutName;

        if RequestJson.Get('companyName', Token) then
            CompanyNameValue := CopyStr(Token.AsValue().AsText(), 1, MaxStrLen(CompanyNameValue));

        // setAsDefault deferred — Report Layouts Impl SetDefault is Internal; see remarks.

        ReportMeta.SetLoadFields(ID);
        if not ReportMeta.Get(ReportId) then
            Error(ReportNotFoundErr, ReportId);

        if LayoutBase64 = '' then
            Error(MissingLayoutBase64Err);

        TempBlob.CreateOutStream(OutStr);
        Base64Convert.FromBase64(LayoutBase64, OutStr);
        TempBlob.CreateInStream(InStr);

        Replacing := TenantReportLayout.Get(ReportId, LayoutName, EmptyGuid);
        if Replacing then begin
            ActionText := 'Replaced';
            TenantReportLayout."Layout Format" := LayoutFormat;
            TenantReportLayout.Description := Description;
            TenantReportLayout."Company Name" := CompanyNameValue;
            TenantReportLayout."MIME Type" := MimeTypeFor(LayoutFormat);
            TenantReportLayout.Layout.ImportStream(InStr, FileNameFor(LayoutName, LayoutFormat));
            TenantReportLayout.Modify(true);
        end else begin
            ActionText := 'Created';
            TenantReportLayout.Init();
            TenantReportLayout."Report ID" := ReportId;
            TenantReportLayout.Name := LayoutName;
            TenantReportLayout."App ID" := EmptyGuid;
            TenantReportLayout."Layout Format" := LayoutFormat;
            TenantReportLayout.Description := Description;
            TenantReportLayout."Company Name" := CompanyNameValue;
            TenantReportLayout."MIME Type" := MimeTypeFor(LayoutFormat);
            TenantReportLayout.Layout.ImportStream(InStr, FileNameFor(LayoutName, LayoutFormat));
            TenantReportLayout.Insert(true);
        end;

        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('reportId', ReportId);
        ResponseJson.Add('name', LayoutName);
        ResponseJson.Add('layoutFormat', FormatName(LayoutFormat));
        ResponseJson.Add('action', ActionText);
        ResponseJson.Add('isDefault', false);
        Argument.SetResponseJson(ResponseJson);
    end;

    local procedure GetRequiredInteger(RequestJson: JsonObject; FieldName: Text): Integer
    var
        Token: JsonToken;
    begin
        if not RequestJson.Get(FieldName, Token) then
            Error(MissingFieldErr, FieldName);
        exit(Token.AsValue().AsInteger());
    end;

    local procedure GetRequiredText(RequestJson: JsonObject; FieldName: Text): Text
    var
        Token: JsonToken;
    begin
        if not RequestJson.Get(FieldName, Token) then
            Error(MissingFieldErr, FieldName);
        exit(Token.AsValue().AsText());
    end;

    local procedure ParseLayoutFormat(FormatText: Text; ReportId: Integer): Option
    var
        Upper: Text;
        TenantReportLayout: Record "Tenant Report Layout";
    begin
        Upper := FormatText.Trim().ToUpper();
        case Upper of
            'WORD':
                exit(TenantReportLayout."Layout Format"::Word);
            'RDLC', 'RDL':
                exit(TenantReportLayout."Layout Format"::RDLC);
            'EXCEL':
                exit(TenantReportLayout."Layout Format"::Excel);
            else
                Error(InvalidLayoutFormatErr, FormatText, ReportId);
        end;
    end;

    local procedure MimeTypeFor(LayoutFormat: Option RDLC,Word,Excel,Custom): Text[255]
    begin
        case LayoutFormat of
            LayoutFormat::Word:
                exit('application/vnd.openxmlformats-officedocument.wordprocessingml.document');
            LayoutFormat::Excel:
                exit('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
            LayoutFormat::RDLC:
                exit('application/xml');
            else
                exit('application/octet-stream');
        end;
    end;

    local procedure FileNameFor(LayoutName: Text[250]; LayoutFormat: Option RDLC,Word,Excel,Custom): Text
    begin
        case LayoutFormat of
            LayoutFormat::Word:
                exit(LayoutName + '.docx');
            LayoutFormat::Excel:
                exit(LayoutName + '.xlsx');
            LayoutFormat::RDLC:
                exit(LayoutName + '.rdl');
            else
                exit(LayoutName);
        end;
    end;

    local procedure FormatName(LayoutFormat: Option RDLC,Word,Excel,Custom): Text
    begin
        case LayoutFormat of
            LayoutFormat::Word:
                exit('Word');
            LayoutFormat::Excel:
                exit('Excel');
            LayoutFormat::RDLC:
                exit('RDLC');
            else
                exit('Custom');
        end;
    end;

    var
        ReportNotFoundErr: Label 'Report %1 not found.', Comment = 'is-IS=Skýrsla %1 finnst ekki.';
        InvalidLayoutFormatErr: Label 'Layout format %1 is not valid for report %2.', Comment = 'is-IS=Útlitssnið %1 er ógilt fyrir skýrslu %2.';
        MissingFieldErr: Label 'Request must include "%1".', Comment = 'is-IS=Beiðni verður að innihalda "%1".';
        MissingLayoutBase64Err: Label 'Request must include non-empty "layoutBase64".', Comment = 'is-IS=Beiðni verður að innihalda "layoutBase64" sem er ekki autt.';
}
