namespace Origo.Bifrost.Orchestrator;

table 10035590 "Report Request Preset ori"
{
    Caption = 'Bifrost Report Request Preset', Comment = 'is-IS=Bifröst Skýrsluforsendur';
    DataClassification = CustomerContent;
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    fields
    {
        field(1; "Report ID"; Integer)
        {
            Caption = 'Report ID', Comment = 'is-IS=Skýrsluauðkenni';
        }
        field(2; "User Security ID"; Guid)
        {
            Caption = 'User Security ID', Comment = 'is-IS=Notandaauðkenni';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description', Comment = 'is-IS=Lýsing';
        }
        field(10; "Request Page XML"; Blob)
        {
            Caption = 'Request Page XML', Comment = 'is-IS=XML beiðnisíðu';
        }
    }

    keys
    {
        key(PK; "Report ID", "User Security ID")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Writes the Request Page XML blob from text. Only fills the stream; the caller still has to
    /// <c>Insert</c> or <c>Modify</c> the record.
    /// </summary>
    /// <param name="XmlText">The captured request page parameters to store for this report and user.</param>
    procedure SetRequestPageXml(XmlText: Text)
    var
        OutStr: OutStream;
    begin
        "Request Page XML".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(XmlText);
    end;

    /// <summary>
    /// Reads the Request Page XML blob as text. This is what the report message types feed to
    /// <c>Report.SaveAs</c> and <c>Report.Execute</c> when the request itself carries no parameters.
    /// </summary>
    /// <returns>Text. The stored request page XML, or empty when the preset was never captured.</returns>
    procedure GetRequestPageXml() XmlText: Text
    var
        InStr: InStream;
    begin
        CalcFields("Request Page XML");
        if not "Request Page XML".HasValue() then
            exit('');
        "Request Page XML".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(XmlText);
    end;

    /// <summary>
    /// Reports whether request page parameters have been captured for this report and user, without
    /// reading the blob itself.
    /// </summary>
    /// <returns>Boolean. True when the Request Page XML blob holds a value.</returns>
    procedure HasRequestPageXml(): Boolean
    begin
        CalcFields("Request Page XML");
        exit("Request Page XML".HasValue());
    end;
}
