namespace Origo.Bifrost.Orchestrator.Test;

using Microsoft.Sales.Reports;
using Origo.Bifrost.Orchestrator;
using System.DateTime;
using System.EMail;
using System.Environment.Configuration;
using System.TestLibraries.Utilities;
using System.Threading;

/// <summary>
/// Unit tests for the Bifrost Orchestrator extension covering setup, scheduling, notifications, and recurring templates.
/// </summary>
codeunit 96411 "Orchestrator Unit Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER]  
    end;

    var
        Assert: Codeunit "library Assert";
        WrongCategoryCodeErr: Label 'Category Code is wrnog. Expected: %1, Actual: %2', Locked = true, Comment = '%1: expected category code; %2: actual category code';
        EntryRemovedErr: Label '%1 removed.', Locked = true, Comment = '%1 - Table Name';
        EntryNotRemovedErr: Label '%1 not removed.', Locked = true, Comment = '%1 - Table Name';
        InvalidFieldValueTok: Label 'Invalid value in field %1', Locked = true, Comment = '%1 - Field Name';

    [Test]
    procedure CodeunitsSubscribeAndAppearInSetupOnOpenGeneralSetupPage()
    var
        OrchestratorEntry: Record "Scheduled Entry ori";
        JobQueueOkSample: Codeunit "Ok Sample";
        OrchestratorSetupPg: TestPage "Scheduler Setup ori";
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER]  

        // [GIVEN] empty Job Queue Scheduler Entries Setup
        DeleteAllJobQueueSchedulerEntries();

        // [WHEN] setup is opened and subscriber exists
        BindSubscription(JobQueueOkSample);
        OrchestratorSetupPg.OpenView();
        UnBindSubscription(JobQueueOkSample);
        OrchestratorSetupPg.Close();

        // [THEN] Subscriber is registered in the job queue helper setup
        OrchestratorEntry.Get(JobQueueOkSample.GetJobQueueID());
    end;

    [Test]
    procedure JobQueueSchedulerCategoryCodeIsSetOnOpenGeneralSetupPage()
    var
        JobQueueCategory: Record "Job Queue Category";
        JobQueueManagement: Codeunit "Scheduler Mgt ori";
        OrchestratorSetupPg: TestPage "Scheduler Setup ori";
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER]  

        // [GIVEN] clear general setup
        // [GIVEN] empty Job Queue Scheduler Setup
        CleanJobQueueSchedulerSetup();

        // [WHEN] setup is opened
        OrchestratorSetupPg.OpenView();

        // [THEN] JobQueueScheduler Category exists and is set on General Setup
        JobQueueCategory.Get(JobQueueManagement.GetJobQueueOrchestratorTok());
        Assert.AreEqual(JobQueueManagement.GetJobQueueOrchestratorTok(), OrchestratorSetupPg."Job Queue Category Code".Value(), StrSubstNo(WrongCategoryCodeErr, JobQueueManagement.GetJobQueueOrchestratorTok(), OrchestratorSetupPg."Job Queue Category Code".Value()));
        OrchestratorSetupPg.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,JobQueueEntriesModalPageHandler,MessageHandler')]
    procedure JobQueueIsCreatedAndEnqueuedForCodeunitsInJobQueueSchedulerEntriesWhenJobQueueHendlerCUIsRun()
    var
        TempJobQueueEntry: Record "Job Queue Entry" temporary;
        JobQueueOkSample: Codeunit "Ok Sample";
        LibraryJobQueue: Codeunit "Library Orchestrator";
        OrchestratorSetupPg: TestPage "Scheduler Setup ori";
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER]  

        CleanArtifacts();

        // [GIVEN] Job Queue Scheduler General Setup is opened
        // [GIVEN] JobQueueOkSample is registered in setup
        BindSubscription(JobQueueOkSample);
        OrchestratorSetupPg.OpenView();
        UnBindSubscription(JobQueueOkSample);

        // [GIVEN] block all existing records except JobQueueOkSample 
        BlockAllJobQueueSetupEntriesExceptSampleIsOKRecord(OrchestratorSetupPg);

        // [WHEN] Job Queue Handler CU is run
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);
        OrchestratorSetupPg."JobQueueStatusField".Drilldown();
        UnBindSubscription(LibraryJobQueue);

        // [THEN] JobQueueHandler and JobQueueOkSample CUs have been enqueued to run
        LibraryJobQueue.GetCollectedJobQueueEntries(TempJobQueueEntry);
        Assert.IsTrue(TempJobQueueEntry.Count in [2, 3, 4], 'JobQueueHandler and JobQueueOkSample CUs have been enqueued to run');

        TempJobQueueEntry.SetRange("Object Type to Run", TempJobQueueEntry."Object Type to Run"::Codeunit);
        TempJobQueueEntry.SetRange("Object ID to Run", Codeunit::"Scheduler Handler ori");
        Assert.IsTrue(TempJobQueueEntry.Count in [1, 2], 'JobQueueHandler CU has been enqueued to run');

        TempJobQueueEntry.SetRange("Object ID to Run", Codeunit::"Ok Sample");
        Assert.IsTrue(TempJobQueueEntry.Count in [1, 2], 'JobQueueOkSample CU has been enqueued to run');

        OrchestratorSetupPg.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,JobQueueEntriesModalPageHandler,MessageHandler')]
    procedure CategoryCodeIsGotFromJobQueueSchedulerEntryIfSpecified()
    var
        JobQueueEntry: Record "Job Queue Entry";
        LibraryJobQueue: Codeunit "Library Orchestrator";
        JobQueueOkSample: Codeunit "Ok Sample";
        OrchestratorSetupPg: TestPage "Scheduler Setup ori";
        CategoryCode: Code[10];
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER]  

        // [GIVEN] Clean Job Queue Scheduler General Setup 
        CleanJobQueueSchedulerSetup();
        CleanArtifacts();

        // [GIVEN] Job Queue Scheduler General Setup is opened
        // [GIVEN] JobQueueOkSample is registered in setup
        BindSubscription(JobQueueOkSample);
        OrchestratorSetupPg.OpenEdit();
        UnBindSubscription(JobQueueOkSample);

        // [GIVEN] New Category Code "X" for the JobQueueOkSample CU in Job Queue Scheduler Entries 
        CategoryCode := CreateNewCategoryCode();
        OrchestratorSetupPg."Job Queues".GoToKey(JobQueueOkSample.GetJobQueueID());
        OrchestratorSetupPg."Job Queues"."Job Queue Category Code".Value(CategoryCode);


        // [WHEN] Job Queue Handler CU is run
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);
        OrchestratorSetupPg."JobQueueStatusField".Drilldown();
        UnBindSubscription(LibraryJobQueue);


        // [THEN] JobQueueOkSample CUs has been enqueued and CategoryCode == "X"        
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Ok Sample");
        JobQueueEntry.FindFirst();
        Assert.AreEqual(CategoryCode, JobQueueEntry."Job Queue Category Code", StrSubstNo(WrongCategoryCodeErr, CategoryCode, JobQueueEntry."Job Queue Category Code"));

        OrchestratorSetupPg.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,JobQueueEntriesModalPageHandler,MessageHandler')]
    procedure BlockedEntriesAreSkipped()
    var
        TempJobQueueEntry: Record "Job Queue Entry" temporary;
        LibraryJobQueue: Codeunit "Library Orchestrator";
        JobQueueOkSample: Codeunit "Ok Sample";
        OrchestratorSetupPg: TestPage "Scheduler Setup ori";
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER]  

        // [GIVEN] Clean Job Queue Scheduler General Setup 
        DeleteAllJobQueueSchedulerEntries();
        CleanArtifacts();

        // [GIVEN] Job Queue Scheduler General Setup is opened
        // [GIVEN] JobQueueOkSample is registered in setup
        BindSubscription(JobQueueOkSample);
        OrchestratorSetupPg.OpenView();
        UnBindSubscription(JobQueueOkSample);

        // [GIVEN] Entry to run JobQueueOkSample CU is Blocked
        OrchestratorSetupPg."Job Queues".GoToKey(JobQueueOkSample.GetJobQueueID());
        OrchestratorSetupPg."Job Queues".Blocked.SetValue(true);

        // [WHEN] Job Queue Handler CU is run
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);
        OrchestratorSetupPg."JobQueueStatusField".Drilldown();
        UnBindSubscription(LibraryJobQueue);


        // [THEN] JobQueueOkSample CUs has NOT been enqueued
        LibraryJobQueue.GetCollectedJobQueueEntries(TempJobQueueEntry);
        TempJobQueueEntry.SetRange("Object Type to Run", TempJobQueueEntry."Object Type to Run"::Codeunit);
        TempJobQueueEntry.SetRange("Object ID to Run", Codeunit::"Ok Sample");
        Assert.RecordIsEmpty(TempJobQueueEntry);

        OrchestratorSetupPg.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,JobQueueEntriesModalPageHandler,MessageHandler')]
    procedure EntriesWithEarliestDateTimeSetLaterThenMomentOfRunningAreSkipped()
    var
        TempJobQueueEntry: Record "Job Queue Entry" temporary;
        LibraryJobQueue: Codeunit "Library Orchestrator";
        JobQueueOkSample: Codeunit "Ok Sample";
        OrchestratorSetupPg: TestPage "Scheduler Setup ori";
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER]  

        // [GIVEN] Clean Job Queue Scheduler General Setup 
        DeleteAllJobQueueSchedulerEntries();
        CleanArtifacts();

        // [GIVEN] Job Queue Scheduler General Setup is opened
        // [GIVEN] JobQueueOkSample is registered in setup
        BindSubscription(JobQueueOkSample);
        OrchestratorSetupPg.OpenView();
        UnBindSubscription(JobQueueOkSample);

        // [GIVEN] Setup "Earliest Start Date/Time" on Entry to run JobQueueOkSample CU 
        OrchestratorSetupPg."Job Queues".GoToKey(JobQueueOkSample.GetJobQueueID());
        OrchestratorSetupPg."Job Queues"."Earliest Start Date/Time".SetValue(CurrentDateTime + 1440000); // one day

        // [WHEN] Job Queue Handler CU is run
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);
        OrchestratorSetupPg."JobQueueStatusField".Drilldown();
        UnBindSubscription(LibraryJobQueue);


        // [THEN] JobQueueOkSample CUs has NOT been enqueued
        LibraryJobQueue.GetCollectedJobQueueEntries(TempJobQueueEntry);
        TempJobQueueEntry.SetRange("Object Type to Run", TempJobQueueEntry."Object Type to Run"::Codeunit);
        TempJobQueueEntry.SetRange("Object ID to Run", Codeunit::"Ok Sample");
        Assert.RecordIsEmpty(TempJobQueueEntry);

        OrchestratorSetupPg.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,JobQueueEntriesModalPageHandler,MessageHandler')]
    procedure EarliestStartDateTimeIsRecalculated()
    var
        OrchestratorEntry: Record "Scheduled Entry ori";
        JobQueueEntry: Record "Job Queue Entry";
        LibraryJobQueue: Codeunit "Library Orchestrator";
        JobQueueOkSample: Codeunit "Ok Sample";
        OrchestratorMgt: Codeunit "Scheduler Mgt ori";
        OrchestratorSetupPg: TestPage "Scheduler Setup ori";
        NotEarlierThen: DateTime;
        Momment: DateTime;
        EarliestStartDateTimeErr: Label '%1 is not correctly recalculated', Comment = '%1: "Earliest Start Date/Time"';
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER]  

        // [GIVEN] Clean Job Queue Scheduler General Setup 
        DeleteAllJobQueueSchedulerEntries();
        CleanArtifacts();

        // [GIVEN] Job Queue Scheduler General Setup is opened
        BindSubscription(JobQueueOkSample);
        OrchestratorSetupPg.OpenView();
        UnBindSubscription(JobQueueOkSample);

        // [GIVEN] Setup "Earliest Start Date/Time" and "No. of Minutes between Runs" on Entry to run JobQueueOkSample CU 
        Momment := CurrentDateTime();
        OrchestratorSetupPg."Job Queues".GoToKey(JobQueueOkSample.GetJobQueueID());
        OrchestratorSetupPg."Job Queues"."Earliest Start Date/Time".SetValue(Momment);
        OrchestratorSetupPg."Job Queues"."No. of Minutes between Runs".SetValue(1440);

        // [GIVEN] Next earliest time to run
        NotEarlierThen := Momment + 1440000;

        // [WHEN] Job Queue Handler CU is run
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);
        OrchestratorSetupPg."JobQueueStatusField".Drilldown();
        UnBindSubscription(LibraryJobQueue);


        // [THEN] time for Entry to run JobQueueOkSample CU is correctly recalculated
        OrchestratorEntry.Get(JobQueueOkSample.GetJobQueueID());
        JobQueueEntry.Get(OrchestratorMgt.GetManagementJobQueueId());
        Assert.IsFalse(JobQueueEntry."Earliest Start Date/Time" > NotEarlierThen, StrSubstNo(EarliestStartDateTimeErr, JobQueueEntry.FieldName("Earliest Start Date/Time")));

        OrchestratorSetupPg.Close();
    end;

    [Test]
    procedure "NoneNotificationType_EnterNotificationReceipient_VerifyErrorShouldBeBlank"()
    var
        OrchestratorEntry: Record "Scheduled Entry ori";
        LibraryRandom: Codeunit Any;
        NoNotificationErr: Label '%3 is not supported for %1 %2', Locked = true;
    begin
        // [GIVEN] None Notification Type
        OrchestratorEntry.Init();
        OrchestratorEntry.Validate("Notification Type", OrchestratorEntry."Notification Type"::None);
        // [WHEN] Enter Notification Receipient 
        asserterror OrchestratorEntry.Validate("Notification Recipient", LibraryRandom.AlphanumericText(10));
        // [THEN] Verify Error Should Be Blank
        Assert.ExpectedError(StrSubstNo(NoNotificationErr, OrchestratorEntry.FieldCaption("Notification Type"), OrchestratorEntry."Notification Type", OrchestratorEntry.FieldCaption("Notification Recipient")));
    end;

    [Test]
    procedure "EMailNotificationType_NonEmailEntered_VerifyErrorShouldBeEmailAddress"()
    var
        OrchestratorEntry: Record "Scheduled Entry ori";
        LibraryRandom: Codeunit Any;
        NotValidErr: Label 'The email address "%1" is not valid.', Locked = true;
        TestEMailAddress: Text;
    begin
        // [GIVEN] EMail Notification Type 
        OrchestratorEntry.Init();
        OrchestratorEntry.Validate("Notification Type", OrchestratorEntry."Notification Type"::EMail);
        // [WHEN] Non Email Entered 
        TestEMailAddress := LibraryRandom.AlphanumericText(10);
        asserterror OrchestratorEntry.Validate("Notification Recipient", TestEMailAddress);
        // [THEN] Verify Error Should Be Email Address 
        Assert.ExpectedError(StrSubstNo(NotValidErr, TestEMailAddress));
    end;

    [Test]
    procedure "EMailNotificationType_RestartNotificationType_VerifyEMailContent"()
    var
        OrchestratorEntry: Record "Scheduled Entry ori";
        JobQueueEntry: Record "Job Queue Entry";
        EmailItem: Record "Email Item";
        JobQueueOkSample: Codeunit "Ok Sample";
        EMailHandler: Codeunit "Email Handler";
        LibraryRandom: Codeunit Any;
        OrchestratorSetupPg: TestPage "Scheduler Setup ori";
        NotificationInterface: Interface "Notification ori";
        JobLastErrMsg: Label 'The job last execution error was:', Locked = true;
        JobRestartedMsg: Label 'The following job has been restarted:', Locked = true;
        JobRestartedSubjectMsg: Label 'Job ''%1'' has been restarted', Comment = '%1 = Job Description', Locked = true;
        EnvironmentMsg: Label 'Environment information:', Locked = true;
        SchedulerSetupMsg: Label 'Open Orchestrator Setup', Locked = true;
        JobQueueEntryMsg: Label 'Open Job Queue Entry', Locked = true;
        FieldValidationErr: Label 'Incorrect field value: %1', Locked = true;
        ReturnedEMailBody: Text;
    begin
        // [GIVEN] Clean Job Queue Scheduler General Setup 
        DeleteAllJobQueueSchedulerEntries();
        CleanArtifacts();
        // [GIVEN] EMailNotificationType
        // [GIVEN] Job Queue Scheduler General Setup is opened
        // [GIVEN] JobQueueOkSample is registered in setup
        BindSubscription(JobQueueOkSample);
        OrchestratorSetupPg.OpenEdit();
        OrchestratorSetupPg."Job Queues".Description.SetValue(LibraryRandom.AlphanumericText(100));
        OrchestratorSetupPg."Job Queues"."Notification Type".SetValue(OrchestratorEntry."Notification Type"::EMail);
        OrchestratorSetupPg."Job Queues"."Notification Recipient".SetValue('gunnar@navision.guru');
        OrchestratorSetupPg."Job Queues".ScheduleNow.Invoke();
        OrchestratorSetupPg.Close();
        UnBindSubscription(JobQueueOkSample);

        // [WHEN] Restart Notification Type
        OrchestratorEntry.FindFirst();
        JobQueueEntry.Get(OrchestratorEntry.ID);
        JobQueueEntry."Error Message" := CopyStr(LibraryRandom.AlphanumericText(250), 1, 2048);
        // [THEN] Verify EMail Content
        Bindsubscription(EMailHandler);
        NotificationInterface := OrchestratorEntry."Notification Type";
        NotificationInterface.SendRestartNotification(OrchestratorEntry, JobQueueEntry);
        UnBindSubscription(EMailHandler);
        EmailItem := EMailHandler.GetEMailItem();
        Assert.AreEqual('gunnar@navision.guru', EmailItem."Send to", StrSubstNo(FieldValidationErr, EmailItem.FieldName("Send to")));
        Assert.AreEqual(StrSubstNo(JobRestartedSubjectMsg, OrchestratorEntry.Description), EmailItem.Subject, StrSubstNo(FieldValidationErr, EmailItem.FieldName("Subject")));
        Assert.IsFalse(EmailItem."Plaintext Formatted", StrSubstNo(FieldValidationErr, EmailItem.FieldName("Plaintext Formatted")));

        ReturnedEMailBody := EMailHandler.GetEMailBodyText();
        Assert.ExpectedMessage(JobLastErrMsg, ReturnedEMailBody);
        Assert.ExpectedMessage(JobRestartedMsg, ReturnedEMailBody);
        Assert.ExpectedMessage(EnvironmentMsg, ReturnedEMailBody);
        Assert.ExpectedMessage(SchedulerSetupMsg, ReturnedEMailBody);
        Assert.ExpectedMessage(JobQueueEntryMsg, ReturnedEMailBody);
        Assert.ExpectedMessage(JobQueueEntry."Error Message", ReturnedEMailBody);

    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure BlockJobQueueSchedulerEntryOpenFromJQEntryCard()
    var
        JobQueueEntry: Record "Job Queue Entry";
        OrchestratorEntry: Record "Scheduled Entry ori";
        JobQueueOkSample: Codeunit "Ok Sample";
        OrchestratorSetupPg: TestPage "Scheduler Setup ori";
        OrchestratorEntryCard: TestPage "Scheduled Entry Card ori";
        JobQueueEntryCard: TestPage "Job Queue Entry Card";
        JobQueueID: Guid;
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER]  
        // Verify that blocking the Job Queue Scheduler is not removing it & Job Queue Entry is removed after confirmation

        // [GIVEN] Clean Job Queue Scheduler General Setup 
        DeleteAllJobQueueSchedulerEntries();
        CleanArtifacts();

        // [GIVEN] Job Queue Scheduler General Setup is opened
        // [GIVEN] JobQueueOkSample is registered in setup
        BindSubscription(JobQueueOkSample);
        OrchestratorSetupPg.OpenView();
        OrchestratorSetupPg."Job Queues".GoToKey(JobQueueOkSample.GetJobQueueID());
        OrchestratorSetupPg."Job Queues".ScheduleNow.Invoke();
        OrchestratorSetupPg.Close();
        JobQueueID := JobQueueOkSample.GetJobQueueID();
        UnBindSubscription(JobQueueOkSample);

        // [GIVEN] Job Queue Entry Card is opened
        JobQueueEntry.Get(JobQueueID);
        JobQueueEntryCard.OpenView();
        JobQueueEntryCard.GoToRecord(JobQueueEntry);

        // [GIVEN] Open Job Queue Scheduler from the Job Queue Entry Card 
        OrchestratorEntryCard.Trap();
        JobQueueEntryCard."AddToScheduler ori".Invoke();

        // [THEN] 'Blocked' is false
        Assert.IsFalse(OrchestratorEntryCard.Blocked.AsBoolean(), StrSubstNo(InvalidFieldValueTok, OrchestratorEntryCard.Blocked.Caption()));

        // [THEN] 'Scheduled' is true
        Assert.IsTrue(OrchestratorEntryCard.Scheduled.AsBoolean(), StrSubstNo(InvalidFieldValueTok, OrchestratorEntryCard.Scheduled.Caption()));

        // [WHEN] Block the entry
        OrchestratorEntryCard.Blocked.SetValue(true);

        // [THEN] 'Blocked' becomes true
        Assert.IsTrue(OrchestratorEntryCard.Blocked.AsBoolean(), StrSubstNo(InvalidFieldValueTok, OrchestratorEntryCard.Blocked.Caption()));

        // [THEN] 'Scheduled' becomes false
        Assert.IsFalse(OrchestratorEntryCard.Scheduled.AsBoolean(), StrSubstNo(InvalidFieldValueTok, OrchestratorEntryCard.Scheduled.Caption()));

        // [THEN] Job Queue Entry is removed
        Assert.IsFalse(JobQueueEntry.Get(JobQueueID), StrSubstNo(EntryNotRemovedErr, JobQueueEntry.TableCaption()));

        // [THEN] Job Queue Scheduler Entry is not removed
        Assert.IsTrue(OrchestratorEntry.Get(JobQueueID), StrSubstNo(EntryRemovedErr, OrchestratorEntry.TableCaption()));
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerRefuseOverwriteOpenCard(Question: Text[1024]; var Reply: Boolean)
    begin
        // Refuse to overwrite, but agree to open the card
        if StrPos(Question, 'overwrite') > 0 then
            Reply := false
        else
            Reply := true;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerRefuseOverwriteOpenCard')]
    procedure JobQueueSchedulerEntryCardOpensWhenEntryExistsAndUserRefusesOverwrite()
    var
        JobQueueEntry: Record "Job Queue Entry";
        OrchestratorEntry: Record "Scheduled Entry ori";
        JobQueueOkSample: Codeunit "Ok Sample";
        OrchestratorSetupPg: TestPage "Scheduler Setup ori";
        OrchestratorCardPg: TestPage "Scheduled Entry Card ori";
        JobQueueEntryCard: TestPage "Job Queue Entry Card";
        JobQueueID: Guid;
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER]  
        // Verify that Job Queue Scheduler Entry card opens when entry exists and user refuses overwrite

        // [GIVEN] Clean Job Queue Scheduler General Setup 
        DeleteAllJobQueueSchedulerEntries();
        CleanArtifacts();

        // [GIVEN] Job Queue Scheduler entry already exists
        BindSubscription(JobQueueOkSample);
        OrchestratorSetupPg.OpenView();
        OrchestratorSetupPg."Job Queues".GoToKey(JobQueueOkSample.GetJobQueueID());
        OrchestratorSetupPg."Job Queues".ScheduleNow.Invoke();
        OrchestratorSetupPg.Close();
        JobQueueID := JobQueueOkSample.GetJobQueueID();
        UnBindSubscription(JobQueueOkSample);

        // [GIVEN] Job Queue Entry Card is opened
        JobQueueEntry.Get(JobQueueID);
        JobQueueEntryCard.OpenView();
        JobQueueEntryCard.GoToRecord(JobQueueEntry);

        // [WHEN] Try to add Job Queue Scheduler Entry from Job Queue Entry Card
        // [AND] User refuses overwrite but confirms to open card
        OrchestratorCardPg.Trap();
        JobQueueEntryCard."AddToScheduler ori".Invoke();

        // [THEN] Job Queue Scheduler Entry card page opens with existing entry
        // Verify by checking Object Type and Object ID match the expected entry
        Assert.AreEqual(Format(OrchestratorCardPg."Object Type to Run"), OrchestratorCardPg."Object Type to Run".Value, 'Wrong entry opened on card page');
        Assert.AreEqual(Format(OrchestratorCardPg."Object ID to Run"), OrchestratorCardPg."Object ID to Run".Value, 'Wrong entry opened on card page');
        OrchestratorCardPg.Close();
        JobQueueEntryCard.Close();

        // [THEN] Job Queue Scheduler Entry is not removed
        Assert.IsTrue(OrchestratorEntry.Get(JobQueueID), StrSubstNo(EntryRemovedErr, OrchestratorEntry.TableCaption()));
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    procedure JobQueueEntriesModalPageHandler(var JobQueueEntries: TestPage "Job Queue Entries")
    begin
        // [WHEN] Job Queue Handler CU is run
        JobQueueEntries.RunInForeground.Invoke();
    end;


    local procedure BlockAllJobQueueSetupEntriesExceptSampleIsOKRecord(var OrchestratorSetupPg: TestPage "Scheduler Setup ori")
    var
        JobQueueOkSample: Codeunit "Ok Sample";
    begin
        OrchestratorSetupPg."Job Queues".Filter.SetFilter(ID, StrSubstNo('<>%1', JobQueueOkSample.GetJobQueueID()));
        OrchestratorSetupPg."Job Queues".Filter.SetFilter(Blocked, StrSubstNo('%1', false));

        if OrchestratorSetupPg."Job Queues".First() then
            repeat
                OrchestratorSetupPg."Job Queues".Blocked.SetValue(true);
            until not OrchestratorSetupPg."Job Queues".Next();

        OrchestratorSetupPg."Job Queues".Filter.SetFilter(ID, '');
        OrchestratorSetupPg."Job Queues".Filter.SetFilter(Blocked, '');
    end;

    local procedure CleanJobQueueSchedulerSetup()
    var
        JobQueueGeneralSetup: Record "Scheduler Setup ori";
    begin
        if JobQueueGeneralSetup.Get() then
            JobQueueGeneralSetup.Delete(true);

        DeleteAllJobQueueSchedulerEntries();
    end;

    local procedure CleanArtifacts()
    var
        JobQueueEntry: Record "Job Queue Entry";
        TempOrchestratorEntry: Record "Scheduled Entry ori" temporary;
        JobQueueOkSample: Codeunit "Ok Sample";
    begin
        TempOrchestratorEntry.ID := JobQueueOkSample.GetJobQueueID();

        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Ok Sample");
        JobQueueEntry.SetRange("Record ID to Process", TempOrchestratorEntry.RecordId());
        if not JobQueueEntry.IsEmpty() then
            JobQueueEntry.DeleteAll();
    end;

    local procedure DeleteAllJobQueueSchedulerEntries()
    var
        OrchestratorEntry: Record "Scheduled Entry ori";
    begin
        OrchestratorEntry.DeleteAll(true);
    end;

    local procedure CreateNewCategoryCode() CategoryCode: Code[10]
    var
        JobQueueGeneralSetup: Record "Scheduler Setup ori";
        LibraryRandom: Codeunit "Any";
    begin
        CategoryCode := Format(LibraryRandom.AlphanumericText(MaxStrLen(CategoryCode)));
        JobQueueGeneralSetup.VerifyJobQueueCategoryCode(CategoryCode, CategoryCode);
    end;

    [Test]
    procedure RecurringTemplateWeekdayValidation()
    var
        RecurringTemplate: Record "Recurring Template ori";
        RecurringTemplateCard: TestPage "Recurring Template ori";
        OrchestratorSetupPg: TestPage "Scheduler Setup ori";
        RecurringTemplatesPage: TestPage "Recurring Templates ori";
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER] [RECURRING TEMPLATE]
        // [SCENARIO] At least one weekday OR Next Run Date Formula must be set

        // [GIVEN] A new Recurring Template record with all weekdays set to false and no DateFormula
        RecurringTemplate.Init();
        RecurringTemplate.Code := 'TEST001';
        RecurringTemplate.Description := 'Test Template';
        RecurringTemplate.Insert();

        // [GIVEN] Job Queue Scheduler Setup page is opened
        OrchestratorSetupPg.OpenView();

        // [GIVEN] Recurring Templates list page is opened via RecurringTemplates action
        RecurringTemplatesPage.Trap();
        OrchestratorSetupPg.RecurringTemplates.Invoke();

        // [GIVEN] Card page is opened by clicking Edit on record in the list
        RecurringTemplateCard.Trap();
        RecurringTemplatesPage.GoToRecord(RecurringTemplate);
        RecurringTemplatesPage.Edit().Invoke();

        // [WHEN] Attempting to close the card page after modifying a field triggers OnModify validation
        RecurringTemplateCard.Description.SetValue('Trigger OnModify');
        asserterror RecurringTemplateCard.Close();

        // [WHEN] All weekdays are unchecked
        asserterror RecurringTemplate.Validate("Run on Mondays");
        asserterror RecurringTemplate.Validate("Run on Tuesdays");
        asserterror RecurringTemplate.Validate("Run on Wednesdays");
        asserterror RecurringTemplate.Validate("Run on Thursdays");
        asserterror RecurringTemplate.Validate("Run on Fridays");
        asserterror RecurringTemplate.Validate("Run on Saturdays");
        asserterror RecurringTemplate.Validate("Run on Sundays");

        // [THEN] Error should be raised indicating at least one scheduling option must be set
    end;

    [Test]
    procedure RecurringTemplateTimeRangeValidation()
    var
        RecurringTemplate: Record "Recurring Template ori";
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER] [RECURRING TEMPLATE]
        // [SCENARIO] Ending Time must be greater than Starting Time

        // [GIVEN] A new Recurring Template with valid weekday
        RecurringTemplate.Init();
        RecurringTemplate.Code := 'TEST002';
        RecurringTemplate.Description := 'Test Template with Time Range.';
        RecurringTemplate."Run on Mondays" := true;
        RecurringTemplate."Starting Time" := 150000T; // 15:00:00

        // [WHEN] Ending Time is set to earlier than Starting Time
        asserterror RecurringTemplate.Validate("Ending Time", 100000T); // 10:00:00

        // [THEN] Error should be raised for invalid time range
    end;

    [Test]
    procedure RecurringTemplateCanBeInsertedWithValidData()
    var
        RecurringTemplate: Record "Recurring Template ori";
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER] [RECURRING TEMPLATE]
        // [SCENARIO] Recurring Template can be inserted with valid weekday and time data

        // [GIVEN] A new Recurring Template with valid data
        RecurringTemplate.Init();
        RecurringTemplate.Code := 'TEST003';
        RecurringTemplate.Description := 'Valid Test Template';
        RecurringTemplate."Run on Mondays" := true;
        RecurringTemplate."Run on Fridays" := true;
        RecurringTemplate."Starting Time" := 080000T; // 08:00:00
        RecurringTemplate."Ending Time" := 170000T; // 17:00:00
        RecurringTemplate."No. of Minutes between Runs" := 60;

        // [WHEN] Record is inserted
        RecurringTemplate.Insert(true);

        // [THEN] Record is successfully created
        Assert.IsTrue(RecurringTemplate.Get('TEST003'), 'Recurring Template should be inserted successfully.');
    end;

    [Test]
    procedure RecurringTemplatesActionNavigationFromSetupPage()
    var
        OrchestratorSetupPg: TestPage "Scheduler Setup ori";
        RecurringTemplatesPage: TestPage "Recurring Templates ori";
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER] [RECURRING TEMPLATE]
        // [SCENARIO] Recurring Templates can be accessed from Job Queue Scheduler Setup page

        // [GIVEN] Job Queue Scheduler Setup page is opened
        OrchestratorSetupPg.OpenView();

        // [WHEN] Recurring Templates action is invoked
        RecurringTemplatesPage.Trap();
        OrchestratorSetupPg.RecurringTemplates.Invoke();

        // [THEN] Recurring Templates page is opened
        Assert.IsTrue(RecurringTemplatesPage.Editable(), 'Recurring Templates page should be accessible from Setup.');

        RecurringTemplatesPage.Close();
        OrchestratorSetupPg.Close();
    end;

    [Test]
    procedure RecurringTemplateCardPageCanBeOpened()
    var
        RecurringTemplate: Record "Recurring Template ori";
        OrchestratorSetupPg: TestPage "Scheduler Setup ori";
        RecurringTemplatesPage: TestPage "Recurring Templates ori";
        RecurringTemplateCard: TestPage "Recurring Template ori";
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER] [RECURRING TEMPLATE]
        // [SCENARIO] Recurring Template card page can be opened from list page by clicking Edit

        // [GIVEN] A Recurring Template record exists
        RecurringTemplate.Init();
        RecurringTemplate.Code := 'TEST004';
        RecurringTemplate.Description := 'Test Card Page';
        RecurringTemplate."Run on Mondays" := true;
        RecurringTemplate.Insert();

        // [GIVEN] Job Queue Scheduler Setup page is opened
        OrchestratorSetupPg.OpenView();

        // [GIVEN] Recurring Templates list page is opened via RecurringTemplates action
        RecurringTemplatesPage.Trap();
        OrchestratorSetupPg.RecurringTemplates.Invoke();

        // [WHEN] Card page is opened by clicking Edit on record in the list
        RecurringTemplateCard.Trap();
        RecurringTemplatesPage.GoToRecord(RecurringTemplate);
        RecurringTemplatesPage.Edit().Invoke();

        // [THEN] Card page is opened and displays the template
        Assert.IsTrue(RecurringTemplateCard.Editable(), 'Recurring Template card page should be accessible from list.');

        RecurringTemplateCard.Close();
        RecurringTemplatesPage.Close();
        OrchestratorSetupPg.Close();
    end;

    [Test]
    procedure RecurringTemplateNoOfMinutesBetweenRunsValidation()
    var
        RecurringTemplate: Record "Recurring Template ori";
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER] [RECURRING TEMPLATE]
        // [SCENARIO] No. of Minutes between Runs validation and default value

        // [GIVEN] A new Recurring Template with valid weekday
        RecurringTemplate.Init();
        RecurringTemplate.Code := 'TEST005';
        RecurringTemplate.Description := 'Test Minutes Between Runs';
        RecurringTemplate."Run on Mondays" := true;
        RecurringTemplate.Insert();

        // [WHEN] No. of Minutes between Runs is set to 0
        RecurringTemplate.Validate("No. of Minutes between Runs", 0);

        // [THEN] It defaults to 1440
        Assert.AreEqual(1440, RecurringTemplate."No. of Minutes between Runs", 'No. of Minutes between Runs should default to 1440 when set to 0.');

        // [WHEN] No. of Minutes between Runs is set to a specific value
        Evaluate(RecurringTemplate."Next Run Date Formula", '<+1W>');
        RecurringTemplate.Validate("No. of Minutes between Runs", 60);

        // [THEN] Next Run Date Formula should be cleared
        Assert.AreEqual('', Format(RecurringTemplate."Next Run Date Formula"), 'Next Run Date Formula should be cleared when No. of Minutes between Runs is set.');
    end;

    [Test]
    procedure RecurringTemplateNextRunDateFormulaValidation()
    var
        RecurringTemplate: Record "Recurring Template ori";
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER] [RECURRING TEMPLATE]
        // [SCENARIO] Next Run Date Formula validation clears related fields

        // [GIVEN] A Recurring Template with minutes and weekdays configured
        RecurringTemplate.Init();
        RecurringTemplate.Code := 'TEST006';
        RecurringTemplate.Description := 'Test Date Formula';
        RecurringTemplate."Run on Mondays" := true;
        RecurringTemplate."Run on Fridays" := true;
        RecurringTemplate."No. of Minutes between Runs" := 60;
        RecurringTemplate.Insert();

        // [WHEN] Next Run Date Formula is set
        Evaluate(RecurringTemplate."Next Run Date Formula", '<+1W>');
        RecurringTemplate.Validate("Next Run Date Formula", RecurringTemplate."Next Run Date Formula");

        // [THEN] No. of Minutes between Runs should be cleared
        Assert.AreEqual(0, RecurringTemplate."No. of Minutes between Runs", 'No. of Minutes between Runs should be cleared when Next Run Date Formula is set.');

        // [THEN] All weekday fields should be cleared
        Assert.IsFalse(RecurringTemplate."Run on Mondays", 'Run on Mondays should be cleared.');
        Assert.IsFalse(RecurringTemplate."Run on Fridays", 'Run on Fridays should be cleared.');
        Assert.IsFalse(RecurringTemplate."Run on Tuesdays", 'Run on Tuesdays should be cleared.');
        Assert.IsFalse(RecurringTemplate."Run on Wednesdays", 'Run on Wednesdays should be cleared.');
        Assert.IsFalse(RecurringTemplate."Run on Thursdays", 'Run on Thursdays should be cleared.');
        Assert.IsFalse(RecurringTemplate."Run on Saturdays", 'Run on Saturdays should be cleared.');
        Assert.IsFalse(RecurringTemplate."Run on Sundays", 'Run on Sundays should be cleared.');
    end;

    [Test]
    procedure SelectTemplateOnSchedulerEntry_VerifyAllFieldsCopy()
    var
        RecurringTemplate: Record "Recurring Template ori";
        OrchestratorEntry: Record "Scheduled Entry ori";
        OriginalDescription: Text[1024];
        FieldMismatchErr: Label 'Field %1 not correctly copied from template. Expected: %2, Actual: %3', Comment = '%1 = Field name, %2 = Expected value, %3 = Actual value';
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER] [RECURRING TEMPLATE]
        // [SCENARIO] Select a template on scheduler entry - verify all fields copy (except Description)

        // [GIVEN] A Recurring Template with all fields populated
        RecurringTemplate.Init();
        RecurringTemplate.Code := 'TEMPLATETEST';
        RecurringTemplate.Description := 'Template Description';
        RecurringTemplate."Time Zone Nr." := 23;
        RecurringTemplate."Run on Mondays" := true;
        RecurringTemplate."Run on Tuesdays" := true;
        RecurringTemplate."Run on Wednesdays" := false;
        RecurringTemplate."Run on Thursdays" := true;
        RecurringTemplate."Run on Fridays" := false;
        RecurringTemplate."Run on Saturdays" := true;
        RecurringTemplate."Run on Sundays" := false;
        RecurringTemplate."Starting Time" := 080000T; // 08:00:00
        RecurringTemplate."Ending Time" := 170000T; // 17:00:00
        RecurringTemplate."No. of Minutes between Runs" := 120;
        Evaluate(RecurringTemplate."Next Run Date Formula", '');
        RecurringTemplate.Insert();

        // [GIVEN] A new Job Queue Scheduler Entry with a different Description
        OrchestratorEntry.Init();
        OrchestratorEntry.ID := CreateGuid();
        OrchestratorEntry."Object Type to Run" := OrchestratorEntry."Object Type to Run"::Report;
        OrchestratorEntry."Object ID to Run" := 1;
        OriginalDescription := 'Entry Description';
        OrchestratorEntry.Description := OriginalDescription;
        OrchestratorEntry.Insert();

        // [WHEN] Template is selected on the Scheduler Entry
        OrchestratorEntry.Validate("Recurring Template Code", 'TEMPLATETEST');
        OrchestratorEntry.Modify();

        // [THEN] Verify all fields are copied from template (except Description)
        Assert.AreEqual(23, OrchestratorEntry."Time Zone Nr.", StrSubstNo(FieldMismatchErr, 'Time Zone Nr.', '23', OrchestratorEntry."Time Zone Nr."));
        Assert.IsTrue(OrchestratorEntry."Run on Mondays", StrSubstNo(FieldMismatchErr, 'Run on Mondays', 'true', Format(OrchestratorEntry."Run on Mondays")));
        Assert.IsTrue(OrchestratorEntry."Run on Tuesdays", StrSubstNo(FieldMismatchErr, 'Run on Tuesdays', 'true', Format(OrchestratorEntry."Run on Tuesdays")));
        Assert.IsFalse(OrchestratorEntry."Run on Wednesdays", StrSubstNo(FieldMismatchErr, 'Run on Wednesdays', 'false', Format(OrchestratorEntry."Run on Wednesdays")));
        Assert.IsTrue(OrchestratorEntry."Run on Thursdays", StrSubstNo(FieldMismatchErr, 'Run on Thursdays', 'true', Format(OrchestratorEntry."Run on Thursdays")));
        Assert.IsFalse(OrchestratorEntry."Run on Fridays", StrSubstNo(FieldMismatchErr, 'Run on Fridays', 'false', Format(OrchestratorEntry."Run on Fridays")));
        Assert.IsTrue(OrchestratorEntry."Run on Saturdays", StrSubstNo(FieldMismatchErr, 'Run on Saturdays', 'true', Format(OrchestratorEntry."Run on Saturdays")));
        Assert.IsFalse(OrchestratorEntry."Run on Sundays", StrSubstNo(FieldMismatchErr, 'Run on Sundays', 'false', Format(OrchestratorEntry."Run on Sundays")));
        Assert.AreEqual(080000T, OrchestratorEntry."Starting Time", StrSubstNo(FieldMismatchErr, 'Starting Time', '08:00:00', Format(OrchestratorEntry."Starting Time")));
        Assert.AreEqual(170000T, OrchestratorEntry."Ending Time", StrSubstNo(FieldMismatchErr, 'Ending Time', '17:00:00', Format(OrchestratorEntry."Ending Time")));
        Assert.AreEqual(120, OrchestratorEntry."No. of Minutes between Runs", StrSubstNo(FieldMismatchErr, 'No. of Minutes between Runs', '120', Format(OrchestratorEntry."No. of Minutes between Runs")));
        Assert.AreEqual('', Format(OrchestratorEntry."Next Run Date Formula"), StrSubstNo(FieldMismatchErr, 'Next Run Date Formula', '', Format(OrchestratorEntry."Next Run Date Formula")));

        // [THEN] Verify Description is NOT changed (should remain as original)
        Assert.AreEqual(OriginalDescription, OrchestratorEntry.Description, StrSubstNo(FieldMismatchErr, 'Description', OriginalDescription, OrchestratorEntry.Description));
    end;

    [Test]
    procedure ManuallyModifyWeekdayFields_VerifySyncToJobQueueEntry()
    var
        OrchestratorEntry: Record "Scheduled Entry ori";
        JobQueueEntry: Record "Job Queue Entry";
        FieldNotSyncedErr: Label 'Field %1 not synced to Job Queue Entry. Expected: %2, Actual: %3', Comment = '%1 = Field name, %2 = Expected value, %3 = Actual value';
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER] [SYNC TO JOB QUEUE ENTRY]
        // [SCENARIO] Manually modify weekday fields on scheduler entry - verify sync to Job Queue Entry

        // [GIVEN] A Job Queue Scheduler Entry with created Job Queue Entry (scheduled)
        OrchestratorEntry.Init();
        OrchestratorEntry.ID := CreateGuid();
        OrchestratorEntry."Object Type to Run" := OrchestratorEntry."Object Type to Run"::Codeunit;
        OrchestratorEntry."Object ID to Run" := Codeunit::"Scheduler Handler ori";
        OrchestratorEntry."Run on Mondays" := false;
        OrchestratorEntry."Run on Tuesdays" := false;
        OrchestratorEntry."Run on Wednesdays" := false;
        OrchestratorEntry."Run on Thursdays" := false;
        OrchestratorEntry."Run on Fridays" := false;
        OrchestratorEntry."Run on Saturdays" := false;
        OrchestratorEntry."Run on Sundays" := false;
        OrchestratorEntry."No. of Minutes between Runs" := 60;
        OrchestratorEntry.Insert();

        // [GIVEN] Create corresponding Job Queue Entry
        JobQueueEntry.Init();
        JobQueueEntry.ID := OrchestratorEntry.ID;
        JobQueueEntry."Object Type to Run" := OrchestratorEntry."Object Type to Run";
        JobQueueEntry."Object ID to Run" := OrchestratorEntry."Object ID to Run";
        JobQueueEntry."Run on Mondays" := false;
        JobQueueEntry."Run on Tuesdays" := false;
        JobQueueEntry."Run on Wednesdays" := false;
        JobQueueEntry."Run on Thursdays" := false;
        JobQueueEntry."Run on Fridays" := false;
        JobQueueEntry."Run on Saturdays" := false;
        JobQueueEntry."Run on Sundays" := false;
        JobQueueEntry.Insert();

        // [WHEN] Manually modify weekday fields on scheduler entry
        OrchestratorEntry.Validate("Run on Mondays", true);
        OrchestratorEntry.Validate("Run on Wednesdays", true);
        OrchestratorEntry.Validate("Run on Fridays", true);
        OrchestratorEntry.Modify();

        // [THEN] Verify changes are synced to Job Queue Entry
        JobQueueEntry.Get(OrchestratorEntry.ID);
        Assert.IsTrue(JobQueueEntry."Run on Mondays", StrSubstNo(FieldNotSyncedErr, 'Run on Mondays', 'true', Format(JobQueueEntry."Run on Mondays")));
        Assert.IsTrue(JobQueueEntry."Run on Wednesdays", StrSubstNo(FieldNotSyncedErr, 'Run on Wednesdays', 'true', Format(JobQueueEntry."Run on Wednesdays")));
        Assert.IsTrue(JobQueueEntry."Run on Fridays", StrSubstNo(FieldNotSyncedErr, 'Run on Fridays', 'true', Format(JobQueueEntry."Run on Fridays")));

        // [THEN] Verify other weekdays remain false
        Assert.IsFalse(JobQueueEntry."Run on Tuesdays", StrSubstNo(FieldNotSyncedErr, 'Run on Tuesdays', 'false', Format(JobQueueEntry."Run on Tuesdays")));
        Assert.IsFalse(JobQueueEntry."Run on Thursdays", StrSubstNo(FieldNotSyncedErr, 'Run on Thursdays', 'false', Format(JobQueueEntry."Run on Thursdays")));
        Assert.IsFalse(JobQueueEntry."Run on Saturdays", StrSubstNo(FieldNotSyncedErr, 'Run on Saturdays', 'false', Format(JobQueueEntry."Run on Saturdays")));
        Assert.IsFalse(JobQueueEntry."Run on Sundays", StrSubstNo(FieldNotSyncedErr, 'Run on Sundays', 'false', Format(JobQueueEntry."Run on Sundays")));
    end;

    [Test]
    procedure ModifyStartingEndingTime_VerifyValidationAndSync()
    var
        OrchestratorEntry: Record "Scheduled Entry ori";
        JobQueueEntry: Record "Job Queue Entry";
        InvalidTimeRangeErr: Label 'Ending Time must be greater than Starting Time.';
        FieldNotSyncedErr: Label 'Field %1 not synced to Job Queue Entry. Expected: %2, Actual: %3', Comment = '%1 = Field name, %2 = Expected value, %3 = Actual value';
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER] [TIME RANGE VALIDATION]
        // [SCENARIO] Modify Starting/Ending Time - verify validation and sync to Job Queue Entry

        // [GIVEN] A Job Queue Scheduler Entry with created Job Queue Entry
        OrchestratorEntry.Init();
        OrchestratorEntry.ID := CreateGuid();
        OrchestratorEntry."Object Type to Run" := OrchestratorEntry."Object Type to Run"::Codeunit;
        OrchestratorEntry."Object ID to Run" := Codeunit::"Scheduler Handler ori";
        OrchestratorEntry."Run on Mondays" := true;
        OrchestratorEntry."Starting Time" := 080000T; // 08:00:00
        OrchestratorEntry."Ending Time" := 170000T; // 17:00:00
        OrchestratorEntry.Insert();

        // [GIVEN] Create corresponding Job Queue Entry
        JobQueueEntry.Init();
        JobQueueEntry.ID := OrchestratorEntry.ID;
        JobQueueEntry."Object Type to Run" := OrchestratorEntry."Object Type to Run";
        JobQueueEntry."Object ID to Run" := OrchestratorEntry."Object ID to Run";
        JobQueueEntry."Starting Time" := 080000T;
        JobQueueEntry."Ending Time" := 170000T;
        JobQueueEntry.Insert();

        Commit();

        // [WHEN] Try to set Ending Time earlier than Starting Time
        asserterror OrchestratorEntry.Validate("Ending Time", 070000T); // 07:00:00 (earlier than starting time)

        // [THEN] Validation error should be raised
        Assert.ExpectedError(InvalidTimeRangeErr);

        // [WHEN] Update Starting Time to 06:00:00
        OrchestratorEntry.Validate("Starting Time", 060000T);
        OrchestratorEntry.Modify();

        // [THEN] Verify Starting Time is synced to Job Queue Entry
        JobQueueEntry.Get(OrchestratorEntry.ID);
        Assert.AreEqual(060000T, JobQueueEntry."Starting Time", StrSubstNo(FieldNotSyncedErr, 'Starting Time', '06:00:00', Format(JobQueueEntry."Starting Time")));

        // [WHEN] Update Ending Time to 18:00:00
        OrchestratorEntry.Validate("Ending Time", 180000T);
        OrchestratorEntry.Modify();

        // [THEN] Verify Ending Time is synced to Job Queue Entry
        JobQueueEntry.Get(OrchestratorEntry.ID);
        Assert.AreEqual(180000T, JobQueueEntry."Ending Time", StrSubstNo(FieldNotSyncedErr, 'Ending Time', '18:00:00', Format(JobQueueEntry."Ending Time")));

        // [WHEN] Validate valid time range (Starting < Ending)
        OrchestratorEntry.Validate("Starting Time", 090000T); // 09:00:00
        OrchestratorEntry.Validate("Ending Time", 170000T); // 17:00:00
        OrchestratorEntry.Modify();

        // [THEN] Both times should be updated successfully and synced
        JobQueueEntry.Get(OrchestratorEntry.ID);
        Assert.AreEqual(090000T, JobQueueEntry."Starting Time", StrSubstNo(FieldNotSyncedErr, 'Starting Time', '09:00:00', Format(JobQueueEntry."Starting Time")));
        Assert.AreEqual(170000T, JobQueueEntry."Ending Time", StrSubstNo(FieldNotSyncedErr, 'Ending Time', '17:00:00', Format(JobQueueEntry."Ending Time")));
    end;

    [Test]
    procedure CreateSchedulerEntryFromJobQueueEntry_VerifyRecurringFieldsCopy()
    var
        JobQueueEntry: Record "Job Queue Entry";
        OrchestratorEntry: Record "Scheduled Entry ori";
        UserPersonalization: Record "User Personalization";
        TimeZone: Record "Time Zone";
        ExpectedTimeZoneNo: Integer;
        FieldMismatchErr: Label 'Field %1 not correctly copied from Job Queue Entry. Expected: %2, Actual: %3', Comment = '%1 = Field name, %2 = Expected value, %3 = Actual value';
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER] [JOB QUEUE ENTRY COPY]
        // [SCENARIO] Create scheduler entry from existing Job Queue Entry - verify recurring fields copy and Time Zone Nr. from User Personalization

        // [GIVEN] A Job Queue Entry with all recurring fields populated
        JobQueueEntry.Init();
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Report;
        JobQueueEntry."Object ID to Run" := 1;
        JobQueueEntry.Description := 'Test Job Queue Entry';
        JobQueueEntry."Earliest Start Date/Time" := CurrentDateTime();
        JobQueueEntry."Job Queue Category Code" := 'DEFAULT';
        JobQueueEntry."No. of Minutes between Runs" := 240;
        JobQueueEntry."Run on Mondays" := true;
        JobQueueEntry."Run on Tuesdays" := false;
        JobQueueEntry."Run on Wednesdays" := true;
        JobQueueEntry."Run on Thursdays" := false;
        JobQueueEntry."Run on Fridays" := true;
        JobQueueEntry."Run on Saturdays" := false;
        JobQueueEntry."Run on Sundays" := true;
        JobQueueEntry."Starting Time" := 080000T; // 08:00:00
        JobQueueEntry."Ending Time" := 170000T; // 17:00:00
        Evaluate(JobQueueEntry."Next Run Date Formula", '<+1W>');
        JobQueueEntry.Insert();

        // [WHEN] Copy Job Queue Entry to Scheduler Entry
        OrchestratorEntry.CopyJobQueueEntryToOrchestratorEntry(JobQueueEntry);

        // [THEN] Verify all recurring fields are copied from Job Queue Entry
        Assert.AreEqual(JobQueueEntry.ID, OrchestratorEntry.ID, StrSubstNo(FieldMismatchErr, 'ID', JobQueueEntry.ID, OrchestratorEntry.ID));
        Assert.AreEqual(JobQueueEntry."Object Type to Run", OrchestratorEntry."Object Type to Run", StrSubstNo(FieldMismatchErr, 'Object Type to Run', Format(JobQueueEntry."Object Type to Run"), Format(OrchestratorEntry."Object Type to Run")));
        Assert.AreEqual(JobQueueEntry."Object ID to Run", OrchestratorEntry."Object ID to Run", StrSubstNo(FieldMismatchErr, 'Object ID to Run', Format(JobQueueEntry."Object ID to Run"), Format(OrchestratorEntry."Object ID to Run")));
        Assert.AreEqual(JobQueueEntry.Description, OrchestratorEntry.Description, StrSubstNo(FieldMismatchErr, 'Description', JobQueueEntry.Description, OrchestratorEntry.Description));
        Assert.AreEqual(JobQueueEntry."Job Queue Category Code", OrchestratorEntry."Job Queue Category Code", StrSubstNo(FieldMismatchErr, 'Job Queue Category Code', JobQueueEntry."Job Queue Category Code", OrchestratorEntry."Job Queue Category Code"));
        Assert.AreEqual(JobQueueEntry."No. of Minutes between Runs", OrchestratorEntry."No. of Minutes between Runs", StrSubstNo(FieldMismatchErr, 'No. of Minutes between Runs', Format(JobQueueEntry."No. of Minutes between Runs"), Format(OrchestratorEntry."No. of Minutes between Runs")));

        // [THEN] Verify all weekday fields are copied
        Assert.AreEqual(JobQueueEntry."Run on Mondays", OrchestratorEntry."Run on Mondays", StrSubstNo(FieldMismatchErr, 'Run on Mondays', Format(JobQueueEntry."Run on Mondays"), Format(OrchestratorEntry."Run on Mondays")));
        Assert.AreEqual(JobQueueEntry."Run on Tuesdays", OrchestratorEntry."Run on Tuesdays", StrSubstNo(FieldMismatchErr, 'Run on Tuesdays', Format(JobQueueEntry."Run on Tuesdays"), Format(OrchestratorEntry."Run on Tuesdays")));
        Assert.AreEqual(JobQueueEntry."Run on Wednesdays", OrchestratorEntry."Run on Wednesdays", StrSubstNo(FieldMismatchErr, 'Run on Wednesdays', Format(JobQueueEntry."Run on Wednesdays"), Format(OrchestratorEntry."Run on Wednesdays")));
        Assert.AreEqual(JobQueueEntry."Run on Thursdays", OrchestratorEntry."Run on Thursdays", StrSubstNo(FieldMismatchErr, 'Run on Thursdays', Format(JobQueueEntry."Run on Thursdays"), Format(OrchestratorEntry."Run on Thursdays")));
        Assert.AreEqual(JobQueueEntry."Run on Fridays", OrchestratorEntry."Run on Fridays", StrSubstNo(FieldMismatchErr, 'Run on Fridays', Format(JobQueueEntry."Run on Fridays"), Format(OrchestratorEntry."Run on Fridays")));
        Assert.AreEqual(JobQueueEntry."Run on Saturdays", OrchestratorEntry."Run on Saturdays", StrSubstNo(FieldMismatchErr, 'Run on Saturdays', Format(JobQueueEntry."Run on Saturdays"), Format(OrchestratorEntry."Run on Saturdays")));
        Assert.AreEqual(JobQueueEntry."Run on Sundays", OrchestratorEntry."Run on Sundays", StrSubstNo(FieldMismatchErr, 'Run on Sundays', Format(JobQueueEntry."Run on Sundays"), Format(OrchestratorEntry."Run on Sundays")));

        // [THEN] Verify time range fields are copied
        Assert.AreEqual(JobQueueEntry."Starting Time", OrchestratorEntry."Starting Time", StrSubstNo(FieldMismatchErr, 'Starting Time', Format(JobQueueEntry."Starting Time"), Format(OrchestratorEntry."Starting Time")));
        Assert.AreEqual(JobQueueEntry."Ending Time", OrchestratorEntry."Ending Time", StrSubstNo(FieldMismatchErr, 'Ending Time', Format(JobQueueEntry."Ending Time"), Format(OrchestratorEntry."Ending Time")));

        // [THEN] Verify date formula is copied
        Assert.AreEqual(Format(JobQueueEntry."Next Run Date Formula"), Format(OrchestratorEntry."Next Run Date Formula"), StrSubstNo(FieldMismatchErr, 'Next Run Date Formula', Format(JobQueueEntry."Next Run Date Formula"), Format(OrchestratorEntry."Next Run Date Formula")));

        // [THEN] Verify Blocked is set to false
        Assert.IsFalse(OrchestratorEntry.Blocked, StrSubstNo(FieldMismatchErr, 'Blocked', 'false', Format(OrchestratorEntry.Blocked)));

        // [THEN] Verify Time Zone Nr. is set from User Personalization
        if UserPersonalization.Get(UserSecurityId()) then begin
            TimeZone.SetRange(ID, UserPersonalization."Time Zone");
            if TimeZone.FindFirst() then
                ExpectedTimeZoneNo := TimeZone."No.";
        end;
        Assert.AreEqual(ExpectedTimeZoneNo, OrchestratorEntry."Time Zone Nr.", StrSubstNo(FieldMismatchErr, 'Time Zone Nr.', Format(ExpectedTimeZoneNo), Format(OrchestratorEntry."Time Zone Nr.")));
    end;

    [Test]
    procedure ChangingTemplate_VerifyExistingValuesOverwritten()
    var
        RecurringTemplate1: Record "Recurring Template ori";
        RecurringTemplate2: Record "Recurring Template ori";
        OrchestratorEntry: Record "Scheduled Entry ori";
        FieldValueErr: Label 'Field %1 not correctly updated when template changed. Expected: %2, Actual: %3', Comment = '%1 = Field name, %2 = Expected value, %3 = Actual value';
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER] [RECURRING TEMPLATE]
        // [SCENARIO] Verify that changing template overwrites existing values

        // [GIVEN] Two Recurring Templates with different configurations
        RecurringTemplate1.Init();
        RecurringTemplate1.Code := 'TEMPLATE_A';
        RecurringTemplate1.Description := 'Template A';
        RecurringTemplate1."Time Zone Nr." := 23;
        RecurringTemplate1."Run on Mondays" := true;
        RecurringTemplate1."Run on Tuesdays" := true;
        RecurringTemplate1."Run on Wednesdays" := false;
        RecurringTemplate1."Run on Thursdays" := false;
        RecurringTemplate1."Run on Fridays" := false;
        RecurringTemplate1."Run on Saturdays" := false;
        RecurringTemplate1."Run on Sundays" := false;
        RecurringTemplate1."Starting Time" := 080000T; // 08:00:00
        RecurringTemplate1."Ending Time" := 170000T; // 17:00:00
        RecurringTemplate1."No. of Minutes between Runs" := 120;
        RecurringTemplate1.Insert();

        RecurringTemplate2.Init();
        RecurringTemplate2.Code := 'TEMPLATE_B';
        RecurringTemplate2.Description := 'Template B';
        RecurringTemplate2."Time Zone Nr." := 24;
        RecurringTemplate2."Run on Mondays" := false;
        RecurringTemplate2."Run on Tuesdays" := false;
        RecurringTemplate2."Run on Wednesdays" := true;
        RecurringTemplate2."Run on Thursdays" := true;
        RecurringTemplate2."Run on Fridays" := true;
        RecurringTemplate2."Run on Saturdays" := true;
        RecurringTemplate2."Run on Sundays" := false;
        RecurringTemplate2."Starting Time" := 060000T; // 06:00:00
        RecurringTemplate2."Ending Time" := 180000T; // 18:00:00
        RecurringTemplate2."No. of Minutes between Runs" := 240;
        RecurringTemplate2.Insert();

        // [GIVEN] A Job Queue Scheduler Entry with Template A selected
        OrchestratorEntry.Init();
        OrchestratorEntry.ID := CreateGuid();
        OrchestratorEntry."Object Type to Run" := OrchestratorEntry."Object Type to Run"::Report;
        OrchestratorEntry."Object ID to Run" := 1;
        OrchestratorEntry.Insert();

        OrchestratorEntry.Validate("Recurring Template Code", 'TEMPLATE_A');
        OrchestratorEntry.Modify();

        // [WHEN] Change to Template B
        OrchestratorEntry.Validate("Recurring Template Code", 'TEMPLATE_B');
        OrchestratorEntry.Modify();

        // [THEN] Verify all fields are overwritten with Template B values
        Assert.AreEqual(24, OrchestratorEntry."Time Zone Nr.", StrSubstNo(FieldValueErr, 'Time Zone Nr.', '24', OrchestratorEntry."Time Zone Nr."));
        Assert.IsFalse(OrchestratorEntry."Run on Mondays", StrSubstNo(FieldValueErr, 'Run on Mondays', 'false', Format(OrchestratorEntry."Run on Mondays")));
        Assert.IsFalse(OrchestratorEntry."Run on Tuesdays", StrSubstNo(FieldValueErr, 'Run on Tuesdays', 'false', Format(OrchestratorEntry."Run on Tuesdays")));
        Assert.IsTrue(OrchestratorEntry."Run on Wednesdays", StrSubstNo(FieldValueErr, 'Run on Wednesdays', 'true', Format(OrchestratorEntry."Run on Wednesdays")));
        Assert.IsTrue(OrchestratorEntry."Run on Thursdays", StrSubstNo(FieldValueErr, 'Run on Thursdays', 'true', Format(OrchestratorEntry."Run on Thursdays")));
        Assert.IsTrue(OrchestratorEntry."Run on Fridays", StrSubstNo(FieldValueErr, 'Run on Fridays', 'true', Format(OrchestratorEntry."Run on Fridays")));
        Assert.IsTrue(OrchestratorEntry."Run on Saturdays", StrSubstNo(FieldValueErr, 'Run on Saturdays', 'true', Format(OrchestratorEntry."Run on Saturdays")));
        Assert.IsFalse(OrchestratorEntry."Run on Sundays", StrSubstNo(FieldValueErr, 'Run on Sundays', 'false', Format(OrchestratorEntry."Run on Sundays")));
        Assert.AreEqual(060000T, OrchestratorEntry."Starting Time", StrSubstNo(FieldValueErr, 'Starting Time', '06:00:00', Format(OrchestratorEntry."Starting Time")));
        Assert.AreEqual(180000T, OrchestratorEntry."Ending Time", StrSubstNo(FieldValueErr, 'Ending Time', '18:00:00', Format(OrchestratorEntry."Ending Time")));
        Assert.AreEqual(240, OrchestratorEntry."No. of Minutes between Runs", StrSubstNo(FieldValueErr, 'No. of Minutes between Runs', '240', Format(OrchestratorEntry."No. of Minutes between Runs")));
    end;

    [Test]
    procedure TimeZoneCode_VerifyStored()
    var
        OrchestratorEntry: Record "Scheduled Entry ori";
        TimeZoneNotStoredErr: Label 'Time Zone Nr. not stored on Scheduler Entry. Expected: %1, Actual: %2.', Comment = '%1 = Expected value, %2 = Actual value';
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER] [TIME ZONE NR.]
        // [SCENARIO] Verify Time Zone Nr. is stored on Scheduler Entry but NOT synced to Job Queue Entry

        // [GIVEN] A Job Queue Scheduler Entry with a Time Zone Nr.
        OrchestratorEntry.Init();
        OrchestratorEntry.ID := CreateGuid();
        OrchestratorEntry."Object Type to Run" := OrchestratorEntry."Object Type to Run"::Codeunit;
        OrchestratorEntry."Object ID to Run" := Codeunit::"Scheduler Handler ori";
        OrchestratorEntry."Time Zone Nr." := 23;
        OrchestratorEntry."Run on Mondays" := true;
        OrchestratorEntry.Insert();

        // [THEN] Verify Time Zone Nr. is stored on Scheduler Entry
        OrchestratorEntry.Get(OrchestratorEntry.ID);
        Assert.AreEqual(23, OrchestratorEntry."Time Zone Nr.", StrSubstNo(TimeZoneNotStoredErr, '23', OrchestratorEntry."Time Zone Nr."));

        // [WHEN] Modify Time Zone Nr. on Scheduler Entry
        OrchestratorEntry.Validate("Time Zone Nr.", 24);
        OrchestratorEntry.Modify();

        // [THEN] Verify new Time Zone Nr. is stored on Scheduler Entry
        OrchestratorEntry.Get(OrchestratorEntry.ID);
        Assert.AreEqual(24, OrchestratorEntry."Time Zone Nr.", StrSubstNo(TimeZoneNotStoredErr, '24', OrchestratorEntry."Time Zone Nr."));
    end;

    // ═══════════════════════════════════════════════════════════════════
    // CalcNextRunTimeForRecurringSchedule tests
    // ═══════════════════════════════════════════════════════════════════

    [Test]
    procedure CalcNextRunTime_NextRunDateFormula_CalculatesCorrectDate()
    var
        OrchestratorEntry: Record "Scheduled Entry ori";
        ScheduleCalc: Codeunit "Schedule Calc ori";
        StartingDateTime: DateTime;
        LastExecutionDateTime: DateTime;
        ResultDateTime: DateTime;
        ExpectedDate: Date;
        WrongDateErr: Label 'Expected date %1 but got %2', Locked = true;
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER] [SCHEDULE CALC]
        // [SCENARIO] CalcNextRunTime with Next Run Date Formula set calculates the correct next date

        // [GIVEN] A scheduler entry with Next Run Date Formula = <+1W> (weekly) and Starting Time 08:00
        OrchestratorEntry.Init();
        OrchestratorEntry.ID := CreateGuid();
        OrchestratorEntry."Starting Time" := 080000T;
        Evaluate(OrchestratorEntry."Next Run Date Formula", '<+1W>');

        // [GIVEN] Starting DateTime is CurrentDateTime
        StartingDateTime := CurrentDateTime;
        LastExecutionDateTime := 0DT;

        // [WHEN] CalcNextRunTimeForRecurringSchedule is called
        ResultDateTime := ScheduleCalc.CalcNextRunTimeForRecurringSchedule(OrchestratorEntry, LastExecutionDateTime, StartingDateTime);

        // [THEN] Result date should be starting date
        ExpectedDate := DT2Date(StartingDateTime);
        Assert.AreEqual(
            CreateDateTime(ExpectedDate, 080000T),
            ResultDateTime,
            StrSubstNo(WrongDateErr, CreateDateTime(ExpectedDate, 080000T), ResultDateTime));

        // [GIVEN] LastExecutionDateTime is ResultDateTime from the previous run
        LastExecutionDateTime := ResultDateTime;

        // [WHEN] CalcNextRunTimeForRecurringSchedule is called
        ResultDateTime := ScheduleCalc.CalcNextRunTimeForRecurringSchedule(OrchestratorEntry, LastExecutionDateTime, StartingDateTime);

        // [THEN] Result date should be starting date + 1 week
        if DT2Time(StartingDateTime) >= 080000T then
            ExpectedDate := CalcDate('<+1W>', DT2Date(StartingDateTime))
        else
            ExpectedDate := DT2Date(StartingDateTime);

        Assert.AreEqual(
            CreateDateTime(ExpectedDate, 080000T),
            ResultDateTime,
            StrSubstNo(WrongDateErr, CreateDateTime(ExpectedDate, 080000T), ResultDateTime));
    end;

    [Test]
    procedure CalcNextRunTime_NextRunDateFormula_InvalidFormulaRaisesError()
    var
        OrchestratorEntry: Record "Scheduled Entry ori";
        ScheduleCalc: Codeunit "Schedule Calc ori";
        StartingDateTime: DateTime;
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER] [SCHEDULE CALC]
        // [SCENARIO] CalcNextRunTime with a backward date formula raises an error

        // [GIVEN] A scheduler entry with Next Run Date Formula = <-1W> (goes backward)
        OrchestratorEntry.Init();
        OrchestratorEntry.ID := CreateGuid();
        Evaluate(OrchestratorEntry."Next Run Date Formula", '<-1W>');

        StartingDateTime := CurrentDateTime + (2 * 24 * 60 * 60 * 1000);

        // [WHEN] CalcNextRunTimeForRecurringSchedule is called
        asserterror ScheduleCalc.CalcNextRunTimeForRecurringSchedule(OrchestratorEntry, 0DT, StartingDateTime);

        // [THEN] An error is raised about invalid formula
        Assert.ExpectedError('is invalid');
    end;

    [Test]
    procedure CalcNextRunTime_WeekdaysSelected_SchedulesOnCorrectDay()
    var
        OrchestratorEntry: Record "Scheduled Entry ori";
        ScheduleCalc: Codeunit "Schedule Calc ori";
        StartingDateTime: DateTime;
        ResultDateTime: DateTime;
        ResultWeekDay: Integer;
        WrongWeekdayErr: Label 'Expected weekday Mon(1), Wed(3), or Fri(5) but got %1', Locked = true;
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER] [SCHEDULE CALC]
        // [SCENARIO] CalcNextRunTime with weekdays selected schedules on the correct day

        // [GIVEN] A scheduler entry that runs Mon/Wed/Fri with 60 min intervals, 08:00-17:00
        OrchestratorEntry.Init();
        OrchestratorEntry.ID := CreateGuid();
        OrchestratorEntry."Run on Mondays" := true;
        OrchestratorEntry."Run on Tuesdays" := false;
        OrchestratorEntry."Run on Wednesdays" := true;
        OrchestratorEntry."Run on Thursdays" := false;
        OrchestratorEntry."Run on Fridays" := true;
        OrchestratorEntry."Run on Saturdays" := false;
        OrchestratorEntry."Run on Sundays" := false;
        OrchestratorEntry."Starting Time" := 080000T;
        OrchestratorEntry."Ending Time" := 170000T;
        OrchestratorEntry."No. of Minutes between Runs" := 60;

        // [GIVEN] Starting DateTime is now, last execution was now
        StartingDateTime := CurrentDateTime;

        // [WHEN] CalcNextRunTimeForRecurringSchedule is called
        ResultDateTime := ScheduleCalc.CalcNextRunTimeForRecurringSchedule(OrchestratorEntry, CurrentDateTime, StartingDateTime);

        // [THEN] Result falls on Monday (1), Wednesday (3), or Friday (5)
        ResultWeekDay := Date2DWY(DT2Date(ResultDateTime), 1);
        Assert.IsTrue(
            ResultWeekDay in [1, 3, 5],
            StrSubstNo(WrongWeekdayErr, ResultWeekDay));
    end;

    [Test]
    procedure CalcNextRunTime_OutsideTimeWindow_SchedulesNextValidTime()
    var
        OrchestratorEntry: Record "Scheduled Entry ori";
        ScheduleCalc: Codeunit "Schedule Calc ori";
        StartingDateTime: DateTime;
        LastExecutionDateTime: DateTime;
        ResultDateTime: DateTime;
        TooEarlyErr: Label 'Result time %1 is before Starting Time %2', Locked = true;
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER] [SCHEDULE CALC]
        // [SCENARIO] Run due now but outside time window should schedule for next valid time

        // [GIVEN] A scheduler entry that runs daily 09:00-17:00 every 60 min
        OrchestratorEntry.Init();
        OrchestratorEntry.ID := CreateGuid();
        OrchestratorEntry."Run on Mondays" := true;
        OrchestratorEntry."Run on Tuesdays" := true;
        OrchestratorEntry."Run on Wednesdays" := true;
        OrchestratorEntry."Run on Thursdays" := true;
        OrchestratorEntry."Run on Fridays" := true;
        OrchestratorEntry."Run on Saturdays" := true;
        OrchestratorEntry."Run on Sundays" := true;
        OrchestratorEntry."Starting Time" := 090000T;
        OrchestratorEntry."Ending Time" := 170000T;
        OrchestratorEntry."No. of Minutes between Runs" := 60;

        // [GIVEN] Starting DateTime is early morning (before the time window)
        StartingDateTime := CreateDateTime(DT2Date(CurrentDateTime), 050000T);
        LastExecutionDateTime := 0DT;

        // [WHEN] CalcNextRunTimeForRecurringSchedule is called
        ResultDateTime := ScheduleCalc.CalcNextRunTimeForRecurringSchedule(OrchestratorEntry, LastExecutionDateTime, StartingDateTime);

        // [THEN] Result time should be at or after the Starting Time (09:00)
        Assert.IsTrue(
            DT2Time(ResultDateTime) >= 090000T,
            StrSubstNo(TooEarlyErr, DT2Time(ResultDateTime), 090000T));
    end;

    [Test]
    procedure CalcNextRunTime_FridayWithWeekendExcluded_SchedulesMonday()
    var
        OrchestratorEntry: Record "Scheduled Entry ori";
        ScheduleCalc: Codeunit "Schedule Calc ori";
        FridayDate: Date;
        StartingDateTime: DateTime;
        LastExecutionDateTime: DateTime;
        ResultDateTime: DateTime;
        NotMondayErr: Label 'Expected Monday (weekday 1) but got weekday %1, date %2', Locked = true;
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER] [SCHEDULE CALC]
        // [SCENARIO] Run on Friday with time window, next run should be Monday if weekend excluded

        // [GIVEN] A scheduler entry for weekdays only (Mon-Fri), 08:00-17:00
        OrchestratorEntry.Init();
        OrchestratorEntry.ID := CreateGuid();
        OrchestratorEntry."Run on Mondays" := true;
        OrchestratorEntry."Run on Tuesdays" := true;
        OrchestratorEntry."Run on Wednesdays" := true;
        OrchestratorEntry."Run on Thursdays" := true;
        OrchestratorEntry."Run on Fridays" := true;
        OrchestratorEntry."Run on Saturdays" := false;
        OrchestratorEntry."Run on Sundays" := false;
        OrchestratorEntry."Starting Time" := 080000T;
        OrchestratorEntry."Ending Time" := 170000T;
        OrchestratorEntry."No. of Minutes between Runs" := 60;

        // [GIVEN] Find the next Friday from today
        FridayDate := DT2Date(CurrentDateTime);
        while Date2DWY(FridayDate, 1) <> 5 do
            FridayDate := FridayDate + 1;

        // [GIVEN] Starting DateTime is Friday at 16:30 (near end of window), last execution at 16:00
        StartingDateTime := CreateDateTime(FridayDate, 163000T);
        LastExecutionDateTime := CreateDateTime(FridayDate, 160000T);

        // [WHEN] CalcNextRunTimeForRecurringSchedule is called
        ResultDateTime := ScheduleCalc.CalcNextRunTimeForRecurringSchedule(OrchestratorEntry, LastExecutionDateTime, StartingDateTime);

        // [THEN] Result date should be Monday (weekday = 1) at Starting Time
        if DT2Date(ResultDateTime) > FridayDate then
            Assert.AreEqual(1, Date2DWY(DT2Date(ResultDateTime), 1),
                StrSubstNo(NotMondayErr, Date2DWY(DT2Date(ResultDateTime), 1), DT2Date(ResultDateTime)));
    end;

    [Test]
    procedure CalcNextRunTime_LastExecYesterday_CalculatesCorrectNextRun()
    var
        OrchestratorEntry: Record "Scheduled Entry ori";
        ScheduleCalc: Codeunit "Schedule Calc ori";
        Yesterday: Date;
        StartingDateTime: DateTime;
        LastExecutionDateTime: DateTime;
        ResultDateTime: DateTime;
        ResultInPastErr: Label 'Result %1 should not be before current time %2', Locked = true;
        ResultBeforeLastExecErr: Label 'Result %1 should be after last execution %2', Locked = true;
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER] [SCHEDULE CALC]
        // [SCENARIO] Last execution was yesterday, should calculate correct next run

        // [GIVEN] A scheduler entry running every day, every 60 min, 08:00-17:00
        OrchestratorEntry.Init();
        OrchestratorEntry.ID := CreateGuid();
        OrchestratorEntry."Run on Mondays" := true;
        OrchestratorEntry."Run on Tuesdays" := true;
        OrchestratorEntry."Run on Wednesdays" := true;
        OrchestratorEntry."Run on Thursdays" := true;
        OrchestratorEntry."Run on Fridays" := true;
        OrchestratorEntry."Run on Saturdays" := true;
        OrchestratorEntry."Run on Sundays" := true;
        OrchestratorEntry."Starting Time" := 080000T;
        OrchestratorEntry."Ending Time" := 170000T;
        OrchestratorEntry."No. of Minutes between Runs" := 60;

        // [GIVEN] Last execution was yesterday at 17:00, starting from yesterday at 08:00
        Yesterday := DT2Date(CurrentDateTime) - 1;
        LastExecutionDateTime := CreateDateTime(Yesterday, 170000T);
        StartingDateTime := CreateDateTime(Yesterday, 080000T);

        // [WHEN] CalcNextRunTimeForRecurringSchedule is called
        ResultDateTime := ScheduleCalc.CalcNextRunTimeForRecurringSchedule(OrchestratorEntry, LastExecutionDateTime, StartingDateTime);

        // [THEN] Result should be after last execution
        Assert.IsTrue(
            ResultDateTime > LastExecutionDateTime,
            StrSubstNo(ResultBeforeLastExecErr, ResultDateTime, LastExecutionDateTime));

        // [THEN] Result should be today or later (not in the past)
        Assert.IsTrue(
            DT2Date(ResultDateTime) >= DT2Date(CurrentDateTime),
            StrSubstNo(ResultInPastErr, ResultDateTime, CurrentDateTime));
    end;

    [Test]
    procedure CalcNextRunTime_NextRunDateFormula_WithLastExec_AdvancesCorrectly()
    var
        OrchestratorEntry: Record "Scheduled Entry ori";
        ScheduleCalc: Codeunit "Schedule Calc ori";
        StartDate: Date;
        StartingDateTime: DateTime;
        LastExecutionDateTime: DateTime;
        ResultDateTime: DateTime;
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER] [SCHEDULE CALC]
        // [SCENARIO] Next Run Date Formula with a past last execution advances past CurrentDateTime

        // [GIVEN] A scheduler entry with monthly formula and Starting Time 06:00
        OrchestratorEntry.Init();
        OrchestratorEntry.ID := CreateGuid();
        OrchestratorEntry."Starting Time" := 060000T;
        Evaluate(OrchestratorEntry."Next Run Date Formula", '<+1M>');

        // [GIVEN] Starting DateTime 3 months ago, last execution 2 months ago
        StartDate := CalcDate('<-3M>', DT2Date(CurrentDateTime));
        StartingDateTime := CreateDateTime(StartDate, 060000T);
        LastExecutionDateTime := CreateDateTime(CalcDate('<-2M>', DT2Date(CurrentDateTime)), 060000T);

        // [WHEN] CalcNextRunTimeForRecurringSchedule is called
        ResultDateTime := ScheduleCalc.CalcNextRunTimeForRecurringSchedule(OrchestratorEntry, LastExecutionDateTime, StartingDateTime);

        // [THEN] Result time should be at Starting Time
        Assert.AreEqual(060000T, DT2Time(ResultDateTime), 'Result time should be at Starting Time 06:00');
    end;

    // ═══════════════════════════════════════════════════════════════════
    // Retry Policy tests
    // ═══════════════════════════════════════════════════════════════════

    [Test]
    procedure RetryPolicyAlways_ErrorEntry_AlwaysRestartsAndIncrementsCounter()
    var
        OrchestratorEntry: Record "Scheduled Entry ori";
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueSchedulerHandler: Codeunit "Scheduler Handler ori";
        LibraryJobQueue: Codeunit "Library Orchestrator";
        i: Integer;
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER] [RETRY POLICY]
        // [SCENARIO] Retry Policy = Always restarts the entry on every error regardless of error count

        // [GIVEN] A Job Queue Scheduler Entry with Retry Policy = Always and error count = 0
        CreateRetryPolicyTestEntry(OrchestratorEntry, OrchestratorEntry."Retry Policy"::Always, 0);
        CreateErrorJobQueueEntry(JobQueueEntry, OrchestratorEntry);

        // [WHEN] ScheduleTask is called 5 consecutive times (simulating repeated failures)
        BindSubscription(LibraryJobQueue);
        for i := 1 to 5 do
            SimulateErrorAndSchedule(JobQueueSchedulerHandler, OrchestratorEntry, JobQueueEntry, i);
        UnBindSubscription(LibraryJobQueue);

        // [THEN] Error counter should be 5 (incremented every time, never suppressed)
        Assert.AreEqual(5, OrchestratorEntry."Errors Since Last Success", 'Always policy should restart every time; counter should equal number of errors.');
    end;

    [Test]
    procedure RetryPolicyThreeTimes_ThirdRestartAllowed_FourthSuppressed()
    var
        OrchestratorEntry: Record "Scheduled Entry ori";
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueSchedulerHandler: Codeunit "Scheduler Handler ori";
        LibraryJobQueue: Codeunit "Library Orchestrator";
        i: Integer;
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER] [RETRY POLICY]
        // [SCENARIO] Retry Policy = Three Times allows 3 restarts then suppresses the 4th

        // [GIVEN] A Job Queue Scheduler Entry with Retry Policy = Three Times and error count = 0
        CreateRetryPolicyTestEntry(OrchestratorEntry, OrchestratorEntry."Retry Policy"::"Three Times", 0);
        CreateErrorJobQueueEntry(JobQueueEntry, OrchestratorEntry);

        BindSubscription(LibraryJobQueue);

        // [WHEN] ScheduleTask is called 3 times (first 3 errors)
        for i := 1 to 3 do
            SimulateErrorAndSchedule(JobQueueSchedulerHandler, OrchestratorEntry, JobQueueEntry, i);

        // [THEN] Counter should be 3 after 3 restarts
        Assert.AreEqual(3, OrchestratorEntry."Errors Since Last Success", 'Counter should be 3 after 3 restarts.');

        // [WHEN] 4th error occurs — ScheduleTask is called again
        SimulateErrorAndSchedule(JobQueueSchedulerHandler, OrchestratorEntry, JobQueueEntry, 4);

        UnBindSubscription(LibraryJobQueue);

        // [THEN] Counter should still be 3 (restart was suppressed, counter not incremented)
        Assert.AreEqual(3, OrchestratorEntry."Errors Since Last Success", '4th restart should be suppressed; counter should remain 3.');
    end;

    [Test]
    procedure RetryPolicyNever_ErrorEntry_SuppressesImmediately()
    var
        OrchestratorEntry: Record "Scheduled Entry ori";
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueSchedulerHandler: Codeunit "Scheduler Handler ori";
        LibraryJobQueue: Codeunit "Library Orchestrator";
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER] [RETRY POLICY]
        // [SCENARIO] Retry Policy = Never suppresses restart immediately on first error

        // [GIVEN] A Job Queue Scheduler Entry with Retry Policy = Never and error count = 0
        CreateRetryPolicyTestEntry(OrchestratorEntry, OrchestratorEntry."Retry Policy"::Never, 0);
        CreateErrorJobQueueEntry(JobQueueEntry, OrchestratorEntry);

        // [WHEN] ScheduleTask is called on the error entry
        BindSubscription(LibraryJobQueue);
        JobQueueSchedulerHandler.ScheduleTask(OrchestratorEntry);
        UnBindSubscription(LibraryJobQueue);

        // [THEN] Counter should remain 0 (restart was suppressed, counter never incremented)
        OrchestratorEntry.Get(OrchestratorEntry.ID);
        Assert.AreEqual(0, OrchestratorEntry."Errors Since Last Success", 'Never policy should suppress immediately; counter should remain 0.');
    end;

    [Test]
    procedure RetryPolicy_ErrorCounterResetsOnSuccess()
    var
        OrchestratorEntry: Record "Scheduled Entry ori";
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        JobQueueSchedulerHandler: Codeunit "Scheduler Handler ori";
        LibraryJobQueue: Codeunit "Library Orchestrator";
    begin
        // [FEATURE] [JOB QUEUE SCHEDULER] [RETRY POLICY]
        // [SCENARIO] Error counter resets to 0 when the job succeeds after previous failures

        // [GIVEN] A Job Queue Scheduler Entry with Retry Policy = Always and 2 accumulated errors
        CreateRetryPolicyTestEntry(OrchestratorEntry, OrchestratorEntry."Retry Policy"::Always, 2);

        // [GIVEN] A Job Queue Entry that is now in Ready status (not Error, not On Hold)
        JobQueueEntry.Init();
        JobQueueEntry.ID := OrchestratorEntry.ID;
        JobQueueEntry."Object Type to Run" := OrchestratorEntry."Object Type to Run";
        JobQueueEntry."Object ID to Run" := OrchestratorEntry."Object ID to Run";
        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry.Insert();

        // [GIVEN] A Job Queue Log Entry with Status = Success for this entry
        JobQueueLogEntry.Init();
        JobQueueLogEntry.ID := OrchestratorEntry.ID;
        JobQueueLogEntry."Entry No." := 0;
        JobQueueLogEntry.Status := JobQueueLogEntry.Status::Success;
        JobQueueLogEntry.Insert();

        // [WHEN] ScheduleTask is called (entry is not Error/On Hold → hits ResetErrorCounterOnSuccess)
        BindSubscription(LibraryJobQueue);
        JobQueueSchedulerHandler.ScheduleTask(OrchestratorEntry);
        UnBindSubscription(LibraryJobQueue);

        // [THEN] Error counter should be reset to 0
        OrchestratorEntry.Get(OrchestratorEntry.ID);
        Assert.AreEqual(0, OrchestratorEntry."Errors Since Last Success", 'Counter should reset to 0 after a successful execution.');
    end;

    local procedure CreateRetryPolicyTestEntry(var OrchestratorEntry: Record "Scheduled Entry ori"; RetryPolicy: Enum "Retry Policy ori"; ErrorsSinceLastSuccess: Integer)
    begin
        OrchestratorEntry.Init();
        OrchestratorEntry.ID := CreateGuid();
        OrchestratorEntry."Object Type to Run" := OrchestratorEntry."Object Type to Run"::Codeunit;
        OrchestratorEntry."Object ID to Run" := Codeunit::"Ok Sample";
        OrchestratorEntry."Retry Policy" := RetryPolicy;
        OrchestratorEntry."Errors Since Last Success" := ErrorsSinceLastSuccess;
        OrchestratorEntry."No. of Minutes between Runs" := 60;
        OrchestratorEntry."Run on Mondays" := true;
        OrchestratorEntry."Run on Tuesdays" := true;
        OrchestratorEntry."Run on Wednesdays" := true;
        OrchestratorEntry."Run on Thursdays" := true;
        OrchestratorEntry."Run on Fridays" := true;
        OrchestratorEntry.Insert();
    end;

    local procedure CreateErrorJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry"; OrchestratorEntry: Record "Scheduled Entry ori")
    begin
        JobQueueEntry.Init();
        JobQueueEntry.ID := OrchestratorEntry.ID;
        JobQueueEntry."Object Type to Run" := OrchestratorEntry."Object Type to Run";
        JobQueueEntry."Object ID to Run" := OrchestratorEntry."Object ID to Run";
        JobQueueEntry.Status := JobQueueEntry.Status::Error;
        JobQueueEntry."Error Message" := 'Test error';
        JobQueueEntry.Insert();
    end;

    local procedure SimulateErrorAndSchedule(var JobQueueSchedulerHandler: Codeunit "Scheduler Handler ori"; var OrchestratorEntry: Record "Scheduled Entry ori"; var JobQueueEntry: Record "Job Queue Entry"; ErrorNo: Integer)
    begin
        JobQueueEntry.Get(OrchestratorEntry.ID);
        JobQueueEntry.Status := JobQueueEntry.Status::Error;
        JobQueueEntry."Error Message" := 'Test error ' + Format(ErrorNo);
        JobQueueEntry.Modify();
        JobQueueSchedulerHandler.ScheduleTask(OrchestratorEntry);
        OrchestratorEntry.Get(OrchestratorEntry.ID);
    end;
}
