namespace Origo.Bifrost.Orchestrator.Test;

using Microsoft.Foundation.Reporting;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Origo.Bifrost.Orchestrator;

/// <summary>
/// Arms the document-send mock for the current session. The subscriber skips the platform send only while armed,
/// so a refusal test still reaches the real checks and a happy-path test never transmits e-mail.
/// </summary>
codeunit 96471 "Doc Send Mock ori"
{
    SingleInstance = true;

    var
        Armed: Boolean;
        Seen: Boolean;
        LastNo: Code[20];
        LastProfile: Code[20];
        LastKind: Text;

    procedure Arm()
    begin
        Armed := true;
        ClearCapture();
    end;

    procedure Disarm()
    begin
        Armed := false;
        ClearCapture();
    end;

    procedure IsArmed(): Boolean
    begin
        exit(Armed);
    end;

    procedure Capture(Kind: Text; DocumentNo: Code[20]; ProfileCode: Code[20])
    begin
        Seen := true;
        LastKind := Kind;
        LastNo := DocumentNo;
        LastProfile := ProfileCode;
    end;

    procedure WasCaptured(): Boolean
    begin
        exit(Seen);
    end;

    procedure CapturedNo(): Code[20]
    begin
        exit(LastNo);
    end;

    procedure CapturedProfile(): Code[20]
    begin
        exit(LastProfile);
    end;

    procedure CapturedKind(): Text
    begin
        exit(LastKind);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Doc Send Process ori", OnBeforeSendSalesDocument, '', false, false)]
    local procedure OnBeforeSendSalesDocument(var SalesHeader: Record "Sales Header"; var DocumentSendingProfile: Record "Document Sending Profile"; var IsHandled: Boolean)
    var
        Kind: Text;
    begin
        if not Armed then
            exit;
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Quote then
            Kind := 'SalesQuote'
        else
            Kind := 'SalesOrderConfirmation';
        Capture(Kind, SalesHeader."No.", DocumentSendingProfile.Code);
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Doc Send Process ori", OnBeforeSendPurchaseDocument, '', false, false)]
    local procedure OnBeforeSendPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var DocumentSendingProfile: Record "Document Sending Profile"; var IsHandled: Boolean)
    begin
        if not Armed then
            exit;
        Capture('PurchaseOrder', PurchaseHeader."No.", DocumentSendingProfile.Code);
        IsHandled := true;
    end;

    local procedure ClearCapture()
    begin
        Seen := false;
        LastNo := '';
        LastProfile := '';
        LastKind := '';
    end;
}
