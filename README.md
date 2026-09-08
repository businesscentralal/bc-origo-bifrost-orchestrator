# Bifrost Orchestrator

**App name:** Bifrost Orchestrator (display form *Bifröst stjórnandi*)  
**Publisher:** Origo — **Version:** 28.0.0.0 — **Target:** Cloud (BC 28, runtime 17.0)  
**App ID:** `7da3f512-5c19-47cd-bbe4-4c2bc713f1db` — **Test app ID:** `194ecd04-5688-4af6-94bc-732c714251fc`  
**Object ID range:** 10035535–10035634 (tests 96400–96499) — **Namespace:** `Origo.Bifrost.Orchestrator`  
**Environments:** Business Central online (SaaS) and the COSMO Alpaca development containers `bc28-is` (CRONUS IS) and `bc28-w1` (CRONUS International Ltd.)

---

## Overview

Bifrost Orchestrator is the scheduling and automation module of the Bifröst platform. It does two
things.

**It runs a scheduler.** A single management Job Queue Entry fires every five minutes and walks the
`Scheduled Entry ori` table: each row is a Job Queue Entry the orchestrator watches. Rows are
created, re-enqueued and restarted according to a retry policy, weekday/time windows or a recurring
template, and a failure can raise a notification by email or Telegram.

**It runs playbooks.** A playbook is a declarative, reusable sequence of Bifröst message types. Steps
pass data to each other through a shared JSON workspace with `@path` references, iterate over arrays
returned by an earlier step, page through large result sets, and branch on conditions. The step
executor isolates every dispatch in its own `Codeunit.Run` scope, so a message type that commits or
fails cannot take the surrounding run down with it.

Everything the app does is also a message type on Foundation's queue API route
(`origo/bifrost/v1.0`), so an external system or an AI agent drives a playbook exactly the way a
scheduled Job Queue Entry does. It is the successor of *Origo Cloud Events Orchestrator*.

---

## Functional Flow

1. **Set the app up.** An administrator opens **Bifrost Orchestrator Setup** (`Scheduler Setup ori`),
   runs the setup wizard, enables *Allow HttpClient Requests* for the extension and starts the
   management job queue. **Bifröst Setup** raises the notification while either is missing — setup
   notifications live there for the whole Bifröst family, never on an app's own setup page.
2. **Register what should be watched.** A Job Queue Entry becomes a scheduled entry either from the
   *Job Queue Entries* page (action *Add to Bifrost Orchestrator*) or through
   `Orchestrator.Entry.Register`. The row carries the schedule, the retry policy and the
   notification settings.
3. **The scheduler works the list.** `Scheduler Handler ori` runs every five minutes. For every
   non-blocked entry it either creates and enqueues the next Job Queue Entry, restarts a failed one,
   or leaves it alone because the retry policy says so. Successful runs reset the error counter.
4. **Failures are reported.** The entry's `Notif. Type ori` selects a `Notification ori`
   implementation — none, email, or Telegram — and the restart notification goes out through it.
5. **Author a playbook.** `Playbooks ori` / `Playbook Card ori` define the header, the steps
   (`Playbook Step ori`) and their conditions (`Playbook Condition ori`). Each step names one
   Bifröst message type and a JSON request template.
6. **Run it.** A playbook runs immediately (`Orchestrator.Playbook.Run`), once through the job queue
   after a delay (`Orchestrator.Playbook.Enqueue`), or on a schedule
   (`Orchestrator.Playbook.Schedule`, which creates a scheduled entry from a recurring template).
7. **Read the result.** Every run writes a `Playbook Instance ori` header and one
   `Playbook Step Log ori` row per dispatch — request, response, duration and workspace snapshot —
   readable from the **Playbook Execution Log** or as the message-type response.

---

## Benefits

- **One place to watch the job queue.** Restart policy, failure counter, weekday windows and
  notifications live on the scheduled entry instead of being spread over ad-hoc Job Queue Entries.
- **Automation without AL code.** A playbook chains existing message types with data flow,
  iteration, paging and branching, so a new routine is a data change, not a deployment.
- **A failing step cannot break the run.** `Msg Executor ori` dispatches inside `Codeunit.Run`, so a
  message type that commits or errors is isolated and the playbook decides what happens next.
- **Every run is auditable.** Instance and step logs keep the request sent, the response received
  and the workspace at that point, under retention policies registered on install.
- **Same contract for people and machines.** The 20 message types serve the BC client, the Bifröst
  MCP server and any external caller, and each one documents itself at runtime.
- **No secrets in this app.** The Telegram bot token and the OAuth client credentials live in the
  Foundation secret store; pages only show *Set* or *Not set*.
- **Bilingual and AppSource-ready.** Every caption ships in en-US and is-IS; every object carries the
  registered ` ori` affix.
- **Safe succession.** On first install per company the app takes its data over from the published
  *Origo Cloud Events Orchestrator* app.

---

## Logic Flow

**Scheduling**

