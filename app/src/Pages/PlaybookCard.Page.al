/// <summary>
/// Card page for configuring a Bifrost Playbook: header fields, steps, and schedule.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

page 10035548 "Playbook Card ori"
{
    Caption = 'Bifrost Playbook', Comment = 'is-IS=Bifröst keðja';
    ContextSensitiveHelpPage = 'playbook-card';
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "Playbook ori";
    UsageCategory = None;
    DataCaptionExpression = Rec.Code;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General', Comment = 'is-IS=Almennt';

                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique code for this playbook.', Comment = 'is-IS=Tilgreinir einstakan kóða fyrir þessa keðju.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the playbook.', Comment = 'is-IS=Tilgreinir lýsingu keðjunnar.';
                }
            }
            part(Steps; "Playbook Steps Subpage ori")
            {
                ApplicationArea = All;
                SubPageLink = "Playbook Code" = field(Code);
                Caption = 'Steps', Comment = 'is-IS=Skref';
            }
            part(Conditions; "Playbook Cond. Subpage ori")
            {
                ApplicationArea = All;
                Provider = Steps;
                SubPageLink = "Playbook Code" = field("Playbook Code"), "Step No." = field("Step No.");
                Caption = 'Step Conditions', Comment = 'is-IS=Skilyrði skrefa';
            }
            group(Schedule)
            {
                Caption = 'Schedule', Comment = 'is-IS=Tímaáætlun';

                field(Scheduled; Rec.Scheduled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates whether this playbook has an active Orchestrator Entry.', Comment = 'is-IS=Gefur til kynna hvort keðjan hafi virka vinnsluraðarstjórafærslu.';
                }
            }
            group(InitialRequest)
            {
                Caption = 'Initial Request', Comment = 'is-IS=Upphafsbeðni';

                field(InitialRequestTemplate; InitialRequestText)
                {
                    ApplicationArea = All;
                    Caption = 'Initial Request JSON', Comment = 'is-IS=Upphafsbeðni JSON';
                    ToolTip = 'JSON payload passed to the first step when no runtime initialRequest is provided.', Comment = 'is-IS=JSON gagnahlað sent í fyrsta skref þegar engin keyrslubeðni er gefin.';
                    MultiLine = true;

                    trigger OnValidate()
                    begin
                        Rec.SetInitialRequestTemplate(InitialRequestText);
                        Rec.Modify(true);
                    end;
                }
            }
        }
        area(FactBoxes)
        {
            part(StepTemplate; "Playbook Step Template FB ori")
            {
                ApplicationArea = All;
                Provider = Steps;
                SubPageLink = "Playbook Code" = field("Playbook Code"), "Step No." = field("Step No.");
                Caption = 'Request Template', Comment = 'is-IS=Sniðmát beiðni';
            }
            part(LastRunFB; "Playbook Last Run FB ori")
            {
                ApplicationArea = All;
                SubPageLink = ID = field("Last Run Instance ID");
                Caption = 'Last Execution', Comment = 'is-IS=Síðasta keyrsla';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunNow)
            {
                Caption = 'Run Now', Comment = 'is-IS=Keyra núna';
                ApplicationArea = All;
                ToolTip = 'Execute the playbook immediately in the foreground.', Comment = 'is-IS=Keyra keðjuna strax í forgrunni.';
                Image = Start;

                trigger OnAction()
                var
                    Runner: Codeunit "Playbook Runner ori";
                    InitialRequest: BigText;
                    FinalResponse: BigText;
                    InstanceId: Guid;
                    InitialRequestText: Text;
                begin
                    InitialRequestText := Rec.GetInitialRequestTemplate();
                    if InitialRequestText <> '' then
                        InitialRequest.AddText(InitialRequestText);

                    Runner.Run(Rec.Code, InitialRequest, FinalResponse, InstanceId);

                    Rec.Get(Rec.Code);
                    Rec."Last Run Instance ID" := InstanceId;
                    Rec."Last Run At" := CurrentDateTime();
                    Rec."Last Run Status" := GetInstanceStatus(InstanceId);
                    Rec.Modify();

                    Message(RunCompletedMsg, Rec.Code, Rec."Last Run Status");
                end;
            }
            action(ScheduleAction)
            {
                Caption = 'Schedule', Comment = 'is-IS=Tímasetja';
                ApplicationArea = All;
                ToolTip = 'Create an Orchestrator Entry to run this playbook on a recurring schedule.', Comment = 'is-IS=Búa til vinnsluraðarstjórafærslu til að keyra þessa keðju reglulega.';
                Image = Timesheet;
                Enabled = not Rec.Scheduled;

                trigger OnAction()
                var
                    Wizard: Page "Schedule Playbook ori";
                begin
                    Wizard.SetPlaybook(Rec);
                    if Wizard.RunModal() = Action::OK then begin
                        CurrPage.Update(false);
                        Message(ScheduledMsg, Rec.Code);
                    end;
                end;
            }
            action(OpenOrchestratorEntry)
            {
                Caption = 'Orchestrator Entry', Comment = 'is-IS=Vinnsluraðarstjórafærsla';
                ApplicationArea = All;
                ToolTip = 'Open the linked Orchestrator Entry to manage the schedule.', Comment = 'is-IS=Opna tengda vinnsluraðarstjórafærslu til að stjórna áætlun.';
                Image = SetupList;
                Enabled = Rec.Scheduled;

                trigger OnAction()
                var
                    Entry: Record "Scheduled Entry ori";
                begin
                    Entry.Get(Rec."Orchestrator Entry ID");
                    Page.Run(Page::"Scheduled Entry Card ori", Entry);
                end;
            }
        }
        area(Navigation)
        {
            action(Instances)
            {
                Caption = 'Execution Log', Comment = 'is-IS=Keyrsluskrá';
                ApplicationArea = All;
                ToolTip = 'View execution history for this playbook.', Comment = 'is-IS=Skoða keyrsluskrá fyrir þessa keðju.';
                Image = Log;
                RunObject = page "Playbook Instances ori";
                RunPageLink = "Playbook Code" = field(Code);
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'is-IS=Vinna';

                actionref(RunNow_Promoted; RunNow) { }
                actionref(Schedule_Promoted; ScheduleAction) { }
                actionref(OpenEntry_Promoted; OpenOrchestratorEntry) { }
            }
            group(Category_Report)
            {
                Caption = 'History', Comment = 'is-IS=Saga';

                actionref(Instances_Promoted; Instances) { }
            }
        }
    }

    var
        InitialRequestText: Text;
        RunCompletedMsg: Label 'Playbook %1 completed with status: %2.', Comment = '%1 = playbook code, %2 = status, is-IS=Keðja %1 lauk með stöðu: %2.';
        ScheduledMsg: Label 'Playbook %1 has been scheduled.', Comment = '%1 = playbook code, is-IS=Keðja %1 hefur verið tímasett.';

    trigger OnAfterGetCurrRecord()
    begin
        InitialRequestText := Rec.GetInitialRequestTemplate();
    end;

    local procedure GetInstanceStatus(InstanceId: Guid): Enum "Playbook Inst. Status ori"
    var
        Instance: Record "Playbook Instance ori";
    begin
        if Instance.Get(InstanceId) then
            exit(Instance.Status);
        exit("Playbook Inst. Status ori"::Failed);
    end;
}
