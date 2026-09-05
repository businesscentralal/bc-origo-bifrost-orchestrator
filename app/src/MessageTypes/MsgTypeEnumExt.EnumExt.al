/// <summary>
/// Registers all Bifrost Nornir message types and maps each to its
/// implementing "Msg Interface ori" codeunit.
/// </summary>
namespace Origo.Bifrost.Nornir;

using Origo.Bifrost;

enumextension 10035536 "MsgType.EnumExt ori" extends "Message Type ori"
{
    value(10035537; "Orchestrator.Entry.Run")
    {
        Caption = 'Orchestrator.Entry.Run';
        Implementation = "Msg Interface ori" = "SE Run Msg ori";
    }
    value(10035538; "Orchestrator.Entry.Restart")
    {
        Caption = 'Orchestrator.Entry.Restart';
        Implementation = "Msg Interface ori" = "SE Restart Msg ori";
    }
    value(10035541; "Orchestrator.Status.Get")
    {
        Caption = 'Orchestrator.Status.Get';
        Implementation = "Msg Interface ori" = "Status Get Msg ori";
    }
    value(10035542; "Orchestrator.Status.Restart")
    {
        Caption = 'Orchestrator.Status.Restart';
        Implementation = "Msg Interface ori" = "Status Restart Msg ori";
    }
    value(10035543; "Orchestrator.Status.RestartIfNeeded")
    {
        Caption = 'Orchestrator.Status.RestartIfNeeded';
        Implementation = "Msg Interface ori" = "Status RestartIf Msg ori";
    }
    value(10035544; "Orchestrator.Playbook.Run")
    {
        Caption = 'Orchestrator.Playbook.Run';
        Implementation = "Msg Interface ori" = "Playbook Run Msg ori";
    }
    value(10035548; "Orchestrator.JobQueueEntry.Restart")
    {
        Caption = 'Orchestrator.JobQueueEntry.Restart';
        Implementation = "Msg Interface ori" = "Entry Restart Msg ori";
    }
    value(10035549; "Orchestrator.JobQueueEntry.RestartIfNeeded")
    {
        Caption = 'Orchestrator.JobQueueEntry.RestartIfNeeded';
        Implementation = "Msg Interface ori" = "Entry RestartIf Msg ori";
    }
    value(10035551; "Help.Orchestrator.Get")
    {
        Caption = 'Help.Orchestrator.Get';
        Implementation = "Msg Interface ori" = "Help Get Impl ori";
    }
    value(10035552; "Orchestrator.Playbook.Schedule")
    {
        Caption = 'Orchestrator.Playbook.Schedule';
        Implementation = "Msg Interface ori" = "Playbook Schedule Msg ori";
    }
    value(10035576; "Orchestrator.Entry.Register")
    {
        Caption = 'Orchestrator.Entry.Register';
        Implementation = "Msg Interface ori" = "SE Register Msg ori";
    }
    value(10035578; "Orchestrator.Entry.Schedule")
    {
        Caption = 'Orchestrator.Entry.Schedule';
        Implementation = "Msg Interface ori" = "SE Schedule Msg ori";
    }
    value(10035582; "Orchestrator.Email.Send")
    {
        Caption = 'Orchestrator.Email.Send';
        Implementation = "Msg Interface ori" = "Email Send Msg ori";
    }
    value(10035583; "Orchestrator.Playbook.Enqueue")
    {
        Caption = 'Orchestrator.Playbook.Enqueue';
        Implementation = "Msg Interface ori" = "Playbook Enqueue Msg ori";
    }
    value(10035588; "Orchestrator.Telegram.Message")
    {
        Caption = 'Orchestrator.Telegram.Message';
        Implementation = "Msg Interface ori" = "Telegram Msg ori";
    }
    value(10035590; "Orchestrator.Report.List")
    {
        Caption = 'Orchestrator.Report.List';
        Implementation = "Msg Interface ori" = "Report List Msg ori";
    }
    value(10035591; "Orchestrator.Report.Get")
    {
        Caption = 'Orchestrator.Report.Get';
        Implementation = "Msg Interface ori" = "Report Get Msg ori";
    }
    value(10035592; "Orchestrator.Report.SaveAs")
    {
        Caption = 'Orchestrator.Report.SaveAs';
        Implementation = "Msg Interface ori" = "Report SaveAs Msg ori";
    }
    value(10035597; "Orchestrator.Report.Run")
    {
        Caption = 'Orchestrator.Report.Run';
        Implementation = "Msg Interface ori" = "Report Run Msg ori";
    }
    value(10035596; "Orchestrator.Workspace.Preview")
    {
        Caption = 'Orchestrator.Workspace.Preview';
        Implementation = "Msg Interface ori" = "Workspace Preview Msg ori";
    }
}
