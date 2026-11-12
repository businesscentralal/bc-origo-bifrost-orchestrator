namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

/// <summary>
/// Shared contract chapters for Purchase.Order.Send, Sales.Quote.Send and Sales.OrderConfirmation.Send.
/// The matching PDF message types are a catalog dependency (issues 91-93) and are named in the notes.
/// They are not related-chapter entries until those types exist, because Foundation refuses an unknown name.
/// </summary>
codeunit 10035631 "Doc Send Contract ori"
{
    Access = Internal;

    internal procedure PurchaseOrderDescription(): Text[250]
    var
        DescriptionLbl: Label 'Sends a purchase order through the resolved Document Sending Profile.', Comment = 'is-IS=Sendir innkaupapöntun með forstillingu skjalasendingar sem leyst er upp.';
    begin
        exit(DescriptionLbl);
    end;

    internal procedure SalesQuoteDescription(): Text[250]
    var
        DescriptionLbl: Label 'Sends a sales quote through the resolved Document Sending Profile.', Comment = 'is-IS=Sendir sölutilboð með forstillingu skjalasendingar sem leyst er upp.';
    begin
        exit(DescriptionLbl);
    end;

    internal procedure OrderConfirmationDescription(): Text[250]
    var
        DescriptionLbl: Label 'Sends a sales order confirmation through the resolved Document Sending Profile.', Comment = 'is-IS=Sendir sölupöntunarstaðfestingu með forstillingu skjalasendingar sem leyst er upp.';
    begin
        exit(DescriptionLbl);
    end;

    internal procedure PurchaseOrderKeywords(): Text
    var
        KeywordsLbl: Label 'send purchase order, email the purchase order, send the order to the vendor, purchase order delivery, e-mail the PO, deliver the purchase order', Comment = 'is-IS=senda innkaupapöntun, senda innkaupapöntun í tölvupósti, senda pöntun á lánardrottin, afhending innkaupapöntunar, tölvupóstur með innkaupapöntun, afhenda innkaupapöntunina';
    begin
        exit(KeywordsLbl);
    end;

    internal procedure SalesQuoteKeywords(): Text
    var
        KeywordsLbl: Label 'send sales quote, email the quote, send the quote to the customer, quote delivery, e-mail the offer, deliver the quote', Comment = 'is-IS=senda sölutilboð, senda tilboð í tölvupósti, senda tilboð til viðskiptamanns, afhending tilboðs, tölvupóstur með tilboði, afhenda tilboðið';
    begin
        exit(KeywordsLbl);
    end;

    internal procedure OrderConfirmationKeywords(): Text
    var
        KeywordsLbl: Label 'send order confirmation, email the order confirmation, send the sales order to the customer, order confirmation delivery, e-mail the confirmation, deliver the order confirmation', Comment = 'is-IS=senda pöntunarstaðfestingu, senda pöntunarstaðfestingu í tölvupósti, senda sölupöntun til viðskiptamanns, afhending pöntunarstaðfestingar, tölvupóstur með staðfestingu, afhenda pöntunarstaðfestinguna';
    begin
        exit(KeywordsLbl);
    end;

    internal procedure PurchaseOrderSelection(): Text
    var
        SelectionLbl: Label 'Send a purchase order to the vendor through a document sending profile, as the Send action on the purchase order does. Irreversible. To get a PDF without sending, use Purchase.Order.Pdf when that type is available.', Comment = 'is-IS=Senda lánardrottni innkaupapöntun með forstillingu skjalasendingar, eins og aðgerðin Senda á innkaupapöntuninni. Óafturkræft. Til að fá PDF án sendingar, notaðu Purchase.Order.Pdf þegar sú tegund er tiltæk.';
    begin
        exit(SelectionLbl);
    end;

    internal procedure SalesQuoteSelection(): Text
    var
        SelectionLbl: Label 'Send a sales quote to the customer through a document sending profile, as the Send action on the quote does. Irreversible. To get a PDF without sending, use Sales.Quote.Pdf when that type is available.', Comment = 'is-IS=Senda viðskiptamanni sölutilboð með forstillingu skjalasendingar, eins og aðgerðin Senda á tilboðinu. Óafturkræft. Til að fá PDF án sendingar, notaðu Sales.Quote.Pdf þegar sú tegund er tiltæk.';
    begin
        exit(SelectionLbl);
    end;

    internal procedure OrderConfirmationSelection(): Text
    var
        SelectionLbl: Label 'Send a sales order confirmation to the customer through a document sending profile, as the Send action on the sales order does. Irreversible. To get a PDF without sending, use Sales.OrderConfirmation.Pdf when that type is available.', Comment = 'is-IS=Senda viðskiptamanni sölupöntunarstaðfestingu með forstillingu skjalasendingar, eins og aðgerðin Senda á sölupöntuninni. Óafturkræft. Til að fá PDF án sendingar, notaðu Sales.OrderConfirmation.Pdf þegar sú tegund er tiltæk.';
    begin
        exit(SelectionLbl);
    end;

    internal procedure Envelope(SubjectDescription: Text): JsonObject
    var
        Parts: Codeunit "Orch B1 Contract Parts ori";
        Forms: List of [Text];
    begin
        Forms.Add('guid');
        Forms.Add('code');
        exit(Parts.Envelope(Forms, SubjectDescription, false));
    end;

    internal procedure Target(NumberKey: Text; IdKey: Text; DocumentCaption: Text) Result: JsonArray
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Result.Add(ContractMgt.TargetEntry('subject', 'guid|code', TargetSubjectLbl));
        Result.Add(ContractMgt.TargetEntry('data.documentNo', 'code', StrSubstNo(TargetNumberLbl, NumberKey)));
        Result.Add(ContractMgt.TargetEntry('data.' + NumberKey, 'code', TargetAliasLbl));
        Result.Add(ContractMgt.TargetEntry('data.documentId', 'guid', TargetIdLbl));
        Result.Add(ContractMgt.TargetEntry('data.' + IdKey, 'guid', TargetIdAliasLbl));
    end;

    internal procedure Parameters(var ParameterList: JsonArray; NumberKey: Text; IdKey: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        ParameterList.Add(ContractMgt.Parameter('documentNo', 'string', false, DocumentNumberAGuidBelongsInDocumentidLbl));
        ParameterList.Add(ContractMgt.Parameter(NumberKey, 'string', false, SameAsDocumentnoWhenBothAreSentLbl));
        ParameterList.Add(ContractMgt.Parameter('documentId', 'string', false, SystemidGuidOfTheDocumentLbl));
        ParameterList.Add(ContractMgt.Parameter(IdKey, 'string', false, SameAsDocumentidWhenBothAreSentLbl));
        ParameterList.Add(ContractMgt.Parameter('documentSendingProfile', 'string', false,
            CodeOfTheDocumentSendingProfileForLbl));
    end;

    internal procedure Response(var ResponseObject: JsonObject; DocumentTypeText: Text; PartyNoName: Text; PartyNameName: Text; PartyCaption: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Fields: JsonArray;
        Sources: JsonArray;
        Source: JsonObject;
    begin
        Parts.AddResponseField(Fields, 'status', 'string', 'Success.');
        Parts.AddResponseField(Fields, 'documentType', 'string', StrSubstNo(ResponseTypeLbl, DocumentTypeText));
        Parts.AddResponseField(Fields, 'documentNo', 'string', NoOfTheDocumentLbl);
        Parts.AddResponseField(Fields, 'documentId', 'string', SystemidOfTheDocumentGuidNoBracesLbl);
        Parts.AddResponseField(Fields, PartyNoName, 'string', StrSubstNo(ResponsePartyNoLbl, PartyCaption));
        Parts.AddResponseField(Fields, PartyNameName, 'string', StrSubstNo(ResponsePartyNameLbl, PartyCaption));
        Parts.AddResponseField(Fields, 'documentSendingProfileCode', 'string', CodeOfTheDocumentSendingProfileThatLbl);
        Sources.Add('Request');
        if PartyNoName = 'vendorNo' then
            Sources.Add('Vendor')
        else
            Sources.Add('Customer');
        Sources.Add('Default');
        Source := ContractMgt.ResponseField('documentSendingProfileSource', 'string', WhereTheProfileCameFromRequestTheLbl);
        Source.Add('allowed', Sources);
        Fields.Add(Source);
        Parts.AddResponseField(Fields, 'message', 'string', DocumentSentSuccessfullyLbl);
        ResponseObject := Parts.Response(Fields, 'text/json');
    end;

    internal procedure Errors(var ErrorList: JsonArray; DocumentCaption: Text; TableCaptionText: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        ErrorList.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, ReadPermissionDeniedLbl,
            StrSubstNo(ReadDeniedLbl, TableCaptionText), StrSubstNo(GrantReadLbl, TableCaptionText)));
        ErrorList.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::MissingParameter, SendTheDocumentNumberOrSystemidLbl,
            SubjectAndTheDocumentKeysWereAllLbl, PutTheNumberInSubjectOrDataLbl));
        ErrorList.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::RecordNotFound, StrSubstNo(NotFoundLbl, DocumentCaption),
            StrSubstNo(NotFoundCauseLbl, DocumentCaption), SendTheDocumentNumberOrSystemidOfLbl));
        ErrorList.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::InvalidParameterFormat, ParameterDocumentsendingprofileIsNotAJsonStringLbl,
            DocumentsendingprofileWasSentAsAnObjectOrLbl,
            SendTheValueAsAJsonStringLbl));
        ErrorList.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::InvalidParameterFormat, DocumentidIsNotAGuidLbl,
            DocumentidOrTheIdKeyIsNotLbl, SendTheSystemidAsAGuidOrLbl));
        ErrorList.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::ConflictingIdentifiers, TheIdentifiersNameDifferentDocumentsLbl,
            TwoKeysWereSentAndTheyDoLbl, SendOneDocumentNumberOrOneSystemidLbl));
        ErrorList.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::RecordNotFound, DocumentSendingProfileCodeNotFoundLbl,
            DocumentsendingprofileNamesAProfileThatDoesNotLbl, SendTheCodeOfAnExistingDocumentLbl));
        ErrorList.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PreconditionFailed, ThePartyProfileDoesNotExistOrLbl,
            NoDocumentsendingprofileWasSentAndTheCustomerLbl,
            SendDocumentsendingprofileFixThePartyProfileOrLbl));
        ErrorList.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PreconditionFailed, DocumentSendingProfileCodeSavesTheDocumentLbl,
            TheResolvedProfileHasADiskChannelLbl, SendAProfileThatHasNoDiskLbl));
        ErrorList.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PreconditionFailed, TheResolvedProfilePromptsForEMailLbl,
            EMailIsYesPromptForSettingsLbl, PassAProfileWithEMailSetLbl));
        ErrorList.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PreconditionFailed, TheCustomerOrVendorHasNoELbl,
            TheResolvedProfileSendsEMailAndLbl, SetTheEMailAddressOrSelectLbl));
        ErrorList.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::BusinessCentralError, BusinessCentralSOwnErrorTextLbl,
            BusinessCentralRefusesToSendForExampleLbl,
            ReadTheTextCheckTheDocumentBeforeLbl));
    end;

    internal procedure Effect(var EffectObject: JsonObject; Changes: Text)
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        EffectObject := Parts.CommittingEffect(Changes, false);
    end;

    internal procedure RelatedSales(var Related: JsonArray; MessageTypeName: Text)
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        if MessageTypeName <> 'Purchase.Order.Send' then
            Parts.Related(Related, 'Purchase.Order.Send', TheDocumentIsAPurchaseOrderLbl);
        if MessageTypeName <> 'Sales.Quote.Send' then
            Parts.Related(Related, 'Sales.Quote.Send', TheDocumentIsASalesQuoteLbl);
        if MessageTypeName <> 'Sales.OrderConfirmation.Send' then
            Parts.Related(Related, 'Sales.OrderConfirmation.Send', TheDocumentIsASalesOrderConfirmationLbl);
        Parts.Related(Related, 'Data.Records.Get', YouWantToReadTheDocumentAfterwardsLbl);
    end;

    internal procedure Workflow(var WorkflowObject: JsonObject; MessageTypeName: Text; Purpose: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Steps: JsonArray;
    begin
        Steps.Add(ContractMgt.WorkflowStep('Data.Records.Get', ReadTheDocumentAndTakeItsNumberLbl));
        Steps.Add(ContractMgt.WorkflowStep(MessageTypeName, Purpose));
        WorkflowObject.Add('steps', Steps);
    end;

    internal procedure Example(var Examples: JsonArray; MessageTypeName: Text; NumberKey: Text; SampleNo: Text)
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.Example(Examples, SendWithAnExplicitProfileLbl,
            '{"type":"' + MessageTypeName + '","data":{"' + NumberKey + '":"' + SampleNo + '","documentSendingProfile":"EMAIL"}}',
            '{"status":"Success","documentNo":"' + SampleNo + '","documentSendingProfileCode":"EMAIL","documentSendingProfileSource":"Request","message":"Document sent successfully."}');
        Parts.Example(Examples, UnknownDocumentLbl,
            '{"type":"' + MessageTypeName + '","data":{"documentNo":"DOES-NOT-EXIST"}}',
            '{"status":"Error","code":"RecordNotFound","parameter":"documentNo","nextStep":"Send the document number or SystemId of an existing document of this type."}');
    end;

    internal procedure Overview(DocumentCaption: Text; PdfTypeName: Text): Text
    begin
        exit(StrSubstNo(OverviewLbl, DocumentCaption, PdfTypeName));
    end;

    internal procedure Notes(PdfTypeName: Text): Text
    begin
        exit(StrSubstNo(NotesLbl, PdfTypeName));
    end;

    var
        NotesLbl: Label 'Success means every profile channel ran without error, not confirmed receipt. A retry sends again. subject and data identifiers must agree; a GUID is the SystemId, otherwise the number. Conflicting keys return ConflictingIdentifiers. Profile codes are compared in upper case. Disk or prompted e-mail profiles are refused before sending. The matching PDF type %1 is a separate dependency for callers wanting a file; this send does not call it.', Comment = 'is-IS=Success merkir að allar sendingarleiðir keyrðu án villu, ekki staðfesta móttöku. Endurtekið kall sendir aftur. Auðkenni í subject og data verða að vísa á sama skjal; GUID er SystemId, annað gildi skjalnúmer. Misvísandi lyklar skila ConflictingIdentifiers. Forstillingarkóðar eru bornir saman með hástöfum. Diskvistun og tölvupóststillingum sem krefjast spurningar er hafnað fyrir sendingu. Samsvarandi PDF-tegund %1 er sérstakt háð atriði fyrir þá sem vilja skrá; þessi sending kallar ekki á hana.';
        OverviewLbl: Label 'Sends one document (%1) through a Document Sending Profile: the request profile, otherwise the party profile, otherwise the Default profile. Irreversible. Missing documents, profiles or required e-mail addresses are refused before sending. Worker tests must mock the send; Disk profiles need a client and are refused. The matching PDF type is %2.', Comment = 'is-IS=Sendir eitt skjal (%1) með forstillingu skjalasendingar: forstillingu úr beiðni, annars forstillingu aðila, annars sjálfgefinni forstillingu. Óafturkræft. Skjölum, forstillingum eða nauðsynlegum netföngum sem vantar er hafnað fyrir sendingu. Prófanir í vinnuumhverfi verða að herma eftir sendingu; diskvistun þarf biðlara og er hafnað. Samsvarandi PDF-tegund er %2.';
        TargetSubjectLbl: Label 'The document number, or its SystemId. A GUID is the SystemId. Anything else is the number.', Comment = 'is-IS=Skjalnúmer eða SystemId skjalsins. GUID er SystemId. Annað gildi er skjalnúmer.';
        TargetIdAliasLbl: Label 'SystemId of the document. Same document as documentId when both are sent.', Comment = 'is-IS=SystemId skjalsins. Verður að vísa á sama skjal og documentId ef bæði eru send.';
        TargetNumberLbl: Label 'Document number. Optional when subject or %1 is sent.', Comment = 'is-IS=Skjalnúmer. Valfrjálst ef subject eða %1 er sent.';
        TargetAliasLbl: Label 'Document number. Same document as documentNo when both are sent.', Comment = 'is-IS=Skjalnúmer. Verður að vísa á sama skjal og documentNo ef bæði eru send.';
        NotFoundCauseLbl: Label 'The number or SystemId does not identify an existing document of this type (%1).', Comment = 'is-IS=Númerið eða SystemId vísar ekki á skjal af þessari tegund (%1) sem er til.';
        GrantReadLbl: Label 'Ask an administrator to grant read access to %1.', Comment = 'is-IS=Biddu kerfisstjóra um lesaðgang að %1.';
        ReadDeniedLbl: Label 'The caller has no read permission on %1.', Comment = 'is-IS=Kallandinn hefur ekki lesaðgang að %1.';
        TargetIdLbl: Label 'SystemId of the document.', Comment = 'is-IS=SystemId skjalsins.';
        NotFoundLbl: Label 'Document not found (%1).', Comment = 'is-IS=Skjal fannst ekki (%1).';
        ResponseTypeLbl: Label 'Always %1.', Comment = 'is-IS=Alltaf %1.';
        ResponsePartyNoLbl: Label 'Party number (%1).', Comment = 'is-IS=Númer aðila (%1).';
        ResponsePartyNameLbl: Label 'Party name (%1).', Comment = 'is-IS=Nafn aðila (%1).';
        DocumentNumberAGuidBelongsInDocumentidLbl: Label 'Document number. A GUID belongs in documentId or subject. At most 20 characters.', Comment = 'is-IS=Skjalnúmer, að hámarki 20 stafir. GUID á heima í documentId eða subject.';
        SameAsDocumentnoWhenBothAreSentLbl: Label 'Same as documentNo. When both are sent they must name the same document.', Comment = 'is-IS=Sama og documentNo. Ef bæði eru send verða þau að vísa á sama skjal.';
        SystemidGuidOfTheDocumentLbl: Label 'SystemId (GUID) of the document.', Comment = 'is-IS=SystemId skjalsins (GUID).';
        SameAsDocumentidWhenBothAreSentLbl: Label 'Same as documentId. When both are sent they must name the same document.', Comment = 'is-IS=Sama og documentId. Ef bæði eru send verða þau að vísa á sama skjal.';
        CodeOfTheDocumentSendingProfileForLbl: Label 'Code of the Document Sending Profile for this call only, at most 20 characters. A longer value is refused (InvalidParameterFormat), never cut. Must exist, must not save to disk and must not prompt for e-mail settings. Left out: the vendor or customer profile, then the profile marked Default.', Comment = 'is-IS=Kóði forstillingar skjalasendingar fyrir þetta kall, að hámarki 20 stafir. Lengri gildi eru höfnuð (InvalidParameterFormat), aldrei stytt. Forstillingin verður að vera til, má ekki vista á disk eða biðja um tölvupóststillingar. Ef lyklinum er sleppt er forstilling lánardrottins eða viðskiptamanns notuð, annars sjálfgefin forstilling.';
        NoOfTheDocumentLbl: Label 'No. of the document.', Comment = 'is-IS=Númer skjalsins.';
        SystemidOfTheDocumentGuidNoBracesLbl: Label 'SystemId of the document (GUID, no braces).', Comment = 'is-IS=SystemId skjalsins (GUID án slaufusviga).';
        CodeOfTheDocumentSendingProfileThatLbl: Label 'Code of the Document Sending Profile that was used.', Comment = 'is-IS=Kóði forstillingar skjalasendingar sem var notuð.';
        WhereTheProfileCameFromRequestTheLbl: Label 'Where the profile came from: Request, the party profile, or Default.', Comment = 'is-IS=Hvaðan forstillingin kom: Request (beiðni), forstilling viðskiptamanns eða lánardrottins, eða Default (sjálfgefin).';
        DocumentSentSuccessfullyLbl: Label 'Document sent successfully.', Comment = 'is-IS=Skjal sent.';
        ReadPermissionDeniedLbl: Label 'Read permission denied.', Comment = 'is-IS=Lesaðgangi hafnað.';
        SendTheDocumentNumberOrSystemidLbl: Label 'Send the document number or SystemId.', Comment = 'is-IS=Sendu skjalnúmer eða SystemId.';
        SubjectAndTheDocumentKeysWereAllLbl: Label 'subject and the document keys were all left out.', Comment = 'is-IS=Hvorki subject né auðkennislyklar skjals voru send.';
        PutTheNumberInSubjectOrDataLbl: Label 'Put the number in subject or data.documentNo, or the SystemId in subject or data.documentId.', Comment = 'is-IS=Settu númerið í subject eða data.documentNo, eða SystemId í subject eða data.documentId.';
        SendTheDocumentNumberOrSystemidOfLbl: Label 'Send the document number or SystemId of an existing document of this type.', Comment = 'is-IS=Sendu númer eða SystemId skjals af þessari tegund sem er til.';
        ParameterDocumentsendingprofileIsNotAJsonStringLbl: Label 'Parameter "documentSendingProfile" is not a JSON string or is longer than 20 characters.', Comment = 'is-IS=Færibreytan "documentSendingProfile" er ekki JSON-strengur eða er lengri en 20 stafir.';
        DocumentsendingprofileWasSentAsAnObjectOrLbl: Label 'documentSendingProfile was sent as an object or an array, or is longer than 20 characters. A longer code is refused, never cut.', Comment = 'is-IS=documentSendingProfile var sent sem hlutur eða fylki, eða er lengra en 20 stafir. Lengri kóða er hafnað, hann er aldrei styttur.';
        SendTheValueAsAJsonStringLbl: Label 'Send the value as a JSON string of at most 20 characters.', Comment = 'is-IS=Sendu gildið sem JSON-streng sem er að hámarki 20 stafir.';
        DocumentidIsNotAGuidLbl: Label 'documentId is not a GUID.', Comment = 'is-IS=documentId er ekki GUID.';
        DocumentidOrTheIdKeyIsNotLbl: Label 'documentId or the id key is not a GUID.', Comment = 'is-IS=documentId eða annar auðkennislykill er ekki GUID.';
        SendTheSystemidAsAGuidOrLbl: Label 'Send the SystemId as a GUID, or send the document number.', Comment = 'is-IS=Sendu SystemId sem GUID eða sendu skjalnúmerið.';
        TheIdentifiersNameDifferentDocumentsLbl: Label 'The identifiers name different documents.', Comment = 'is-IS=Auðkennin vísa á mismunandi skjöl.';
        TwoKeysWereSentAndTheyDoLbl: Label 'Two keys were sent and they do not name the same document. Nothing was sent.', Comment = 'is-IS=Tveir lyklar voru sendir og vísa ekki á sama skjal. Ekkert var sent.';
        SendOneDocumentNumberOrOneSystemidLbl: Label 'Send one document number or one SystemId.', Comment = 'is-IS=Sendu eitt skjalnúmer eða eitt SystemId.';
        DocumentSendingProfileCodeNotFoundLbl: Label 'Document Sending Profile "{code}" not found.', Comment = 'is-IS=Forstilling skjalasendingar "{code}" fannst ekki.';
        DocumentsendingprofileNamesAProfileThatDoesNotLbl: Label 'documentSendingProfile names a profile that does not exist. Nothing was sent.', Comment = 'is-IS=documentSendingProfile vísar á forstillingu sem er ekki til. Ekkert var sent.';
        SendTheCodeOfAnExistingDocumentLbl: Label 'Send the Code of an existing Document Sending Profile, or leave the key out.', Comment = 'is-IS=Sendu kóða forstillingar skjalasendingar sem er til eða slepptu lyklinum.';
        ThePartyProfileDoesNotExistOrLbl: Label 'The party profile does not exist, or no profile resolves.', Comment = 'is-IS=Forstilling viðskiptamanns eða lánardrottins er ekki til eða engin forstilling finnst.';
        NoDocumentsendingprofileWasSentAndTheCustomerLbl: Label 'No documentSendingProfile was sent and the customer or vendor profile is missing or points at a deleted profile, and no profile is marked Default.', Comment = 'is-IS=documentSendingProfile var ekki sent, forstilling viðskiptamanns eða lánardrottins vantar eða hefur verið eytt og engin forstilling er sjálfgefin.';
        SendDocumentsendingprofileFixThePartyProfileOrLbl: Label 'Send documentSendingProfile, fix the party profile, or mark one profile Default.', Comment = 'is-IS=Sendu documentSendingProfile, lagfærðu forstillingu viðskiptamanns eða lánardrottins eða veldu sjálfgefna forstillingu.';
        DocumentSendingProfileCodeSavesTheDocumentLbl: Label 'Document Sending Profile "{code}" saves the document to disk, which needs a client.', Comment = 'is-IS=Forstilling skjalasendingar "{code}" vistar skjalið á disk og þarf því biðlara.';
        TheResolvedProfileHasADiskChannelLbl: Label 'The resolved profile has a Disk channel. Nothing was sent.', Comment = 'is-IS=Forstillingin vistar á disk. Ekkert var sent.';
        SendAProfileThatHasNoDiskLbl: Label 'Send a profile that has no Disk channel.', Comment = 'is-IS=Sendu forstillingu sem vistar ekki á disk.';
        TheResolvedProfilePromptsForEMailLbl: Label 'The resolved profile prompts for e-mail settings.', Comment = 'is-IS=Forstillingin biður um tölvupóststillingar.';
        EMailIsYesPromptForSettingsLbl: Label 'E-Mail is Yes (Prompt for Settings). Nothing was sent.', Comment = 'is-IS=Tölvupóstur er stilltur á Já (biðja um stillingar). Ekkert var sent.';
        PassAProfileWithEMailSetLbl: Label 'Pass a profile with E-Mail set to Yes (Use Default Settings).', Comment = 'is-IS=Sendu forstillingu með tölvupóst stilltan á Já (nota sjálfgefnar stillingar).';
        TheCustomerOrVendorHasNoELbl: Label 'The customer or vendor has no e-mail address for the profile.', Comment = 'is-IS=Netfang viðskiptamanns eða lánardrottins vantar fyrir forstillinguna.';
        TheResolvedProfileSendsEMailAndLbl: Label 'The resolved profile sends e-mail and the party has no e-mail address. Nothing was sent.', Comment = 'is-IS=Forstillingin sendir tölvupóst en netfang viðskiptamanns eða lánardrottins vantar. Ekkert var sent.';
        SetTheEMailAddressOrSelectLbl: Label 'Set the e-mail address or select a profile that does not send e-mail.', Comment = 'is-IS=Skráðu netfangið eða veldu forstillingu sem sendir ekki tölvupóst.';
        BusinessCentralSOwnErrorTextLbl: Label 'Business Central''s own error text', Comment = 'is-IS=Villutexti frá Business Central';
        BusinessCentralRefusesToSendForExampleLbl: Label 'Business Central refuses to send, for example no e-mail account or no report for the Report Selection usage.', Comment = 'is-IS=Business Central hafnar sendingu, til dæmis vegna þess að tölvupóstreikning eða skýrslu fyrir skýrsluvalið vantar.';
        ReadTheTextCheckTheDocumentBeforeLbl: Label 'Read the text. Check the document before sending again: a channel may already have delivered it.', Comment = 'is-IS=Lestu textann. Athugaðu skjalið áður en þú sendir aftur: ein sendingarleið gæti þegar hafa afhent það.';
        TheDocumentIsAPurchaseOrderLbl: Label 'The document is a purchase order.', Comment = 'is-IS=Skjalið er innkaupapöntun.';
        TheDocumentIsASalesQuoteLbl: Label 'The document is a sales quote.', Comment = 'is-IS=Skjalið er sölutilboð.';
        TheDocumentIsASalesOrderConfirmationLbl: Label 'The document is a sales order confirmation.', Comment = 'is-IS=Skjalið er staðfesting sölupöntunar.';
        YouWantToReadTheDocumentAfterwardsLbl: Label 'You want to read the document afterwards without sending it again.', Comment = 'is-IS=Þú vilt lesa skjalið eftir sendingu án þess að senda það aftur.';
        ReadTheDocumentAndTakeItsNumberLbl: Label 'Read the document and take its number or SystemId.', Comment = 'is-IS=Lestu skjalið og notaðu númer þess eða SystemId.';
        SendWithAnExplicitProfileLbl: Label 'Send with an explicit profile', Comment = 'is-IS=Senda með tilgreindri forstillingu';
        UnknownDocumentLbl: Label 'Unknown document', Comment = 'is-IS=Óþekkt skjal';
}
