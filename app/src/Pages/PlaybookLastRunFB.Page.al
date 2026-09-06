namespace Origo.Bifrost.Orchestrator;

page 10035583 "Playbook Last Run FB ori"
{
    Caption = 'Last Execution', Comment = 'is-IS=Síðasta keyrsla';
    PageType = CardPart;
    SourceTable = "Playbook Instance ori";
    Editable = false;

    layout
    {
        area(Content)
        {
            field(Status; Rec.Status)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the status of the last execution.', Comment = 'is-IS=Tilgreinir stöðu síðustu keyrslu.';
                StyleExpr = StatusStyle;
                DrillDown = true;

                trigger OnDrillDown()
                begin
                    Page.Run(Page::"Playbook Instance Card ori", Rec);
                end;
            }
            field("Started At"; Rec."Started At")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies when the last execution started.', Comment = 'is-IS=Tilgreinir hvenær síðasta keyrsla hófst.';
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
                DrillDown = true;

                trigger OnDrillDown()
                begin
                    Page.Run(Page::"Playbook Instance Card ori", Rec);
                end;
            }
            field("Items Processed"; Rec."Items Processed")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the total items processed.', Comment = 'is-IS=Tilgreinir heildarfjölda hluta unninna.';
            }
            field("Error Text"; Rec."Error Text")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the error message if the execution failed.', Comment = 'is-IS=Tilgreinir villuboð ef keyrslan mistókst.';
                Visible = Rec."Error Text" <> '';
            }
        }
    }

    var
        StatusStyle: Text;

    trigger OnAfterGetCurrRecord()
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
