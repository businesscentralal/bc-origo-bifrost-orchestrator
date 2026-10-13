namespace Origo.Bifrost.Orchestrator.Test;

using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Origo.Bifrost;
using Origo.Bifrost.Orchestrator;
using System.Reflection;
using System.TestLibraries.Utilities;

/// <summary>Checks bounded XML overlays, extensible templates and real report execution.</summary>
codeunit 96431 "Report Parameter Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit "Library Assert";
        Resolver: Codeunit "Report Parameters ori";

    /// <summary>Updates only named options and preserves the caller's other options and data view.</summary>
    [Test]
    procedure OverlayPreservesOtherValues()
    var
        Request: JsonObject;
        Parameters: JsonObject;
        Result: XmlDocument;
        Node: XmlNode;
    begin
        Parameters.Add('SampleText', 'new <text> & "quotes"');
        Request := RequestWithBase(Parameters);
        XmlDocument.ReadFrom(Resolver.Resolve(96455, Request), Result);
        Assert.AreEqual('new <text> & "quotes"', OptionText(Result, 'SampleText'), 'Text is XML escaped, not markup');
        Assert.AreEqual('false', OptionText(Result, 'SampleFlag'), 'Untouched option');
        Result.SelectSingleNode('/ReportParameters/DataItems/DataItem', Node);
        Assert.AreEqual('VERSION(1) SORTING(Field1) WHERE(Field1=CONST(1))', Node.AsXmlElement().InnerText(), 'Caller data item view retained');
    end;

    /// <summary>Unknown names, including XPath-like input, cannot address another XML node.</summary>
    [Test]
    procedure UnknownNameFails()
    var
        Request: JsonObject;
        Parameters: JsonObject;
    begin
        Parameters.Add('SampleText" or @name="SampleFlag', 'malicious');
        Request := RequestWithBase(Parameters);
        asserterror Resolver.Resolve(96455, Request);
        Assert.ExpectedError('Unknown request page parameter SampleText" or @name="SampleFlag on report 96455.');
    end;

    /// <summary>A report without a registered template asks for explicit XML.</summary>
    [Test]
    procedure MissingBaseFails()
    var
        Request: JsonObject;
        Parameters: JsonObject;
    begin
        Parameters.Add('SampleText', 'test');
        Request.Add('parameters', Parameters);
        asserterror Resolver.Resolve(96455, Request);
        Assert.ExpectedError('Provide requestPageXml.');
    end;

    /// <summary>Caller XML must belong to the requested report.</summary>
    [Test]
    procedure WrongReportXmlFails()
    var
        Request: JsonObject;
        Parameters: JsonObject;
    begin
        Request := RequestWithBase(Parameters);
        asserterror Resolver.Resolve(1316, Request);
        Assert.ExpectedError('ReportParameters for report 1316');
    end;

    /// <summary>Malformed XML is rejected before executing a report.</summary>
    [Test]
    procedure MalformedXmlFails()
    var
        Request: JsonObject;
        Parameters: JsonObject;
    begin
        Request.Add('parameters', Parameters);
        Request.Add('requestPageXml', '<not-closed');
        asserterror Resolver.Resolve(96455, Request);
        Assert.ExpectedError('ReportParameters for report 96455');
    end;

    /// <summary>Duplicate option names are ambiguous and rejected.</summary>
    [Test]
    procedure DuplicateOptionFails()
    var
        Request: JsonObject;
        Parameters: JsonObject;
    begin
        Parameters.Add('x', 'new');
        Request.Add('parameters', Parameters);
        Request.Add('requestPageXml', '<ReportParameters id="96455"><Options><Field name="x">1</Field><Field name="x">2</Field></Options></ReportParameters>');
        asserterror Resolver.Resolve(96455, Request);
        Assert.ExpectedError('unique option names');
    end;

    /// <summary>Arrays are not parameter maps.</summary>
    [Test]
    procedure NonObjectParametersFail()
    var
        Request: JsonObject;
        Values: JsonArray;
    begin
        Request.Add('parameters', Values);
        asserterror Resolver.Resolve(96455, Request);
        Assert.ExpectedError('parameters must be an object.');
    end;

    /// <summary>Null option values cannot erase a request control silently.</summary>
    [Test]
    procedure NullValueFails()
    var
        Request: JsonObject;
        Parameters: JsonObject;
        NullValue: JsonValue;
    begin
        NullValue.SetValueToNull();
        Parameters.Add('SampleText', NullValue);
        Request := RequestWithBase(Parameters);
        asserterror Resolver.Resolve(96455, Request);
        Assert.ExpectedError('non-null scalar');
    end;

    /// <summary>Nested maps cannot be serialized into arbitrary request options.</summary>
    [Test]
    procedure NestedValueFails()
    var
        Request: JsonObject;
        Parameters: JsonObject;
        Nested: JsonObject;
    begin
        Parameters.Add('SampleText', Nested);
        Request := RequestWithBase(Parameters);
        asserterror Resolver.Resolve(96455, Request);
        Assert.ExpectedError('non-null scalar');
    end;

    /// <summary>Every supported Statement alias maps to an actual platform control and invariant value.</summary>
    [Test]
    procedure StatementTemplateMapsOptions()
    var
        Request: JsonObject;
        Parameters: JsonObject;
        Result: XmlDocument;
    begin
        Parameters.Add('StartDate', '2026-01-01');
        Parameters.Add('EndDate', '2026-12-31');
        Parameters.Add('DateChoice', 'Posting Date');
        Parameters.Add('PrintAging', true);
        Parameters.Add('AgingBandPeriodLength', '30D');
        Parameters.Add('PrintAllHavingBalance', false);
        Parameters.Add('StatementStyle', 'Open Item');
        Request.Add('parameters', Parameters);
        XmlDocument.ReadFrom(Resolver.Resolve(1316, Request), Result);
        Assert.AreEqual('2026-01-01', OptionText(Result, 'StartDate'), 'Start date');
        Assert.AreEqual('2026-12-31', OptionText(Result, 'EndDate'), 'End date');
        Assert.AreEqual('1', OptionText(Result, 'DateChoice'), 'Date option ordinal');
        Assert.AreEqual('true', OptionText(Result, 'IncludeAgingBand'), 'Boolean');
        Assert.AreEqual('<30D>', OptionText(Result, 'PeriodLength'), 'Formula text');
        Assert.AreEqual('false', OptionText(Result, 'PrintAllHavingBal'), 'Balance flag');
        Assert.AreEqual('1', OptionText(Result, 'StatementStyle'), 'Statement ordinal');
    end;

    /// <summary>Alias and actual control cannot set the same option twice with order-dependent values.</summary>
    [Test]
    procedure DuplicateAliasesFail()
    var
        Request: JsonObject;
        Parameters: JsonObject;
    begin
        Parameters.Add('PrintAging', true);
        Parameters.Add('IncludeAgingBand', false);
        Request.Add('parameters', Parameters);
        asserterror Resolver.Resolve(1316, Request);
        Assert.ExpectedError('specified more than once');
    end;

    /// <summary>The platform capture uses globals rather than the request-page control identifiers.</summary>
    [Test]
    [HandlerFunctions('CaptureSampleOptions')]
    procedure NativeCaptureMatchesTemplateSchema()
    var
        Document: XmlDocument;
    begin
        XmlDocument.ReadFrom(Report.RunRequestPage(Report::"Layout Sample Report ori", SampleTemplate()), Document);
        Assert.AreEqual('native capture', OptionText(Document, 'SampleText'), 'Native XML serialization name');
        Assert.AreEqual('true', OptionText(Document, 'SampleFlag'), 'Native boolean serialization');
    end;

    /// <summary>Provides deterministic options to the test report request page.</summary>
    [RequestPageHandler]
    procedure CaptureSampleOptions(var RequestPage: TestRequestPage "Layout Sample Report ori")
    begin
        RequestPage.FixtureText.SetValue('native capture');
        RequestPage.FixtureFlag.SetValue(true);
        RequestPage.OK().Invoke();
    end;

    /// <summary>A nonexistent Statement control fails rather than being mapped to different semantics.</summary>
    [Test]
    procedure StatementUnknownOptionFails()
    var
        Request: JsonObject;
        Parameters: JsonObject;
    begin
        Parameters.Add('PrintEntriesNotDue', true);
        Request.Add('parameters', Parameters);
        asserterror Resolver.Resolve(1316, Request);
        Assert.ExpectedError('Unknown request page parameter PrintEntriesNotDue on report 1316.');
    end;

    /// <summary>Choice captions are fixed contract names; unknown values are rejected.</summary>
    [Test]
    procedure StatementBadChoiceFails()
    var
        Request: JsonObject;
        Parameters: JsonObject;
    begin
        Parameters.Add('DateChoice', 'not-a-date-choice');
        Request.Add('parameters', Parameters);
        asserterror Resolver.Resolve(1316, Request);
        Assert.ExpectedError('DateChoice must be one of: Due Date, Posting Date.');
    end;

    /// <summary>Explicit XML takes precedence over built-in templates and cannot gain missing fields.</summary>
    [Test]
    procedure CallerXmlPrecedesTemplate()
    var
        Request: JsonObject;
        Parameters: JsonObject;
    begin
        Parameters.Add('PrintAging', true);
        Request.Add('parameters', Parameters);
        Request.Add('requestPageXml', '<ReportParameters id="1316"><Options><Field name="StartDate">2026-01-01</Field></Options></ReportParameters>');
        asserterror Resolver.Resolve(1316, Request);
        Assert.ExpectedError('Unknown request page parameter PrintAging on report 1316.');
    end;

    /// <summary>A subscriber supplies a deterministic template, and real SaveAs sees its overlaid values.</summary>
    [Test]
    procedure RegisteredTemplateRendersValues()
    var
        Subscriber: Codeunit "Report Parameter Tests ori";
        Request: JsonObject;
        Parameters: JsonObject;
        Result: XmlDocument;
        Node: XmlNode;
    begin
        BindSubscription(Subscriber);
        Parameters.Add('SampleText', 'observed & <safe>');
        Parameters.Add('SampleFlag', true);
        Parameters.Add('SampleDate', '2026-10-13');
        Request.Add('parameters', Parameters);
        Result := SaveAsXml(Request);
        UnbindSubscription(Subscriber);
        Result.SelectSingleNode('//*[@name="ObservedText"]', Node);
        Assert.AreEqual('observed & <safe>', Node.AsXmlElement().InnerText(), 'Actual report read explicit text');
        Result.SelectSingleNode('//*[@name="ObservedFlag"]', Node);
        Assert.AreEqual('true', LowerCase(Node.AsXmlElement().InnerText()), 'Actual report read boolean');
        Result.SelectSingleNode('//*[@name="ObservedDate"]', Node);
        Assert.AreEqual('2026-10-13', Node.AsXmlElement().InnerText(), 'Actual report read ISO date');
    end;

    /// <summary>Explicit parameters ignore an invalid saved preset and leave its bytes unchanged.</summary>
    [Test]
    procedure ExplicitParametersDoNotUsePreset()
    var
        Preset: Record "Report Request Preset ori";
        Request: JsonObject;
        Parameters: JsonObject;
    begin
        Preset.Init();
        Preset."Report ID" := Report::"Layout Sample Report ori";
        Preset."User Security ID" := UserSecurityId();
        Preset.SetRequestPageXml('<invalid-owned-saved-settings/>');
        Preset.Insert();
        Parameters.Add('SampleText', 'explicit');
        Request := RequestWithBase(Parameters);
        SaveAsXml(Request);
        Preset.Get(Report::"Layout Sample Report ori", UserSecurityId());
        Assert.AreEqual('<invalid-owned-saved-settings/>', Preset.GetRequestPageXml(), 'No saved setting mutation');
        Preset.Delete();
    end;

    /// <summary>Renders the actual 1316 aging dataset using isolated customer and ledger fixtures.</summary>
    [Test]
    procedure StatementRendersOwnAgingData()
    var
        Customer: Record Customer;
        Entry: Record "Cust. Ledger Entry";
        Detail: Record "Detailed Cust. Ledg. Entry";
        Layout: Record "Report Layout List";
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report SaveAs Msg ori";
        Request: JsonObject;
        Parameters: JsonObject;
        Content: InStream;
        Document: XmlDocument;
        Node: XmlNode;
        Nodes: XmlNodeList;
        EntryNo: Integer;
        DetailNo: Integer;
        Amount: Decimal;
        Total: Decimal;
    begin
        Customer.Init();
        Customer."No." := CopyStr('XOVL-' + DelChr(Format(CreateGuid(), 0, 4), '=', '-'), 1, MaxStrLen(Customer."No."));
        Customer.Name := 'Owned statement overlay fixture';
        Customer.Insert();
        if Entry.FindLast() then
            EntryNo := Entry."Entry No.";
        EntryNo += 1;
        Entry.Init();
        Entry."Entry No." := EntryNo;
        Entry."Customer No." := Customer."No.";
        Entry."Document Type" := Entry."Document Type"::Invoice;
        Entry."Document No." := Customer."No.";
        Entry."Posting Date" := 20261201D;
        Entry."Due Date" := 20261215D;
        Entry.Open := true;
        Entry.Positive := true;
        Entry.Insert();
        if Detail.FindLast() then
            DetailNo := Detail."Entry No.";
        DetailNo += 1;
        Detail.Init();
        Detail."Entry No." := DetailNo;
        Detail."Cust. Ledger Entry No." := EntryNo;
        Detail."Customer No." := Customer."No.";
        Detail."Posting Date" := 20261201D;
        Detail."Entry Type" := Detail."Entry Type"::"Initial Entry";
        Detail.Amount := 75;
        Detail."Amount (LCY)" := 75;
        Detail.Insert();
        Parameters.Add('StartDate', '2026-01-01');
        Parameters.Add('EndDate', '2026-12-31');
        Parameters.Add('PrintAging', true);
        Parameters.Add('AgingBandPeriodLength', '30D');
        Parameters.Add('DateChoice', 'Due Date');
        Request.Add('reportId', 1316);
        Request.Add('format', 'XML');
        Request.Add('parameters', Parameters);
        Request.Add('tableView', 'WHERE(No.=CONST(' + Customer."No." + '))');
        Layout.SetRange("Report ID", 1316);
        Layout.SetRange(Name, 'StandardStatement.rdlc');
        Assert.IsTrue(Layout.FindFirst(), 'Installed standard RDLC layout');
        Request.Add('layoutName', Layout.Name);
        Request.Add('appId', Format(Layout."Application ID", 0, 4));
        TempArgument.Init();
        TempArgument.Insert();
        TempArgument.SetRequestJson(Request);
        Handler.ExecuteBifrostTask(TempArgument);
        TempArgument.CalcFields("Response Content");
        TempArgument."Response Content".CreateInStream(Content);
        XmlDocument.ReadFrom(Content, Document);
        Assert.IsTrue(Document.SelectSingleNode('//*[@name="AgingBandEndingDate"]', Node), 'Actual statement emitted its aging section');
        Assert.IsTrue(StrPos(Node.AsXmlElement().InnerText(), '30') > 0, 'Actual statement uses requested period');
        Document.SelectNodes('//*[starts-with(@name,"AgingBandBufCol")]', Nodes);
        foreach Node in Nodes do
            if Evaluate(Amount, Node.AsXmlElement().InnerText(), 9) then
                Total += Amount;
        Assert.AreEqual(75, Total, 'Own ledger amount reaches aging buckets');
        Detail.Delete();
        Entry.Delete();
        Customer.Delete();
        Assert.IsFalse(Detail.Get(DetailNo), 'Own detailed entry cleaned');
        Assert.IsFalse(Entry.Get(EntryNo), 'Own entry cleaned');
        Assert.IsFalse(Customer.Get(Customer."No."), 'Own customer cleaned');
    end;

    local procedure RequestWithBase(Parameters: JsonObject) Request: JsonObject
    begin
        Request.Add('parameters', Parameters);
        Request.Add('requestPageXml', SampleTemplate());
    end;

    local procedure SampleTemplate(): Text
    begin
        exit('<ReportParameters name="Layout Sample Report ori" id="96455"><Options>' +
            '<Field name="SampleText">base</Field><Field name="SampleFlag">false</Field><Field name="SampleDate">0001-01-01</Field>' +
            '</Options><DataItems><DataItem name="Loop">VERSION(1) SORTING(Field1) WHERE(Field1=CONST(1))</DataItem></DataItems></ReportParameters>');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Parameters ori", OnGetRequestPageTemplate, '', false, false)]
    local procedure SupplySampleTemplate(ReportId: Integer; var RequestPageXml: Text)
    begin
        if ReportId = Report::"Layout Sample Report ori" then
            RequestPageXml := SampleTemplate();
    end;

    local procedure OptionText(Document: XmlDocument; OptionName: Text): Text
    var
        Node: XmlNode;
    begin
        Assert.IsTrue(Document.SelectSingleNode('/ReportParameters/Options/Field[@name="' + OptionName + '"]', Node), 'Option exists: ' + OptionName);
        exit(Node.AsXmlElement().InnerText());
    end;

    local procedure SaveAsXml(Request: JsonObject) Result: XmlDocument
    var
        TempArgument: Record "Message Argument ori" temporary;
        Handler: Codeunit "Report SaveAs Msg ori";
        Content: InStream;
    begin
        Request.Add('reportId', Report::"Layout Sample Report ori");
        Request.Add('format', 'XML');
        Request.Add('tableView', 'WHERE(Number=CONST(1))');
        TempArgument.Init();
        TempArgument.Insert();
        TempArgument.SetRequestJson(Request);
        Handler.ExecuteBifrostTask(TempArgument);
        TempArgument.CalcFields("Response Content");
        TempArgument."Response Content".CreateInStream(Content);
        XmlDocument.ReadFrom(Content, Result);
    end;
}