```
Job Queue Entry (management, fixed id, every 5 min)
        │  runs
        ▼
"Scheduler Handler ori".OnRun
        │  ScheduleJobs — loops "Scheduled Entry ori" where not Blocked
        ▼
   for each entry ──► JobQueueEntryFound?
        │                 │
        │  no ────────────┘──► ScheduleNextJobQueueEntry
        │                        ("Schedule Calc ori" computes the next run)
        │
        └─ yes ──► ShouldSkipRestartByPolicy?  ("Retry Policy ori")
                     │  no  ──► RestartJobQueueEntryWithCounter
                     │            ├─ directly, or
                     │            └─ via "Scheduler API Client ori" (OAuth 2.0 client credentials)
                     │          ──► Interface "Notification ori"
                     │                ├─ "None Notification ori"
                     │                ├─ "Email Notification ori"  ──► "Email Send ori"
                     │                └─ "Telegram Notif. ori"     ──► "Telegram Send ori"
                     └─ yes ──► telemetry only
```

**Playbooks**

```
caller ─► Bifröst Foundation (Queue → Task → Data)
             │
             ▼
        Message Type ori  (extended by "MsgType.EnumExt ori")
             │  binds to
             ▼
        "<Area> <Verb> Msg ori" : Msg Interface ori
             │  delegates to "<Area> Msg Handler ori"
             ▼
        "Playbook Runner ori".Run(playbookCode, initialRequest)
             │  Workspace.Reset()  — seeds _sys (dates, company, user) and _who (Help.WhoAmI.Get)
             │  LogMgt.CreateInstance() ──► "Playbook Instance ori"
             ▼
        step loop, while NextStepNo > 0
             ├─ Disabled?                  ──► follow Next Step No. (Success)
             ├─ Start conditions hold?     ──► no: record Cancelled, follow the success branch
             ├─ Paged?                     ──► ExecutePagedBlock (Page Size, Page Through Step No.)
             ├─ Iterate Array Path set?    ──► ExecuteForEachStep, one dispatch per array element
             └─ otherwise                  ──► ExecuteSingleStep
                        │
                        ▼
             "Playbook Step Executor ori".Execute
                        │
                        ▼
             "Msg Executor ori"  (Access = Internal, SingleInstance)
                        │  Codeunit.Run scope; non-text responses base64 in a JSON envelope
                        ▼
             Bifröst Foundation "Dispatcher ori"
                        │
                        ▼
             "Playbook Workspace ori"  (WriteFromResponse, RecordStep, RollUpRun)
             "Playbook Log Mgt ori"    ──► "Playbook Step Log ori"
             │
             └─ Success conditions ──► Next Step No. (Success) / (Failure)
```

Supporting paths:

- **Workspace and references** — `Playbook Workspace ori` is a SingleInstance JSON document
  addressed by dot-notation paths. `Playbook JSON Helper ori` resolves `@path` references inside a
  request template, evaluates conditions and extracts arrays. `_run`, `_steps` and `_tail` hold the
  run report; `_sys` and `_who` are seeded before step 1.
- **Conditions** — `Playbook Condition ori` lines are evaluated in disjunctive normal form: all lines
  in a group must hold, and any group holding is enough. `Playbook Cond. Type ori` says whether a
  condition gates the start of a step, decides its success, or only escalates the run to failed.
- **Enqueued runs** — `Playbook ori.EnqueuePlaybook` parks the initial request in `JQ Parameter ori`
  under the new Job Queue Entry id; `Playbook JQ Dispatcher ori` picks it up when the job fires.
- **Reports** — `Report Msg Handler ori` backs the four `Orchestrator.Report.*` types;
  `Report Run Exec ori` runs a processing-only report in its own transaction scope so a report error
  is returned instead of failing the message. Presets live in `Report Request Preset ori`, which
  `Report Data Restriction ori` blocks from the generic `Data.Records.*` types.
- **Secrets** — `Secrets ori` is the only place that composes secret codes and calls Foundation's
  `Secret Store ori`. It registers its codes from `App Install ori`, `App Upgrade ori` and the setup
  page's `OnOpenPage`; registration is idempotent.
- **Help** — `Help ori` holds the Markdown contract of all 20 message types; `Help Get Impl ori`
  serves it as `Help.Orchestrator.Get` and `Overview Subscriber ori` registers the module in
  Foundation's message-type overview.
- **Lifecycle** — `App Install ori` initialises the setup record, lets subscribers register their job
  queue codeunits and registers the retention policies; `App Takeover ori` copies data over from the
  published Cloud Events Orchestrator app on first install per company.

---

## Setup & Configuration

| Step | Where | What |
| --- | --- | --- |
| 1 | Extension Management (page 2500) | Enable **Allow HttpClient Requests** for Bifrost Orchestrator. Needed by Telegram and by the OAuth restart client. **Bifröst Setup** shows an aggregated notification with a *Start setup wizard* action while it is off. |
| 2 | **Bifröst Setup** → *Apps* → **Bifrost Orchestrator** | Open `Scheduler Setup ori` (page 10035536), the single place this module is configured. |
| 3 | **Set up Bifrost Orchestrator** (assisted setup) | `Scheduler Setup Wizard ori` walks through HTTP client requests, the management job queue and the scheduling defaults. Also reachable from the *Start setup wizard* action on Bifröst Setup. |
| 4 | *Restart Job Queue* action | Creates and enqueues the management Job Queue Entry — recurring, every 5 minutes, all seven days, running codeunit `Scheduler Handler ori`. The status field on the setup page reports whether it is running. |
| 5 | *Client Credentials* action | One `Client Credentials ori` row per Entra app registration used to restart entries through the API. |
| 6 | *App Secrets* action | The Bifröst secret list, filtered to this app. |

