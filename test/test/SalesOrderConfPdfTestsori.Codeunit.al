namespace Origo.Bifrost.Orchestrator.Test;

using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Document;
using Origo.Bifrost;
using System.TestLibraries.Utilities;

/// <summary>
/// Sales.OrderConfirmation.Pdf (#93): the order is found by No. or SystemId, printed with Report Selections usage
/// S.Order and answered as a PDF; unknown, missing, conflicting and non-order identifiers and a missing report
/// selection answer a Bifrost error code with a nextStep. Every test creates its own customer and order.
/// </summary>
codeunit 96481 "Sales Order Conf Pdf Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LibrarySales: Codeunit "Library - Sales";
        Dispatch: Codeunit "Orch Dispatch Helper ori";

    [Test]
    procedure OrderNoAnswersThePdfAndCountsThePrint()
    var
        SalesHeader: Record "Sales Header";
        TempArgument: Record "Message Argument ori" temporary;
        PrintedBefore: Integer;
    begin
        // [SCENARIO #93 AC01] An order No. answers the order confirmation as a PDF and the print is counted
        LibrarySales.CreateSalesOrder(SalesHeader);
        PrintedBefore := SalesHeader."No. Printed";

        RunType(TempArgument, '{"orderNo":"' + SalesHeader."No." + '"}');

        AssertIsPdf(TempArgument);
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        Assert.AreEqual(PrintedBefore + 1, SalesHeader."No. Printed", 'The standard order confirmation counts the print');
    end;

    [Test]
    procedure SystemIdAndMatchingNoAnswerThePdf()
    var
        SalesHeader: Record "Sales Header";
        TempArgument: Record "Message Argument ori" temporary;
    begin
        // [SCENARIO #93 AC01] orderId as SystemId, together with documentNo of the same order, answers the PDF
        LibrarySales.CreateSalesOrder(SalesHeader);

        RunType(TempArgument, '{"orderId":"' + Format(SalesHeader.SystemId, 0, 4) + '","documentNo":"' + SalesHeader."No." + '"}');

        AssertIsPdf(TempArgument);
    end;

    [Test]
    procedure UnknownOrderIsRecordNotFound()
    var
        TempArgument: Record "Message Argument ori" temporary;
    begin
        // [SCENARIO #93 AC02] An order No. that does not exist is refused with RecordNotFound and a nextStep
        RunType(TempArgument, '{"orderNo":"NOSUCHORDER93"}');

        AssertRefusal(TempArgument, 'RecordNotFound');
    end;

    [Test]
    procedure QuoteNoIsNotAnOrder()
    var
        SalesHeader: Record "Sales Header";
        OrderWithSameNo: Record "Sales Header";
        TempArgument: Record "Message Argument ori" temporary;
    begin
        // [SCENARIO #93 AC02 edge] A sales quote, by No. or by SystemId, is not an order. Its No. is one no order has.
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Quote;
        SalesHeader."No." := 'GL93Q' + CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 12);
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo());
        SalesHeader.Modify(true);
        OrderWithSameNo.SetRange("Document Type", OrderWithSameNo."Document Type"::Order);
        OrderWithSameNo.SetRange("No.", SalesHeader."No.");
        Assert.RecordIsEmpty(OrderWithSameNo);

        RunType(TempArgument, '{"orderNo":"' + SalesHeader."No." + '"}');
        AssertRefusal(TempArgument, 'RecordNotFound');

        RunType(TempArgument, '{"orderId":"' + Format(SalesHeader.SystemId, 0, 4) + '"}');
        AssertRefusal(TempArgument, 'RecordNotFound');
    end;

    [Test]
    procedure NoIdentifierIsMissingParameter()
    var
        TempArgument: Record "Message Argument ori" temporary;
    begin
        // [SCENARIO #93 AC04 invalid input] No identifier at all is refused with MissingParameter
        RunType(TempArgument, '{}');

        AssertRefusal(TempArgument, 'MissingParameter');
    end;

    [Test]
    procedure TwoDifferentOrdersAreConflictingIdentifiers()
    var
        FirstOrder: Record "Sales Header";
        SecondOrder: Record "Sales Header";
        TempArgument: Record "Message Argument ori" temporary;
    begin
        // [SCENARIO #93 AC04 edge] Identifiers of two different orders are refused with ConflictingIdentifiers
        LibrarySales.CreateSalesOrder(FirstOrder);
        LibrarySales.CreateSalesOrder(SecondOrder);

        RunType(TempArgument, '{"orderNo":"' + FirstOrder."No." + '","orderId":"' + Format(SecondOrder.SystemId, 0, 4) + '"}');

        AssertRefusal(TempArgument, 'ConflictingIdentifiers');
    end;

    [Test]
    procedure NoOrderReportIsPreconditionFailed()
    var
        SalesHeader: Record "Sales Header";
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
        TempArgument: Record "Message Argument ori" temporary;
    begin
        // [SCENARIO #93 AC04 edge] Without a report for usage S.Order the call is refused with PreconditionFailed, not a BC error
        LibrarySales.CreateSalesOrder(SalesHeader);
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"S.Order");
        ReportSelections.DeleteAll();
        CustomReportSelection.SetRange(Usage, CustomReportSelection.Usage::"S.Order");
        CustomReportSelection.DeleteAll();

        RunType(TempArgument, '{"orderNo":"' + SalesHeader."No." + '"}');

        AssertRefusal(TempArgument, 'PreconditionFailed');
    end;

    [Test]
    procedure TheTypeIsInboundAndReadsSalesHeader()
    var
        MessageTypeInterface: Interface "Msg Interface ori";
    begin
        // [SCENARIO #93 AC03/AC05] The type is a write (No. Printed) so Inbound, filtered on Sales Header like the invoice PDF, and its name has three parts
        MessageTypeInterface := "Message Type ori"::"Sales.OrderConfirmation.Pdf";
        Assert.AreEqual("Msg Direction ori"::Inbound, MessageTypeInterface.GetMessageDirection(), 'Direction');
        Assert.AreEqual(Database::"Sales Header", MessageTypeInterface.GetFilterTableNo(), 'Permission table');
        Assert.AreEqual(3, Format("Message Type ori"::"Sales.OrderConfirmation.Pdf").Split('.').Count(), 'Three dot-separated parts');
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
        // [SCENARIO #171 AC03] Effect and translated help name the interaction log entry. AC02: this test does not print.
        Contract := "Message Type ori"::"Sales.OrderConfirmation.Pdf";
        Assert.IsTrue(Contract.GetEffect(Effect), 'Effect is declared');
        Assert.IsTrue(Effect.Get('changes', Token), 'changes is present');
        Assert.IsTrue(Token.AsValue().AsText().Contains('interaction'), 'Effect names the interaction log');
        Assert.IsTrue(Contract.GetOverview(Overview), 'Overview is declared');
        Assert.IsTrue(Overview.Contains('interaction log entry'), 'Overview names the interaction log entry');
        Assert.IsTrue(Contract.GetNotes(Notes), 'Notes are declared');
        Assert.IsTrue(Notes.Contains('interaction log entry'), 'Notes name the interaction log entry');
        Assert.IsTrue(ReadDescription(1033).Contains('interaction log entry'), 'en-US description names the interaction log entry');
        Assert.IsTrue(ReadSelection(1033).Contains('interaction log entry'), 'en-US selection names the interaction log entry');
        Assert.IsTrue(ReadDescription(1039).Contains('samskiptaskrá'), 'is-IS description names the interaction log');
        Assert.IsTrue(ReadSelection(1039).Contains('samskiptaskrá'), 'is-IS selection names the interaction log');
    end;

    local procedure ReadDescription(LanguageId: Integer): Text
    var
        MessageTypeInterface: Interface "Msg Interface ori";
        PreviousLanguage: Integer;
        Description: Text;
    begin
        MessageTypeInterface := "Message Type ori"::"Sales.OrderConfirmation.Pdf";
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
        Discovery := "Message Type ori"::"Sales.OrderConfirmation.Pdf";
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
        Dispatch.Execute("Message Type ori"::"Sales.OrderConfirmation.Pdf", TempArgument);
    end;

    local procedure AssertIsPdf(var TempArgument: Record "Message Argument ori" temporary)
    var
        InStr: InStream;
        Header: Text;
    begin
        if TempArgument."Content Type" <> 'application/pdf' then
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
