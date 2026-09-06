/// <summary>
/// List page for browsing and selecting Job Queue Recurring Templates.
/// </summary>
namespace Origo.Bifrost.Nornir;

page 10035542 "Recurring Templates ori"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    ContextSensitiveHelpPage = 'recurring-templates';
    SourceTable = "Recurring Template ori";
    CardPageId = "Recurring Template ori";
    Caption = 'Job Queue Recurring Templates', Comment = 'is-IS=Endurtekningarsniðmát vinnsluraða';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                Editable = false;
                field(Code; Rec.Code)
                {
                    ToolTip = 'Specifies the code of the job queue recurring template.', Comment = 'is-IS=Tilgreinir kóða endurtekningarsniðmáts.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description of the job queue recurring template.', Comment = 'is-IS=Tilgreinir lýsingu endurtekningarsniðmáts.';
                }
                field("Time Zone Display Name"; Rec."Time Zone Display Name")
                {
                    Caption = 'Time Zone', Comment = 'is-IS=Tímabelti';
                    ToolTip = 'Specifies the time zone for the job queue recurring template.', Comment = 'is-IS=Tilgreinir tímabelti endurtekningarsniðmáts.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(InsertSampleTemplates)
            {
                ApplicationArea = All;
                Caption = 'Insert Sample Templates', Comment = 'is-IS=Setja inn sýnishorn sniðmáta';
                ToolTip = 'Inserts a set of commonly used recurring schedule templates.', Comment = 'is-IS=Setur inn sett af algengum endurtekningarsniðmátum.';
                Image = Apply;

                trigger OnAction()
                var
                    RecTemplate: Record "Recurring Template ori";
                begin
                    RecTemplate.InsertSampleTemplates();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(InsertSampleTemplatesRef; InsertSampleTemplates) { }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.CalcFields("Time Zone Display Name");
    end;
}
