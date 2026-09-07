namespace Origo.Bifrost.Orchestrator;

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
            // Holds the queued playbook's request payload, which routinely carries customer data.
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; ID)
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Reads the Request Data blob as text. This is the initial request JSON that
    /// <c>Playbook ori.EnqueuePlaybook</c> parked here under the Job Queue Entry id, and that
    /// <c>Playbook JQ Dispatcher ori</c> picks up when the queued job fires.
    /// </summary>
    /// <returns>Text. The stored request, or empty when nothing was stored.</returns>
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

    /// <summary>
    /// Writes the Request Data blob from text. Only fills the stream; the caller still has to
    /// <c>Insert</c> or <c>Modify</c> the record.
    /// </summary>
    /// <param name="RequestText">The initial request JSON to hand to the queued playbook run.</param>
    procedure SetRequestData(RequestText: Text)
    var
        OutStr: OutStream;
    begin
        "Request Data".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.Write(RequestText);
    end;
}
