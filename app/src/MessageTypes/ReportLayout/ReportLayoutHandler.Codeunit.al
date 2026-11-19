namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using Microsoft.Foundation.Reporting;
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
/// setAsDefault / clearDefault (#197): SetDefaultReportLayoutSelection is also Internal, so the
/// handler makes the same two writes that procedure makes for the current company: the
/// company-wide Tenant Report Layout Selection row (empty User ID) and the Report Layout Selection
/// type. It never writes a per-user selection, a layout override or another company.
/// </remarks>
codeunit 10035600 "Report Layout Handler ori"
{
    Access = Internal;
    Permissions =
        tabledata "Tenant Report Layout" = RIMD,
        tabledata "Tenant Report Layout Selection" = RIMD,
        tabledata "Report Layout Selection" = RIMD,
        tabledata "Report Layout List" = R,
        tabledata "Report Metadata" = R;

    procedure ExecuteSet(var Argument: Record "Message Argument ori")
    var
        TenantReportLayout: Record "Tenant Report Layout";
        ReportMeta: Record "Report Metadata";
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        BlobStaging: Codeunit "Blob Staging ori";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        ReportId: Integer;
        LayoutName: Text[250];
        Description: Text[250];
        CompanyNameValue: Text[30];
        LayoutFormatText: Text;
        LayoutBase64: Text;
        StagingIdText: Text;
        StagingId: Guid;
        HasBase64: Boolean;
        HasStagingId: Boolean;
        ActionText: Text;
        LayoutFormat: Option RDLC,Word,Excel,Custom;
        OutStr: OutStream;
        InStr: InStream;
        EmptyGuid: Guid;
        Replacing: Boolean;
        SetAsDefault: Boolean;
        ClearDefault: Boolean;
        PreviousDefaultName: Text[250];
        PreviousDefaultAppId: Guid;
        Token: JsonToken;
    begin
        RequestJson := Argument.GetRequestJson();
        ReportId := GetRequiredInteger(RequestJson, 'reportId');
        SetAsDefault := GetOptionalBoolean(RequestJson, 'setAsDefault');
        ClearDefault := GetOptionalBoolean(RequestJson, 'clearDefault');
        HasBase64 := RequestJson.Contains('layoutBase64');
        HasStagingId := RequestJson.Contains('stagingId');
        if SetAsDefault and ClearDefault then
            Error(SetAndClearDefaultErr);
        if ClearDefault then begin
            if HasBase64 or HasStagingId then
                Error(ClearDefaultWithLayoutErr);
            ExecuteClearDefault(Argument, ReportId);
            exit;
        end;
        LayoutName := CopyStr(GetRequiredText(RequestJson, 'name'), 1, MaxStrLen(LayoutName));
        if HasBase64 and HasStagingId then
            Error(BothLayoutSourcesErr);
        if RequestJson.Contains('appId') and (HasBase64 or HasStagingId) then
            Error(AppIdWithLayoutErr);
        if SetAsDefault and not (HasBase64 or HasStagingId) then begin
            ExecuteSelectDefault(Argument, RequestJson, ReportId, LayoutName);
            exit;
        end;
        LayoutFormatText := GetRequiredText(RequestJson, 'layoutFormat');
        if not (HasBase64 or HasStagingId) then
            Error(NoLayoutSourceErr);
        if HasStagingId then begin
            StagingIdText := GetRequiredText(RequestJson, 'stagingId');
            if not Evaluate(StagingId, StagingIdText) or IsNullGuid(StagingId) then
                Error(InvalidStagingIdErr, StagingIdText);
        end else
            LayoutBase64 := GetRequiredText(RequestJson, 'layoutBase64');
        LayoutFormat := ParseLayoutFormat(LayoutFormatText, ReportId);

        if RequestJson.Get('description', Token) then
            Description := CopyStr(Token.AsValue().AsText(), 1, MaxStrLen(Description))
        else
            Description := LayoutName;

        if RequestJson.Get('companyName', Token) then
            CompanyNameValue := CopyStr(Token.AsValue().AsText(), 1, MaxStrLen(CompanyNameValue));

        ReportMeta.SetLoadFields(ID, "DefaultLayoutName", "App ID");
        if not ReportMeta.Get(ReportId) then
            Error(ReportNotFoundErr, ReportId);
        if SetAsDefault and (CompanyNameValue <> '') and (CompanyNameValue <> CompanyName()) then
            Error(LayoutOtherCompanyErr, LayoutName, CompanyNameValue, CompanyName());

        if HasStagingId then begin
            // Take reads and deletes the row in this transaction. A later import error rolls the delete back,
            // so the row survives a failed import and the call can be retried with the same id.
            if not BlobStaging.Take(StagingId, TempBlob) then
                Error(StagingIdNotFoundErr, StagingIdText);
        end else begin
            if LayoutBase64 = '' then
                Error(MissingLayoutBase64Err);
            TempBlob.CreateOutStream(OutStr);
            Base64Convert.FromBase64(LayoutBase64, OutStr);
        end;
        TempBlob.CreateInStream(InStr);

        // The platform refuses to modify the content or type of an existing layout, so a replace
        // deletes the user-defined row and inserts it again under the same key, as the
        // Report Layouts page's Replace Layout action does (Report Layouts Impl. InsertNewLayout).
        GetCurrentDefault(ReportMeta, PreviousDefaultName, PreviousDefaultAppId);
        Replacing := TenantReportLayout.Get(ReportId, LayoutName, EmptyGuid);
        // The key has no company, so a layout limited to another company holds this name for the whole tenant.
        // It must not be replaced or re-scoped from here (#237); nothing has been changed yet.
        if Replacing and (TenantReportLayout."Company Name" <> '') and (TenantReportLayout."Company Name" <> CompanyName()) then begin
            Argument.RespondWithError("Bifrost Error Code ori"::PreconditionFailed, StrSubstNo(LayoutNameTakenOtherCompanyErr, LayoutName, ReportId, CompanyName()), 'name', LayoutName, NameExpectedTok, NameNextStepTok);
            exit;
        end;
        if Replacing then begin
            ActionText := 'Replaced';
            TenantReportLayout.Delete(true);
        end else
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

        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('reportId', ReportId);
        ResponseJson.Add('name', LayoutName);
        ResponseJson.Add('layoutFormat', FormatName(LayoutFormat));
        ResponseJson.Add('action', ActionText);
        if SetAsDefault then begin
            AddPreviousDefault(ResponseJson, PreviousDefaultName, PreviousDefaultAppId);
            WriteDefaultSelection(ReportId, LayoutName, EmptyGuid, LayoutFormat);
        end;
        ResponseJson.Add('isDefault', SetAsDefault or IsCurrentDefault(ReportMeta, LayoutName, EmptyGuid));
        Argument.SetResponseJson(ResponseJson);
    end;

    /// <summary>Makes an existing layout (extension or user-defined) the report's default in the current company.</summary>
    local procedure ExecuteSelectDefault(var Argument: Record "Message Argument ori"; RequestJson: JsonObject; ReportId: Integer; LayoutName: Text[250])
    var
        ReportMeta: Record "Report Metadata";
        LayoutList: Record "Report Layout List";
        TenantReportLayout: Record "Tenant Report Layout";
        ResponseJson: JsonObject;
        AppIdText: Text;
        AppId: Guid;
        HasAppId: Boolean;
    begin
        HasAppId := RequestJson.Contains('appId');
        if HasAppId then begin
            AppIdText := GetRequiredText(RequestJson, 'appId');
            if not Evaluate(AppId, AppIdText) then
                Error(InvalidAppIdErr, AppIdText);
        end;
        ReportMeta.SetLoadFields(ID, "DefaultLayoutName", "App ID");
        if not ReportMeta.Get(ReportId) then
            Error(ReportNotFoundErr, ReportId);

        LayoutList.SetRange("Report ID", ReportId);
        LayoutList.SetRange(Name, LayoutName);
        if HasAppId then
            LayoutList.SetRange("Application ID", AppId);
        LayoutList.SetLoadFields("Report ID", Name, "Application ID", "Layout Format");
        if not LayoutList.FindFirst() then
            Error(LayoutNotFoundErr, LayoutName, ReportId);
        if LayoutList.Count() > 1 then
            Error(AmbiguousLayoutErr, LayoutName, ReportId);
        if IsNullGuid(LayoutList."Application ID") then begin
            TenantReportLayout.SetLoadFields("Company Name");
            if TenantReportLayout.Get(ReportId, LayoutList.Name, LayoutList."Application ID") then
                if (TenantReportLayout."Company Name" <> '') and (TenantReportLayout."Company Name" <> CompanyName()) then
                    Error(LayoutOtherCompanyErr, LayoutName, TenantReportLayout."Company Name", CompanyName());
        end;

        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('reportId', ReportId);
        ResponseJson.Add('name', LayoutList.Name);
        ResponseJson.Add('layoutFormat', FormatName(LayoutList."Layout Format"));
        ResponseJson.Add('appId', Format(LayoutList."Application ID", 0, 4));
        ResponseJson.Add('action', 'DefaultSet');
        AddPreviousDefault(ResponseJson, ReportMeta);
        WriteDefaultSelection(ReportId, LayoutList.Name, LayoutList."Application ID", LayoutList."Layout Format");
        ResponseJson.Add('isDefault', true);
        Argument.SetResponseJson(ResponseJson);
    end;

    /// <summary>Removes the current company's default layout selection, so the report's built-in default applies again.</summary>
    local procedure ExecuteClearDefault(var Argument: Record "Message Argument ori"; ReportId: Integer)
    var
        ReportMeta: Record "Report Metadata";
        TenantSelection: Record "Tenant Report Layout Selection";
        LayoutSelection: Record "Report Layout Selection";
        LayoutList: Record "Report Layout List";
        ResponseJson: JsonObject;
        EmptyGuid: Guid;
        DefaultAppId: Guid;
        DefaultName: Text[250];
        HadSelection: Boolean;
    begin
        ReportMeta.SetLoadFields(ID, "DefaultLayoutName", "App ID");
        if not ReportMeta.Get(ReportId) then
            Error(ReportNotFoundErr, ReportId);

        AddPreviousDefault(ResponseJson, ReportMeta);
        HadSelection := TenantSelection.Get(ReportId, CompanyName(), EmptyGuid);
        if HadSelection then
            TenantSelection.Delete(true);
        // The default that applies now: the all-companies selection if there is one, else the built-in default.
        GetCurrentDefault(ReportMeta, DefaultName, DefaultAppId);
        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('reportId', ReportId);
        ResponseJson.Add('name', DefaultName);
        if FindLayout(ReportId, DefaultName, DefaultAppId, LayoutList) then
            ResponseJson.Add('layoutFormat', FormatName(LayoutList."Layout Format"))
        else
            ResponseJson.Add('layoutFormat', '');
        ResponseJson.Add('appId', Format(DefaultAppId, 0, 4));
        if HadSelection then begin
            // Report Layout Selection follows the default that applies now, as SetDefault would write it.
            if LayoutSelection.Get(ReportId, CompanyName()) and FindLayout(ReportId, DefaultName, DefaultAppId, LayoutList) then begin
                LayoutSelection.Type := SelectionTypeFor(LayoutList."Layout Format");
                LayoutSelection.Modify(true);
            end;
            ResponseJson.Add('action', 'DefaultCleared');
        end else
            ResponseJson.Add('action', 'NoChange');
        ResponseJson.Add('isDefault', true);
        Argument.SetResponseJson(ResponseJson);
    end;

    /// <summary>
    /// The same writes as Report Layouts Impl. SetDefaultReportLayoutSelection for the current company:
    /// the company-wide Tenant Report Layout Selection row and the Report Layout Selection type.
    /// </summary>
    local procedure WriteDefaultSelection(ReportId: Integer; LayoutName: Text[250]; AppId: Guid; LayoutFormat: Option RDLC,Word,Excel,Custom)
    var
        TenantSelection: Record "Tenant Report Layout Selection";
        LayoutSelection: Record "Report Layout Selection";
        EmptyGuid: Guid;
    begin
        if TenantSelection.Get(ReportId, CompanyName(), EmptyGuid) then begin
            TenantSelection."Layout Name" := LayoutName;
            TenantSelection."App ID" := AppId;
            TenantSelection.Modify(true);
        end else begin
            TenantSelection.Init();
            TenantSelection."Report ID" := ReportId;
            TenantSelection."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(TenantSelection."Company Name"));
            TenantSelection."User ID" := EmptyGuid;
            TenantSelection."Layout Name" := LayoutName;
            TenantSelection."App ID" := AppId;
            TenantSelection.Insert(true);
        end;

        if LayoutSelection.Get(ReportId, CompanyName()) then begin
            // As SetDefaultReportLayoutSelection: only Type changes; a saved Custom Report Layout Code is kept.
            LayoutSelection.Type := SelectionTypeFor(LayoutFormat);
            LayoutSelection.Modify(true);
        end else begin
            LayoutSelection.Init();
            LayoutSelection."Report ID" := ReportId;
            LayoutSelection."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(LayoutSelection."Company Name"));
            LayoutSelection.Type := SelectionTypeFor(LayoutFormat);
            LayoutSelection."Custom Report Layout Code" := '';
            LayoutSelection.Insert(true);
        end;
    end;

    local procedure FindLayout(ReportId: Integer; LayoutName: Text[250]; AppId: Guid; var LayoutList: Record "Report Layout List"): Boolean
    begin
        LayoutList.Reset();
        LayoutList.SetRange("Report ID", ReportId);
        LayoutList.SetRange(Name, LayoutName);
        LayoutList.SetRange("Application ID", AppId);
        LayoutList.SetLoadFields("Layout Format");
        exit(LayoutList.FindFirst());
    end;

    local procedure SelectionTypeFor(LayoutFormat: Option RDLC,Word,Excel,Custom): Integer
    var
        LayoutSelection: Record "Report Layout Selection";
    begin
        case LayoutFormat of
            LayoutFormat::Word:
                exit(LayoutSelection.Type::"Word (built-in)");
            LayoutFormat::Excel:
                exit(LayoutSelection.Type::"Excel Layout");
            LayoutFormat::Custom:
                exit(LayoutSelection.Type::"External Layout");
            else
                exit(LayoutSelection.Type::"RDLC (built-in)");
        end;
    end;

    /// <summary>Adds the default that applied before this call (current-company selection, else the built-in default).</summary>
    local procedure AddPreviousDefault(var ResponseJson: JsonObject; ReportMeta: Record "Report Metadata")
    var
        LayoutName: Text[250];
        AppId: Guid;
    begin
        GetCurrentDefault(ReportMeta, LayoutName, AppId);
        AddPreviousDefault(ResponseJson, LayoutName, AppId);
    end;

    local procedure AddPreviousDefault(var ResponseJson: JsonObject; LayoutName: Text[250]; AppId: Guid)
    begin
        ResponseJson.Add('previousDefault', LayoutName);
        ResponseJson.Add('previousDefaultAppId', Format(AppId, 0, 4));
    end;

    local procedure IsCurrentDefault(ReportMeta: Record "Report Metadata"; LayoutName: Text[250]; AppId: Guid): Boolean
    var
        DefaultName: Text[250];
        DefaultAppId: Guid;
    begin
        GetCurrentDefault(ReportMeta, DefaultName, DefaultAppId);
        exit((DefaultName = LayoutName) and (DefaultAppId = AppId));
    end;

    local procedure GetCurrentDefault(ReportMeta: Record "Report Metadata"; var LayoutName: Text[250]; var AppId: Guid)
    var
        TenantSelection: Record "Tenant Report Layout Selection";
        EmptyGuid: Guid;
    begin
        // Same lookup as Orchestrator.ReportLayout.List isDefault: current-company selection, then the
        // all-companies selection (blank Company Name), else the built-in default.
        TenantSelection.SetLoadFields("Layout Name", "App ID");
        // AL evaluates both operands of "or", so the two Gets are separate: the company row must win.
        if not TenantSelection.Get(ReportMeta.ID, CompanyName(), EmptyGuid) then
            if not TenantSelection.Get(ReportMeta.ID, '', EmptyGuid) then begin
                LayoutName := CopyStr(ReportMeta."DefaultLayoutName", 1, MaxStrLen(LayoutName));
                AppId := ReportMeta."App ID";
                exit;
            end;
        LayoutName := TenantSelection."Layout Name";
        AppId := TenantSelection."App ID";
    end;

    local procedure GetOptionalBoolean(RequestJson: JsonObject; FieldName: Text): Boolean
    var
        Token: JsonToken;
    begin
        if not RequestJson.Get(FieldName, Token) then
            exit(false);
        if not Token.IsValue() then
            Error(NotBooleanErr, FieldName);
        if Token.AsValue().IsNull() then
            exit(false);
        exit(Token.AsValue().AsBoolean());
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
        TenantReportLayout: Record "Tenant Report Layout";
        Upper: Text;
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
        BothLayoutSourcesErr: Label 'Send either "layoutBase64" or "stagingId", not both.', Comment = 'is-IS=Sendu annaðhvort "layoutBase64" eða "stagingId", ekki bæði.';
        NoLayoutSourceErr: Label 'Request must include "layoutBase64" or "stagingId".', Comment = 'is-IS=Beiðni verður að innihalda "layoutBase64" eða "stagingId".';
        InvalidStagingIdErr: Label '"stagingId" %1 is not a valid GUID.', Comment = 'is-IS="stagingId" %1 er ekki gilt GUID.';
        StagingIdNotFoundErr: Label 'Staging row %1 was not found or has already been taken.', Comment = 'is-IS=Milligeymslufærsla %1 fannst ekki eða hefur þegar verið tekin.';
        MissingLayoutBase64Err: Label 'Request must include non-empty "layoutBase64".', Comment = 'is-IS=Beiðni verður að innihalda "layoutBase64" sem er ekki autt.';
        SetAndClearDefaultErr: Label 'Send either "setAsDefault" or "clearDefault", not both.', Comment = 'is-IS=Sendu annaðhvort "setAsDefault" eða "clearDefault", ekki bæði.';
        ClearDefaultWithLayoutErr: Label 'Send "clearDefault" without "layoutBase64" or "stagingId".', Comment = 'is-IS=Sendu "clearDefault" án "layoutBase64" eða "stagingId".';
        AppIdWithLayoutErr: Label 'Send "appId" only with "setAsDefault" and no layout file.', Comment = 'is-IS=Sendu "appId" aðeins með "setAsDefault" og engri útlitsskrá.';
        InvalidAppIdErr: Label '"appId" %1 is not a valid GUID.', Comment = 'is-IS="appId" %1 er ekki gilt GUID.';
        LayoutNotFoundErr: Label 'Layout %1 not found on report %2.', Comment = 'is-IS=Útlit %1 fannst ekki fyrir skýrslu %2.';
        AmbiguousLayoutErr: Label 'More than one layout named %1 exists on report %2. Send "appId".', Comment = 'is-IS=Fleiri en eitt útlit heitir %1 í skýrslu %2. Sendu "appId".';
        LayoutOtherCompanyErr: Label 'Layout %1 belongs to company %2 and cannot be the default in company %3.', Comment = 'is-IS=Útlit %1 tilheyrir fyrirtækinu %2 og getur ekki verið sjálfgefið í fyrirtækinu %3.';
        LayoutNameTakenOtherCompanyErr: Label 'Layout %1 on report %2 is limited to another company and cannot be replaced from company %3. Use another layout name.', Comment = 'is-IS=Útlit %1 í skýrslu %2 er takmarkað við annað fyrirtæki og er ekki hægt að skipta um það úr fyrirtækinu %3. Notaðu annað heiti á útlitið.';
        NameExpectedTok: Label 'a layout name that is not used by a layout limited to another company', Comment = 'is-IS=útlitsheiti sem er ekki notað af útliti sem takmarkað er við annað fyrirtæki';
        NameNextStepTok: Label 'Use another layout name.', Comment = 'is-IS=Notaðu annað heiti á útlitið.';
        NotBooleanErr: Label '"%1" must be true or false.', Comment = 'is-IS="%1" verður að vera true eða false.';
}
