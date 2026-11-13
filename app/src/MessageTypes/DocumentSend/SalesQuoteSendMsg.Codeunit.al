namespace Origo.Bifrost.Orchestrator;

using Microsoft.Sales.Document;
using Origo.Bifrost;

/// <summary>
/// Sales.Quote.Send. Sends a sales quote through the Document Sending Profile, as Sales.SalesInvoice.Send does.
/// </summary>
codeunit 10035633 "Sales Quote Send Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
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
        exit(Contract.SalesQuoteDescription());
    end;

    procedure GetKeywords(): Text
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        exit(Contract.SalesQuoteKeywords());
    end;

    procedure GetSelectionDescription(): Text
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        exit(Contract.SalesQuoteSelection());
    end;

    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Envelope := Contract.Envelope(SalesQuoteNumberOrItsSystemidLbl);
        exit(true);
    end;

    procedure GetTarget(var Target: JsonArray): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Target := Contract.Target('quoteNo', 'quoteId', SalesQuoteLbl);
        exit(true);
    end;

    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Contract.Parameters(Parameters, 'quoteNo', 'quoteId');
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Contract.Response(Response, 'SalesQuote', 'customerNo', 'customerName', CustomerLbl);
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Contract.Errors(Errors, SalesQuote2Lbl, 'Sales Header');
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Contract.Effect(Effect, SendsTheSalesQuoteWithTheResolvedLbl);
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
        Contract.RelatedSales(Related, 'Sales.Quote.Send');
        exit(true);
    end;

    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Contract.Workflow(Workflow, 'Sales.Quote.Send', SendThatSalesQuoteLbl);
        exit(true);
    end;

    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Contract.Example(Examples, 'Sales.Quote.Send', 'quoteNo', '1001');
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Overview := Contract.Overview(SalesQuoteLbl, 'Sales.Quote.Pdf');
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    var
        Contract: Codeunit "Doc Send Contract ori";
    begin
        Notes := Contract.Notes('Sales.Quote.Pdf');
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
        SalesQuoteNumberOrItsSystemidLbl: Label 'Sales quote number, or its SystemId.', Comment = 'is-IS=Númer sölutilboðs eða SystemId þess.';
        SalesQuoteLbl: Label 'sales quote', Comment = 'is-IS=sölutilboð';
        CustomerLbl: Label 'Customer', Comment = 'is-IS=Viðskiptamaður';
        SalesQuote2Lbl: Label 'Sales quote', Comment = 'is-IS=Sölutilboð';
        SendsTheSalesQuoteWithTheResolvedLbl: Label 'Sends the sales quote with the resolved profile, as the Send action does.', Comment = 'is-IS=Sendir sölutilboð með forstillingunni sem fannst, eins og aðgerðin Senda gerir.';
        SendThatSalesQuoteLbl: Label 'Send that sales quote.', Comment = 'is-IS=Sendu sölutilboðið.';
}
