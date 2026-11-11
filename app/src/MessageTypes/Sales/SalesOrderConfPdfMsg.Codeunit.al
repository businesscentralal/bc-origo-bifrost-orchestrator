namespace Origo.Bifrost.Orchestrator;

using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Origo.Bifrost;
using System.Utilities;

/// <summary>
/// Sales.OrderConfirmation.Pdf (#93): prints one sales order with the report that Report Selections usage
/// S.Order names for its Sell-to Customer (by default 1305 Standard Sales - Order Conf.) and answers the PDF.
/// The order is found by No. or SystemId from subject, orderNo, orderId, documentNo or documentId.
/// </summary>
codeunit 10035629 "Sales Order Conf Pdf Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;
    Permissions = tabledata "Sales Header" = R,
                  tabledata "Report Selections" = R,
                  tabledata "Custom Report Selection" = R;

    procedure IsEnabled(): Boolean
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(GetFilterTableNo());
        exit(RecRef.ReadPermission());
    end;

    procedure GetFilterTableNo(): Integer
    begin
        exit(Database::"Sales Header");
    end;

    procedure GetDescription(): Text[250]
    var
        DescriptionLbl: Label 'Prints a sales order confirmation as a PDF document.', Comment = 'is-IS=Prentar pöntunarstaðfestingu sölupöntunar sem PDF-skjal.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'order confirmation pdf, sales order pdf, print order confirmation, confirm order to customer, order confirmation copy, print sales order', Comment = 'is-IS=pöntunarstaðfesting pdf, sölupöntun pdf, prenta pöntunarstaðfestingu, staðfesta pöntun til viðskiptamanns, afrit pöntunarstaðfestingar, prenta sölupöntun';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Get an open sales order as an order confirmation PDF, printed with the customer''s report selection for usage S.Order. Increases the order''s No. Printed. For a posted invoice use Sales.SalesInvoice.Pdf; for any other report use Orchestrator.Report.SaveAs.', Comment = 'is-IS=Sækja opna sölupöntun sem PDF-pöntunarstaðfestingu, prentaða með skýrsluvali viðskiptamanns fyrir notkunina S.Order. Hækkar prentteljara pöntunarinnar. Fyrir bókaðan reikning notaðu Sales.SalesInvoice.Pdf; fyrir aðrar skýrslur notaðu Orchestrator.Report.SaveAs.';
    begin
        exit(SelectionLbl);
    end;

    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Forms: List of [Text];
    begin
        Forms.AddRange('guid', 'no');
        Envelope := Parts.Envelope(Forms, 'The sales order: its SystemId (a GUID) or its No.', false, 'application/pdf');
        exit(true);
    end;

    procedure GetTarget(var Target: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Target.Add(ContractMgt.TargetEntry('subject', 'guid|no', 'A GUID is read as the SystemId of the sales order, anything else as its No.'));
        Target.Add(ContractMgt.TargetEntry('data.orderNo', 'guid|no', 'Read the same way as subject.'));
        Target.Add(ContractMgt.TargetEntry('data.orderId', 'guid|no', 'Read the same way as subject.'));
        Target.Add(ContractMgt.TargetEntry('data.documentNo', 'guid|no', 'Read the same way as subject.'));
        Target.Add(ContractMgt.TargetEntry('data.documentId', 'guid|no', 'Read the same way as subject.'));
        exit(true);
    end;

    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('orderNo', 'string', false, 'The No. or the SystemId of the sales order. Needed when subject is empty.'));
        Parameters.Add(ContractMgt.Parameter('orderId', 'string', false, 'The SystemId or the No. of the sales order.'));
        Parameters.Add(ContractMgt.Parameter('documentNo', 'string', false, 'Same as orderNo, for callers that use the generic document keys.'));
        Parameters.Add(ContractMgt.Parameter('documentId', 'string', false, 'Same as orderId, for callers that use the generic document keys.'));
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Fields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'binary', 'binary', 'The PDF file of the order confirmation itself, not JSON. A client such as MCP hands it on as base64.');
        Response := Parts.Response(Fields, 'application/pdf');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, 'Read permission denied for sales orders.',
            'The caller has no read permission on Sales Header.', 'Ask an administrator to grant read access to Sales Header.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::MissingParameter, 'No sales order was named.',
            'subject, orderNo, orderId, documentNo and documentId are all empty.', 'Send the order No. or SystemId as subject or as data.orderNo.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::RecordNotFound, 'Sales order <value> was not found.',
            'No sales order of type Order has that No. or SystemId. Quotes, invoices and posted documents are not orders.', 'Find the order with Data.Records.Get on Sales Header filtered on Document Type Order.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::ConflictingIdentifiers, 'The identifiers name different sales orders.',
            'Two of subject, orderNo, orderId, documentNo and documentId point at different orders.', 'Send one identifier, or identifiers of the same order.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PreconditionFailed, 'No report is set up for Report Selections usage S.Order.',
            'Neither Report Selections nor the customer''s document layouts name a report for the order confirmation.', 'Set up an order confirmation report in Report Selection - Sales, usage Order.'));
        Parts.AddRuntimeError(Errors, 'The report fails while rendering, for example a layout error.', 'Read the text and correct the report layout or the order.');
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    begin
        Effect.Add('effect', 'write');
        Effect.Add('changes', 'Increases No. Printed on the sales order: the standard report counts the print. A replacement report in Report Selections may not. Saving the PDF commits the work done so far, so the call cannot run inside a larger transaction that is rolled back.');
        Effect.Add('idempotent', false);
        exit(true);
    end;

    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    procedure GetRelated(var Related: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.Related(Related, 'Sales.SalesInvoice.Pdf', 'The order is posted and you need the posted sales invoice instead.');
        Parts.Related(Related, 'Orchestrator.Report.SaveAs', 'You need another report, a format other than PDF or your own request page options.');
        exit(true);
    end;

    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Steps: JsonArray;
    begin
        Steps.Add(ContractMgt.WorkflowStep('Data.Records.Get', 'Find the sales order on Sales Header, filtered on Document Type Order; read its no or id.'));
        Steps.Add(ContractMgt.WorkflowStep('Sales.OrderConfirmation.Pdf', 'Get the order confirmation PDF with that no as subject.'));
        Steps.Add(ContractMgt.WorkflowStep('Email.Draft.Set', 'Attach the PDF to an e-mail draft for the customer.'));
        Workflow.Add('steps', Steps);
        Workflow.Add('text', 'Send an order confirmation to the customer.');
        exit(true);
    end;

    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.Example(Examples, 'Print an order confirmation', '{"type":"Sales.OrderConfirmation.Pdf","data":{"orderNo":"101005"}}', '{"contentType":"application/pdf","size":48211,"base64":"<base64>"}');
        Parts.Example(Examples, 'Unknown order', '{"type":"Sales.OrderConfirmation.Pdf","data":{"orderNo":"NOSUCHORDER"}}', '{"status":"Error","code":"RecordNotFound","parameter":"orderNo","received":"NOSUCHORDER"}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Returns an open sales order as an order confirmation PDF, printed with the report the customer''s Report Selection (usage S.Order) names; by default the standard order confirmation. ' +
            'Use it to hand a confirmation of the order to a person or another system. Printing it increases No. Printed on the order.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'subject and the keys under data (orderNo, orderId, documentNo, documentId) are all tried: a value that looks like a GUID is read as the SystemId, anything else as the No. ' +
            'Only documents of type Order are found. Two identifiers that name different orders are refused with ConflictingIdentifiers. ' +
            'Only the Success answer is a PDF; an error answer is JSON (text/json). The same read permission on Sales Header is required as for reading the order. ' +
            'Saving the PDF commits the work done so far, so the call cannot run inside a larger transaction that is rolled back.';
        exit(true);
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Inbound);
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        SalesHeader: Record "Sales Header";
        ReportSelections: Record "Report Selections";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
    begin
        Argument.AssertVersion1();
        Argument.AssertIsLicensed();

        RecRef.Open(Database::"Sales Header");
        if not RecRef.ReadPermission() then begin
            Argument.RespondWithError("Bifrost Error Code ori"::PermissionDenied, PermissionDeniedErr, '', '', ExpectedPermissionTxt, PermissionNextStepTxt);
            exit;
        end;

        if not FindOrder(Argument, SalesHeader) then
            exit;

        if not HasOrderReport(SalesHeader) then begin
            Argument.RespondWithError("Bifrost Error Code ori"::PreconditionFailed, NoReportErr, '', 'S.Order', ExpectedReportTxt, NoReportNextStepTxt);
            exit;
        end;

        // The order confirmation report refuses no filter; print exactly this order.
        SalesHeader.SetRecFilter();
        ReportSelections.GetPdfReportForCust(TempBlob, Enum::"Report Selection Usage"::"S.Order", SalesHeader, SalesHeader."Sell-to Customer No.");
        Argument.SetResponsePdf(TempBlob);
    end;

    local procedure FindOrder(var Argument: Record "Message Argument ori"; var SalesHeader: Record "Sales Header"): Boolean
    var
        RequestJson: JsonObject;
        Identifiers: Dictionary of [Text, Text];
        Sources: List of [Text];
        Source: Text;
        Value: Text;
        FirstSource: Text;
        FirstValue: Text;
        FoundId: Guid;
        HasFound: Boolean;
    begin
        RequestJson := Argument.GetRequestJson();
        Sources.AddRange('subject', 'orderNo', 'orderId', 'documentNo', 'documentId');
        Identifiers.Add('subject', Argument.Subject.Trim());
        Identifiers.Add('orderNo', ReadIdentifier(RequestJson, 'orderNo', Argument));
        Identifiers.Add('orderId', ReadIdentifier(RequestJson, 'orderId', Argument));
        Identifiers.Add('documentNo', ReadIdentifier(RequestJson, 'documentNo', Argument));
        Identifiers.Add('documentId', ReadIdentifier(RequestJson, 'documentId', Argument));
        foreach Source in Sources do begin
            Value := Identifiers.Get(Source);
            if Value <> '' then begin
                if not FindOrderByValue(Value, SalesHeader) then begin
                    Argument.RespondWithRecordNotFound(Database::"Sales Header", Value, Source);
                    exit(false);
                end;
                if HasFound and (SalesHeader.SystemId <> FoundId) then begin
                    Argument.RespondWithError("Bifrost Error Code ori"::ConflictingIdentifiers, StrSubstNo(ConflictErr, FirstSource, FirstValue, Source, Value),
                        Source, Value, StrSubstNo(SameOrderTxt, FirstValue), ConflictNextStepTxt);
                    exit(false);
                end;
                if not HasFound then begin
                    HasFound := true;
                    FoundId := SalesHeader.SystemId;
                    FirstSource := Source;
                    FirstValue := Value;
                end;
            end;
        end;

        if not HasFound then begin
            Argument.RespondWithError("Bifrost Error Code ori"::MissingParameter, MissingOrderErr, 'orderNo', '', ExpectedOrderTxt, MissingNextStepTxt);
            exit(false);
        end;
        SalesHeader.GetBySystemId(FoundId);
        exit(true);
    end;

    local procedure ReadIdentifier(RequestJson: JsonObject; KeyName: Text; var Argument: Record "Message Argument ori"): Text
    var
        Token: JsonToken;
    begin
        if not RequestJson.Get(KeyName, Token) then
            exit('');
        if not Token.IsValue() then
            exit('');
        if Token.AsValue().IsNull() then
            exit('');
        exit(Argument.TokenAsText(Token).Trim());
    end;

    local procedure FindOrderByValue(Value: Text; var SalesHeader: Record "Sales Header"): Boolean
    var
        OrderId: Guid;
    begin
        Clear(SalesHeader);
        if Evaluate(OrderId, Value) then begin
            if not SalesHeader.GetBySystemId(OrderId) then
                exit(false);
            exit(SalesHeader."Document Type" = SalesHeader."Document Type"::Order);
        end;
        if StrLen(Value) > MaxStrLen(SalesHeader."No.") then
            exit(false);
        exit(SalesHeader.Get(SalesHeader."Document Type"::Order, CopyStr(Value, 1, MaxStrLen(SalesHeader."No."))));
    end;

    local procedure HasOrderReport(SalesHeader: Record "Sales Header"): Boolean
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
    begin
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"S.Order");
        ReportSelections.SetFilter("Report ID", '<>0');
        if not ReportSelections.IsEmpty() then
            exit(true);
        CustomReportSelection.SetRange("Source Type", Database::Customer);
        CustomReportSelection.SetRange("Source No.", SalesHeader."Sell-to Customer No.");
        CustomReportSelection.SetRange(Usage, CustomReportSelection.Usage::"S.Order");
        CustomReportSelection.SetFilter("Report ID", '<>0');
        exit(not CustomReportSelection.IsEmpty());
    end;

    var
        PermissionDeniedErr: Label 'Read permission denied for sales orders.', Comment = 'is-IS=Lesheimild vantar fyrir sölupantanir.';
        PermissionNextStepTxt: Label 'Ask an administrator to grant read access to Sales Header.', Comment = 'is-IS=Biddu kerfisstjóra um lesaðgang að Sales Header.';
        MissingOrderErr: Label 'No sales order was named. Send the order No. or SystemId.', Comment = 'is-IS=Engin sölupöntun var tilgreind. Sendu númer eða SystemId pöntunarinnar.';
        MissingNextStepTxt: Label 'Send the order No. or SystemId as subject or as data.orderNo.', Comment = 'is-IS=Sendu númer eða SystemId pöntunarinnar sem subject eða sem data.orderNo.';
        ConflictErr: Label '%1 %2 and %3 %4 name different sales orders.', Comment = 'is-IS=%1 %2 og %3 %4 vísa á mismunandi sölupantanir.';
        SameOrderTxt: Label 'An identifier of the same order as %1', Comment = 'is-IS=Auðkenni sömu pöntunar og %1';
        ConflictNextStepTxt: Label 'Send one identifier, or identifiers of the same order.', Comment = 'is-IS=Sendu eitt auðkenni, eða auðkenni sömu pöntunar.';
        NoReportErr: Label 'No report is set up for Report Selections usage S.Order.', Comment = 'is-IS=Engin skýrsla er skilgreind fyrir notkunina S.Order í skýrsluvali.';
        ExpectedPermissionTxt: Label 'Read permission on Sales Header', Comment = 'is-IS=Lesheimild á Sales Header';
        ExpectedOrderTxt: Label 'The No. or SystemId of a sales order', Comment = 'is-IS=Númer eða SystemId sölupöntunar';
        ExpectedReportTxt: Label 'A report for Report Selections usage S.Order', Comment = 'is-IS=Skýrsla fyrir notkunina S.Order í skýrsluvali';
        NoReportNextStepTxt: Label 'Set up an order confirmation report in Report Selection - Sales, usage Order.', Comment = 'is-IS=Skilgreindu skýrslu fyrir pöntunarstaðfestingu í Skýrsluval - Sala, notkun Pöntun.';
}
