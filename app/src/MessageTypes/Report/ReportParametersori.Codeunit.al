namespace Origo.Bifrost.Orchestrator;

/// <summary>Overlays explicit request parameters on caller XML or a registered report template.</summary>
codeunit 10035614 "Report Parameters ori"
{
    /// <summary>Resolves explicit parameters without reading or writing saved user settings.</summary>
    internal procedure Resolve(ReportId: Integer; Request: JsonObject): Text
    var
        ParametersToken: JsonToken;
        XmlToken: JsonToken;
        Parameters: JsonObject;
        Document: XmlDocument;
        Root: XmlElement;
        IdAttribute: XmlAttribute;
        Fields: XmlNodeList;
        FieldNode: XmlNode;
        OptionElement: XmlElement;
        NameAttribute: XmlAttribute;
        Value: JsonToken;
        BaseXml: Text;
        ParameterName: Text;
        ControlName: Text;
        ParameterText: Text;
        Found: Boolean;
        UpdatedControls: List of [Text];
    begin
        Request.Get('parameters', ParametersToken);
        if not ParametersToken.IsObject() then
            Error(ParametersObjectErr);
        Parameters := ParametersToken.AsObject();
        if Request.Get('requestPageXml', XmlToken) then
            if not XmlToken.AsValue().IsNull() then
                BaseXml := XmlToken.AsValue().AsText();
        if BaseXml = '' then begin
            OnGetRequestPageTemplate(ReportId, BaseXml);
            if (BaseXml = '') and (ReportId = 1316) then
                BaseXml := StatementTemplate();
        end;
        if BaseXml = '' then
            Error(MissingBaseErr, ReportId);
        if not XmlDocument.ReadFrom(BaseXml, Document) then
            Error(InvalidBaseErr, ReportId);
        if not Document.GetRoot(Root) then
            Error(InvalidBaseErr, ReportId);
        if Root.Name() <> 'ReportParameters' then
            Error(InvalidBaseErr, ReportId);
        if not Root.Attributes().Get('id', IdAttribute) then
            Error(InvalidBaseErr, ReportId);
        if IdAttribute.Value() <> Format(ReportId, 0, 9) then
            Error(InvalidBaseErr, ReportId);
        Document.SelectNodes('/ReportParameters/Options/Field', Fields);
        foreach ParameterName in Parameters.Keys() do begin
            Parameters.Get(ParameterName, Value);
            ControlName := ParameterName;
            if ReportId = 1316 then
                ControlName := StatementControlName(ParameterName);
            if UpdatedControls.Contains(ControlName) then
                Error(DuplicateParameterErr, ControlName, ReportId);
            UpdatedControls.Add(ControlName);
            Found := false;
            foreach FieldNode in Fields do begin
                OptionElement := FieldNode.AsXmlElement();
                if OptionElement.Attributes().Get('name', NameAttribute) then
                    if NameAttribute.Value() = ControlName then begin
                        if Found then
                            Error(InvalidBaseErr, ReportId);
                        ParameterText := ScalarText(Value, ParameterName);
                        if ReportId = 1316 then
                            ParameterText := StatementValue(ControlName, ParameterText);
                        // XML DOM insertion escapes text; parameter names never enter an XPath.
                        OptionElement.ReplaceNodes(XmlText.Create(ParameterText));
                        Found := true;
                    end;
            end;
            if not Found then
                Error(UnknownParameterErr, ParameterName, ReportId);
        end;
        Document.WriteTo(BaseXml);
        exit(BaseXml);
    end;

    local procedure ScalarText(Value: JsonToken; ParameterName: Text): Text
    begin
        if not Value.IsValue() then
            Error(ScalarErr, ParameterName);
        if Value.AsValue().IsNull() then
            Error(ScalarErr, ParameterName);
        exit(Value.AsValue().AsText());
    end;

    local procedure StatementControlName(ParameterName: Text): Text
    begin
        case ParameterName of
            'StartDate': exit('Start Date');
            'EndDate': exit('End Date');
            'DateChoice': exit('AgingBandby');
            'PrintAging': exit('IncludeAgingBand');
            'AgingBandPeriodLength': exit('AgingBandPeriodLengt');
            'PrintAllHavingBalance': exit('IncludeAllCustomerswithBalance');
            'StatementStyle': exit('Statement Style');
        end;
        exit(ParameterName);
    end;

    local procedure StatementValue(ControlName: Text; Value: Text): Text
    begin
        case ControlName of
            'AgingBandPeriodLengt':
                if (Value <> '') and not Value.StartsWith('<') then
                    exit('<' + Value + '>');
            'AgingBandby':
                case Value of
                    'Due Date', '0': exit('0');
                    'Posting Date', '1': exit('1');
                    else Error(ChoiceErr, 'DateChoice', 'Due Date, Posting Date');
                end;
            'Statement Style':
                case Value of
                    'Balance', '0': exit('0');
                    'Open Item', '1': exit('1');
                    else Error(ChoiceErr, 'StatementStyle', 'Balance, Open Item');
                end;
        end;
        exit(Value);
    end;

    local procedure StatementTemplate(): Text
    begin
        // BC 28.5 report 1316 request control names, not translated captions or variable names.
        // PrintEntriesNotDue has no corresponding control and must fail as unknown.
        exit('<ReportParameters name="Standard Statement" id="1316"><Options>' +
            '<Field name="Start Date">0001-01-01</Field><Field name="End Date">0001-01-01</Field>' +
            '<Field name="AgingBandby">0</Field><Field name="IncludeAgingBand">false</Field>' +
            '<Field name="AgingBandPeriodLengt">&lt;1M&gt;</Field>' +
            '<Field name="IncludeAllCustomerswithBalance">true</Field>' +
            '<Field name="Statement Style">0</Field>' +
            '</Options><DataItems/></ReportParameters>');
    end;

    /// <summary>Supplies a headless XML template for a report without accessing saved settings.</summary>
    /// <param name="ReportId">Report whose request controls the template describes.</param>
    /// <param name="RequestPageXml">Base XML; leave unchanged when the report is not supported.</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetRequestPageTemplate(ReportId: Integer; var RequestPageXml: Text)
    begin
    end;

    var
        ParametersObjectErr: Label 'parameters must be an object.', Comment = 'is-IS=parameters verður að vera hlutur.';
        MissingBaseErr: Label 'No request page template is registered for report %1. Provide requestPageXml.', Comment = 'is-IS=Ekkert sniðmát beiðnisíðu er skráð fyrir skýrslu %1. Gefðu upp requestPageXml.';
        InvalidBaseErr: Label 'requestPageXml must contain ReportParameters for report %1 with unique option names.', Comment = 'is-IS=requestPageXml verður að innihalda ReportParameters fyrir skýrslu %1 með einkvæmum heitum valkosta.';
        UnknownParameterErr: Label 'Unknown request page parameter %1 on report %2.', Comment = 'is-IS=Óþekkt færibreyta beiðnisíðu %1 í skýrslu %2.';
        ScalarErr: Label 'Request page parameter %1 must be a non-null scalar value.', Comment = 'is-IS=Færibreyta beiðnisíðu %1 verður að vera einfalt gildi sem er ekki null.';
        DuplicateParameterErr: Label 'Request page option %1 is specified more than once on report %2.', Comment = 'is-IS=Valkostur beiðnisíðu %1 er tilgreindur oftar en einu sinni í skýrslu %2.';
        ChoiceErr: Label 'Request page parameter %1 must be one of: %2.', Comment = 'is-IS=Færibreyta beiðnisíðu %1 verður að vera eitt af: %2.';
}
