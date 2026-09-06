namespace Origo.Bifrost.Orchestrator;

codeunit 10035586 "Telegram Send ori"
{
    Access = Internal;

    [NonDebuggable]
    internal procedure SendMessage(BotToken: SecretText; ChatId: Text; MessageText: Text): Boolean
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

    internal procedure GetLastResponse(): Text
    begin
        exit(LastResponseText);
    end;

    var
        ApiUrlTok: Label 'https://api.telegram.org/bot%1/sendMessage', Locked = true;
        LastResponseText: Text;
}
