/// <summary>
/// Job Queue entry point for playbook execution. When the Job Queue fires, this
/// codeunit reads the playbook record from the Job Queue Entry's Record ID to Process,
/// then delegates to the Bifrost Playbook Runner.
///
/// Also subscribes to the Bifrost Orchestrator registration event to automatically
/// create orchestrator entries for enabled playbooks.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using System.Threading;
using System.Utilities;

codeunit 10035548 "Playbook JQ Dispatcher ori"
{
    TableNo = "Job Queue Entry";
    Permissions = tabledata "Playbook ori" = RM,
                  tabledata "Playbook Instance ori" = R,
                  tabledata "JQ Parameter ori" = RD;

    trigger OnRun()
    var
        Playbook: Record "Playbook ori";
        JQParameter: Record "JQ Parameter ori";
        Runner: Codeunit "Playbook Runner ori";
        InitialRequest: BigText;
        FinalResponse: BigText;
        InstanceId: Guid;
        InitialRequestText: Text;
    begin
        Playbook.Get(GetPlaybookCodeFromJobQueueEntry(Rec));

        if JQParameter.Get(Rec.ID) then
            InitialRequestText := JQParameter.GetRequestData()
        else
            InitialRequestText := Playbook.GetInitialRequestTemplate();
        if InitialRequestText <> '' then
            InitialRequest.AddText(InitialRequestText);

        Runner.Run(Playbook.Code, InitialRequest, FinalResponse, InstanceId);

        Playbook.Get(Playbook.Code);
        Playbook."Last Run Instance ID" := InstanceId;
        Playbook."Last Run At" := CurrentDateTime();

        if GetInstanceStatus(InstanceId) = "Playbook Inst. Status ori"::Completed then
            Playbook."Last Run Status" := "Playbook Inst. Status ori"::Completed
        else
            Playbook."Last Run Status" := "Playbook Inst. Status ori"::Failed;

        Playbook.Modify();
    end;

    local procedure GetPlaybookCodeFromJobQueueEntry(JobQueueEntry: Record "Job Queue Entry"): Code[20]
    var
        Playbook: Record "Playbook ori";
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Playbook ori");
        RecRef.Get(JobQueueEntry."Record ID to Process");
        RecRef.SetTable(Playbook);
        exit(Playbook.Code);
    end;

    local procedure GetInstanceStatus(InstanceId: Guid): Enum "Playbook Inst. Status ori"
    var
        Instance: Record "Playbook Instance ori";
    begin
        if Instance.Get(InstanceId) then
            exit(Instance.Status);
        exit("Playbook Inst. Status ori"::Failed);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", OnAfterDeleteEvent, '', false, false)]
    local procedure OnAfterDeleteJobQueueEntry(var Rec: Record "Job Queue Entry"; RunTrigger: Boolean)
    var
        JQParameter: Record "JQ Parameter ori";
    begin
        JQParameter.SetRange(ID, Rec.ID);
        if not JQParameter.IsEmpty() then
            JQParameter.DeleteAll();
    end;
}
