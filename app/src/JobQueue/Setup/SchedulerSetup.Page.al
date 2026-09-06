namespace Origo.Bifrost.Nornir;

using System.Environment;
using System.Threading;

/// <summary>
/// Setup page for the Job Queue Orchestrator configuration.
/// </summary>
page 10035536 "Scheduler Setup ori"
{
    AdditionalSearchTerms = 'Manage Job Queues,Job Queue Management,Job Queue Restarted,Job Queue Notification';
    ApplicationArea = All;
    Caption = 'Job Queue Orchestrator Setup', Comment = 'is-IS=Uppsetning vinnsluraðara';
    ContextSensitiveHelpPage = 'scheduler-setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Scheduler Setup ori";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General', Comment = 'is-IS=Almænn';
                field("Job Queue Category Code"; Rec."Job Queue Category Code")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the value of the Job Queue Category Code field.', Comment = 'is-IS=Tilgreinir gildi reitsins Flokkunarkóði vinnsluraða.';
                }
                field("Log Job Queue Activity"; Rec."Log Job Queue Activity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Log Job Queue Activity field.', Comment = 'is-IS=Tilgreinir gildi reitsins Skrá verkvirkni vinnsluraða.';
                }
                field("Job Queue User ID"; Rec."Job Queue User ID")
                {
                    ApplicationArea = All;
                    Enabled = JobQueueUserEnabled;
                    ToolTip = 'Specifies the User ID that will own the management job queue entry.  This user must have permission to run the job queue entries.  If no user is specified, the current user will be used.', Comment = 'is-IS=Tilgreinir notendaauðkenni sem mún stjarnár stjórn vinnsluraðafærslunni. Þssi notandi verður að hafa heimildir til að keyra vinnsluraðafærslurnar. Ef enginn notandi er tilgreindur er nnotilegur notandinn notaður.';
                    Visible = JobQueueUserEnabled;
                }
                field(JobQueueStatusField; JobQueueStatus)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Job Queue Orchestrator Status', Comment = 'is-IS=Staða vinnsluraðara';
                    Editable = false;
                    QuickEntry = false;
                    StyleExpr = JobQueueStyleExpr;
                    ToolTip = 'Specifies the job queue status that is required for Job Queue Orchestrator', Comment = 'is-IS=Tilgreinir staðu vinnsluraða sem er köfðuð fyrir vinnsluraðara';
                    trigger OnDrillDown()
                    begin
                        JobQueueManagement.ShowJobQueueEntry(Rec);
                        JobQueueManagement.GetJobQueueStatus(JobQueueStatus, JobQueueStyleExpr);
                    end;
                }
                field("Emit Telemetry"; Rec."Emit Telemetry")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if Telemetry is emitted for every execution.', Comment = 'is-IS=Tilgreinir hvort fjarmælingar eru sendar á hverri keyrslu.';
                }
            }
            group(TelegramGroup)
            {
                Caption = 'Telegram', Comment = 'is-IS=Telegram';
                field(TelegramBotTokenField; TelegramBotTokenText)
                {
                    ApplicationArea = All;
                    Caption = 'Telegram Bot Token', Comment = 'is-IS=Telegram-vélmennislykill';
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the Telegram Bot API token used to send notifications.', Comment = 'is-IS=Tilgreinir Telegram-vélmennislykil sem notaður er til að senda tilkynningar.';

                    trigger OnValidate()
                    begin
                        if TelegramBotTokenText = '***' then
                            exit;
                        Rec.SetTelegramBotToken(TelegramBotTokenText);
                        Rec.Modify(true);
                    end;
                }
                field(TelegramBotEnabledField; Rec.HasTelegramBotToken())
                {
                    ApplicationArea = All;
                    Caption = 'Bot Token Configured', Comment = 'is-IS=Vélmennislykill stilltur';
                    Editable = false;
                    ToolTip = 'Indicates whether a Telegram Bot Token has been configured.', Comment = 'is-IS=Gefur til kynna hvort Telegram-vélmennislykill hafi verið stilltur.';
                }
            }
            part("Job Queues"; "Sched. Entry Subform ori")
            {
                ApplicationArea = All;
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action(JobQueueEntries)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Job Queue Entries', Comment = 'is-IS=Vinnsluraðafærslur';
                Image = TaskList;
                RunObject = page "Job Queue Entries";
                ToolTip = 'See the job queue entries.', Comment = 'is-IS=Sjá vinnsluraðafærslurnar.';
            }
            action(RecurringTemplates)
            {
                ApplicationArea = All;
                Caption = 'Recurring Templates', Comment = 'is-IS=Endurtekningarsniðmát';
                Image = Template;
                RunObject = page "Recurring Templates ori";
                ToolTip = 'Manage recurring schedule templates for job queue entries.', Comment = 'is-IS=Faraó endurtekningarsniðmát fyrir vinnsluraðafærslur.';
            }
        }
        area(Processing)
        {
            action(RestartJobQueue)
            {
                ApplicationArea = All;
                Caption = 'Restart Job Queue', Comment = 'is-IS=Endurræsa verkroð';
                Image = ResetStatus;
                ToolTip = 'Restart the management job queue.', Comment = 'is-IS=Endurræsa stjórnunar verkroð.';
                trigger OnAction()
                begin
                    Rec.RestartManagementJobQueue();
                end;
            }
        }
    }

    var
        EnvironmentMgt: Codeunit "Environment Information";
        JobQueueManagement: Codeunit "Scheduler Mgt ori";
        JobQueueUserEnabled: Boolean;
        JobQueueStatus: Text;
        JobQueueStyleExpr: Text;
        TelegramBotTokenText: Text;

    trigger OnInit()
    begin
        JobQueueUserEnabled := EnvironmentMgt.IsOnPrem();
    end;

    trigger OnOpenPage()
    begin
        Rec.OnOpenEmptyRec();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        JobQueueManagement.GetJobQueueStatus(JobQueueStatus, JobQueueStyleExpr);
        if Rec.HasTelegramBotToken() then
            TelegramBotTokenText := '***'
        else
            TelegramBotTokenText := '';
    end;
}
