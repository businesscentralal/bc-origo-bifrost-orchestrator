namespace Origo.Bifrost.Nornir;

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

    procedure SetRequestPageXml(XmlText: Text)
    var
        OutStr: OutStream;
    begin
        "Request Page XML".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(XmlText);
    end;

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

    procedure HasRequestPageXml(): Boolean
    begin
        CalcFields("Request Page XML");
        exit("Request Page XML".HasValue());
    end;
}
