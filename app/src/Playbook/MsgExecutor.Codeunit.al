namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
using System.Text;
using System.Utilities;

/// <summary>
/// Executes a single Bifrost message type in its own Codeunit.Run scope so that message types
/// which commit or fail are isolated from the surrounding playbook run. Delegates the actual
/// dispatch to the Bifrost Foundation <c>Dispatcher ori</c> codeunit. Binary responses
/// (non-text content types) are base64-encoded and wrapped in a JSON envelope.
/// </summary>
codeunit 10035603 "Msg Executor ori"
{
    Access = Internal;
    SingleInstance = true;

    trigger OnRun()
    var
        Dispatcher: Codeunit "Dispatcher ori";
        ResponseTempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        RequestContent: BigText;
        ResponseBigText: BigText;
        ResponseInStr: InStream;
        MessageVersion: Enum "Message Version ori";
    begin
        Clear(ResponseText);
        Clear(ResponseContentType);
        IsBinaryResponse := false;

        if RequestText <> '' then
            RequestContent.AddText(RequestText);

        Dispatcher.EnqueueAndProcess(MessageType, MessageVersion::"1.0", SubjectText, SourceText, 'application/json',
            RequestContent, EmptyTaskId, 0, EmptyMessageId, ResponseTempBlob, ResponseContentType, ResponseTime);

        if IsPassThroughContentType(ResponseContentType) then begin
            ResponseTempBlob.CreateInStream(ResponseInStr, TextEncoding::UTF8);
            ResponseBigText.Read(ResponseInStr);
            if ResponseBigText.Length() > 0 then
                ResponseBigText.GetSubText(ResponseText, 1);
        end else begin
            ResponseTempBlob.CreateInStream(ResponseInStr);
            ResponseText := BuildBinaryEnvelope(Base64Convert.ToBase64(ResponseInStr), ResponseContentType);
            IsBinaryResponse := true;
        end;
    end;

    /// <summary>
    /// Sets the message type, subject and request payload for the next run.
    /// </summary>
    /// <param name="NewMessageType">The registered Bifrost message type to dispatch.</param>
    /// <param name="NewSubject">Subject of the message. Pass an empty text when not applicable.</param>
    /// <param name="NewRequestText">JSON request payload. Pass an empty text when no payload is required.</param>
    procedure SetParameters(NewMessageType: Enum "Message Type ori"; NewSubject: Text; NewRequestText: Text)
    begin
        MessageType := NewMessageType;
        SubjectText := CopyStr(NewSubject, 1, MaxStrLen(SubjectText));
        SourceText := SourceTok;
        RequestText := NewRequestText;
        Clear(ResponseText);
        Clear(ResponseContentType);
        IsBinaryResponse := false;
    end;

    /// <summary>
    /// Returns the response payload produced by the last run.
    /// </summary>
    /// <returns>Response text, or a JSON envelope with base64 content for binary responses.</returns>
    procedure GetResponseText(): Text
    begin
        exit(ResponseText);
    end;

    /// <summary>
    /// Returns the MIME type of the response produced by the last run.
    /// </summary>
    /// <returns>The response content type.</returns>
    procedure GetResponseContentType(): Text[50]
    begin
        exit(ResponseContentType);
    end;

    /// <summary>
    /// Indicates whether the last response was binary and therefore base64-encoded.
    /// </summary>
    /// <returns>True when the response was binary.</returns>
    procedure GetIsBinaryResponse(): Boolean
    begin
        exit(IsBinaryResponse);
    end;

    local procedure IsPassThroughContentType(ContentType: Text[50]): Boolean
    begin
        if ContentType = '' then
            exit(true);
        if ContentType.StartsWith('text/') then
            exit(true);
        if ContentType in ['application/json', 'application/xml'] then
            exit(true);
        exit(false);
    end;

    local procedure BuildBinaryEnvelope(Base64Value: Text; ContentType: Text[50]) ResultJson: Text
    var
        ResultObject: JsonObject;
    begin
        ResultObject.Add('contentType', ContentType);
        ResultObject.Add('size', StrLen(Base64Value));
        ResultObject.Add('base64', Base64Value);
        ResultObject.WriteTo(ResultJson);
    end;

    var
        MessageType: Enum "Message Type ori";
        SubjectText: Text[250];
        SourceText: Text[250];
        RequestText: Text;
        ResponseText: Text;
        ResponseContentType: Text[50];
        ResponseTime: Duration;
        IsBinaryResponse: Boolean;
        EmptyTaskId: Guid;
        EmptyMessageId: Guid;
        SourceTok: Label 'Bifrost Orchestrator Playbook', Locked = true;
}
