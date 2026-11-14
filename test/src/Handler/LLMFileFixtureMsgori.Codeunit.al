namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using System.Text;
using System.Utilities;

/// <summary>
/// Issue #180: deterministic stand-ins for a PDF-producing step, a picture-reading step and LLM.Prompt.Complete
/// with an inline file. No provider is called. The file reader decodes the inline base64 and answers with the
/// text after the mock marker, so a test proves that the bytes of an earlier step reached the file parameter.
/// </summary>
codeunit 96482 "LLM File Fixture Msg ori" implements "Msg Interface ori", "Msg Contract ori"
{
    var
        PdfContentTok: Label '%PDF-1.4 mock The Cannon Group PLC', Locked = true;
        PictureContentTok: Label 'JFIF mock desk', Locked = true;
        MockMarkerTok: Label ' mock ', Locked = true;
        UnreadableResponseTok: Label '{"status":"Error","code":"PreconditionFailed","error":"The file could not be read.","parameter":"file","nextStep":"Send a readable PDF, PNG or JPEG file."}', Locked = true;

    /// <summary>The fixture is always available in the test app.</summary>
    procedure IsEnabled(): Boolean
    begin
        exit(true);
    end;

    /// <summary>No business table is bound to the fixture.</summary>
    procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    /// <summary>Describes the test fixture.</summary>
    procedure GetDescription(): Text[250]
    begin
        exit('Deterministic file source and inline-file reader');
    end;

    /// <summary>The fixture receives a test request.</summary>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Inbound);
    end;

    /// <summary>Returns a PDF, a picture record or the answer read from an inline file, as the request asks.</summary>
    /// <param name="Argument">Test request and response.</param>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        TempBlob: Codeunit "Temp Blob";
        Request: JsonObject;
        Token: JsonToken;
        PdfStream: OutStream;
    begin
        Request := Argument.GetRequestJson();
        if Request.Get('source', Token) then begin
            if Token.AsValue().AsText() = 'pdf' then begin
                TempBlob.CreateOutStream(PdfStream, TextEncoding::UTF8);
                PdfStream.WriteText(PdfContentTok);
                Argument.SetResponsePdf(TempBlob);
                exit;
            end;
            Argument.SetResponseText('{"status":"Success","noOfRecords":1,"result":[{"picture":"' + ToBase64(PictureContentTok) + '"}]}');
            exit;
        end;
        if Request.Get('file', Token) then
            if Token.IsObject() then begin
                ReadFile(Token.AsObject(), Argument);
                exit;
            end;
        Argument.SetResponseText(UnreadableResponseTok);
    end;

    /// <summary>The content of the PDF the source returns.</summary>
    /// <returns>The PDF text.</returns>
    procedure PdfContent(): Text
    begin
        exit(PdfContentTok);
    end;

    /// <summary>The content of the picture the source returns.</summary>
    /// <returns>The picture text.</returns>
    procedure PictureContent(): Text
    begin
        exit(PictureContentTok);
    end;

    /// <summary>Base64 of a text, as the runner stores binary output.</summary>
    /// <param name="Value">The text.</param>
    /// <returns>The base64.</returns>
    procedure ToBase64(Value: Text): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
    begin
        exit(Base64Convert.ToBase64(Value));
    end;

    local procedure ReadFile(FileJson: JsonObject; var Argument: Record "Message Argument ori")
    var
        Token: JsonToken;
        Data: Text;
        MimeType: Text;
        Content: Text;
        Reply: JsonObject;
        ReplyText: Text;
    begin
        if FileJson.Get('data', Token) then
            Data := Token.AsValue().AsText();
        if FileJson.Get('mimeType', Token) then
            MimeType := Token.AsValue().AsText();
        if (Data = '') or not (MimeType in ['application/pdf', 'image/png', 'image/jpeg']) or not TryDecode(Data, Content) then begin
            Argument.SetResponseText(UnreadableResponseTok);
            exit;
        end;
        if (MimeType = 'application/pdf') and not Content.StartsWith('%PDF') then begin
            Argument.SetResponseText(UnreadableResponseTok);
            exit;
        end;
        if not Content.Contains(MockMarkerTok) then begin
            Argument.SetResponseText(UnreadableResponseTok);
            exit;
        end;
        Reply.Add('status', 'Success');
        Reply.Add('reply', CopyStr(Content, Content.IndexOf(MockMarkerTok) + StrLen(MockMarkerTok)));
        Reply.WriteTo(ReplyText);
        Argument.SetResponseText(ReplyText);
    end;

    [TryFunction]
    local procedure TryDecode(Data: Text; var Content: Text)
    var
        Base64Convert: Codeunit "Base64 Convert";
    begin
        Content := Base64Convert.FromBase64(Data);
    end;

    /// <summary>Declares the test request envelope.</summary>
    /// <param name="Envelope">Receives the envelope.</param>
    /// <returns>True; the fixture has a contract.</returns>
    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Subject: JsonObject;
    begin
        Subject.Add('use', 'notUsed');
        Envelope.Add('subject', Subject);
        Envelope.Add('dataRequired', false);
        Envelope.Add('version', '1.0');
        Envelope.Add('contentType', 'text/json');
        exit(true);
    end;

    /// <summary>Declares the fixture parameters.</summary>
    /// <param name="Parameters">Receives the fixture parameters.</param>
    /// <returns>True; no other request parameters are accepted.</returns>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('source', 'string', false, 'pdf returns a PDF; picture returns a record with a base64 picture.'));
        Parameters.Add(ContractMgt.Parameter('prompt', 'string', false, 'Fixture prompt.'));
        Parameters.Add(ContractMgt.Parameter('file', 'object', false, 'Inline file with data, mimeType and fileName.'));
        exit(true);
    end;

    /// <summary>The fixture returns constant data and changes no business records.</summary>
    /// <param name="Effect">Receives the effect.</param>
    /// <returns>True; the fixture is read-only.</returns>
    procedure GetEffect(var Effect: JsonObject): Boolean
    begin
        Effect.Add('effect', 'read');
        Effect.Add('changes', 'Returns deterministic test data; no business records change.');
        Effect.Add('idempotent', true);
        exit(true);
    end;

    /// <summary>No additional target chapter is required by the fixture.</summary>
    /// <param name="Target">Unused optional chapter.</param>
    /// <returns>False; this chapter is absent.</returns>
    procedure GetTarget(var Target: JsonArray): Boolean
    begin
        exit(false);
    end;

    /// <summary>No additional response chapter is required by the fixture.</summary>
    /// <param name="Response">Unused optional chapter.</param>
    /// <returns>False; this chapter is absent.</returns>
    procedure GetResponse(var Response: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>No additional errors chapter is required by the fixture.</summary>
    /// <param name="Errors">Unused optional chapter.</param>
    /// <returns>False; this chapter is absent.</returns>
    procedure GetErrors(var Errors: JsonArray): Boolean
    begin
        exit(false);
    end;

    /// <summary>No additional metering chapter is required by the fixture.</summary>
    /// <param name="Metering">Unused optional chapter.</param>
    /// <returns>False; this chapter is absent.</returns>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>No additional related chapter is required by the fixture.</summary>
    /// <param name="Related">Unused optional chapter.</param>
    /// <returns>False; this chapter is absent.</returns>
    procedure GetRelated(var Related: JsonArray): Boolean
    begin
        exit(false);
    end;

    /// <summary>No additional workflow chapter is required by the fixture.</summary>
    /// <param name="Workflow">Unused optional chapter.</param>
    /// <returns>False; this chapter is absent.</returns>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>No additional examples chapter is required by the fixture.</summary>
    /// <param name="Examples">Unused optional chapter.</param>
    /// <returns>False; this chapter is absent.</returns>
    procedure GetExamples(var Examples: JsonArray): Boolean
    begin
        exit(false);
    end;

    /// <summary>No additional overview chapter is required by the fixture.</summary>
    /// <param name="Overview">Unused optional chapter.</param>
    /// <returns>False; this chapter is absent.</returns>
    procedure GetOverview(var Overview: Text): Boolean
    begin
        Clear(Overview);
        exit(false);
    end;

    /// <summary>No additional notes chapter is required by the fixture.</summary>
    /// <param name="Notes">Unused optional chapter.</param>
    /// <returns>False; this chapter is absent.</returns>
    procedure GetNotes(var Notes: Text): Boolean
    begin
        Clear(Notes);
        exit(false);
    end;
}
