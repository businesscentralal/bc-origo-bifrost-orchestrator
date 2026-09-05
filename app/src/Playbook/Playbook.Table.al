/// <summary>
/// Playbook definition header. A playbook is a named, reusable sequence of Bifrost
/// message type calls with data flow, foreach iteration, and conditional branching.
/// </summary>
namespace Origo.Bifrost.Nornir;

using System.Threading;

table 10035539 "Playbook ori"
{
    Caption = 'Bifrost Playbook', Comment = 'is-IS=Bifröst keðja';
    DataClassification = SystemMetadata;
    LookupPageId = "Playbooks ori";
    DrillDownPageId = "Playbooks ori";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code', Comment = 'is-IS=Kóði';
            NotBlank = true;
        }
        field(10; Description; Text[250])
        {
            Caption = 'Description', Comment = 'is-IS=Lýsing';
        }
        field(30; "Initial Request Template"; Blob)
        {
            Caption = 'Initial Request Template', Comment = 'is-IS=Upphafsbeðni sniðmát';
        }
        field(70; "Last Run Instance ID"; Guid)
        {
            Caption = 'Last Run Instance ID', Comment = 'is-IS=Auðkenni síðustu keyrslu';
            Editable = false;
        }
        field(71; "Last Run Status"; Enum "Playbook Inst. Status ori")
        {
            Caption = 'Last Run Status', Comment = 'is-IS=Staða síðustu keyrslu';
            Editable = false;
        }
        field(72; "Last Run At"; DateTime)
        {
            Caption = 'Last Run At', Comment = 'is-IS=Síðast keyrt';
            Editable = false;
        }
        field(80; "Orchestrator Entry ID"; Guid)
        {
            Caption = 'Orchestrator Entry ID', Comment = 'is-IS=Auðkenni vinnsluraðarstjóra';
            Editable = false;
        }
        field(81; Scheduled; Boolean)
        {
            Caption = 'Scheduled', Comment = 'is-IS=Tímasett';
            FieldClass = FlowField;
            CalcFormula = exist("Scheduled Entry ori" where(ID = field("Orchestrator Entry ID")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Gets the initial request template as text.
    /// </summary>
    /// <returns>The JSON template text, or empty if not set.</returns>
    procedure GetInitialRequestTemplate(): Text
    var
        InStr: InStream;
        Result: Text;
    begin
        CalcFields("Initial Request Template");
        if not "Initial Request Template".HasValue() then
            exit('');
        "Initial Request Template".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(Result);
        exit(Result);
    end;

    /// <summary>
    /// Sets the initial request template from text.
    /// </summary>
    /// <param name="TemplateText">JSON template text to store.</param>
    procedure SetInitialRequestTemplate(TemplateText: Text)
    var
        OutStr: OutStream;
    begin
        "Initial Request Template".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(TemplateText);
    end;

    procedure CreateOrchestratorEntry(
        RecurringTemplateCode: Code[20];
        NotificationType: Enum "Notif. Type ori";
        NotificationRecipient: Text[2048];
        JobQueueCategoryCode: Code[10];
        EmitTelemetry: Boolean;
        RetryPolicy: Enum "Retry Policy ori"): Guid
    var
        Entry: Record "Scheduled Entry ori";
        AlreadyScheduledErr: Label 'Playbook %1 is already scheduled. Remove the existing orchestrator entry first.', Comment = '%1 = playbook code, is-IS=Keðja %1 er þegar tímasett. Fjarlægðu núverandi vinnsluraðarstjórafærslu fyrst.';
    begin
        if not IsNullGuid("Orchestrator Entry ID") then begin
            Entry.SetLoadFields(ID);
            if Entry.Get("Orchestrator Entry ID") then
                Error(AlreadyScheduledErr, Code);
        end;

        Entry.Init();
        Entry.ID := CreateGuid();
        Entry."Object Type to Run" := Entry."Object Type to Run"::Codeunit;
        Entry.Validate("Object ID to Run", Codeunit::"Playbook JQ Dispatcher ori");
        Entry."Record ID to Process" := RecordId();
        Entry."Related Record System Id" := SystemId;
        Entry.Description := Description;
        Entry.Validate("Recurring Template Code", RecurringTemplateCode);
        Entry."Notification Type" := NotificationType;
        Entry."Notification Recipient" := NotificationRecipient;
        Entry."Job Queue Category Code" := JobQueueCategoryCode;
        Entry."Emit Telemetry" := EmitTelemetry;
        Entry."Retry Policy" := RetryPolicy;
        Entry.Blocked := false;
        Entry."Earliest Start Date/Time" := CurrentDateTime();
        Entry.Insert(true);

        "Orchestrator Entry ID" := Entry.ID;
        Modify();
        exit(Entry.ID);
    end;

    procedure EnqueuePlaybook(RequestData: Text): Guid
    begin
        exit(EnqueuePlaybook(RequestData, '', 60));
    end;

    procedure EnqueuePlaybook(RequestData: Text; JobQueueCategoryCode: Code[10]; DelaySeconds: Integer): Guid
    var
        JQEntry: Record "Job Queue Entry";
        JQParameter: Record "JQ Parameter ori";
    begin
        if DelaySeconds < 60 then
            DelaySeconds := 60;

        JQEntry.Init();
        JQEntry.ID := CreateGuid();
        JQEntry."Object Type to Run" := JQEntry."Object Type to Run"::Codeunit;
        JQEntry."Object ID to Run" := Codeunit::"Playbook JQ Dispatcher ori";
        JQEntry.Description := CopyStr(Description, 1, MaxStrLen(JQEntry.Description));
        JQEntry."Record ID to Process" := RecordId();
        JQEntry."Job Queue Category Code" := JobQueueCategoryCode;
        JQEntry."Recurring Job" := false;
        JQEntry."Earliest Start Date/Time" := CurrentDateTime() + (DelaySeconds * 1000);
        JQEntry.Insert(true);

        if RequestData <> '' then begin
            JQParameter.Init();
            JQParameter.ID := JQEntry.ID;
            JQParameter.SetRequestData(RequestData);
            JQParameter.Insert(true);
        end;

        JQEntry.SetStatus(JQEntry.Status::Ready);
        exit(JQEntry.ID);
    end;
}
