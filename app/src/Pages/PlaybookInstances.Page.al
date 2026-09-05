/// <summary>
/// List page for playbook execution instances (log).
/// </summary>
namespace Origo.Bifrost.Nornir;

using Origo.Bifrost;

page 10035550 "Playbook Instances ori"
{
    Caption = 'Playbook Execution Log', Comment = 'is-IS=Keyrsluskrá keðju';
    ContextSensitiveHelpPage = 'playbook-instances.html';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Playbook Instance ori";
    Editable = false;
    CardPageId = "Playbook Instance Card ori";
    SourceTableView = sorting("Playbook Code", "Started At") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Instances)
            {
                field("Playbook Code"; Rec."Playbook Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the playbook that was executed.', Comment = 'is-IS=Tilgreinir keðjuna sem var keyrð.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the execution status.', Comment = 'is-IS=Tilgreinir stöðu keyrslu.';
                    StyleExpr = StatusStyle;
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
                field("Error Text"; Rec."Error Text")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the error message if the playbook failed.', Comment = 'is-IS=Tilgreinir villuboð ef keðjan mistókst.';
                }
            }
        }
    }

    var
        StatusStyle: Text;

    trigger OnAfterGetRecord()
    begin
        case Rec.Status of
            Rec.Status::Completed:
                StatusStyle := 'Favorable';
            Rec.Status::Failed:
                StatusStyle := 'Unfavorable';
            Rec.Status::Running:
                StatusStyle := 'Ambiguous';
            else
                StatusStyle := 'Standard';
        end;
    end;
}
