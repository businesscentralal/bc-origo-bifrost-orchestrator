/// <summary>
/// Runtime execution log for a playbook run. Created when a playbook starts, updated
/// as steps execute, finalized when the playbook completes or fails.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

table 10035542 "Playbook Instance ori"
{
    Caption = 'Bifrost Playbook Instance', Comment = 'is-IS=Keyrsla Bifröst keðju';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; ID; Guid)
        {
            Caption = 'ID', Comment = 'is-IS=Auðkenni';
        }
        field(10; "Playbook Code"; Code[20])
        {
            Caption = 'Playbook Code', Comment = 'is-IS=Kóði keðju';
            TableRelation = "Playbook ori".Code;
        }
        field(20; Status; Enum "Playbook Inst. Status ori")
        {
            Caption = 'Status', Comment = 'is-IS=Staða';
        }
        field(30; "Started At"; DateTime)
        {
            Caption = 'Started At', Comment = 'is-IS=Byrjaði';
        }
        field(31; "Completed At"; DateTime)
        {
            Caption = 'Completed At', Comment = 'is-IS=Lauk';
        }
        field(32; "Total Duration"; Duration)
        {
            Caption = 'Total Duration', Comment = 'is-IS=Heildartími';
        }
        field(40; "Steps Executed"; Integer)
        {
            Caption = 'Steps Executed', Comment = 'is-IS=Skref keyrð';
        }
        field(41; "Steps Failed"; Integer)
        {
            Caption = 'Steps Failed', Comment = 'is-IS=Skref mistókst';
        }
        field(42; "Items Processed"; Integer)
        {
            Caption = 'Items Processed', Comment = 'is-IS=Hlutir unnir';
        }
        field(50; "Initiated By"; Guid)
        {
            Caption = 'Initiated By', Comment = 'is-IS=Keyrt af';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(60; "Error Text"; Text[2048])
        {
            Caption = 'Error Text', Comment = 'is-IS=Villuboð';
        }
        field(70; Context; Blob)
        {
            Caption = 'Context', Comment = 'is-IS=Samhengi';
            // Holds the playbook's initial request payload, which routinely carries customer data.
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; ID)
        {
            Clustered = true;
        }
        key(PlaybookDate; "Playbook Code", "Started At")
        {
        }
    }
}
