namespace Origo.Bifrost.Orchestrator;

using System.Threading;

/// <summary>
/// API page exposing Job Queue Log Entries for external integrations.
/// </summary>
page 10035540 "Log Entry ori"
{
    APIGroup = 'jobQueueOrchestrator';
    APIPublisher = 'origo';
    APIVersion = 'v1.0';
    Caption = 'Job Queue Log Entries API', Comment = 'is-IS=Kladdafærslur vinnsluraða API';
    Editable = false;
    EntityCaption = 'Queue Log Entry', Comment = 'is-IS=Kladdafærsla vinnsluraða';
    EntityName = 'queueLogEntry';
    EntitySetCaption = 'Queue Log Entries', Comment = 'is-IS=Kladdafærslur vinnsluraða';
    EntitySetName = 'queueLogEntries';
    ODataKeyFields = "Entry No.";
    PageType = API;
    SourceTable = "Job Queue Log Entry";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(id; Rec.ID)
                {
                    Caption = 'ID', Comment = 'is-IS=Auðkenni';
                    ToolTip = 'Specifies the ID of the job queue entry in the log.', Comment = 'is-IS=Tilgreinir auðkenni vinnsluraðafærslu í kladda.';
                }
                field(entryNo; Rec."Entry No.")
                {
                    Caption = 'Entry No.', Comment = 'is-IS=Færslunr.';
                }
                field(startDateTime; Rec."Start Date/Time")
                {
                    Caption = 'Start Date/Time', Comment = 'is-IS=Upphafsdagur/tími';
                    ToolTip = 'Specifies the date and time when the job was started.', Comment = 'is-IS=Tilgreinir dagsetningu og tíma þegar verk hófst.';
                }
                field(endDateTime; Rec."End Date/Time")
                {
                    Caption = 'End Date/Time', Comment = 'is-IS=Lokadagur/tími';
                    ToolTip = 'Specifies the date and time when the job ended.', Comment = 'is-IS=Tilgreinir dagsetningu og tíma þegar verki lauk.';
                }
                field(userID; Rec."User ID")
                {
                    Caption = 'User ID', Comment = 'is-IS=Notendaauðkenni';
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.', Comment = 'is-IS=Tilgreinir notendaauðkenni.';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status', Comment = 'is-IS=Staða';
                    ToolTip = 'Specifies the status of the running of the job queue entry in a log.', Comment = 'is-IS=Tilgreinir stöðu keyrslu í kladda.';
                }
                field(errorMessage; Rec."Error Message")
                {
                    Caption = 'Error Message', Comment = 'is-IS=Villuboð';
                    ToolTip = 'Specifies an error that occurred in the job queue.', Comment = 'is-IS=Tilgreinir villu sem kom upp í vinnslurað.';
                }
                field(errorMessageRegisterId; Rec."Error Message Register Id")
                {
                    Caption = 'Error Message Register Id', Comment = 'is-IS=Auðkenni villuboðskráningar';
                }
            }
        }
    }
}