`Scheduler Setup ori` (table 10035536) fields:

| Field | Purpose |
| --- | --- |
| `Job Queue Category Code` | Category the management Job Queue Entry is created under. |
| `Job Queue User ID` | User the management entry runs as (on-premises only). |
| `Log Job Queue Activity` | Whether the handler writes Activity Log entries. |
| `Emit Telemetry` | Whether the handler emits heartbeat telemetry on every pass. |

Secrets are held in the **Bifröst Foundation secret store**, never in this app's own
IsolatedStorage. Codeunit `Secrets ori` composes the codes; all use scope *Company*:

| Code | Value |
| --- | --- |
| `TELEGRAM-BOT-TOKEN` | The Telegram bot token. Set and cleared from the setup page. |
| `CREDENTIAL-<CODE>-CLIENT-ID` | OAuth 2.0 client id of a `Client Credentials ori` record. |
| `CREDENTIAL-<CODE>-CLIENT-SECRET` | OAuth 2.0 client secret of that record. |

`<CODE>` is the record code uppercased. A code too long for `Code[50]` is shortened to its first 16
characters plus a hash suffix, so long codes sharing a prefix stay distinct. Pages never show or
edit a secret — they show **Set** / **Not set** and offer *Set …* / *Clear …* actions.

Telegram notifications additionally need a **Telegram Chat ID** on the recipient's
`User Setup ori` record (Bifröst User Setup), added by this app's table and page extensions.

---

## Example Scenario

Finance wants the nightly *Aged Accounts Receivable* report generated every working morning at
07:00 and the result announced in the controller's Telegram chat.

1. **Author the playbook** `AR-NIGHTLY` on `Playbooks ori`, three steps:

   | Step | Message type | Request template | Notes |
   | --- | --- | --- | --- |
   | 10 | `Orchestrator.Report.List` | `{ "processingOnly": false }` | Finds the report id once during authoring; disabled afterwards. |
   | 20 | `Orchestrator.Report.SaveAs` | `{ "reportId": 120, "format": "PDF" }` | *Result Log Paths* keeps `size` and `fileName` in the workspace. |
   | 30 | `Orchestrator.Telegram.Message` | `{ "message": "AR report ready for @_sys.workDate — @20.fileName (@20.size bytes)" }` | `@` references resolve out of the workspace before dispatch. |

   Step 20's *Next Step No. (Failure)* points at a fourth step that sends a different Telegram text,
   so a failed generation is reported rather than silently skipped.

2. **Schedule it** with `Orchestrator.Playbook.Schedule`:

   ```json
   { "type": "Orchestrator.Playbook.Schedule",
     "data": { "playbookCode": "AR-NIGHTLY", "recurringTemplateCode": "WORKDAYS-0700",
               "notificationType": "Telegram", "retryPolicy": "ThreeTimes" } }
   ```

   The response returns the new `orchestratorEntryId`. `Scheduler Handler ori` picks the row up on
   its next pass and creates the Job Queue Entry from the recurring template — no manual job queue
   work.

3. **Every workday at 07:00** the job fires. `Playbook Runner ori` resets the workspace, seeds
   `_sys` and `_who`, creates a `Playbook Instance ori`, and walks steps 20 and 30. Step 20's
   response is written into the workspace under key `20`; step 30 reads it back through the `@`
   references.

4. **The controller gets the Telegram message.** `Telegram Send ori` posts it with the bot token
   substituted into a secret request URI, so the token never reaches telemetry or an error text.

5. **If something goes wrong** — report id gone, HTTP client requests switched off, Telegram
   unreachable — the failing step is recorded as `Failed` on the instance with the error text and
   the response body, the playbook follows the failure branch, and after three consecutive failures
   the *ThreeTimes* retry policy stops re-enqueuing the entry instead of retrying forever. Nothing
   escapes to the API as an exception: message types answer with `status = Error` and a message.

---

## Objects

112 objects, all inside range 10035535–10035634. Highest id in use: 10035607. Free ids:
10035557–10035558, 10035563–10035565, 10035569, 10035573, 10035575, 10035577–10035578, 10035580 and
10035608–10035634. Every object carries the mandatory ` ori` affix.

### Tables

