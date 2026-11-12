namespace Origo.Bifrost.Orchestrator;

using Microsoft.Foundation.Reporting;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Origo.Bifrost;
using System.Utilities;

/// <summary>
/// Purchase.Order.Pdf (#91): prints one purchase order with the report that Report Selections usage
/// P.Order names for its Buy-from Vendor (by default 1322 Standard Purchase - Order) and answers the PDF.
/// The order is found by No. or SystemId from subject, orderNo, orderId, documentNo or documentId.
/// </summary>
codeunit 10035625 "Purch Order Pdf Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;
    Permissions = tabledata "Purchase Header" = R,
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
        exit(Database::"Purchase Header");
    end;

    procedure GetDescription(): Text[250]
    var
        DescriptionLbl: Label 'Prints a purchase order as a PDF document and writes an interaction log entry when an interaction template is set up.', Comment = 'is-IS=Prentar innkaupapöntun sem PDF-skjal og skrifar færslu í samskiptaskrá þegar samskiptasniðmát er skilgreint.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'purchase order pdf, print purchase order, send order to vendor, purchase order copy, vendor order pdf, print PO', Comment = 'is-IS=innkaupapöntun pdf, prenta innkaupapöntun, senda pöntun til lánardrottins, afrit innkaupapöntunar, pöntun lánardrottins pdf, prenta innkaupapöntun aftur';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Get an open purchase order as a PDF, printed with the vendor''s report selection for usage P.Order. Increases the order''s No. Printed and, when an interaction template is set up, writes an interaction log entry. For a sales order confirmation use Sales.OrderConfirmation.Pdf; for any other report use Orchestrator.Report.SaveAs.', Comment = 'is-IS=Sækja opna innkaupapöntun sem PDF, prentaða með skýrsluvali lánardrottins fyrir notkunina P.Order. Hækkar prentteljara pöntunarinnar og, þegar samskiptasniðmát er skilgreint, skrifar færslu í samskiptaskrá. Fyrir pöntunarstaðfestingu sölupöntunar notaðu Sales.OrderConfirmation.Pdf; fyrir aðrar skýrslur notaðu Orchestrator.Report.SaveAs.';
    begin
        exit(SelectionLbl);
    end;

    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Forms: List of [Text];
    begin
        Forms.AddRange('guid', 'no');
        Envelope := Parts.Envelope(Forms, 'The purchase order: its SystemId (a GUID) or its No.', false, 'application/pdf');
        exit(true);
    end;

    procedure GetTarget(var Target: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Target.Add(ContractMgt.TargetEntry('subject', 'guid|no', 'A GUID is read as the SystemId of the purchase order, anything else as its No.'));
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
        Parameters.Add(ContractMgt.Parameter('orderNo', 'string', false, 'The No. or the SystemId of the purchase order. Needed when subject is empty.'));
        Parameters.Add(ContractMgt.Parameter('orderId', 'string', false, 'The SystemId or the No. of the purchase order.'));
        Parameters.Add(ContractMgt.Parameter('documentNo', 'string', false, 'Same as orderNo, for callers that use the generic document keys.'));
        Parameters.Add(ContractMgt.Parameter('documentId', 'string', false, 'Same as orderId, for callers that use the generic document keys.'));
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Fields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'binary', 'binary', 'The PDF file of the purchase order itself, not JSON. A client such as MCP hands it on as base64.');
        Parts.AddResponseField(Fields, 'datacontenttype', 'string', 'application/pdf with a quoted name parameter containing PurchaseOrder-<SystemId>.pdf. The SystemId is lowercase without braces; this stable filename contains no unsafe document-number characters. Playbooks expose the same MIME value as contentType.');
        Response := Parts.Response(Fields, 'application/pdf');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Parts: Codeunit "Orch B1 Contract Parts ori";
    begin
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, 'Read permission denied for purchase orders.',
            'The caller has no read permission on Purchase Header.', 'Ask an administrator to grant read access to Purchase Header.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::MissingParameter, 'No purchase order was named.',
            'subject, orderNo, orderId, documentNo and documentId are all empty.', 'Send the order No. or SystemId as subject or as data.orderNo.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::RecordNotFound, 'Purchase order <value> was not found.',
            'No purchase document of type Order has that No. or SystemId. Quotes, invoices, blanket orders and posted documents are not orders.', 'Find the order with Data.Records.Get on Purchase Header filtered on Document Type Order.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::ConflictingIdentifiers, 'The identifiers name different purchase orders.',
            'Two of subject, orderNo, orderId, documentNo and documentId point at different orders.', 'Send one identifier, or identifiers of the same order.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PreconditionFailed, 'No report is set up for Report Selections usage P.Order.',
            'Neither Report Selections nor the vendor''s document layouts name a report for the purchase order.', 'Set up a purchase order report in Report Selection - Purchase, usage Order.'));
        Parts.AddRuntimeError(Errors, 'The report fails while rendering, for example a layout error.', 'Read the text and correct the report layout or the order.');
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    begin
        Effect.Add('effect', 'write');
        Effect.Add('changes', 'Increases No. Printed on the purchase order and, when an interaction template is set up for purchase orders, writes an interaction log entry for the vendor''s contact: the standard report does both. It may also archive a version of the order when Purchases & Payables Setup archives orders. A replacement report in Report Selections may not. Saving the PDF commits the work done so far, so the call cannot run inside a larger transaction that is rolled back.');
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
        Parts.Related(Related, 'Sales.SalesInvoice.Pdf', 'You need a posted sales document for a customer, not a purchase order.');
        Parts.Related(Related, 'Orchestrator.Report.SaveAs', 'You need another report, a format other than PDF or your own request page options.');
        exit(true);
    end;

    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Steps: JsonArray;
    begin
        Steps.Add(ContractMgt.WorkflowStep('Data.Records.Get', 'Find the purchase order on Purchase Header, filtered on Document Type Order; read its no or id.'));
        Steps.Add(ContractMgt.WorkflowStep('Purchase.Order.Pdf', 'Get the purchase order PDF with that no as subject.'));
        Steps.Add(ContractMgt.WorkflowStep('Email.Draft.Set', 'Attach the PDF to an e-mail draft for the vendor.'));
        Workflow.Add('steps', Steps);
        Workflow.Add('text', 'Send a purchase order to the vendor.');
        exit(true);
    end;

    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.Example(Examples, 'Print a purchase order', '{"type":"Purchase.Order.Pdf","data":{"orderNo":"106001"}}', '{"contentType":"application/pdf; name=\"PurchaseOrder-00000000-0000-0000-0000-000000000001.pdf\"","size":45120,"base64":"<base64>"}');
        Parts.Example(Examples, 'Unknown order', '{"type":"Purchase.Order.Pdf","data":{"orderNo":"NOSUCHORDER"}}', '{"status":"Error","code":"RecordNotFound","parameter":"orderNo","received":"NOSUCHORDER"}');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Returns an open purchase order as a PDF, printed with the report the vendor''s Report Selection (usage P.Order) names; by default the standard purchase order. ' +
            'Use it to hand the order to the vendor, a person or another system. Printing it increases No. Printed on the order and, when an interaction template is set up for purchase orders, writes an interaction log entry.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'subject and the keys under data (orderNo, orderId, documentNo, documentId) are all tried: a value that looks like a GUID is read as the SystemId, anything else as the No. ' +
            'Only purchase documents of type Order are found. Two identifiers that name different orders are refused with ConflictingIdentifiers. ' +
            'The success MIME type carries name="PurchaseOrder-<SystemId>.pdf"; callers may use that filename when saving the unchanged binary PDF. Only the Success answer is a PDF; an error answer is JSON (text/json). The same read permission on Purchase Header is required as for reading the order. ' +
            'Saving the PDF commits the work done so far, so the call cannot run inside a larger transaction that is rolled back. ' +
            'When an interaction template is set up for purchase orders, the standard report writes an interaction log entry for the vendor''s contact. A replacement report in Report Selections may not. The call does not change whether that logging happens.';
        exit(true);
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Inbound);
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        PurchaseHeader: Record "Purchase Header";
        ReportSelections: Record "Report Selections";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
    begin
        Argument.AssertVersion1();
        Argument.AssertIsLicensed();

        RecRef.Open(Database::"Purchase Header");
        if not RecRef.ReadPermission() then begin
            Argument.RespondWithError("Bifrost Error Code ori"::PermissionDenied, PermissionDeniedErr, '', '', ExpectedPermissionTxt, PermissionNextStepTxt);
            exit;
        end;

        if not FindOrder(Argument, PurchaseHeader) then
            exit;

        if not HasOrderReport(PurchaseHeader) then begin
            Argument.RespondWithError("Bifrost Error Code ori"::PreconditionFailed, NoReportErr, '', 'P.Order', ExpectedReportTxt, NoReportNextStepTxt);
            exit;
        end;

        // The purchase order report prints every record in its filter; print exactly this order.
        PurchaseHeader.SetRecFilter();
        ReportSelections.GetPdfReportForVend(TempBlob, Enum::"Report Selection Usage"::"P.Order", PurchaseHeader, PurchaseHeader."Buy-from Vendor No.");
        Argument.SetResponsePdf(TempBlob);
        // Keep the PDF bytes and expose its filename through the response MIME metadata.
        Argument."Content Type" := CopyStr('application/pdf; name="PurchaseOrder-' + Format(PurchaseHeader.SystemId, 0, 4).ToLower() + '.pdf"', 1, MaxStrLen(Argument."Content Type"));
    end;

    local procedure FindOrder(var Argument: Record "Message Argument ori"; var PurchaseHeader: Record "Purchase Header"): Boolean
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
                if not FindOrderByValue(Value, PurchaseHeader) then begin
                    Argument.RespondWithRecordNotFound(Database::"Purchase Header", Value, Source);
                    exit(false);
                end;
                if HasFound and (PurchaseHeader.SystemId <> FoundId) then begin
                    Argument.RespondWithError("Bifrost Error Code ori"::ConflictingIdentifiers, StrSubstNo(ConflictErr, FirstSource, FirstValue, Source, Value),
                        Source, Value, StrSubstNo(SameOrderTxt, FirstValue), ConflictNextStepTxt);
                    exit(false);
                end;
                if not HasFound then begin
                    HasFound := true;
                    FoundId := PurchaseHeader.SystemId;
                    FirstSource := Source;
                    FirstValue := Value;
                end;
            end;
        end;

        if not HasFound then begin
            Argument.RespondWithError("Bifrost Error Code ori"::MissingParameter, MissingOrderErr, 'orderNo', '', ExpectedOrderTxt, MissingNextStepTxt);
            exit(false);
        end;
        PurchaseHeader.GetBySystemId(FoundId);
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

    local procedure FindOrderByValue(Value: Text; var PurchaseHeader: Record "Purchase Header"): Boolean
    var
        OrderId: Guid;
    begin
        Clear(PurchaseHeader);
        if Evaluate(OrderId, Value) then begin
            if not PurchaseHeader.GetBySystemId(OrderId) then
                exit(false);
            exit(PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order);
        end;
        if StrLen(Value) > MaxStrLen(PurchaseHeader."No.") then
            exit(false);
        exit(PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, CopyStr(Value, 1, MaxStrLen(PurchaseHeader."No."))));
    end;

    local procedure HasOrderReport(PurchaseHeader: Record "Purchase Header"): Boolean
    var
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
    begin
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"P.Order");
        ReportSelections.SetFilter("Report ID", '<>0');
        if not ReportSelections.IsEmpty() then
            exit(true);
        CustomReportSelection.SetRange("Source Type", Database::Vendor);
        CustomReportSelection.SetRange("Source No.", PurchaseHeader."Buy-from Vendor No.");
        CustomReportSelection.SetRange(Usage, CustomReportSelection.Usage::"P.Order");
        CustomReportSelection.SetFilter("Report ID", '<>0');
        exit(not CustomReportSelection.IsEmpty());
    end;

    var
        PermissionDeniedErr: Label 'Read permission denied for purchase orders.', Comment = 'is-IS=Lesheimild vantar fyrir innkaupapantanir.';
        PermissionNextStepTxt: Label 'Ask an administrator to grant read access to Purchase Header.', Comment = 'is-IS=Biddu kerfisstjóra um lesaðgang að Purchase Header.';
        MissingOrderErr: Label 'No purchase order was named. Send the order No. or SystemId.', Comment = 'is-IS=Engin innkaupapöntun var tilgreind. Sendu númer eða SystemId pöntunarinnar.';
        MissingNextStepTxt: Label 'Send the order No. or SystemId as subject or as data.orderNo.', Comment = 'is-IS=Sendu númer eða SystemId pöntunarinnar sem subject eða sem data.orderNo.';
        ConflictErr: Label '%1 %2 and %3 %4 name different purchase orders.', Comment = '%1 = first identifier source, %2 = first value, %3 = second identifier source, %4 = second value, is-IS=%1 %2 og %3 %4 vísa á mismunandi innkaupapantanir.';
        SameOrderTxt: Label 'An identifier of the same order as %1', Comment = '%1 = the first identifier value, is-IS=Auðkenni sömu pöntunar og %1';
        ConflictNextStepTxt: Label 'Send one identifier, or identifiers of the same order.', Comment = 'is-IS=Sendu eitt auðkenni, eða auðkenni sömu pöntunar.';
        NoReportErr: Label 'No report is set up for Report Selections usage P.Order.', Comment = 'is-IS=Engin skýrsla er skilgreind fyrir notkunina P.Order í skýrsluvali.';
        ExpectedPermissionTxt: Label 'Read permission on Purchase Header', Comment = 'is-IS=Lesheimild á Purchase Header';
        ExpectedOrderTxt: Label 'The No. or SystemId of a purchase order', Comment = 'is-IS=Númer eða SystemId innkaupapöntunar';
        ExpectedReportTxt: Label 'A report for Report Selections usage P.Order', Comment = 'is-IS=Skýrsla fyrir notkunina P.Order í skýrsluvali';
        NoReportNextStepTxt: Label 'Set up a purchase order report in Report Selection - Purchase, usage Order.', Comment = 'is-IS=Skilgreindu skýrslu fyrir innkaupapöntun í Skýrsluval - Innkaup, notkun Pöntun.';
}
