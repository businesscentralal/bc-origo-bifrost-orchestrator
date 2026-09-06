/// <summary>
/// Email-based notification implementation for the Job Queue Orchestrator.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using System.EMail;
using System.Environment;
using System.Threading;

codeunit 10035541 "Email Notification ori" implements "Notification ori"
{
    /// <summary>
    /// Returns that a notification recipient is mandatory for email notifications.
    /// </summary>
    /// <returns>True.</returns>
    internal procedure IsNotificationReceipientMandatory() IsMandatory: Boolean
    begin
        IsMandatory := true;

        OnAfterIsNotificationReceipientMandatory(IsMandatory);
    end;

    /// <summary>
    /// No-op for email: execution completion does not send an email.
    /// </summary>
    /// <param name="Scheduled Entry ori">The orchestrator entry that was executed.</param>
    /// <param name="JobQueueEntry">The Job Queue Entry with execution results.</param>
    internal procedure SendExecutionCompletedNotification("Scheduled Entry ori": Record "Scheduled Entry ori"; JobQueueEntry: Record "Job Queue Entry");
    begin
        // We are not sending email notification for a completed job

        OnAfterSendExecutionCompletedNotification("Scheduled Entry ori", JobQueueEntry);
    end;

    /// <summary>
    /// No-op for email: heartbeat does not send an email.
    /// </summary>
    /// <param name="Scheduled Entry ori">The orchestrator entry to report on.</param>
    internal procedure SendHeartbeatNotification("Scheduled Entry ori": Record "Scheduled Entry ori");
    begin
        // We are not sending email notification for a heartbeat job

        OnAfterSendHeartbeatNotification("Scheduled Entry ori");
    end;

    /// <summary>
    /// Sends an email notification when a Job Queue Entry is restarted.
    /// </summary>
    /// <param name="Scheduled Entry ori">The orchestrator entry being restarted.</param>
    /// <param name="JobQueueEntry">The restarted Job Queue Entry.</param>
    internal procedure SendRestartNotification("Scheduled Entry ori": Record "Scheduled Entry ori"; JobQueueEntry: Record "Job Queue Entry")
    var
        TempEmailItem: Record "Email Item" temporary;
        OrchestratorSetup: Record "Scheduler Setup ori";
        IsHandled: Boolean;
        Success: Boolean;
        JobRestartedSubjectMsg: Label 'Job ''%1'' has been restarted', Comment = '%1 = Job Description, is-IS=Verk ''%1'' hefur verið endurræst';
        BodyText, EMailAddress : Text;
    begin
        OnBeforeSendRestartNotification("Scheduled Entry ori", JobQueueEntry, IsHandled);
        if IsHandled then
            exit;

        if "Scheduled Entry ori"."Notification Recipient" = '' then exit;
        if not IsValidEMailAddress("Scheduled Entry ori") then exit;

        OrchestratorSetup.Get();
        BodyText := BuildRestartNotificationEmailItem("Scheduled Entry ori", JobQueueEntry, OrchestratorSetup);

        foreach EMailAddress in "Scheduled Entry ori"."Notification Recipient".Split(';') do begin
            TempEmailItem.Init();
            TempEmailItem."Send to" := CopyStr(EMailAddress, 1, MaxStrLen(TempEmailItem."Send to"));
            TempEmailItem.Subject := StrSubstNo(JobRestartedSubjectMsg, "Scheduled Entry ori".Description);
            TempEmailItem."Plaintext Formatted" := false;
            OnAfterPreparingEmailItemBeforeSend("Scheduled Entry ori", JobQueueEntry, TempEmailItem, BodyText, IsHandled);
            TempEmailItem.SetBodyText(BodyText);
            if not IsHandled then begin
                ClearLastError();
                Success := Codeunit.Run(Codeunit::"Email Send ori", TempEmailItem);
                if not Success then
                    LogEmailSendError("Scheduled Entry ori", JobQueueEntry, TempEmailItem);
            end;
        end;

        OnAfterSendRestartNotification("Scheduled Entry ori", JobQueueEntry);
    end;

    /// <summary>
    /// Sends a test email notification to validate the notification setup.
    /// </summary>
    /// <param name="Scheduled Entry ori">The orchestrator entry to test.</param>
    internal procedure SendTestNotification("Scheduled Entry ori": Record "Scheduled Entry ori")
    var
        TempEmailItem: Record "Email Item" temporary;
        JobQueueEntry: Record "Job Queue Entry";
        OrchestratorSetup: Record "Scheduler Setup ori";
        IsHandled: Boolean;
        JobRestartedSubjectMsg: Label 'Test Email for job ''%1''', Comment = '%1 = Job Description, is-IS=Prófunarpóstur fyrir verk ''%1''';
        TestEmailMsg: Label 'Test Email', Comment = 'is-IS=Prófunarpóstur';
        BodyText, EMailAddress : Text;
    begin
        OnBeforeSendTestNotification("Scheduled Entry ori", IsHandled);
        if IsHandled then
            exit;

        "Scheduled Entry ori".TestField("Notification Recipient");
        IsValidEMailAddress("Scheduled Entry ori");

        if not JobQueueEntry.Get("Scheduled Entry ori".ID) then
            JobQueueEntry.Init();

        JobQueueEntry."Error Message" := TestEmailMsg;

        OrchestratorSetup.Get();
        BodyText := BuildRestartNotificationEmailItem("Scheduled Entry ori", JobQueueEntry, OrchestratorSetup);

        foreach EMailAddress in "Scheduled Entry ori"."Notification Recipient".Split(';') do begin
            TempEmailItem.Init();
            TempEmailItem."Send to" := CopyStr(EMailAddress, 1, MaxStrLen(TempEmailItem."Send to"));
            TempEmailItem.Subject := StrSubstNo(JobRestartedSubjectMsg, "Scheduled Entry ori".Description);
            TempEmailItem."Plaintext Formatted" := false;
            OnAfterPreparingTestEmailItemBeforeSend("Scheduled Entry ori", JobQueueEntry, TempEmailItem, BodyText, IsHandled);
            TempEmailItem.SetBodyText(BodyText);
            if not IsHandled then
                TempEmailItem.Send(true, "Email Scenario"::"Scheduler ori");
        end;
    end;

    /// <summary>
    /// Validates that the notification recipient has a valid email address.
    /// </summary>
    /// <param name="Scheduled Entry ori">The orchestrator entry to validate.</param>
    internal procedure ValidateNotificationReceipient("Scheduled Entry ori": Record "Scheduled Entry ori")
    var
        MailMgt: Codeunit "Mail Management";
        IsHandled: Boolean;
    begin
        OnBeforeValidateNotificationReceipient("Scheduled Entry ori", IsHandled);
        if IsHandled then
            exit;

        MailMgt.CheckValidEmailAddresses("Scheduled Entry ori"."Notification Recipient");

        OnAfterValidateNotificationReceipient("Scheduled Entry ori");
    end;

    local procedure BuildRestartNotificationEmailItem(var "Scheduled Entry ori": Record "Scheduled Entry ori"; var JobQueueEntry: Record "Job Queue Entry"; var OrchestratorSetup: Record "Scheduler Setup ori") BodyText: Text
    var
        EnvironmentInformation: Codeunit "Environment Information";
        EnvironmentMsg: Label 'Environment information:', Comment = 'is-IS=Upplýsingar um umhverfi:';
        IsOnPremMsg: Label 'Is OnPrem: ', Comment = 'is-IS=Er staðbundin: ';
        IsProductionMsg: Label 'Is Production: ', Comment = 'is-IS=Er framleiðsla: ';
        JobLastErrMsg: Label 'The job last execution error was:', Comment = 'is-IS=Síðasta keyrsluvilla verksins var:';
        JobQueueEntryMsg: Label 'Open Job Queue Entry', Comment = 'is-IS=Opna vinnsluraðafærslu';
        JobRestartedMsg: Label 'The following job has been restarted:', Comment = 'is-IS=Eftirfarandi verk hefur verið endurræst:';
        OrchestratorSetupMsg: Label 'Open Orchestrator Setup', Comment = 'is-IS=Opna uppsetningu vinnsluraðara';
        UrlTok: Label '<a href="%1">', Locked = true;
        BodyTextBuilder: TextBuilder;
    begin
        BodyTextBuilder.AppendLine('<p class=MsoNormal style=''margin-bottom:12.0pt;line-height:normal;background:white''><span style=''font-size:18.0pt;font-family:"Open Sans",sans-serif;color:#333333''>' + EnvironmentMsg + '</span></p>');
        BodyTextBuilder.AppendLine('<p class=MsoNormal style=''margin-top:0cm;margin-right:0cm;margin-bottom:0cm;margin-left:35.4pt;line-height:normal;background:white''><span style=''font-size:10.0pt;font-family:"Open Sans",sans-serif;color:black''>' + IsProductionMsg + Format(EnvironmentInformation.IsProduction()) + '</span></p>');
        BodyTextBuilder.AppendLine('<p class=MsoNormal style=''margin-top:0cm;margin-right:0cm;margin-bottom:0cm;margin-left:35.4pt;line-height:normal;background:white''><span style=''font-size:10.0pt;font-family:"Open Sans",sans-serif;color:black''>' + IsOnPremMsg + Format(EnvironmentInformation.IsOnPrem()) + '</span></p>');
        BodyTextBuilder.AppendLine('<p class=MsoNormal style=''margin-top:0cm;margin-right:0cm;margin-bottom:0cm;margin-left:35.4pt;line-height:normal;background:white''><span style=''font-size:10.0pt;font-family:"Open Sans",sans-serif;color:black''>' + StrSubstNo(UrlTok, GetUrl(ClientType::Web, CompanyName, ObjectType::Page, Page::"Scheduler Setup ori", OrchestratorSetup)) + OrchestratorSetupMsg + '</a></span></p>');
        BodyTextBuilder.AppendLine('<p class=MsoNormal style=''margin-top:0cm;margin-right:0cm;margin-bottom:0cm;margin-left:35.4pt;line-height:normal;background:white''><span style=''font-size:10.0pt;font-family:"Open Sans",sans-serif;color:black''>' + StrSubstNo(UrlTok, GetUrl(ClientType::Web, CompanyName, ObjectType::Page, Page::"Job Queue Entry Card", JobQueueEntry)) + JobQueueEntryMsg + '</a></span></p>');
        BodyTextBuilder.AppendLine('<p class=MsoNormal style=''margin-top:0cm;margin-right:0cm;margin-bottom:0cm;margin-left:35.4pt;line-height:normal;background:white''><span style=''font-size:10.0pt;font-family:"Open Sans",sans-serif;color:black''>' + '</span></p>');
        BodyTextBuilder.AppendLine('<p class=MsoNormal style=''margin-bottom:12.0pt;line-height:normal;background:white''><span style=''font-size:18.0pt;font-family:"Open Sans",sans-serif;color:#333333''>' + JobRestartedMsg + '</span></p>');
        BodyTextBuilder.AppendLine('<p class=MsoNormal style=''margin-top:0cm;margin-right:0cm;margin-bottom:0cm;margin-left:35.4pt;line-height:normal;background:white''><span style=''font-size:10.0pt;font-family:"Open Sans",sans-serif;color:black''>' + "Scheduled Entry ori".Description + '</span></p>');
        BodyTextBuilder.AppendLine('<p class=MsoNormal style=''margin-top:0cm;margin-right:0cm;margin-bottom:0cm;margin-left:35.4pt;line-height:normal;background:white''><span style=''font-size:10.0pt;font-family:"Open Sans",sans-serif;color:black''>' + '</span></p>');
        BodyTextBuilder.AppendLine('<p class=MsoNormal style=''margin-bottom:12.0pt;line-height:normal;background:white''><span style=''font-size:18.0pt;font-family:"Open Sans",sans-serif;color:#333333''>' + JobLastErrMsg + '</span></p>');
        BodyTextBuilder.AppendLine('<p class=MsoNormal style=''margin-top:0cm;margin-right:0cm;margin-bottom:0cm;margin-left:35.4pt;line-height:normal;background:white''><span style=''font-size:10.0pt;font-family:"Open Sans",sans-serif;color:black''>' + JobQueueEntry."Error Message" + '</span></p>');
        BodyTextBuilder.AppendLine('<p class=MsoNormal style=''margin-top:0cm;margin-right:0cm;margin-bottom:0cm;margin-left:35.4pt;line-height:normal;background:white''><span style=''font-size:10.0pt;font-family:"Open Sans",sans-serif;color:black''>' + '</span></p>');
        BodyText := BodyTextBuilder.ToText();
    end;

    [TryFunction]
    local procedure IsValidEMailAddress("Scheduled Entry ori": Record "Scheduled Entry ori")
    var
        MailMgt: Codeunit "Mail Management";
    begin
        "Scheduled Entry ori".TestField("Notification Recipient");
        MailMgt.CheckValidEmailAddresses("Scheduled Entry ori"."Notification Recipient");
    end;

#pragma warning disable AA0137
    local procedure LogEmailSendError("Scheduled Entry ori": Record "Scheduled Entry ori"; JobQueueEntry: Record "Job Queue Entry"; var TempEmailItem: Record "Email Item" temporary)
#pragma warning restore AA0137
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        "Scheduled Entry ori".CopyToCustomDimensions(CustomDimensions);
        "Scheduled Entry ori".CopyLastExecutionInformationToCustomDimensions(CustomDimensions);
        CustomDimensions.Add(DelChr(TempEmailItem.FieldName("Send to"), '=', ' '), TempEmailItem."Send to");
        CustomDimensions.Add('Error', GetLastErrorText());

        Session.LogMessage('O4NJQS-0007', 'Error Sending Email', Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsNotificationReceipientMandatory(var IsMandatory: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPreparingEmailItemBeforeSend("Scheduled Entry ori": Record "Scheduled Entry ori"; JobQueueEntry: Record "Job Queue Entry"; var TempEmailItem: Record "Email Item" temporary; var BodyText: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPreparingTestEmailItemBeforeSend("Scheduled Entry ori": Record "Scheduled Entry ori"; JobQueueEntry: Record "Job Queue Entry"; var TempEmailItem: Record "Email Item" temporary; BodyText: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSendExecutionCompletedNotification("Scheduled Entry ori": Record "Scheduled Entry ori"; JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSendHeartbeatNotification("Scheduled Entry ori": Record "Scheduled Entry ori")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSendRestartNotification("Scheduled Entry ori": Record "Scheduled Entry ori"; JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateNotificationReceipient("Scheduled Entry ori": Record "Scheduled Entry ori")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendRestartNotification("Scheduled Entry ori": Record "Scheduled Entry ori"; JobQueueEntry: Record "Job Queue Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendTestNotification("Scheduled Entry ori": Record "Scheduled Entry ori"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateNotificationReceipient("Scheduled Entry ori": Record "Scheduled Entry ori"; var IsHandled: Boolean)
    begin
    end;
}