| ID | Name | Purpose |
| --- | --- | --- |
| 10035535 | `Scheduled Entry ori` | Stores the orchestrator configuration for each monitored Job Queue Entry. |
| 10035536 | `Scheduler Setup ori` | Singleton setup table for the Job Queue Orchestrator configuration. |
| 10035537 | `Recurring Template ori` | Reusable recurring schedule templates for scheduled entries. |
| 10035538 | `Client Credentials ori` | Names the OAuth 2.0 client credential pairs used by scheduled entries; the values live in the Foundation secret store. |
| 10035539 | `Playbook ori` | Playbook definition header — a named, reusable sequence of message-type calls. |
| 10035540 | `Playbook Step ori` | A single step within a playbook: one message type, its request template, iteration and branching. |
| 10035542 | `Playbook Instance ori` | Runtime execution log for one playbook run. |
| 10035543 | `Playbook Step Log ori` | Per-step, per-iteration execution detail within a playbook instance. |
| 10035544 | `JQ Parameter ori` | Parks the initial request of an enqueued playbook under its Job Queue Entry id until the job fires. |
| 10035590 | `Report Request Preset ori` | Saved report request page XML per report and user (`Access = Internal`). |
| 10035599 | `Playbook Condition ori` | One condition line for a playbook step, evaluated in disjunctive normal form. |

### Table extensions

| ID | Name | Extends | Purpose |
| --- | --- | --- | --- |
| 10035535 | `JobQueueEntry.TableExt ori` | Job Queue Entry | Adds the Bifrost Orchestrator scheduling flag to the Job Queue Entry table. |
| 10035584 | `User Setup Ext ori` | `User Setup ori` (Foundation) | Adds the Telegram Chat ID field used to address Telegram notifications. |

### Pages

| ID | Name | Purpose |
| --- | --- | --- |
| 10035535 | `Sched. Entry Subform ori` | List part page displaying scheduled entries as a subform. |
| 10035536 | `Scheduler Setup ori` | The module's own setup page — the only place it is configured. |
| 10035537 | `Scheduled Entry API ori` | API page exposing scheduled entries for external integrations. |
| 10035538 | `Entries API ori` | API page exposing Job Queue Entries with an action to add entries to the orchestrator. |
| 10035539 | `Scheduler Status ori` | API page exposing the orchestrator status and restart actions. |
| 10035540 | `Log Entry ori` | API page exposing Job Queue Log Entries for external integrations. |
| 10035541 | `Categories ori` | API page exposing Job Queue Categories for external integrations. |
| 10035542 | `Recurring Templates ori` | List page for browsing and selecting recurring templates. |
| 10035543 | `Recurring Template ori` | Card page for viewing and editing a recurring template. |
| 10035544 | `Scheduled Entry Card ori` | Card page for a single scheduled entry. |
| 10035545 | `Credentials Card ori` | Card page for one Client Credentials record; the id and secret are only reported as set or not set. |
| 10035546 | `Credentials List ori` | List page for Client Credentials records, with a Secrets status column. |
| 10035548 | `Playbook Card ori` | Card page for a playbook: header fields, steps and schedule. |
| 10035549 | `Playbook Instance Card ori` | Card page for a single playbook execution instance, with step log detail. |
| 10035550 | `Playbook Instances ori` | List page for playbook execution instances (the execution log). |
| 10035551 | `Playbooks ori` | List page for playbook definitions. |
| 10035552 | `Playbook Step Logs Sub. ori` | Subpage showing step-level execution log within an instance. |
| 10035553 | `Playbook Steps Subpage ori` | Subpage for inline editing of playbook step definitions. |
| 10035554 | `Playbook Step Template FB ori` | Factbox for editing the JSON request template of the selected step. |
| 10035555 | `Playbook Step Log Dtl. FB ori` | Factbox showing the request sent and response received for the selected step log entry. |
| 10035556 | `Playbook Template Editor ori` | Full-page editor for a step's JSON request template, hosting the Bifröst text editor control add-in. |
| 10035583 | `Playbook Last Run FB ori` | Factbox showing status and figures of the playbook's last execution. |
| 10035584 | `Schedule Playbook ori` | Request page wizard for scheduling a playbook as a scheduled entry. |
| 10035589 | `Scheduler Setup Wizard ori` | Assisted setup: HTTP client requests, management job queue, scheduling defaults. |
| 10035591 | `Report Preset Card ori` | Card for a saved report request page preset. |
| 10035602 | `Playbook Cond. Subpage ori` | Conditions for every step in a playbook, in one grid. |

### Page extensions

| ID | Name | Extends | Purpose |
| --- | --- | --- | --- |
| 10035535 | `JobQueueEntryCard.PageExt ori` | Job Queue Entry Card | Adds the orchestrator scheduling actions to the Job Queue Entry Card. |
| 10035536 | `JobQueueEntries.PageExt ori` | Job Queue Entries | Adds the orchestrator scheduling actions to the Job Queue Entries list. |
| 10035537 | `Setup JQ ori` | `Setup ori` (Foundation) | Adds exactly one *Apps* action pointing at `Scheduler Setup ori`. |
| 10035584 | `User Setup Ext ori` | `User Setup Editor ori` (Foundation) | Shows the Telegram Chat ID field on the Bifröst User Setup editor. |

### Enums

