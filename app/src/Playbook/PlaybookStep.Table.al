/// <summary>
/// A single step within a playbook. Each step calls one Bifrost message type
/// and can optionally iterate over an array from a prior step's response.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

table 10035540 "Playbook Step ori"
{
    Caption = 'Bifrost Playbook Step', Comment = 'is-IS=Skref Bifröst keðju';
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
        }
        field(10; Description; Text[250])
        {
            Caption = 'Description', Comment = 'is-IS=Lýsing';
        }
        field(15; "Step Type"; Enum "Playbook Step Type ori")
        {
            Caption = 'Step Type', Comment = 'is-IS=Tegund skrefs';
        }
        field(20; "Message Type"; Enum "Message Type ori")
        {
            Caption = 'Message Type', Comment = 'is-IS=Skilaboðagerð';
        }
        field(30; "Request Template"; Blob)
        {
            Caption = 'Request Template', Comment = 'is-IS=Sniðmát beiðni';
        }
        field(40; "Iterate Array Path"; Text[250])
        {
            Caption = 'Iterate Array Path', Comment = 'is-IS=Slóð fylkis til ítrunar';
        }
        field(41; "Iterate Source Step No."; Integer)
        {
            Caption = 'Iterate Source Step No.', Comment = 'is-IS=Upprunaskref ítrunar';
            BlankZero = true;
        }
        field(60; "Next Step No. (Success)"; Integer)
        {
            Caption = 'Next Step No. (Success)', Comment = 'is-IS=Næsta skref (árangur)';
        }
        field(61; "Next Step No. (Failure)"; Integer)
        {
            Caption = 'Next Step No. (Failure)', Comment = 'is-IS=Næsta skref (misbrestur)';
        }
        field(70; "Stop On Item Error"; Boolean)
        {
            Caption = 'Stop On Item Error', Comment = 'is-IS=Stöðva við villu hlutar';
        }
        field(80; "Skip If Step Failed"; Integer)
        {
            Caption = 'Skip If Step Failed', Comment = 'is-IS=Sleppa ef skref mistókst';
        }
        field(90; "Result Log Paths"; Text[2048])
        {
            Caption = 'Result Log Paths', Comment = 'is-IS=Niðurstöðuskráningarslóðir';
        }
        field(91; "Summary Paths"; Text[2048])
        {
            Caption = 'Summary Paths', Comment = 'is-IS=Slóðir samantektar';
        }
        field(100; Paged; Boolean)
        {
            Caption = 'Paged', Comment = 'is-IS=Síðuð';
        }
        field(101; "Page Size"; Integer)
        {
            Caption = 'Page Size', Comment = 'is-IS=Síðustærð';
            InitValue = 500;
            MinValue = 1;
        }
        field(102; "Page Through Step No."; Integer)
        {
            Caption = 'Page Through Step No.', Comment = 'is-IS=Síða í gegnum skrefnúmer';
        }
        field(110; Disabled; Boolean)
        {
            Caption = 'Disabled', Comment = 'is-IS=Óvirkt';
        }
        field(111; "Exclude From Run Status"; Boolean)
        {
            Caption = 'Exclude From Run Status', Comment = 'is-IS=Undanskilja frá stöðu keyrslu';
        }
    }

    keys
    {
        key(PK; "Playbook Code", "Step No.")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        Condition: Record "Playbook Condition ori";
    begin
        Condition.SetRange("Playbook Code", "Playbook Code");
        Condition.SetRange("Step No.", "Step No.");
        Condition.DeleteAll(true);
    end;

    /// <summary>
    /// Gets the request template as text.
    /// </summary>
    procedure GetRequestTemplate(): Text
    var
        InStr: InStream;
        Result: Text;
    begin
        CalcFields("Request Template");
        if not "Request Template".HasValue() then
            exit('');
        "Request Template".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(Result);
        exit(Result);
    end;

    /// <summary>
    /// Sets the request template from text.
    /// </summary>
    procedure SetRequestTemplate(TemplateText: Text)
    var
        OutStr: OutStream;
    begin
        "Request Template".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(TemplateText);
    end;

    /// <summary>
    /// Returns true if this step should iterate over an array from a prior step.
    /// </summary>
    procedure IsForEach(): Boolean
    begin
        exit("Iterate Array Path" <> '');
    end;

    /// <summary>
    /// Returns true if this step has at least one condition of the given type.
    /// </summary>
    procedure HasConditions(CondType: Enum "Playbook Cond. Type ori"): Boolean
    var
        Condition: Record "Playbook Condition ori";
    begin
        Condition.FilterForStep("Playbook Code", "Step No.", CondType);
        exit(not Condition.IsEmpty());
    end;

    /// <summary>
    /// A Check step answers a question — a false Success condition is the answer,
    /// not a failure, so it must not count towards the run's failure total.
    /// </summary>
    procedure IsCheck(): Boolean
    begin
        exit("Step Type" = "Step Type"::Check);
    end;
}
