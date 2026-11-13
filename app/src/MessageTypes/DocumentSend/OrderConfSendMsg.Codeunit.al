namespace Origo.Bifrost.Orchestrator;

using Microsoft.Sales.Document;
using Origo.Bifrost;

/// <summary>
/// Sales.OrderConfirmation.Send. Sends a sales order confirmation through the Document Sending Profile.
/// </summary>
codeunit 10035634 "Order Conf Send Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
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
        exit(Database::"Sales Header");
    end;

    procedure GetDescription(): Text[250]
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        exit(Contract.OrderConfirmationDescription());
    end;

    procedure GetKeywords(): Text
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        exit(Contract.OrderConfirmationKeywords());
    end;

    procedure GetSelectionDescription(): Text
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        exit(Contract.OrderConfirmationSelection());
    end;

    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Envelope := Contract.Envelope(SalesOrderNumberOrItsSystemidLbl);
        exit(true);
    end;

    procedure GetTarget(var Target: JsonArray): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Target := Contract.Target('orderNo', 'orderId', SalesOrderLbl);
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
        Contract.Response(Response, 'SalesOrderConfirmation', 'customerNo', 'customerName', CustomerLbl);
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Contract.Errors(Errors, SalesOrder2Lbl, 'Sales Header');
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Contract.Effect(Effect, SendsTheSalesOrderConfirmationWithTheLbl);
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
        Contract.RelatedSales(Related, 'Sales.OrderConfirmation.Send');
        exit(true);
    end;

    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Contract.Workflow(Workflow, 'Sales.OrderConfirmation.Send', SendThatSalesOrderConfirmationLbl);
        exit(true);
    end;

    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Contract.Example(Examples, 'Sales.OrderConfirmation.Send', 'orderNo', '101001');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Overview := Contract.Overview(SalesOrderConfirmationLbl, 'Sales.OrderConfirmation.Pdf');
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Notes := Contract.Notes('Sales.OrderConfirmation.Pdf');
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
        SalesOrderNumberOrItsSystemidLbl: Label 'Sales order number, or its SystemId.', Comment = 'is-IS=Númer sölupöntunar eða SystemId hennar.';
        SalesOrderLbl: Label 'sales order', Comment = 'is-IS=sölupöntun';
        CustomerLbl: Label 'Customer', Comment = 'is-IS=Viðskiptamaður';
        SalesOrder2Lbl: Label 'Sales order', Comment = 'is-IS=Sölupöntun';
        SendsTheSalesOrderConfirmationWithTheLbl: Label 'Sends the sales order confirmation with the resolved profile, as the Send action does.', Comment = 'is-IS=Sendir staðfestingu sölupöntunar með forstillingunni sem fannst, eins og aðgerðin Senda gerir.';
        SendThatSalesOrderConfirmationLbl: Label 'Send that sales order confirmation.', Comment = 'is-IS=Sendu staðfestingu sölupöntunarinnar.';
        SalesOrderConfirmationLbl: Label 'sales order confirmation', Comment = 'is-IS=staðfesting sölupöntunar';
}