| ID | Name | Purpose |
| --- | --- | --- |
| 10035535 | `Notif. Type ori` | Notification type — `None`, `EMail`, `Telegram`; implements `Notification ori`. |
| 10035536 | `Retry Policy ori` | Whether and how many times a failed Job Queue Entry is automatically restarted. |
| 10035538 | `Playbook Cond. Operator ori` | Operators used when evaluating a condition against a JSON value. |
| 10035539 | `Playbook Inst. Status ori` | Status of a playbook execution instance. |
| 10035600 | `Playbook Cond. Type ori` | What a playbook condition governs — `Start`, `Success` or `Error`. |
| 10035601 | `Playbook Step Type ori` | Whether a false Success condition means the step failed (`Action`) or is simply the answer to a question (`Check`). |

### Enum extensions

| ID | Name | Extends | Purpose |
| --- | --- | --- | --- |
| 10035535 | `EmailScenario.EnumExt ori` | Email Scenario | Adds the orchestrator email scenario. |
| 10035536 | `MsgType.EnumExt ori` | `Message Type ori` (Foundation) | The 20 message types this app publishes. Captions are `Locked = true` — they are the public wire contract. |
| 10035605 | `RequestLogType.EnumExt ori` | `Request Log Type ori` (Foundation) | Adds the playbook request-log type so playbook steps are classified separately from the Foundation log types. |

### Interface

| Name | Purpose |
| --- | --- |
| `Notification ori` | Abstraction over one notification channel: heartbeat, restart and execution-completed notifications. |

### Codeunits

| ID | Name | Purpose |
| --- | --- | --- |
| 10035535 | `Scheduler Handler ori` | Main handler: processes and reschedules the scheduled entries on every management job queue pass. |
| 10035536 | `Scheduler Mgt ori` | Management: schedules and cancels the management Job Queue Entry, reports status, runs an entry once. |
| 10035537 | `App Install ori` | Fresh install: data take-over, setup record, job queue registration, retention policies. |
| 10035538 | `App Upgrade ori` | Data upgrades for the extension. |
| 10035539 | `Scheduler Events ori` | Event subscribers for Job Queue Entry lifecycle events. |
| 10035540 | `None Notification ori` | No-op `Notification ori` implementation used when notifications are disabled. |
| 10035541 | `Email Notification ori` | Email `Notification ori` implementation. |
| 10035542 | `Scheduler Manual Evt ori` | Manual event subscribers for Job Queue Entry deletion prompts. |
| 10035543 | `Email Send ori` | Sends an email item using the orchestrator email scenario. |
| 10035544 | `Schedule Calc ori` | Calculates the next run date/time from a date formula or from weekday and minute settings. |
| 10035545 | `Scheduler API Client ori` | HTTP client that calls the orchestrator API as an Entra application using the OAuth 2.0 client credentials flow. |
| 10035546 | `Playbook JSON Helper ori` | Stateless JSON utilities: `@path` reference resolution, condition evaluation, array extraction, dot-notation paths. |
| 10035547 | `Playbook Runner ori` | Reads a playbook, executes steps in sequence, handles iteration, paging, branching and logging. |
| 10035548 | `Playbook JQ Dispatcher ori` | Job Queue entry point for playbook execution. |
| 10035549 | `Playbook Log Mgt ori` | CRUD helpers for playbook instance and step log records. |
| 10035550 | `SE Msg Handler ori` | Shared handler behind the `Orchestrator.Entry.*` message types. |
| 10035551 | `Status Msg Handler ori` | Shared handler behind the `Orchestrator.Status.*` message types. |
| 10035552 | `Playbook Msg Handler ori` | Shared handler behind the `Orchestrator.Playbook.*` message types. |
| 10035555 | `SE Run Msg ori` | `Orchestrator.Entry.Run` |
| 10035556 | `SE Restart Msg ori` | `Orchestrator.Entry.Restart` |
| 10035559 | `Status Get Msg ori` | `Orchestrator.Status.Get` |
| 10035560 | `Status Restart Msg ori` | `Orchestrator.Status.Restart` |
| 10035561 | `Status RestartIf Msg ori` | `Orchestrator.Status.RestartIfNeeded` |
| 10035562 | `Playbook Run Msg ori` | `Orchestrator.Playbook.Run` |
| 10035566 | `Entry Msg Handler ori` | Shared handler behind the `Orchestrator.JobQueueEntry.*` message types. |
| 10035567 | `Entry Restart Msg ori` | `Orchestrator.JobQueueEntry.Restart` |
| 10035568 | `Entry RestartIf Msg ori` | `Orchestrator.JobQueueEntry.RestartIfNeeded` |
| 10035570 | `Help Get Impl ori` | `Help.Orchestrator.Get` — the module directory. |
| 10035571 | `Overview Subscriber ori` | Registers the module in Foundation's message-type overview. |
| 10035572 | `Playbook Step Executor ori` | Executes one step through `Msg Executor ori` and writes its step log entry. |
| 10035574 | `Playbook Schedule Msg ori` | `Orchestrator.Playbook.Schedule` |
| 10035576 | `Help ori` | Central help provider — the Markdown contract of all 20 message types. |
| 10035579 | `SE Register Msg ori` | `Orchestrator.Entry.Register` |
| 10035581 | `SE Schedule Msg ori` | `Orchestrator.Entry.Schedule` |
| 10035582 | `Email Send Msg ori` | `Orchestrator.Email.Send` |
| 10035583 | `Playbook Workspace ori` | SingleInstance JSON workspace steps read from and write to, addressed by dot-notation paths. |
| 10035584 | `Playbook Enqueue Msg ori` | `Orchestrator.Playbook.Enqueue` |
| 10035585 | `WhoAmI Subscriber ori` | Adds the caller's Telegram chat id to the `Help.WhoAmI.Get` response so playbooks can address it as `@_who.telegramChatId`. |
| 10035586 | `Telegram Send ori` | Posts one HTML message to the Telegram sendMessage endpoint; the bot token goes in as a secret request URI. |
| 10035587 | `Telegram Notif. ori` | Telegram `Notification ori` implementation. |
| 10035588 | `Telegram Msg ori` | `Orchestrator.Telegram.Message` |
| 10035589 | `Scheduler Wizard Reg. ori` | Registers the setup wizard as an assisted setup. |
| 10035590 | `Report Data Restriction ori` | Blocks `Report Request Preset ori` from the generic `Data.Records.*` message types. |
| 10035592 | `Report Msg Handler ori` | Shared handler behind the `Orchestrator.Report.*` message types. |
| 10035593 | `Report List Msg ori` | `Orchestrator.Report.List` |
| 10035594 | `Report Get Msg ori` | `Orchestrator.Report.Get` |
| 10035595 | `Report SaveAs Msg ori` | `Orchestrator.Report.SaveAs` |
| 10035596 | `Workspace Preview Msg ori` | `Orchestrator.Workspace.Preview` |
| 10035597 | `Report Run Msg ori` | `Orchestrator.Report.Run` |
| 10035598 | `Report Run Exec ori` | Runs a processing-only report in its own transaction scope so the caller can catch the error. |
| 10035603 | `Msg Executor ori` | The only path from playbook code to Foundation's `Dispatcher ori`; wraps every dispatch in a `Codeunit.Run` scope. |
| 10035604 | `App Takeover ori` | One-time data take-over from the published *Origo Cloud Events Orchestrator* app. |
| 10035606 | `Secrets ori` | Single access point for every secret this app keeps in the Foundation secret store. |
| 10035607 | `Orchestrator Registration ori` | Registers the app in Foundation's `App Registry ori` so Bifröst Setup can name it in the aggregated setup notifications. |

