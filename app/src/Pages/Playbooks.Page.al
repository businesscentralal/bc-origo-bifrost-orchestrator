/// <summary>
/// List page for Bifrost Playbook definitions.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.Utilities;

page 10035551 "Playbooks ori"
{
    Extensible = false;
    Caption = 'Bifrost Playbooks', Comment = 'is-IS=Bifröst keðjur';
    ContextSensitiveHelpPage = 'playbooks';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Playbook ori";
    CardPageId = "Playbook Card ori";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Playbooks)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique code for this playbook.', Comment = 'is-IS=Tilgreinir einstakan kóða fyrir þessa keðju.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the playbook.', Comment = 'is-IS=Tilgreinir lýsingu keðjunnar.';
                }
                field("Last Run Status"; Rec."Last Run Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the status of the last execution.', Comment = 'is-IS=Tilgreinir stöðu síðustu keyrslu.';
                }
                field("Last Run At"; Rec."Last Run At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the playbook was last executed.', Comment = 'is-IS=Tilgreinir hvenær keðjan var síðast keyrð.';
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            group(Tools)
            {
                Caption = 'Tools', Comment = 'is-IS=Verkfæri';
                ToolTip = 'Open playbook and table data tools.', Comment = 'is-IS=Opna verkfæri fyrir keðjur og töflugögn.';
                Image = Tools;
                action(TableData)
                {
                    ApplicationArea = All;
                    Caption = 'Table Data', Comment = 'is-IS=Töflugögn';
                    ToolTip = 'View, edit, export and import table data within your permissions.', Comment = 'is-IS=Skoða, breyta, flytja út og flytja inn töflugögn innan heimilda þinna.';
                    Image = Table;
                    RunObject = page "Table Data ori";
                    AccessByPermission = page "Table Data ori" = X;
                }
                action(CopyPlans)
                {
                    ApplicationArea = All;
                    Caption = 'Copy Plans', Comment = 'is-IS=Afritunaráætlanir';
                    ToolTip = 'View copy plans and configure table-to-table playbooks within your permissions.', Comment = 'is-IS=Skoða afritunaráætlanir og stilla keðjur til að afrita milli taflna innan heimilda þinna.';
                    Image = Copy;
                    RunObject = page "Copy Plans ori";
                    AccessByPermission = page "Copy Plans ori" = X;
                }
            }
            action(ExportPlaybook)
            {
                ApplicationArea = All;
                Caption = 'Export Playbook', Comment = 'is-IS=Flytja út keðju';
                ToolTip = 'Downloads the selected playbook with its steps, conditions and Transform mappings as a playbook file.', Comment = 'is-IS=Sækir valda keðju með skrefum, skilyrðum og umbreytingarvörpunum sem keðjuskrá.';
                Image = Export;
                Scope = Repeater;
                AccessByPermission = codeunit "Table JSON Export ori" = X;
                Enabled = Rec.Code <> '';

                trigger OnAction()
                begin
                    ExportSelected();
                end;
            }
            action(ImportPlaybook)
            {
                ApplicationArea = All;
                Caption = 'Import Playbook', Comment = 'is-IS=Flytja inn keðju';
                ToolTip = 'Uploads a playbook file and imports the playbook, its steps, conditions and Transform mappings after you confirm.', Comment = 'is-IS=Hleður upp keðjuskrá og flytur inn keðjuna, skrefin, skilyrðin og umbreytingarvörpunirnar eftir staðfestingu.';
                Image = Import;
                AccessByPermission = codeunit "Table JSON Import ori" = X;

                trigger OnAction()
                begin
                    ImportFile();
                end;
            }
            action(Instances)
            {
                Caption = 'Execution Log', Comment = 'is-IS=Keyrsluskrá';
                ApplicationArea = All;
                ToolTip = 'View execution history for this playbook.', Comment = 'is-IS=Skoða keyrsluskrá fyrir þessa keðju.';
                Image = Log;
                RunObject = page "Playbook Instances ori";
                RunPageLink = "Playbook Code" = field(Code);
            }
        }
    }

    var
        FileNameTxt: Label 'Playbook-%1.json', Locked = true;
        DownloadTitleTxt: Label 'Export playbook', Comment = 'is-IS=Flytja út keðju';
        UploadTitleTxt: Label 'Import playbook', Comment = 'is-IS=Flytja inn keðju';
        NotJsonErr: Label 'The file is not valid JSON.', Comment = 'is-IS=Skráin er ekki gild JSON-skrá.';
        ImportQst: Label 'Import playbook %1? Rows with the same key are overwritten, and an error stops the import without writing anything.', Comment = '%1 = playbook code, is-IS=Flytja inn keðjuna %1? Línur með sama lykil eru yfirskrifaðar og villa stöðvar innflutninginn án þess að nokkuð sé skrifað.';
        ImportedMsg: Label 'Playbook %1 imported: %2 steps, %3 conditions and %4 transform rows.', Comment = '%1 = playbook code, %2 = steps, %3 = conditions, %4 = transform rows, is-IS=Keðjan %1 var flutt inn: %2 skref, %3 skilyrði og %4 umbreytingarlínur.';

    local procedure ExportSelected()
    var
        TableJSONExport: Codeunit "Table JSON Export ori";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        FileName: Text;
    begin
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        TableJSONExport.ExportPlaybook(Rec.Code).WriteTo(OutStr);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        FileName := StrSubstNo(FileNameTxt, Rec.Code);
        DownloadFromStream(InStr, DownloadTitleTxt, '', '', FileName);
    end;

    local procedure ImportFile()
    var
        InStr: InStream;
        Envelope: JsonObject;
        FileName: Text;
    begin
        if not UploadIntoStream(UploadTitleTxt, '', '', FileName, InStr) then
            exit;
        if not Envelope.ReadFrom(InStr) then
            Error(ErrorInfo.Create(NotJsonErr));
        ImportPlaybookFile(Envelope);
    end;

    /// <summary>Imports a playbook file after the user confirms (used by the Import Playbook action and tests).</summary>
    /// <param name="Envelope">The uploaded playbook file.</param>
    /// <returns>True when the user confirmed and the playbook was imported.</returns>
    internal procedure ImportPlaybookFile(Envelope: JsonObject): Boolean
    var
        TableJSONImport: Codeunit "Table JSON Import ori";
        Result: JsonObject;
        Token: JsonToken;
        PlaybookCode: Text;
    begin
        if Envelope.Get('playbookCode', Token) then
            if Token.IsValue() then
                PlaybookCode := Token.AsValue().AsText();
        if not Confirm(StrSubstNo(ImportQst, PlaybookCode), false) then
            exit(false);
        Result := TableJSONImport.ImportPlaybookFromUI(Envelope);
        CurrPage.Update(false);
        Message(StrSubstNo(ImportedMsg, PlaybookCode, TableRows(Result, Database::"Playbook Step ori"), TableRows(Result, Database::"Playbook Condition ori"), TableRows(Result, Database::"Playbook Transform ori")));
        exit(true);
    end;

    local procedure TableRows(Result: JsonObject; TableNo: Integer): Integer
    var
        Tables: JsonArray;
        Token: JsonToken;
        TableToken: JsonToken;
        RowsToken: JsonToken;
        Index: Integer;
    begin
        if not Result.Get('tables', Token) then
            exit(0);
        Tables := Token.AsArray();
        for Index := 1 to Tables.Count() do begin
            Tables.Get(Index - 1, TableToken);
            if TableToken.AsObject().Get('tableNo', RowsToken) then
                if RowsToken.AsValue().AsInteger() = TableNo then
                    if TableToken.AsObject().Get('rows', RowsToken) then
                        exit(RowsToken.AsValue().AsInteger());
        end;
    end;
}
