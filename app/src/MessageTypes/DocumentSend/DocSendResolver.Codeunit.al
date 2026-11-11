namespace Origo.Bifrost.Orchestrator;

using Microsoft.Foundation.Reporting;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Origo.Bifrost;

/// <summary>
/// Resolves the Document Sending Profile for purchase orders, sales quotes and sales order confirmations.
/// Resolution order matches Sales.SalesInvoice.Send: request override, then the vendor or customer profile, then Default.
/// A profile that needs a client is refused before anything is sent.
/// </summary>
codeunit 10035629 "Doc Send Resolver ori"
{
    Access = Internal;
    Permissions = tabledata Customer = R,
                  tabledata Vendor = R,
                  tabledata "Document Sending Profile" = R;

    /// <summary>
    /// Reads the optional documentSendingProfile. A value longer than a profile code, or a value that is not a JSON
    /// string, is refused with InvalidParameterFormat and is never cut.
    /// </summary>
    /// <param name="Argument">The request. Receives the collected error when the value is not acceptable.</param>
    /// <param name="OverrideCode">Receives the profile code, or an empty code when the key was left out.</param>
    /// <returns>True when the value is acceptable or absent.</returns>
    /// <summary>
    /// Reads an optional JSON string. A missing key or JSON null is empty. A non-string, and a string longer than
    /// MaxLength, is InvalidParameterFormat. A longer value is refused and is never cut.
    /// </summary>
    /// <param name="RequestJson">The request object.</param>
    /// <param name="KeyName">Request property name.</param>
    /// <param name="MaxLength">Longest accepted text. Zero means no limit.</param>
    /// <param name="Argument">Receives the coded error.</param>
    /// <param name="Value">Receives the text, or empty when the key is absent.</param>
    /// <returns>True when the value is acceptable or absent.</returns>
    internal procedure TryReadOptionalText(RequestJson: JsonObject; KeyName: Text; MaxLength: Integer; var Argument: Record "Message Argument ori"; var Value: Text): Boolean
    var
        Token: JsonToken;
        Written: Text;
        Shown: Text;
        NotAStringErr: Label 'Parameter "%1" is not a JSON string.', Comment = '%1 = parameter name, is-IS=Færibreyta "%1" er ekki JSON strengur.';
        NotAStringExpectedTok: Label 'a JSON string', Comment = 'is-IS=JSON strengur';
        NotAStringNextStepTok: Label 'Send %1 as a JSON string, or leave the key out.', Comment = '%1 = parameter name, is-IS=Sendu %1 sem JSON streng, eða slepptu lyklinum.';
        TooLongErr: Label 'Parameter "%1" has value "%2", which is longer than %3 characters.', Comment = '%1 = parameter name, %2 = received value, %3 = maximum length, is-IS=Færibreyta "%1" hefur gildið "%2", sem er lengra en %3 stafir.';
        TooLongExpectedTok: Label 'at most %1 characters', Comment = '%1 = maximum length, is-IS=í mesta lagi %1 stafir';
        TooLongNextStepTok: Label 'Send a value of at most %1 characters. A longer value is refused and is never cut.', Comment = '%1 = maximum length, is-IS=Sendu gildi sem er mest %1 stafir að lengd. Lengra gildi er hafnað og er aldrei skorið.';
    begin
        Value := '';
        if not RequestJson.Get(KeyName, Token) then
            exit(true);
        if Token.IsValue() then
            if Token.AsValue().IsNull() then
                exit(true);
        Token.WriteTo(Written);
        if not Written.StartsWith('"') then begin
            Argument.RespondWithError("Bifrost Error Code ori"::InvalidParameterFormat, StrSubstNo(NotAStringErr, KeyName), KeyName, Shorten(Written), NotAStringExpectedTok, StrSubstNo(NotAStringNextStepTok, KeyName));
            exit(false);
        end;
        Value := Token.AsValue().AsText();
        if (MaxLength > 0) and (StrLen(Value) > MaxLength) then begin
            Shown := Shorten(Value);
            Argument.RespondWithError("Bifrost Error Code ori"::InvalidParameterFormat, StrSubstNo(TooLongErr, KeyName, Shown, MaxLength), KeyName, Shown, StrSubstNo(TooLongExpectedTok, MaxLength), StrSubstNo(TooLongNextStepTok, MaxLength));
            Clear(Value);
            exit(false);
        end;
        exit(true);
    end;

    internal procedure TryReadOverride(var Argument: Record "Message Argument ori"; var OverrideCode: Code[20]): Boolean
    var
        ProfileText: Text;
        RequestJson: JsonObject;
    begin
        Clear(OverrideCode);
        RequestJson := Argument.GetRequestJson();
        if not TryReadOptionalText(RequestJson, 'documentSendingProfile', MaxStrLen(OverrideCode), Argument, ProfileText) then
            exit(false);
        OverrideCode := CopyStr(UpperCase(ProfileText), 1, MaxStrLen(OverrideCode));
        exit(true);
    end;

    local procedure Shorten(Value: Text): Text
    begin
        if StrLen(Value) <= 80 then
            exit(Value);
        exit(CopyStr(Value, 1, 77) + '...');
    end;

    /// <summary>
    /// Resolves a profile for a customer or a vendor and refuses one that cannot run without a client.
    /// </summary>
    /// <param name="ForVendor">True for a purchase order (the buy-from vendor). False for a sales document (the sell-to customer).</param>
    /// <param name="PartyNo">Customer or vendor number the document is sent to.</param>
    /// <param name="OverrideCode">Optional one-time profile code. Empty skips the request tier.</param>
    /// <param name="DocumentSendingProfile">Returns the resolved profile.</param>
    /// <param name="Source">Returns Request, Customer, Vendor or Default.</param>
    /// <param name="Argument">Receives the coded error when no usable profile resolves.</param>
    /// <returns>True when a usable profile was resolved.</returns>
    internal procedure TryResolve(ForVendor: Boolean; PartyNo: Code[20]; OverrideCode: Code[20]; var DocumentSendingProfile: Record "Document Sending Profile"; var Source: Text; var Argument: Record "Message Argument ori"): Boolean
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        PartyProfile: Code[20];
        ProfileNotFoundErr: Label 'Document Sending Profile "%1" not found.', Comment = '%1 = profile code, is-IS=Forstilling skjalasendingar "%1" fannst ekki.';
        ProfileNotFoundNextStepTok: Label 'Send the Code of an existing Document Sending Profile, or leave the key out.', Comment = 'is-IS=Sendu kóða forstillingar skjalasendingar sem er til, eða slepptu lyklinum.';
        ProfileExpectedTok: Label 'the Code of an existing Document Sending Profile', Comment = 'is-IS=kóði forstillingar skjalasendingar sem er til';
        PartyProfileMissingErr: Label 'Document Sending Profile "%1" referenced by %2 %3 does not exist.', Comment = '%1 = profile code, %2 = customer or vendor, %3 = party no., is-IS=Forstilling skjalasendingar "%1" sem %2 %3 vísar í er ekki til.';
        PartyProfileNextStepTok: Label 'Fix the profile on the customer or vendor card, or send documentSendingProfile.', Comment = 'is-IS=Lagaðu forstillinguna á viðskiptamanns- eða lánardrottnaspjaldinu, eða sendu documentSendingProfile.';
        NoProfileExpectedTok: Label 'a Document Sending Profile on the customer or vendor, or one profile marked Default', Comment = 'is-IS=forstilling skjalasendingar á viðskiptamanninum eða lánardrottninum, eða ein forstilling merkt sem sjálfgefin';
        NoProfileResolvedErr: Label 'No Document Sending Profile resolved for %1 %2 and no system default profile exists.', Comment = '%1 = customer or vendor, %2 = party no., is-IS=Engin forstilling skjalasendingar fannst fyrir %1 %2 og engin sjálfgefin kerfisforstilling er til.';
        NoProfileNextStepTok: Label 'Send documentSendingProfile, give the customer or vendor a profile, or mark one profile Default.', Comment = 'is-IS=Sendu documentSendingProfile, gefðu viðskiptamanninum eða lánardrottninum forstillingu, eða merktu eina forstillingu sem sjálfgefna.';
        CustomerTok: Label 'customer', Comment = 'is-IS=viðskiptamaður';
        VendorTok: Label 'vendor', Comment = 'is-IS=lánardrottinn';
        PartyTok: Text;
    begin
        Clear(DocumentSendingProfile);
        Source := '';
        if ForVendor then
            PartyTok := VendorTok
        else
            PartyTok := CustomerTok;

        if OverrideCode <> '' then begin
            if not DocumentSendingProfile.Get(OverrideCode) then begin
                Argument.RespondWithError("Bifrost Error Code ori"::RecordNotFound, StrSubstNo(ProfileNotFoundErr, OverrideCode), 'documentSendingProfile', OverrideCode, ProfileExpectedTok, ProfileNotFoundNextStepTok);
                exit(false);
            end;
            Source := 'Request';
            exit(IsUsableWithoutClient(DocumentSendingProfile, Argument));
        end;

        if ForVendor then begin
            Vendor.SetLoadFields("Document Sending Profile");
            if Vendor.Get(PartyNo) then
                PartyProfile := Vendor."Document Sending Profile";
        end else begin
            Customer.SetLoadFields("Document Sending Profile");
            if Customer.Get(PartyNo) then
                PartyProfile := Customer."Document Sending Profile";
        end;

        if PartyProfile <> '' then begin
            if not DocumentSendingProfile.Get(PartyProfile) then begin
                Argument.RespondWithError("Bifrost Error Code ori"::PreconditionFailed, StrSubstNo(PartyProfileMissingErr, PartyProfile, PartyTok, PartyNo), 'documentSendingProfile', PartyProfile, ProfileExpectedTok, PartyProfileNextStepTok);
                exit(false);
            end;
            if ForVendor then
                Source := 'Vendor'
            else
                Source := 'Customer';
            exit(IsUsableWithoutClient(DocumentSendingProfile, Argument));
        end;

        DocumentSendingProfile.Reset();
        DocumentSendingProfile.SetRange(Default, true);
        if DocumentSendingProfile.FindFirst() then begin
            Source := 'Default';
            exit(IsUsableWithoutClient(DocumentSendingProfile, Argument));
        end;

        Argument.RespondWithError("Bifrost Error Code ori"::PreconditionFailed, StrSubstNo(NoProfileResolvedErr, PartyTok, PartyNo), 'documentSendingProfile', PartyNo, NoProfileExpectedTok, NoProfileNextStepTok);
        exit(false);
    end;

    local procedure IsUsableWithoutClient(DocumentSendingProfile: Record "Document Sending Profile"; var Argument: Record "Message Argument ori"): Boolean
    var
        DiskProfileErr: Label 'Document Sending Profile "%1" saves the document to disk, which needs a client; it cannot run through the API.', Comment = '%1 = profile code, is-IS=Forstilling skjalasendingar "%1" vistar skjalið á disk, sem krefst biðlara; það er ekki hægt að keyra það í gegnum API.';
        DiskProfileNextStepTok: Label 'Send documentSendingProfile with a profile that has no Disk channel: E-Mail, Electronic Document, or Printer with default settings.', Comment = 'is-IS=Sendu documentSendingProfile með forstillingu sem hefur enga Disk-rás: tölvupóst, rafrænt skjal eða prentara með sjálfgefnum stillingum.';
        DiskProfileExpectedTok: Label 'a Document Sending Profile without a Disk channel', Comment = 'is-IS=forstilling skjalasendingar án Disk-rásar';
        PromptEmailErr: Label 'Document Sending Profile "%1" prompts for e-mail settings, which needs a client; it cannot run through the API.', Comment = '%1 = profile code, is-IS=Forstilling skjalasendingar "%1" biður um tölvupóststillingar, sem krefst biðlara; það er ekki hægt að keyra hana í gegnum API.';
        PromptEmailNextStepLbl: Label 'Pass documentSendingProfile with E-Mail set to Yes (Use Default Settings), or change the resolved profile to use default e-mail settings. Nothing was sent.', Comment = 'is-IS=Sendu documentSendingProfile með tölvupóst stilltan á Yes (Use Default Settings), eða breyttu forstillingunni þannig að hún noti sjálfgefnar tölvupóststillingar. Ekkert var sent.';
        PromptEmailExpectedLbl: Label 'a Document Sending Profile without an e-mail settings prompt', Comment = 'is-IS=forstilling skjalasendingar sem biður ekki um tölvupóststillingar';
    begin
        if DocumentSendingProfile.Disk <> DocumentSendingProfile.Disk::No then begin
            Argument.RespondWithError("Bifrost Error Code ori"::PreconditionFailed, StrSubstNo(DiskProfileErr, DocumentSendingProfile.Code), 'documentSendingProfile', DocumentSendingProfile.Code, DiskProfileExpectedTok, DiskProfileNextStepTok);
            exit(false);
        end;
        if DocumentSendingProfile."E-Mail" = DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)" then begin
            Argument.RespondWithError("Bifrost Error Code ori"::PreconditionFailed, StrSubstNo(PromptEmailErr, DocumentSendingProfile.Code), 'documentSendingProfile', DocumentSendingProfile.Code, PromptEmailExpectedLbl, PromptEmailNextStepLbl);
            exit(false);
        end;
        exit(true);
    end;
}
