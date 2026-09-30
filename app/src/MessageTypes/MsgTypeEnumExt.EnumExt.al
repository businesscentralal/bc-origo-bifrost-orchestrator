/// <summary>
/// Registers all Bifrost Orchestrator message types and maps each to its
/// implementing "Msg Interface ori" codeunit.
/// </summary>
namespace Origo.Bifrost.Orchestrator;

using Origo.Bifrost;
enumextension 10035536 "MsgType.EnumExt ori" extends "Message Type ori"
{
    value(10035537; "Orchestrator.Entry.Run")
    {
      Caption = 'Orchestrator.Entry.Run', Locked = true;
      Implementation = "Msg Interface ori" = "SE Run Msg ori", "Msg Discovery ori" = "SE Run Msg ori", "Msg Contract ori" = "SE Run Msg ori";
   }
    value(10035538; "Orchestrator.Entry.Restart")
    {
      Caption = 'Orchestrator.Entry.Restart', Locked = true;
      Implementation = "Msg Interface ori" = "SE Restart Msg ori", "Msg Discovery ori" = "SE Restart Msg ori", "Msg Contract ori" = "SE Restart Msg ori";
   }
    value(10035541; "Orchestrator.Status.Get")
    {
      Caption = 'Orchestrator.Status.Get', Locked = true;
      Implementation = "Msg Interface ori" = "Status Get Msg ori", "Msg Discovery ori" = "Status Get Msg ori", "Msg Contract ori" = "Status Get Msg ori";
   }
    value(10035542; "Orchestrator.Status.Restart")
    {
      Caption = 'Orchestrator.Status.Restart', Locked = true;
      Implementation = "Msg Interface ori" = "Status Restart Msg ori", "Msg Discovery ori" = "Status Restart Msg ori", "Msg Contract ori" = "Status Restart Msg ori";
   }
    value(10035543; "Orchestrator.Status.RestartIfNeeded")
    {
      Caption = 'Orchestrator.Status.RestartIfNeeded', Locked = true;
      Implementation = "Msg Interface ori" = "Status RestartIf Msg ori", "Msg Discovery ori" = "Status RestartIf Msg ori", "Msg Contract ori" = "Status RestartIf Msg ori";
   }
    value(10035544; "Orchestrator.Playbook.Run")
    {
      Caption = 'Orchestrator.Playbook.Run', Locked = true;
      Implementation = "Msg Interface ori" = "Playbook Run Msg ori", "Msg Discovery ori" = "Playbook Run Msg ori", "Msg Contract ori" = "Playbook Run Msg ori";
   }
    value(10035548; "Orchestrator.JobQueueEntry.Restart")
    {
      Caption = 'Orchestrator.JobQueueEntry.Restart', Locked = true;
      Implementation = "Msg Interface ori" = "Entry Restart Msg ori", "Msg Discovery ori" = "Entry Restart Msg ori", "Msg Contract ori" = "Entry Restart Msg ori";
   }
    value(10035549; "Orchestrator.JobQueueEntry.RestartIfNeeded")
    {
      Caption = 'Orchestrator.JobQueueEntry.RestartIfNeeded', Locked = true;
      Implementation = "Msg Interface ori" = "Entry RestartIf Msg ori", "Msg Discovery ori" = "Entry RestartIf Msg ori", "Msg Contract ori" = "Entry RestartIf Msg ori";
   }
    value(10035551; "Help.Orchestrator.Get")
    {
      Caption = 'Help.Orchestrator.Get', Locked = true;
      Implementation = "Msg Interface ori" = "Help Get Impl ori", "Msg Discovery ori" = "Help Get Impl ori", "Msg Contract ori" = "Help Get Impl ori";
   }
    value(10035552; "Orchestrator.Playbook.Schedule")
    {
      Caption = 'Orchestrator.Playbook.Schedule', Locked = true;
      Implementation = "Msg Interface ori" = "Playbook Schedule Msg ori", "Msg Discovery ori" = "Playbook Schedule Msg ori", "Msg Contract ori" = "Playbook Schedule Msg ori";
   }
    value(10035576; "Orchestrator.Entry.Register")
    {
      Caption = 'Orchestrator.Entry.Register', Locked = true;
      Implementation = "Msg Interface ori" = "SE Register Msg ori", "Msg Discovery ori" = "SE Register Msg ori", "Msg Contract ori" = "SE Register Msg ori";
   }
    value(10035578; "Orchestrator.Entry.Schedule")
    {
      Caption = 'Orchestrator.Entry.Schedule', Locked = true;
      Implementation = "Msg Interface ori" = "SE Schedule Msg ori", "Msg Discovery ori" = "SE Schedule Msg ori", "Msg Contract ori" = "SE Schedule Msg ori";
   }
    value(10035582; "Orchestrator.Email.Send")
    {
      Caption = 'Orchestrator.Email.Send', Locked = true;
      Implementation = "Msg Interface ori" = "Email Send Msg ori", "Msg Discovery ori" = "Email Send Msg ori", "Msg Contract ori" = "Email Send Msg ori";
   }
    value(10035583; "Orchestrator.Playbook.Enqueue")
    {
      Caption = 'Orchestrator.Playbook.Enqueue', Locked = true;
      Implementation = "Msg Interface ori" = "Playbook Enqueue Msg ori", "Msg Discovery ori" = "Playbook Enqueue Msg ori", "Msg Contract ori" = "Playbook Enqueue Msg ori";
   }
    value(10035588; "Orchestrator.Telegram.Message")
    {
      Caption = 'Orchestrator.Telegram.Message', Locked = true;
      Implementation = "Msg Interface ori" = "Telegram Msg ori", "Msg Discovery ori" = "Telegram Msg ori", "Msg Contract ori" = "Telegram Msg ori";
   }
    value(10035590; "Orchestrator.Report.List")
    {
      Caption = 'Orchestrator.Report.List', Locked = true;
      Implementation = "Msg Interface ori" = "Report List Msg ori", "Msg Discovery ori" = "Report List Msg ori", "Msg Contract ori" = "Report List Msg ori";
   }
    value(10035591; "Orchestrator.Report.Get")
    {
      Caption = 'Orchestrator.Report.Get', Locked = true;
      Implementation = "Msg Interface ori" = "Report Get Msg ori", "Msg Discovery ori" = "Report Get Msg ori", "Msg Contract ori" = "Report Get Msg ori";
   }
    value(10035592; "Orchestrator.Report.SaveAs")
    {
      Caption = 'Orchestrator.Report.SaveAs', Locked = true;
      Implementation = "Msg Interface ori" = "Report SaveAs Msg ori", "Msg Discovery ori" = "Report SaveAs Msg ori", "Msg Contract ori" = "Report SaveAs Msg ori";
   }
    value(10035597; "Orchestrator.Report.Run")
    {
      Caption = 'Orchestrator.Report.Run', Locked = true;
      Implementation = "Msg Interface ori" = "Report Run Msg ori", "Msg Discovery ori" = "Report Run Msg ori", "Msg Contract ori" = "Report Run Msg ori";
   }
    value(10035596; "Orchestrator.Workspace.Preview")
    {
      Caption = 'Orchestrator.Workspace.Preview', Locked = true;
      Implementation = "Msg Interface ori" = "Workspace Preview Msg ori", "Msg Discovery ori" = "Workspace Preview Msg ori", "Msg Contract ori" = "Workspace Preview Msg ori";
   }
    value(10035599; "Orchestrator.ReportLayout.Set")
    {
      Caption = 'Orchestrator.ReportLayout.Set', Locked = true;
      Implementation = "Msg Interface ori" = "Report Layout Set Msg ori", "Msg Discovery ori" = "Report Layout Set Msg ori", "Msg Contract ori" = "Report Layout Set Msg ori";
   }
}
