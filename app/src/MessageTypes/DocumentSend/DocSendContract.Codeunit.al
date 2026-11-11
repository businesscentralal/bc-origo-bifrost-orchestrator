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
        Result.Add(ContractMgt.TargetEntry('subject', 'guid|code', 'The ' + DocumentCaption + ' number, or its SystemId. A GUID is the SystemId. Anything else is the number.'));
        Result.Add(ContractMgt.TargetEntry('data.documentNo', 'code', 'The ' + DocumentCaption + ' number. Optional when subject or ' + NumberKey + ' is sent.'));
        Result.Add(ContractMgt.TargetEntry('data.' + NumberKey, 'code', 'The ' + DocumentCaption + ' number. Same document as documentNo when both are sent.'));
        Result.Add(ContractMgt.TargetEntry('data.documentId', 'guid', 'SystemId of the ' + DocumentCaption + '.'));
        Result.Add(ContractMgt.TargetEntry('data.' + IdKey, 'guid', 'SystemId of the ' + DocumentCaption + '. Same document as documentId when both are sent.'));
    end;

    internal procedure Parameters(var ParameterList: JsonArray; NumberKey: Text; IdKey: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        ParameterList.Add(ContractMgt.Parameter('documentNo', 'string', false, 'Document number. A GUID belongs in documentId or subject. At most 20 characters.'));
        ParameterList.Add(ContractMgt.Parameter(NumberKey, 'string', false, 'Same as documentNo. When both are sent they must name the same document.'));
        ParameterList.Add(ContractMgt.Parameter('documentId', 'string', false, 'SystemId (GUID) of the document.'));
        ParameterList.Add(ContractMgt.Parameter(IdKey, 'string', false, 'Same as documentId. When both are sent they must name the same document.'));
        ParameterList.Add(ContractMgt.Parameter('documentSendingProfile', 'string', false,
            'Code of the Document Sending Profile for this call only, at most 20 characters. A longer value is refused (InvalidParameterFormat), never cut. Must exist, must not save to disk and must not prompt for e-mail settings. Left out: the vendor or customer profile, then the profile marked Default.'));
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
        Parts.AddResponseField(Fields, 'documentType', 'string', 'Always ' + DocumentTypeText + '.');
        Parts.AddResponseField(Fields, 'documentNo', 'string', 'No. of the document.');
        Parts.AddResponseField(Fields, 'documentId', 'string', 'SystemId of the document (GUID, no braces).');
        Parts.AddResponseField(Fields, PartyNoName, 'string', PartyCaption + ' number.');
        Parts.AddResponseField(Fields, PartyNameName, 'string', PartyCaption + ' name.');
        Parts.AddResponseField(Fields, 'documentSendingProfileCode', 'string', 'Code of the Document Sending Profile that was used.');
        Sources.Add('Request');
        if PartyNoName = 'vendorNo' then
            Sources.Add('Vendor')
        else
            Sources.Add('Customer');
        Sources.Add('Default');
        Source := ContractMgt.ResponseField('documentSendingProfileSource', 'string', 'Where the profile came from: Request, the party profile, or Default.');
        Source.Add('allowed', Sources);
        Fields.Add(Source);
        Parts.AddResponseField(Fields, 'message', 'string', 'Document sent successfully.');
        ResponseObject := Parts.Response(Fields, 'text/json');
    end;

    internal procedure Errors(var ErrorList: JsonArray; DocumentCaption: Text; TableCaptionText: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        ErrorList.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, 'Read permission denied.',
            'The caller has no read permission on ' + TableCaptionText + '.', 'Ask an administrator to grant read access to ' + TableCaptionText + '.'));
        ErrorList.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::MissingParameter, 'Send the document number or SystemId.',
            'subject and the document keys were all left out.', 'Put the number in subject or data.documentNo, or the SystemId in subject or data.documentId.'));
        ErrorList.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::RecordNotFound, DocumentCaption + ' was not found.',
            'The number or SystemId is not an existing ' + DocumentCaption + ' of this type.', 'Send the document number or SystemId of an existing document of this type.'));
        ErrorList.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::InvalidParameterFormat, 'Parameter "documentSendingProfile" is not a JSON string or is longer than 20 characters.',
            'documentSendingProfile was sent as an object or an array, or is longer than 20 characters. A longer code is refused, never cut.',
            'Send the value as a JSON string of at most 20 characters.'));
        ErrorList.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::InvalidParameterFormat, 'documentId is not a GUID.',
            'documentId or the id key is not a GUID.', 'Send the SystemId as a GUID, or send the document number.'));
        ErrorList.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::ConflictingIdentifiers, 'The identifiers name different documents.',
            'Two keys were sent and they do not name the same document. Nothing was sent.', 'Send one document number or one SystemId.'));
        ErrorList.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::RecordNotFound, 'Document Sending Profile "{code}" not found.',
            'documentSendingProfile names a profile that does not exist. Nothing was sent.', 'Send the Code of an existing Document Sending Profile, or leave the key out.'));
        ErrorList.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PreconditionFailed, 'The party profile does not exist, or no profile resolves.',
            'No documentSendingProfile was sent and the customer or vendor profile is missing or points at a deleted profile, and no profile is marked Default.',
            'Send documentSendingProfile, fix the party profile, or mark one profile Default.'));
        ErrorList.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PreconditionFailed, 'Document Sending Profile "{code}" saves the document to disk, which needs a client.',
            'The resolved profile has a Disk channel. Nothing was sent.', 'Send a profile that has no Disk channel.'));
        ErrorList.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PreconditionFailed, 'The resolved profile prompts for e-mail settings.',
            'E-Mail is Yes (Prompt for Settings). Nothing was sent.', 'Pass a profile with E-Mail set to Yes (Use Default Settings).'));
        ErrorList.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PreconditionFailed, 'The customer or vendor has no e-mail address for the profile.',
            'The resolved profile sends e-mail and the party has no e-mail address. Nothing was sent.', 'Set the e-mail address or select a profile that does not send e-mail.'));
        ErrorList.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::BusinessCentralError, 'Business Central''s own error text',
            'Business Central refuses to send, for example no e-mail account or no report for the Report Selection usage.',
            'Read the text. Check the document before sending again: a channel may already have delivered it.'));
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
            Parts.Related(Related, 'Purchase.Order.Send', 'The document is a purchase order.');
        if MessageTypeName <> 'Sales.Quote.Send' then
            Parts.Related(Related, 'Sales.Quote.Send', 'The document is a sales quote.');
        if MessageTypeName <> 'Sales.OrderConfirmation.Send' then
            Parts.Related(Related, 'Sales.OrderConfirmation.Send', 'The document is a sales order confirmation.');
        Parts.Related(Related, 'Data.Records.Get', 'You want to read the document afterwards without sending it again.');
    end;

    internal procedure Workflow(var WorkflowObject: JsonObject; MessageTypeName: Text; Purpose: Text)
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Steps: JsonArray;
    begin
        Steps.Add(ContractMgt.WorkflowStep('Data.Records.Get', 'Read the document and take its number or SystemId.'));
        Steps.Add(ContractMgt.WorkflowStep(MessageTypeName, Purpose));
        WorkflowObject.Add('steps', Steps);
    end;

    internal procedure Example(var Examples: JsonArray; MessageTypeName: Text; NumberKey: Text; SampleNo: Text)
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
    begin
        Parts.Example(Examples, 'Send with an explicit profile',
            '{"type":"' + MessageTypeName + '","data":{"' + NumberKey + '":"' + SampleNo + '","documentSendingProfile":"EMAIL"}}',
            '{"status":"Success","documentNo":"' + SampleNo + '","documentSendingProfileCode":"EMAIL","documentSendingProfileSource":"Request","message":"Document sent successfully."}');
        Parts.Example(Examples, 'Unknown document',
            '{"type":"' + MessageTypeName + '","data":{"documentNo":"DOES-NOT-EXIST"}}',
            '{"status":"Error","code":"RecordNotFound","parameter":"documentNo","nextStep":"Send the document number or SystemId of an existing document of this type."}');
    end;

    internal procedure Overview(DocumentCaption: Text; PdfTypeName: Text): Text
    begin
        exit('Sends one ' + DocumentCaption + ' the way the Send action does, through a Document Sending Profile: the one named in the request, else the party profile, else the profile marked Default. ' +
            'Irreversible. Nothing is sent when the document, the profile or a required e-mail address is missing. Tests and this API must not send real e-mail from a worker container; a Disk profile is refused because it needs a client. ' +
            'The matching PDF type is ' + PdfTypeName + '.');
    end;

    internal procedure Notes(PdfTypeName: Text): Text
    begin
        exit('Success means Business Central ran every channel of the profile without an error, not that the recipient received the document. Not retry-safe: a second call sends the document again. ' +
            'subject and the keys under data are all tried. A GUID is the SystemId; anything else is the number. Two keys that name different documents are ConflictingIdentifiers. ' +
            'The profile code is compared in upper case. A profile with a Disk channel, or E-Mail set to prompt, is refused before anything is sent. ' +
            'Depends on the matching PDF message type ' + PdfTypeName + ' for callers that want the file instead of sending. That type is a separate message and is not called by this send.');
    end;
}
