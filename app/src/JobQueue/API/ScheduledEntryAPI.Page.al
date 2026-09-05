namespace Origo.Bifrost.Nornir;

using System.Threading;

/// <summary>
/// API page exposing Job Queue Orchestrator Entries for external integrations.
/// </summary>
page 10035537 "Scheduled Entry API ori"
{
    APIGroup = 'jobQueueOrchestrator';
    APIPublisher = 'origo';
    APIVersion = 'v1.0';
    Caption = 'Job Queue Orchestrator Entries API', Comment = 'is-IS=Vinnsluraðarfærslur API';
    DelayedInsert = true;
    EntityCaption = 'Scheduled Entry', Comment = 'is-IS=Tímasett færsla';
    EntityName = 'scheduledEntry';
    EntitySetCaption = 'Scheduled Entries', Comment = 'is-IS=Tímasettar færslur';
    EntitySetName = 'scheduledEntries';
    Extensible = false;
    ODataKeyFields = ID;
    PageType = API;
    SourceTable = "Scheduled Entry ori";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(id; Rec.ID)
                {
                    Caption = 'ID', Comment = 'is-IS=Auðkenni';
                }
                field(objectTypeToRun; Rec."Object Type to Run")
                {
                    Caption = 'Object Type to Run', Comment = 'is-IS=Gerð hluts til keyrslu';
                }
                field(objectIDToRun; Rec."Object ID to Run")
                {
                    Caption = 'Object ID to Run', Comment = 'is-IS=Auðkenni hluts til keyrslu';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description', Comment = 'is-IS=Lýsing';
                }
                field(jobQueueCategoryCode; Rec."Job Queue Category Code")
                {
                    Caption = 'Job Queue Category Code', Comment = 'is-IS=Flokkunarkóði vinnsluraða';
                }
                field(noOfMinutesBetweenRuns; Rec."No. of Minutes between Runs")
                {
                    Caption = 'No. of Minutes between Runs', Comment = 'is-IS=Fjöldi mínúta milli keyrslu';
                }
                field(earliestStartDateTime; Rec."Earliest Start Date/Time")
                {
                    Caption = 'Earliest Start Date/Time', Comment = 'is-IS=Fyrsti tími til keyrslu';
                }
                field(blocked; Rec.Blocked)
                {
                    Caption = 'Blocked', Comment = 'is-IS=Lokað';
                }
                field(notificationType; Rec."Notification Type")
                {
                    Caption = 'Notification Type', Comment = 'is-IS=Gerð tilkynningar';
                }
                field(notificationRecipient; Rec."Notification Recipient")
                {
                    Caption = 'Notification Recipient', Comment = 'is-IS=Viðtakandi tilkynningar';
                }
                field(recordIDToProcess; Rec."Record ID to Process")
                {
                    Caption = 'Record ID to Process', Comment = 'is-IS=Auðkenni gagna til úrvinnslu';
                }
                field(relatedRecordSystemId; Rec."Related Record System Id")
                {
                    Caption = 'Related Record System Id', Comment = 'is-IS=Kerfisauðkenni tengdrar færslu';
                }
                field(scheduled; Rec.Scheduled)
                {
                    Caption = 'Scheduled', Comment = 'is-IS=Tímasett';
                    Editable = false;
                }
            }
        }
    }

    [ServiceEnabled]
    /// <summary>
    /// Deletes the associated Job Queue Entry and returns the updated orchestrator entry.
    /// </summary>
    /// <param name="ActionContext">The web service action context for the response.</param>
    procedure ScheduleJobQueueEntryUpdate(var ActionContext: WebServiceActionContext)
    var
        Exists: Boolean;
    begin
        Rec.TestField(Blocked, false);
        Exists := Rec.DeleteJobQueueEntry();

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Scheduled Entry API ori");
        ActionContext.AddEntityKey(Rec.FieldNo(ID), Rec.ID);
        if Exists then
            ActionContext.SetResultCode(WebServiceActionResultCode::Updated)
        else
            ActionContext.SetResultCode(WebServiceActionResultCode::Get);
    end;

    [ServiceEnabled]
    /// <summary>
    /// Deletes the existing Job Queue Entry and schedules a new one for this orchestrator entry.
    /// </summary>
    /// <param name="ActionContext">The web service action context for the response.</param>
    procedure UpdateJobQueueEntry(var ActionContext: WebServiceActionContext)
    var
        JobQueueHandler: Codeunit "Scheduler Handler ori";
        Exists: Boolean;
    begin
        Rec.TestField(Blocked, false);
        Exists := Rec.DeleteJobQueueEntry();
        JobQueueHandler.ScheduleTask(Rec);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Scheduled Entry API ori");
        ActionContext.AddEntityKey(Rec.FieldNo(ID), Rec.ID);
        if Exists then
            ActionContext.SetResultCode(WebServiceActionResultCode::Updated)
        else
            ActionContext.SetResultCode(WebServiceActionResultCode::Created);
    end;

    [ServiceEnabled]
    /// <summary>
    /// Restarts the linked Job Queue Entry for this orchestrator entry.
    /// </summary>
    /// <param name="ActionContext">The web service action context for the response.</param>
    procedure RestartJobQueueEntry(var ActionContext: WebServiceActionContext)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        Rec.TestField(Blocked, false);
        JobQueueEntry.Get(Rec.ID);
        JobQueueEntry.Restart();

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Scheduled Entry API ori");
        ActionContext.AddEntityKey(Rec.FieldNo(ID), Rec.ID);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    [ServiceEnabled]
    /// <summary>
    /// Sets the linked Job Queue Entry status to Ready for this orchestrator entry.
    /// </summary>
    /// <param name="ActionContext">The web service action context for the response.</param>
    procedure SetStatusToReady(var ActionContext: WebServiceActionContext)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        Rec.TestField(Blocked, false);
        JobQueueEntry.Get(Rec.ID);
        JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Scheduled Entry API ori");
        ActionContext.AddEntityKey(Rec.FieldNo(ID), Rec.ID);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}
