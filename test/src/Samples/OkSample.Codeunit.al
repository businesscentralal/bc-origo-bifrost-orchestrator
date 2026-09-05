namespace Origo.Bifrost.Nornir.Test;

using Origo.Bifrost.Nornir;
/// <summary>
/// Sample codeunit used in tests to register and run a basic job queue scheduler entry.
/// </summary>
codeunit 96310 "Ok Sample"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        exit;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Scheduled Entry ori", 'OnRegisterJobQueueCodeunits', '', false, false)]
    local procedure Table_RMJobQueueEntrySetup_OnRegisterJobQueueCodeunits(Rec: Record "Scheduled Entry ori")
    begin
        RegisteOkSampleJobQueue(Rec);
    end;

    local procedure RegisteOkSampleJobQueue(Rec: Record "Scheduled Entry ori")
    begin
        if Rec.Get(GetJobQueueID()) then exit;

        Rec.Init();
        Rec.ID := GetJobQueueID();
        Rec."Object Type to Run" := Rec."Object Type to Run"::Codeunit;
        Rec."Object ID to Run" := Codeunit::"Ok Sample";
        Rec."Earliest Start Date/Time" := CurrentDateTime;
        Rec.Blocked := false;
        Rec."No. of Minutes between Runs" := 1440;
        Rec."Run on Mondays" := true;
        Rec.Insert();
    end;

    procedure GetJobQueueID(): Guid
    begin
        exit('c951010f-3cc6-4be8-a151-d35eee1add93');
    end;
}