### Permission sets

| ID | Name | Purpose |
| --- | --- | --- |
| 10035535 | `BIFROST Orchestr ori` | Full set: every table, page and codeunit the app owns. |
| 10035536 | `BIFROST OrchSet ori` | Setup role: scheduler setup, client credentials, recurring templates and the setup wizard. |
| 10035537 | `BIFROST OrchMgt ori` | Operations role: monitor, run and restart scheduled entries; read-only on setup and credentials. |
| 10035538 | `BIFROST PlaybAdm ori` | Playbook administration: every playbook page, full CRUD on playbook data, and execute on every codeunit that runs or dispatches a playbook. |
| 10035539 | `BIFROST PlaybVw ori` | Playbook viewer: the same playbook pages except the run-only Schedule wizard, read-only on playbook data, no execute on any playbook codeunit. |

---

## Dependencies

| App | ID | Purpose |
| --- | --- | --- |
| Bifrost Foundation | `7505e808-6e52-4b96-a328-82573391297a` | Origo 28.0.0.0 — the message-type kernel (`Message Type ori`, `Msg Interface ori`, `Message Argument ori`, `Dispatcher ori`, `Secret Store ori`, `User Setup ori`, the Queue → Task → Data API route). |

This is the only AL dependency. Bifrost Orchestrator does **not** depend on Bifrost Bragi (chat,
language models, MCP Tool Server).

The test app additionally depends on Bifrost Orchestrator itself and on Microsoft's
Tests-TestLibraries, Library Assert, Test Runner, Any and Library Variable Storage.

At runtime the base application's own Job Queue permissions are needed for scheduling, and outgoing
HTTP calls must be allowed for the Telegram and OAuth paths.

---

## Permissions

Five assignable permission sets ship with the app. **Each one has to be combined with a Bifröst
Foundation permission set** (`BIFROST Full ori` or `BIFROST Read ori`): the message loop, the request
log, `User Setup ori` and the secret store live in Foundation, and job queue scheduling additionally
needs the base application's own Job Queue permissions.

