namespace Origo.Bifrost.Orchestrator;

using Microsoft.Purchases.Document;
using Origo.Bifrost;

/// <summary>
/// Purchase.Order.Send. Sends a purchase order through the Document Sending Profile, as Sales.SalesInvoice.Send does.
/// </summary>
codeunit 10035632 "Purch Order Send Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;

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
        Contract: Codeunit "Doc Send Contract ori";
    begin
        exit(Contract.PurchaseOrderDescription());
    end;

    procedure GetKeywords(): Text
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        exit(Contract.PurchaseOrderKeywords());
    end;

    procedure GetSelectionDescription(): Text
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        exit(Contract.PurchaseOrderSelection());
    end;

    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Envelope := Contract.Envelope(PurchaseOrderNumberOrItsSystemidLbl);
        exit(true);
    end;

    procedure GetTarget(var Target: JsonArray): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Target := Contract.Target('orderNo', 'orderId', PurchaseOrderLbl);
        exit(true);
    end;

    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Contract.Parameters(Parameters, 'orderNo', 'orderId');
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Contract.Response(Response, 'PurchaseOrder', 'vendorNo', 'vendorName', VendorLbl);
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Contract.Errors(Errors, PurchaseOrder2Lbl, 'Purchase Header');
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Contract.Effect(Effect, SendsThePurchaseOrderWithTheResolvedLbl);
        exit(true);
    end;

    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    procedure GetRelated(var Related: JsonArray): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Contract.RelatedSales(Related, 'Purchase.Order.Send');
        exit(true);
    end;

    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Contract.Workflow(Workflow, 'Purchase.Order.Send', SendThatPurchaseOrderLbl);
        exit(true);
    end;

    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Contract.Example(Examples, 'Purchase.Order.Send', 'orderNo', '106001');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Overview := Contract.Overview(PurchaseOrderLbl, 'Purchase.Order.Pdf');
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Notes := Contract.Notes('Purchase.Order.Pdf');
        exit(true);
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit("Msg Direction ori"::Inbound);
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        Process: Codeunit "Doc Send Process ori";
    begin
        Process.Execute(Argument);
    end;

    var
        PurchaseOrderNumberOrItsSystemidLbl: Label 'Purchase order number, or its SystemId.', Comment = 'is-IS=Númer innkaupapöntunar eða SystemId hennar.';
        PurchaseOrderLbl: Label 'purchase order', Comment = 'is-IS=innkaupapöntun';
        VendorLbl: Label 'Vendor', Comment = 'is-IS=Lánardrottinn';
        PurchaseOrder2Lbl: Label 'Purchase order', Comment = 'is-IS=Innkaupapöntun';
        SendsThePurchaseOrderWithTheResolvedLbl: Label 'Sends the purchase order with the resolved profile, as the Send action does.', Comment = 'is-IS=Sendir innkaupapöntun með forstillingunni sem fannst, eins og aðgerðin Senda gerir.';
        SendThatPurchaseOrderLbl: Label 'Send that purchase order.', Comment = 'is-IS=Sendu innkaupapöntunina.';
}
