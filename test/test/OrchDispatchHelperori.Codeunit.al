namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using System.Text;
using System.Utilities;

/// <summary>
/// Runs an Orchestrator message type through Foundation's dispatcher, the only path that marks a call as licensed
/// (Argument.SetLicensed is internal to Foundation). Calling the implementation directly is refused by AssertIsLicensed.
/// </summary>
codeunit 96457 "Orch Dispatch Helper ori"
{
    /// <summary>Dispatches the request held in the argument and writes the response back into it.</summary>
    /// <param name="MessageType">The registered message type to run.</param>
    /// <param name="TempArgument">Temporary argument carrying the request JSON; receives the response and content type.</param>
    procedure Execute(MessageType: Enum "Message Type ori"; var TempArgument: Record "Message Argument ori" temporary)
    var
        RequestJson: JsonObject;
        ExpectedCount: Integer;
    begin
        RequestJson := TempArgument.GetRequestJson();
        Dispatch(MessageType, RequestJson, TempArgument);
        // Foundation refuses an irreversible call until the caller repeats it with the announced expectedCount.
        // Callers do exactly that, so the helper repeats the request once with the count the refusal names.
        if not GetExpectedCountFromConfirmation(TempArgument, ExpectedCount) then
            exit;
        if RequestJson.Contains('expectedCount') then
            RequestJson.Replace('expectedCount', ExpectedCount)
        else
            RequestJson.Add('expectedCount', ExpectedCount);
        Dispatch(MessageType, RequestJson, TempArgument);
    end;

    local procedure GetExpectedCountFromConfirmation(var TempArgument: Record "Message Argument ori" temporary; var ExpectedCount: Integer): Boolean
    var
        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        if not IsTextContent(TempArgument."Content Type") then
            exit(false);
        ResponseJson := TempArgument.GetResponseJson();
        if not ResponseJson.Get('code', Token) then
            exit(false);
        if Token.AsValue().AsText() <> 'ConfirmationRequired' then
            exit(false);
        if not ResponseJson.Get('expected', Token) then
            exit(false);
        exit(Evaluate(ExpectedCount, Token.AsValue().AsText()));
    end;

    local procedure Dispatch(MessageType: Enum "Message Type ori"; RequestJson: JsonObject; var TempArgument: Record "Message Argument ori" temporary)
    var
        Dispatcher: Codeunit "Dispatcher ori";
        ResponseTempBlob: Codeunit "Temp Blob";
        RequestContent: BigText;
        ResponseBigText: BigText;
        ResponseText: Text;
        ResponseContentType: Text[100];
        ResponseTime: Duration;
        EmptyTaskId: Guid;
        MessageId: Guid;
        RequestText: Text;
        ResponseJson: JsonObject;
        ResponseInStr: InStream;
        ContentOutStr: OutStream;
    begin
        RequestJson.WriteTo(RequestText);
        RequestContent.AddText(RequestText);

        Dispatcher.EnqueueAndProcess(MessageType, "Message Version ori"::"1.0", TempArgument.Subject, '', 'text/json', RequestContent, EmptyTaskId, 1033, MessageId, ResponseTempBlob, ResponseContentType, ResponseTime);

        TempArgument."Content Type" := ResponseContentType;
        if IsTextContent(ResponseContentType) then begin
            ResponseTempBlob.CreateInStream(ResponseInStr, TextEncoding::UTF8);
            ResponseBigText.Read(ResponseInStr);
            if ResponseBigText.Length() > 0 then
                ResponseBigText.GetSubText(ResponseText, 1);
            if ResponseJson.ReadFrom(ResponseText) then
                TempArgument.SetResponseJson(ResponseJson)
            else
                TempArgument.SetResponseText(ResponseText);
            TempArgument."Content Type" := ResponseContentType;
        end else begin
            ResponseTempBlob.CreateInStream(ResponseInStr);
            TempArgument."Response Content".CreateOutStream(ContentOutStr);
            CopyStream(ContentOutStr, ResponseInStr);
        end;
        TempArgument.Modify();
    end;

    /// <summary>Dispatches like Execute and raises the response error text when the dispatcher returns a failure.</summary>
    /// <param name="MessageType">The registered message type to run.</param>
    /// <param name="TempArgument">Temporary argument carrying the request JSON.</param>
    procedure ExecuteExpectingError(MessageType: Enum "Message Type ori"; var TempArgument: Record "Message Argument ori" temporary)
    var
        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        Execute(MessageType, TempArgument);
        ResponseJson := TempArgument.GetResponseJson();
        if ResponseJson.Get('status', Token) then
            if Token.AsValue().AsText() = 'Error' then begin
                ResponseJson.Get('error', Token);
                Error(Token.AsValue().AsText());
            end;
    end;

    local procedure IsTextContent(ContentType: Text): Boolean
    begin
        exit((ContentType = '') or ContentType.StartsWith('text/') or (ContentType in ['application/json', 'application/xml']));
    end;
}
