namespace Origo.Bifrost.Orchestrator.Test;

using Origo.Bifrost;
using System.TestLibraries.Utilities;

/// <summary>
/// Roster direction for Orchestrator message types. Foundation treats Outbound as a read.
/// Types whose contract effect is write or irreversible are Inbound so MCP clients do not
/// treat them as read-only. Pure reads stay Outbound. Report.Get stays Both because it
/// reads and inserts an empty preset. Report.SaveAs stays Outbound: its effect is read.
/// </summary>
codeunit 96455 "Msg Direction Tests ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure ExecutingTypesAreInbound()
    begin
        // [SCENARIO #90] Run, Enqueue, Schedule and the other executing types are not read-only
        AssertDirection("Message Type ori"::"Orchestrator.Entry.Run", "Msg Direction ori"::Inbound, 'Orchestrator.Entry.Run');
        AssertDirection("Message Type ori"::"Orchestrator.Entry.Restart", "Msg Direction ori"::Inbound, 'Orchestrator.Entry.Restart');
        AssertDirection("Message Type ori"::"Orchestrator.Entry.Register", "Msg Direction ori"::Inbound, 'Orchestrator.Entry.Register');
        AssertDirection("Message Type ori"::"Orchestrator.Entry.Schedule", "Msg Direction ori"::Inbound, 'Orchestrator.Entry.Schedule');
        AssertDirection("Message Type ori"::"Orchestrator.Status.Restart", "Msg Direction ori"::Inbound, 'Orchestrator.Status.Restart');
        AssertDirection("Message Type ori"::"Orchestrator.Status.RestartIfNeeded", "Msg Direction ori"::Inbound, 'Orchestrator.Status.RestartIfNeeded');
        AssertDirection("Message Type ori"::"Orchestrator.Playbook.Run", "Msg Direction ori"::Inbound, 'Orchestrator.Playbook.Run');
        AssertDirection("Message Type ori"::"Orchestrator.Playbook.Schedule", "Msg Direction ori"::Inbound, 'Orchestrator.Playbook.Schedule');
        AssertDirection("Message Type ori"::"Orchestrator.Playbook.Enqueue", "Msg Direction ori"::Inbound, 'Orchestrator.Playbook.Enqueue');
        AssertDirection("Message Type ori"::"Orchestrator.JobQueueEntry.Restart", "Msg Direction ori"::Inbound, 'Orchestrator.JobQueueEntry.Restart');
        AssertDirection("Message Type ori"::"Orchestrator.JobQueueEntry.RestartIfNeeded", "Msg Direction ori"::Inbound, 'Orchestrator.JobQueueEntry.RestartIfNeeded');
        AssertDirection("Message Type ori"::"Orchestrator.Report.Run", "Msg Direction ori"::Inbound, 'Orchestrator.Report.Run');
        AssertDirection("Message Type ori"::"Orchestrator.Email.Send", "Msg Direction ori"::Inbound, 'Orchestrator.Email.Send');
        AssertDirection("Message Type ori"::"Orchestrator.Telegram.Message", "Msg Direction ori"::Inbound, 'Orchestrator.Telegram.Message');
        AssertDirection("Message Type ori"::"Orchestrator.ReportLayout.Set", "Msg Direction ori"::Inbound, 'Orchestrator.ReportLayout.Set');
    end;

    [Test]
    procedure ReadTypesStayOutboundOrBoth()
    begin
        // [SCENARIO #90] Reads stay Outbound. Report.Get remains Both. SaveAs remains a read.
        AssertDirection("Message Type ori"::"Orchestrator.Status.Get", "Msg Direction ori"::Outbound, 'Orchestrator.Status.Get');
        AssertDirection("Message Type ori"::"Help.Orchestrator.Get", "Msg Direction ori"::Outbound, 'Help.Orchestrator.Get');
        AssertDirection("Message Type ori"::"Orchestrator.Report.List", "Msg Direction ori"::Outbound, 'Orchestrator.Report.List');
        AssertDirection("Message Type ori"::"Orchestrator.Workspace.Preview", "Msg Direction ori"::Outbound, 'Orchestrator.Workspace.Preview');
        AssertDirection("Message Type ori"::"Orchestrator.Report.SaveAs", "Msg Direction ori"::Outbound, 'Orchestrator.Report.SaveAs');
        AssertDirection("Message Type ori"::"Orchestrator.Report.Get", "Msg Direction ori"::Both, 'Orchestrator.Report.Get');
    end;

    local procedure AssertDirection(MessageType: Enum "Message Type ori"; Expected: Enum "Msg Direction ori"; Name: Text)
    var
        MessageTypeInterface: Interface "Msg Interface ori";
    begin
        MessageTypeInterface := MessageType;
        Assert.AreEqual(Expected, MessageTypeInterface.GetMessageDirection(), Name);
    end;
}
