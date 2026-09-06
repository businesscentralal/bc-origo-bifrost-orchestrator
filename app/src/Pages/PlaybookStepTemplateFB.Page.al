/// <summary>
/// Factbox for editing the JSON request template of the selected playbook step.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using System.Utilities;

page 10035554 "Playbook Step Template FB ori"
{
    Caption = 'Request Template', Comment = 'is-IS=Sniðmát beiðni';
    PageType = CardPart;
    SourceTable = "Playbook Step ori";

    layout
    {
        area(Content)
        {
            field(RequestTemplate; RequestTemplateText)
            {
                ApplicationArea = All;
                Caption = 'Request Template', Comment = 'is-IS=Sniðmát beiðni';
                ShowCaption = false;
                MultiLine = true;
                ToolTip = 'Specifies the JSON request template sent to the message type. Supports {{placeholder}} tokens filled from prior step responses via bindings.', Comment = 'is-IS=Tilgreinir JSON sniðmát beiðni sem sent er á skilaboðagerðina. Styður {{færibreyta}} tákn sem fyllt eru úr svörum fyrri skrefa með bindingum.';

                trigger OnValidate()
                begin
                    Rec.SetRequestTemplate(RequestTemplateText);
                    CurrPage.SaveRecord();
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EditTemplate)
            {
                ApplicationArea = All;
                Caption = 'Edit', Comment = 'is-IS=Breyta';
                Image = Edit;
                ToolTip = 'Opens the request template in a full-page editor.', Comment = 'is-IS=Opnar sniðmát beiðni í heilsíðuritli.';

                trigger OnAction()
                var
                    StepRec: Record "Playbook Step ori";
                    Editor: Page "Playbook Template Editor ori";
                begin
                    StepRec := Rec;
                    StepRec.SetRecFilter();
                    Editor.SetTableView(StepRec);
                    Editor.RunModal();
                    if Rec.Find() then;
                    RequestTemplateText := Rec.GetRequestTemplate();
                    CurrPage.Update(false);
                end;
            }
            action(DownloadTemplate)
            {
                ApplicationArea = All;
                Caption = 'Download', Comment = 'is-IS=Sækja';
                Image = Download;
                ToolTip = 'Downloads the request template as a JSON file.', Comment = 'is-IS=Sækir sniðmát beiðni sem JSON skrá.';

                trigger OnAction()
                var
                    TempBlob: Codeunit "Temp Blob";
                    InStr: InStream;
                    OutStr: OutStream;
                    FileName: Text;
                begin
                    TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
                    OutStr.WriteText(Rec.GetRequestTemplate());
                    TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
                    FileName := StrSubstNo(DownloadFileNameTok, Rec."Playbook Code", Rec."Step No.");
                    DownloadFromStream(InStr, '', '', '', FileName);
                end;
            }
            action(UploadTemplate)
            {
                ApplicationArea = All;
                Caption = 'Upload', Comment = 'is-IS=Hlaða upp';
                Image = Import;
                ToolTip = 'Replaces the request template with the contents of a selected JSON file.', Comment = 'is-IS=Skiptir út sniðmáti beiðni með innihaldi valinnar JSON skráar.';

                trigger OnAction()
                var
                    InStr: InStream;
                    UploadedText: Text;
                    FileName: Text;
                begin
                    if not UploadIntoStream('', '', '', FileName, InStr) then
                        exit;
                    InStr.ReadText(UploadedText);
                    Rec.SetRequestTemplate(UploadedText);
                    CurrPage.SaveRecord();
                    RequestTemplateText := Rec.GetRequestTemplate();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        RequestTemplateText: Text;
        DownloadFileNameTok: Label 'RequestTemplate_%1_%2.json', Locked = true;

    trigger OnAfterGetRecord()
    begin
        RequestTemplateText := Rec.GetRequestTemplate();
    end;
}
