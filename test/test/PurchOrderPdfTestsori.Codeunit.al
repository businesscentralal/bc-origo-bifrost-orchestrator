namespace Origo.Bifrost.Orchestrator.Test;

using Microsoft.Foundation.Reporting;
using Microsoft.Purchases.Document;
using Origo.Bifrost;
using System.Utilities;
using System.TestLibraries.Utilities;

/// <summary>
/// Purchase.Order.Pdf (#91): the order is found by No. or SystemId, printed with Report Selections usage
/// P.Order and answered as a PDF; unknown, missing, conflicting and non-order identifiers and a missing report
/// selection answer a Bifrost error code with a nextStep. Every test creates its own vendor and order.
/// </summary>
codeunit 96480 "Purch Order Pdf Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LibraryPurchase: Codeunit "Library - Purchase";
        Dispatch: Codeunit "Orch Dispatch Helper ori";

    [Test]
    procedure OrderNoAnswersThePdfAndCountsThePrint()
    var
        PurchaseHeader: Record "Purchase Header";
        TempArgument: Record "Message Argument ori" temporary;
        PrintedBefore: Integer;
    begin
        // [SCENARIO #91 AC01] A purchase order No. answers the purchase order as a PDF and the print is counted
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        PrintedBefore := PurchaseHeader."No. Printed";

        RunType(TempArgument, '{"orderNo":"' + PurchaseHeader."No." + '"}');

        AssertIsPdf(TempArgument);
        Assert.AreEqual('application/pdf; name="PurchaseOrder-' + Format(PurchaseHeader.SystemId, 0, 4).ToLower() + '.pdf"', TempArgument."Content Type", 'The caller receives the stable filename in the MIME metadata');
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        Assert.AreEqual(PrintedBefore + 1, PurchaseHeader."No. Printed", 'The standard purchase order report counts the print');
    end;

    [Test]
    procedure SubjectSystemIdAndMatchingNoAnswerThePdf()
    var
        PurchaseHeader: Record "Purchase Header";
        Dispatcher: Codeunit "Dispatcher ori";
        ResponseTempBlob: Codeunit "Temp Blob";
        RequestContent: BigText;
        InStr: InStream;
        Header: Text;
        ResponseContentType: Text[100];
        ResponseTime: Duration;
        MessageId: Guid;
        EmptyTaskId: Guid;
    begin
        // [SCENARIO #91 AC01] The SystemId as subject, together with documentNo of the same order, answers the PDF
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        RequestContent.AddText('{"documentNo":"' + PurchaseHeader."No." + '"}');

        Dispatcher.EnqueueAndProcess("Message Type ori"::"Purchase.Order.Pdf", "Message Version ori"::"1.0", CopyStr(Format(PurchaseHeader.SystemId, 0, 4), 1, 250), '', 'text/json',
            RequestContent, EmptyTaskId, 1033, MessageId, ResponseTempBlob, ResponseContentType, ResponseTime);

        Assert.AreEqual('application/pdf; name="PurchaseOrder-' + Format(PurchaseHeader.SystemId, 0, 4).ToLower() + '.pdf"', ResponseContentType, 'The public dispatcher preserves the PDF filename');
        Assert.IsTrue(ResponseTempBlob.HasValue(), 'The PDF has content');
        ResponseTempBlob.CreateInStream(InStr);
        InStr.ReadText(Header, 4);
        Assert.AreEqual('%PDF', Header, 'The answer is a PDF file');
    end;

    [Test]
    procedure UnknownOrderIsRecordNotFound()
    var
        TempArgument: Record "Message Argument ori" temporary;
    begin
        // [SCENARIO #91 AC02] A purchase order No. that does not exist is refused with RecordNotFound and a nextStep
        RunType(TempArgument, '{"orderNo":"NOSUCHPO91"}');

        AssertRefusal(TempArgument, 'RecordNotFound');
    end;

    [Test]
    procedure UnknownSystemIdIsRecordNotFound()
    var
        TempArgument: Record "Message Argument ori" temporary;
    begin
        // [SCENARIO #91 AC02] A SystemId that no purchase document has is refused with RecordNotFound
        RunType(TempArgument, '{"orderId":"' + Format(CreateGuid(), 0, 4) + '"}');

        AssertRefusal(TempArgument, 'RecordNotFound');
    end;

    [Test]
    procedure QuoteIsNotAnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        OrderWithSameNo: Record "Purchase Header";
        TempArgument: Record "Message Argument ori" temporary;
    begin
        // [SCENARIO #91 AC04 edge] A purchase quote, by No. or by SystemId, is not an order. Its No. is one no order has.
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Quote;
        PurchaseHeader."No." := 'NY91Q' + CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 12);
        PurchaseHeader.Insert(true);
        PurchaseHeader.Validate("Buy-from Vendor No.", LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Modify(true);
        OrderWithSameNo.SetRange("Document Type", OrderWithSameNo."Document Type"::Order);
        OrderWithSameNo.SetRange("No.", PurchaseHeader."No.");
        Assert.RecordIsEmpty(OrderWithSameNo);

        RunType(TempArgument, '{"orderNo":"' + PurchaseHeader."No." + '"}');
        AssertRefusal(TempArgument, 'RecordNotFound');

        RunType(TempArgument, '{"orderId":"' + Format(PurchaseHeader.SystemId, 0, 4) + '"}');
        AssertRefusal(TempArgument, 'RecordNotFound');
    end;

    [Test]
    procedure NoIdentifierIsMissingParameter()
    var
        TempArgument: Record "Message Argument ori" temporary;
    begin
        // [SCENARIO #91 AC04 invalid input] No identifier at all is refused with MissingParameter
        RunType(TempArgument, '{}');

        AssertRefusal(TempArgument, 'MissingParameter');
    end;

    [Test]
    procedure TwoDifferentOrdersAreConflictingIdentifiers()
    var
        FirstOrder: Record "Purchase Header";
        SecondOrder: Record "Purchase Header";
        TempArgument: Record "Message Argument ori" temporary;
    begin
        // [SCENARIO #91 AC04 edge] Identifiers of two different purchase orders are refused with ConflictingIdentifiers
        LibraryPurchase.CreatePurchaseOrder(FirstOrder);
        LibraryPurchase.CreatePurchaseOrder(SecondOrder);

        RunType(TempArgument, '{"orderNo":"' + FirstOrder."No." + '","orderId":"' + Format(SecondOrder.SystemId, 0, 4) + '"}');

        AssertRefusal(TempArgument, 'ConflictingIdentifiers');
    end;

    [Test]
    procedure NoOrderReportIsPreconditionFailed()
    var
        PurchaseHeader: Record "Purchase Header";
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        TempArgument: Record "Message Argument ori" temporary;
    begin
        // [SCENARIO #91 AC04 edge] Without a report for usage P.Order the call is refused with PreconditionFailed, not a BC error
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"P.Order");
        ReportSelections.DeleteAll();
        CustomReportSelection.SetRange(Usage, CustomReportSelection.Usage::"P.Order");
        CustomReportSelection.DeleteAll();

        RunType(TempArgument, '{"orderNo":"' + PurchaseHeader."No." + '"}');

        AssertRefusal(TempArgument, 'PreconditionFailed');
    end;

    [Test]
    procedure TheTypeIsInboundAndReadsPurchaseHeader()
    var
        MessageTypeInterface: Interface "Msg Interface ori";
    begin
        // [SCENARIO #91 AC03/AC05] The type is a write (No. Printed) so Inbound, filtered on Purchase Header for its read permission, and its name has three parts
        MessageTypeInterface := "Message Type ori"::"Purchase.Order.Pdf";
        Assert.AreEqual("Msg Direction ori"::Inbound, MessageTypeInterface.GetMessageDirection(), 'Direction');
        Assert.AreEqual(Database::"Purchase Header", MessageTypeInterface.GetFilterTableNo(), 'Permission table');
        Assert.AreEqual(3, Format("Message Type ori"::"Purchase.Order.Pdf").Split('.').Count(), 'Three dot-separated parts');
    end;

    [Test]
    procedure EffectAndHelpNameTheInteractionLogEntry()
    var
        Contract: Interface "Msg Contract ori";
        Effect: JsonObject;
        Token: JsonToken;
        Overview: Text;
        Notes: Text;
    begin
        // [SCENARIO #171 AC01] Effect and translated help name the interaction log entry. AC02: this test does not print.
        Contract := "Message Type ori"::"Purchase.Order.Pdf";
        Assert.IsTrue(Contract.GetEffect(Effect), 'Effect is declared');
        Assert.IsTrue(Effect.Get('changes', Token), 'changes is present');
        Assert.IsTrue(Token.AsValue().AsText().Contains('interaction log entry'), 'Effect names the interaction log entry');
        Assert.IsTrue(Contract.GetOverview(Overview), 'Overview is declared');
        Assert.IsTrue(Overview.Contains('interaction log entry'), 'Overview names the interaction log entry');
        Assert.IsTrue(Contract.GetNotes(Notes), 'Notes are declared');
        Assert.IsTrue(Notes.Contains('interaction log entry'), 'Notes name the interaction log entry');
        Assert.IsTrue(ReadDescription(1033).Contains('interaction log entry'), 'en-US description names the interaction log entry');
        Assert.IsTrue(ReadSelection(1033).Contains('interaction log entry'), 'en-US selection names the interaction log entry');
        Assert.IsTrue(ReadDescription(1039).Contains('samskiptaskrá'), 'is-IS description names the interaction log');
        Assert.IsTrue(ReadSelection(1039).Contains('samskiptaskrá'), 'is-IS selection names the interaction log');
    end;

    [Test]
    procedure HelpStatesWhenAPurchaseOrderIsArchived()
    var
        Contract: Interface "Msg Contract ori";
        Effect: JsonObject;
        Changes: JsonToken;
        Overview: Text;
        Notes: Text;
        EnglishDescription: Text;
        IcelandicDescription: Text;
        EnglishSelection: Text;
        IcelandicSelection: Text;
    begin
        // [SCENARIO #176 AC01] Purchase.Order.Pdf states the archive side effect where it applies: not on this headless call.
        Contract := "Message Type ori"::"Purchase.Order.Pdf";
        EnglishDescription := ReadDescription(1033);
        IcelandicDescription := ReadDescription(1039);
        EnglishSelection := ReadSelection(1033);
        IcelandicSelection := ReadSelection(1039);

        // [THEN] happy path: the catalogue names Purchase Header Archive and says this call does not store one
        Assert.IsTrue(EnglishDescription.Contains('does not store a Purchase Header Archive version on this call'), 'en-US description says this call does not archive');
        Assert.IsTrue(IcelandicDescription.Contains('Purchase Header Archive'), 'is-IS description names the archive table');
        Assert.IsTrue(EnglishSelection.Contains('cannot be removed over MCP'), 'en-US selection says an archive version stays');
        Assert.IsTrue(IcelandicSelection.Contains('Purchase Header Archive'), 'is-IS selection names the archive table');
        Assert.IsTrue(IcelandicSelection.Contains('MCP'), 'is-IS selection names MCP');
        Assert.IsTrue(StrLen(EnglishDescription) <= 250, 'en-US description fits Text[250]');
        Assert.IsTrue(StrLen(IcelandicDescription) <= 250, 'is-IS description fits Text[250]');
        Assert.IsTrue(Contract.GetEffect(Effect), 'effect exists');
        Assert.IsTrue(Effect.Get('changes', Changes), 'effect changes exist');
        Assert.IsTrue(Changes.AsValue().AsText().Contains('Purchase Header Archive version cannot be removed over MCP'), 'effect says an archive version stays');
        Assert.IsTrue(Contract.GetOverview(Overview), 'overview exists');
        Assert.IsTrue(Overview.Contains('does not archive the order on this call'), 'overview says this call does not archive');
        Assert.IsTrue(Contract.GetNotes(Notes), 'notes exist');
        Assert.IsTrue(Notes.Contains('does not open the request page'), 'notes name the request page');

        // [THEN] invalid reading: setup alone does not make this call archive, and the notes do not say the archive is deleted
        Assert.IsFalse(Changes.AsValue().AsText().Contains('when Purchases & Payables Setup archives orders'), 'effect no longer says setup alone archives');
        Assert.IsFalse(Notes.Contains('deleted'), 'notes do not say the archive is deleted');

        // [THEN] edge: a replacement report may still archive
        Assert.IsTrue(Changes.AsValue().AsText().Contains('A replacement report may still archive'), 'effect allows a replacement report to archive');
    end;

    local procedure ReadDescription(LanguageId: Integer): Text
    var
        MessageTypeInterface: Interface "Msg Interface ori";
        PreviousLanguage: Integer;
        Description: Text;
    begin
        MessageTypeInterface := "Message Type ori"::"Purchase.Order.Pdf";
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Description := MessageTypeInterface.GetDescription();
        GlobalLanguage(PreviousLanguage);
        exit(Description);
    end;

    local procedure ReadSelection(LanguageId: Integer): Text
    var
        Discovery: Interface "Msg Discovery ori";
        PreviousLanguage: Integer;
        Selection: Text;
    begin
        Discovery := "Message Type ori"::"Purchase.Order.Pdf";
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Selection := Discovery.GetSelectionDescription();
        GlobalLanguage(PreviousLanguage);
        exit(Selection);
    end;

    local procedure RunType(var TempArgument: Record "Message Argument ori" temporary; RequestText: Text)
    var
        RequestJson: JsonObject;
    begin
        TempArgument.Reset();
        TempArgument.DeleteAll();
        TempArgument.Init();
        TempArgument.ID := CreateGuid();
        TempArgument.Insert();
        RequestJson.ReadFrom(RequestText);
        TempArgument.SetRequestJson(RequestJson);
        TempArgument.Modify();
        Dispatch.Execute("Message Type ori"::"Purchase.Order.Pdf", TempArgument);
    end;

    local procedure AssertIsPdf(var TempArgument: Record "Message Argument ori" temporary)
    var
        InStr: InStream;
        Header: Text;
    begin
        if not TempArgument."Content Type".StartsWith('application/pdf; name="PurchaseOrder-') then
            Assert.Fail('Success answers a PDF, got ' + TempArgument."Content Type" + ': ' + TempArgument.GetResponseText());
        TempArgument.CalcFields("Response Content");
        Assert.IsTrue(TempArgument."Response Content".HasValue(), 'The PDF has content');
        TempArgument."Response Content".CreateInStream(InStr);
        InStr.ReadText(Header, 4);
        Assert.AreEqual('%PDF', Header, 'The answer is a PDF file');
    end;

    local procedure AssertRefusal(var TempArgument: Record "Message Argument ori" temporary; ExpectedCode: Text)
    var
        ResponseJson: JsonObject;
        Token: JsonToken;
    begin
        Assert.AreNotEqual('application/pdf', TempArgument."Content Type", 'A refusal is not a PDF');
        ResponseJson := TempArgument.GetResponseJson();
        Assert.IsTrue(ResponseJson.Get('code', Token), 'The refusal has a code: ' + TempArgument.GetResponseText());
        Assert.AreEqual(ExpectedCode, Token.AsValue().AsText(), 'Error code');
        Assert.IsTrue(ResponseJson.Get('nextStep', Token), 'The refusal has a nextStep');
        Assert.AreNotEqual('', Token.AsValue().AsText(), 'nextStep is not empty');
    end;
}
