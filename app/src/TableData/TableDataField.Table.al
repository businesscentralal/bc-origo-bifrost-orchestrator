namespace Origo.Bifrost.Orchestrator;

/// <summary>
/// Temporary buffer for one field of one record on the "Table Data Fields ori" page (#155, Phase 2). Holds no data.
/// </summary>
table 10035565 "Table Data Field ori"
{
    Caption = 'Table Data Field', Comment = 'is-IS=Reitur töflugagna';
    DataClassification = SystemMetadata;
    TableType = Temporary;
    Extensible = false;

    fields
    {
        field(1; "Field No."; Integer)
        {
            Caption = 'Field No.', Comment = 'is-IS=Reitarnr.';
            ToolTip = 'Specifies the number of the field.', Comment = 'is-IS=Tilgreinir númer reitsins.';
        }
        field(2; "Field Name"; Text[80])
        {
            Caption = 'Field Name', Comment = 'is-IS=Heiti reits';
            ToolTip = 'Specifies the name of the field.', Comment = 'is-IS=Tilgreinir heiti reitsins.';
        }
        field(3; Value; Text[2048])
        {
            Caption = 'Value', Comment = 'is-IS=Gildi';
            ToolTip = 'Specifies the value of the field as the serializer writes it. Change it to save a new value.', Comment = 'is-IS=Tilgreinir gildi reitsins eins og raðarinn skrifar það. Breyttu því til að vista nýtt gildi.';
        }
        field(4; Type; Text[30])
        {
            Caption = 'Type', Comment = 'is-IS=Tegund';
            ToolTip = 'Specifies the data type of the field.', Comment = 'is-IS=Tilgreinir gagnategund reitsins.';
        }
        field(5; "Part of Primary Key"; Boolean)
        {
            Caption = 'Part of Primary Key', Comment = 'is-IS=Hluti af aðallykli';
            ToolTip = 'Specifies whether the field is part of the primary key. Primary key fields cannot be edited here.', Comment = 'is-IS=Tilgreinir hvort reiturinn er hluti af aðallyklinum. Ekki er hægt að breyta reitum aðallykils hér.';
        }
        field(6; "Json Key"; Text[80])
        {
            Caption = 'Json Key', Comment = 'is-IS=JSON-lykill';
            ToolTip = 'Specifies the key of the field in the serializer JSON.', Comment = 'is-IS=Tilgreinir lykil reitsins í JSON raðarans.';
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
