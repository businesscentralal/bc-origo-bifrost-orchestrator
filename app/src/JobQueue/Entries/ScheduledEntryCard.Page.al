namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.DateTime;
using System.Environment;
using System.Threading;

/// <summary>
/// Card page for viewing and editing a single Job Queue Orchestrator Entry.
/// </summary>
page 10035544 "Scheduled Entry Card ori"
{
    Caption = 'Job Queue Orchestrator Entry Card', Comment = 'is-IS=Spjald vinnsluraðarafærslu';
    DataCaptionFields = "Object Type to Run", "Object Caption to Run";
    ContextSensitiveHelpPage = 'scheduled-entry-card';
    PageType = Card;
    SourceTable = "Scheduled Entry ori";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General', Comment = 'is-IS=Almænn';
                field("Object Type to Run"; Rec."Object Type to Run")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the object to be run by the job queue entry.', Comment = 'is-IS=Tilgreinir gerð hluts til keyrslu.';
                }
                field("Object ID to Run"; Rec."Object ID to Run")
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the ID of the object to be run by the job queue entry.', Comment = 'is-IS=Tilgreinir auðkenni hluts til keyrslu.';
                }
                field("Object Caption to Run"; Rec."Object Caption to Run")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the caption of the object to be run by the job queue entry.', Comment = 'is-IS=Tilgreinir kafli hluts til keyrslu.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the job queue orchestrator entry.', Comment = 'is-IS=Tilgreinir lúsingu vinnsluraðarfærslu.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownToRelatedEntry();
                    end;
                }
                group(ReportOutputGroup)
                {
                    ShowCaption = false;
                    Visible = Rec."Object Type to Run" = Rec."Object Type to Run"::Report;
                    field("Report Output Type"; Rec."Report Output Type")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Report Output Type field.', Comment = 'is-IS=Tilgreinir gerð úttaks skýrslu.';
                    }
                }
                field("Job Queue Category Code"; Rec."Job Queue Category Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code of the job queue category to which the entry belongs.', Comment = 'is-IS=Tilgreinir kóða flokks vinnsluraða.';
                }
                field("Job Queue User ID"; Rec."Job Queue User ID")
                {
                    ApplicationArea = All;
                    Enabled = JobQueueUserEnabled;
                    ToolTip = 'Specifies the User ID that will own the job queue entry. This user must have permission to run the job queue entries. If no user is specified, the current user will be used.', Comment = 'is-IS=Tilgreinir notendaauðkenni sem mún eña vinnsluraðafærslunni.';
                    Visible = JobQueueUserEnabled;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the orchestrator entry is blocked.', Comment = 'is-IS=Tilgreinir hvort vinnsluraðarfærslan sé lokáð.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Emit Telemetry"; Rec."Emit Telemetry")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if telemetry is emitted for every execution.', Comment = 'is-IS=Tilgreinir hvort fjarmælingar eru sendar á hverri keyrslu.';
                }
                field("Client Credentials Code"; Rec."Client Credentials Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Client Credentials Code to use for this orchestrator entry.', Comment = 'is-IS=Tilgreinir kóða kliensta auðkeninga.';
                }
                field("Earliest Start Date/Time"; Rec."Earliest Start Date/Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the earliest date and time when the job queue entry should be run.', Comment = 'is-IS=Tilgreinir fyrsti daga og tíma þegar vinnsluraðafærslan skyldi keyrast.';
                }
                field("Recurring Template Code"; Rec."Recurring Template Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the recurring template to use for this orchestrator entry.', Comment = 'is-IS=Tilgreinir endurtekningarsniðmát.';
                }
                field(Scheduled; Rec.Scheduled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if this schedule entry has been scheduled as a job queue entry.', Comment = 'is-IS=Tilgreinir hvort þssari vinnsluraðafærslu hér verið tímasett.';
                }
            }
            group(RetryPolicy)
            {
                Caption = 'Retry Policy', Comment = 'is-IS=Endurprófanarstefna';
                field("Retry Policy"; Rec."Retry Policy")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the retry policy for this orchestrator entry. Always - entry is always restarted on error. Three Times - entry is restarted only if it has failed fewer than 3 times. Never - entry is never automatically restarted on error.', Comment = 'is-IS=Tilgreinir endurprófanarstefnu. Alltaf - færsla er alltaf endurræsin við villu. Þrjú sinni - færsla er endurræsin bara ef hún hefur mistekist færri en 3 sinnum. Aldrei - færsla er aldrei endurræsin sjálfkrafa við villu.';
                }
                field("Errors Since Last Success"; Rec."Errors Since Last Success")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of consecutive errors since the last successful execution. This counter resets when the entry runs successfully.', Comment = 'is-IS=Tilgreinir fjölda villna frá síðustu gangi. Þessi telji endurstillast þegar færslan keyrist með góðum árangri.';
                }
            }
            group(Recurrence)
            {
                Caption = 'Recurrence', Comment = 'is-IS=Endurtekning';
                Editable = Rec."Recurring Template Code" = '';
                group(RunOnDays)
                {
                    ShowCaption = false;
                    field("Run on Mondays"; Rec."Run on Mondays")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies that the job queue entry runs on Mondays.', Comment = 'is-IS=Tilgreinir að vinnsluraðarafærslan keyrist á mánudaga.';
                    }
                    field("Run on Tuesdays"; Rec."Run on Tuesdays")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies that the job queue entry runs on Tuesdays.', Comment = 'is-IS=Tilgreinir að vinnsluraðarafærslan keyrist á þriðjudaga.';
                    }
                    field("Run on Wednesdays"; Rec."Run on Wednesdays")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies that the job queue entry runs on Wednesdays.', Comment = 'is-IS=Tilgreinir að vinnsluraðarafærslan keyrist á miðvikudaga.';
                    }
                    field("Run on Thursdays"; Rec."Run on Thursdays")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies that the job queue entry runs on Thursdays.', Comment = 'is-IS=Tilgreinir að vinnsluraðarafærslan keyrist á fimmtudaga.';
                    }
                    field("Run on Fridays"; Rec."Run on Fridays")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies that the job queue entry runs on Fridays.', Comment = 'is-IS=Tilgreinir að vinnsluraðarafærslan keyrist á föstudaga.';
                    }
                    field("Run on Saturdays"; Rec."Run on Saturdays")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies that the job queue entry runs on Saturdays.', Comment = 'is-IS=Tilgreinir að vinnsluraðarafærslan keyrist á laugardaga.';
                    }
                    field("Run on Sundays"; Rec."Run on Sundays")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies that the job queue entry runs on Sundays.', Comment = 'is-IS=Tilgreinir að vinnsluraðarafærslan keyrist á sunnudaga.';
                    }
                }
                field("Time Zone"; Rec."Time Zone Display Name")
                {
                    ApplicationArea = All;
                    Caption = 'Time Zone', Comment = 'is-IS=Tímabelti';
                    Editable = false;
                    ToolTip = 'Specifies the time zone for this orchestrator entry.', Comment = 'is-IS=Tilgreinir tímabeltið fyrir þessa vinnsluraðarafærslu.';

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
                field("Next Run Date Formula"; Rec."Next Run Date Formula")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date formula for calculating the next run date.', Comment = 'is-IS=Tilgreinir dagsetningarformúlu fyrir útreikning næstu keyrsludagsetningar.';
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the earliest time of the day that the recurring job queue entry is to be run.', Comment = 'is-IS=Tilgreinir fyrsta tíma dagsins sem endurtekin vinnsluraðarafærsla á að keyra.';
                }
                field("Ending Time"; Rec."Ending Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the latest time of the day that the recurring job queue entry is to be run.', Comment = 'is-IS=Tilgreinir síðasta tíma dagsins sem endurtekin vinnsluraðarafærsla á að keyra.';
                }
                field("No. of Minutes between Runs"; Rec."No. of Minutes between Runs")
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    ToolTip = 'Specifies the minimum number of minutes that are to pass between runs of the job queue entry.', Comment = 'is-IS=Tilgreinir lágmarksfjölda mínútna milli keyrslu vinnsluraðarafærslu.';
                }
            }
            group(Notification)
            {
                Caption = 'Notification', Comment = 'is-IS=Tilkynning';
                field("Notification Type"; Rec."Notification Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the notification type for this orchestrator entry.', Comment = 'is-IS=Tilgreinir gerð tilkynningar fyrir þessa vinnsluraðarafærslu.';

                    trigger OnValidate()
                    begin
                        GetNotificationReceipientMandatory();
                        TryPopulateTelegramChatId();
                    end;
                }
                field("Notification Recipient"; Rec."Notification Recipient")
                {
                    ApplicationArea = All;
                    ShowMandatory = NotificationReceipientMandatory;
                    ToolTip = 'Specifies the recipient of the notification.', Comment = 'is-IS=Tilgreinir viðtakanda tilkynningarinnar.';

                    trigger OnAssistEdit()
                    var
                        NotificationInterface: Interface "Notification ori";
                    begin
                        NotificationInterface := Rec."Notification Type";
                        NotificationInterface.SendTestNotification(Rec);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunInForeground)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Run once (foreground)', Comment = 'is-IS=Keyra einu sinni (forgrunni)';
                Image = DebugNext;
                ToolTip = 'Run a copy of this job once in foreground.', Comment = 'is-IS=Keyra afrit af þessu verki einu sinni í forgrunni.';

                trigger OnAction()
                var
                    JobQueueManagement: Codeunit "Scheduler Mgt ori";
                begin
                    JobQueueManagement.RunJobQueueEntryOnce(Rec);
                end;
            }
            action(Reschedule)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reschedule', Comment = 'is-IS=Enduáætla';
                Image = Refresh;
                ToolTip = 'Reschedule this job.', Comment = 'is-IS=Enduáætla þetta verk.';

                trigger OnAction()
                begin
                    Rec.TestField(Blocked, false);
                    Rec.DeleteJobQueueEntry();
                    Message(EntryRemovedMsg);
                end;
            }
            action(ScheduleNow)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Schedule Now', Comment = 'is-IS=Áætla núna';
                Image = Start;
                ToolTip = 'Reschedule this job for execution now.', Comment = 'is-IS=Enduáætla þetta verk til keyrslu strax.';

                trigger OnAction()
                var
                    JobQueueHandler: Codeunit "Scheduler Handler ori";
                    ApiClient: Codeunit "Scheduler API Client ori";
                begin
                    Rec.TestField(Blocked, false);
                    if ApiClient.Initialize(Rec) then begin
                        ApiClient.CallUpdateJobQueueEntry(Rec);
                        CurrPage.Update();
                        exit;
                    end;
                    Rec.DeleteJobQueueEntry();
                    JobQueueHandler.ScheduleTask(Rec);
                    CurrPage.Update();
                end;
            }
        }
        area(Navigation)
        {
            action(ActivityLog)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Activity Log', Comment = 'is-IS=Aðgerðaskrá';
                Image = Log;
                ToolTip = 'See the job queue orchestrator activity.', Comment = 'is-IS=Sjá virkni vinnsluraðarans.';

                trigger OnAction()
                var
                    JobsMgt: Codeunit "Scheduler Mgt ori";
                begin
                    JobsMgt.ShowActivityLog(Rec);
                end;
            }
            action(JobQueueEntryAction)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Job Queue Entry', Comment = 'is-IS=Vinnsluraðarafærsla';
                Enabled = JobQueueEntryFound;
                Image = TaskList;
                RunObject = page "Job Queue Entry Card";
                RunPageLink = ID = field(ID);
                ToolTip = 'See the job queue entry card.', Comment = 'is-IS=Sjá spjald vinnsluraðarafærslu.';
            }
        }
    }

    var
        JobQueueEntry: Record "Job Queue Entry";
        EnvironmentMgt: Codeunit "Environment Information";
        JobQueueEntryFound: Boolean;
        JobQueueUserEnabled: Boolean;
        NotificationReceipientMandatory: Boolean;
        EntryRemovedMsg: Label 'Job Queue Entry has been removed. New entry will be created by the Job Queue Orchestrator.', Comment = 'is-IS=Vinnsluröðarfærslu hefur verið eytt. Ný færsla verður búin til af vinnsluraðaráætlara.';

    trigger OnInit()
    begin
        JobQueueUserEnabled := EnvironmentMgt.IsOnPrem();
    end;

    trigger OnOpenPage()
    begin
        Rec.CalcFields("Time Zone Display Name");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if IsNullGuid(Rec.ID) then
            Rec.ID := CreateGuid();

        if Rec."Earliest Start Date/Time" = 0DT then
            Rec."Earliest Start Date/Time" := CurrentDateTime();

        if not Rec.Blocked then
            Rec.Blocked := true;

        JobQueueEntryFound := false;

        if Rec."No. of Minutes between Runs" = 0 then
            Rec.Validate("No. of Minutes between Runs");
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Rec.TestField("Object ID to Run");
        Rec.ValidateRecurringSchedule();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        JobQueueEntryFound := Rec.GetJobQueueEntryOnce(JobQueueEntry);
        GetNotificationReceipientMandatory();
    end;

    local procedure GetNotificationReceipientMandatory()
    var
        NotificationInterface: Interface "Notification ori";
    begin
        NotificationInterface := Rec."Notification Type";
        NotificationReceipientMandatory := NotificationInterface.IsNotificationReceipientMandatory();
    end;

    local procedure TryPopulateTelegramChatId()
    var
        UserSetup: Record "User Setup ori";
    begin
        if Rec."Notification Type" <> Rec."Notification Type"::Telegram then
            exit;
        if Rec."Notification Recipient" <> '' then
            exit;
        if UserSetup.Get(UserSecurityId()) then
            if UserSetup."Telegram Chat ID ori" <> '' then
                Rec."Notification Recipient" := UserSetup."Telegram Chat ID ori";
    end;
}
