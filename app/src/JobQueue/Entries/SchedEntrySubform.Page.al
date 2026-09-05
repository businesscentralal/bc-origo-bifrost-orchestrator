namespace Origo.Bifrost.Nornir;

using System.Environment;
using System.Threading;

/// <summary>
/// List part page displaying Job Queue Orchestrator Entries as a subform.
/// </summary>
page 10035535 "Sched. Entry Subform ori"
{
    Caption = 'Orchestrator Entries', Comment = 'is-IS=Vinnsluraðarfærslur';
    CardPageId = "Scheduled Entry Card ori";
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Scheduled Entry ori";
    SourceTableView = sorting("Object Type to Run", "Object ID to Run");
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                Editable = false;
                field("Object Type to Run"; Rec."Object Type to Run")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Object Type to Run field.', Comment = 'is-IS=Tilgreinir gerð hluts til keyrslu.';
                }
                field("Object ID to Run"; Rec."Object ID to Run")
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    ToolTip = 'Specifies the value of the Object ID to Run field.', Comment = 'is-IS=Tilgreinir auðkenni hluts til keyrslu.';
                }
                field("Object Caption to Run"; Rec."Object Caption to Run")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Object Caption to Run field.', Comment = 'is-IS=Tilgreinir kafli hluts til keyrslu.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Description field.', Comment = 'is-IS=Tilgreinir lýsingu.';
                }
                field("Earliest Start Date/Time"; Rec."Earliest Start Date/Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Earliest Start Date/Time field.', Comment = 'is-IS=Tilgreinir fyrsta tíma til keyrslu.';
                }
                field("Recurring Template Code"; Rec."Recurring Template Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the recurring template to use for this orchestrator entry.', Comment = 'is-IS=Tilgreinir endurtekningarsniðmát.';
                }
                field("Time Zone"; Rec."Time Zone Display Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the time zone for this orchestrator entry.', Comment = 'is-IS=Tilgreinir tímabelti vinnsluraðara.';
                }
                field("No. of Minutes between Runs"; Rec."No. of Minutes between Runs")
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    ToolTip = 'Specifies the value of the No. of Minutes between Runs field.', Comment = 'is-IS=Tilgreinir fjölda mínúta milli keyrslu.';
                }
                field("Job Queue Category Code"; Rec."Job Queue Category Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Job Queue Category Code of Minutes between Runs field.', Comment = 'is-IS=Tilgreinir flokkunarkóða vinnsluraða.';
                }
                field("Job Queue User ID"; Rec."Job Queue User ID")
                {
                    ApplicationArea = All;
                    Enabled = JobQueueUserEnabled;
                    ToolTip = 'Specifies the User ID that will own the management job queue entry.  This user must have permission to run the job queue entries.  If no user is specified, the current user will be used.', Comment = 'is-IS=Tilgreinir notendaauðkenni sem mún eña vinnsluraðafærslunni.';
                    Visible = JobQueueUserEnabled;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Blocked field.', Comment = 'is-IS=Tilgreinir hvort færslan sé lokuð.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Notification Type"; Rec."Notification Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Notification Type field.', Comment = 'is-IS=Tilgreinir gerð tilkynningar.';
                }
                field("Notification Recipient"; Rec."Notification Recipient")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Notification Recipient field.', Comment = 'is-IS=Tilgreinir viðtakanda tilkynningar.';
                }
                field("Emit Telemetry"; Rec."Emit Telemetry")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if Telemetry is emitted for every execution.', Comment = 'is-IS=Tilgreinir hvort fjarmælingar eru sendar á hverri keyrslu.';
                }
                field("Client Credentials Code"; Rec."Client Credentials Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Client Credentials Code to use for this orchestrator entry.', Comment = 'is-IS=Tilgreinir kóða auðkenningar.';
                }
                field(Scheduled; Rec.Scheduled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if this schedule entry has been scheduled as a job queue entry.', Comment = 'is-IS=Tilgreinir hvort þessi færsla hefur verið tímasett.';
                }
                field("Run on Mondays"; Rec."Run on Mondays")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies that the job queue entry runs on Mondays.', Comment = 'is-IS=Tilgreinir að vinnsluraðafærslan keyrist á mánudagum.';
                }
                field("Run on Tuesdays"; Rec."Run on Tuesdays")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies that the job queue entry runs on Tuesdays.', Comment = 'is-IS=Tilgreinir að vinnsluraðafærslan keyrist á þriðjudagum.';
                }
                field("Run on Wednesdays"; Rec."Run on Wednesdays")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies that the job queue entry runs on Wednesdays.', Comment = 'is-IS=Tilgreinir að vinnsluraðafærslan keyrist á miðvikudagum.';
                }
                field("Run on Thursdays"; Rec."Run on Thursdays")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies that the job queue entry runs on Thursdays.', Comment = 'is-IS=Tilgreinir að vinnsluraðafærslan keyrist á fimmtudagum.';
                }
                field("Run on Fridays"; Rec."Run on Fridays")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies that the job queue entry runs on Fridays.', Comment = 'is-IS=Tilgreinir að vinnsluraðafærslan keyrist á föstudagum.';
                }
                field("Run on Saturdays"; Rec."Run on Saturdays")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies that the job queue entry runs on Saturdays.', Comment = 'is-IS=Tilgreinir að vinnsluraðafærslan keyrist á laugardagum.';
                }
                field("Run on Sundays"; Rec."Run on Sundays")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies that the job queue entry runs on Sundays.', Comment = 'is-IS=Tilgreinir að vinnsluraðafærslan keyrist á sunnudagum.';
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the earliest time of the day that the recurring job queue entry is to be run.', Comment = 'is-IS=Tilgreinir fyrsta tíma dagsins til keyrslu.';
                }
                field("Ending Time"; Rec."Ending Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the latest time of the day that the recurring job queue entry is to be run.', Comment = 'is-IS=Tilgreinir síðasta tíma dagsins til keyrslu.';
                }
                field("Next Run Date Formula"; Rec."Next Run Date Formula")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date formula for calculating the next run date.', Comment = 'is-IS=Tilgreinir formúlu dagsetningar til næstu keyrslu.';
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
                Scope = Repeater;
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
                Caption = 'Reschedule', Comment = 'is-IS=Endurstilla';
                Image = DebugNext;
                Scope = Repeater;
                ToolTip = 'Reschedule this job.', Comment = 'is-IS=Endurstilla þetta verk.';

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
                Caption = 'Schedule Now', Comment = 'is-IS=Tímasetja núna';
                Image = DebugNext;
                Scope = Repeater;
                ToolTip = 'Reschedule this job for execution now.', Comment = 'is-IS=Endurstilla þetta verk til keyrslu núna.';

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
            action(ActivityLog)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Activity Log', Comment = 'is-IS=Aðgerðakladdi';
                Image = Log;
                Scope = Repeater;
                ToolTip = 'See the job queue Orchestrator activity.', Comment = 'is-IS=Sjá aðgerðir vinnsluraðara.';

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
                Caption = 'Job Queue Entry', Comment = 'is-IS=Vinnsluraðafærsla';
                Enabled = JobQueueEntryFound;
                Image = TaskList;
                RunObject = page "Job Queue Entry Card";
                RunPageLink = ID = field(ID);
                Scope = Repeater;
                ToolTip = 'See the job queue entry card.', Comment = 'is-IS=Sjá vinnsluraðafærslu spjaldið.';
            }
            action(DrillDown)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Drill Down', Comment = 'is-IS=Kafanleg';
                Enabled = JobQueueEntryFound;
                Image = Card;
                Scope = Repeater;
                ToolTip = 'Drill down to the related entry.', Comment = 'is-IS=Kafa niður í tengda færslu.';
                trigger OnAction()
                begin
                    Rec.DrillDownToRelatedEntry();
                end;
            }
        }
    }

    var
        JobQueueEntry: Record "Job Queue Entry";
        EnvironmentMgt: Codeunit "Environment Information";
        JobQueueEntryFound: Boolean;
        JobQueueUserEnabled: Boolean;
        EntryRemovedMsg: Label 'Job Queue Entry has been removed. New entry will be created by the Job Queue Orchestrator.', Comment = 'is-IS=Vinnsluröðarfærslu hefur verið eytt. Ný færsla verður búin til af vinnsluraðaráætlara.';

    trigger OnInit()
    begin
        JobQueueUserEnabled := EnvironmentMgt.IsOnPrem();
    end;

    trigger OnOpenPage()
    begin
        Rec.CalcFields("Time Zone Display Name");
        Rec.RegisterJobQueueCodeunits();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        JobQueueEntryFound := Rec.GetJobQueueEntryOnce(JobQueueEntry);
    end;
}
