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
        Assert.AreEqual('Success', Token.AsValue().AsText(), 'status value');
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
    begin
        if DocumentSendingProfile.Get(ProfileCode) then
            DocumentSendingProfile.Delete(true);
        DocumentSendingProfile.Init();
        DocumentSendingProfile.Code := ProfileCode;
        DocumentSendingProfile.Description := ProfileCode;
        DocumentSendingProfile."E-Mail" := DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)";
        if Disk then
            DocumentSendingProfile.Disk := DocumentSendingProfile.Disk::PDF
        else
            DocumentSendingProfile.Disk := DocumentSendingProfile.Disk::No;
        DocumentSendingProfile.Insert(true);
    end;

    local procedure SentEmailCount(): Integer
    var
        SentEmail: Record "Sent Email";
    begin
        exit(SentEmail.Count());
    end;
}
