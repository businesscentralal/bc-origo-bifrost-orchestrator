namespace Origo.Bifrost.Nornir.Test;

using Origo.Bifrost.Nornir;
/// <summary>Marker written by the sample processing-only report, so tests can prove it ran.</summary>
table 96450 "Test Run Marker"
{
    Caption = 'Bifrost Test Run Marker';
    DataClassification = SystemMetadata;
    InherentEntitlements = X;
    InherentPermissions = X;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; Source; Text[50])
        {
            Caption = 'Source';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
