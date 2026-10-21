/// <summary>
/// Request page wizard for scheduling a playbook as an Orchestrator Entry.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using System.Threading;

page 10035584 "Schedule Playbook ori"
{
    Extensible = false;
    Caption = 'Schedule Playbook', Comment = 'is-IS=Tímasetja keðju';
    ContextSensitiveHelpPage = 'schedule-playbook';
    PageType = StandardDialog;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(ScheduleSettings)
            {
                Caption = 'Schedule', Comment = 'is-IS=Áætlun';

                field(RecurringTemplateCode; RecurringTemplateCode)
                {
                    Caption = 'Recurring Template Code', Comment = 'is-IS=Endurtekningarsniðmát';
                    ApplicationArea = All;
                    ToolTip = 'Select the recurring schedule template.', Comment = 'is-IS=Veldu endurtekningarsniðmát.';
                    TableRelation = "Recurring Template ori";
                    ShowMandatory = true;
                }
            }
            group(NotificationSettings)
            {
                Caption = 'Notification', Comment = 'is-IS=Tilkynning';

                field(NotificationType; NotificationType)
                {
                    Caption = 'Notification Type', Comment = 'is-IS=Gerð tilkynningar';
                    ApplicationArea = All;
                    ToolTip = 'Select the notification type for error reporting.', Comment = 'is-IS=Veldu gerð tilkynningar fyrir villutilkynningar.';

                    trigger OnValidate()
                    begin
                        NotificationRecipient := '';
                    end;
                }
                field(NotificationRecipient; NotificationRecipient)
                {
                    Caption = 'Notification Recipient', Comment = 'is-IS=Viðtakandi tilkynningar';
                    ApplicationArea = All;
                    ToolTip = 'Specify the notification recipient address.', Comment = 'is-IS=Tilgreindu viðtakanda tilkynningar.';
                    ShowMandatory = NotificationType <> NotificationType::None;
                }
            }
            group(AdvancedSettings)
            {
                Caption = 'Advanced', Comment = 'is-IS=Ítarlegt';

                field(JobQueueCategoryCode; JobQueueCategoryCode)
                {
                    Caption = 'Job Queue Category Code', Comment = 'is-IS=Flokkunarkóði vinnsluraða';
                    ApplicationArea = All;
                    ToolTip = 'Optionally assign a Job Queue Category.', Comment = 'is-IS=Úthlutaðu flokkunarkóða vinnsluraðar ef þarf.';
                    TableRelation = "Job Queue Category";
                }
                field(RetryPolicy; RetryPolicy)
                {
                    Caption = 'Retry Policy', Comment = 'is-IS=Endurprófunarreglur';
                    ApplicationArea = All;
                    ToolTip = 'Specify how errors are retried.', Comment = 'is-IS=Tilgreindu hvernig villur eru endurprófaðar.';
                }
                field(EmitTelemetry; EmitTelemetry)
                {
                    Caption = 'Emit Telemetry', Comment = 'is-IS=Senda fjarmælingar';
                    ApplicationArea = All;
                    ToolTip = 'Enable telemetry emission for this entry.', Comment = 'is-IS=Virkja fjarmælingar fyrir þessa færslu.';
                }
            }
        }
    }

    var
        Playbook: Record "Playbook ori";
        RecurringTemplateCode: Code[20];
        JobQueueCategoryCode: Code[10];
        NotificationRecipient: Text[2048];
        NotificationType: Enum "Notif. Type ori";
        RetryPolicy: Enum "Retry Policy ori";
        EmitTelemetry: Boolean;
        MissingTemplateErr: Label 'You must select a Recurring Template Code.', Comment = 'is-IS=Þú verður að velja endurtekningarsniðmát.';
        WarningsConfirmQst: Label 'The playbook verifies with warnings: %1\Schedule it anyway?', Comment = '%1 = the warnings, is-IS=Keðjan sannreynist með viðvörunum: %1\Á samt að tímasetja hana?';

    /// <summary>
    /// Tells the dialog which playbook it is scheduling. Call it before <c>RunModal</c>. Also sets
    /// the retry policy to Always, so the field opens on the value most schedules want.
    /// </summary>
    /// <param name="SourcePlaybook">The playbook the orchestrator entry will be created for.</param>
    procedure SetPlaybook(var SourcePlaybook: Record "Playbook ori")
    begin
        Playbook := SourcePlaybook;
        RetryPolicy := RetryPolicy::Always;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Verify: Codeunit "Playbook Verify ori";
        Blocking: JsonArray;
        OrchestratorEntryPkId: Guid;
        Summary: Text;
        IgnoreWarnings: Boolean;
    begin
        if CloseAction <> Action::OK then
            exit(true);

        if RecurringTemplateCode = '' then
            Error(MissingTemplateErr);

        Playbook.Get(Playbook.Code);
        // Errors refuse the schedule. Warnings are shown and the user decides, as ignoreWarnings does for the message type.
        if Verify.GetBlockingFindings(Playbook.Code, true, Blocking, Summary) then
            Error('%1', Summary);
        if Verify.GetBlockingFindings(Playbook.Code, false, Blocking, Summary) then begin
            if not Confirm(WarningsConfirmQst, false, Summary) then
                exit(false);
            IgnoreWarnings := true;
        end;
        Playbook.CreateOrchestratorEntry(
            RecurringTemplateCode, NotificationType, NotificationRecipient,
            JobQueueCategoryCode, EmitTelemetry, RetryPolicy, IgnoreWarnings, OrchestratorEntryPkId);

        exit(true);
    end;
}
