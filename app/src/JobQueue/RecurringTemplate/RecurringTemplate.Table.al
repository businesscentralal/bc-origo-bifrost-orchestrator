/// <summary>
/// Defines reusable recurring schedule templates for Job Queue Orchestrator Entries.
/// </summary>
namespace Origo.Bifrost.Nornir;

using System.DateTime;
using System.Environment.Configuration;

table 10035537 "Recurring Template ori"
{
    Caption = 'Job Queue Recurring Template', Comment = 'is-IS=Endurtekningarsniðmát vinnsluraða';
    DataClassification = SystemMetadata;
    LookupPageId = "Recurring Templates ori";
    DrillDownPageId = "Recurring Templates ori";

    fields
    {
        field(10; Code; Code[20])
        {
            Caption = 'Code', Comment = 'is-IS=Kóði';
            DataClassification = SystemMetadata;
            NotBlank = true;
        }
        field(20; Description; Text[100])
        {
            Caption = 'Description', Comment = 'is-IS=Lýsing';
            DataClassification = SystemMetadata;
        }
        field(31; "Time Zone Nr."; Integer)
        {
            Caption = 'Time Zone Nr.', Comment = 'is-IS=Númer tímabeltis';
            DataClassification = SystemMetadata;
            TableRelation = "Time Zone";
        }
        field(35; "Time Zone Display Name"; Text[250])
        {
            CalcFormula = lookup("Time Zone"."Display Name" where("No." = field("Time Zone Nr.")));
            Caption = 'Time Zone', Comment = 'is-IS=Tímabelti';
            Editable = false;
            FieldClass = FlowField;
        }
        field(40; "Run on Mondays"; Boolean)
        {
            Caption = 'Run on Mondays', Comment = 'is-IS=Keyra á mánudagum';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                Clear("Next Run Date Formula");
                ValidateWeekday();
            end;
        }
        field(50; "Run on Tuesdays"; Boolean)
        {
            Caption = 'Run on Tuesdays', Comment = 'is-IS=Keyra á þriðjudagum';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                Clear("Next Run Date Formula");
                ValidateWeekday();
            end;
        }
        field(60; "Run on Wednesdays"; Boolean)
        {
            Caption = 'Run on Wednesdays', Comment = 'is-IS=Keyra á miðvikudagum';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                Clear("Next Run Date Formula");
                ValidateWeekday();
            end;
        }
        field(70; "Run on Thursdays"; Boolean)
        {
            Caption = 'Run on Thursdays', Comment = 'is-IS=Keyra á fimmtudagum';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                Clear("Next Run Date Formula");
                ValidateWeekday();
            end;
        }
        field(80; "Run on Fridays"; Boolean)
        {
            Caption = 'Run on Fridays', Comment = 'is-IS=Keyra á föstudagum';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                Clear("Next Run Date Formula");
                ValidateWeekday();
            end;
        }
        field(90; "Run on Saturdays"; Boolean)
        {
            Caption = 'Run on Saturdays', Comment = 'is-IS=Keyra á laugardagum';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                Clear("Next Run Date Formula");
                ValidateWeekday();
            end;
        }
        field(100; "Run on Sundays"; Boolean)
        {
            Caption = 'Run on Sundays', Comment = 'is-IS=Keyra á sunnudagum';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                Clear("Next Run Date Formula");
                ValidateWeekday();
            end;
        }
        field(110; "Starting Time"; Time)
        {
            Caption = 'Starting Time', Comment = 'is-IS=Upphafstími';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                ValidateTimeRange();
            end;
        }
        field(120; "Ending Time"; Time)
        {
            Caption = 'Ending Time', Comment = 'is-IS=Lokatími';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                ValidateTimeRange();
            end;
        }
        field(130; "No. of Minutes between Runs"; Integer)
        {
            Caption = 'No. of Minutes between Runs', Comment = 'is-IS=Fjöldi mínúta milli keyrslu';
            DataClassification = SystemMetadata;
            MinValue = 0;

            trigger OnValidate()
            begin
                Clear("Next Run Date Formula");
                SetMinimumNumberOfMinutesBetweenRuns();
            end;
        }
        field(140; "Next Run Date Formula"; DateFormula)
        {
            Caption = 'Next Run Date Formula', Comment = 'is-IS=Formúla næsta keyrsludags';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                Clear("No. of Minutes between Runs");
                ClearRunOnWeekdays();
                ValidateRecurringSchedule();
            end;
        }
    }

    keys
    {
        key(Key1; Code)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Code, Description, "Time Zone Nr.")
        {
        }
        fieldgroup(Brick; Code, Description)
        {
        }
    }

    var
        NoValidRecurringScheduleErr: Label 'At least one weekday or a next run date formula must be configured.', Comment = 'is-IS=Að minnsta kosti einn vikudag eða næstu keyrsludagsetningarformúlu verður að stilla.';
        EndingTimeBeforeStartingTimeErr: Label 'Ending Time must be greater than Starting Time.', Comment = 'is-IS=Lokatími verður að vera stærri en upphafstími.';

    trigger OnModify()
    begin
        ValidateRecurringSchedule();
    end;

    local procedure ValidateWeekday()
    begin
        ValidateRecurringSchedule();
        SetMinimumNumberOfMinutesBetweenRuns();
    end;

    local procedure ValidateTimeRange()
    begin
        if ("Starting Time" <> 0T) and ("Ending Time" <> 0T) and ("Ending Time" <= "Starting Time") then
            Error(EndingTimeBeforeStartingTimeErr);
    end;

    local procedure ClearRunOnWeekdays()
    begin
        "Run on Fridays" := false;
        "Run on Mondays" := false;
        "Run on Saturdays" := false;
        "Run on Sundays" := false;
        "Run on Thursdays" := false;
        "Run on Tuesdays" := false;
        "Run on Wednesdays" := false;
    end;

    local procedure SetMinimumNumberOfMinutesBetweenRuns()
    begin
        if not IsNextRunDateFormulaSet() and (Rec."No. of Minutes between Runs" = 0) then
            Rec."No. of Minutes between Runs" := 1440; // Default to one day
    end;

    /// <summary>
    /// Validates that at least one weekday or a next run date formula is configured.
    /// </summary>
    procedure ValidateRecurringSchedule()
    begin
        if not (HasWeekdaySelected() or IsNextRunDateFormulaSet()) then
            Error(NoValidRecurringScheduleErr);
    end;

    local procedure HasWeekdaySelected(): Boolean
    begin
        exit("Run on Mondays"
            or "Run on Tuesdays"
            or "Run on Wednesdays"
            or "Run on Thursdays"
            or "Run on Fridays"
            or "Run on Saturdays"
            or "Run on Sundays");
    end;

    /// <summary>
    /// Checks whether the Next Run Date Formula field has a value.
    /// </summary>
    /// <returns>True if a date formula is configured.</returns>
    procedure IsNextRunDateFormulaSet(): Boolean
    begin
        exit(Format("Next Run Date Formula") <> '');
    end;

    procedure InsertSampleTemplates()
    begin
        InsertIfNotExists('WEEKDAYS', 'Weekdays (Mon-Fri, every 30 min)', true, true, true, true, true, false, false, 080000T, 170000T, 30);
        InsertIfNotExists('DAILY', 'Daily (Mon-Sun, once a day)', true, true, true, true, true, true, true, 060000T, 0T, 0);
        InsertIfNotExists('HOURLY-24/7', 'Hourly (Mon-Sun, 24/7)', true, true, true, true, true, true, true, 0T, 0T, 60);
        InsertIfNotExists('NIGHTLY', 'Nightly (Mon-Fri, 22:00-06:00)', true, true, true, true, true, false, false, 220000T, 060000T, 60);
        InsertIfNotExists('WEEKLY-MON', 'Weekly on Mondays', true, false, false, false, false, false, false, 060000T, 0T, 0);
    end;

    local procedure InsertIfNotExists(NewCode: Code[20]; NewDescription: Text[100]; Mon: Boolean; Tue: Boolean; Wed: Boolean; Thu: Boolean; Fri: Boolean; Sat: Boolean; Sun: Boolean; StartTime: Time; EndTime: Time; MinutesBetween: Integer)
    var
        RecTemplate: Record "Recurring Template ori";
    begin
        if RecTemplate.Get(NewCode) then
            exit;
        RecTemplate.Init();
        RecTemplate.Code := NewCode;
        RecTemplate.Description := NewDescription;
        RecTemplate.SetUpTimeZoneFromUserPersonalization(RecTemplate);
        RecTemplate."Run on Mondays" := Mon;
        RecTemplate."Run on Tuesdays" := Tue;
        RecTemplate."Run on Wednesdays" := Wed;
        RecTemplate."Run on Thursdays" := Thu;
        RecTemplate."Run on Fridays" := Fri;
        RecTemplate."Run on Saturdays" := Sat;
        RecTemplate."Run on Sundays" := Sun;
        RecTemplate."Starting Time" := StartTime;
        RecTemplate."Ending Time" := EndTime;
        RecTemplate."No. of Minutes between Runs" := MinutesBetween;
        RecTemplate.Insert(true);
    end;

    /// <summary>
    /// Sets the Time Zone Code from the current user's personalization settings.
    /// </summary>
    /// <param name="Recurring Template ori">The recurring template record to update with the user's time zone.</param>
    procedure SetUpTimeZoneFromUserPersonalization(var "Recurring Template ori": Record "Recurring Template ori")
    var
        UserPersonalization: Record "User Personalization";
        TimeZone: Record "Time Zone";
    begin
        if UserPersonalization.Get(UserSecurityId()) then begin
            TimeZone.SetLoadFields("No.");
            TimeZone.SetRange(ID, UserPersonalization."Time Zone");
            if TimeZone.FindFirst() then
                "Recurring Template ori"."Time Zone Nr." := TimeZone."No.";
        end;
    end;
}
