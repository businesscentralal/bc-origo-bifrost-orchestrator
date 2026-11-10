namespace Origo.Bifrost.Orchestrator;

/// <summary>
/// Temporary buffer for one row shown on the "Table Data ori" page (#155, Phase 2). Holds no data: the page fills it
/// from the source table through "Table Data Mgt ori" for the current page of rows.
/// </summary>
table 10035564 "Table Data Row ori"
{
    Caption = 'Table Data Row', Comment = 'is-IS=Lína töflugagna';
    DataClassification = SystemMetadata;
    TableType = Temporary;
    AllowInCustomizations = Never;
    Extensible = false;

    fields
    {
        field(1; "Row No."; Integer)
        {
            Caption = 'Row No.', Comment = 'is-IS=Línunr.';
            ToolTip = 'Specifies the position of the row on the current page.', Comment = 'is-IS=Tilgreinir staðsetningu línunnar á núverandi síðu.';
        }
        field(2; "Record SystemId"; Guid)
        {
            Caption = 'Record SystemId', Comment = 'is-IS=SystemId færslu';
            ToolTip = 'Specifies the SystemId of the record in the source table.', Comment = 'is-IS=Tilgreinir SystemId færslunnar í upprunatöflunni.';
        }
        field(3; "Primary Key"; Text[250])
        {
            Caption = 'Primary Key', Comment = 'is-IS=Aðallykill';
            ToolTip = 'Specifies the primary key values of the record.', Comment = 'is-IS=Tilgreinir gildi aðallykils færslunnar.';
        }
        field(4; Summary; Text[2048])
        {
            Caption = 'Summary', Comment = 'is-IS=Samantekt';
            ToolTip = 'Specifies the first fields of the record as Name=Value pairs.', Comment = 'is-IS=Tilgreinir fyrstu reiti færslunnar sem Heiti=Gildi pör.';
        }
    }

    keys
    {
        key(PK; "Row No.")
        {
            Clustered = true;
        }
    }
}
