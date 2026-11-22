namespace Origo.Bifrost.Orchestrator;

/// <summary>
/// Access object of the Table Data Management pages (#261), the Orchestrator counterpart of TableDataManagementAccess in
/// Tools for Power Users. The table holds no data. A user with Read permission on it may export and view table data; Modify
/// permission (all of insert, modify and delete) is also needed to edit, delete and import. The Orchestrator permission
/// sets grant it; Foundation's guards apply on top.
/// </summary>
table 10035631 "Table Data Access ori"
{
    Access = Internal;
    Caption = 'Table Data Management Access', Comment = 'is-IS=Aðgangur að töflugagnastjórnun';
    DataClassification = SystemMetadata;
    Extensible = false;

    fields
    {
        field(1; ID; Guid)
        {
            Caption = 'ID', Comment = 'is-IS=Auðkenni';
        }
    }

    keys
    {
        key(PK; ID)
        {
            Clustered = true;
        }
    }

    var
        ReadAccessErr: Label 'You do not have read access to table data management.', Comment = 'is-IS=Þú hefur ekki lesaðgang að töflugagnastjórnun.';
        ModifyAccessErr: Label 'You do not have modify access to table data management.', Comment = 'is-IS=Þú hefur ekki breytingaaðgang að töflugagnastjórnun.';

    /// <summary>Raises an error unless the user has read access to the table data management.</summary>
    internal procedure AssertReadAccess()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Table Data Access ori");
        if not RecRef.ReadPermission() then
            Error(ErrorInfo.Create(ReadAccessErr));
    end;

    /// <summary>Raises an error unless the user has modify access to the table data management.</summary>
    internal procedure AssertModifyAccess()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Table Data Access ori");
        if not RecRef.WritePermission() then
            Error(ErrorInfo.Create(ModifyAccessErr));
    end;
}
