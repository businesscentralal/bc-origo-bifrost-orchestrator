namespace Origo.Bifrost.Orchestrator;

using System.IO;
using System.Reflection;

/// <summary>
/// Stores the field-level mapping between a source and a destination field of a Copy Table Mapping
/// (port of Tools for Power Users "Copy Field Mapping").
/// </summary>
table 10035633 "Copy Field Mapping ori"
{
    Caption = 'Copy Field Mapping', Comment = 'is-IS=Afrita reit - vörpun';
    DataClassification = SystemMetadata;
    Access = Public;

    fields
    {
        field(1; "Copy Table Mapping ID"; Guid)
        {
            Caption = 'Copy Table Mapping ID', Comment = 'is-IS=Afrita töflu - vörpunarkenni';
            TableRelation = "Copy Table Mapping ori".ID;

            trigger OnValidate()
            begin
                CopyTableIDs();
            end;
        }
        field(2; "Source Table ID"; Integer)
        {
            Caption = 'Source Table ID', Comment = 'is-IS=Töflukenni upprunastaðs';
        }
        field(3; "Destination Table ID"; Integer)
        {
            Caption = 'Destination Table ID', Comment = 'is-IS=Töflukenni viðtökustaðs';
        }
        field(4; "Source Field ID"; Integer)
        {
            Caption = 'Source Field ID', Comment = 'is-IS=Kenni upprunareits';
            ToolTip = 'Specifies the value of the Source Field ID field.', Comment = 'is-IS=Tilgreinir gildi reitsins reitakenni upprunastaðar.';
            NotBlank = true;
            TableRelation = Field."No." where(TableNo = field("Source Table ID"), ObsoleteState = filter(No | Pending), Class = const(Normal), "No." = filter(< 2000000000));

            trigger OnValidate()
            var
                TableField: Record "Field";
            begin
                TableField.Get("Source Table ID", "Source Field ID");
                TableField.TestField(Class, TableField.Class::Normal);
                TableField.TestField(Enabled, true);
                if TableField.ObsoleteState = TableField.ObsoleteState::Removed then
                    TableField.TestField(ObsoleteState, TableField.ObsoleteState::No);
                CalcFields("Source Field Caption");
                "Destination Field ID" := 0;
                "Destination Field Caption" := '';
                EvaluateDestinationFieldID();
            end;
        }
        field(5; "Source Field Caption"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Source Table ID"), "No." = field("Source Field ID")));
            Caption = 'Source Field Caption', Comment = 'is-IS=Texti upprunareits';
            ToolTip = 'Specifies the value of the Source Field Caption field.', Comment = 'is-IS=Tilgreinir gildi reitsins reitatexti upprunastaðar.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Destination Field ID"; Integer)
        {
            Caption = 'Destination Field ID', Comment = 'is-IS=Kenni viðtökureits';
            ToolTip = 'Specifies the value of the Destination Field ID field.', Comment = 'is-IS=Tilgreinir gildi reitsins reitakenni viðtökustaðar.';
            NotBlank = true;
            TableRelation = Field."No." where(TableNo = field("Destination Table ID"), ObsoleteState = filter(No | Pending), Class = const(Normal), "No." = filter(< 2000000000));

            trigger OnValidate()
            var
                TableField: Record "Field";
            begin
                if "Destination Field ID" = 0 then
                    exit;
                TableField.Get("Destination Table ID", "Destination Field ID");
                TableField.TestField(Class, TableField.Class::Normal);
                TableField.TestField(Enabled, true);
                if TableField.ObsoleteState = TableField.ObsoleteState::Removed then
                    TableField.TestField(ObsoleteState, TableField.ObsoleteState::No);
                CalcFields("Destination Field Caption");
            end;
        }
        field(7; "Destination Field Caption"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Destination Table ID"), "No." = field("Destination Field ID")));
            Caption = 'Destination Field Caption', Comment = 'is-IS=Texti viðtökureits';
            ToolTip = 'Specifies the value of the Destination Field Caption field.', Comment = 'is-IS=Tilgreinir gildi reitsins reitatexti viðtökustaðar.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "Transformation Rule"; Code[20])
        {
            Caption = 'Transformation Rule', Comment = 'is-IS=Umbreytingarregla';
            ToolTip = 'Specifies the value of the Transformation Rule field.', Comment = 'is-IS=Tilgreinir gildi reitsins umbreytingarregla.';
            TableRelation = "Transformation Rule";
        }
        field(28; "Is Part Of Primary Key"; Boolean)
        {
            CalcFormula = lookup(Field.IsPartOfPrimaryKey where(TableNo = field("Destination Table ID"), "No." = field("Destination Field ID")));
            Caption = 'Is Part Of Primary Key', Comment = 'is-IS=Er hluti af frumlykli';
            ToolTip = 'Specifies the value of the Is Part Of Primary Key field.', Comment = 'is-IS=Tilgreinir gildi reitsins hluti af frumlykli.';
            Editable = false;
            FieldClass = FlowField;
        }
    }
    keys
    {
        key(PK; "Copy Table Mapping ID", "Source Field ID")
        {
            Clustered = true;
        }
    }

    local procedure CopyTableIDs()
    var
        TableMapping: Record "Copy Table Mapping ori";
    begin
        TableMapping.SetLoadFields("Source Table ID", "Destination Table ID");
        TableMapping.Get("Copy Table Mapping ID");
        TableMapping.TestField("Source Table ID");
        TableMapping.TestField("Destination Table ID");
        "Source Table ID" := TableMapping."Source Table ID";
        "Destination Table ID" := TableMapping."Destination Table ID";
    end;

    local procedure EvaluateDestinationFieldID()
    var
        DestinationTableField: Record "Field";
        SourceTableField: Record "Field";
        IsMatch: Boolean;
    begin
        SourceTableField.Get("Source Table ID", "Source Field ID");
        IsMatch := DestinationTableField.Get("Destination Table ID", "Source Field ID");
        if IsMatch then
            IsMatch := DestinationTableField.Class = SourceTableField.Class;
        if IsMatch then
            IsMatch := DestinationTableField.Enabled = SourceTableField.Enabled;
        if IsMatch then
            IsMatch := DestinationTableField.ObsoleteState in [SourceTableField.ObsoleteState::No, SourceTableField.ObsoleteState::Pending];
        if IsMatch then
            case SourceTableField.Type of
                SourceTableField.Type::Code, SourceTableField.Type::Text:
                    IsMatch := (DestinationTableField.Type in [SourceTableField.Type::Code, SourceTableField.Type::Text]) and (DestinationTableField.Len >= SourceTableField.Len);
                SourceTableField.Type::Integer:
                    IsMatch := DestinationTableField.Type in [SourceTableField.Type::Integer, SourceTableField.Type::BigInteger];
                else
                    IsMatch := DestinationTableField.Type = SourceTableField.Type;
            end;
        if IsMatch then
            Validate("Destination Field ID", DestinationTableField."No.");
    end;
}
