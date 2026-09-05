/// <summary>
/// One condition line for a playbook step.
/// </summary>
/// <remarks>
/// Evaluation is disjunctive normal form: all lines within a Group No. must hold
/// (AND), and any group holding is enough (OR). That gives full boolean
/// expressiveness with no nesting, precedence or parentheses. An empty set is true.
/// </remarks>
namespace Origo.Bifrost.Nornir;

table 10035599 "Playbook Condition ori"
{
    Caption = 'Bifrost Playbook Condition', Comment = 'is-IS=Skilyrði keðjuskrefs';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Playbook Code"; Code[20])
        {
            Caption = 'Playbook Code', Comment = 'is-IS=Kóði keðju';
            TableRelation = "Playbook ori".Code;
        }
        field(2; "Step No."; Integer)
        {
            Caption = 'Step No.', Comment = 'is-IS=Skrefnúmer';
            TableRelation = "Playbook Step ori"."Step No." where("Playbook Code" = field("Playbook Code"));
        }
        field(3; "Condition Type"; Enum "Playbook Cond. Type ori")
        {
            Caption = 'Condition Type', Comment = 'is-IS=Tegund skilyrðis';
        }
        field(4; "Group No."; Integer)
        {
            Caption = 'Group No.', Comment = 'is-IS=Hópnúmer';
            InitValue = 1;
            MinValue = 1;
        }
        field(5; "Line No."; Integer)
        {
            Caption = 'Line No.', Comment = 'is-IS=Línunúmer';
        }
        field(10; Path; Text[250])
        {
            Caption = 'Path', Comment = 'is-IS=Slóð';
        }
        field(11; Operator; Enum "Playbook Cond. Operator ori")
        {
            Caption = 'Operator', Comment = 'is-IS=Virki';
        }
        field(12; "Value"; Text[250])
        {
            Caption = 'Value', Comment = 'is-IS=Gildi';
        }
        field(20; Description; Text[100])
        {
            Caption = 'Description', Comment = 'is-IS=Lýsing';
        }
    }

    keys
    {
        key(PK; "Playbook Code", "Step No.", "Condition Type", "Group No.", "Line No.")
        {
            Clustered = true;
        }
    }

    /// <summary>Applies the filters for one step's conditions of a single type, in evaluation order.</summary>
    procedure FilterForStep(PlaybookCode: Code[20]; StepNo: Integer; CondType: Enum "Playbook Cond. Type ori")
    begin
        Reset();
        SetRange("Playbook Code", PlaybookCode);
        SetRange("Step No.", StepNo);
        SetRange("Condition Type", CondType);
    end;

    /// <summary>Next free line number within a step, type and group.</summary>
    procedure NextLineNo(PlaybookCode: Code[20]; StepNo: Integer; CondType: Enum "Playbook Cond. Type ori"; GroupNo: Integer): Integer
    var
        Existing: Record "Playbook Condition ori";
    begin
        Existing.FilterForStep(PlaybookCode, StepNo, CondType);
        Existing.SetRange("Group No.", GroupNo);
        if Existing.FindLast() then
            exit(Existing."Line No." + 10000);
        exit(10000);
    end;
}
