namespace Origo.Bifrost.Nornir;

table 10035544 "JQ Parameter ori"
{
    Caption = 'Bifrost JQ Parameter', Comment = 'is-IS=Færibreyta vinnsluraðar Bifrastar';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; ID; Guid)
        {
            Caption = 'ID', Comment = 'is-IS=Auðkenni';
        }
        field(10; "Request Data"; Blob)
        {
            Caption = 'Request Data', Comment = 'is-IS=Beðnigögn';
        }
    }

    keys
    {
        key(PK; ID)
        {
            Clustered = true;
        }
    }

    procedure GetRequestData(): Text
    var
        InStr: InStream;
        Result: Text;
    begin
        CalcFields("Request Data");
        if not "Request Data".HasValue() then
            exit('');
        "Request Data".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.Read(Result);
        exit(Result);
    end;

    procedure SetRequestData(RequestText: Text)
    var
        OutStr: OutStream;
    begin
        "Request Data".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.Write(RequestText);
    end;
}