| Permission set | Role | Grants |
| --- | --- | --- |
| `BIFROST Orchestr ori` | Full | Every table, page and codeunit the app owns |
| `BIFROST OrchSet ori` | Setup | Scheduler setup, client credentials, recurring templates and the setup wizard |
| `BIFROST OrchMgt ori` | Operations | Monitor, run and restart scheduled entries; read-only on setup and credentials |
| `BIFROST PlaybAdm ori` | Playbook admin | All playbook pages (list, card, instances, subpages, FactBoxes, template editor, the Schedule wizard); full CRUD on playbook, step, condition, instance, step log and `JQ Parameter ori`/`Report Request Preset ori`; execute on `Playbook Runner ori`, `Playbook Step Executor ori`, `Msg Executor ori`, `Playbook JQ Dispatcher ori` and `Playbook Log Mgt ori` |
| `BIFROST PlaybVw ori` | Playbook viewer | The same playbook pages as PlaybAdm **except** the Schedule wizard (a run-only entry point); read-only on the same tables; **no codeunit execute permission at all** — viewing works entirely through the table Read grants, so nothing that runs or writes a playbook is reachable through this role |

The permission-set object names have a hard 20-character ceiling because `Role ID` is `Code[20]` —
that is why the setup role is `BIFROST OrchSet ori` and not `BIFROST OrchSetup ori`.

### Playbook admin vs. viewer — design notes

`BIFROST PlaybAdm ori` and `BIFROST PlaybVw ori` originally granted only `tabledata` and were not
usable roles — every playbook page and codeunit was unreachable through either set. Both now carry
the full page/codeunit grants described above; see the XML doc comments on the two permission set
objects (`app/src/BIFROSTPlaybAdm.PermissionSet.al`, `app/src/BIFROSTPlaybVw.PermissionSet.al`) for
the complete reasoning, including:

- Why `Schedule Playbook ori` is the only playbook page withheld from the viewer role (it is a
  run-only wizard with no "view" use, and Business Central checks page permission whenever a page
  is opened, so withholding it concretely blocks scheduling for a viewer).
- Why the viewer role gets **no** codeunit grant, not even `Playbook Log Mgt ori` — that codeunit
  only exposes write procedures and elevates its own permission to `RIMD` on the instance/step log
  tables, so granting it would let a "view" role write log data through the codeunit's own
  elevated permission.
- A documented, **not yet fixed** residual risk: the "Run Now" action on `Playbook Card ori` calls
  `Playbook Runner ori` through a plain procedure call rather than `Codeunit.Run`/`PAGE.Run`, so
  Business Central's codeunit execute-permission gate — which only fires on those two call shapes —
  does not stop a viewer who has page access to `Playbook Card ori` from triggering it in practice,
  even without codeunit execute permission on `Playbook Runner ori`. A real UI-level fix (hiding or
  disabling Run Now / Schedule for non-admins, or an explicit permission check inside the action)
  is out of scope for this fix.
- **No automated test** exists in this repository for "a PlaybVw-only user cannot run or schedule a
  playbook." Verify manually until such a test is added.

---

## Known issues

- **`Orchestrator.Entry.Register`** fails when it is called over the message-type API for a Job Queue
  Entry that is not yet a scheduled entry. `Scheduled Entry ori.InsertFromJobQueueEntry` opens a card
  page unconditionally for new entries, and Business Central's Data Services layer rejects that as a
  client callback. The defect is pre-existing — the identical code is in the predecessor app — and is
  **not** fixed in this release. Workaround: register the entry from the *Job Queue Entries* page
  (action *Add to Bifrost Orchestrator*), then use `Orchestrator.Entry.Schedule` /
  `Orchestrator.Entry.Run` over the API. Full analysis and the suggested fix are in
  `test/reports/Bifrost_Orchestrator_MessageType_TestReport_2026-09-05.md`.

---

## Repository layout

| Folder | Content |
| --- | --- |
| `app/` | The AppSource app (`Bifrost Orchestrator`) |
| `app/src/JobQueue/` | Scheduled entries, scheduler setup and wizard, recurring templates, notifications, secrets, Job Queue extension objects, API pages |
| `app/src/Playbook/` | Playbook, step and condition tables, runner, step executor, workspace, message executor and JSON helper |
| `app/src/Log/` | Playbook instance and step log tables, log management |
| `app/src/Pages/` | Playbook, instance and template editor pages |
| `app/src/MessageTypes/` | Message type enum extension, implementations, shared handlers and the help codeunit |
| `app/src/Install/` | `App Takeover ori` — data take-over from the published legacy app |
| `app/assets/playbooks/` | Sample playbook step templates |
| `test/` | Test app (`Bifrost Orchestrator - Tests`, range 96400–96499) |
| `test/reports/` | End-to-end message-type test reports (internal, not published) |
| `.AL-Go/`, `.github/` | AL-Go for GitHub / COSMO Alpaca pipeline configuration |

---

## Development

- Open `al.code-workspace` in VS Code.
- Development containers: COSMO Alpaca `bc28-is` (CRONUS IS) and `bc28-w1` (CRONUS International
  Ltd.), both defined in `app/.vscode/launch.json` — git-ignored and the authority for the instance
  ids. Publish and run the unit tests on **both**; select the target with
  `-LaunchConfiguration 'launch: bc28-w1'`.
- Compile locally with `alc.exe` plus CodeCop, UICop and AppSourceCop. Symbols live in
  `app/.alpackages`; test symbols in `test/.alpackages`, including the Bifrost Foundation `.app`.
  Zero errors and zero warnings is the bar.

  ```
  alc.exe /project:app /packagecachepath:app/.alpackages /out:app/output/orchestrator.app ^
          /analyzer:<CodeCop.dll> /analyzer:<UICop.dll> /analyzer:<AppSourceCop.dll>
  ```

