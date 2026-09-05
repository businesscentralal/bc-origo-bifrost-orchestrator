namespace Origo.Bifrost.Nornir;

using System.Threading;

/// <summary>
/// API page exposing Job Queue Categories for external integrations.
/// </summary>
page 10035541 "Categories ori"
{
    APIGroup = 'jobQueueOrchestrator';
    APIPublisher = 'origo';
    APIVersion = 'v1.0';
    Caption = 'Job Queue Categories', Comment = 'is-IS=Flokkar vinnsluraða';
    DelayedInsert = true;
    EntityCaption = 'Queue Category', Comment = 'is-IS=Flokkur vinnsluraða';
    EntityName = 'queueCategory';
    EntitySetCaption = 'Queue Categories', Comment = 'is-IS=Flokkar vinnsluraða';
    EntitySetName = 'queueCategories';
    ODataKeyFields = Code;
    PageType = API;
    SourceTable = "Job Queue Category";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("code"; Rec."Code")
                {
                    Caption = 'Code', Comment = 'is-IS=Kóði';
                    ToolTip = 'Specifies a code for the category of job queue. You can enter a maximum of 10 characters, both numbers and letters.', Comment = 'is-IS=Tilgreinir kóða flokks vinnsluraða.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description', Comment = 'is-IS=Lýsing';
                    ToolTip = 'Specifies a description of the job queue category. You can enter a maximum of 30 characters, both numbers and letters.', Comment = 'is-IS=Tilgreinir lýsingu flokks vinnsluraða.';
                }
            }
        }
    }
}
