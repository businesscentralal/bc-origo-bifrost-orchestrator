namespace Origo.Bifrost.Orchestrator;

using System.Threading;

/// <summary>
/// API page exposing the Job Queue Orchestrator status and restart actions.
/// </summary>
page 10035539 "Scheduler Status ori"
{
    APIGroup = 'jobQueueOrchestrator';
    APIPublisher = 'origo';
    APIVersion = 'v1.0';
    Caption = 'Job Queue Orchestrator Status', Comment = 'is-IS=Staða vinnsluraðara';
    DelayedInsert = true;
    EntityCaption = 'Setup', Comment = 'is-IS=Uppsetning';
    EntityName = 'setup';
    EntitySetCaption = 'Status', Comment = 'is-IS=Staða';
    EntitySetName = 'status';
    Extensible = false;
    ODataKeyFields = SystemId;
    PageType = API;
    SourceTable = "Scheduler Setup ori";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(systemId; Rec.SystemId)
                {
                    Caption = 'System Id', Comment = 'is-IS=Kerfisauðkenni';
                }
                field(jobQueueCategoryCode; Rec."Job Queue Category Code")
                {
                    Caption = 'Job Queue Category Code', Comment = 'is-IS=Flokkunarkóði vinnsluraða';
                }
                field(logJobQueueActivity; Rec."Log Job Queue Activity")
                {
                    Caption = 'Log Job Queue Activity', Comment = 'is-IS=Skrá virkni vinnsluraða';
                }
                field(status; JobQueueStatus)
                {
                    Caption = 'Job Queue Orchestrator Status', Comment = 'is-IS=Staða vinnsluraðara';
                    Editable = false;
                }
                field(readyToStart; ReadyToStart)
                {
                    Caption = 'Ready To Start', Comment = 'is-IS=Tilbúinn til keyrslu';
                    Editable = false;
                }
            }
        }
    }

    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueManagement: Codeunit "Scheduler Mgt ori";
        ReadyToStart: Boolean;
        JobQueueStatus, JobQueueStyleExpr : Text;

    trigger OnAfterGetCurrRecord()
    begin
        ReadyToStart := JobQueueManagement.GetJobQueueStatus(JobQueueStatus, JobQueueStyleExpr);
    end;

    [ServiceEnabled]
    /// <summary>
    /// Restarts the management Job Queue Entry unconditionally.
    /// </summary>
    /// <param name="ActionContext">The web service action context for the response.</param>
    procedure Restart(var ActionContext: WebServiceActionContext)
    begin
        Rec.RestartManagementJobQueue();

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Entries API ori");
        ActionContext.AddEntityKey(JobQueueEntry.FieldNo(ID), JobQueueManagement.GetManagementJobQueueId());
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    [ServiceEnabled]
    /// <summary>
    /// Restarts the management Job Queue Entry only if it is not already running.
    /// </summary>
    /// <param name="ActionContext">The web service action context for the response.</param>
    procedure RestartIfNeeded(var ActionContext: WebServiceActionContext)
    begin
        ReadyToStart := JobQueueManagement.GetJobQueueStatus(JobQueueStatus, JobQueueStyleExpr);
        if not ReadyToStart then
            Rec.RestartManagementJobQueue();

        ActionContext.SetObjectType(ObjectType::Page);
        ActionContext.SetObjectId(Page::"Entries API ori");
        ActionContext.AddEntityKey(JobQueueEntry.FieldNo(ID), JobQueueManagement.GetManagementJobQueueId());
        if ReadyToStart then
            ActionContext.SetResultCode(WebServiceActionResultCode::Get)
        else
            ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;
}
