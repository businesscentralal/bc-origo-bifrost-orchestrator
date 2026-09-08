/// <summary>
/// Playbook definition header. A playbook is a named, reusable sequence of Bifrost
/// message type calls with data flow, foreach iteration, and conditional branching.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

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

    /// <summary>
    /// Puts this playbook on a recurring schedule by creating an orchestrator entry that runs the
    /// Playbook JQ Dispatcher, and stores the new entry id back on the playbook. A playbook that
    /// already points at a living orchestrator entry is refused; the existing entry has to be
    /// removed first. A stale id left behind by a deleted entry is simply overwritten.
    /// </summary>
    /// <param name="RecurringTemplateCode">The recurring template that sets days, times and interval.</param>
    /// <param name="NotificationType">How to notify on failure and restart: none, e-mail or Telegram.</param>
    /// <param name="NotificationRecipient">The address or chat id the notifications go to.</param>
    /// <param name="JobQueueCategoryCode">The Job Queue category to run under, or empty for none.</param>
    /// <param name="EmitTelemetry">Whether the entry writes telemetry on every run.</param>
    /// <param name="RetryPolicy">How often a failed run may be restarted automatically.</param>
    /// <returns>Guid. The id of the orchestrator entry that was created.</returns>
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

    /// <summary>
    /// Queues this playbook for a single background run with the defaults: no Job Queue category
    /// and a 60 second delay. Delegates to the three-parameter overload.
    /// </summary>
    /// <param name="RequestData">The initial request JSON handed to the run, or empty to use the playbook's own template.</param>
    /// <returns>Guid. The id of the Job Queue Entry that will run the playbook.</returns>
    procedure EnqueuePlaybook(RequestData: Text): Guid
    begin
        exit(EnqueuePlaybook(RequestData, '', 60));
    end;

    /// <summary>
    /// Queues this playbook for a single background run, letting the caller pick the Job Queue
    /// category and how long to wait before it starts. The request data is parked in a
    /// <c>JQ Parameter ori</c> row keyed by the Job Queue Entry id, which the dispatcher reads when
    /// the job fires; when no request data is given the playbook's own initial request template is
    /// used instead. A delay below 60 seconds is raised to 60.
    /// </summary>
    /// <param name="RequestData">The initial request JSON handed to the run, or empty to use the playbook's own template.</param>
    /// <param name="JobQueueCategoryCode">The Job Queue category to run under, or empty for none.</param>
    /// <param name="DelaySeconds">Seconds to wait before the earliest start. Values below 60 are raised to 60.</param>
    /// <returns>Guid. The id of the Job Queue Entry that will run the playbook.</returns>
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
