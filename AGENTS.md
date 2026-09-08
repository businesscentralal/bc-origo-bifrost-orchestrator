# Bifrost Orchestrator — Agent Context

This file gives AI agents the big-picture context needed to work in this repository correctly and safely.

---

## What This Extension Does

**Bifrost Orchestrator** is a Business Central AL extension that adds scheduling and orchestration on top of **Bifrost Foundation**. It does two things:

1. **Job Queue scheduling and supervision** — Job Queue entries are registered as *scheduled entries*, which the app monitors, restarts according to a retry policy, and reports on. Failures raise a notification (None, Email or Telegram).
2. **Playbooks** — a declarative, multi-step runner. Each step calls one Bifrost message type; results flow into a shared workspace that later steps read with `@path` references. Steps support forEach iteration over an array from an earlier step, conditional branching (success/failure next step, skip-if-failed, conditions), and paged execution over large result sets.

Everything the app can do is also exposed as message types on the Bifrost queue API (`origo/bifrost/v1.0`), so an external system, an automation tool or an AI agent drives a playbook exactly the way the Job Queue does.

---

## Who Uses It

- Business Central administrators and IT teams who need supervised, restartable background jobs with notification on failure.
- Integration developers who chain Bifrost message types into multi-step workflows without writing AL.
- External systems and agents that call `Orchestrator.*` message types through Bifrost Foundation.

---

## Repository Structure

```
app/              Business Central AL extension (publisher: Origo, ID range 10035535–10035634)
  src/
    JobQueue/
      Entries/          Scheduled Entry table, card and subform, retry policy enum
      Setup/            Scheduler Setup table/page, setup wizard, client credentials
      Handlers/         Scheduler Mgt/Handler/Events, schedule calculation, API client
      Notifications/    Notification interface + None/Email/Telegram implementations, User Setup extension
      RecurringTemplate/ Recurring schedule templates
      Extension/        Job Queue Entry table and page extensions
      API/              OData API pages (entries, scheduled entries, status, categories, log)
      Install/          Install and Upgrade codeunits
    Playbook/           Playbook, Step, Condition tables; Runner, Step Executor, Msg Executor,
                        Workspace, JSON helper; step/condition/status enums
    Log/                Playbook Instance and Playbook Step Log tables + log management
    Pages/              Playbook list/card, instances, step subpages, template editor, FactBoxes
    MessageTypes/       MsgType enum extension + one folder per area (Entry, ScheduledEntry,
                        Status, Playbook, Report, Telegram) + Help codeunits
  Help/             HTML help pages (en-US and is-IS) deployed to Azure Blob
  Translations/     Generated .xlf translation file
  docs/             AppSource submission material (user scenarios, Partner Center texts)
  assets/           Logo and sample playbook step templates

test/             Separate test app (ID range 96400–96499)
  src/            Installer, libraries, handlers, sample reports and tables
  test/           Test codeunits (Subtype = Test)

.AL-Go/, .github/ AL-Go for GitHub / COSMO Alpaca pipeline configuration
```

---

## Core Architectural Concepts

### Dependency on Bifrost Foundation

Bifrost Orchestrator has exactly one AL dependency: **Bifrost Foundation** (`7505e808-6e52-4b96-a328-82573391297a`). It uses Foundation for the message loop (`Message ori`, `Message Argument ori`, `Msg Interface ori`, `Dispatcher ori`), for `User Setup ori` (which Bifrost Orchestrator extends with the Telegram Chat ID) and for `Bifrost Setup`. Bifrost Orchestrator does **not** depend on Bifrost Bragi (chat, language models, MCP Tool Server).

### Message Type Registration

Every Bifrost Orchestrator message type is:
- A value in `enumextension "MsgType.EnumExt ori"` (10035536) extending Foundation's `Message Type ori`
- An impl codeunit implementing `Msg Interface ori` (`<Area> <Verb> Msg ori`), usually delegating to a shared `<Area> Msg Handler ori`
- A help codeunit whose markdown is collected by `Help ori` and served through `Help.Orchestrator.Get`

