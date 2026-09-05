namespace Origo.Bifrost.Nornir;

/// <summary>
/// Stores OAuth 2.0 client credentials (client_id and client_secret) pairs,
/// identified by a unique Code and Description for use in Job Queue Orchestrator lines.
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
        field(30; "Client ID"; Guid)
        {
            Caption = 'Client ID', Comment = 'is-IS=Auðkenni biðlara';
            DataClassification = SystemMetadata;
        }
        field(40; "Client Secret"; Guid)
        {
            Caption = 'Client Secret', Comment = 'is-IS=Leyniorð biðlara';
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

    var
        UnableToSetClientIdMsg: Label 'Unable to set Client Id', Comment = 'is-IS=Ekki tókst að setja auðkenni biðlara';
        UnableToGetClientIdMsg: Label 'Unable to get Client Id', Comment = 'is-IS=Ekki tókst að sækja auðkenni biðlara';
        UnableToSetClientSecretMsg: Label 'Unable to set Client Secret', Comment = 'is-IS=Ekki tókst að setja leyniorð biðlara';
        UnableToGetClientSecretMsg: Label 'Unable to get Client Secret', Comment = 'is-IS=Ekki tókst að sækja leyniorð biðlara';

    trigger OnDelete()
    begin
        if not IsNullGuid(Rec."Client ID") then
            if IsolatedStorage.Delete(Format(Rec."Client ID"), DataScope::Company) then;
        if not IsNullGuid(Rec."Client Secret") then
            if IsolatedStorage.Delete(Format(Rec."Client Secret"), DataScope::Company) then;
    end;

    [NonDebuggable]
    internal procedure SetClientId(ClientId: Text)
    begin
        if ClientId = '' then begin
            if not IsNullGuid(Rec."Client ID") then
                if IsolatedStorage.Delete(Format(Rec."Client ID"), DataScope::Company) then;
            exit;
        end;

        if IsNullGuid(Rec."Client ID") then
            Rec."Client ID" := CreateGuid();

        if not IsolatedStorage.Set(Format(Rec."Client ID"), ClientId, DataScope::Company) then
            Error(UnableToSetClientIdMsg);
    end;

    [NonDebuggable]
    internal procedure GetClientId(ClientIdKey: Guid) ClientId: Text
    begin
        if not IsolatedStorage.Get(Format(ClientIdKey), DataScope::Company, ClientId) then
            Error(UnableToGetClientIdMsg);
    end;

    [NonDebuggable]
    internal procedure SetClientSecret(ClientSecret: SecretText)
    begin
        if ClientSecret.IsEmpty() then begin
            if not IsNullGuid(Rec."Client Secret") then
                if IsolatedStorage.Delete(Format(Rec."Client Secret"), DataScope::Company) then;
            exit;
        end;

        if IsNullGuid(Rec."Client Secret") then
            Rec."Client Secret" := CreateGuid();

        if not IsolatedStorage.Set(Format(Rec."Client Secret"), ClientSecret, DataScope::Company) then
            Error(UnableToSetClientSecretMsg);
    end;

    [NonDebuggable]
    internal procedure GetClientSecret(ClientSecretKey: Guid) ClientSecret: SecretText
    begin
        if not IsolatedStorage.Get(Format(ClientSecretKey), DataScope::Company, ClientSecret) then
            Error(UnableToGetClientSecretMsg);
    end;
}
