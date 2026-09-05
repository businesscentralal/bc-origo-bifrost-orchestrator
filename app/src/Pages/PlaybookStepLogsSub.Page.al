/// <summary>
/// Subpage showing step-level execution log within a playbook instance.
/// </summary>
namespace Origo.Bifrost.Nornir;

using System.Utilities;

page 10035552 "Playbook Step Logs Sub. ori"
{
    Caption = 'Playbook Step Log', Comment = 'is-IS=Atburðaskrá keðjuskrefa';
    PageType = ListPart;
    SourceTable = "Playbook Step Log ori";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(StepLogs)
            {
                field("Step No."; Rec."Step No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the step number.', Comment = 'is-IS=Tilgreinir skrefnúmer.';
                }
                field("Iteration No."; Rec."Iteration No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the foreach iteration number (0 for single-call steps).', Comment = 'is-IS=Tilgreinir ítrunarnúmer (0 fyrir einfalt kall).';
                }
                field("Message Type"; Rec."Message Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the message type that was executed.', Comment = 'is-IS=Tilgreinir skilaboðagerð sem var keyrð.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the step execution status.', Comment = 'is-IS=Tilgreinir stöðu keyrsluskautar.';
                    StyleExpr = StatusStyle;
                }
                field(Duration; Rec.Duration)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how long this step took.', Comment = 'is-IS=Tilgreinir hversu lengi skrefið tók.';
                }
                field("Error Text"; Rec."Error Text")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the error message if the step failed.', Comment = 'is-IS=Tilgreinir villuboð ef skrefið mistókst.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DownloadRequest)
            {
                ApplicationArea = All;
                Caption = 'Download Request', Comment = 'is-IS=Sækja beiðni';
                ToolTip = 'Download the request JSON sent to the message type.', Comment = 'is-IS=Sækja beiðni-JSON sem var send á skilaboðagerðina.';
                Image = SendTo;

                trigger OnAction()
                begin
                    DownloadBlob(Rec.GetRequestSent(), StrSubstNo(FileNameTok, 'request', Rec."Step No.", Rec."Iteration No."));
                end;
            }
            action(DownloadResponse)
            {
                ApplicationArea = All;
                Caption = 'Download Response', Comment = 'is-IS=Sækja svar';
                ToolTip = 'Download the response JSON returned by the message type.', Comment = 'is-IS=Sækja svar-JSON sem skilaboðagerðin skilaði.';
                Image = GetSourceDoc;

                trigger OnAction()
                begin
                    DownloadBlob(Rec.GetResponseReceived(), StrSubstNo(FileNameTok, 'response', Rec."Step No.", Rec."Iteration No."));
                end;
            }
            action(DownloadWorkspace)
            {
                ApplicationArea = All;
                Caption = 'Download Workspace', Comment = 'is-IS=Sækja vinnusvæði';
                ToolTip = 'Download the workspace JSON snapshot from this step.', Comment = 'is-IS=Sækja vinnusvæðis-JSON afrit frá þessu skrefi.';
                Image = Export;
                Enabled = Rec.Status = Rec.Status::Failed;

                trigger OnAction()
                begin
                    DownloadBlob(Rec.GetWorkspaceSnapshot(), StrSubstNo(FileNameTok, 'workspace', Rec."Step No.", Rec."Iteration No."));
                end;
            }
        }
    }

    var
        StatusStyle: Text;
        FileNameTok: Label '%1-step%2-iter%3.json', Locked = true;
        NoContentErr: Label 'No content available for download.', Comment = 'is-IS=Ekkert efni til niðurhals.';

    local procedure DownloadBlob(Content: Text; FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
    begin
        if Content = '' then
            Error(NoContentErr);
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(Content);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        DownloadFromStream(InStr, '', '', '*.json', FileName);
    end;

    trigger OnAfterGetRecord()
    begin
        case Rec.Status of
            Rec.Status::Completed:
                StatusStyle := 'Favorable';
            Rec.Status::Failed:
                StatusStyle := 'Unfavorable';
            else
                StatusStyle := 'Standard';
        end;
    end;
}
