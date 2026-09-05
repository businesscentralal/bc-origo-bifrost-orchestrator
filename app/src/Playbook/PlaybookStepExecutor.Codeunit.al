namespace Origo.Bifrost.Nornir;

using Origo.Bifrost;

/// <summary>
/// Executes a single message type through <see cref="Msg Executor ori"/>, which wraps the
/// Bifrost Foundation dispatcher in a Codeunit.Run scope. The isolation keeps a message type
/// that commits or fails from aborting the surrounding playbook run; binary responses are
/// returned base64-encoded in a JSON envelope.
/// </summary>
codeunit 10035572 "Playbook Step Executor ori"
{
    Access = Internal;

    /// <summary>
    /// Runs one playbook step by dispatching the given message type.
    /// </summary>
    /// <param name="MessageType">The Bifrost message type to execute.</param>
    /// <param name="Subject">Subject of the message. Pass an empty text when not applicable.</param>
    /// <param name="RequestText">JSON request payload. Pass an empty text when no payload is required.</param>
    /// <param name="ResponseText">Receives the response payload, or the error text when the step failed.</param>
    /// <param name="ErrorText">Receives the error text when the step failed.</param>
    /// <returns>True when the message type executed without raising an error.</returns>
    procedure Execute(MessageType: Enum "Message Type ori"; Subject: Text; RequestText: Text; var ResponseText: Text; var ErrorText: Text): Boolean
    var
        MsgExecutor: Codeunit "Msg Executor ori";
        IsError: Boolean;
        StartTime: DateTime;
    begin
        StartTime := CurrentDateTime();

        MsgExecutor.SetParameters(MessageType, ResolveSubject(Subject, RequestText), RequestText);
        if not MsgExecutor.Run() then begin
            ResponseText := GetLastErrorText();
            IsError := true;
        end else
            ResponseText := MsgExecutor.GetResponseText();

        if IsError then
            ErrorText := ResponseText;

        LogStep(Format(MessageType), RequestText, ResponseText, not IsError, ErrorText, CurrentDateTime() - StartTime);
        exit(not IsError);
    end;

    local procedure LogStep(MessageType: Text; RequestText: Text; ResponseText: Text; Success: Boolean; ErrorText: Text; Elapsed: Duration)
    var
        Setup: Record "Setup ori";
        Logger: Codeunit "Request Logger ori";
    begin
        Setup.SetLoadFields("Request Debug Mode");
        if not Setup.Get() then
            exit;
        if not Setup."Request Debug Mode" then
            exit;

        Logger.Log(
            CopyStr(MessageType, 1, 50),
            'PLAY',
            '',
            'Bifrost Nornir Playbook Runner',
            0,
            Elapsed,
            Success,
            ErrorText,
            RequestText,
            ResponseText,
            Enum::"Request Log Type ori"::"Nornir Playbook");
        Logger.Insert();
    end;

    local procedure ResolveSubject(Subject: Text; RequestText: Text): Text
    var
        RequestJson: JsonObject;
        SubjectToken: JsonToken;
    begin
        if Subject <> '' then
            exit(Subject);
        if RequestText = '' then
            exit('');
        if not RequestJson.ReadFrom(RequestText) then
            exit('');
        if not RequestJson.Get('subject', SubjectToken) then
            exit('');
        if SubjectToken.IsValue() then
            exit(SubjectToken.AsValue().AsText());
    end;
}
