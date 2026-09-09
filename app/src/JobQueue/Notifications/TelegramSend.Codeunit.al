namespace Origo.Bifrost.Orchestrator;

codeunit 10035586 "Telegram Send ori"
{
    Access = Internal;

    /// <summary>
    /// Posts one HTML-formatted message to the Telegram sendMessage endpoint. The bot token goes
    /// into the request URI through <c>SetSecretRequestUri</c>, so it never reaches the telemetry
    /// or the error text. A transport failure is not thrown: it is stored as the last response and
    /// reported as false, so a failing notification never brings down the job it reports on.
    /// </summary>
    /// <param name="BotToken">The bot token from the secret store; substituted into the API URL.</param>
    /// <param name="ChatId">The Telegram chat that receives the message.</param>
    /// <param name="MessageText">The message body. Sent with parse mode HTML.</param>
    /// <returns>Boolean. True when Telegram answered with a success status code.</returns>
    [NonDebuggable]
    procedure SendMessage(BotToken: SecretText; ChatId: Text; MessageText: Text): Boolean
    var
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        HttpHeaders: HttpHeaders;
        RequestJson: JsonObject;
        RequestText: Text;
        ResponseText: Text;
    begin
        RequestJson.Add('chat_id', ChatId);
        RequestJson.Add('text', MessageText);
        RequestJson.Add('parse_mode', 'HTML');
        RequestJson.WriteTo(RequestText);

        HttpContent.WriteFrom(RequestText);
        HttpContent.GetHeaders(HttpHeaders);
        HttpHeaders.Remove('Content-Type');
        HttpHeaders.Add('Content-Type', 'application/json');

        HttpRequestMessage.Method('POST');
        HttpRequestMessage.SetSecretRequestUri(SecretStrSubstNo(ApiUrlTok, BotToken));
        HttpRequestMessage.Content(HttpContent);

        if not HttpClient.Send(HttpRequestMessage, HttpResponse) then begin
            LastResponseText := GetLastErrorText();
            exit(false);
        end;

        HttpResponse.Content.ReadAs(ResponseText);
        LastResponseText := ResponseText;
        exit(HttpResponse.IsSuccessStatusCode());
    end;

    /// <summary>
    /// Returns what the last <c>SendMessage</c> call left behind: the Telegram response body, or
    /// the error text when the request never got through. This is how the caller finds out why a
    /// send returned false.
    /// </summary>
    /// <returns>Text. The last response body or error text, empty before the first send.</returns>
    procedure GetLastResponse(): Text
    begin
        exit(LastResponseText);
    end;

    var
        ApiUrlTok: Label 'https://api.telegram.org/bot%1/sendMessage', Locked = true;
        LastResponseText: Text;
}
