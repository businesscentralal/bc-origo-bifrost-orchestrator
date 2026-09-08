/// <summary>
/// HTTP client for calling the Job Queue Orchestrator API as an Entra application
/// using OAuth2 client credentials flow.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using System.Azure.Identity;
using System.Environment;
using System.Security.Authentication;

codeunit 10035545 "Scheduler API Client ori"
{
    Access = Internal;

    var
        ClientCredentials: Record "Client Credentials ori";
        AccessToken: SecretText;
        TokenExpiry: DateTime;
        FailedToAcquireTokenErr: Label 'Failed to acquire OAuth2 token for client credentials code %1.', Comment = '%1 = Client Credentials Code||is-IS=Ekki tókst að sækja OAuth2-tóka fyrir auðkenniskóða %1.';
        ApiCallNoResponseErr: Label 'No response received from API call for orchestrator entry %1.', Comment = '%1 = Orchestrator Entry ID||is-IS=Ekkert svar barst frá API-kalli fyrir vinnsluraðarafærslu %1.';
        MicrosoftLoginUrlTok: Label 'https://login.microsoftonline.com/', Locked = true;
        OAuth2TokenPathTok: Label '/oauth2/v2.0/token', Locked = true;
        BusinessCentralDefaultScopeTok: Label 'https://api.businesscentral.dynamics.com/.default', Locked = true;

    /// <summary>
    /// Initializes the API client with the client credentials from the given orchestrator entry.
    /// </summary>
    /// <param name="Scheduled Entry ori">The orchestrator entry whose client credentials to use.</param>
    /// <returns>True if the entry has client credentials configured.</returns>
    [NonDebuggable]
    internal procedure Initialize("Scheduled Entry ori": Record "Scheduled Entry ori"): Boolean
    begin
        Clear(AccessToken);
        Clear(TokenExpiry);

        if "Scheduled Entry ori"."Client Credentials Code" = '' then
            exit(false);

        ClientCredentials.SetLoadFields(Code);
        if not ClientCredentials.Get("Scheduled Entry ori"."Client Credentials Code") then
            exit(false);

        exit(ClientCredentials.IsComplete());
    end;

    /// <summary>
    /// Calls the UpdateJobQueueEntry action on the Orchestrator Entries API as the Entra application.
    /// </summary>
    /// <param name="Scheduled Entry ori">The orchestrator entry to update.</param>
    [NonDebuggable]
    internal procedure CallUpdateJobQueueEntry("Scheduled Entry ori": Record "Scheduled Entry ori")
    var
        ActionUrl: Text;
    begin
        ActionUrl := BuildActionUrl("Scheduled Entry ori".ID, 'scheduledEntries', 'UpdateJobQueueEntry');
        PostAction(ActionUrl, "Scheduled Entry ori".ID);
    end;

    /// <summary>
    /// Calls the RestartJobQueueEntry action on the Orchestrator Entries API as the Entra application.
    /// </summary>
    /// <param name="Scheduled Entry ori">The orchestrator entry whose Job Queue Entry to restart.</param>
    [NonDebuggable]
    internal procedure CallRestartJobQueueEntry("Scheduled Entry ori": Record "Scheduled Entry ori")
    var
        ActionUrl: Text;
    begin
        ActionUrl := BuildActionUrl("Scheduled Entry ori".ID, 'scheduledEntries', 'RestartJobQueueEntry');
        PostAction(ActionUrl, "Scheduled Entry ori".ID);
    end;

    /// <summary>
    /// Calls the SetStatusToReady action on the Orchestrator Entries API as the Entra application.
    /// </summary>
    /// <param name="Scheduled Entry ori">The orchestrator entry whose Job Queue Entry status to set to Ready.</param>
    [NonDebuggable]
    internal procedure CallSetStatusToReady("Scheduled Entry ori": Record "Scheduled Entry ori")
    var
        ActionUrl: Text;
    begin
        ActionUrl := BuildActionUrl("Scheduled Entry ori".ID, 'scheduledEntries', 'SetStatusToReady');
        PostAction(ActionUrl, "Scheduled Entry ori".ID);
    end;

    [NonDebuggable]
    local procedure PostAction(ActionUrl: Text; EntryId: Guid)
    var
        HttpClient: HttpClient;
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        RequestHeaders: HttpHeaders;
        Token: SecretText;
        CustomDimensions: Dictionary of [Text, Text];
        ApiCallTok: Label 'API Call', Locked = true;
    begin
        Token := AcquireToken();
        if Token.IsEmpty() then begin
            LogApiError(EntryId, FailedToAcquireTokenErr, ClientCredentials.Code);
            exit;
        end;

        HttpRequest.SetRequestUri(ActionUrl);
        HttpRequest.Method := 'POST';
        HttpRequest.GetHeaders(RequestHeaders);
        RequestHeaders.Add('Authorization', SecretStrSubstNo('Bearer %1', Token));

        if not HttpClient.Send(HttpRequest, HttpResponse) then
            LogApiError(EntryId, ApiCallNoResponseErr, Format(EntryId, 0, 4));

        if not HttpResponse.IsSuccessStatusCode() then begin
            CustomDimensions.Add('StatusCode', Format(HttpResponse.HttpStatusCode(), 0, 9));
            CustomDimensions.Add('EntryId', Format(EntryId, 0, 4));
            CustomDimensions.Add('ActionUrl', ActionUrl);
            Session.LogMessage('O4NJQS-0010', ApiCallTok, Verbosity::Error,
                DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
        end;
    end;

    [NonDebuggable]
    local procedure AcquireToken(): SecretText
    var
        Secrets: Codeunit "Secrets ori";
        ClientIdValue: SecretText;
        ClientSecret: SecretText;
        TokenValue: SecretText;
        TokenCacheAcquiredTok: Label 'Token acquired from cache', Locked = true;
        TokenAcquiredTok: Label 'Token acquired', Locked = true;
    begin
        if (not AccessToken.IsEmpty()) and (TokenExpiry > CurrentDateTime) then begin
            Session.LogMessage('O4NJQS-0011', TokenCacheAcquiredTok, Verbosity::Verbose,
                DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher,
                'Source', 'TokenCache');
            exit(AccessToken);
        end;

        if not Secrets.TryGetClientId(ClientCredentials.Code, ClientIdValue) then
            exit;
        if not Secrets.TryGetClientSecret(ClientCredentials.Code, ClientSecret) then
            exit;

        if not RequestClientCredentialsToken(ClientIdValue, ClientSecret, TokenValue) then
            exit;
        if TokenValue.IsEmpty() then
            exit;

        AccessToken := TokenValue;
        TokenExpiry := CurrentDateTime + (3500 * 1000);

        Session.LogMessage('O4NJQS-0012', TokenAcquiredTok, Verbosity::Normal,
            DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher,
            'Source', 'OAuth2');
        exit(AccessToken);
    end;

    /// <summary>
    /// Runs the OAuth 2.0 client credentials grant against the Microsoft Entra token endpoint.
    /// The request is built by hand rather than with codeunit OAuth2 because every OAuth2 overload
    /// takes the client id as Text, while the client id of a Bifrost Orchestrator credential lives in the
    /// Bifröst secret store and is only available as SecretText - SecretText.Unwrap is not allowed
    /// in Cloud extensions. The form body is composed with SecretStrSubstNo so neither the client id
    /// nor the client secret is ever materialised as Text.
    /// </summary>
    [NonDebuggable]
    local procedure RequestClientCredentialsToken(ClientIdValue: SecretText; ClientSecret: SecretText; var TokenValue: SecretText): Boolean
    var
        TokenClient: HttpClient;
        RequestContent: HttpContent;
        ContentHeaders: HttpHeaders;
        TokenResponse: HttpResponseMessage;
        ResponseJson: JsonObject;
        AccessTokenToken: JsonToken;
        RequestBody: SecretText;
        ScopeValue: SecretText;
        ResponseText: Text;
        ScopeText: Text;
        FormUrlEncodedTok: Label 'application/x-www-form-urlencoded', Locked = true;
        ContentTypeTok: Label 'Content-Type', Locked = true;
        AccessTokenPropertyTok: Label 'access_token', Locked = true;
        TokenRequestBodyTok: Label 'grant_type=client_credentials&client_id=%1&client_secret=%2&scope=%3', Locked = true;
    begin
        ScopeText := BusinessCentralDefaultScopeTok;
        ScopeValue := ScopeText;
        RequestBody := SecretStrSubstNo(TokenRequestBodyTok, ClientIdValue, ClientSecret, ScopeValue);
        RequestContent.WriteFrom(RequestBody);
        RequestContent.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains(ContentTypeTok) then
            ContentHeaders.Remove(ContentTypeTok);
        ContentHeaders.Add(ContentTypeTok, FormUrlEncodedTok);

        if not TokenClient.Post(GetAuthorityUrl(), RequestContent, TokenResponse) then
            exit(false);
        if not TokenResponse.IsSuccessStatusCode() then
            exit(false);
        if not TokenResponse.Content().ReadAs(ResponseText) then
            exit(false);
        if not ResponseJson.ReadFrom(ResponseText) then
            exit(false);
        if not ResponseJson.Get(AccessTokenPropertyTok, AccessTokenToken) then
            exit(false);

        TokenValue := AccessTokenToken.AsValue().AsText();
        exit(true);
    end;

    local procedure GetAuthorityUrl(): Text
    var
        AzureAdTenant: Codeunit "Azure AD Tenant";
        AadTenantId: Text;
    begin
        AadTenantId := AzureAdTenant.GetAadTenantId();
        exit(MicrosoftLoginUrlTok + AadTenantId + OAuth2TokenPathTok);
    end;

    local procedure BuildActionUrl(EntryId: Guid; APIPageName: Text; ActionName: Text) APIUrl: Text
    var
        Company: Record Company;
        APIUrlTok: Label 'origo/jobQueueOrchestrator/v1.0/companies(%1)/%2(%3)/Microsoft.NAV.%4', Locked = true;
    begin
        Company.Get(CompanyName);
        APIUrl := GetUrl(ClientType::Api);
        if APIUrl.IndexOf('?') > 0 then
            APIUrl := APIUrl.Substring(1, APIUrl.IndexOf('?') - 1) + StrSubstNo(APIUrlTok, Format(Company.Id).TrimStart('{').TrimEnd('}'), APIPageName, Format(EntryId, 0, 4), ActionName) + APIUrl.Substring(APIUrl.IndexOf('?'))
        else
            APIUrl += StrSubstNo(APIUrlTok, Format(Company.Id).TrimStart('{').TrimEnd('}'), APIPageName, Format(EntryId, 0, 4), ActionName);
    end;

    local procedure LogApiError(EntryId: Guid; ErrorMsg: Text; Param: Text)
    var
        CustomDimensions: Dictionary of [Text, Text];
        ApiErrorTok: Label 'API Error', Locked = true;
    begin
        CustomDimensions.Add('EntryId', Format(EntryId, 0, 4));
        CustomDimensions.Add('ErrorMessage', StrSubstNo(ErrorMsg, Param));
        Session.LogMessage('O4NJQS-0013', ApiErrorTok, Verbosity::Error,
            DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
    end;
}
