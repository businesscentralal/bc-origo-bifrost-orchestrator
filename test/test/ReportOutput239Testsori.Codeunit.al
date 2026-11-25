namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.TestLibraries.Utilities;

/// <summary>Issue 239: output MIME types, byte lengths and refusal boundaries with owned report fixtures.</summary>
codeunit 96464 "Report Output 239 Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    /// <summary>AC01: all four formats declare their real MIME type and retain their bytes in English.</summary>
    [Test]
    procedure FormatsEnglish()
    begin
        VerifyFormats(1033);
    end;

    /// <summary>AC01: all four formats declare the same MIME types and byte lengths in Icelandic.</summary>
    [Test]
    procedure FormatsIcelandic()
    begin
        VerifyFormats(1039);
    end;

    /// <summary>Omitting format retains the existing PDF default.</summary>
    [Test]
    procedure OmittedFormatDefaultsToPdf()
    begin
        VerifyOutput('', 'application/pdf', '%PDF', 1033);
    end;

    /// <summary>Case-insensitive format parsing also selects the matching MIME type.</summary>
    [Test]
    procedure MixedCaseFormatSelectsWordMime()
    begin
        VerifyOutput('wOrD', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'PK', 1039);
    end;

    /// <summary>Invalid formats are refused before producing output, in both languages.</summary>
    [Test]
    procedure UnsupportedFormatIsRefused()
    begin
        VerifyRefusal('{"reportId":96455,"format":"CSV","tableView":"WHERE(Number=CONST(1))"}', 1033);
        VerifyRefusal('{"reportId":96455,"format":"CSV","tableView":"WHERE(Number=CONST(1))"}', 1039);
    end;

    /// <summary>A missing report cannot be mistaken for a successfully rendered document.</summary>
    [Test]
    procedure MissingReportIsRefused()
    begin
        VerifyRefusal('{"format":"Word"}', 1033);
        VerifyRefusal('{"format":"Word"}', 1039);
    end;

    /// <summary>Both help chapters expose the exact mapping and explain the MCP size follow-up.</summary>
    [Test]
    procedure HelpDescribesFormatsAndSizeFollowUp()
    var
        SaveMsg: Codeunit "Report SaveAs Msg ori";
        Chapter: JsonObject;
        Token: JsonToken;
        Mapping: JsonObject;
        Notes: Text;
        PriorLanguage: Integer;
    begin
        SaveMsg.GetEnvelope(Chapter);
        Chapter.Get('contentTypesByFormat', Token);
        Mapping := Token.AsObject();
        AssertMapping(Mapping);
        Clear(Chapter);
        SaveMsg.GetResponse(Chapter);
        Chapter.Get('contentTypesByFormat', Token);
        Mapping := Token.AsObject();
        AssertMapping(Mapping);
        PriorLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        SaveMsg.GetNotes(Notes);
        GlobalLanguage(PriorLanguage);
        Assert.IsTrue(Notes.Contains('byte length'), 'Help defines size as bytes');
        Assert.IsTrue(Notes.Contains('mcp-stateless#265'), 'Help names the runtime follow-up');
        GlobalLanguage(1039);
        SaveMsg.GetNotes(Notes);
        GlobalLanguage(PriorLanguage);
        Assert.IsTrue(Notes.Contains('bætafjöldi'), 'Icelandic help defines size as bytes');
        Assert.IsTrue(Notes.Contains('mcp-stateless#265'), 'Icelandic help names the runtime follow-up');
    end;

    local procedure VerifyFormats(LanguageId: Integer)
    begin
        VerifyOutput('PDF', 'application/pdf', '%PDF', LanguageId);
        VerifyOutput('Word', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'PK', LanguageId);
        VerifyOutput('Excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'PK', LanguageId);
        VerifyOutput('XML', 'application/xml', '<?xml', LanguageId);
    end;

    local procedure VerifyOutput(OutputFormat: Text; ExpectedMime: Text; Magic: Text; LanguageId: Integer)
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Msg Handler ori";
        Request: JsonObject;
        Input: InStream;
        Prefix: Text;
        ByteLength: BigInteger;
        PriorLanguage: Integer;
    begin
        // [GIVEN] An extension-owned report, restricted to its single successful fixture row.
        Request.Add('reportId', Report::"Layout Sample Report ori");
        Request.Add('tableView', 'WHERE(Number=CONST(1))');
        if OutputFormat <> '' then
            Request.Add('format', OutputFormat);
        TempArgument.Init();
        TempArgument.Insert();
        TempArgument.SetRequestJson(Request);
        PriorLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        // [WHEN] The handler renders the requested format.
        Handler.ExecuteSaveAs(TempArgument);
        GlobalLanguage(PriorLanguage);
        // [THEN] The content type and file signature agree, and size is the actual byte length.
        Assert.AreEqual(ExpectedMime, TempArgument."Content Type", 'MIME type matches rendered format');
        Assert.IsTrue(TempArgument.GetResponseContentLength() > 0, 'Rendered file is not empty');
        TempArgument."Response Content".CreateInStream(Input, TextEncoding::UTF8);
        ByteLength := TempArgument.GetResponseContentLength();
        Assert.AreEqual(Input.Length(), ByteLength, 'Length counts stream bytes');
        Input.ReadText(Prefix, StrLen(Magic));
        Assert.AreEqual(Magic, Prefix, 'Original file signature survives');
    end;

    local procedure VerifyRefusal(RequestText: Text; LanguageId: Integer)
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report Msg Handler ori";
        Request: JsonObject;
        PriorLanguage: Integer;
    begin
        Request.ReadFrom(RequestText);
        TempArgument.Init();
        TempArgument.Insert();
        TempArgument.SetRequestJson(Request);
        PriorLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        asserterror Handler.ExecuteSaveAs(TempArgument);
        GlobalLanguage(PriorLanguage);
        Assert.IsTrue(GetLastErrorText() <> '', 'Invalid input produces a refusal');
        Assert.AreEqual(0, TempArgument.GetResponseContentLength(), 'Refused input produces no document');
    end;

    local procedure AssertMapping(Mapping: JsonObject)
    var
        Token: JsonToken;
    begin
        Mapping.Get('PDF', Token);
        Assert.AreEqual('application/pdf', Token.AsValue().AsText(), 'PDF mapping');
        Mapping.Get('Word', Token);
        Assert.AreEqual('application/vnd.openxmlformats-officedocument.wordprocessingml.document', Token.AsValue().AsText(), 'Word mapping');
        Mapping.Get('Excel', Token);
        Assert.AreEqual('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', Token.AsValue().AsText(), 'Excel mapping');
        Mapping.Get('XML', Token);
        Assert.AreEqual('application/xml', Token.AsValue().AsText(), 'XML mapping');
    end;
}
