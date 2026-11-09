namespace Origo.Bifrost.Orchestrator;

/// <summary>Temporary table-data browser rows; no business data is persisted in this table.</summary>
table 10035564 "Table Data Row ori"
{
    TableType = Temporary;
    AllowInCustomizations = Never;
    DataClassification = CustomerContent;
    Caption = 'Table Data Row', Comment = 'is-IS=Gagnafærsla töflu';
    fields
    {
        field(1; "Row No."; Integer)
        {
            Caption = 'Row No.', Comment = 'is-IS=Færslunr.';
        }
        field(2; "Primary Key"; Text[2048])
        {
            Caption = 'Primary Key', Comment = 'is-IS=Aðallykill';
        }
        field(3; Summary; Text[2048])
        {
            Caption = 'Summary', Comment = 'is-IS=Samantekt';
        }
        field(4; "Row JSON"; Blob)
        {
            Caption = 'Row JSON', Comment = 'is-IS=JSON-færsla';
        }
    }
    keys
    {
        key(PK; "Row No.")
        {
            Clustered = true;
        }
    }

    /// <summary>Stores the complete serializer envelope without truncation.</summary>
    procedure SetRow(Value: JsonObject)
    var
        Output: OutStream;
    begin
        Clear("Row JSON");
        "Row JSON".CreateOutStream(Output, TextEncoding::UTF8);
        Value.WriteTo(Output);
    end;

    /// <summary>Reads the complete serializer envelope.</summary>
    procedure GetRow() Value: JsonObject
    var
        Input: InStream;
    begin
        CalcFields("Row JSON");
        "Row JSON".CreateInStream(Input, TextEncoding::UTF8);
        Value.ReadFrom(Input);
    end;
}
