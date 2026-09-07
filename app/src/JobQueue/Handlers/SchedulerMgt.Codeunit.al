/// <summary>
/// Management codeunit for the Job Queue Orchestrator: scheduling, cancellation, and status.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Microsoft.Utilities;
using System.Environment;
using System.Environment.Configuration;
using System.Security.AccessControl;
using System.Threading;
using System.Utilities;

codeunit 10035536 "Scheduler Mgt ori"
{
    Access = Internal;

    var
        ExecuteBeginMsg: Label 'Executing job queue entry...', Comment = 'is-IS=Keyri vinnsluraðafærslu...';
        ExecuteEndErrorMsg: Label 'Job finished executing.\Status: %1\Error: %2', Comment = '%1 is a status value, e.g. Success, %2=Error message, is-IS=Verk lokið.\Staða: %1\Villa: %2';
        ExecuteEndSuccessMsg: Label 'Job finished executing.\Status: %1', Comment = '%1 is a status value, e.g. Success, is-IS=Verk lokið.\Staða: %1';
        JobQueueErrorColorTok: Label 'Unfavorable', Locked = true;
        JobQueueExpiredErr: Label 'Job Queue execution has expired, please restart', Comment = 'is-IS=Keyrsla vinnsluraðar er útrunnið, vinsamlegast endurræstu';
        JobQueueFailedErr: Label 'Job Queue execution has failed, please restart', Comment = 'is-IS=Keyrsla vinnsluraðar mistókst, vinsamlegast endurræstu';
        JobQueueIsRunningTok: Label 'Job Queue is running', Comment = 'is-IS=Vinnsluröð er í keyrslu';
        JobQueueNotConfiguredErr: Label 'Job Queue has not been configured', Comment = 'is-IS=Vinnsluröð hefur ekki verið stillt';
        JobQueueNotScheduledQst: Label 'Job Queue has not been scheduled, schedule now?', Comment = 'is-IS=Vinnsluröð hefur ekki verið tímasett, tímasetja núna?';
        JobQueueRunningColorTok: Label 'Favorable', Locked = true;
        RunOnceQst: Label 'This will create a temporary non-recurrent copy of this job and will run it once in the foreground.\Do you want to continue?', Comment = 'is-IS=Þetta mun stofna tímabundinn einskiptisafrit af ýessu verki og keyra það einu sinni í forgrunni.\Viltu halda áfram?';

    /// <summary>
    /// Cancels the management Job Queue Entry if it exists.
    /// </summary>
    internal procedure CancelJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if JobQueueEntry.Get(GetManagementJobQueueId()) then
            JobQueueEntry.Cancel();
    end;

    /// <summary>
    /// Returns the fixed Job Queue Category token used by the orchestrator.
    /// </summary>
    /// <returns>The orchestrator category token.</returns>
    internal procedure GetJobQueueOrchestratorTok(): Text[10]
    var
        JobQueueOrchestratorTok: Label 'JOBSSCHDLR', MaxLength = 10, Locked = true;
    begin
        exit(JobQueueOrchestratorTok);
    end;

    /// <summary>
    /// Gets the current status and style expression for the management Job Queue Entry.
    /// </summary>
    /// <param name="JobQueueStatus">Returns a descriptive status text.</param>
    /// <param name="JobQueueStyleExpr">Returns the style expression for the status indicator.</param>
    /// <returns>True if the Job Queue Entry is ready to start.</returns>
    internal procedure GetJobQueueStatus(var JobQueueStatus: Text; var JobQueueStyleExpr: Text) ReadyToStart: Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if JobQueueEntry.Get(GetManagementJobQueueId()) then begin
            if JobQueueEntry.IsExpired(CurrentDateTime - 60000) then begin
                JobQueueStyleExpr := JobQueueErrorColorTok;
                JobQueueStatus := JobQueueExpiredErr;
                exit;
            end;
            if JobQueueEntry.IsReadyToStart() then
                if JobQueueEntry."Earliest Start Date/Time" < (CurrentDateTime - 60000) then begin
                    JobQueueStyleExpr := JobQueueErrorColorTok;
                    JobQueueStatus := JobQueueExpiredErr;
                    exit;
                end else begin
                    JobQueueStyleExpr := JobQueueRunningColorTok;
                    JobQueueStatus := JobQueueIsRunningTok;
                    exit(true);
                end;
            JobQueueStyleExpr := JobQueueErrorColorTok;
            JobQueueStatus := JobQueueFailedErr;
            exit;
        end;
        JobQueueStatus := JobQueueNotConfiguredErr;
        JobQueueStyleExpr := JobQueueErrorColorTok;
    end;

    /// <summary>
    /// Returns the fixed Guid used for the management Job Queue Entry.
    /// </summary>
    /// <returns>The management Job Queue Entry ID.</returns>
    /// <remarks>
    /// This must NOT be the same Guid as the predecessor app's (<c>Origo Cloud Events
    /// Orchestrator</c>) management job queue entry - both apps are installed side by side and
    /// share the single base-application "Job Queue Entry" table, so an identical id would make
    /// Bifrost Orchestrator find and reuse the legacy app's entry (which still points at the legacy
    /// handler codeunit) instead of scheduling its own. Freshly generated for this app.
    /// </remarks>
    internal procedure GetManagementJobQueueId(): Guid
    begin
        exit('461b5088-cc5f-4b4a-9e5e-b4cde335df66');
    end;

    /// <summary>
    /// Triggers registration of job queue codeunits via the orchestrator entry event.
    /// </summary>
    internal procedure RegisterJobQueues()
    var
        "Scheduled Entry ori": Record "Scheduled Entry ori";
    begin
        "Scheduled Entry ori".RegisterJobQueueCodeunits();
    end;

    /// <summary>
    /// Runs a temporary non-recurrent copy of the selected orchestrator entry once in the foreground.
    /// </summary>
    /// <param name="SelectedJobQueueOrchestratorEntry">The orchestrator entry to execute.</param>
    internal procedure RunJobQueueEntryOnce(var SelectedJobQueueOrchestratorEntry: Record "Scheduled Entry ori")
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        ConfirmManagement: Codeunit "Confirm Management";
        SuccessDispatcher: Boolean;
        SuccessErrorHandler: Boolean;
        Window: Dialog;
        CustomDimensions: Dictionary of [Text, Text];
        JobQueueEntryExecutedTok: Label 'Job Queue Entry Executed', Locked = true;
    begin
        if not ConfirmManagement.GetResponseOrDefault(RunOnceQst, false) then
            exit;

        Window.Open(ExecuteBeginMsg);
        JobQueueEntry.Init();
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."Object Type to Run" := SelectedJobQueueOrchestratorEntry."Object Type to Run";
        JobQueueEntry."Object ID to Run" := SelectedJobQueueOrchestratorEntry."Object ID to Run";
        JobQueueEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(JobQueueEntry."User ID"));
        JobQueueEntry."Recurring Job" := false;
        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry."Job Queue Category Code" := '';
        JobQueueEntry."Record ID to Process" := SelectedJobQueueOrchestratorEntry.RecordId;
        Clear(JobQueueEntry."Expiration Date/Time");
        Clear(JobQueueEntry."System Task ID");
        JobQueueEntry.Insert(true);

        SelectedJobQueueOrchestratorEntry.CopyToCustomDimensions(CustomDimensions);
        SelectedJobQueueOrchestratorEntry.CopyLastExecutionInformationToCustomDimensions(CustomDimensions);
        Log('O4NJQS-0005', JobQueueEntryExecutedTok, Verbosity::Normal, CustomDimensions);
        Commit();

        // Run the job queue
        SuccessDispatcher := Codeunit.Run(Codeunit::"Job Queue Dispatcher", JobQueueEntry);

        // If JQ fails, run the error handler
        if not SuccessDispatcher then begin
            SuccessErrorHandler := Codeunit.Run(Codeunit::"Job Queue Error Handler", JobQueueEntry);

            // If the error handler fails, save the error (Non-AL errors will automatically surface to end-user)
            // If it is unable to save the error (No permission etc), it should also just be surfaced to the end-user.
            if not SuccessErrorHandler then begin
                JobQueueEntry.SetError(GetLastErrorText());
                JobQueueEntry.InsertLogEntry(JobQueueLogEntry);
                JobQueueEntry.FinalizeLogEntry(JobQueueLogEntry, GetLastErrorCallStack());
                Commit();
            end;
        end;

        Window.Close();
        if JobQueueEntry.Find() then
            if JobQueueEntry.Delete() then;
        JobQueueLogEntry.SetLoadFields(Status, "Error Message");
        JobQueueLogEntry.ReadIsolation := IsolationLevel::ReadCommitted;
        JobQueueLogEntry.SetRange(ID, JobQueueEntry.ID);
        if JobQueueLogEntry.FindFirst() then
            if JobQueueLogEntry.Status = JobQueueLogEntry.Status::Success then
                Message(ExecuteEndSuccessMsg, JobQueueLogEntry.Status)
            else
                Message(ExecuteEndErrorMsg, JobQueueLogEntry.Status, JobQueueLogEntry."Error Message");
    end;

    /// <summary>
    /// Creates and enqueues the management Job Queue Entry with the specified category and user.
    /// </summary>
    /// <param name="JobQueueCategoryCode">The category code for the entry.</param>
    /// <param name="JobQueueUserId">The user ID to run the entry as.</param>
    internal procedure ScheduleJobQueueEntry(JobQueueCategoryCode: Code[10]; JobQueueUserId: Code[50])
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueScheduleEntry: Record "Scheduled Entry ori";
        ScheduledTask: Record "Scheduled Task";
        User: Record User;
        UserPersonalization: Record "User Personalization";
        CustomDimensions: Dictionary of [Text, Text];
        JobQueueEntryCreatedTok: Label 'Job Queue Entry for Orchestrator Created', Locked = true;
        JobQueueEntryDescTxt: Label 'Job Queue Orchestrator - Handler', MaxLength = 250, Comment = 'is-IS=Vinnsluraðari - Meðhöndlun';
    begin
        CancelJobQueueEntry();
        JobQueueEntry.Init();
        JobQueueEntry.ID := GetManagementJobQueueId();
        JobQueueEntry."Recurring Job" := true;
        JobQueueEntry."Run on Mondays" := true;
        JobQueueEntry."Run on Tuesdays" := true;
        JobQueueEntry."Run on Wednesdays" := true;
        JobQueueEntry."Run on Thursdays" := true;
        JobQueueEntry."Run on Fridays" := true;
        JobQueueEntry."Run on Saturdays" := true;
        JobQueueEntry."Run on Sundays" := true;
        JobQueueEntry."No. of Minutes between Runs" := 5;
        JobQueueEntry."Earliest Start Date/Time" := CurrentDateTime();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"Scheduler Handler ori";
        JobQueueEntry."Starting Time" := 080000T;
        JobQueueEntry."Maximum No. of Attempts to Run" := 3;
        JobQueueEntry."Job Queue Category Code" := JobQueueCategoryCode;
        JobQueueEntry.Description := JobQueueEntryDescTxt;
        JobQueueEntry.Insert(true);
        Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);

        CustomDimensions.Add(DelChr(JobQueueScheduleEntry.FieldName("Job Queue Category Code"), '=', ' '), JobQueueCategoryCode);
        CustomDimensions.Add(DelChr(JobQueueScheduleEntry.FieldName("Job Queue User ID"), '=', ' '), JobQueueUserId);
        Log('O4NJQS-0000', JobQueueEntryCreatedTok, Verbosity::Normal, CustomDimensions);
        Commit();
        if JobQueueUserId = '' then exit;
        User.SetLoadFields(State, "User Security ID", "User Name");
        User.SetRange("User Name", JobQueueUserId);
        if not User.FindFirst() then exit;
        if User.State = User.State::Disabled then exit;
        if not ScheduledTask.Get(JobQueueEntry."System Task ID") then exit;
        ScheduledTask."User ID" := User."User Security ID";
        ScheduledTask."User Name" := User."User Name";

        UserPersonalization.SetLoadFields("Locale ID");
        if UserPersonalization.Get(User."User Security ID") then
            if UserPersonalization."Locale ID" <> 0 then
                ScheduledTask."User Format ID" := UserPersonalization."Locale ID";

        ScheduledTask.Modify();
        JobQueueEntry."User ID" := JobQueueUserId;
        JobQueueEntry.Modify();
        Commit();
    end;

    /// <summary>
    /// Shows the Activity Log entries for a orchestrator entry.
    /// </summary>
    /// <param name="Rec">The orchestrator entry to show logs for.</param>
    internal procedure ShowActivityLog(var Rec: Record "Scheduled Entry ori")
    var
        ActivityLog: Record "Activity Log";
    begin
        ActivityLog.ShowEntries(Rec);
    end;

    /// <summary>
    /// Opens the Job Queue Entries page for the management entry, offering to schedule if missing.
    /// </summary>
    /// <param name="JobQueueGeneralSetup">The orchestrator setup record.</param>
    internal procedure ShowJobQueueEntry(JobQueueGeneralSetup: Record "Scheduler Setup ori")
    var
        JobQueueEntry: Record "Job Queue Entry";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not JobQueueEntry.Get(GetManagementJobQueueId()) then
            if ConfirmManagement.GetResponseOrDefault(JobQueueNotScheduledQst, true) then
                ScheduleJobQueueEntry(JobQueueGeneralSetup.GetJobQueueCategoryCode(), JobQueueGeneralSetup."Job Queue User ID");
        if JobQueueEntry.Get(GetManagementJobQueueId()) then
            Page.RunModal(Page::"Job Queue Entries", JobQueueEntry);
    end;

    local procedure Log(EventId: Text; Message: Text; Verbosity: Verbosity; CustomDimensions: Dictionary of [Text, Text])
    begin
        Session.LogMessage(EventId, Message, Verbosity, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Scheduled Entry ori", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteJob(var Rec: Record "Scheduled Entry ori")
    var
        ActivityLog: Record "Activity Log";
    begin
        ActivityLog.SetRange("Record ID", Rec.RecordId);
        if not ActivityLog.IsEmpty() then
            ActivityLog.DeleteAll();
    end;

    /// <summary>
    /// Reports whether the administrator has allowed this extension to make outgoing HTTP calls.
    /// Without it the API client cannot reach the scheduling service, so the setup page raises its
    /// notification on this rather than letting the first call fail.
    /// </summary>
    /// <returns>Boolean. True when Allow HttpClient Requests is set for this app.</returns>
    internal procedure IsHttpClientEnabled(): Boolean
    var
        NAVAppSetting: Record "NAV App Setting";
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        exit(NAVAppSetting.Get(AppInfo.Id()) and NAVAppSetting."Allow HttpClient Requests");
    end;
}
