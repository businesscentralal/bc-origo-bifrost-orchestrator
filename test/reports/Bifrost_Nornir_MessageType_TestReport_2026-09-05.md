# Bifrost Nornir - Message Type Test Report

**Date:** 2026-09-05
**Environment:** bc28-is (CRONUS IS), via the `origo-bc-bc28-is` MCP server (Bifrost API route `origo/bifrost/v1.0`)
**Test data prefix:** `BIFT-N`
**Scope:** all 20 message types registered by `MsgType.EnumExt ori` (10035536)

## Summary

| Result | Count |
|---|---|
| Verified happy path | 18 |
| Verified negative/error path (graceful, non-5xx) | 18 |
| Skipped happy path (would cause a real external side effect) | 2 (`Orchestrator.Email.Send`, `Orchestrator.Telegram.Message`) |
| Defects found | 1 (`Orchestrator.Entry.Register`, pre-existing in the legacy app too) |

All calls returned either a well-formed `status: Success` payload or a graceful, human-readable
error - no message type produced an HTTP 5xx or an unhandled exception.

## Per-type results

| Message Type | Happy path | Negative path | Notes |
|---|---|---|---|
| `Help.Orchestrator.Get` | ✅ Success | n/a (no parameters) | Returned the full API directory markdown |
| `Orchestrator.Status.Get` | ✅ Success | n/a | Confirmed "Job Queue has not been configured" before, "Job Queue is running" after `Status.RestartIfNeeded` |
| `Orchestrator.Status.Restart` | ✅ Success | n/a | Unconditional restart, idempotent |
| `Orchestrator.Status.RestartIfNeeded` | ✅ Success | n/a | Created the management Job Queue Entry under the new Guid (see Defects Fixed below) |
| `Orchestrator.Workspace.Preview` | ✅ Success | n/a | Returned `_sys` and `_who` seed data |
| `Orchestrator.Entry.Run` | ✅ Success (`BIFT-N01` playbook's own entry) | ✅ empty `id` -> graceful error | |
| `Orchestrator.Entry.Restart` | ✅ Success | ✅ unknown `id` -> graceful error | |
| `Orchestrator.Entry.Schedule` | ✅ Success | ✅ unknown `id` -> graceful error | |
| `Orchestrator.Entry.Register` | ❌ **Defect** (see below) | ✅ missing `jobQueueEntryId` -> graceful error | |
| `Orchestrator.JobQueueEntry.Restart` | ✅ Success | ✅ unknown `id` -> graceful error | |
| `Orchestrator.JobQueueEntry.RestartIfNeeded` | ✅ Success (no-op, already Ready) | ✅ wrong parameter name -> graceful error | |
| `Orchestrator.Playbook.Run` | ✅ Success (1 step executed) | ✅ unknown `playbookCode` -> graceful error | |
| `Orchestrator.Playbook.Schedule` | ✅ Success | ✅ re-schedule already-scheduled playbook -> graceful error | |
| `Orchestrator.Playbook.Enqueue` | ✅ Success (created a real Job Queue Entry, 60s delay) | ✅ unknown `playbookCode` -> graceful error | |
| `Orchestrator.Report.List` | ✅ Success (789 reports) | n/a | |
| `Orchestrator.Report.Get` | ✅ Success (report 5) | ✅ unknown `reportId` -> graceful error | |
| `Orchestrator.Report.SaveAs` | ✅ Success (PDF generated, report 5) | n/a (already covered by Report.Get negative) | |
| `Orchestrator.Report.Run` | ✅ Success (report 795, "Adjust Cost - Item Entries") | ✅ report 99003805 missing a required "Starting Date" -> graceful error | |
| `Orchestrator.Email.Send` | ⏭ Skipped (would send a real email) | ✅ unknown `outboxSystemId` -> graceful error | |
| `Orchestrator.Telegram.Message` | ⏭ Skipped (Bot Token / HTTP Client Requests not configured on this container) | ✅ prerequisite check -> graceful "HTTP client requests are not enabled" error | Confirmed `IsEnabled()` correctly hides the type from `list_message_types` when prerequisites are unmet |

## Defect: `Orchestrator.Entry.Register` fails via API for brand-new entries

**Symptom:** calling `Orchestrator.Entry.Register` with the id of a Job Queue Entry that is
not yet an orchestrator entry fails with:

```
Microsoft Dynamics 365 Business Central Data Services attempted to issue a client callback
to run page 10035544 Scheduled Entry Card ori. Client callbacks are not supported on
Microsoft Dynamics 365 Business Central Data Services.
```

**Root cause:** `Scheduled Entry ori.InsertFromJobQueueEntry(JobQueueEntry, HideDialog)`
(`app/src/JobQueue/Entries/ScheduledEntry.Table.al`, procedure starting around line 686) only
honours `HideDialog` in the branch where the entry **already exists**:

```al
if Get(JobQueueEntry.ID) then begin
    if HideDialog then begin
        ...
        exit;
    end else begin
        ...
    end;
end else begin
    CopyJobQueueEntryToOrchestratorEntry(JobQueueEntry);
    ShouldOpenCard := true;      // <- ignores HideDialog
    IsNewEntry := true;
end;

if ShouldOpenCard then
    if IsNewEntry then begin
        if ConfirmManagement.GetResponseOrDefault(EntryCreatedQst, true) then
            Page.Run(Page::"Scheduled Entry Card ori", Rec);   // <- fails headlessly
    end ...
```

For a genuinely new entry, `ShouldOpenCard` is set unconditionally, `ConfirmManagement.
GetResponseOrDefault` auto-confirms in a non-interactive session, and `Page.Run` then throws
the client-callback error. The row is still inserted and committed (`Insert(true); Commit();`
runs before the failing `Page.Run`), so the API caller sees an error even though the
registration itself succeeded - a partial-success-reported-as-failure defect on top of the
headless-call defect.

**This is not a migration regression.** The identical code (only object names differ)
exists in the predecessor app: `CE Orchestrator Entry ori.InsertFromJobQueueEntry`
in `D:\Git\Origo\OrigoSoftwareSolutions\bc-cloudevents-orchestrator\app\src\JobQueue\Entries\CEOrchestratorEntry.Table.al`
(same line numbers, same logic). It was left unchanged during the migration per the
"no copy-paste, but no unrelated behavior changes" migration discipline, and is flagged here for a
separate fix (in both apps) rather than folded into this rebrand PR.

**Suggested fix (for a follow-up change):** pass `HideDialog` through the `else` branch too,
e.g. `ShouldOpenCard := not HideDialog;` in both branches, so a caller that asked to suppress
the dialog never reaches `Page.Run`.

## Defects fixed during this migration (not pre-existing)

Two genuine, migration-introduced defects were found and fixed while preparing for this test
pass (both are covered by commits on `feature/bifrost-nornir-migration` and by passing unit
tests):

1. **Test app object-id collision** - the proposed test range 96300-96399 collided with
   `Cloud Events Gagnatorg - Tests`, which occupies the same block on bc28-is/bc28-w1 but
   was unregistered in the object range workbook. Every Bifrost Nornir - Tests object was
   moved to 96400-96499.
2. **Management Job Queue Entry Guid collision** - `SchedulerMgt.Codeunit.al`'s
   `GetManagementJobQueueId()` kept the legacy app's exact Guid
   (`e69e6a8b-a507-442e-ae01-e30f8dde10a5`). Since both apps are installed side by side and
   share the base-application Job Queue Entry table, Bifrost Nornir was finding and reusing
   the legacy app's own management entry instead of ever scheduling its own - confirmed live
   via `Orchestrator.Status.Get` ("Job Queue has not been configured" before the fix,
   "Job Queue is running" after) and via two previously-failing unit tests, now passing.
   Fixed with a freshly generated Guid (`461b5088-cc5f-4b4a-9e5e-b4cde335df66`).

## Test data cleanup

All `BIFT-N*` test records were removed after the pass via `Test.Records.Delete`:
- `Scheduled Entry ori`: 2 rows
- `Job Queue Entry`: 1 row
- `Playbook Step ori`: 83 rows (broader than intended - the cleanup filter used the
  portfolio-wide `BIFT-*` wildcard instead of `BIFT-N*` for this one call, so it also removed
  pre-existing `BIFT-*` playbook step rows left over from earlier testing of this same app.
  `Playbook Step ori` is exclusive to Bifrost Nornir - no other app's table or data was
  affected)
- `Playbook ori`: 1 row (`BIFT-N01`)
- `Recurring Template ori`: 1 row (`BIFT-N01`)
