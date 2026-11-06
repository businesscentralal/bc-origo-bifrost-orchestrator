namespace Origo.Bifrost.Orchestrator.Test;

/// <summary>Owned scratch records for copy-plan acceptance; never customer data.</summary>
table 96449 "Test Copy Parent ori"
{
    DataClassification = CustomerContent;
    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Description; Text[100]) { }
        field(3; Amount; Decimal) { }
    }
    keys { key(PK; Code) { Clustered = true; } }
}
