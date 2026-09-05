/// <summary>
/// Full-page editor for a playbook step's JSON request template, hosting the
/// Bifrost Base text editor control add-in.
/// </summary>
namespace Origo.Bifrost.Nornir;

using Origo.Bifrost;

page 10035556 "Playbook Template Editor ori"
{
    Caption = 'Playbook Template Editor', Comment = 'is-IS=Ritill keðjusniðmáts';
    PageType = CardPart;
    SourceTable = "Playbook Step ori";
    DataCaptionExpression = GetCaption();
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;
    ShowFilter = false;

    layout
    {
        area(Content)
        {
            group(RequestTemplate)
            {
                Caption = 'Request Template', Comment = 'is-IS=Sniðmát beiðni';
                ShowCaption = false;

                usercontrol(DataEditor; "Text Editor ori")
                {
                    ApplicationArea = All;

                    trigger ControlReady()
                    begin
                        CurrPage.DataEditor.SetReadOnly(not CurrPage.Editable());
                        CurrPage.DataEditor.SetContent(DataAsText);
                    end;

                    trigger ContentChanged(Content: Text)
                    begin
                        if not CurrPage.Editable() then
                            exit;

                        Rec.SetRequestTemplate(Content);
                        Rec.Modify(true);
                    end;
                }
            }
        }
    }

    var
        DataAsText: Text;

    trigger OnAfterGetCurrRecord()
    begin
        DataAsText := Rec.GetRequestTemplate();
        CurrPage.DataEditor.SetReadOnly(not CurrPage.Editable());
        CurrPage.DataEditor.SetContent(DataAsText);
    end;

    local procedure GetCaption(): Text
    begin
        exit(Rec.FieldCaption("Request Template"));
    end;
}
