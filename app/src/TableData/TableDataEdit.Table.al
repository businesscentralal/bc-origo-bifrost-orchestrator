namespace Origo.Bifrost.Orchestrator;

using System.Reflection;

/// <summary>
/// Temporary in-memory table used by the Table Data Management pages: one row of the edit grid (#261), and the four
/// date and time filters of the main page. Port of "Tools Edit Table" from Tools for Power Users.
/// </summary>
table 10035630 "Table Data Edit ori"
{
    Access = Internal;
    Caption = 'Edit Table', Comment = 'is-IS=Breyta töflu';
    DataClassification = SystemMetadata;
    Extensible = false;
    ReplicateData = false;
    TableType = Temporary;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID', Comment = 'is-IS=Kenni töflu';
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.', Comment = 'is-IS=Færslunr.';
        }
        field(3; "Record System Id"; Guid)
        {
            Caption = 'System Id', Comment = 'is-IS=Kerfiskenni';
        }
        field(4; "Record Created Up To"; DateTime)
        {
            Caption = 'Record Created Up To', Comment = 'is-IS=Færsla stofnuð að';
        }
        field(5; "Record Modified Up To"; DateTime)
        {
            Caption = 'Record Modified Up To', Comment = 'is-IS=Færslu breytt að';
        }
        field(6; "Record Created After"; DateTime)
        {
            Caption = 'Record Created After', Comment = 'is-IS=Færsla stofnuð eftir';
        }
        field(7; "Record Modified After"; DateTime)
        {
            Caption = 'Record Modified After', Comment = 'is-IS=Færslu breytt eftir';
        }
        field(8; "Record Created Filter"; DateTime)
        {
            Caption = 'Record Created Filter', Comment = 'is-IS=Færsla stofnuð afmörkun';
            FieldClass = FlowFilter;
        }
        field(9; "Record Modified Filter"; DateTime)
        {
            Caption = 'Record Modified Filter', Comment = 'is-IS=Færslu breytt afmörkun';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(Key1; "Table ID", "Entry No.")
        {
            Clustered = true;
        }
    }
}
