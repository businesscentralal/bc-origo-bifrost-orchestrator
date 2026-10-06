namespace Origo.Bifrost.Orchestrator;

using System.Threading;

/// <summary>
/// API page exposing Job Queue Entries with an action to add entries to the orchestrator.
/// </summary>
page 10035538 "Entries API ori"
{
    APIGroup = 'jobQueueOrchestrator';
    APIPublisher = 'origo';
    APIVersion = 'v1.0';
    Caption = 'Job Queue Entries API', Comment = 'is-IS=Vinnsluraðafærslur API';
    Editable = false;
    EntityCaption = 'Queue Entry', Comment = 'is-IS=Vinnsluraðafærsla';
    EntityName = 'queueEntry';
    EntitySetCaption = 'Queue Entries', Comment = 'is-IS=Vinnsluraðafærslur';
    EntitySetName = 'queueEntries';
    Extensible = false;
    ODataKeyFields = ID;
    PageType = API;
    SourceTable = "Job Queue Entry";

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
                    ToolTip = 'Specifies the type of the object, report or codeunit, that is to be run for the job queue entry. After you specify a type, you then select an object ID of that type in the Object ID to Run field.', Comment = 'is-IS=Tilgreinir gerð hluts til keyrslu.';
                }
                field(objectIDToRun; Rec."Object ID to Run")
                {
                    Caption = 'Object ID to Run', Comment = 'is-IS=Auðkenni hluts til keyrslu';
                    ToolTip = 'Specifies the ID of the object that is to be run for this job. You can select an ID that is of the object type that you have specified in the Object Type to Run field.', Comment = 'is-IS=Tilgreinir auðkenni hluts til keyrslu.';
                }
                field(objectCaptionToRun; Rec."Object Caption to Run")
                {
                    Caption = 'Object Caption to Run', Comment = 'is-IS=Kafli hluts til keyrslu';
                    ToolTip = 'Specifies the name of the object that is selected in the Object ID to Run field.', Comment = 'is-IS=Tilgreinir nafn hluts til keyrslu.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description', Comment = 'is-IS=Lýsing';
                    ToolTip = 'Specifies a description of the job queue entry. You can edit and update the description on the job queue entry card. The description is also displayed in the Job Queue Entries window, but it cannot be updated there.', Comment = 'is-IS=Tilgreinir lýsingu vinnsluraðafærslu.';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status', Comment = 'is-IS=Staða';
                    ToolTip = 'Specifies the status of the job queue entry. When you create a job queue entry, its status is set to On Hold. You can set the status to Ready and back to On Hold. Otherwise, status information in this field is updated automatically.', Comment = 'is-IS=Tilgreinir stöðu vinnsluraðafærslu.';
                }
                field(scheduled; Rec.Scheduled)
                {
                    Caption = 'Scheduled', Comment = 'is-IS=Tímasett';
                    ToolTip = 'Specifies if the job queue entry has been scheduled to run automatically, which happens when an entry changes status to Ready. If the field is cleared, the job queue entry is not scheduled to run.', Comment = 'is-IS=Tilgreinir hvort vinnsluraðafærsla hafí verið tímasett.';
                }
                field(orchestratorEnabled; Rec."Scheduler Enabled ori")
                {
                    Caption = 'Orchestrator Enabled', Comment = 'is-IS=Vinnsluraðari virkur';
                }
                field(jobQueueCategoryCode; Rec."Job Queue Category Code")
                {
                    Caption = 'Job Queue Category Code', Comment = 'is-IS=Flokkunarkóði vinnsluraða';
                    ToolTip = 'Specifies the code of the job queue category to which the job queue entry belongs. Choose the field to select a code from the list.', Comment = 'is-IS=Tilgreinir flokkunarkóða vinnsluraða.';
                }
                field(runOnMondays; Rec."Run on Mondays")
                {
                    Caption = 'Run on Mondays', Comment = 'is-IS=Keyra á mánudagum';
                    ToolTip = 'Specifies that the job queue entry runs on Mondays.', Comment = 'is-IS=Tilgreinir að keyrist á mánudagum.';
                }
                field(runOnTuesdays; Rec."Run on Tuesdays")
                {
                    Caption = 'Run on Tuesdays', Comment = 'is-IS=Keyra á þriðjudagum';
                    ToolTip = 'Specifies that the job queue entry runs on Tuesdays.', Comment = 'is-IS=Tilgreinir að keyrist á þriðjudagum.';
                }
                field(runOnWednesdays; Rec."Run on Wednesdays")
                {
                    Caption = 'Run on Wednesdays', Comment = 'is-IS=Keyra á miðvikudagum';
                    ToolTip = 'Specifies that the job queue entry runs on Wednesdays.', Comment = 'is-IS=Tilgreinir að keyrist á miðvikudagum.';
                }
                field(runOnThursdays; Rec."Run on Thursdays")
                {
                    Caption = 'Run on Thursdays', Comment = 'is-IS=Keyra á fimmtudagum';
                    ToolTip = 'Specifies that the job queue entry runs on Thursdays.', Comment = 'is-IS=Tilgreinir að keyrist á fimmtudagum.';
                }
                field(runOnFridays; Rec."Run on Fridays")
                {
                    Caption = 'Run on Fridays', Comment = 'is-IS=Keyra á föstudagum';
                    ToolTip = 'Specifies that the job queue entry runs on Fridays.', Comment = 'is-IS=Tilgreinir að keyrist á föstudagum.';
                }
                field(runOnSaturdays; Rec."Run on Saturdays")
                {
                    Caption = 'Run on Saturdays', Comment = 'is-IS=Keyra á laugardagum';
                    ToolTip = 'Specifies that the job queue entry runs on Saturdays.', Comment = 'is-IS=Tilgreinir að keyrist á laugardagum.';
                }
                field(runOnSundays; Rec."Run on Sundays")
                {
                    Caption = 'Run on Sundays', Comment = 'is-IS=Keyra á sunnudagum';
                    ToolTip = 'Specifies that the job queue entry runs on Sundays.', Comment = 'is-IS=Tilgreinir að keyrist á sunnudagum.';
                }
                field(startingTime; Rec."Starting Time")
                {
                    Caption = 'Starting Time', Comment = 'is-IS=Upphafstími';
                    ToolTip = 'Specifies the earliest time of the day that the recurring job queue entry is to be run.', Comment = 'is-IS=Tilgreinir fyrsta tíma dagsins til keyrslu.';
                }
                field(endingTime; Rec."Ending Time")
                {
                    Caption = 'Ending Time', Comment = 'is-IS=Lokatími';
                    ToolTip = 'Specifies the latest time of the day that the recurring job queue entry is to be run.', Comment = 'is-IS=Tilgreinir síðasta tíma dagsins til keyrslu.';
                }
                field(earliestStartDateTime; Rec."Earliest Start Date/Time")
                {
                    Caption = 'Earliest Start Date/Time', Comment = 'is-IS=Fyrsti tími til keyrslu';
                    ToolTip = 'Specifies the earliest date and time when the job queue entry should be run.  The format for the date and time must be month/day/year hour:minute, and then AM or PM. For example, 3/10/2021 12:00 AM.', Comment = 'is-IS=Tilgreinir fyrsta daga og tíma til keyrslu.';
                }
                field(userID; Rec."User ID")
                {
                    Caption = 'User ID', Comment = 'is-IS=Notendaauðkenni';
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.', Comment = 'is-IS=Tilgreinir notendaauðkenni.';
                }
                field(errorMessage; Rec."Error Message")
                {
                    Caption = 'Error Message', Comment = 'is-IS=Villuboð';
                    ToolTip = 'Specifies the latest error message that was received from the job queue entry. You can view the error message if the Status field is set to Error. The field can contain up to 250 characters.', Comment = 'is-IS=Tilgreinir villuboð.';
                }
            }
        }
    }

    [ServiceEnabled]
    /// <summary>
    /// Adds the current Job Queue Entry to the orchestrator.
    /// </summary>
    /// <param name="ActionContext">The web service action context for the response.</param>
    procedure AddToJobQueueOrchestrator(var ActionContext: WebServiceActionContext)
    var
        JobQueueScheduleEntry: Record "Scheduled Entry ori";
        Exists: Boolean;
    begin
        Exists := JobQueueScheduleEntry.Get(Rec.ID);
        JobQueueScheduleEntry.InsertFromJobQueueEntry(Rec, true);

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Scheduled Entry API ori");
        ActionContext.AddEntityKey(JobQueueScheduleEntry.FieldNo(ID), JobQueueScheduleEntry.ID);
        if Exists then
            ActionContext.SetResultCode(WebServiceActionResultCode::Updated)
        else
            ActionContext.SetResultCode(WebServiceActionResultCode::Created);
    end;
}
