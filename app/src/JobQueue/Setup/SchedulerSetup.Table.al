namespace Origo.Bifrost.Nornir;

using System.Security.AccessControl;
using System.Security.User;
using System.Threading;

/// <summary>
/// Singleton setup table for the Job Queue Orchestrator configuration.
/// </summary>
table 10035536 "Scheduler Setup ori"
{
    Caption = 'Job Queue Orchestrator Setup', Comment = 'is-IS=Uppsetning vinnsluraðara';
    DataClassification = SystemMetadata;

    fields
    {
        field(10; PrimaryKey; Code[10])
        {
            Caption = 'PrimaryKey', Comment = 'is-IS=Aðallykill';
            DataClassification = SystemMetadata;
        }
        field(20; "Job Queue Category Code"; Code[10])
        {
            Caption = 'Job Queue Category Code', Comment = 'is-IS=Flokkunarkóði vinnsluraða';
            DataClassification = SystemMetadata;
            TableRelation = "Job Queue Category";
        }
        field(30; "Log Job Queue Activity"; Boolean)
        {
            Caption = 'Log Job Queue Activity', Comment = 'is-IS=Skrá virkni vinnsluraða';
            DataClassification = SystemMetadata;
        }
        field(40; "Job Queue User ID"; Code[50])
        {
            Caption = 'User ID', Comment = 'is-IS=Notendaauðkenni';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
            TableRelation = User."User Name";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UserSelection: Codeunit "User Selection";
            begin
                UserSelection.ValidateUserName("Job Queue User ID");
            end;
        }
        field(50; "Emit Telemetry"; Boolean)
        {
            Caption = 'Emit Telemetry', Comment = 'is-IS=Senda fjarmælingar';
            DataClassification = SystemMetadata;
        }
        field(60; "Telegram Bot Token ID"; Guid)
        {
            Caption = 'Telegram Bot Token ID', Comment = 'is-IS=Auðkenni Telegram-vélmennislykils';
            DataClassification = SystemMetadata;
        }
    }
    keys
    {
        key(PK; PrimaryKey)
        {
            Clustered = true;
        }
    }
    var
        JobQueueManagement: Codeunit "Scheduler Mgt ori";
        JobQueueOrchestratorDescTok: Label 'Job Queue Orchestrator', MaxLength = 30, Comment = 'is-IS=Vinnsluraðari';
        UnableToSetBotTokenMsg: Label 'Unable to set Telegram Bot Token', Comment = 'is-IS=Ekki tókst að setja Telegram-vélmennislykil';
        UnableToGetBotTokenMsg: Label 'Unable to get Telegram Bot Token', Comment = 'is-IS=Ekki tókst að sækja Telegram-vélmennislykil';
        RecordHasBeenRead: Boolean;

    /// <summary>
    /// Reads the setup record once per session and caches it.
    /// </summary>
    procedure GetRecordOnce()
    begin
        if RecordHasBeenRead then
            exit;
        Get();
        RecordHasBeenRead := true;
    end;

    /// <summary>
    /// Returns the configured Job Queue Category Code or the default orchestrator token.
    /// </summary>
    /// <returns>The Job Queue Category Code.</returns>
    internal procedure GetJobQueueCategoryCode() JobQueueCategoryCode: Code[10]
    begin
        if "Job Queue Category Code" = '' then
            JobQueueCategoryCode := JobQueueManagement.GetJobQueueOrchestratorTok()
        else
            JobQueueCategoryCode := "Job Queue Category Code";

        VerifyJobQueueCategoryCode(JobQueueCategoryCode, JobQueueOrchestratorDescTok);
    end;

    /// <summary>
    /// Initializes the setup record with defaults when opening an empty table.
    /// </summary>
    internal procedure OnOpenEmptyRec()
    begin
        if not IsEmpty() then
            exit;

        Init();
        PrimaryKey := '';
        "Job Queue Category Code" := JobQueueManagement.GetJobQueueOrchestratorTok();
        VerifyJobQueueCategoryCode("Job Queue Category Code", JobQueueOrchestratorDescTok);
        Insert(true);
    end;

    /// <summary>
    /// Restarts the management job queue entry using the configured category and user.
    /// </summary>
    internal procedure RestartManagementJobQueue()
    var
        JobQueueMgt: Codeunit "Scheduler Mgt ori";
    begin
        JobQueueMgt.ScheduleJobQueueEntry("Job Queue Category Code", "Job Queue User ID");
    end;

    /// <summary>
    /// Verifies the Job Queue Category exists; creates it if missing.
    /// </summary>
    /// <param name="JobQueueCategoryCode">The category code to verify.</param>
    /// <param name="JobQueueCategoryDescription">The description to use when creating the category.</param>
    internal procedure VerifyJobQueueCategoryCode(JobQueueCategoryCode: Code[10]; JobQueueCategoryDescription: Text[30])
    var
        JobQueueCategory: Record "Job Queue Category";
    begin
        if JobQueueCategory.Get(JobQueueCategoryCode) then exit;
        JobQueueCategory.Init();
        JobQueueCategory.Code := JobQueueCategoryCode;
        JobQueueCategory.Description := JobQueueCategoryDescription;
        JobQueueCategory.Insert();
    end;

    [NonDebuggable]
    internal procedure SetTelegramBotToken(BotToken: SecretText)
    begin
        if BotToken.IsEmpty() then begin
            if not IsNullGuid("Telegram Bot Token ID") then
                if IsolatedStorage.Delete(Format("Telegram Bot Token ID"), DataScope::Company) then;
            exit;
        end;

        if IsNullGuid("Telegram Bot Token ID") then
            "Telegram Bot Token ID" := CreateGuid();

        if not IsolatedStorage.Set(Format("Telegram Bot Token ID"), BotToken, DataScope::Company) then
            Error(UnableToSetBotTokenMsg);
    end;

    [NonDebuggable]
    internal procedure GetTelegramBotToken() BotToken: SecretText
    begin
        if not IsolatedStorage.Get(Format("Telegram Bot Token ID"), DataScope::Company, BotToken) then
            Error(UnableToGetBotTokenMsg);
    end;

    internal procedure HasTelegramBotToken(): Boolean
    begin
        exit(not IsNullGuid("Telegram Bot Token ID") and IsolatedStorage.Contains(Format("Telegram Bot Token ID"), DataScope::Company));
    end;
}
