namespace Origo.Bifrost.Orchestrator.Test;

using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Origo.Bifrost;
using System.TestLibraries.Utilities;
using System.Text;
using System.Utilities;

/// <summary>
/// Acceptance tests for Sales.Quote.Pdf (#92): a quote number or SystemId returns a PDF,
/// an unknown quote is RecordNotFound, and a non-quote document is not accepted.
/// </summary>
codeunit 96471 "Sales Quote Pdf Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        MarkerTok: Label 'FRAR-Q92', Locked = true;

    [Test]
    procedure MissingQuoteIsMissingParameter()
    begin
        // [SCENARIO #92] A call with no quote number and no SystemId is MissingParameter and tells the caller what to send.
        AssertRefusal('{}', 'MissingParameter');
    end;

    [Test]
    procedure UnknownQuoteNumberIsRecordNotFound()
    begin
        // [SCENARIO #92] An unknown quote number is RecordNotFound and names a next step.
        AssertRefusal('{"quoteNo":"NO-SUCH-QUOTE-92"}', 'RecordNotFound');
    end;

    [Test]
    procedure UnknownSystemIdIsRecordNotFound()
    var
        MissingId: Guid;
    begin
        // [SCENARIO #92] An unknown SystemId is RecordNotFound.
        MissingId := CreateGuid();
        AssertRefusal('{"systemId":"' + Format(MissingId, 0, 4) + '"}', 'RecordNotFound');
    end;

    [Test]
    procedure NumericQuoteNoIsInvalidParameterFormat()
    begin
        // [SCENARIO #92] A quote number sent as a JSON number is invalid input.
        AssertRefusal('{"quoteNo":12345}', 'InvalidParameterFormat');
    end;

    [Test]
    procedure QuoteNumberReturnsPdf()
    var
        SalesHeader: Record "Sales Header";
        TempArgument: Record "Message Argument ori" temporary;
    begin
        // [SCENARIO #92] The quote number returns a non-empty PDF.
        DeleteMarkedDocuments();
        CreateQuote(SalesHeader);
        DispatchJson('{"quoteNo":"' + SalesHeader."No." + '"}', TempArgument);
        AssertPdf(TempArgument);
        DeleteMarkedDocuments();
    end;

    [Test]
    procedure SystemIdReturnsPdf()
    var
        SalesHeader: Record "Sales Header";
        TempArgument: Record "Message Argument ori" temporary;
    begin
        // [SCENARIO #92] The quote SystemId returns a non-empty PDF.
        DeleteMarkedDocuments();
        CreateQuote(SalesHeader);
        DispatchJson('{"systemId":"' + Format(SalesHeader.SystemId, 0, 4) + '"}', TempArgument);
        AssertPdf(TempArgument);
        DeleteMarkedDocuments();
    end;

    [Test]
    procedure SubjectReturnsPdf()
    var
        SalesHeader: Record "Sales Header";
        ResponseBlob: Codeunit "Temp Blob";
        ContentType: Text;
    begin
        // [SCENARIO #92] The quote number in subject returns a non-empty PDF.
        DeleteMarkedDocuments();
        CreateQuote(SalesHeader);
        DispatchSubject(SalesHeader."No.", 1033, ContentType, ResponseBlob);
        Assert.AreEqual('application/pdf', ContentType, 'content type');
        Assert.IsTrue(ResponseBlob.Length() > 100, 'pdf length');
        Assert.IsTrue(BlobStartsWithPdf(ResponseBlob), 'pdf header');
        DeleteMarkedDocuments();
    end;

    [Test]
    procedure OrderSystemIdIsNotAQuote()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO #92] The SystemId of a sales order is not a sales quote.
        DeleteMarkedDocuments();
        CreateOrder(SalesHeader);
        AssertRefusal('{"systemId":"' + Format(SalesHeader.SystemId, 0, 4) + '"}', 'RecordNotFound');
        DeleteMarkedDocuments();
    end;

    [Test]
    procedure ConflictingIdentifiersAreRefused()
    var
        FirstQuote: Record "Sales Header";
        SecondQuote: Record "Sales Header";
    begin
        // [SCENARIO #92] A quote number and a SystemId that name different quotes are ConflictingIdentifiers.
        DeleteMarkedDocuments();
        CreateQuote(FirstQuote);
        CreateQuote(SecondQuote);
        AssertRefusal('{"quoteNo":"' + FirstQuote."No." + '","systemId":"' + Format(SecondQuote.SystemId, 0, 4) + '"}', 'ConflictingIdentifiers');
        DeleteMarkedDocuments();
    end;

    [Test]
    procedure NameHasThreePartsAndHelpIsTranslated()
    var
        MessageTypeInterface: Interface "Msg Interface ori";
        Discovery: Interface "Msg Discovery ori";
        Contract: Interface "Msg Contract ori";
        Effect: JsonObject;
        Changes: JsonToken;
        Overview: Text;
        Notes: Text;
        PreviousLanguage: Integer;
        EnglishDescription: Text;
        IcelandicDescription: Text;
        EnglishSelection: Text;
        IcelandicSelection: Text;
        EnglishKeywords: Text;
        IcelandicKeywords: Text;
    begin
        // [SCENARIO #92] The message type name has three parts, and the discovery help has an is-IS translation.
        Assert.IsTrue("Message Type ori".Names().Contains('Sales.Quote.Pdf'), 'registered name');
        Assert.AreEqual(3, 'Sales.Quote.Pdf'.Split('.').Count(), 'three dot-separated parts');

        MessageTypeInterface := "Message Type ori"::"Sales.Quote.Pdf";
        Discovery := "Message Type ori"::"Sales.Quote.Pdf";
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        EnglishDescription := MessageTypeInterface.GetDescription();
        EnglishSelection := Discovery.GetSelectionDescription();
        EnglishKeywords := Discovery.GetKeywords();
        GlobalLanguage(1039);
        IcelandicDescription := MessageTypeInterface.GetDescription();
        IcelandicSelection := Discovery.GetSelectionDescription();
        IcelandicKeywords := Discovery.GetKeywords();
        GlobalLanguage(PreviousLanguage);

        // [SCENARIO #171 AC03] Both discovery languages and the contract disclose the report's interaction log side effect.
        Assert.IsTrue(EnglishDescription.Contains('interaction log entry'), 'en-US description discloses interaction logging');
        Assert.IsTrue(EnglishSelection.Contains('interaction log entry'), 'en-US selection discloses interaction logging');
        Assert.IsTrue(IcelandicDescription.Contains('samskiptaskrá'), 'is-IS description discloses interaction logging');
        Assert.IsTrue(IcelandicSelection.Contains('samskiptaskrá'), 'is-IS selection discloses interaction logging');
        Contract := "Message Type ori"::"Sales.Quote.Pdf";
        Assert.IsTrue(Contract.GetEffect(Effect), 'effect exists');
        Assert.IsTrue(Effect.Get('changes', Changes), 'effect changes exist');
        Assert.IsTrue(Changes.AsValue().AsText().Contains('interaction log entry when an interaction template is set up'), 'conditional interaction log effect');
        Assert.IsTrue(Contract.GetOverview(Overview), 'overview exists');
        Assert.IsTrue(Overview.Contains('interaction log entry'), 'overview discloses interaction logging');
        Assert.IsTrue(Contract.GetNotes(Notes), 'notes exist');
        Assert.IsTrue(Notes.Contains('interaction log entry'), 'notes disclose interaction logging');

        Assert.AreNotEqual('', EnglishDescription, 'en-US description');
        Assert.AreNotEqual(EnglishDescription, IcelandicDescription, 'is-IS description');
        Assert.AreNotEqual(EnglishSelection, IcelandicSelection, 'is-IS selection');
        Assert.AreNotEqual(EnglishKeywords, IcelandicKeywords, 'is-IS keywords');
        Assert.IsTrue(EnglishKeywords.Split(',').Count() >= 3, 'keywords');
        Assert.AreEqual("Msg Direction ori"::Both, MessageTypeInterface.GetMessageDirection(), 'direction');
    end;

    [Test]
    procedure HelpStatesTheQuoteArchiveSideEffect()
    var
        MessageTypeInterface: Interface "Msg Interface ori";
        Discovery: Interface "Msg Discovery ori";
        Contract: Interface "Msg Contract ori";
        Effect: JsonObject;
        Changes: JsonToken;
        Overview: Text;
        Notes: Text;
        PreviousLanguage: Integer;
        EnglishDescription: Text;
        IcelandicDescription: Text;
        EnglishSelection: Text;
        IcelandicSelection: Text;
        EnglishOverview: Text;
    begin
        // [SCENARIO #176 AC01] Happy path: the quote PDF help states the archive side effect in both catalogue languages.
        // [GIVEN] Sales.Quote.Pdf
        MessageTypeInterface := "Message Type ori"::"Sales.Quote.Pdf";
        Discovery := "Message Type ori"::"Sales.Quote.Pdf";
        Contract := "Message Type ori"::"Sales.Quote.Pdf";
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        EnglishDescription := MessageTypeInterface.GetDescription();
        EnglishSelection := Discovery.GetSelectionDescription();
        Assert.IsTrue(Contract.GetOverview(EnglishOverview), 'overview in 1033');
        GlobalLanguage(1039);
        IcelandicDescription := MessageTypeInterface.GetDescription();
        IcelandicSelection := Discovery.GetSelectionDescription();
        Assert.IsTrue(Contract.GetOverview(Overview), 'overview in 1039');
        GlobalLanguage(PreviousLanguage);

        // [THEN] en-US and is-IS catalogue texts name Archive Quotes Always and Sales Header Archive
        Assert.IsTrue(EnglishDescription.Contains('Archive Quotes is Always'), 'en-US description names Always');
        Assert.IsTrue(EnglishDescription.Contains('Sales Header Archive'), 'en-US description names the archive table');
        Assert.IsTrue(EnglishSelection.Contains('cannot be removed over MCP'), 'en-US selection says the archive stays');
        Assert.IsTrue(IcelandicDescription.Contains('Sales Header Archive'), 'is-IS description names the archive table');
        Assert.IsTrue(IcelandicDescription.Contains('Always'), 'is-IS description names Always');
        Assert.IsTrue(IcelandicSelection.Contains('Sales Header Archive'), 'is-IS selection names the archive table');
        Assert.IsTrue(IcelandicSelection.Contains('MCP'), 'is-IS selection names MCP');
        Assert.IsTrue(StrLen(EnglishDescription) <= 250, 'en-US description fits Text[250]');
        Assert.IsTrue(StrLen(IcelandicDescription) <= 250, 'is-IS description fits Text[250]');

        // [THEN] help chapters stay English and state the same side effect
        Assert.AreEqual(EnglishOverview, Overview, 'overview chapter stays English at 1039');
        Assert.IsTrue(Contract.GetEffect(Effect), 'effect exists');
        Assert.IsTrue(Effect.Get('changes', Changes), 'effect changes exist');
        Assert.IsTrue(Changes.AsValue().AsText().Contains('Sales Header Archive version that cannot be removed over MCP'), 'effect names the archive');
        Assert.IsTrue(EnglishOverview.Contains('Sales Header Archive'), 'overview names the archive');
        Assert.IsTrue(Contract.GetNotes(Notes), 'notes exist');
        Assert.IsTrue(Notes.Contains('Sales Header Archive'), 'notes name the archive');
    end;

    [Test]
    procedure HelpDoesNotSayTheQuoteArchiveIsRemoved()
    var
        Contract: Interface "Msg Contract ori";
        Notes: Text;
    begin
        // [SCENARIO #176] Invalid reading: the help must not say the archived quote is removed.
        // [GIVEN] Sales.Quote.Pdf notes
        Contract := "Message Type ori"::"Sales.Quote.Pdf";
        Assert.IsTrue(Contract.GetNotes(Notes), 'notes exist');
        // [THEN] the archive cannot be removed over MCP, and the notes do not say it is deleted
        Assert.IsTrue(Notes.Contains('cannot be removed over MCP'), 'notes say the archive stays');
        Assert.IsFalse(Notes.Contains('deleted'), 'notes do not say the archive is deleted');
    end;

    [Test]
    procedure HelpLimitsQuoteArchivingToAlways()
    var
        Contract: Interface "Msg Contract ori";
        Effect: JsonObject;
        Changes: JsonToken;
        Notes: Text;
    begin
        // [SCENARIO #176] Edge: Question and Never do not archive on this call, and a replacement report may not.
        Contract := "Message Type ori"::"Sales.Quote.Pdf";
        Assert.IsTrue(Contract.GetEffect(Effect), 'effect exists');
        Assert.IsTrue(Effect.Get('changes', Changes), 'effect changes exist');
        Assert.IsTrue(Changes.AsValue().AsText().Contains('Question and Never do not archive on this call'), 'effect limits archiving to Always');
        Assert.IsTrue(Changes.AsValue().AsText().Contains('A replacement report may not archive'), 'effect allows a replacement report to skip archiving');
        Assert.IsFalse(Changes.AsValue().AsText().Contains('always archives'), 'effect does not say every print archives');
        Assert.IsTrue(Contract.GetNotes(Notes), 'notes exist');
        Assert.IsTrue(Notes.Contains('this call does not confirm'), 'notes say a Question setup is not confirmed');
        Assert.IsTrue(Notes.Contains('Never does not archive'), 'notes name Never');
    end;

    local procedure AssertRefusal(RequestText: Text; ExpectedCode: Text)
    var
        TempArgument: Record "Message Argument ori" temporary;
        ResponseJson: JsonObject;
    begin
        DispatchJson(RequestText, TempArgument);
        ResponseJson := TempArgument.GetResponseJson();
        Assert.AreEqual('Error', JsonText(ResponseJson, 'status'), RequestText);
        Assert.AreEqual(ExpectedCode, JsonText(ResponseJson, 'code'), RequestText);
        Assert.AreNotEqual('', JsonText(ResponseJson, 'nextStep'), 'nextStep ' + RequestText);
    end;

    local procedure AssertPdf(var TempArgument: Record "Message Argument ori" temporary)
    var
        InStream: InStream;
        Prefix: Text;
    begin
        Assert.AreEqual('application/pdf', TempArgument."Content Type", 'content type');
        TempArgument.CalcFields("Response Content");
        Assert.IsTrue(TempArgument."Response Content".Length > 100, 'pdf length');
        TempArgument."Response Content".CreateInStream(InStream);
        InStream.ReadText(Prefix, 4);
        Assert.AreEqual('%PDF', Prefix, 'pdf header');
    end;

    local procedure BlobStartsWithPdf(var TempBlob: Codeunit "Temp Blob"): Boolean
    var
        InStream: InStream;
        Prefix: Text;
    begin
        TempBlob.CreateInStream(InStream);
        InStream.ReadText(Prefix, 4);
        exit(Prefix = '%PDF');
    end;

    local procedure DispatchJson(RequestText: Text; var TempArgument: Record "Message Argument ori" temporary)
    var
        Helper: Codeunit "Orch Dispatch Helper ori";
        RequestJson: JsonObject;
    begin
        TempArgument.Init();
        TempArgument.Insert();
        RequestJson.ReadFrom(RequestText);
        TempArgument.SetRequestJson(RequestJson);
        Helper.Execute("Message Type ori"::"Sales.Quote.Pdf", TempArgument);
    end;

    local procedure DispatchSubject(Subject: Text[250]; LanguageId: Integer; var ContentType: Text; var ResponseBlob: Codeunit "Temp Blob")
    var
        Dispatcher: Codeunit "Dispatcher ori";
        RequestContent: BigText;
        ResponseContentType: Text[100];
        ResponseTime: Duration;
        EmptyTaskId: Guid;
        MessageId: Guid;
    begin
        RequestContent.AddText('{}');
        Dispatcher.EnqueueAndProcess("Message Type ori"::"Sales.Quote.Pdf", "Message Version ori"::"1.0", Subject, '', 'text/json', RequestContent, EmptyTaskId, LanguageId, MessageId, ResponseBlob, ResponseContentType, ResponseTime);
        ContentType := ResponseContentType;
    end;

    local procedure JsonText(ResponseJson: JsonObject; PropertyKey: Text): Text
    var
        Token: JsonToken;
    begin
        if not ResponseJson.Get(PropertyKey, Token) then
            exit('');
        if not Token.IsValue() then
            exit('');
        exit(Token.AsValue().AsText());
    end;

    local procedure CreateQuote(var SalesHeader: Record "Sales Header")
    begin
        CreateDocument(SalesHeader, SalesHeader."Document Type"::Quote);
    end;

    local procedure CreateOrder(var SalesHeader: Record "Sales Header")
    begin
        CreateDocument(SalesHeader, SalesHeader."Document Type"::Order);
    end;

    local procedure CreateDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesHeader."Your Reference" := MarkerTok;
        SalesHeader.Modify(true);
    end;

    local procedure DeleteMarkedDocuments()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Ids: List of [Guid];
        DocumentId: Guid;
    begin
        SalesHeader.SetRange("Your Reference", MarkerTok);
        if SalesHeader.FindSet() then
            repeat
                Ids.Add(SalesHeader.SystemId);
            until SalesHeader.Next() = 0;
        foreach DocumentId in Ids do
            if SalesHeader.GetBySystemId(DocumentId) then begin
                SalesLine.SetRange("Document Type", SalesHeader."Document Type");
                SalesLine.SetRange("Document No.", SalesHeader."No.");
                SalesLine.DeleteAll(true);
                SalesHeader.Delete(true);
            end;
    end;
}
