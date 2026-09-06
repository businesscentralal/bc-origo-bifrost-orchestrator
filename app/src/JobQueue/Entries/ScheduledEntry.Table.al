namespace Origo.Bifrost.Orchestrator;

using Microsoft.Foundation.Reporting;
using Microsoft.Utilities;
using System.DateTime;
using System.Environment.Configuration;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.User;
using System.Threading;
using System.Utilities;

/// <summary>
/// Stores the orchestrator configuration for each monitored Job Queue Entry.
/// </summary>
table 10035535 "Scheduled Entry ori"
{
    Caption = 'Job Queue Orchestrator Entry', Comment = 'is-IS=Vinnsluraðarfærsla';
    DataCaptionFields = "Object Type to Run", "Object Caption to Run";
    DataClassification = SystemMetadata;

    fields
    {
        field(10; ID; Guid)
        {
            Caption = 'ID', Comment = 'is-IS=Auðkenni';
            DataClassification = SystemMetadata;
        }
        field(12; Scheduled; Boolean)
        {
            CalcFormula = exist("Job Queue Entry" where(ID = field(ID)));
            Caption = 'Scheduled', Comment = 'is-IS=Tímasett';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; Status; Option)
        {
            CalcFormula = lookup("Job Queue Entry".Status where(ID = field(ID)));
            Caption = 'Status', Comment = 'is-IS=Staða';
            Editable = false;
            FieldClass = FlowField;
            OptionCaption = 'Ready,In Process,Error,On Hold,Finished,On Hold with Inactivity Timeout', Comment = 'is-IS=Tilbúin,Í vinnslu,Villa,Í bið,Lokið,Í bið vegna óvirkni';
            OptionMembers = Ready,"In Process",Error,"On Hold",Finished,"On Hold with Inactivity Timeout";
        }
        field(15; "Record ID to Process"; RecordId)
        {
            Caption = 'Record ID to Process', Comment = 'is-IS=Auðkenni gagna til úrvinnslu';
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                if Rec.DeleteJobQueueEntry() then
                    Message(DeletedMsg);
            end;
        }
        field(20; "Earliest Start Date/Time"; DateTime)
        {
            Caption = 'Earliest Start Date/Time', Comment = 'is-IS=Fyrsti tími til keyrslu';
            DataClassification = SystemMetadata;
            trigger OnLookup()
            begin
                Rec.Validate("Earliest Start Date/Time", LookupDateTime(Rec."Earliest Start Date/Time"));
            end;
        }
        field(27; "Object Type to Run"; Option)
        {
            Caption = 'Object Type to Run', Comment = 'is-IS=Gerð hluts til keyrslu';
            InitValue = "Report";
            OptionCaption = ',,,Report,,Codeunit', Comment = 'is-IS=,,,Skýrsla,,Kóðaeining';
            OptionMembers = ,,,"Report",,"Codeunit";
            trigger OnValidate()
            begin
                if "Object Type to Run" <> xRec."Object Type to Run" then
                    Validate("Object ID to Run", 0);
                if Rec.DeleteJobQueueEntry() then
                    Message(DeletedMsg);
            end;
        }
        field(30; "Object ID to Run"; Integer)
        {
            Caption = 'Object ID to Run', Comment = 'is-IS=Auðkenni hluts til keyrslu';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = field("Object Type to Run"));

            trigger OnLookup()
            var
                NewObjectID: Integer;
            begin
                if LookupObjectID(NewObjectID) then
                    Validate("Object ID to Run", NewObjectID);
            end;

            trigger OnValidate()
            var
                AllObj: Record AllObj;
            begin
                if "Object ID to Run" = 0 then
                    exit;
                if not AllObj.Get("Object Type to Run", "Object ID to Run") then
                    Error(ObjNotFoundErr, "Object Type to Run", "Object ID to Run");

                CalcFields("Object Caption to Run");
                if Description = '' then
                    Description := GetDefaultDescription();

                if Rec.DeleteJobQueueEntry() then
                    Message(DeletedMsg);

                if "Object Type to Run" <> "Object Type to Run"::Report then
                    exit;

                "Report Output Type" := "Report Output Type"::"None (Processing only)";
            end;
        }
        field(40; "Object Caption to Run"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = field("Object Type to Run"),
                                                                           "Object ID" = field("Object ID to Run")));
            Caption = 'Object Caption to Run', Comment = 'is-IS=Kafli hluts til keyrslu';
            Editable = false;
            FieldClass = FlowField;
        }
        field(45; "Report Output Type"; Enum "Job Queue Report Output Type")
        {
            Caption = 'Report Output Type', Comment = 'is-IS=Gerð skýrsluúttaks';

            trigger OnValidate()
            var
                ReportManagementHelper: Codeunit "Report Management Helper";
            begin
                TestField("Object Type to Run", "Object Type to Run"::Report);

                if ReportManagementHelper.IsProcessingOnly("Object ID to Run") then
                    TestField("Report Output Type", "Report Output Type"::"None (Processing only)");

                ModifyReportOutputType();
            end;
        }
        field(50; "No. of Minutes between Runs"; Integer)
        {
            Caption = 'No. of Minutes between Runs', Comment = 'is-IS=Fjöldi mínúta milli keyrslu';
            DataClassification = SystemMetadata;
            MinValue = 0;

            trigger OnValidate()
            begin
                Clear("Next Run Date Formula");
                SetMinimumNumberOfMinutesBetweenRuns();

                ModifyRecurringFields();
            end;
        }
        field(60; "Job Queue Category Code"; Code[10])
        {
            Caption = 'Job Queue Category Code', Comment = 'is-IS=Flokkunarkóði vinnsluraða';
            DataClassification = SystemMetadata;
            TableRelation = "Job Queue Category";
            trigger OnValidate()
            var
                JobQueueEntry: Record "Job Queue Entry";
            begin
                JobQueueEntry.SetRange(ID, ID);
                if not JobQueueEntry.IsEmpty() then
                    JobQueueEntry.ModifyAll("Job Queue Category Code", "Job Queue Category Code");
            end;
        }
        field(70; Blocked; Boolean)
        {
            Caption = 'Blocked', Comment = 'is-IS=Lokað';
            DataClassification = SystemMetadata;
            InitValue = true;
            trigger OnValidate()
            begin
                BlockScheduleEntry(not GuiAllowed);
            end;
        }
        field(80; "Related Record System Id"; Guid)
        {
            Caption = 'Related Record System Id', Comment = 'is-IS=Auðkenni kerfisgagna tengdrar færslu';
            DataClassification = SystemMetadata;
        }
        field(90; Description; Text[1024])
        {
            Caption = 'Description', Comment = 'is-IS=Lýsing';
            DataClassification = SystemMetadata;
            trigger OnValidate()
            var
                JobQueueEntry: Record "Job Queue Entry";
            begin
                JobQueueEntry.SetRange(ID, ID);
                if not JobQueueEntry.IsEmpty() then
                    JobQueueEntry.ModifyAll(Description, CopyStr(Description, 1, MaxStrLen(JobQueueEntry.Description)));
            end;
        }
        field(100; "Notification Type"; Enum "Notif. Type ori")
        {
            Caption = 'Notification Type', Comment = 'is-IS=Gerð tilkynningar';
            DataClassification = SystemMetadata;
            trigger OnValidate()
            begin
                Clear("Notification Recipient");
            end;
        }
        field(110; "Notification Recipient"; Text[2048])
        {
            Caption = 'Notification Recipient', Comment = 'is-IS=Viðtakandi tilkynningar';
            DataClassification = SystemMetadata;
            trigger OnValidate()
            var
                NotificationInterface: Interface "Notification ori";
            begin
                NotificationInterface := "Notification Type";
                NotificationInterface.ValidateNotificationReceipient(Rec);
            end;
        }
        field(140; "Job Queue User ID"; Code[50])
        {
            Caption = 'User ID', Comment = 'is-IS=Notendaauðkenni';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
            TableRelation = User."User Name";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UserSelection: Codeunit "User Selection";
            begin
                UserSelection.ValidateUserName("Job Queue User ID");
                if Rec.DeleteJobQueueEntry() then
                    Message(DeletedMsg);
            end;
        }
        field(150; "Emit Telemetry"; Boolean)
        {
            Caption = 'Emit Telemetry', Comment = 'is-IS=Senda fjarmælingar';
            DataClassification = SystemMetadata;
        }
        field(160; "Recurring Template Code"; Code[20])
        {
            Caption = 'Recurring Template Code', Comment = 'is-IS=Kóði endur tek a sniðmáts';
            DataClassification = SystemMetadata;
            TableRelation = "Recurring Template ori".Code;

            trigger OnValidate()
            var
                RecurringTemplate: Record "Recurring Template ori";
            begin
                if "Recurring Template Code" = '' then
                    exit;

                if RecurringTemplate.Get("Recurring Template Code") then begin
                    // Copy all fields EXCEPT Description
                    "Time Zone Nr." := RecurringTemplate."Time Zone Nr.";
                    "Run on Mondays" := RecurringTemplate."Run on Mondays";
                    "Run on Tuesdays" := RecurringTemplate."Run on Tuesdays";
                    "Run on Wednesdays" := RecurringTemplate."Run on Wednesdays";
                    "Run on Thursdays" := RecurringTemplate."Run on Thursdays";
                    "Run on Fridays" := RecurringTemplate."Run on Fridays";
                    "Run on Saturdays" := RecurringTemplate."Run on Saturdays";
                    "Run on Sundays" := RecurringTemplate."Run on Sundays";
                    "Starting Time" := RecurringTemplate."Starting Time";
                    "Ending Time" := RecurringTemplate."Ending Time";
                    "No. of Minutes between Runs" := RecurringTemplate."No. of Minutes between Runs";
                    "Next Run Date Formula" := RecurringTemplate."Next Run Date Formula";

                    // Trigger sync to Job Queue Entry
                    if Rec.DeleteJobQueueEntry() then
                        Message(DeletedMsg);
                end;
            end;
        }
        field(171; "Time Zone Nr."; Integer)
        {
            Caption = 'Time Zone Nr.', Comment = 'is-IS=Númer tímabeltis';
            DataClassification = SystemMetadata;
            TableRelation = "Time Zone";
        }
        field(175; "Time Zone Display Name"; Text[250])
        {
            CalcFormula = lookup("Time Zone"."Display Name" where("No." = field("Time Zone Nr.")));
            Caption = 'Time Zone', Comment = 'is-IS=Tímabelti';
            FieldClass = FlowField;
        }
        field(180; "Run on Mondays"; Boolean)
        {
            Caption = 'Run on Mondays', Comment = 'is-IS=Keyra á mánudögum';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                Clear("Next Run Date Formula");
                ValidateWeekday();

                ModifyRecurringFields();
            end;
        }
        field(190; "Run on Tuesdays"; Boolean)
        {
            Caption = 'Run on Tuesdays', Comment = 'is-IS=Keyra á þrist dagum';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                Clear("Next Run Date Formula");
                ValidateWeekday();

                ModifyRecurringFields();
            end;
        }
        field(200; "Run on Wednesdays"; Boolean)
        {
            Caption = 'Run on Wednesdays', Comment = 'is-IS=Keyra á miðviku köllum';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                Clear("Next Run Date Formula");
                ValidateWeekday();

                ModifyRecurringFields();
            end;
        }
        field(210; "Run on Thursdays"; Boolean)
        {
            Caption = 'Run on Thursdays', Comment = 'is-IS=Keyra á fimmtud köllum';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                Clear("Next Run Date Formula");
                ValidateWeekday();

                ModifyRecurringFields();
            end;
        }
        field(220; "Run on Fridays"; Boolean)
        {
            Caption = 'Run on Fridays', Comment = 'is-IS=Keyra á föstudögum';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                Clear("Next Run Date Formula");
                ValidateWeekday();

                ModifyRecurringFields();
            end;
        }
        field(230; "Run on Saturdays"; Boolean)
        {
            Caption = 'Run on Saturdays', Comment = 'is-IS=Keyra á laugardögum';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                Clear("Next Run Date Formula");
                ValidateWeekday();

                ModifyRecurringFields();
            end;
        }
        field(240; "Run on Sundays"; Boolean)
        {
            Caption = 'Run on Sundays', Comment = 'is-IS=Keyra á sunnudögum';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                Clear("Next Run Date Formula");
                ValidateWeekday();

                ModifyRecurringFields();
            end;
        }
        field(250; "Starting Time"; Time)
        {
            Caption = 'Starting Time', Comment = 'is-IS=Upphafstími';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                JobQueueEntry: Record "Job Queue Entry";
            begin
                ValidateTimeRange();

                // Sync to Job Queue Entry
                JobQueueEntry.SetRange(ID, ID);
                if not JobQueueEntry.IsEmpty() then
                    JobQueueEntry.ModifyAll("Starting Time", "Starting Time", true);
            end;
        }
        field(260; "Ending Time"; Time)
        {
            Caption = 'Ending Time', Comment = 'is-IS=Lokatími';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                JobQueueEntry: Record "Job Queue Entry";
            begin
                ValidateTimeRange();

                // Sync to Job Queue Entry
                JobQueueEntry.SetRange(ID, ID);
                if not JobQueueEntry.IsEmpty() then
                    JobQueueEntry.ModifyAll("Ending Time", "Ending Time", true);
            end;
        }
        field(270; "Next Run Date Formula"; DateFormula)
        {
            Caption = 'Next Run Date Formula', Comment = 'is-IS=Formúla næsta keyrsludags';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                Clear("No. of Minutes between Runs");
                ClearRunOnWeekdays();
                ValidateRecurringSchedule();

                ModifyRecurringFields();
            end;
        }
        field(280; "Client Credentials Code"; Code[50])
        {
            Caption = 'Client Credentials Code', Comment = 'is-IS=Kóði kliensta auðkenningar';
            DataClassification = SystemMetadata;
            TableRelation = "Client Credentials ori";
        }
        field(290; "Retry Policy"; Enum "Retry Policy ori")
        {
            Caption = 'Retry Policy', Comment = 'is-IS=Endurprófanarstefna';
            DataClassification = SystemMetadata;
            InitValue = Always;
        }
        field(300; "Errors Since Last Success"; Integer)
        {
            Caption = 'Errors Since Last Success', Comment = 'is-IS=Villur frá síðustu gangi';
            DataClassification = SystemMetadata;
            Editable = false;
            InitValue = 0;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
        key(Key2; "Object Type to Run", "Object ID to Run")
        {
        }
    }

    var
        DeletedMsg: Label 'The linked Job Queue Entry has been deleted.  New Job Queue Entry will be automatically created by the Job Queue Orchestrator.', Comment = 'is-IS=Tengdri vinnsluraðafærslu hefur verið eytt. Ný vinnsluraðafærsla verður sjálfkrafa stofnuð af vinnsluraðaranum.';
        ObjNotFoundErr: Label 'There is no %1 with ID %2.', Comment = '%1 = Object Type, %2 = Object ID';
        EndingTimeBeforeStartingTimeErr: Label 'Ending Time must be greater than Starting Time.', Comment = 'is-IS=Lokatími verður að vera stærri en upphafstími.';

    trigger OnRename()
    var
        RenameErr: Label 'You cannot rename entries in this table.', Comment = 'is-IS=Ekki er hægt að endurnefna færslur í þessari töflu.';
    begin
        Error(RenameErr);
    end;

    trigger OnInsert()
    begin
        CheckRecursion();
    end;

    trigger OnModify()
    begin
        CheckRecursion();
    end;

    trigger OnDelete()
    var
        ActivityLog: Record "Activity Log";
    begin
        ActivityLog.SetRange("Record ID", RecordId);
        if not ActivityLog.IsEmpty() then
            ActivityLog.DeleteAll();
    end;

    /// <summary>
    /// Copies field values from a Job Queue Entry into this orchestrator entry and inserts it.
    /// </summary>
    /// <param name="JobQueueEntry">The source Job Queue Entry record.</param>
    procedure CopyJobQueueEntryToOrchestratorEntry(var JobQueueEntry: Record "Job Queue Entry")
    var
        UserPersonalization: Record "User Personalization";
        TimeZone: Record "Time Zone";
    begin
        Init();
        ID := JobQueueEntry.ID;
        "Object Type to Run" := JobQueueEntry."Object Type to Run";
        "Object ID to Run" := JobQueueEntry."Object ID to Run";
        Blocked := false;
        Description := JobQueueEntry.Description;
        "Earliest Start Date/Time" := JobQueueEntry."Earliest Start Date/Time";
        "Job Queue Category Code" := JobQueueEntry."Job Queue Category Code";
        "No. of Minutes between Runs" := JobQueueEntry."No. of Minutes between Runs";
        "Record ID to Process" := JobQueueEntry."Record ID to Process";
        // Copy new recurring fields
        "Run on Mondays" := JobQueueEntry."Run on Mondays";
        "Run on Tuesdays" := JobQueueEntry."Run on Tuesdays";
        "Run on Wednesdays" := JobQueueEntry."Run on Wednesdays";
        "Run on Thursdays" := JobQueueEntry."Run on Thursdays";
        "Run on Fridays" := JobQueueEntry."Run on Fridays";
        "Run on Saturdays" := JobQueueEntry."Run on Saturdays";
        "Run on Sundays" := JobQueueEntry."Run on Sundays";
        "Starting Time" := JobQueueEntry."Starting Time";
        "Ending Time" := JobQueueEntry."Ending Time";
        "Next Run Date Formula" := JobQueueEntry."Next Run Date Formula";
        // Set Time Zone from current user's personalization
        if UserPersonalization.Get(UserSecurityId()) then begin
            TimeZone.SetLoadFields("No.");
            TimeZone.SetRange(ID, UserPersonalization."Time Zone");
            if TimeZone.FindFirst() then
                "Time Zone Nr." := TimeZone."No.";
        end;
        OnAfterCopyJobQueueEntryToOrchestratorEntryBeforeInsert(Rec, JobQueueEntry);
        Insert(true);
        Commit();
    end;

    /// <summary>
    /// Copies the last Job Queue Log Entry execution information into custom dimensions for telemetry.
    /// </summary>
    /// <param name="CustomDimensions">The dictionary to populate with execution details.</param>
    /// <returns>True if the last execution was successful.</returns>
    procedure CopyLastExecutionInformationToCustomDimensions(var CustomDimensions: Dictionary of [Text, Text]) WasSuccess: Boolean;
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
        IsHandled: Boolean;
    begin
        OnBeforeCopyLastExecutionInformationToCustomDimensions(Rec, JobQueueLogEntry, CustomDimensions, IsHandled);
        if IsHandled then
            exit;
        JobQueueLogEntry.SetLoadFields(ID, "Start Date/Time", "End Date/Time", "User ID", Status);
        JobQueueLogEntry.ReadIsolation := IsolationLevel::ReadCommitted;
        JobQueueLogEntry.SetCurrentKey("Start Date/Time", ID);
        JobQueueLogEntry.SetRange(ID, ID);
        if not JobQueueLogEntry.FindLast() then
            exit;

        WasSuccess := JobQueueLogEntry.Status = JobQueueLogEntry.Status::Success;

        CustomDimensions.Add(DelChr(JobQueueLogEntry.FieldName("Start Date/Time"), '=', ' '), Format(JobQueueLogEntry."Start Date/Time"));
        CustomDimensions.Add(DelChr(JobQueueLogEntry.FieldName("End Date/Time"), '=', ' '), Format(JobQueueLogEntry."End Date/Time"));
        CustomDimensions.Add(DelChr(JobQueueLogEntry.FieldName("User ID"), '=', ' '), JobQueueLogEntry."User ID");
        CustomDimensions.Add(DelChr(JobQueueLogEntry.FieldName(Status), '=', ' '), Format(JobQueueLogEntry.Status));

        OnAfterCopyLastExecutionInformationToCustomDimensions(Rec, JobQueueLogEntry, CustomDimensions);
    end;

    /// <summary>
    /// Copies the orchestrator entry identification fields into custom dimensions for telemetry.
    /// </summary>
    /// <param name="CustomDimensions">The dictionary to populate with entry details.</param>
    procedure CopyToCustomDimensions(var CustomDimensions: Dictionary of [Text, Text]);
    begin
        Clear(CustomDimensions);
        CustomDimensions.Add(FieldName(ID), ID);
        CustomDimensions.Add(DelChr(FieldName("Object Type to Run"), '=', ' '), Format("Object Type to Run", 1));
        CustomDimensions.Add(DelChr(FieldName("Object ID to Run"), '=', ' '), Format("Object ID to Run"));
        CustomDimensions.Add(DelChr(FieldName(Description), '=', ' '), Description);

        OnAfterCopyToCustomDimensions(Rec, CustomDimensions);
    end;

    /// <summary>
    /// Handles blocking a orchestrator entry by optionally deleting the associated job queue entry.
    /// </summary>
    /// <param name="HideDialog">If true, skips the confirmation dialog.</param>
    internal procedure BlockScheduleEntry(HideDialog: Boolean)
    var
        ConfirmManagement: Codeunit "Confirm Management";
        DeleteScheduledQst: Label 'Do you want to delete the scheduled job queue entry?', Comment = 'is-IS=Viltu eyða áætlaðri vinnsluraðafærslu?';
    begin
        TestField("Object ID to Run");
        if not Blocked then
            exit;

        Rec.CalcFields(Scheduled);
        if Rec.Scheduled then
            if HideDialog then
                Rec.DeleteJobQueueEntry()
            else
                if GuiAllowed() then
                    if ConfirmManagement.GetResponseOrDefault(DeleteScheduledQst, true) then
                        Rec.DeleteJobQueueEntry();
    end;

    /// <summary>
    /// Calculates the next run date/time for a recurring job based on minutes between runs.
    /// </summary>
    /// <param name="Scheduled Entry ori">The entry to update with the new run time.</param>
    /// <param name="StartingDateTime">The base date/time for the calculation.</param>
    internal procedure CalcNextRunTimeForRecurringJob(var "Scheduled Entry ori": Record "Scheduled Entry ori"; StartingDateTime: DateTime)
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
        "Schedule Calc ori": Codeunit "Schedule Calc ori";
        NewRunDateTime: DateTime;
    begin
        JobQueueLogEntry.ReadIsolation := IsolationLevel::ReadCommitted;
        JobQueueLogEntry.SetCurrentKey("Start Date/Time", ID);
        JobQueueLogEntry.SetRange(ID, "Scheduled Entry ori".ID);
        if JobQueueLogEntry.FindLast() then
            NewRunDateTime := "Schedule Calc ori".CalcNextRunTimeForRecurringSchedule("Scheduled Entry ori", JobQueueLogEntry."End Date/Time", StartingDateTime)
        else
            NewRunDateTime := "Schedule Calc ori".CalcNextRunTimeForRecurringSchedule("Scheduled Entry ori", 0DT, StartingDateTime);

        if NewRunDateTime <> 0DT then begin
            "Scheduled Entry ori"."Earliest Start Date/Time" := NewRunDateTime;
            "Scheduled Entry ori".Modify();
        end;
    end;

    /// <summary>
    /// Deletes the Job Queue Entry associated with this orchestrator entry.
    /// </summary>
    /// <returns>True if a Job Queue Entry existed and was deleted.</returns>
    internal procedure DeleteJobQueueEntry() Exists: Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange(ID, ID);
        if JobQueueEntry.IsEmpty() then
            exit;
        JobQueueEntry.DeleteAll();
        exit(true);
    end;

    /// <summary>
    /// Opens the Job Queue Entry Card page for the associated Job Queue Entry.
    /// </summary>
    internal procedure DrillDownToJobQueueEntry();
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if JobQueueEntry.Get(ID) then
            Page.Run(Page::"Job Queue Entry Card", JobQueueEntry);
    end;

    /// <summary>
    /// Raises the OnDrillDownToRelatedEntry event for custom drill-down handling.
    /// </summary>
    internal procedure DrillDownToRelatedEntry()
    begin
        OnDrillDownToRelatedEntry(Rec);
    end;

    /// <summary>
    /// Returns the Job Queue Category Code from this entry or from the orchestrator setup.
    /// </summary>
    /// <returns>The resolved category code.</returns>
    internal procedure GetJobQueueCategoryCode() CategoryCode: Text
    var
        JobQueueGeneralSetup: Record "Scheduler Setup ori";
    begin
        if Rec."Job Queue Category Code" <> '' then
            CategoryCode := Rec."Job Queue Category Code"
        else
            if JobQueueGeneralSetup.Get() then
                CategoryCode := JobQueueGeneralSetup.GetJobQueueCategoryCode();
    end;

    /// <summary>
    /// Retrieves the associated Job Queue Entry, caching the result for repeated calls.
    /// </summary>
    /// <param name="JobQueueEntry">The Job Queue Entry record to populate.</param>
    /// <returns>True if the Job Queue Entry was found.</returns>
    internal procedure GetJobQueueEntryOnce(var JobQueueEntry: Record "Job Queue Entry"): Boolean
    begin
        if IsNullGuid(ID) then
            exit(false);
        if JobQueueEntry.ID = ID then exit(true);
        exit(JobQueueEntry.Get(ID));
    end;

    /// <summary>
    /// Creates a orchestrator entry from a Job Queue Entry, optionally prompting the user.
    /// </summary>
    /// <param name="JobQueueEntry">The source Job Queue Entry.</param>
    /// <param name="HideDialog">If true, skips user confirmation dialogs.</param>
    procedure InsertFromJobQueueEntry(JobQueueEntry: Record "Job Queue Entry"; HideDialog: Boolean)
    var
        OrchestratorMgt: Codeunit "Scheduler Mgt ori";
        ConfirmManagement: Codeunit "Confirm Management";
        EntryCreatedQst: Label 'Job Queue Orchestrator Entry has been created, do you want to open it?', Comment = 'is-IS=Vinnsluraðarafærsla hefur verið stofnuð, viltu opna hana?';
        EntryExistsQst: Label 'Do you want to open the entry?', Comment = 'is-IS=Viltu opna færsluna?';
        NotManagementJobQueueErr: Label 'The Job Queue Orchestrator Management Job Queue Entry cannot be one of the Job Queue Orchestrator Entries.', Comment = 'is-IS=Stjórnunarfærsla vinnsluraðarans getur ekki verið ein af vinnsluraðarafærslunum.';
        OverwriteQst: Label 'Job Queue Orchestrator Entry already exists for this Job Queue Entry, do you want to overwrite it?', Comment = 'is-IS=Vinnsluraðarafærsla er þegar til fyrir þessa vinnsluraðafærslu, viltu skrifa yfir hana?';
        ShouldOpenCard: Boolean;
        IsNewEntry: Boolean;
    begin
        if JobQueueEntry.ID = OrchestratorMgt.GetManagementJobQueueId() then
            Error(NotManagementJobQueueErr);

        if Get(JobQueueEntry.ID) then begin
            if HideDialog then begin
                Delete();
                CopyJobQueueEntryToOrchestratorEntry(JobQueueEntry);
                exit;
            end else begin
                if ConfirmManagement.GetResponseOrDefault(OverwriteQst, true) then begin
                    Delete();
                    CopyJobQueueEntryToOrchestratorEntry(JobQueueEntry);
                    IsNewEntry := true;
                end;
                ShouldOpenCard := true;
            end;
        end else begin
            CopyJobQueueEntryToOrchestratorEntry(JobQueueEntry);
            ShouldOpenCard := true;
            IsNewEntry := true;
        end;

        if ShouldOpenCard then
            if IsNewEntry then begin
                if ConfirmManagement.GetResponseOrDefault(EntryCreatedQst, true) then
                    Page.Run(Page::"Scheduled Entry Card ori", Rec);
            end else
                if ConfirmManagement.GetResponseOrDefault(EntryExistsQst, true) then
                    Page.Run(Page::"Scheduled Entry Card ori", Rec);
    end;

    /// <summary>
    /// Raises the OnRegisterJobQueueCodeunits event for subscribers to register codeunits.
    /// </summary>
    internal procedure RegisterJobQueueCodeunits()
    begin
        OnRegisterJobQueueCodeunits(Rec);
    end;

    local procedure CheckRecursion()
    var
        JobQueueMgt: Codeunit "Scheduler Mgt ori";
        RecursionErr: Label 'Scheduling Codeunit "Job Queue Orchestrator Handler" will cause recursion.', Comment = 'is-IS=Áætlun kóðaeiningar "Job Queue Orchestrator Handler" mun valda endurkvæmni.';
    begin
        if ID = JobQueueMgt.GetManagementJobQueueId() then
            Error(RecursionErr);

        if Rec."Object Type to Run" <> Rec."Object Type to Run"::Codeunit then
            exit;
        if Rec."Object ID to Run" = Codeunit::"Scheduler Handler ori" then
            Error(RecursionErr);
    end;

    local procedure GetDefaultDescription(): Text[250]
    var
        DefaultDescription: Text[250];
    begin
        CalcFields("Object Caption to Run");
        DefaultDescription := CopyStr("Object Caption to Run", 1, MaxStrLen(DefaultDescription));
        exit(DefaultDescription);
    end;

    local procedure LookupDateTime(NewDateTime: DateTime): DateTime
    var
        DateTimeDialog: Page "Date-Time Dialog";
    begin
        DateTimeDialog.SetDateTime(RoundDateTime(NewDateTime, 1000));

        if DateTimeDialog.RunModal() = Action::OK then
            NewDateTime := DateTimeDialog.GetDateTime();
        exit(NewDateTime);
    end;

    local procedure LookupObjectID(var NewObjectID: Integer): Boolean
    var
        AllObjWithCaption: Record AllObjWithCaption;
        Objects: Page Objects;
    begin
        if AllObjWithCaption.Get("Object Type to Run", "Object ID to Run") then;
        AllObjWithCaption.FilterGroup(2);
        AllObjWithCaption.SetRange("Object Type", "Object Type to Run");
        AllObjWithCaption.FilterGroup(0);
        Objects.SetRecord(AllObjWithCaption);
        Objects.SetTableView(AllObjWithCaption);
        Objects.LookupMode := true;
        if Objects.RunModal() = Action::LookupOK then begin
            Objects.GetRecord(AllObjWithCaption);
            NewObjectID := AllObjWithCaption."Object ID";
            exit(true);
        end;
        exit(false);
    end;

    local procedure SetMinimumNumberOfMinutesBetweenRuns()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueOrchestratorMinimumNumberOfMinutesBetweenRuns: Integer;
    begin
        if not IsNextRunDateFormulaSet() and (Rec."No. of Minutes between Runs" = 0) then
            Rec."No. of Minutes between Runs" := 1440; // Default to one day
        if Rec."No. of Minutes between Runs" <> 0 then begin
            if JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"Scheduler Handler ori") then
                JobQueueOrchestratorMinimumNumberOfMinutesBetweenRuns := JobQueueEntry."No. of Minutes between Runs";

            if JobQueueOrchestratorMinimumNumberOfMinutesBetweenRuns > 0 then
                if Rec."No. of Minutes between Runs" < JobQueueOrchestratorMinimumNumberOfMinutesBetweenRuns then
                    Rec."No. of Minutes between Runs" := JobQueueOrchestratorMinimumNumberOfMinutesBetweenRuns;
        end;
    end;

    local procedure ValidateTimeRange()
    begin
        if ("Starting Time" <> 0T) and ("Ending Time" <> 0T) and ("Ending Time" <= "Starting Time") then
            Error(EndingTimeBeforeStartingTimeErr);
    end;

    local procedure ValidateWeekday()
    begin
        ValidateRecurringSchedule();
        SetMinimumNumberOfMinutesBetweenRuns();
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

    /// <summary>
    /// Validates that at least one weekday or a next run date formula is configured.
    /// </summary>
    procedure ValidateRecurringSchedule()
    var
        NoValidRecurringScheduleErr: Label 'At least one weekday or a next run date formula must be configured.', Comment = 'is-IS=Að minnsta kosti einn vikudag eða næstu keyrsludagsetningarformúlu verður að stilla.';
    begin
        if not (HasWeekdaySelected() or IsNextRunDateFormulaSet()) then
            Error(NoValidRecurringScheduleErr);
    end;

    /// <summary>
    /// Checks whether any weekday is selected for recurring runs.
    /// </summary>
    /// <returns>True if at least one weekday is selected.</returns>
    procedure HasWeekdaySelected(): Boolean
    begin
        exit("Run on Mondays"
            or "Run on Tuesdays"
            or "Run on Wednesdays"
            or "Run on Thursdays"
            or "Run on Fridays"
            or "Run on Saturdays"
            or "Run on Sundays");
    end;

    local procedure ModifyRecurringFields()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // Sync to Job Queue Entry
        JobQueueEntry.SetRange(ID, ID);
        if not JobQueueEntry.IsEmpty() then begin
            JobQueueEntry.ModifyAll("Run on Mondays", "Run on Mondays", true);
            JobQueueEntry.ModifyAll("Run on Tuesdays", "Run on Tuesdays", true);
            JobQueueEntry.ModifyAll("Run on Wednesdays", "Run on Wednesdays", true);
            JobQueueEntry.ModifyAll("Run on Thursdays", "Run on Thursdays", true);
            JobQueueEntry.ModifyAll("Run on Fridays", "Run on Fridays", true);
            JobQueueEntry.ModifyAll("Run on Saturdays", "Run on Saturdays", true);
            JobQueueEntry.ModifyAll("Run on Sundays", "Run on Sundays", true);
            JobQueueEntry.ModifyAll("No. of Minutes between Runs", "No. of Minutes between Runs", true);
            JobQueueEntry.ModifyAll("Next Run Date Formula", "Next Run Date Formula", true);
        end;
    end;

    local procedure ModifyReportOutputType()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // Sync to Job Queue Entry
        JobQueueEntry.SetRange(ID, ID);
        if not JobQueueEntry.IsEmpty() then
            JobQueueEntry.ModifyAll("Report Output Type", "Report Output Type", true);
    end;

    /// <summary>
    /// Checks whether the Next Run Date Formula field has a value.
    /// </summary>
    /// <returns>True if a date formula is configured.</returns>
    procedure IsNextRunDateFormulaSet(): Boolean
    begin
        exit(Format("Next Run Date Formula") <> '');
    end;

    /// <summary>
    /// Calculates the ending DateTime boundary for a given date based on the Starting/Ending Time configuration.
    /// </summary>
    /// <param name="EndDate">The reference DateTime whose date part is used.</param>
    /// <returns>The ending DateTime boundary.</returns>
    internal procedure GetEndingDateTime(EndDate: DateTime) EndingDateTime: DateTime
    begin
        if "Ending Time" = 0T then
            exit(CreateDateTime(DT2Date(EndDate), 0T));
        if "Starting Time" = 0T then
            exit(CreateDateTime(DT2Date(EndDate), "Ending Time"));
        if "Starting Time" < "Ending Time" then
            exit(CreateDateTime(DT2Date(EndDate), "Ending Time"));
        exit(CreateDateTime(DT2Date(EndDate) + 1, "Ending Time"));
    end;

    /// <summary>
    /// Calculates the starting DateTime boundary for a given date based on the Starting Time configuration.
    /// </summary>
    /// <param name="StartingDate">The reference DateTime whose date part is used.</param>
    /// <returns>The starting DateTime boundary.</returns>
    internal procedure GetStartingDateTime(StartingDate: DateTime) StartingDateTime: DateTime
    begin
        exit(CreateDateTime(DT2Date(StartingDate), "Starting Time"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyJobQueueEntryToOrchestratorEntryBeforeInsert(var Rec: Record "Scheduled Entry ori"; JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyLastExecutionInformationToCustomDimensions(Rec: Record "Scheduled Entry ori"; JobQueueLogEntry: Record "Job Queue Log Entry"; var CustomDimensions: Dictionary of [Text, Text])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyToCustomDimensions(Rec: Record "Scheduled Entry ori"; var CustomDimensions: Dictionary of [Text, Text])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyLastExecutionInformationToCustomDimensions(Rec: Record "Scheduled Entry ori"; JobQueueLogEntry: Record "Job Queue Log Entry"; var CustomDimensions: Dictionary of [Text, Text]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDrillDownToRelatedEntry(Rec: Record "Scheduled Entry ori")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRegisterJobQueueCodeunits(Rec: Record "Scheduled Entry ori")
    begin
    end;
}
