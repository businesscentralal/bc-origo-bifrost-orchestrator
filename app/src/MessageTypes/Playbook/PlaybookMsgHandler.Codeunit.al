/// <summary>
/// Executes the Orchestrator.Playbook.* message types: run, schedule, and enqueue for Bifrost Playbooks.
/// </summary>
namespace Origo.Bifrost.Nornir;

using Origo.Bifrost;
using System.Threading;

codeunit 10035552 "Playbook Msg Handler ori"
{
    Access = Internal;
    Permissions =
        tabledata "Playbook ori" = RM,
        tabledata "Scheduled Entry ori" = RIMD,
        tabledata "Recurring Template ori" = R,
        tabledata "JQ Parameter ori" = RIM,
        tabledata "Job Queue Entry" = RIMD;

    /// <summary>
    /// Executes a Bifrost Playbook immediately and returns the execution result.
    /// </summary>
    /// <param name="Argument">Message argument carrying the request and receiving the response.</param>
    procedure ExecuteRun(var Argument: Record "Message Argument ori")
    var
        Playbook: Record "Playbook ori";
        Instance: Record "Playbook Instance ori";
        Runner: Codeunit "Playbook Runner ori";
        InitialRequest: BigText;
        FinalResponse: BigText;
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        InitialRequestToken: JsonToken;
        InstanceId: Guid;
    begin
        RequestJson := Argument.GetRequestJson();
        Playbook.Get(GetPlaybookCode(Argument, RequestJson));

        if RequestJson.Get('initialRequest', InitialRequestToken) then
            InitialRequest.AddText(Format(InitialRequestToken));

        Runner.Run(Playbook.Code, InitialRequest, FinalResponse, InstanceId);

        Instance.SetLoadFields(Status, "Steps Executed", "Steps Failed", "Items Processed");
        Instance.Get(InstanceId);

        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('instanceId', Format(InstanceId, 0, 4));
        ResponseJson.Add('playbookCode', Playbook.Code);
        ResponseJson.Add('playbookStatus', Format(Instance.Status));
        ResponseJson.Add('stepsExecuted', Instance."Steps Executed");
        ResponseJson.Add('stepsFailed', Instance."Steps Failed");
        ResponseJson.Add('itemsProcessed', Instance."Items Processed");
        Argument.SetResponseJson(ResponseJson);
    end;

    /// <summary>
    /// Creates an Orchestrator Entry for the playbook using the specified recurring template and notification settings.
    /// </summary>
    /// <param name="Argument">Message argument carrying the request and receiving the response.</param>
    procedure ExecuteSchedule(var Argument: Record "Message Argument ori")
    var
        Playbook: Record "Playbook ori";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        EntryId: Guid;
        RecurringTemplateCode: Code[20];
        NotificationType: Enum "Notif. Type ori";
        NotificationRecipient: Text[2048];
        JobQueueCategoryCode: Code[10];
        EmitTelemetry: Boolean;
        RetryPolicy: Enum "Retry Policy ori";
    begin
        RequestJson := Argument.GetRequestJson();
        Playbook.Get(GetPlaybookCode(Argument, RequestJson));

        RecurringTemplateCode := CopyStr(GetJsonText(RequestJson, 'recurringTemplateCode'), 1, 20);
        if RecurringTemplateCode = '' then
            Error(MissingTemplateCodeErr);

        NotificationType := ParseNotificationType(GetJsonText(RequestJson, 'notificationType'));
        NotificationRecipient := CopyStr(GetJsonText(RequestJson, 'notificationRecipient'), 1, 2048);
        JobQueueCategoryCode := CopyStr(GetJsonText(RequestJson, 'jobQueueCategoryCode'), 1, 10);
        EmitTelemetry := GetJsonBool(RequestJson, 'emitTelemetry');
        RetryPolicy := ParseRetryPolicy(GetJsonText(RequestJson, 'retryPolicy'));

        EntryId := Playbook.CreateOrchestratorEntry(
            RecurringTemplateCode, NotificationType, NotificationRecipient,
            JobQueueCategoryCode, EmitTelemetry, RetryPolicy);

        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('playbookCode', Playbook.Code);
        ResponseJson.Add('scheduled', true);
        ResponseJson.Add('orchestratorEntryId', Format(EntryId, 0, 4));
        Argument.SetResponseJson(ResponseJson);
    end;

    procedure ExecuteEnqueue(var Argument: Record "Message Argument ori")
    var
        Playbook: Record "Playbook ori";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        InitialRequestToken: JsonToken;
        CategoryToken: JsonToken;
        DelayToken: JsonToken;
        JQEntryId: Guid;
        RequestDataText: Text;
        CategoryCode: Code[10];
        DelaySeconds: Integer;
    begin
        RequestJson := Argument.GetRequestJson();
        Playbook.Get(GetPlaybookCode(Argument, RequestJson));

        if RequestJson.Get('initialRequest', InitialRequestToken) then
            RequestDataText := Format(InitialRequestToken);

        if RequestJson.Get('jobQueueCategory', CategoryToken) then
            CategoryCode := CopyStr(CategoryToken.AsValue().AsText(), 1, 10);

        DelaySeconds := 60;
        if RequestJson.Get('delaySeconds', DelayToken) then
            DelaySeconds := DelayToken.AsValue().AsInteger();
        if DelaySeconds < 60 then
            DelaySeconds := 60;

        JQEntryId := Playbook.EnqueuePlaybook(RequestDataText, CategoryCode, DelaySeconds);

        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('playbookCode', Playbook.Code);
        ResponseJson.Add('jobQueueEntryId', Format(JQEntryId, 0, 4));
        ResponseJson.Add('delaySeconds', DelaySeconds);
        if CategoryCode <> '' then
            ResponseJson.Add('jobQueueCategory', CategoryCode);
        Argument.SetResponseJson(ResponseJson);
    end;

    local procedure GetPlaybookCode(var Argument: Record "Message Argument ori"; RequestJson: JsonObject): Code[20]
    var
        PlaybookCodeToken: JsonToken;
    begin
        if RequestJson.Get('playbookCode', PlaybookCodeToken) then
            exit(CopyStr(PlaybookCodeToken.AsValue().AsText(), 1, 20));
        if Argument.Subject <> '' then
            exit(CopyStr(Argument.Subject, 1, 20));
        Error(MissingPlaybookCodeErr);
    end;

    var
        MissingPlaybookCodeErr: Label 'Request must include "playbookCode" in the data payload or as the subject.', Comment = 'is-IS=Beiðni verður að innihalda "playbookCode" í gagnahleðslunni eða sem viðfang.';
        MissingTemplateCodeErr: Label 'Request must include "recurringTemplateCode".', Comment = 'is-IS=Beiðni verður að innihalda "recurringTemplateCode".';

    local procedure GetJsonText(RequestJson: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        if RequestJson.Get(PropertyName, Token) then
            exit(Token.AsValue().AsText());
    end;

    local procedure GetJsonBool(RequestJson: JsonObject; PropertyName: Text): Boolean
    var
        Token: JsonToken;
    begin
        if RequestJson.Get(PropertyName, Token) then
            exit(Token.AsValue().AsBoolean());
    end;

    local procedure ParseNotificationType(Value: Text): Enum "Notif. Type ori"
    begin
        case UpperCase(Value) of
            'EMAIL':
                exit("Notif. Type ori"::EMail);
            'TELEGRAM':
                exit("Notif. Type ori"::Telegram);
            else
                exit("Notif. Type ori"::None);
        end;
    end;

    local procedure ParseRetryPolicy(Value: Text): Enum "Retry Policy ori"
    begin
        case UpperCase(Value) of
            'NEVER':
                exit("Retry Policy ori"::Never);
            'THREETIMES':
                exit("Retry Policy ori"::"Three Times");
            else
                exit("Retry Policy ori"::Always);
        end;
    end;
}
