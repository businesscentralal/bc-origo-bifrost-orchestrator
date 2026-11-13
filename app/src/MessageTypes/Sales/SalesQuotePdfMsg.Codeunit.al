namespace Origo.Bifrost.Orchestrator;

using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Document;
using Origo.Bifrost;
using System.Utilities;

/// <summary>
/// Sales.Quote.Pdf returns one sales quote as a PDF, printed with Report Selection usage S.Quote.
/// </summary>
codeunit 10035629 "Sales Quote Pdf Msg ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;
    Permissions = tabledata "Sales Header" = R,
                  tabledata "Report Selections" = R;

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
        DescriptionLbl: Label 'Retrieves a sales quote as a PDF document.', Comment = 'is-IS=Sækir sölutilboð sem PDF-skjal.';
    begin
        exit(DescriptionLbl);
    end;

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'sales quote pdf, print quote, download quote, quote copy, reprint quote', Comment = 'is-IS=sölutilboð pdf, prenta tilboð, sækja tilboð, afrit tilboðs, endurprenta tilboð';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Get a sales quote as a PDF file, printed with the customer''s report selection (usage S.Quote). Takes a quote number or SystemId. The standard report may increase No. Printed.', Comment = 'is-IS=Sækja sölutilboð sem PDF-skrá, prentað með skýrsluvali viðskiptamanns (notkun S.Quote). Tekur númer tilboðs eða SystemId. Staðalskýrslan getur hækkað prentteljarann.';
    begin
        exit(SelectionLbl);
    end;

    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Forms: List of [Text];
    begin
        Forms.Add('guid');
        Forms.Add('code');
        Envelope := QuoteEnvelope(Forms, 'The quote number, or the SystemId of the sales quote.', false, 'application/pdf');
        exit(true);
    end;

    procedure GetTarget(var Target: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Target.Add(ContractMgt.TargetEntry('subject', 'code', 'A quote number, or a GUID read as the SystemId. Used when no data key names the quote.'));
        Target.Add(ContractMgt.TargetEntry('data.quoteNo', 'code', 'The quote number. A GUID in this key is read as the SystemId.'));
        Target.Add(ContractMgt.TargetEntry('data.systemId', 'guid', 'The SystemId of the sales quote.'));
        exit(true);
    end;

    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('quoteNo', 'string', false, 'Quote number. A GUID is read as the SystemId. A sales order with the same number is not a quote.'));
        Parameters.Add(ContractMgt.Parameter('quoteId', 'string', false, 'SystemId or quote number. Same resolution as quoteNo.'));
        Parameters.Add(ContractMgt.Parameter('documentNo', 'string', false, 'Quote number or SystemId. Same resolution as quoteNo.'));
        Parameters.Add(ContractMgt.Parameter('documentId', 'string', false, 'SystemId or quote number. Same resolution as quoteNo.'));
        Parameters.Add(ContractMgt.Parameter('systemId', 'string', false, 'SystemId of the sales quote. A value that is not a GUID is refused.'));
        Parameters.Add(ContractMgt.Parameter('recordSystemId', 'string', false, 'SystemId of the sales quote. Same rule as systemId.'));
        Parameters.Add(ContractMgt.Parameter('id', 'string', false, 'SystemId of the sales quote. Same rule as systemId.'));
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Fields: JsonArray;
    begin
        Parts.AddResponseField(Fields, 'binary', 'binary', 'The sales quote PDF. The success body is the file itself, with content type application/pdf, not JSON.');
        Response := Parts.Response(Fields, 'application/pdf');
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, 'Read permission denied for table 36.', 'The caller has no read permission on Sales Header.', 'Ask an administrator for a permission set that reads the table.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::MissingParameter, 'A sales quote number or SystemId is required.', 'Neither subject nor a quote key was sent.', 'Send subject, quoteNo or systemId for one sales quote.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::RecordNotFound, 'Sales quote "<value>" was not found (from <key>).', 'The number or SystemId is not a sales quote. An order or another document is not a quote.', 'Check the quote number, or send the SystemId of a sales quote.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::ConflictingIdentifiers, 'The quote identifiers name different sales quotes.', 'Two keys resolve to different quotes.', 'Send one quote number or one SystemId, or make every identifier name the same quote.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::InvalidParameterFormat, 'Parameter "<key>" must be text.', 'The key is a number, boolean, object, array or null, or a SystemId key is not a GUID, or a number is longer than 20 characters.', 'Send the quote number as text of at most 20 characters, or a GUID SystemId.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::BusinessCentralError, 'The sales quote PDF is empty.', 'Report Selection usage S.Quote produced no bytes.', 'Check Report Selection usage S.Quote for the sell-to customer.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::BusinessCentralError, 'Business Central''s own error text', 'No report is set up for usage S.Quote, or the report fails while rendering.', 'Check Report Selection usage S.Quote for the sell-to customer and the report layout.'));
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Parts: Codeunit "Orch B2 Contract Parts ori";
        Preconditions: JsonArray;
    begin
        Effect := Parts.Effect('write', 'Renders the sales quote with Report Selection usage S.Quote. The standard report may increase No. Printed. Saving the PDF commits the work done so far.', false, '', Preconditions);
        exit(true);
    end;

    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    procedure GetRelated(var Related: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Related.Add(ContractMgt.RelatedEntry('Sales.SalesInvoice.Pdf', 'You need a posted sales invoice, not an open quote.'));
        Related.Add(ContractMgt.RelatedEntry('Orchestrator.Report.SaveAs', 'You already know the report id and the table view, and you do not want the customer report selection.'));
        exit(true);
    end;

    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Steps: JsonArray;
    begin
        Steps.Add(ContractMgt.WorkflowStep('Sales.Quote.Pdf', 'Get the PDF with the quote number or its SystemId.'));
        Workflow.Add('steps', Steps);
        exit(true);
    end;

    procedure GetExamples(var Examples: JsonArray): Boolean
    begin
        // The success body is the PDF file, not JSON, so there is no response document to show.
        exit(false);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Returns one sales quote as a PDF file, printed with the report the customer''s Report Selection (usage S.Quote, default report 1304) names. ' +
            'Send the quote number or the SystemId. Only a sales quote matches; a sales order with the same number does not.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'subject and the keys quoteNo, quoteId, documentNo, documentId, systemId, recordSystemId and id are all tried. ' +
            'A value that is a GUID is the SystemId. Anything else is the quote number, and only Document Type Quote matches. ' +
            'Two keys that name different quotes are ConflictingIdentifiers. One that matches nothing is RecordNotFound. ' +
            'Only the success answer is a PDF; an error answer is JSON. ' +
            'The same read-permission check as Sales.SalesInvoice.Pdf is applied to Sales Header. ' +
            'Saving the PDF commits the work done so far, so the call cannot run inside a larger transaction that is rolled back.';
        exit(true);
    end;

    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        // Same shape as Sales.SalesInvoice.Pdf: printing can increase No. Printed, and the caller still receives the file.
        exit("Msg Direction ori"::Both);
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        SalesHeader: Record "Sales Header";
        ReportSelections: Record "Report Selections";
        TempBlob: Codeunit "Temp Blob";
    begin
        Argument.AssertVersion1();
        Argument.AssertIsLicensed();
        if not HasSalesHeaderReadPermission(Argument) then
            exit;
        if not FindQuote(Argument, SalesHeader) then
            exit;

        SalesHeader.SetRecFilter();
        ReportSelections.GetPdfReportForCust(TempBlob, Enum::"Report Selection Usage"::"S.Quote", SalesHeader, SalesHeader."Sell-to Customer No.");
        if TempBlob.Length() = 0 then begin
            Argument.RespondWithError("Bifrost Error Code ori"::BusinessCentralError, EmptyPdfErr, 'quoteNo', SalesHeader."No.", PdfExpectedTxt, EmptyPdfNextStepTxt);
            exit;
        end;
        Argument.SetResponsePdf(TempBlob);
    end;

    local procedure HasSalesHeaderReadPermission(var Argument: Record "Message Argument ori"): Boolean
    var
        RecRef: RecordRef;
        ReadPermissionDeniedErr: Label 'Read permission denied for table %1.', Comment = '%1 = table number, is-IS=Lesheimild neitað fyrir töflu %1.';
        ReadPermissionExpectedTxt: Label 'read permission on the data of table %1', Comment = '%1 = table number, is-IS=lesheimild á gögnum í töflu %1';
        ReadPermissionNextStepTxt: Label 'Ask an administrator for a permission set that reads the table.', Comment = 'is-IS=Biddu kerfisstjóra um heimildasamstæðu sem les töfluna.';
    begin
        RecRef.Open(Database::"Sales Header");
        if RecRef.ReadPermission() then begin
            RecRef.Close();
            exit(true);
        end;
        RecRef.Close();
        Argument.RespondWithError("Bifrost Error Code ori"::PermissionDenied, StrSubstNo(ReadPermissionDeniedErr, Format(Database::"Sales Header")), '', '', StrSubstNo(ReadPermissionExpectedTxt, Format(Database::"Sales Header")), ReadPermissionNextStepTxt);
        exit(false);
    end;

    local procedure FindQuote(var Argument: Record "Message Argument ori"; var SalesHeader: Record "Sales Header"): Boolean
    var
        Candidate: Record "Sales Header";
        FoundSystemId: Guid;
        Index: Integer;
        RequestJson: JsonObject;
        Sources: List of [Text];
        Values: List of [Text];
    begin
        RequestJson := Argument.GetRequestJson();
        if not CollectIdentifier(Argument, RequestJson, 'quoteNo', false, Sources, Values) then
            exit(false);
        if not CollectIdentifier(Argument, RequestJson, 'quoteId', false, Sources, Values) then
            exit(false);
        if not CollectIdentifier(Argument, RequestJson, 'documentNo', false, Sources, Values) then
            exit(false);
        if not CollectIdentifier(Argument, RequestJson, 'documentId', false, Sources, Values) then
            exit(false);
        if not CollectIdentifier(Argument, RequestJson, 'systemId', true, Sources, Values) then
            exit(false);
        if not CollectIdentifier(Argument, RequestJson, 'recordSystemId', true, Sources, Values) then
            exit(false);
        if not CollectIdentifier(Argument, RequestJson, 'id', true, Sources, Values) then
            exit(false);
        if Argument.Subject <> '' then begin
            if not AcceptIdentifierText(Argument, 'subject', Argument.Subject, false) then
                exit(false);
            Sources.Add('subject');
            Values.Add(Argument.Subject);
        end;

        if Sources.Count() = 0 then begin
            Argument.RespondWithError("Bifrost Error Code ori"::MissingParameter, MissingQuoteErr, 'subject', '', MissingQuoteExpectedTxt, MissingQuoteNextStepTxt);
            exit(false);
        end;

        for Index := 1 to Sources.Count() do begin
            if not TryResolveQuote(Values.Get(Index), Candidate) then begin
                RespondQuoteNotFound(Argument, Sources.Get(Index), Values.Get(Index));
                exit(false);
            end;
            if IsNullGuid(FoundSystemId) then
                FoundSystemId := Candidate.SystemId
            else
                if FoundSystemId <> Candidate.SystemId then begin
                    Argument.RespondWithError("Bifrost Error Code ori"::ConflictingIdentifiers, ConflictErr, Sources.Get(Index), Values.Get(Index), ConflictExpectedTxt, ConflictNextStepTxt);
                    exit(false);
                end;
        end;

        SalesHeader.SetLoadFields("No.", "Document Type", "Sell-to Customer No.");
        if not SalesHeader.GetBySystemId(FoundSystemId) then begin
            RespondQuoteNotFound(Argument, Sources.Get(1), Values.Get(1));
            exit(false);
        end;
        exit(true);
    end;

    local procedure CollectIdentifier(var Argument: Record "Message Argument ori"; RequestJson: JsonObject; KeyName: Text; GuidOnly: Boolean; var Sources: List of [Text]; var Values: List of [Text]): Boolean
    var
        Token: JsonToken;
        Written: Text;
        TextValue: Text;
    begin
        if not RequestJson.Get(KeyName, Token) then
            exit(true);
        Token.WriteTo(Written);
        if not Written.StartsWith('"') then begin
            Argument.RespondWithError("Bifrost Error Code ori"::InvalidParameterFormat, StrSubstNo(InvalidKeyErr, KeyName), KeyName, CopyStr(Written, 1, 250), InvalidKeyExpectedTxt, StrSubstNo(InvalidKeyNextStepTxt, KeyName));
            exit(false);
        end;
        TextValue := Token.AsValue().AsText();
        if TextValue = '' then
            exit(true);
        if not AcceptIdentifierText(Argument, KeyName, TextValue, GuidOnly) then
            exit(false);
        Sources.Add(KeyName);
        Values.Add(TextValue);
        exit(true);
    end;

    local procedure AcceptIdentifierText(var Argument: Record "Message Argument ori"; KeyName: Text; TextValue: Text; GuidOnly: Boolean): Boolean
    var
        SalesHeader: Record "Sales Header";
    begin
        if GuidOnly and (not IsGuidText(TextValue)) then begin
            Argument.RespondWithError("Bifrost Error Code ori"::InvalidParameterFormat, StrSubstNo(NotAGuidErr, KeyName), KeyName, TextValue, GuidExpectedTxt, StrSubstNo(NotAGuidNextStepTxt, KeyName));
            exit(false);
        end;
        if (not IsGuidText(TextValue)) and (StrLen(TextValue) > MaxStrLen(SalesHeader."No.")) then begin
            Argument.RespondWithError("Bifrost Error Code ori"::InvalidParameterFormat, StrSubstNo(TooLongErr, KeyName), KeyName, TextValue, QuoteNoExpectedTxt, TooLongNextStepTxt);
            exit(false);
        end;
        exit(true);
    end;

    local procedure TryResolveQuote(Value: Text; var SalesHeader: Record "Sales Header"): Boolean
    var
        Parsed: Guid;
    begin
        SalesHeader.SetLoadFields("No.", "Document Type", "Sell-to Customer No.");
        if IsGuidText(Value) then begin
            if not Evaluate(Parsed, Value) then
                exit(false);
            if not SalesHeader.GetBySystemId(Parsed) then
                exit(false);
            exit(SalesHeader."Document Type" = SalesHeader."Document Type"::Quote);
        end;
        exit(SalesHeader.Get(SalesHeader."Document Type"::Quote, CopyStr(Value, 1, MaxStrLen(SalesHeader."No."))));
    end;

    local procedure RespondQuoteNotFound(var Argument: Record "Message Argument ori"; Source: Text; Value: Text)
    var
        NextStep: Text;
    begin
        if IsGuidText(Value) then
            NextStep := QuoteSystemIdNextStepTxt
        else
            NextStep := QuoteNotFoundNextStepTxt;
        Argument.RespondWithError("Bifrost Error Code ori"::RecordNotFound, StrSubstNo(QuoteNotFoundErr, Value, Source), Source, Value, QuoteNotFoundExpectedTxt, NextStep);
    end;

    local procedure IsGuidText(Value: Text): Boolean
    var
        Parsed: Guid;
    begin
        if not Evaluate(Parsed, Value) then
            exit(false);
        exit(not IsNullGuid(Parsed));
    end;

    local procedure QuoteEnvelope(SubjectForms: List of [Text]; SubjectDescription: Text; DataRequired: Boolean; ContentType: Text) Result: JsonObject
    var
        Subject: JsonObject;
        StrictOption: JsonObject;
        Forms: JsonArray;
        Form: Text;
        StrictDescriptionTxt: Label 'Optional root Boolean, default false. When true, unknown data keys are refused before execution with UnknownParameter. Do not place this option inside data.', Comment = 'is-IS=Valfrjálst Boolean-gildi á efsta stigi, sjálfgefið false. Þegar það er true er óþekktum gagnalyklum hafnað fyrir keyrslu með UnknownParameter. Ekki setja þennan valkost inni í data.';
    begin
        Subject.Add('use', 'optional');
        foreach Form in SubjectForms do
            Forms.Add(Form);
        Subject.Add('forms', Forms);
        Subject.Add('description', SubjectDescription);
        StrictOption.Add('type', 'boolean');
        StrictOption.Add('required', false);
        StrictOption.Add('default', false);
        StrictOption.Add('description', StrictDescriptionTxt);
        Result.Add('strict', StrictOption);
        Result.Add('subject', Subject);
        Result.Add('dataRequired', DataRequired);
        Result.Add('version', '1.0');
        Result.Add('contentType', ContentType);
    end;

    var
        MissingQuoteErr: Label 'A sales quote number or SystemId is required.', Comment = 'is-IS=Númer sölutilboðs eða SystemId vantar.';
        MissingQuoteExpectedTxt: Label 'a quote number or a SystemId', Comment = 'is-IS=númer tilboðs eða SystemId';
        MissingQuoteNextStepTxt: Label 'Send subject, quoteNo or systemId for one sales quote.', Comment = 'is-IS=Sendu subject, quoteNo eða systemId fyrir eitt sölutilboð.';
        QuoteNotFoundErr: Label 'Sales quote "%1" was not found (from %2).', Comment = '%1 = value, %2 = key, is-IS=Sölutilboð "%1" fannst ekki (úr %2).';
        QuoteNotFoundExpectedTxt: Label 'an existing sales quote', Comment = 'is-IS=sölutilboð sem er til';
        QuoteNotFoundNextStepTxt: Label 'Check the quote number. A sales order or another document with the same number is not a quote.', Comment = 'is-IS=Athugaðu númer tilboðsins. Sölupöntun eða annað skjal með sama númeri er ekki tilboð.';
        QuoteSystemIdNextStepTxt: Label 'Check that the SystemId belongs to a sales quote.', Comment = 'is-IS=Athugaðu að SystemId tilheyri sölutilboði.';
        ConflictErr: Label 'The quote identifiers name different sales quotes.', Comment = 'is-IS=Auðkenni tilboðsins nefna mismunandi sölutilboð.';
        ConflictExpectedTxt: Label 'identifiers for the same sales quote', Comment = 'is-IS=auðkenni fyrir sama sölutilboð';
        ConflictNextStepTxt: Label 'Send one quote number or one SystemId, or make every identifier name the same quote.', Comment = 'is-IS=Sendu eitt tilboðsnúmer eða eitt SystemId, eða láttu öll auðkenni nefna sama tilboð.';
        InvalidKeyErr: Label 'Parameter "%1" must be text.', Comment = '%1 = key, is-IS=Færibreytan "%1" verður að vera texti.';
        InvalidKeyExpectedTxt: Label 'a text quote number or SystemId', Comment = 'is-IS=texti með númeri tilboðs eða SystemId';
        InvalidKeyNextStepTxt: Label 'Send "%1" as text, not a number, boolean, object or array.', Comment = '%1 = key, is-IS=Sendu "%1" sem texta, ekki tölu, Boolean-gildi, hlut eða fylki.';
        NotAGuidErr: Label 'Parameter "%1" must be a SystemId.', Comment = '%1 = key, is-IS=Færibreytan "%1" verður að vera SystemId.';
        GuidExpectedTxt: Label 'a GUID SystemId', Comment = 'is-IS=GUID SystemId';
        NotAGuidNextStepTxt: Label 'Send a GUID SystemId in "%1".', Comment = '%1 = key, is-IS=Sendu GUID SystemId í "%1".';
        TooLongErr: Label 'Parameter "%1" is longer than 20 characters and is not a SystemId.', Comment = '%1 = key, is-IS=Færibreytan "%1" er lengri en 20 stafir og er ekki SystemId.';
        QuoteNoExpectedTxt: Label 'a quote number of at most 20 characters', Comment = 'is-IS=númer tilboðs sem er í mesta lagi 20 stafir';
        TooLongNextStepTxt: Label 'Send the quote number (at most 20 characters) or the SystemId.', Comment = 'is-IS=Sendu númer tilboðs (í mesta lagi 20 stafir) eða SystemId.';
        EmptyPdfErr: Label 'The sales quote PDF is empty.', Comment = 'is-IS=PDF-skjal sölutilboðsins er tómt.';
        PdfExpectedTxt: Label 'a PDF file', Comment = 'is-IS=PDF-skrá';
        EmptyPdfNextStepTxt: Label 'Check Report Selection usage S.Quote for the sell-to customer.', Comment = 'is-IS=Athugaðu skýrsluval notkunar S.Quote fyrir viðskiptamanninn.';
}
