namespace Origo.Bifrost.Orchestrator;

/// <summary>Temporary field values and current Foundation editability decisions for one row.</summary>
table 10035565 "Table Data Field ori"
{
    TableType = Temporary;
    AllowInCustomizations = Never;
    DataClassification = CustomerContent;
    Caption = 'Table Data Field', Comment = 'is-IS=Gagnareitur töflu';
    fields
    {
        field(1; "Field No."; Integer)
        {
            Caption = 'Field No.', Comment = 'is-IS=Reitarnr.';
        }
        field(2; "Field Name"; Text[250])
        {
            Caption = 'Field Name', Comment = 'is-IS=Heiti reits';
        }
        field(3; Value; Text[2048])
        {
            Caption = 'Value', Comment = 'is-IS=Gildi';
        }
        field(4; "Type"; Text[30])
        {
            Caption = 'Type', Comment = 'is-IS=Gerð';
        }
        field(5; "Can Edit"; Boolean)
        {
            Caption = 'Editable', Comment = 'is-IS=Breytanlegt';
        }
        field(6; "JSON Name"; Text[250])
        {
            Caption = 'JSON Name', Comment = 'is-IS=JSON-heiti';
        }
    }
    keys
    {
        key(PK; "Field No.")
        {
            Clustered = true;
        }
    }
}
