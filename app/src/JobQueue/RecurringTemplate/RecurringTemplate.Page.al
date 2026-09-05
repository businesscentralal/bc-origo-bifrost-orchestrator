/// <summary>
/// Card page for viewing and editing a Job Queue Recurring Template.
/// </summary>
namespace Origo.Bifrost.Nornir;

using System.DateTime;

page 10035543 "Recurring Template ori"
{
    PageType = Card;
    UsageCategory = None;
    ApplicationArea = All;
    ContextSensitiveHelpPage = '"Recurring Template ori".html';
    SourceTable = "Recurring Template ori";
    Caption = 'Job Queue Recurring Template', Comment = 'is-IS=Endurtekningarsniðmát vinnsluraða';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General', Comment = 'is-IS=Almænn';
                field(Code; Rec.Code)
                {
                    ToolTip = 'Specifies the code of the job queue recurring template.', Comment = 'is-IS=Tilgreinir kóða endurtekningarsniðmáts.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description of the job queue recurring template.', Comment = 'is-IS=Tilgreinir lýsingu endurtekningarsniðmáts.';
                }
                field("Time Zone"; Rec."Time Zone Display Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Time Zone', Comment = 'is-IS=Tímabelti';
                    ToolTip = 'Specifies the time zone for the job queue recurring template.', Comment = 'is-IS=Tilgreinir tímabelti endurtekningarsniðmáts.';

                    trigger OnAssistEdit()
                    var
                        TimeZone: Record "Time Zone";
                    begin
                        if TimeZone.Get(Rec."Time Zone Nr.") then;
                        if Page.RunModal(Page::"Time Zones Lookup", TimeZone) = Action::LookupOK then begin
                            Rec."Time Zone Nr." := TimeZone."No.";
                            Rec.CalcFields("Time Zone Display Name");
                        end;
                    end;
                }
            }
            group(Schedule)
            {
                Caption = 'Schedule', Comment = 'is-IS=Áætlun';
                field("Run on Mondays"; Rec."Run on Mondays")
                {
                    ToolTip = 'Specifies if the job queue entry will run on Mondays.', Comment = 'is-IS=Tilgreinir hvort vinnsluraðafærslan keyrist á mánudagum.';
                }
                field("Run on Tuesdays"; Rec."Run on Tuesdays")
                {
                    ToolTip = 'Specifies if the job queue entry will run on Tuesdays.', Comment = 'is-IS=Tilgreinir hvort vinnsluraðafærslan keyrist á þriðjudagum.';
                }
                field("Run on Wednesdays"; Rec."Run on Wednesdays")
                {
                    ToolTip = 'Specifies if the job queue entry will run on Wednesdays.', Comment = 'is-IS=Tilgreinir hvort vinnsluraðafærslan keyrist á miðvikudagum.';
                }
                field("Run on Thursdays"; Rec."Run on Thursdays")
                {
                    ToolTip = 'Specifies if the job queue entry will run on Thursdays.', Comment = 'is-IS=Tilgreinir hvort vinnsluraðafærslan keyrist á fimmtudagum.';
                }
                field("Run on Fridays"; Rec."Run on Fridays")
                {
                    ToolTip = 'Specifies if the job queue entry will run on Fridays.', Comment = 'is-IS=Tilgreinir hvort vinnsluraðafærslan keyrist á föstudagum.';
                }
                field("Run on Saturdays"; Rec."Run on Saturdays")
                {
                    ToolTip = 'Specifies if the job queue entry will run on Saturdays.', Comment = 'is-IS=Tilgreinir hvort vinnsluraðafærslan keyrist á laugardagum.';
                }
                field("Run on Sundays"; Rec."Run on Sundays")
                {
                    ToolTip = 'Specifies if the job queue entry will run on Sundays.', Comment = 'is-IS=Tilgreinir hvort vinnsluraðafærslan keyrist á sunnudagum.';
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ToolTip = 'Specifies the starting time for the job queue entry.', Comment = 'is-IS=Tilgreinir upphafstíma.';
                }
                field("Ending Time"; Rec."Ending Time")
                {
                    ToolTip = 'Specifies the ending time for the job queue entry.', Comment = 'is-IS=Tilgreinir lokatíma.';
                }
            }
            group(Recurrence)
            {
                Caption = 'Recurrence', Comment = 'is-IS=Endurteking';
                field("No. of Minutes between Runs"; Rec."No. of Minutes between Runs")
                {
                    ToolTip = 'Specifies the number of minutes between job queue entries.', Comment = 'is-IS=Tilgreinir fjölda mínúta milli keyrslu.';
                }
                field("Next Run Date Formula"; Rec."Next Run Date Formula")
                {
                    ToolTip = 'Specifies the formula to calculate the next run date.', Comment = 'is-IS=Tilgreinir formúla til að reikna næsta keyrsludag.';
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetUpTimeZoneFromUserPersonalization(Rec);
    end;

    trigger OnOpenPage()
    begin
        Rec.CalcFields("Time Zone Display Name");
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [Action::OK, Action::LookupOK] then
            Rec.ValidateRecurringSchedule();
    end;
}
