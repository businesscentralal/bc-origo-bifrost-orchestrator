/// <summary>
/// Per-step, per-iteration execution detail within a playbook instance.
/// One record per Dispatcher call — foreach steps produce one record per array element.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;

table 10035543 "Playbook Step Log ori"
{
    Caption = 'Bifrost Playbook Step Log', Comment = 'is-IS=Atburðaskrá keðjuskrefs';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Instance ID"; Guid)
        {
            Caption = 'Instance ID', Comment = 'is-IS=Auðkenni keyrslu';
            TableRelation = "Playbook Instance ori".ID;
        }
        field(2; "Step No."; Integer)
        {
            Caption = 'Step No.', Comment = 'is-IS=Skrefnúmer';
        }
        field(3; "Iteration No."; Integer)
        {
            Caption = 'Iteration No.', Comment = 'is-IS=Ítrunarnúmer';
        }
        field(10; "Message Type"; Enum "Message Type ori")
        {
            Caption = 'Message Type', Comment = 'is-IS=Skilaboðagerð';
        }
        field(20; Status; Enum "Playbook Inst. Status ori")
        {
            Caption = 'Status', Comment = 'is-IS=Staða';
        }
        field(30; "Request Sent"; Blob)
        {
            Caption = 'Request Sent', Comment = 'is-IS=Beiðni send';
            // Holds a whole message-type request payload, which routinely carries customer data.
            DataClassification = CustomerContent;
        }
        field(31; "Response Received"; Blob)
        {
            Caption = 'Response Received', Comment = 'is-IS=Svar móttekið';
            DataClassification = CustomerContent;
        }
        field(40; Duration; Duration)
        {
            Caption = 'Duration', Comment = 'is-IS=Tímalengd';
        }
        field(50; "Error Text"; Text[2048])
        {
            Caption = 'Error Text', Comment = 'is-IS=Villuboð';
        }
        field(60; "Iterator Element"; Blob)
        {
            Caption = 'Iterator Element', Comment = 'is-IS=Ítranarstök';
            DataClassification = CustomerContent;
        }
        field(70; "Workspace Snapshot"; Blob)
        {
            Caption = 'Workspace Snapshot', Comment = 'is-IS=Vinnusvæðisafrit';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Instance ID", "Step No.", "Iteration No.")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Sets the request sent blob from text.
    /// </summary>
    procedure SetRequestSent(RequestText: Text)
    var
        OutStr: OutStream;
    begin
        "Request Sent".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(RequestText);
    end;

    /// <summary>
    /// Gets the request sent blob as text.
    /// </summary>
    procedure GetRequestSent(): Text
    var
        InStr: InStream;
        Result: Text;
    begin
        CalcFields("Request Sent");
        if not "Request Sent".HasValue() then
            exit('');
        "Request Sent".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(Result);
        exit(Result);
    end;

    /// <summary>
    /// Sets the response received blob from text.
    /// </summary>
    procedure SetResponseReceived(ResponseText: Text)
    var
        OutStr: OutStream;
    begin
        "Response Received".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(ResponseText);
    end;

    /// <summary>
    /// Gets the response received blob as text.
    /// </summary>
    procedure GetResponseReceived(): Text
    var
        InStr: InStream;
        Result: Text;
    begin
        CalcFields("Response Received");
        if not "Response Received".HasValue() then
            exit('');
        "Response Received".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(Result);
        exit(Result);
    end;

    /// <summary>
    /// Sets the iterator element blob from text.
    /// </summary>
    procedure SetIteratorElement(ElementText: Text)
    var
        OutStr: OutStream;
    begin
        "Iterator Element".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(ElementText);
    end;

    /// <summary>
    /// Sets the workspace snapshot blob from text — the state of the playbook workspace as the
    /// step saw it, kept so a finished run can still be explained.
    /// </summary>
    /// <param name="WorkspaceText">The serialised workspace JSON to store.</param>
    procedure SetWorkspaceSnapshot(WorkspaceText: Text)
    var
        OutStr: OutStream;
    begin
        "Workspace Snapshot".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(WorkspaceText);
    end;

    /// <summary>
    /// Gets the workspace snapshot blob as text.
    /// </summary>
    /// <returns>Text. The stored workspace JSON, or empty when no snapshot was taken.</returns>
    procedure GetWorkspaceSnapshot(): Text
    var
        InStr: InStream;
        Result: Text;
    begin
        CalcFields("Workspace Snapshot");
        if not "Workspace Snapshot".HasValue() then
            exit('');
        "Workspace Snapshot".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(Result);
        exit(Result);
    end;
}