Keys keep the `Orchestrator.*` prefix — they are the published API contract and must not be renamed.

### Playbook Execution

1. `Playbook Runner ori` walks the steps of a `Playbook ori` and creates a `Playbook Instance ori`.
2. For each step, `Playbook Step Executor ori` resolves the request template against the workspace (`Playbook Workspace ori`, `Playbook JSON Helper ori`) and calls `Msg Executor ori`.
3. `Msg Executor ori` (10035603, `Access = Internal`, `SingleInstance`) wraps Foundation's `Dispatcher ori` in a `Codeunit.Run` scope so a message type that commits or fails cannot roll back or abort the playbook run. Non-text responses are base64-encoded into a JSON envelope (`contentType`, `size`, `base64`).
4. `Playbook Log Mgt ori` writes a `Playbook Step Log ori` per step with request, response and workspace snapshot.
5. Branching uses `Next Step No. (Success)` / `Next Step No. (Failure)`, `Skip If Step Failed` and `Playbook Condition ori`.

### Scheduling

`Scheduler Mgt ori` registers and maintains the Job Queue entries. `Scheduled Entry ori` mirrors a Job Queue Entry with the app's own scheduling, retry policy and notification settings; `Scheduler Handler ori` is the codeunit the Job Queue runs. Playbooks are scheduled through `Playbook JQ Dispatcher ori` with parameters in `JQ Parameter ori`.

---

## Key Design Rules

- **Never** call Foundation's `Dispatcher ori` directly from playbook code — always go through `Msg Executor ori` so the `Codeunit.Run` isolation stays intact.
- **Never** rename an existing `Orchestrator.*` message type key or remove an enum value — they are the published API contract.
- **Never** reintroduce chat, language model or MCP Tool Server references. Those objects live in Bifrost Bragi and Bifrost Orchestrator has no dependency on it.
- **Always** return errors as a `status = Error` response with a helpful message through the Foundation argument — never let an unhandled exception reach the API.
- **Always** declare `namespace Origo.Bifrost.Orchestrator;` at the top of every file, and give every object the `ori` suffix within 30 characters.
- **Always** write bilingual captions and tooltips (`Comment = 'is-IS=…'`); Icelandic prose uses "Bifröst".
- **Always** use `SetLoadFields` on record reads, and never `Format()` / `Evaluate()` on enum values.

---

## What AI Agents Should Not Do Here

- Do not add an AL dependency. The single dependency on Bifrost Foundation is deliberate; new capability that needs chat or MCP belongs in Bifrost Bragi.
- Do not put the brand word in object names — "Bifrost" lives in the namespace, the app name, the permission sets (`BIFROST … ori`) and user-facing captions.
- Do not add `Extensible = false` to any enum.
- Do not write credentials into files. The Telegram Bot Token and the client credentials go to the Bifröst Foundation secret store through codeunit `Secrets ori` (codes `TELEGRAM-BOT-TOKEN`, `CREDENTIAL-<CODE>-CLIENT-ID`, `CREDENTIAL-<CODE>-CLIENT-SECRET`, scope Company); container credentials come from the `BC28IS_USER` / `BC28IS_PASSWORD` user environment variables.
- Do not use string concatenation to build markdown in help codeunits — use `TextBuilder.AppendLine()`.
- Do not resurrect `Max Iterations` (legacy field 71 on `Playbook Step ori`) — it was dropped on purpose.

---

## Extending the System

To add a message type: add a value to `MsgType.EnumExt ori`, write the `<Area> <Verb> Msg ori` impl codeunit (delegating to the area's `Msg Handler`), write its help codeunit, register it in `Help ori`, and add tests in `test/test/`. Implementation is not complete without tests, help text and HTML help.
