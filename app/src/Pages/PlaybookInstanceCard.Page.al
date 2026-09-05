/// <summary>
/// Card page for a single playbook execution instance, with step log detail.
/// </summary>
namespace Origo.Bifrost.Nornir;

using Origo.Bifrost;

page 10035549 "Playbook Instance Card ori"
{
    Caption = 'Playbook Execution Detail', Comment = 'is-IS=Upplýsingar um keðjukeyrslu';
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "Playbook Instance ori";
    Editable = false;
    UsageCategory = None;
    DataCaptionExpression = StrSubstNo('%1 · %2', Rec."Playbook Code", Rec.Status);

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General', Comment = 'is-IS=Almennt';

                field("Playbook Code"; Rec."Playbook Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the playbook that was executed.', Comment = 'is-IS=Tilgreinir keðjuna sem var keyrð.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the execution status.', Comment = 'is-IS=Tilgreinir stöðu keyrslu.';
                }
                field("Started At"; Rec."Started At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the execution started.', Comment = 'is-IS=Tilgreinir hvenær keyrsla hófst.';
                }
                field("Completed At"; Rec."Completed At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the execution completed.', Comment = 'is-IS=Tilgreinir hvenær keyrslu lauk.';
                }
                field("Total Duration"; Rec."Total Duration")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total execution time.', Comment = 'is-IS=Tilgreinir heildartíma keyrslu.';
                }
            }
            group(Counters)
            {
                Caption = 'Counters', Comment = 'is-IS=Teljarar';

                field("Steps Executed"; Rec."Steps Executed")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of steps executed.', Comment = 'is-IS=Tilgreinir fjölda skrefa keyrð.';
                }
                field("Steps Failed"; Rec."Steps Failed")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of steps that failed.', Comment = 'is-IS=Tilgreinir fjölda skrefa sem mistókst.';
                }
                field("Items Processed"; Rec."Items Processed")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total foreach items processed.', Comment = 'is-IS=Tilgreinir heildarfjölda hluta unninna.';
                }
            }
            group(ErrorGroup)
            {
                Caption = 'Error', Comment = 'is-IS=Villa';
                Visible = Rec."Error Text" <> '';

                field("Error Text"; Rec."Error Text")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the error message if the playbook failed.', Comment = 'is-IS=Tilgreinir villuboð ef keðjan mistókst.';
                }
            }
            part(StepLogs; "Playbook Step Logs Sub. ori")
            {
                ApplicationArea = All;
                SubPageLink = "Instance ID" = field(ID);
                Caption = 'Step Log', Comment = 'is-IS=Atburðaskrá skrefa';
            }
        }
        area(FactBoxes)
        {
            part(StepLogDetail; "Playbook Step Log Dtl. FB ori")
            {
                ApplicationArea = All;
                Provider = StepLogs;
                SubPageLink = "Instance ID" = field("Instance ID"), "Step No." = field("Step No."), "Iteration No." = field("Iteration No.");
                Caption = 'Selected Step', Comment = 'is-IS=Valið skref';
            }
        }
    }

}