- Publish and run tests without VS Code (pwsh 7, credential from the user-level env vars
  `BC28IS_USER` / `BC28IS_PASSWORD`, never from files):
  `bc-origo-bifrost-core/tools/Publish-BifrostApp.ps1 -AppFile <.app>` and
  `bc-origo-bifrost-core/tools/Run-BifrostTests.ps1`.
- `AppSourceCop.json` sets the mandatory affix to `ori` and the supported countries. Command-line
  `alc` does not raise AS0011 (mandatory affix); AL-Go CI is the gate, so check the ` ori` suffix
  yourself before pushing.
- `app.json` suppresses **AS0081** only — the advisory that `internalsVisibleTo` exposes internal
  objects, which is required so the test app can reach them. No other warning is suppressed.
- Standards: [Origo BC Development Standards](https://github.com/OrigoSoftwareSolutions/bc-dev-standards).
  Project rules are in `.claude/CLAUDE.md`; agent context is in [AGENTS.md](AGENTS.md).
- Every object carries the mandatory ` ori` suffix; the brand name is carried by the namespace, the
  app name and the captions, never by an object-name prefix.

---

## Documentation

All public documentation lives in the [businesscentralal/bifrost](https://github.com/businesscentralal/bifrost)
site repository and is published at <https://businesscentralal.github.io/bifrost>. There are no
`docs/` or `Help/` folders in this repository — an approved deviation from Origo PR gateway check 8.

| What | Where |
| --- | --- |
| Product documentation (overview, message types, AppSource listing) | <https://businesscentralal.github.io/bifrost/en-us/nornir/> |
| In-product help (context-sensitive help pages, en-US and is-IS) | <https://businesscentralal.github.io/bifrost/en-us/help/nornir/> |
| Building on Bifröst (extensibility guide) | <https://businesscentralal.github.io/bifrost/en-us/extensibility/> |
| Release notes | [CHANGELOG.md](CHANGELOG.md) |

The `nornir` path segment is the current site slug, not the app name. Do not change the slugs before
the folders in the site repository are renamed — the published help pages would 404.

Message-type contracts are also served by the app itself at runtime: `Help.Orchestrator.Get` returns
the module directory, and every message type answers its own Markdown help through
`get_message_type_help` / `Help.Implementation.Get`.

### Context-Sensitive Help

`app.json` declares `contextSensitiveHelpUrl` =
`https://businesscentralal.github.io/bifrost/{0}/help/nornir/` and `supportedLocales`
`["en-US", "is-IS"]`, so every help page must exist in both locales on the site.

| Slug | Page that uses it |
| --- | --- |
| `nornir-setup` | `Scheduler Setup ori` |
| `scheduler-setup-wizard` | `Scheduler Setup Wizard ori` |
| `scheduled-entry-card` | `Scheduled Entry Card ori` |
| `job-queue-entries` | `JobQueueEntries.PageExt ori` |
| `job-queue-entry-card` | `JobQueueEntryCard.PageExt ori` |
| `recurring-templates` | `Recurring Templates ori` |
| `recurring-template` | `Recurring Template ori` |
| `credentials-list` | `Credentials List ori` |
| `credentials-card` | `Credentials Card ori` |
| `playbooks` | `Playbooks ori` |
| `playbook-card` | `Playbook Card ori` |
| `playbook-instances` | `Playbook Instances ori` |
| `playbook-instance-card` | `Playbook Instance Card ori` |
| `schedule-playbook` | `Schedule Playbook ori` |
| `report-preset-card` | `Report Preset Card ori` |

---

© 2026 Origo ehf.

<!-- AUTO-UPDATE-START -->
# COSMO Alpaca AL-Go AppSource App Template

[![Use this template](https://github.com/microsoft/AL-Go/assets/10775043/ca1ecc85-2fd3-4ab5-a866-bd2e7e80259d)](https://github.com/new?template_name=Alpaca-AppSource-Template&template_owner=cosmoconsult)

This template repository can be used for managing AppSource Apps for Business Central.

It is a customized version of the [AL-Go-AppSource](https://github.com/microsoft/AL-Go-AppSource) template and is designed to be used with [COSMO Alpaca](https://cosmoconsult.com/cosmo-alpaca).

> [!NOTE]
> If you created this repository using the GitHub web UI (for example by clicking **Use this template** on GitHub.com) instead of creating it from the COSMO Alpaca VS Code extension, you must initialize it using the [COSMO Alpaca VS Code extension](https://marketplace.visualstudio.com/items?itemName=cosmoconsult.cosmo-alpaca). To do this, simply right-click on the repository in VS Code and select _Initialize_.

Please go to https://aka.ms/AL-Go and [COSMO Docs](https://docs.cosmoconsult.com/en-us/cloud-service/alpaca) to learn more.
<!-- AUTO-UPDATE-END -->
