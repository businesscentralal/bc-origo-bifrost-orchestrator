/// <summary>
/// Subpage for playbook steps — inline editing of step definitions.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

page 10035553 "Playbook Steps Subpage ori"
{
    Caption = 'Playbook Steps', Comment = 'is-IS=Keðjuskref';
    PageType = ListPart;
    SourceTable = "Playbook Step ori";
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Steps)
            {
                IndentationColumn = IndentLevel;
                IndentationControls = Description;

                field("Step No."; Rec."Step No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the step sequence number.', Comment = 'is-IS=Tilgreinir raðnúmer skrefsins.';
                    StyleExpr = StepStatusStyle;
                }
                field(LastStatus; LastRunStatusText)
                {
                    ApplicationArea = All;
                    Caption = 'Last Run', Comment = 'is-IS=Síðasta keyrsla';
                    ToolTip = 'Status from the most recent playbook execution.', Comment = 'is-IS=Staða úr síðustu keyrslu keðju.';
                    Editable = false;
                    StyleExpr = StepStatusStyle;
                    Width = 6;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the step description.', Comment = 'is-IS=Tilgreinir lýsingu skrefsins.';
                    StyleExpr = DescriptionStyle;

                    trigger OnValidate()
                    begin
                        SetDescriptionStyle();
                    end;
                }
                field("Message Type"; Rec."Message Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Bifrost message type to execute.', Comment = 'is-IS=Tilgreinir Bifröst skilaboðagerð til keyrslu.';
                }
                field("Iterate Array Path"; Rec."Iterate Array Path")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the JSON path to the array to iterate over. Leave empty for a single call.', Comment = 'is-IS=Tilgreinir JSON slóð fylkis til ítrunar. Skilja eftir autt fyrir eitt kall.';
                }
                field("Iterate Source Step No."; Rec."Iterate Source Step No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies which prior step''s response contains the array to iterate.', Comment = 'is-IS=Tilgreinir hvaða fyrra skref inniheldur fylkið til ítrunar.';
                }
                field("Step Type"; Rec."Step Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Action: a false success condition is a failure. Check: it is simply the answer, and does not fail the run.', Comment = 'is-IS=Aðgerð: ósatt árangursskilyrði telst villa. Athugun: það er einfaldlega svarið og fellir ekki keyrsluna.';
                }
                field("Summary Paths"; Rec."Summary Paths")
                {
                    ApplicationArea = All;
                    ToolTip = 'Response paths copied into the run report for this step. Keep it small — this feeds the report, not later steps.', Comment = 'is-IS=Slóðir í svari sem afritast í keyrsluskýrslu þessa skrefs. Hafðu það stutt — þetta fer í skýrsluna, ekki í síðari skref.';
                }
                field("Exclude From Run Status"; Rec."Exclude From Run Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Leave this step out of the run status and the report. Use it for the reporting steps themselves.', Comment = 'is-IS=Halda þessu skrefi utan við stöðu keyrslu og skýrslu. Notist fyrir skýrsluskrefin sjálf.';
                }
                field("Next Step No. (Success)"; Rec."Next Step No. (Success)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the next step when the condition succeeds. 0 = playbook complete.', Comment = 'is-IS=Tilgreinir næsta skref þegar skilyrði stenst. 0 = keðja lokið.';
                }
                field("Next Step No. (Failure)"; Rec."Next Step No. (Failure)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the next step when the condition fails. 0 = playbook ends.', Comment = 'is-IS=Tilgreinir næsta skref þegar skilyrði bregst. 0 = keðju lýkur.';
                }
                field("Stop On Item Error"; Rec."Stop On Item Error")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether to abort the playbook when a foreach item fails.', Comment = 'is-IS=Tilgreinir hvort stöðva eigi keðjuna þegar hlutur í ítrun bregst.';
                }
                field(Disabled; Rec.Disabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Disables this step so the runner skips it without executing.', Comment = 'is-IS=Gerir skrefið óvirkt svo keyrsluvélin sleppi því.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetDescriptionStyle();
        SetLastRunStatus();
    end;

    local procedure SetDescriptionStyle()
    begin
        if Rec.Disabled then begin
            IndentLevel := 0;
            DescriptionStyle := 'Subordinate';
            exit;
        end;
        if Rec."Iterate Array Path" <> '' then begin
            IndentLevel := 1;
            DescriptionStyle := 'Subordinate';
        end else begin
            IndentLevel := 0;
            DescriptionStyle := 'Standard';
        end;
    end;

    local procedure SetLastRunStatus()
    var
        Playbook: Record "Playbook ori";
        StepLog: Record "Playbook Step Log ori";
    begin
        LastRunStatusText := '';
        StepStatusStyle := 'Standard';

        if not Playbook.Get(Rec."Playbook Code") then
            exit;
        if IsNullGuid(Playbook."Last Run Instance ID") then
            exit;

        StepLog.SetRange("Instance ID", Playbook."Last Run Instance ID");
        StepLog.SetRange("Step No.", Rec."Step No.");
        StepLog.SetLoadFields(Status);
        StepLog.ReadIsolation := IsolationLevel::ReadCommitted;
        if not StepLog.FindLast() then begin
            LastRunStatusText := NotRunTok;
            StepStatusStyle := 'Subordinate';
            exit;
        end;

        case StepLog.Status of
            StepLog.Status::Completed:
                begin
                    LastRunStatusText := CompletedTok;
                    StepStatusStyle := 'Favorable';
                end;
            StepLog.Status::Failed:
                begin
                    LastRunStatusText := FailedTok;
                    StepStatusStyle := 'Unfavorable';
                end;
            StepLog.Status::Cancelled:
                begin
                    LastRunStatusText := SkippedTok;
                    StepStatusStyle := 'Ambiguous';
                end;
            else begin
                LastRunStatusText := Format(StepLog.Status);
                StepStatusStyle := 'Standard';
            end;
        end;
    end;

    var
        IndentLevel: Integer;
        DescriptionStyle: Text;
        StepStatusStyle: Text;
        LastRunStatusText: Text;
        CompletedTok: Label '✓', Locked = true;
        FailedTok: Label '✗', Locked = true;
        SkippedTok: Label '–', Locked = true;
        NotRunTok: Label '·', Locked = true;
}
