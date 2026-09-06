namespace Origo.Bifrost.Orchestrator;

/// <summary>
/// Names the OAuth 2.0 client credentials (client_id and client_secret) pairs used by Job Queue
/// Orchestrator lines. The record itself only carries the code and the description: the two values
/// live in the Bifröst Foundation secret store under the codes
/// <c>CREDENTIAL-&lt;Code&gt;-CLIENT-ID</c> and <c>CREDENTIAL-&lt;Code&gt;-CLIENT-SECRET</c>, both with scope
/// Company. Codeunit <c>Secrets ori</c> composes the codes and reaches the store.
/// </summary>
table 10035538 "Client Credentials ori"
{
    Caption = 'Client Credentials', Comment = 'is-IS=Auðkenni biðlara';
    DataClassification = SystemMetadata;

    fields
    {
        field(10; Code; Code[50])
        {
            Caption = 'Code', Comment = 'is-IS=Kóði';
            DataClassification = SystemMetadata;
            NotBlank = true;
        }
        field(20; Description; Text[250])
        {
            Caption = 'Description', Comment = 'is-IS=Lýsing';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    var
        Secrets: Codeunit "Secrets ori";
    begin
        Secrets.RegisterCredential(Rec.Code);
    end;

    trigger OnRename()
    var
        Secrets: Codeunit "Secrets ori";
    begin
        Secrets.RenameCredential(xRec.Code, Rec.Code);
    end;

    trigger OnDelete()
    var
        Secrets: Codeunit "Secrets ori";
    begin
        Secrets.ClearCredential(Rec.Code);
    end;

    /// <summary>
    /// Reports whether both the client id and the client secret of this record have been entered.
    /// </summary>
    /// <returns>Boolean. True when both values are stored.</returns>
    internal procedure IsComplete(): Boolean
    var
        Secrets: Codeunit "Secrets ori";
    begin
        exit(Secrets.IsClientIdSet(Rec.Code) and Secrets.IsClientSecretSet(Rec.Code));
    end;
}
