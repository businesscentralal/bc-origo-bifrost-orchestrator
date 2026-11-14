namespace Origo.Bifrost.Orchestrator;

using Microsoft.Foundation.Reporting;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Origo.Bifrost;

/// <summary>
/// Sends a purchase order, sales quote or sales order confirmation through a Document Sending Profile.
/// Purchase orders call Purchase Header.SendProfile. Quotes and order confirmations call Document Sending Profile.Send
/// with report usage S.Quote or S.Order, because Sales Header has no SendProfile. Validation finishes before anything
/// is sent. Tests subscribe to the before-send events and skip the platform send so no e-mail leaves a test run.
/// </summary>
codeunit 10035630 "Doc Send Process ori"
{
    Access = Internal;
    TableNo = "Message Argument ori";
    Permissions = tabledata "Sales Header" = RM,
                  tabledata "Purchase Header" = RM,
                  tabledata Customer = R,
                  tabledata Vendor = R,
                  tabledata "Document Sending Profile" = R;

    var
        SentMsg: Label 'Document sent successfully.', Comment = 'is-IS=Skjal sent.';

    trigger OnRun()
    begin
        Send(Rec);
    end;

    /// <summary>
    /// Checks the licence, the request, the document and the profile, then sends inside Codeunit.Run so a
    /// platform failure comes back as BusinessCentralError. Nothing is sent when a check fails.
    /// </summary>
    /// <param name="Argument">Message argument. Type selects the document.</param>
    internal procedure Execute(var Argument: Record "Message Argument ori")
    begin
        Argument.AssertVersion1();
        Argument.AssertIsLicensed();
        if not Ready(Argument) then
            exit;
        if Argument."Omit Commit" then
            Codeunit.Run(Codeunit::"Doc Send Process ori", Argument)
        else
            if not Codeunit.Run(Codeunit::"Doc Send Process ori", Argument) then
                Argument.RespondWithLastError();
    end;

    /// <summary>
    /// Raised before a sales document is sent. A subscriber that sets IsHandled skips SendProfile.
    /// </summary>
    /// <param name="SalesHeader">The quote or order that would be sent.</param>
    /// <param name="DocumentSendingProfile">The resolved profile.</param>
    /// <param name="IsHandled">Set true to skip the real send.</param>
    [IntegrationEvent(false, false)]
    internal procedure OnBeforeSendSalesDocument(var SalesHeader: Record "Sales Header"; var DocumentSendingProfile: Record "Document Sending Profile"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before a purchase order is sent. A subscriber that sets IsHandled skips SendProfile.
    /// </summary>
    /// <param name="PurchaseHeader">The purchase order that would be sent.</param>
    /// <param name="DocumentSendingProfile">The resolved profile.</param>
    /// <param name="IsHandled">Set true to skip the real send.</param>
    [IntegrationEvent(false, false)]
    internal procedure OnBeforeSendPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var DocumentSendingProfile: Record "Document Sending Profile"; var IsHandled: Boolean)
    begin
    end;

    local procedure Ready(var Argument: Record "Message Argument ori"): Boolean
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        Resolver: Codeunit "Doc Send Resolver ori";
        OverrideCode: Code[20];
        Source: Text;
        ForVendor: Boolean;
        PartyNo: Code[20];
        RequestOk: Boolean;
    begin
        case Argument.Type of
            "Message Type ori"::"Purchase.Order.Send":
                begin
                    ForVendor := true;
                    if not HasTableReadPermission(Argument, Database::"Purchase Header") then
                        exit(false);
                end;
            "Message Type ori"::"Sales.Quote.Send",
            "Message Type ori"::"Sales.OrderConfirmation.Send":
                if not HasTableReadPermission(Argument, Database::"Sales Header") then
                    exit(false);
            else
                exit(false);
        end;

        RequestOk := Resolver.TryReadOverride(Argument, OverrideCode);
        if not TryFindDocument(Argument, SalesHeader, PurchaseHeader) then
            exit(false);
        if not RequestOk then
            exit(false);

        if ForVendor then
            PartyNo := PurchaseHeader."Buy-from Vendor No."
        else
            PartyNo := SalesHeader."Sell-to Customer No.";
        if not Resolver.TryResolve(ForVendor, PartyNo, OverrideCode, DocumentSendingProfile, Source, Argument) then
            exit(false);
        if not HasEmailWhenRequired(ForVendor, SalesHeader, PurchaseHeader, DocumentSendingProfile, Argument) then
            exit(false);
        exit(true);
    end;

    local procedure Send(var Argument: Record "Message Argument ori")
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        Resolver: Codeunit "Doc Send Resolver ori";
        OverrideCode: Code[20];
        Source: Text;
        ForVendor: Boolean;
        PartyNo: Code[20];
        IsHandled: Boolean;
    begin
        case Argument.Type of
            "Message Type ori"::"Purchase.Order.Send":
                ForVendor := true;
            "Message Type ori"::"Sales.Quote.Send",
            "Message Type ori"::"Sales.OrderConfirmation.Send":
                ForVendor := false;
            else
                exit;
        end;

        if not Resolver.TryReadOverride(Argument, OverrideCode) then
            exit;
        if not TryFindDocument(Argument, SalesHeader, PurchaseHeader) then
            exit;
        if ForVendor then
            PartyNo := PurchaseHeader."Buy-from Vendor No."
        else
            PartyNo := SalesHeader."Sell-to Customer No.";
        if not Resolver.TryResolve(ForVendor, PartyNo, OverrideCode, DocumentSendingProfile, Source, Argument) then
            exit;
        if not HasEmailWhenRequired(ForVendor, SalesHeader, PurchaseHeader, DocumentSendingProfile, Argument) then
            exit;

        if ForVendor then begin
            OnBeforeSendPurchaseDocument(PurchaseHeader, DocumentSendingProfile, IsHandled);
            if not IsHandled then
                PurchaseHeader.SendProfile(DocumentSendingProfile);
            WritePurchaseSuccess(Argument, PurchaseHeader, DocumentSendingProfile, Source);
        end else begin
            OnBeforeSendSalesDocument(SalesHeader, DocumentSendingProfile, IsHandled);
            if not IsHandled then
                SendSalesDocument(Argument.Type, SalesHeader, DocumentSendingProfile);
            WriteSalesSuccess(Argument, SalesHeader, DocumentSendingProfile, Source);
        end;
    end;

    local procedure TryFindDocument(var Argument: Record "Message Argument ori"; var SalesHeader: Record "Sales Header"; var PurchaseHeader: Record "Purchase Header"): Boolean
    var
        DocumentNo: Code[20];
        DocumentId: Guid;
        HasNo: Boolean;
        HasId: Boolean;
        NotFoundErr: Label '%1 %2 was not found.', Comment = '%1 = document caption, %2 = number or id, is-IS=%1 %2 fannst ekki.';
        NotFoundNextStepTok: Label 'Send the document number or SystemId of an existing document of this type.', Comment = 'is-IS=Sendu númer eða SystemId skjals af þessari tegund sem er til.';
        NotFoundExpectedTok: Label 'the number or SystemId of an existing document of this type', Comment = 'is-IS=númer eða SystemId skjals af þessari tegund sem er til';
        MissingErr: Label 'Send the document number or SystemId.', Comment = 'is-IS=Sendu númer skjals eða SystemId.';
        MissingNextStepTok: Label 'Put the number in subject or data.documentNo, or the SystemId in subject or data.documentId.', Comment = 'is-IS=Settu númerið í subject eða data.documentNo, eða SystemId í subject eða data.documentId.';
        MissingExpectedTok: Label 'a document number or SystemId', Comment = 'is-IS=númer skjals eða SystemId';
        ShownId: Text;
    begin
        if not TryReadIdentifiers(Argument, DocumentNo, DocumentId, HasNo, HasId) then
            exit(false);
        if not HasNo and not HasId then begin
            Argument.RespondWithError("Bifrost Error Code ori"::MissingParameter, MissingErr, 'documentNo', '', MissingExpectedTok, MissingNextStepTok);
            exit(false);
        end;

        if Argument.Type = "Message Type ori"::"Purchase.Order.Send" then begin
            if not FindPurchaseOrder(DocumentNo, DocumentId, HasNo, HasId, PurchaseHeader) then begin
                if HasNo then
                    ShownId := DocumentNo
                else
                    ShownId := Format(DocumentId, 0, 4);
                Argument.RespondWithError("Bifrost Error Code ori"::RecordNotFound, StrSubstNo(NotFoundErr, 'Purchase order', ShownId), 'documentNo', ShownId, NotFoundExpectedTok, NotFoundNextStepTok);
                exit(false);
            end;
            exit(true);
        end;

        if not FindSalesDocument(Argument.Type, DocumentNo, DocumentId, HasNo, HasId, SalesHeader) then begin
            if HasNo then
                ShownId := DocumentNo
            else
                ShownId := Format(DocumentId, 0, 4);
            Argument.RespondWithError("Bifrost Error Code ori"::RecordNotFound, StrSubstNo(NotFoundErr, SalesCaption(Argument.Type), ShownId), 'documentNo', ShownId, NotFoundExpectedTok, NotFoundNextStepTok);
            exit(false);
        end;
        exit(true);
    end;

    local procedure TryReadIdentifiers(var Argument: Record "Message Argument ori"; var DocumentNo: Code[20]; var DocumentId: Guid; var HasNo: Boolean; var HasId: Boolean): Boolean
    var
        Resolver: Codeunit "Doc Send Resolver ori";
        RequestJson: JsonObject;
        NumberText: Text;
        IdText: Text;
        SpecificNo: Text;
        SpecificId: Text;
        SubjectText: Text;
        SpecificNoKey: Text;
        SpecificIdKey: Text;
        NumbersOk: Boolean;
        IdsOk: Boolean;
        NotAGuidErr: Label 'documentId is not a GUID.', Comment = 'is-IS=documentId er ekki GUID.';
        NotAGuidExpectedTok: Label 'a GUID', Comment = 'is-IS=GUID';
        NotAGuidNextStepTok: Label 'Send the SystemId as a GUID, or send the document number.', Comment = 'is-IS=Sendu SystemId sem GUID, eða sendu skjalnúmerið.';
    begin
        RequestJson := Argument.GetRequestJson();
        case Argument.Type of
            "Message Type ori"::"Sales.Quote.Send":
                begin
                    SpecificNoKey := 'quoteNo';
                    SpecificIdKey := 'quoteId';
                end;
            else begin
                SpecificNoKey := 'orderNo';
                SpecificIdKey := 'orderId';
            end;
        end;

        NumbersOk := Resolver.TryReadOptionalText(RequestJson, 'documentNo', MaxStrLen(DocumentNo), Argument, NumberText);
        NumbersOk := Resolver.TryReadOptionalText(RequestJson, SpecificNoKey, MaxStrLen(DocumentNo), Argument, SpecificNo) and NumbersOk;
        IdsOk := Resolver.TryReadOptionalText(RequestJson, 'documentId', 50, Argument, IdText);
        IdsOk := Resolver.TryReadOptionalText(RequestJson, SpecificIdKey, 50, Argument, SpecificId) and IdsOk;
        if not NumbersOk or not IdsOk then
            exit(false);

        SubjectText := Argument.Subject;
        if not Agree(Argument, NumberText, SpecificNo, 'documentNo') then
            exit(false);
        if not Agree(Argument, IdText, SpecificId, 'documentId') then
            exit(false);
        if SubjectText <> '' then
            if IsGuidText(SubjectText) then begin
                if not Agree(Argument, IdText, SubjectText, 'subject') then
                    exit(false);
            end else
                if not Agree(Argument, NumberText, SubjectText, 'subject') then
                    exit(false);

        if NumberText <> '' then begin
            DocumentNo := CopyStr(NumberText, 1, MaxStrLen(DocumentNo));
            HasNo := true;
        end;
        if IdText <> '' then begin
            if not TryParseGuid(IdText, DocumentId) then begin
                Argument.RespondWithError("Bifrost Error Code ori"::InvalidParameterFormat, NotAGuidErr, 'documentId', IdText, NotAGuidExpectedTok, NotAGuidNextStepTok);
                exit(false);
            end;
            HasId := true;
        end;
        exit(true);
    end;

    local procedure Agree(var Argument: Record "Message Argument ori"; var Current: Text; Candidate: Text; ParameterName: Text): Boolean
    var
        ConflictErr: Label 'The identifiers name different documents.', Comment = 'is-IS=Auðkennin nefna mismunandi skjöl.';
        ConflictNextStepTok: Label 'Send one document number or one SystemId, or send the same document in every key.', Comment = 'is-IS=Sendu eitt skjalnúmer eða eitt SystemId, eða sama skjalið í öllum lyklum.';
        ConflictExpectedTok: Label 'one document', Comment = 'is-IS=eitt skjal';
    begin
        if Candidate = '' then
            exit(true);
        if Current = '' then begin
            Current := Candidate;
            exit(true);
        end;
        if UpperCase(DelChr(Current, '=', '{}')) = UpperCase(DelChr(Candidate, '=', '{}')) then
            exit(true);
        Argument.RespondWithError("Bifrost Error Code ori"::ConflictingIdentifiers, ConflictErr, ParameterName, Candidate, ConflictExpectedTok, ConflictNextStepTok);
        exit(false);
    end;

    local procedure FindPurchaseOrder(DocumentNo: Code[20]; DocumentId: Guid; HasNo: Boolean; HasId: Boolean; var PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        if HasId then begin
            if not PurchaseHeader.GetBySystemId(DocumentId) then
                exit(false);
            if PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::Order then
                exit(false);
            if HasNo and (PurchaseHeader."No." <> DocumentNo) then
                exit(false);
        end else begin
            PurchaseHeader.SetRange("No.", DocumentNo);
            if not PurchaseHeader.FindFirst() then
                exit(false);
        end;
        PurchaseHeader.SetRecFilter();
        exit(true);
    end;

    local procedure FindSalesDocument(MessageType: Enum "Message Type ori"; DocumentNo: Code[20]; DocumentId: Guid; HasNo: Boolean; HasId: Boolean; var SalesHeader: Record "Sales Header"): Boolean
    var
        ExpectedType: Enum "Sales Document Type";
    begin
        if MessageType = "Message Type ori"::"Sales.Quote.Send" then
            ExpectedType := SalesHeader."Document Type"::Quote
        else
            ExpectedType := SalesHeader."Document Type"::Order;
        if HasId then begin
            if not SalesHeader.GetBySystemId(DocumentId) then
                exit(false);
            if SalesHeader."Document Type" <> ExpectedType then
                exit(false);
            if HasNo and (SalesHeader."No." <> DocumentNo) then
                exit(false);
        end else begin
            SalesHeader.SetRange("Document Type", ExpectedType);
            SalesHeader.SetRange("No.", DocumentNo);
            if not SalesHeader.FindFirst() then
                exit(false);
        end;
        SalesHeader.SetRecFilter();
        exit(true);
    end;

    local procedure HasEmailWhenRequired(ForVendor: Boolean; SalesHeader: Record "Sales Header"; PurchaseHeader: Record "Purchase Header"; DocumentSendingProfile: Record "Document Sending Profile"; var Argument: Record "Message Argument ori"): Boolean
    var
        PartyNo: Code[20];
        Email: Text;
        MissingEmailErr: Label '%1 %2 has no e-mail address for Document Sending Profile %3.', Comment = '%1 = customer or vendor, %2 = party no., %3 = profile code, is-IS=%1 %2 hefur ekkert tölvupóstfang fyrir forstillingu skjalasendingar %3.';
        MissingEmailNextStepLbl: Label 'Set the e-mail address or select a sending profile that does not send e-mail, then retry. Nothing was sent.', Comment = 'is-IS=Stilltu tölvupóstfangið eða veldu forstillingu sem sendir ekki tölvupóst og reyndu aftur. Ekkert var sent.';
        EmailExpectedLbl: Label 'an e-mail address for the selected sending profile', Comment = 'is-IS=tölvupóstfang fyrir valda forstillingu';
        CustomerTok: Label 'Customer', Comment = 'is-IS=Viðskiptamaður';
        VendorTok: Label 'Vendor', Comment = 'is-IS=Lánardrottinn';
    begin
        if DocumentSendingProfile."E-Mail" = DocumentSendingProfile."E-Mail"::No then
            exit(true);
        if ForVendor then begin
            PartyNo := PurchaseHeader."Buy-from Vendor No.";
            Email := VendorEmail(PurchaseHeader);
            if Email = '' then begin
                Argument.RespondWithError("Bifrost Error Code ori"::PreconditionFailed, StrSubstNo(MissingEmailErr, VendorTok, PartyNo, DocumentSendingProfile.Code), 'email', '', EmailExpectedLbl, MissingEmailNextStepLbl);
                exit(false);
            end;
        end else begin
            PartyNo := SalesHeader."Bill-to Customer No.";
            Email := SalesEmail(SalesHeader);
            if Email = '' then begin
                Argument.RespondWithError("Bifrost Error Code ori"::PreconditionFailed, StrSubstNo(MissingEmailErr, CustomerTok, PartyNo, DocumentSendingProfile.Code), 'email', '', EmailExpectedLbl, MissingEmailNextStepLbl);
                exit(false);
            end;
        end;
        exit(true);
    end;

    local procedure SalesEmail(SalesHeader: Record "Sales Header"): Text
    var
        Customer: Record Customer;
    begin
        Customer.SetLoadFields("E-Mail");
        if Customer.Get(SalesHeader."Bill-to Customer No.") then
            exit(Customer."E-Mail");
    end;

    local procedure VendorEmail(PurchaseHeader: Record "Purchase Header"): Text
    var
        Vendor: Record Vendor;
    begin
        Vendor.SetLoadFields("E-Mail");
        if Vendor.Get(PurchaseHeader."Buy-from Vendor No.") then
            exit(Vendor."E-Mail");
    end;

    local procedure WriteSalesSuccess(var Argument: Record "Message Argument ori"; SalesHeader: Record "Sales Header"; DocumentSendingProfile: Record "Document Sending Profile"; Source: Text)
    var
        ResponseJson: JsonObject;
        DocumentTypeText: Text;
    begin
        if Argument.Type = "Message Type ori"::"Sales.Quote.Send" then
            DocumentTypeText := 'SalesQuote'
        else
            DocumentTypeText := 'SalesOrderConfirmation';
        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('documentType', DocumentTypeText);
        ResponseJson.Add('documentNo', SalesHeader."No.");
        ResponseJson.Add('documentId', Format(SalesHeader.SystemId, 0, 4));
        ResponseJson.Add('customerNo', SalesHeader."Sell-to Customer No.");
        ResponseJson.Add('customerName', SalesHeader."Sell-to Customer Name");
        ResponseJson.Add('documentSendingProfileCode', DocumentSendingProfile.Code);
        ResponseJson.Add('documentSendingProfileSource', Source);
        ResponseJson.Add('message', SentMsg);
        Argument.SetResponseJson(ResponseJson);
        Argument."Content Type" := Argument.GetContentTypeJson();
    end;

    local procedure WritePurchaseSuccess(var Argument: Record "Message Argument ori"; PurchaseHeader: Record "Purchase Header"; DocumentSendingProfile: Record "Document Sending Profile"; Source: Text)
    var
        ResponseJson: JsonObject;
    begin
        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('documentType', 'PurchaseOrder');
        ResponseJson.Add('documentNo', PurchaseHeader."No.");
        ResponseJson.Add('documentId', Format(PurchaseHeader.SystemId, 0, 4));
        ResponseJson.Add('vendorNo', PurchaseHeader."Buy-from Vendor No.");
        ResponseJson.Add('vendorName', PurchaseHeader."Buy-from Vendor Name");
        ResponseJson.Add('documentSendingProfileCode', DocumentSendingProfile.Code);
        ResponseJson.Add('documentSendingProfileSource', Source);
        ResponseJson.Add('message', SentMsg);
        Argument.SetResponseJson(ResponseJson);
        Argument."Content Type" := Argument.GetContentTypeJson();
    end;

    local procedure SendSalesDocument(MessageType: Enum "Message Type ori"; var SalesHeader: Record "Sales Header"; var DocumentSendingProfile: Record "Document Sending Profile")
    var
        ReportSelections: Record "Report Selections";
        Usage: Enum "Report Selection Usage";
    begin
        if MessageType = "Message Type ori"::"Sales.Quote.Send" then
            Usage := ReportSelections.Usage::"S.Quote"
        else
            Usage := ReportSelections.Usage::"S.Order";
        // Bill-to matches Sales Header.EmailRecords. The profile itself was resolved from the sell-to customer.
        DocumentSendingProfile.Send(
            Usage.AsInteger(), SalesHeader, SalesHeader."No.", SalesHeader."Bill-to Customer No.",
            SalesHeader.GetDocTypeTxt(), SalesHeader.FieldNo("Bill-to Customer No."), SalesHeader.FieldNo("No."));
        if SalesHeader."Document Type" <> SalesHeader."Document Type"::Quote then
            exit;
        SalesHeader.Find();
        SalesHeader."Quote Sent to Customer" := CurrentDateTime();
        SalesHeader.Modify();
    end;

    local procedure HasTableReadPermission(var Argument: Record "Message Argument ori"; TableId: Integer): Boolean
    var
        RecRef: RecordRef;
        ReadPermissionDeniedErr: Label 'Read permission denied for table %1.', Comment = '%1 = table number, is-IS=Lesheimild neitað fyrir töflu %1.';
        ReadPermissionExpectedTxt: Label 'read permission on the data of table %1', Comment = '%1 = table number, is-IS=lesheimild á gögnum í töflu %1';
        ReadPermissionNextStepTxt: Label 'Ask an administrator for a permission set that reads the table.', Comment = 'is-IS=Biddu kerfisstjóra um heimildasamstæðu sem les töfluna.';
    begin
        RecRef.Open(TableId);
        if RecRef.ReadPermission() then begin
            RecRef.Close();
            exit(true);
        end;
        RecRef.Close();
        Argument.RespondWithError("Bifrost Error Code ori"::PermissionDenied, StrSubstNo(ReadPermissionDeniedErr, Format(TableId)), '', '', StrSubstNo(ReadPermissionExpectedTxt, TableId), ReadPermissionNextStepTxt);
        exit(false);
    end;

    local procedure SalesCaption(MessageType: Enum "Message Type ori"): Text
    begin
        if MessageType = "Message Type ori"::"Sales.Quote.Send" then
            exit('Sales quote');
        exit('Sales order');
    end;

    local procedure IsGuidText(Value: Text): Boolean
    var
        Parsed: Guid;
    begin
        exit(TryParseGuid(Value, Parsed));
    end;

    local procedure TryParseGuid(Value: Text; var Parsed: Guid): Boolean
    begin
        Value := DelChr(Value, '=', '{}');
        if StrLen(Value) <> 36 then
            exit(false);
        exit(Evaluate(Parsed, Value));
    end;
}
