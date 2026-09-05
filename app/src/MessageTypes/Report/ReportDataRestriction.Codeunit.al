namespace Origo.Bifrost.Nornir;

using Origo.Bifrost;

codeunit 10035590 "Report Data Restriction ori"
{
    Access = Internal;
    SingleInstance = true;

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnAfterIsTableReadRestrictedForDataRecords, '', false, false)]
    local procedure RestrictPresetTableRead(TableNo: Integer; var IsRestricted: Boolean)
    begin
        if TableNo = Database::"Report Request Preset ori" then
            IsRestricted := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Message Argument ori", OnAfterIsTableWriteRestrictedForDataRecords, '', false, false)]
    local procedure RestrictPresetTableWrite(TableNo: Integer; var IsRestricted: Boolean)
    begin
        if TableNo = Database::"Report Request Preset ori" then
            IsRestricted := true;
    end;
}
