/// <summary>
/// Factbox showing the request sent and response received for the selected step log entry.
/// </summary>
namespace Origo.Bifrost.Nornir;

page 10035555 "Playbook Step Log Dtl. FB ori"
{
    Caption = 'Selected Step', Comment = 'is-IS=Valið skref';
    PageType = CardPart;
    SourceTable = "Playbook Step Log ori";
    Editable = false;

    layout
    {
        area(Content)
        {
            group(RequestGroup)
            {
                Caption = 'Request Sent', Comment = 'is-IS=Beiðni send';

                field(RequestText; RequestText)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    ToolTip = 'Specifies the request payload sent to the message type for the selected step.', Comment = 'is-IS=Tilgreinir beiðnina sem var send á skilaboðagerðina fyrir valið skref.';
                    MultiLine = true;
                }
            }
            group(ResponseGroup)
            {
                Caption = 'Response Received', Comment = 'is-IS=Svar móttekið';

                field(ResponseText; ResponseText)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    ToolTip = 'Specifies the response returned by the message type for the selected step.', Comment = 'is-IS=Tilgreinir svarið sem skilaboðagerðin skilaði fyrir valið skref.';
                    MultiLine = true;
                }
            }
            group(WorkspaceGroup)
            {
                Caption = 'Workspace Snapshot', Comment = 'is-IS=Vinnusvæðisafrit';

                field(WorkspaceText; WorkspaceText)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    ToolTip = 'Workspace JSON at the time of failure.', Comment = 'is-IS=Vinnusvæðis-JSON þegar villa átti sér stað.';
                    MultiLine = true;
                }
            }
        }
    }

    var
        RequestText: Text;
        ResponseText: Text;
        WorkspaceText: Text;

    trigger OnAfterGetRecord()
    begin
        RequestText := Rec.GetRequestSent();
        ResponseText := Rec.GetResponseReceived();
        WorkspaceText := Rec.GetWorkspaceSnapshot();
    end;
}
