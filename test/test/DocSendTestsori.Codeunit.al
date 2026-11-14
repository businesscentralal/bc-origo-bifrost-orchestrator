namespace Origo.Bifrost.Orchestrator.Test;

using Microsoft.Foundation.Reporting;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.Email;
using System.TestLibraries.Utilities;

/// <summary>
/// Purchase.Order.Send, Sales.Quote.Send and Sales.OrderConfirmation.Send.
/// Happy paths arm the mock and assert no Sent Email row was added. Refusals stop before SendProfile.
/// </summary>
codeunit 96472 "Doc Send Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        DispatchHelper: Codeunit "Orch Dispatch Helper ori";
        Mock: Codeunit "Doc Send Mock ori";

    /// <summary>Each send type names its own PDF type. It does not name another document's PDF type.</summary>
    [Test]
    procedure SendTypes_RelatedNamesIncludeTheirOwnPdfType()
    var
        PurchaseRelated: List of [Text];
        QuoteRelated: List of [Text];
        ConfirmationRelated: List of [Text];
    begin
        PurchaseRelated := RelatedNames("Message Type ori"::"Purchase.Order.Send");
        Assert.IsTrue(PurchaseRelated.Contains('Purchase.Order.Pdf'), 'Purchase.Order.Send names Purchase.Order.Pdf');
        Assert.IsFalse(PurchaseRelated.Contains('Sales.Quote.Pdf'), 'Purchase.Order.Send does not name Sales.Quote.Pdf');
        Assert.IsFalse(PurchaseRelated.Contains('Sales.OrderConfirmation.Pdf'), 'Purchase.Order.Send does not name Sales.OrderConfirmation.Pdf');

        QuoteRelated := RelatedNames("Message Type ori"::"Sales.Quote.Send");
        Assert.IsTrue(QuoteRelated.Contains('Sales.Quote.Pdf'), 'Sales.Quote.Send names Sales.Quote.Pdf');
        Assert.IsFalse(QuoteRelated.Contains('Sales.OrderConfirmation.Pdf'), 'Sales.Quote.Send does not name Sales.OrderConfirmation.Pdf');
        Assert.IsFalse(QuoteRelated.Contains('Purchase.Order.Pdf'), 'Sales.Quote.Send does not name Purchase.Order.Pdf');

        ConfirmationRelated := RelatedNames("Message Type ori"::"Sales.OrderConfirmation.Send");
        Assert.IsTrue(ConfirmationRelated.Contains('Sales.OrderConfirmation.Pdf'), 'Sales.OrderConfirmation.Send names Sales.OrderConfirmation.Pdf');
        Assert.IsFalse(ConfirmationRelated.Contains('Sales.Quote.Pdf'), 'Sales.OrderConfirmation.Send does not name Sales.Quote.Pdf');
        Assert.IsFalse(ConfirmationRelated.Contains('Purchase.Order.Pdf'), 'Sales.OrderConfirmation.Send does not name Purchase.Order.Pdf');
    end;

    /// <summary>Selection text names the live PDF type and does not say that type is still pending.</summary>
    [Test]
    procedure SalesSendSelection_NamesLivePdfTypeInBothLanguages()
    var
        Discovery: Interface "Msg Discovery ori";
        PreviousLanguage: Integer;
        EnglishQuote: Text;
        IcelandicQuote: Text;
        EnglishConfirmation: Text;
        IcelandicConfirmation: Text;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        Discovery := "Message Type ori"::"Sales.Quote.Send";
        EnglishQuote := Discovery.GetSelectionDescription();
        Discovery := "Message Type ori"::"Sales.OrderConfirmation.Send";
        EnglishConfirmation := Discovery.GetSelectionDescription();
        GlobalLanguage(1039);
        Discovery := "Message Type ori"::"Sales.Quote.Send";
        IcelandicQuote := Discovery.GetSelectionDescription();
        Discovery := "Message Type ori"::"Sales.OrderConfirmation.Send";
        IcelandicConfirmation := Discovery.GetSelectionDescription();
        GlobalLanguage(PreviousLanguage);

        Assert.IsTrue(EnglishQuote.Contains('Sales.Quote.Pdf'), 'en-US quote selection names Sales.Quote.Pdf');
        Assert.IsFalse(EnglishQuote.Contains('when that type is available'), 'en-US quote selection does not say the PDF type is pending');
        Assert.IsFalse(EnglishQuote.Contains('Sales.OrderConfirmation.Pdf'), 'en-US quote selection does not name the order confirmation PDF');
        Assert.IsTrue(IcelandicQuote.Contains('Sales.Quote.Pdf'), 'is-IS quote selection names Sales.Quote.Pdf');
        Assert.IsFalse(IcelandicQuote.Contains('þegar sú tegund er tiltæk'), 'is-IS quote selection does not say the PDF type is pending');
        Assert.AreNotEqual(EnglishQuote, IcelandicQuote, 'quote selection has an is-IS translation');

        Assert.IsTrue(EnglishConfirmation.Contains('Sales.OrderConfirmation.Pdf'), 'en-US confirmation selection names Sales.OrderConfirmation.Pdf');
        Assert.IsFalse(EnglishConfirmation.Contains('when that type is available'), 'en-US confirmation selection does not say the PDF type is pending');
        Assert.IsFalse(EnglishConfirmation.Contains('Sales.Quote.Pdf'), 'en-US confirmation selection does not name the quote PDF');
        Assert.IsTrue(IcelandicConfirmation.Contains('Sales.OrderConfirmation.Pdf'), 'is-IS confirmation selection names Sales.OrderConfirmation.Pdf');
        Assert.IsFalse(IcelandicConfirmation.Contains('þegar sú tegund er tiltæk'), 'is-IS confirmation selection does not say the PDF type is pending');
        Assert.AreNotEqual(EnglishConfirmation, IcelandicConfirmation, 'confirmation selection has an is-IS translation');
    end;

    /// <summary>Purchase-order help translates its chapters while preserving profile source wire values.</summary>
    [Test]
    procedure Scenario_AC04_PurchaseOrderHelp_TranslatesChapters()
    begin
        VerifyHelpTranslations("Message Type ori"::"Purchase.Order.Send", 'Vendor');
    end;

    /// <summary>Quote help translates its chapters while preserving profile source wire values.</summary>
    [Test]
    procedure Scenario_AC04_SalesQuoteHelp_TranslatesChapters()
    begin
        VerifyHelpTranslations("Message Type ori"::"Sales.Quote.Send", 'Customer');
    end;

    /// <summary>Order-confirmation help translates its chapters while preserving profile source wire values.</summary>
    [Test]
    procedure Scenario_AC04_OrderConfirmationHelp_TranslatesChapters()
    begin
        VerifyHelpTranslations("Message Type ori"::"Sales.OrderConfirmation.Send", 'Customer');
    end;

    [Test]
    procedure PurchaseOrderSend_HappyPathIsMockedAndSendsNoEmail()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        TempArgument: Record "Message Argument ori" temporary;
        SentBefore: Integer;
    begin
        // [SCENARIO #94] A purchase order send resolves the request profile and does not transmit e-mail
        CreateVendor(Vendor);
        CreateProfile('BIF94MAIL', false);
        CreatePurchaseOrder(PurchaseHeader, Vendor."No.");
        Mock.Arm();
        SentBefore := SentEmailCount();

        Dispatch(TempArgument, "Message Type ori"::"Purchase.Order.Send",
            '{"documentNo":"' + PurchaseHeader."No." + '","documentSendingProfile":"BIF94MAIL"}', '');

        AssertSuccess(TempArgument, 'PurchaseOrder', 'BIF94MAIL', 'Request');
        Assert.IsTrue(Mock.WasCaptured(), 'Send was mocked');
        Assert.AreEqual('PurchaseOrder', Mock.CapturedKind(), 'Kind');
        Assert.AreEqual(PurchaseHeader."No.", Mock.CapturedNo(), 'Document no.');
        Assert.AreEqual(SentBefore, SentEmailCount(), 'No e-mail was sent');
        Mock.Disarm();
    end;

    [Test]
    procedure SalesQuoteSend_BySystemIdIsMocked()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        TempArgument: Record "Message Argument ori" temporary;
        SentBefore: Integer;
    begin
        // [SCENARIO #94] A sales quote send accepts the SystemId and does not transmit e-mail
        CreateCustomer(Customer);
        CreateProfile('BIF94MAIL', false);
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");
        Mock.Arm();
        SentBefore := SentEmailCount();

        Dispatch(TempArgument, "Message Type ori"::"Sales.Quote.Send",
            '{"documentSendingProfile":"BIF94MAIL"}', Format(SalesHeader.SystemId, 0, 4));

        AssertSuccess(TempArgument, 'SalesQuote', 'BIF94MAIL', 'Request');
        Assert.AreEqual(SalesHeader."No.", Mock.CapturedNo(), 'Document no.');
        Assert.AreEqual(SentBefore, SentEmailCount(), 'No e-mail was sent');
        Mock.Disarm();
    end;

    [Test]
    procedure SalesOrderConfirmationSend_HappyPathIsMocked()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        TempArgument: Record "Message Argument ori" temporary;
        SentBefore: Integer;
    begin
        // [SCENARIO #94] A sales order confirmation send resolves the request profile and does not transmit e-mail
        CreateCustomer(Customer);
        CreateProfile('BIF94MAIL', false);
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        Mock.Arm();
        SentBefore := SentEmailCount();

        Dispatch(TempArgument, "Message Type ori"::"Sales.OrderConfirmation.Send",
            '{"orderNo":"' + SalesHeader."No." + '","documentSendingProfile":"BIF94MAIL"}', '');

        AssertSuccess(TempArgument, 'SalesOrderConfirmation', 'BIF94MAIL', 'Request');
        Assert.AreEqual('SalesOrderConfirmation', Mock.CapturedKind(), 'Kind');
        Assert.AreEqual(SentBefore, SentEmailCount(), 'No e-mail was sent');
        Mock.Disarm();
    end;

    [Test]
    procedure SalesOrderConfirmationSend_UnknownDocumentIsRecordNotFound()
    var
        TempArgument: Record "Message Argument ori" temporary;
        ResponseJson: JsonObject;
    begin
        // [SCENARIO #94] An unknown sales order is RecordNotFound and nothing is sent
        Mock.Disarm();
        Dispatch(TempArgument, "Message Type ori"::"Sales.OrderConfirmation.Send", '{"documentNo":"BIF94-NONE"}', '');
        ResponseJson := TempArgument.GetResponseJson();
        AssertErrorCode(ResponseJson, 'RecordNotFound');
        Assert.IsFalse(Mock.WasCaptured(), 'Unknown document was not sent');
    end;

    [Test]
    procedure PurchaseOrderSend_UnknownProfileIsRecordNotFound()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        TempArgument: Record "Message Argument ori" temporary;
        ResponseJson: JsonObject;
    begin
        // [SCENARIO #94] An unknown document sending profile is RecordNotFound before send
        CreateVendor(Vendor);
        CreatePurchaseOrder(PurchaseHeader, Vendor."No.");
        Mock.Disarm();
        Dispatch(TempArgument, "Message Type ori"::"Purchase.Order.Send",
            '{"documentNo":"' + PurchaseHeader."No." + '","documentSendingProfile":"BIF94-NO"}', '');
        ResponseJson := TempArgument.GetResponseJson();
        AssertErrorCode(ResponseJson, 'RecordNotFound');
        Assert.IsFalse(Mock.WasCaptured(), 'Unknown profile was not sent');
    end;

    [Test]
    procedure SalesQuoteSend_DiskProfileIsPreconditionFailed()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        TempArgument: Record "Message Argument ori" temporary;
        ResponseJson: JsonObject;
    begin
        // [SCENARIO #94] A profile that saves to disk is refused before send
        CreateCustomer(Customer);
        CreateProfile('BIF94DISK', true);
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");
        Mock.Disarm();
        Dispatch(TempArgument, "Message Type ori"::"Sales.Quote.Send",
            '{"quoteNo":"' + SalesHeader."No." + '","documentSendingProfile":"BIF94DISK"}', '');
        ResponseJson := TempArgument.GetResponseJson();
        AssertErrorCode(ResponseJson, 'PreconditionFailed');
        Assert.IsFalse(Mock.WasCaptured(), 'Disk profile was not sent');
    end;

    [Test]
    procedure PurchaseOrderSend_ProfileTooLongIsInvalidParameterFormat()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        TempArgument: Record "Message Argument ori" temporary;
        ResponseJson: JsonObject;
    begin
        // [SCENARIO #94] A profile code longer than 20 characters is refused and never cut
        CreateVendor(Vendor);
        CreatePurchaseOrder(PurchaseHeader, Vendor."No.");
        Mock.Disarm();
        Dispatch(TempArgument, "Message Type ori"::"Purchase.Order.Send",
            '{"documentNo":"' + PurchaseHeader."No." + '","documentSendingProfile":"BIF94-PROFILE-CODE-TOO-LONG"}', '');
        ResponseJson := TempArgument.GetResponseJson();
        AssertErrorCode(ResponseJson, 'InvalidParameterFormat');
        Assert.IsFalse(Mock.WasCaptured(), 'Overlong profile was not sent');
    end;

    [Test]
    procedure SalesQuoteSend_MissingEmailIsPreconditionFailed()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        TempArgument: Record "Message Argument ori" temporary;
        ResponseJson: JsonObject;
    begin
        // [SCENARIO #94] An e-mail profile with no customer e-mail is refused before send
        CreateCustomer(Customer);
        Customer."E-Mail" := '';
        Customer.Modify(true);
        CreateProfile('BIF94MAIL', false);
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");
        Mock.Disarm();
        Dispatch(TempArgument, "Message Type ori"::"Sales.Quote.Send",
            '{"documentNo":"' + SalesHeader."No." + '","documentSendingProfile":"BIF94MAIL"}', '');
        ResponseJson := TempArgument.GetResponseJson();
        AssertErrorCode(ResponseJson, 'PreconditionFailed');
        Assert.IsFalse(Mock.WasCaptured(), 'Missing e-mail was not sent');
    end;

    /// <summary>Checks the real help contract in both supported languages, including stable machine values.</summary>
    local procedure VerifyHelpTranslations(MessageType: Enum "Message Type ori"; PartySource: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        ContractInterface: Interface "Msg Contract ori";
        EnglishContract: JsonObject;
        IcelandicContract: JsonObject;
        CanonicalEnglish: JsonObject;
        CanonicalIcelandic: JsonObject;
        EnglishChapter: JsonToken;
        IcelandicChapter: JsonToken;
        Field: JsonToken;
        Name: JsonToken;
        Allowed: JsonToken;
        ExpectedSources: JsonArray;
        EnglishOverview: Text;
        IcelandicOverview: Text;
        EnglishNotes: Text;
        IcelandicNotes: Text;
        EnglishText: Text;
        IcelandicText: Text;
        ChapterName: Text;
        ChapterNames: List of [Text];
        PreviousLanguage: Integer;
    begin
        // [SCENARIO #94 AC04] Declared help resources are bilingual. Foundation #777 deliberately
        // renders the public structured contract in English regardless of the session language.
        ContractInterface := MessageType;
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        EnglishContract := ReadDeclaredChapters(MessageType);
        ContractMgt.GetContract(MessageType, CanonicalEnglish);
        ContractInterface.GetOverview(EnglishOverview);
        ContractInterface.GetNotes(EnglishNotes);
        GlobalLanguage(1039);
        IcelandicContract := ReadDeclaredChapters(MessageType);
        ContractMgt.GetContract(MessageType, CanonicalIcelandic);
        ContractInterface.GetOverview(IcelandicOverview);
        ContractInterface.GetNotes(IcelandicNotes);
        GlobalLanguage(PreviousLanguage);

        CanonicalEnglish.WriteTo(EnglishText);
        CanonicalIcelandic.WriteTo(IcelandicText);
        Assert.AreEqual(EnglishText, IcelandicText, 'Foundation keeps the structured wire contract in canonical English');

        ChapterNames.Add('envelope');
        ChapterNames.Add('target');
        ChapterNames.Add('parameters');
        ChapterNames.Add('response');
        ChapterNames.Add('errors');
        ChapterNames.Add('effect');
        ChapterNames.Add('related');
        ChapterNames.Add('workflow');
        ChapterNames.Add('examples');
        foreach ChapterName in ChapterNames do begin
            Assert.IsTrue(EnglishContract.Get(ChapterName, EnglishChapter), 'English ' + ChapterName);
            Assert.IsTrue(IcelandicContract.Get(ChapterName, IcelandicChapter), 'Icelandic ' + ChapterName);
            EnglishChapter.WriteTo(EnglishText);
            IcelandicChapter.WriteTo(IcelandicText);
            Assert.AreNotEqual(EnglishText, IcelandicText, ChapterName + ' prose has an is-IS translation');
        end;
        Assert.AreNotEqual(EnglishOverview, IcelandicOverview, 'Overview has an is-IS translation');
        Assert.AreNotEqual(EnglishNotes, IcelandicNotes, 'Notes have an is-IS translation');
        ExpectedSources.Add('Request');
        ExpectedSources.Add(PartySource);
        ExpectedSources.Add('Default');
        ExpectedSources.WriteTo(EnglishText);
        IcelandicContract.Get('response', IcelandicChapter);
        IcelandicChapter.AsObject().Get('fields', Allowed);
        foreach Field in Allowed.AsArray() do begin
            Field.AsObject().Get('name', Name);
            if Name.AsValue().AsText() = 'documentSendingProfileSource' then begin
                Assert.IsTrue(Field.AsObject().Get('allowed', Allowed), 'Profile sources are declared');
                Allowed.WriteTo(IcelandicText);
                Assert.AreEqual(EnglishText, IcelandicText, 'Machine profile sources are never translated');
                exit;
            end;
        end;
        Assert.Fail('Profile source response field was not found');
    end;

    local procedure RelatedNames(MessageType: Enum "Message Type ori") Names: List of [Text]
    var
        Contract: Interface "Msg Contract ori";
        Related: JsonArray;
        Entry: JsonToken;
        NameToken: JsonToken;
    begin
        Contract := MessageType;
        Contract.GetRelated(Related);
        foreach Entry in Related do begin
            Entry.AsObject().Get('name', NameToken);
            Names.Add(NameToken.AsValue().AsText());
        end;
    end;

    /// <summary>Reads each declared chapter without overriding the caller's language.</summary>
    local procedure ReadDeclaredChapters(MessageType: Enum "Message Type ori") Chapters: JsonObject
    var
        Contract: Interface "Msg Contract ori";
        ObjectChapter: JsonObject;
        ArrayChapter: JsonArray;
    begin
        Contract := MessageType;
        Contract.GetEnvelope(ObjectChapter);
        Chapters.Add('envelope', ObjectChapter);
        Contract.GetTarget(ArrayChapter);
        Chapters.Add('target', ArrayChapter);
        Clear(ArrayChapter);
        Contract.GetParameters(ArrayChapter);
        Chapters.Add('parameters', ArrayChapter);
        Clear(ObjectChapter);
        Contract.GetResponse(ObjectChapter);
        Chapters.Add('response', ObjectChapter);
        Clear(ArrayChapter);
        Contract.GetErrors(ArrayChapter);
        Chapters.Add('errors', ArrayChapter);
        Clear(ObjectChapter);
        Contract.GetEffect(ObjectChapter);
        Chapters.Add('effect', ObjectChapter);
        Clear(ArrayChapter);
        Contract.GetRelated(ArrayChapter);
        Chapters.Add('related', ArrayChapter);
        Clear(ObjectChapter);
        Contract.GetWorkflow(ObjectChapter);
        Chapters.Add('workflow', ObjectChapter);
        Clear(ArrayChapter);
        Contract.GetExamples(ArrayChapter);
        Chapters.Add('examples', ArrayChapter);
    end;

    local procedure Dispatch(var TempArgument: Record "Message Argument ori" temporary; MessageType: Enum "Message Type ori"; DataJson: Text; Subject: Text)
    var
        RequestJson: JsonObject;
    begin
        TempArgument.Init();
        TempArgument.Subject := CopyStr(Subject, 1, MaxStrLen(TempArgument.Subject));
        TempArgument.Insert();
        RequestJson.ReadFrom(DataJson);
        TempArgument.SetRequestJson(RequestJson);
        DispatchHelper.Execute(MessageType, TempArgument);
    end;

    local procedure AssertSuccess(var TempArgument: Record "Message Argument ori" temporary; DocumentTypeText: Text; ProfileCode: Code[20]; Source: Text)
    var
        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        ResponseJson := TempArgument.GetResponseJson();
        Assert.IsTrue(ResponseJson.Get('status', Token), 'status');
        Assert.AreEqual('Success', Token.AsValue().AsText(), ResponseJsonText(ResponseJson));
        Assert.IsTrue(ResponseJson.Get('documentType', Token), 'documentType');
        Assert.AreEqual(DocumentTypeText, Token.AsValue().AsText(), 'documentType value');
        Assert.IsTrue(ResponseJson.Get('documentSendingProfileCode', Token), 'profile');
        Assert.AreEqual(ProfileCode, Token.AsValue().AsText(), 'profile value');
        Assert.IsTrue(ResponseJson.Get('documentSendingProfileSource', Token), 'source');
        Assert.AreEqual(Source, Token.AsValue().AsText(), 'source value');
        Assert.IsFalse(ResponseJson.Get('nextStep', Token), 'success has no nextStep');
    end;

    local procedure AssertErrorCode(ResponseJson: JsonObject; ExpectedCode: Text)
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(ResponseJson.Get('status', Token), 'status');
        Assert.AreEqual('Error', Token.AsValue().AsText(), ResponseJsonText(ResponseJson));
        Assert.IsTrue(ResponseJson.Get('code', Token), 'code');
        Assert.AreEqual(ExpectedCode, Token.AsValue().AsText(), ResponseJsonText(ResponseJson));
        Assert.IsTrue(ResponseJson.Get('nextStep', Token), 'nextStep');
        Assert.AreNotEqual('', Token.AsValue().AsText(), 'nextStep text');
    end;

    local procedure ResponseJsonText(ResponseJson: JsonObject): Text
    var
        Result: Text;
    begin
        ResponseJson.WriteTo(Result);
        exit(Result);
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("E-Mail", 'bif94@example.com');
        Customer.Modify(true);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    var
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("E-Mail", 'bif94@example.com');
        Vendor.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
    end;

    local procedure CreateProfile(ProfileCode: Code[20]; Disk: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        Exists: Boolean;
    begin
        // The first profile in the company becomes the default. A later test in this codeunit
        // cannot delete that row ("You cannot delete the default rule"), so an existing code is updated.
        Exists := DocumentSendingProfile.Get(ProfileCode);
        if not Exists then begin
            DocumentSendingProfile.Init();
            DocumentSendingProfile.Code := ProfileCode;
        end;
        DocumentSendingProfile.Description := ProfileCode;
        DocumentSendingProfile."E-Mail" := DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)";
        if Disk then
            DocumentSendingProfile.Disk := DocumentSendingProfile.Disk::PDF
        else
            DocumentSendingProfile.Disk := DocumentSendingProfile.Disk::No;
        if Exists then
            DocumentSendingProfile.Modify(true)
        else
            DocumentSendingProfile.Insert(true);
    end;

    local procedure SentEmailCount(): Integer
    var
        SentEmail: Record "Sent Email";
    begin
        exit(SentEmail.Count());
    end;
}
