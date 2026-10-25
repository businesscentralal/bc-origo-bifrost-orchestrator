# Changelog

All notable changes to Bifrost Orchestrator are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this app uses
Business Central release versioning (`major.minor.build.revision`).

## [Unreleased]

### Added (2026-10-25) - Playbooks on Bifrost Setup Navigate, and Tell Me for the playbook list

- Page extension `Setup JQ ori` (10035537) on Foundation's `Setup ori` keeps the *Bifrost Orchestrator Setup* action in Apps and adds two Navigate actions: *Bifrost Playbooks* (`Playbooks ori`) and *Playbook Execution Log* (`Playbook Instances ori`). The same two actions remain on `Scheduler Setup ori`.
- Page `Playbooks ori` (10035551) sets `UsageCategory = Lists` so Tell Me can open the list. Caption stays *Bifrost Playbooks* and `ApplicationArea` stays `All`.
- Icelandic captions for the two new Bifrost Setup actions are in `app/Translations/Bifrost Orchestrator.is-IS.xlf`, generated with `tools/Update-IcelandicXlf.ps1`.

### Fixed (2026-10-23) - Orchestrator direction and effect declarations (#117)

- Workspace.Preview is offered in both directions; Report.Get declares the preset it may insert as a write (core#1147 C). Codeunits 10035596 `Workspace Preview Msg ori` and 10035594 `Report Get Msg ori`; runtime behavior and the effect changes text are unchanged.
- Workspace.Preview's direction note now says Both in English and Icelandic, matching its metadata (Gunnar's 2026-10-24 exception to contract item 3); the remaining help text is unchanged.
- Test codeunits 96453 `Orch B2 Contract Tests`, 96441 `Contract Complete Tests ori` and 96455 `Msg Direction Tests ori` assert Both for Workspace.Preview and write for Report.Get, following Gunnar's H2 approvals of the existing assertions.

- Reuse the compile-only test hygiene from PR #116: locked format labels and variable ordering in codeunits 96430, 96432, 96433, 96434, 96435, 96437 and 96439; align filenames for 96434 `Playbook Test Library ori`, 96438 `Playbook Example Library ori` and 96440 `Role Lookup Subscriber ori`. Assertions and fixture values are unchanged.

### Changed (2026-10-21) - Message type contract and discovery brought to Foundation parity

No public object, procedure, enum value or message type key changed; only the text and chapters that Help.Implementation.Get and the roster return.

- **Envelope** (codeunit 10035609 `Orch B1 Contract Parts ori`, codeunit 10035610 `Orch B2 Contract Parts ori`): every type now declares the root option `strict` (a translatable description, is-IS added), as Foundation does. The types that never read `subject` (Orchestrator.Status.Get, .Restart, .RestartIfNeeded, Orchestrator.Workspace.Preview, Orchestrator.Telegram.Message, Help.Orchestrator.Get, Orchestrator.Report.List, .Get, .Run, .SaveAs, Orchestrator.ReportLayout.Set, .List, .Get) now say `subject: notUsed` instead of `optional` with a made-up form; the Report types no longer claim the report ID is a subject. Orchestrator.Report.SaveAs states `application/pdf` as its content type, as its response chapter already did. `Orch B2 Contract Parts ori` builds the envelope through `Orch B1 Contract Parts ori` (internal `Envelope` removed there, `NoSubjectEnvelope` added in both).
- **Discovery**: `Orchestrator.ReportLayout.Get` (10035613 `Report Layout Get Msg ori`) and `Orchestrator.ReportLayout.List` (10035612 `Report Layout List Msg ori`) had no selection description of their own and answered their description; each now has a distinct selection label with an is-IS target. `Orchestrator.Entry.Schedule` (10035581 `SE Schedule Msg ori`) no longer says it reschedules "for immediate execution" (it rebuilds the Job Queue schedule from the recurrence settings; description and selection label rewritten, is-IS updated). Typo "a orchestrator entry" fixed in 10035555 `SE Run Msg ori`.
- **Workflow chapters** added where a real sequence exists: 10035555 `SE Run Msg ori`, 10035579 `SE Register Msg ori`, 10035581 `SE Schedule Msg ori`, 10035559 `Status Get Msg ori`, 10035560 `Status Restart Msg ori`, 10035561 `Status RestartIf Msg ori`, 10035584 `Playbook Enqueue Msg ori`, 10035574 `Playbook Schedule Msg ori`, 10035615 `Playbook Verify Msg ori`, 10035596 `Workspace Preview Msg ori`, 10035593 `Report List Msg ori`, 10035597 `Report Run Msg ori`, 10035613, 10035612 and 10035599 (the ReportLayout types); 10035562 `Playbook Run Msg ori` replaces its one-step workflow by Verify then Run.
- **Examples**: 10035613 and 10035612 had none; each now has a request and answer pair taken from the handler (10035611 `Report Layout Read Handler ori`). The Orchestrator.Entry.Schedule example now shows `blocked`, which the answer always carries.
- **Effect**: `idempotent` was wrong on three types. Orchestrator.Playbook.Enqueue (10035584) queues one more run on every call, so it is `false`; Orchestrator.ReportLayout.Get and .List (10035613, 10035612) only read, so they are `true` and their `changes` text says what they read. ReportLayout.List now describes the fields of each layout (`children` of `layouts`).
- **Overview, notes and descriptions**: every overview now says what the type does and when to use it (at least 100 characters). Orchestrator.Playbook.Enqueue says that it does not verify the playbook; Orchestrator.Report.Run notes list the built-in template of report 1316 that its `parameters` text refers to. The sibling lists of `related` for the ReportLayout types now name each other and Orchestrator.ReportLayout.Set.
- **No AL object names in help text**: the parameter, response, effect, overview and notes text no longer names `Scheduled Entry ori`, `Playbook Instance ori`, `Playbook Step Log ori`, `JQ Parameter ori`, `Recurring Template ori`, `Report Preset Card ori`, `Playbook JQ Dispatcher`, `Job Queue - Enqueue` or the runner codeunit; it uses the captions (Job Queue Orchestrator Entry, Bifrost Playbook Instance, Bifrost Playbook Step Log, Job Queue Recurring Template). The errors chapters keep the table names a caller types as `tableName` in Data.Records.Get, and their text is pinned by the `KeepsMainErrors` tests.
- **Translations**: `app/Translations/Bifrost Orchestrator.is-IS.xlf` has an Icelandic unit for the `strict` description, the two new selection labels and the rewritten Entry.Schedule labels, generated with `tools/Update-IcelandicXlf.ps1`.
- **Tests** (test app): new codeunit 96441 `Contract Complete Tests ori` walks every `Orchestrator.*` type and `Help.Orchestrator.Get` and fails when a type lacks a required chapter, declares subject use that the code does not match, has no `strict`, has an error without a Bifrost Error Code (or text), when or fix, has an effect that disagrees with its direction (documented exceptions: Orchestrator.Report.Get, Orchestrator.Workspace.Preview), has an example that is not a JSON request of its own type, names an AL object outside the errors chapter, or has a description, selection description or keywords that are missing, shared with the description or without an is-IS translation.

## [28.0.1.0] - 2026-10-21

### Changed (2026-10-21) - Tests: Verify, Schedule and Run after an uncommitted write, and the role lookup inside a write transaction (#109 follow-up)

- Test codeunit 96437 `Playbook Gate Tests`: the test `VerifyScheduleAndRun_AfterAnUncommittedWrite_StillVerify` makes a real uncommitted write before each of `Orchestrator.Playbook.Verify`, `Orchestrator.Playbook.Schedule` and `Orchestrator.Playbook.Run`, asserts that the write transaction is open, that Verify did not commit, that the findings are intact and that the Schedule gate passed. For Run it proves the gate by a refusal (an error step is added): the runner itself needs a committed transaction, because it seeds the workspace through `Codeunit.Run` before its first commit, so Run is not started inside a write transaction. It replaces `VerifyRunAndSchedule_InsideAWriteTransaction_DoNotError`, which committed before Run.
- Test codeunit 96439 `Playbook Verify Template Tests`: `RoleCode_InsideAWriteTransaction_IsNotDeterminable` asserts that the lookup answers "not determinable" with `Exists` false, that nothing commits, that the role check for an `LLM.*` type name stays silent, and that a role code longer than a code is still judged without a read.
- Limit: the test app has no `LLM.*` message type, so no step can hold one; the role check is exercised with an `LLM.*` type name through `CheckRoleCode` of codeunit 10035618 `Playbook Verify Template ori`, and the entry points with a playbook without an `LLM.*` step. No app object changed.

### Added (2026-10-20) - Safe playbook authoring: workflow, worked examples, Verify checks before run and schedule (#109)

Stacked on #110: it extends `Orchestrator.Playbook.Verify` (added there), it does not add a second message type.

- **Verify and the role lookup**: the language model role lookup of codeunit 10035619 `Playbook Verify Lookup ori` is skipped (answers "not determinable", the check stays silent) inside a transaction that has already written, because Business Central refuses `Codeunit.Run` with a used return value there. The descriptions of 10035615 `Playbook Verify Msg ori` say "Read-only for playbook data; a language model role check leaves a Foundation message log row" (is-IS updated). The refusal answer of 10035616 `Playbook Verify ori` also records the error on the argument (`AddError`), as `RespondWithError` does. Tests: 96439 `Playbook Verify Template Tests` and 96437 `Playbook Gate Tests` run Verify, Schedule and Run inside a write transaction without a subscriber.
- **Orchestrator.Playbook.Verify returns findings, not only warnings** (codeunit 10035616 `Playbook Verify ori`, changed; codeunit 10035615 `Playbook Verify Msg ori`, changed: contract, response, examples, notes). Each finding has `severity` (`error` or `warning`), `stepNo` (0 for the playbook as a whole), `code`, `message` and `nextStep`, in the language of the session (en-US, is-IS); the answer adds `valid`, `errorCount` and `warningCount` and replaces the `warnings` array of #110 with `findings` (`UnsafeForEachWrite` keeps `checkStepNo`). Every step is checked, enabled or not, so a playbook built with all steps disabled can be verified; a finding about a disabled step carries `stepDisabled: true` and never blocks.
- **New checks**, in three new codeunits (all `Access = Internal`, in permission set 10035535 `BIFROST Orchestr ori`):
  - 10035617 `Playbook Verify Step ori`: `MessageTypeUnavailable` (error: unknown or not enabled message type), `CheckWithoutSuccessCondition` (error), `ActionWithoutSuccessCondition` (warning), `NextStepNotFound` (error), `IterateSourceInvalid` (error), `InvalidSkipGate` (error: the gate step is missing, comes later or does not iterate, so every item would be skipped), `ForEachSourceUnguarded` (warning: a record reader that feeds a forEach has no Success condition on `noOfRecords`), and the existing `UnsafeForEachWrite` (warning).
  - 10035618 `Playbook Verify Template ori`: `TemplateNotJson` (error: the engine would send an empty request `{}`), `StepReferenceNotFound` and `StepReferenceNotEarlier` (errors: `@N...`, `@collect:N`, `@10,20`), `LanguageModelRoleNotFound` (error: the `roleCode` of an `LLM.*` step), `UnknownFieldReference` (warning: `@_current.fields.X` against the table the forEach source reads, `@N.field` and `@N.@_iter.field` against the Result Log Paths of step N).
  - 10035619 `Playbook Verify Lookup ori`: reads whether a record exists with `Data.Records.Get` through `Msg Executor ori` (it leaves a Foundation message row, like any step) (no dependency on Bifrost Bragi for the language model roles: table `Bifrost Language Model ori`), reads the field names of a table from the table metadata, and publishes the integration event `OnBeforeCheckLanguageModelRole`. A lookup that cannot be answered (table not readable, Bragi not installed) is "not determinable" and the check stays silent.
  - `ScheduledWithErrors` (error, in 10035616): the playbook is scheduled and an enabled step has an error.
- **Run and schedule refuse a playbook that does not verify.** `Orchestrator.Playbook.Run` (codeunit 10035562 `Playbook Run Msg ori`, via 10035552 `Playbook Msg Handler ori`), `Orchestrator.Playbook.Schedule` (10035574 `Playbook Schedule Msg ori`, via 10035552) and `Playbook ori.CreateOrchestratorEntry` (table 10035539 `Playbook ori`; new overload with `IgnoreWarnings`; the old signature keeps its behaviour for callers except that it now refuses on an error finding, and accepts warnings) verify first. They answer `PreconditionFailed` on `playbookCode`, name the blocking findings in the text and in `findings[]`, and write nothing, when an enabled step has an error, or a warning unless the request sets `ignoreWarnings` to `true`. `ignoreWarnings` never waives an error. The Schedule dialog (page 10035584 `Schedule Playbook ori`) refuses on an error and asks to confirm on a warning. A run started by the Job Queue, and `Orchestrator.Playbook.Enqueue`, are not gated. New parameter `ignoreWarnings` and a `PreconditionFailed` entry in the errors chapter of both contracts.
- **Help.Orchestrator.Get** (codeunit 10035576 `Help ori`): new chapter "Building a playbook safely" (seven numbered steps: design, check that message types and role codes exist with `describe_message_type` and `Data.Records.Get` on `Bifrost Language Model ori`, build with every step disabled, Verify, run read and decision steps only, enable writes one at a time on one test record, then schedule) and the table of finding codes, both right after the Quick Decision Tree; new chapter "Worked Playbook Examples": 1 per-record decision then per-record write (`CREDIT-CTRL`, every line explained), 2 a read-only report (`OVERDUE-REPORT`), 3 the labelled anti-pattern; Rules for AI Agents 1-4 (build disabled, verify before every run and schedule, never write in a forEach without a per-record gate, check that role codes and message types exist; the former rules 18 and 19 are folded into them and the others renumbered); the `roleCode` guidance of the LLM chapter says the code must exist. The help stays English by design.
- **Translations**: `app/Translations/Bifrost Orchestrator.is-IS.xlf` has an Icelandic unit for every new label (the findings and their next steps, the refusal, the Schedule dialog question, the Verify descriptions).
- **Tests** (test app): new codeunits 96435 `Playbook Verify Step Tests`, 96439 `Playbook Verify Template Tests`, 96436 `Playbook Example Tests` (examples 1 and 2 verify with no findings and example 3 with exactly the `UnsafeForEachWrite` warning, in 1033 and 1039; the help carries the base64 of every template), 96437 `Playbook Gate Tests` (Run and Schedule refuse an error and a warning, `ignoreWarnings`, disabled steps, scheduled playbook with errors; in 1033 and 1039), helpers 96438 `Playbook Example Library ori` and 96440 `Role Lookup Subscriber ori`. Changed: 96433 `Playbook Verify Tests` (findings shape), 96434 `Playbook Test Library ori` (condition, edge, Result Log Paths and disabled helpers), 96432 `Playbook Last Run Tests` (its bare playbook runs with `ignoreWarnings`), 96452 `Orch B1 Contract Tests` (errors chapter of Run and Schedule end with the new entry, Schedule has 8 parameters).

### Changed (2026-10-20) - AppSource delivery

- `.AL-Go/settings.json`: `deliverToAppSource` names the Partner Center offer (productId beb3672f-c5f7-44ed-83e7-6f1193560143, main app folder `app`, branch main, no continuous delivery), so the Publish To AppSource workflow can deliver updates.
### Changed (2026-10-19) - AppSource metadata on docs.bifrost.origo.is

- `app.json` `privacyStatement` and `EULA` point at `https://docs.bifrost.origo.is/en-us/licensing/privacy/` and `.../licensing/eula/`, the same pages as Bifrost Foundation and Bifrost Language Models, instead of the old `businesscentralal.github.io/bifrost` addresses.

### Fixed (2026-10-20) - Technical errors in a Check step are failures, not the answer "no" (#106)

- A `Check` step whose message type raises an error, or answers `status` `Error` (also `Refused`, `Failed`, or any other non-`Success` status that carries an `error` text), is now `Failed`. It never reaches its Success conditions, increments `StepsFailed` and fails the run exactly as an `Action` does. Before, the Success condition was evaluated against the error answer, the step was logged `Cancelled` with an empty `ErrorText`, and the run completed with `StepsFailed = 0` (codeunit 10035547 `Playbook Runner ori`, single and forEach paths; new `IsErrorResponse` in codeunit 10035546 `Playbook JSON Helper ori`).
- The step log `ErrorText` and `_steps.<no>.failures[].error` carry the type's `code` and `error` (`<code>: <error>`, still cut to 500 characters in `_steps`).
- A genuine answer of no keeps its meaning (`Cancelled` for a forEach iteration, `Completed` for a single step, run not failed) and is now told apart in the log: `ErrorText` reads "Check answered no." (is-IS "Athugun svaraði nei.").
- `_steps.<no>.items.errored` counts failed Check iterations separately (new `Errored` outcome in codeunit 10035583 `Playbook Workspace ori`); they are also counted in `failed`. `checkFailed` now means only "answered no".
- `Help.Orchestrator.Get` (codeunit 10035576 `Help ori`; Step Type, Execution Semantics, `_steps` example) states the distinction and the `errored` count.
- `Check Step Error Tests` (96430): classifier, `errored` counting, and single and forEach Check steps for error answer, raised error, answer no and answer yes, each in 1033 and 1039, plus an Action that still fails. Helper `Playbook Test Library ori` (96434).

### Fixed (2026-10-20) - Playbook header last-run fields are updated by every run (#107)

- Codeunit 10035547 `Playbook Runner ori` now writes `Last Run Instance ID`, `Last Run Status` and `Last Run At` on `Playbook ori` when a run starts (`Running`) and when it ends (`Completed` or `Failed`). Run Now, `Orchestrator.Playbook.Run`, `Orchestrator.Playbook.Enqueue` and scheduled runs all go through the runner, so all leave the same trace. A run abandoned mid-flight stays `Running` and never leaves the previous `Completed` behind.
- Codeunit 10035548 `Playbook JQ Dispatcher ori` no longer stamps the header itself (it only did so for a run that came back, and only as Completed or Failed).
- `Help.Orchestrator.Get` (codeunit 10035576 `Help ori`) lists `LastRunInstanceID`, `LastRunStatus` and `LastRunAt` in the Playbook ori table and in Execution Semantics, and says when they are written.
- `Playbook Last Run Tests` (96432): Run, Enqueue followed by the Job Queue run, a scheduled run, a failed run, in 1033 and 1039 with the localized `LastRunStatus` caption; a second run, an empty playbook, and the header read mid-run through `Data.Records.Get` (Running).

### Added (2026-10-20) - Orchestrator.Playbook.Verify and per-item forEach guidance (#108)

- New read-only message type `Orchestrator.Playbook.Verify` (codeunits `Playbook Verify Msg ori` 10035615 and `Playbook Verify ori` 10035616, enum value 10035614 in enumextension 10035536 `MsgType.EnumExt ori`; permission set 10035535 `BIFROST Orchestr ori`). It returns localized (en-US and is-IS) warnings. Warning `UnsafeForEachWrite`: an enabled forEach step with a write-type message type (last name segment Set, Post, Delete, Create, Update, Send and similar) iterates the same array as an earlier enabled forEach `Check` step and has `Skip If Step Failed = 0`.
- Not implemented, and why (stated in the type's notes): an operator that is not an AL name cannot be stored (`Operator` is an enum and `Data.Records.Set` refuses a caption that is not an AL name), and a `roleCode` that does not exist cannot be checked because the language model roles belong to Bifrost Bragi, which this app does not depend on.
- `Help.Orchestrator.Get` (codeunit 10035576 `Help ori`) has a section "Per-item decisions in a forEach" (Next Step edges apply once per step, not per item; `Skip If Step Failed = <check step>` is the per-item gate; worked example with the exact field values), Rules for AI Agents 18 (every forEach write step after a forEach Check over the same array must set `Skip If Step Failed` to that Check) and 19 (verify before run), and an Execution Semantics line.
- `Playbook Verify Tests` (96433): warning and its absence for the corrected pattern in 1033 and 1039, two write steps, safe shapes (read, single write, other array, disabled check), write-verb detection, missing and unknown playbook. Contract, effect and direction entries for the new type in test codeunits 96452 `Orch B1 Contract Tests` and 96455 `Msg Direction Tests ori`.

### Changed (2026-10-19) - Help published and guarded (#69)

- The Orchestrator documentation and context-sensitive help are published on https://docs.bifrost.origo.is/ (businesscentralal/bifrost#107). `app.json` `help` now points at `https://docs.bifrost.origo.is/en-us/orchestrator/`.
- The unchanged `tools/Test-HelpLinks.ps1` runs as the `HelpLinks` job in `SourceGuards.yaml` against the documentation site's main branch: every page must link to a help page that exists in en-US and is-IS.

## [28.0.0.0] - 2026-10-19

### Fixed (2026-10-19) - Embedded @path references (#101)

- `Playbook JSON Helper ori` (embedded references) no longer reads a sentence-ending period as part of the path, so `"... date @_sys.today."` resolves instead of staying literal.
- An embedded value is now escaped as JSON string content. A value with a quote, backslash or line break (typical of a language-model reply), or an embedded object such as `@_run`, made the request invalid JSON and stopped the whole run with "The data does not represent a valid JSON token."
- `Resolver Test` (96402): `EmbeddedRefBeforePeriodResolves`, `EmbeddedRefEscapesQuotesAndObjects`.

### Added (2026-10-19) - Bounded report parameters and layout selection (#5)

- Add `Orchestrator.ReportLayout.List` and `.Get` through `Report Layout Read Handler ori` (10035611), message codeunits 10035612/10035613, the message enum/help and permissions. Discovery includes extension and user layouts; export preserves the selected layout bytes.
- `Report Msg Handler ori` (10035592) and Run/SaveAs contracts (10035597/10035595) accept a scalar `parameters` overlay through `Report Parameters ori` (10035614). Caller XML takes precedence over event-registered templates; unknown names, ambiguous aliases, non-scalar values and wrong-report XML fail explicitly. Explicit overlays never read or update saved user settings. Calls without `parameters` retain existing raw XML / preset behavior.
- Supply the BC 28.5 report 1316 template and stable aliases for dates, aging, date choice, balance selection and statement style. `PrintEntriesNotDue` has no platform control and is rejected rather than mapped to different behavior.
- SaveAs accepts temporary `layoutName`/`appId` through the public session-selection API and restores the prior platform/custom selection after rendering success or failure. Persistent `SetDefault` and `setAsDefault` are out of scope; no selection-table writes.
- Native tests 96409/96431 use owned report 96455, imported layout fixtures, observable report parameters and an event template. Cover byte round trips, XML escaping, unknown/malformed input, explicit-input precedence, preset preservation, actual rendering and selection restoration. New error labels have is-IS translations.
- `Orchestrator.ReportLayout.Set` replaces an existing user layout the way the Report Layouts page does (delete and insert under the same key) instead of modifying it, which the platform refused with "The type and content of an existing report layout cannot be modified." A second identical Set now answers `Replaced` (`Report Layout Handler ori`, 10035600; test `SetTwiceReplacesUserLayout` in 96409).

### Changed (2026-10-19) - Context-sensitive help metadata (#69)

- Add unique context-sensitive help slugs to pages 10035535, 10035537–10035541, 10035552–10035556, 10035583 and 10035602. Point the app help URL template at `https://docs.bifrost.origo.is/{0}/help/orchestrator/`. Page behavior, message contracts and translations are unchanged.
- Bilingual help drafts and later publication remain separate acceptance steps in #69; the unchanged HelpLinks guard will be enabled through Architect-owned wiring after documentation publication at AppSource preparation.

### Fixed (2026-10-19) - Workspace.Preview declared a read effect although it commits (#80)

- `Orchestrator.Workspace.Preview` (codeunit `Workspace Preview Msg ori`, 10035596) now declares effect `irreversible`. Seeding `_who` runs `Help.WhoAmI.Get` through `Playbook Step Executor ori` and `Msg Executor ori`, a boolean `Codeunit.Run` whose dispatch commits its queue entry, so Preview cannot run inside an open write transaction or roll back with one. The effect `changes` text, the notes and the selection description (en-US and is-IS) say so. The answer is unchanged and the roster direction stays Outbound, because no business data changes.
- `Orch B2 Contract Tests` (96453) asserts the irreversible effect, the disclosed nested dispatch and the Outbound direction.

### Fixed (2026-10-17) - Executing message types registered as Outbound (#90)

- Message types whose contract effect is write or irreversible now return `GetMessageDirection` Inbound, matching Foundation's roster rule that Outbound is a read and Inbound is a write. MCP clients no longer treat these types as read-only. Pure reads stay Outbound. `Orchestrator.Report.Get` stays Both because it reads and inserts an empty preset. `Orchestrator.Report.SaveAs` stays Outbound because its effect is read.
- Objects: `Codeunit Entry Restart Msg ori` (10035567), `Codeunit Entry RestartIf Msg ori` (10035568), `Codeunit Playbook Enqueue Msg ori` (10035584), `Codeunit Playbook Run Msg ori` (10035562), `Codeunit Playbook Schedule Msg ori` (10035574), `Codeunit Report Run Msg ori` (10035597), `Codeunit SE Register Msg ori` (10035579), `Codeunit SE Restart Msg ori` (10035556), `Codeunit SE Run Msg ori` (10035555), `Codeunit SE Schedule Msg ori` (10035581), `Codeunit Status Restart Msg ori` (10035560), `Codeunit Status RestartIf Msg ori` (10035561).
- `Msg Direction Tests ori` (96455) checks the registered direction of every Orchestrator message type through `Msg Interface ori`.

### Added (2026-10-16) - Report export filter regressions (#85)

- Extend `Report Boundary Tests ori` (codeunit 96454) to reject invalid filter fields for PDF, the default PDF format, Excel and Word alongside XML. Assert JSON error content, `InvalidFilterField`, `tableView`, nonempty recovery guidance, help hints and no report execution, so a validation failure cannot pass as empty binary success.

### Fixed (2026-10-16) - Force-tier refusal regression tests (#88)

- `Data Records Hint Tests` (96428) now expects Foundation's force-openable setup-table refusal for Job Queue Entry (472), while preserving exact permission guidance and the separately discoverable Orchestrator companion hints. Job Queue Entry, Scheduled Task, Report Request Preset and unrelated Customer scenarios run in both en-US (1033) and is-IS (1039). Product behavior and write restrictions are unchanged.

### Security (2026-10-14) - Generic data API field restrictions (#62, core#344)

- `Sched Field Restrict ori` (10035557) blocks generic writes, including forced writes, to Scheduled Entry (10035535) fields 110 Notification Recipient and 140 Job Queue User ID, and Scheduler Setup (10035536) field 40 Job Queue User ID. Reads, neighbouring fields, dedicated scheduling and page edits are unchanged. Field hints name the appropriate BC page and, for recipients, `Orchestrator.Playbook.Schedule`, the dedicated type that sets that value.
- `Sched Field Restrict Tests ori` (96405) checks the public restriction and hint paths, including readable fields, writable neighbours and unchanged table companion hints. `Help ori` (10035576) documents all three restrictions. Existing entry registration and playbook scheduling tests remain enabled; app versions and permission sets are unchanged.

### Changed (2026-10-14) - Contract source guard remediation (#68, #71)

- Declare choice parameter keys literally in `Playbook Schedule Msg ori` (10035574), `Report SaveAs Msg ori` (10035595) and `Report Layout Set Msg ori` (10035599), using entry-taking `WithChoices` helpers in `Orch B1 Contract Parts ori` (10035609) and `Orch B2 Contract Parts ori` (10035610). Preserve all parameter fields and positions.
- Rename the contract-only `AddError` helper to `AddContractError` in both Parts codeunits and its 26 call sites across 11 files. Contract error codes, text and ordering remain unchanged; runtime answers and translations are unchanged.
- Name the paged step's outgoing payload `PageRequestJson` in `Playbook Runner ori` (10035547), keeping `skip`/`take` out of the caller contract. `Orch B1 Contract Tests` (96452), `Orch B2 Contract Tests` (96453) and `Playbook Run Msg Tests` (96421) cover the four choice entries, all 21 error chapters and real outgoing paging-key injection. Guard scripts and CI wiring are unchanged.

### Fixed (2026-10-13) - Headless registration and WhoAmI contract (#10, #63)

- `Scheduled Entry ori` (10035535) honors `HideDialog` for newly registered Job Queue entries. `Entry Registration Tests ori` (96407) checks fresh and repeated headless registration and preserves the interactive confirmation/card flow.
- `WhoAmI Subscriber ori` (10035585) documents the installed `telegramChatId` response field, its caller-specific setup source, empty value and playbook reference. `WhoAmI Contract Tests ori` (96408) checks the real contract builder and retained Foundation chapters.

### Changed (2026-10-13) - PR #67 acceptance reconciliation (#64, #65, #70)

- Pin Foundation to the successful main build `28.0.4.554` in both manifests. `Msg Executor ori` (10035603) exposes its internal binary-envelope builder for the #64 regression tests in `Orchestrator Unit Tests` (96411), covering the Office MIME type and the 100-character boundary without changing the envelope format.
- Keep the documented `User Setup ori` read grant on `Telegram Msg ori` (10035588), following Gunnar's final #65 ruling. `Orchestr Secret Tests` (96403) covers indirect Foundation read through that grant, direct read, denied access, missing token and empty chat ID without sending messages.
- Retain current-main pipeline changes and the strict Force-tier assertions while resolving test/documentation conflicts. Keep the precise XML summaries on `Report Msg Tests` (96416).
- Preserve the job queue log existence assertion in `SE Run Msg Tests` (96427) without loading an unused record. Align the source filenames of `Report Boundary Tests ori` (96454) and report `Test Output Report ori` (96454) with their existing object names so test CodeCop validation is warning-free.
- `Report Msg Handler ori` (10035592) validates both report paths with Foundation `ApplyTableView` and stops on its structured errors before executing a report. Error responses never include call stacks, including debug mode; `Report Run Msg ori` (10035597) documents that response. `Report Boundary Tests ori` (96454), report `Test Output Report ori` (96454) and `Report Run Tests` (96417) cover filter boundaries and error responses.
- Replace repeated/filler Icelandic keywords in `Report Run Msg ori` (10035597) and `Status Get Msg ori` (10035559); restore the four corrupted error/tooltip translations.
- Align the enumerated inherited Icelandic source comments with their existing translations and regenerate XLF; restore the checkmark in `Telegram Notif. ori` (10035587). Objects: `Codeunit Email Notification ori` (10035541), `Codeunit Entry Msg Handler ori` (10035566), `Codeunit Entry Restart Msg ori` (10035567), `Codeunit Entry RestartIf Msg ori` (10035568), `Codeunit Help Get Impl ori` (10035570), `Codeunit Playbook Enqueue Msg ori` (10035584), `Codeunit Playbook Run Msg ori` (10035562), `Codeunit Playbook Schedule Msg ori` (10035574), `Codeunit Report Get Msg ori` (10035594), `Codeunit Report List Msg ori` (10035593), `Codeunit Report Run Msg ori` (10035597), `Codeunit Report SaveAs Msg ori` (10035595), `Codeunit SE Msg Handler ori` (10035550), `Codeunit SE Register Msg ori` (10035579), `Codeunit SE Restart Msg ori` (10035556), `Codeunit SE Run Msg ori` (10035555), `Codeunit SE Schedule Msg ori` (10035581), `Codeunit Scheduler Mgt ori` (10035536), `Codeunit Scheduler Wizard Reg. ori` (10035589), `Codeunit Status Get Msg ori` (10035559), `Codeunit Status Restart Msg ori` (10035560), `Codeunit Status RestartIf Msg ori` (10035561), `Codeunit Telegram Msg ori` (10035588), `Codeunit Telegram Notif. ori` (10035587), `Codeunit Workspace Preview Msg ori` (10035596), `Enum Retry Policy ori` (10035536), `Page Entries API ori` (10035538), `Page Playbook Card ori` (10035548), `Page Playbook Instance Card ori` (10035549), `Page Playbook Instances ori` (10035550), `Page Playbook Last Run FB ori` (10035583), `Page Playbook Step Logs Sub. ori` (10035552), `Page Recurring Template ori` (10035543), `Page Sched. Entry Subform ori` (10035535), `Page Schedule Playbook ori` (10035584), `Page Scheduled Entry API ori` (10035537), `Page Scheduled Entry Card ori` (10035544), `Page Scheduler Setup Wizard ori` (10035589), `Page Scheduler Setup ori` (10035536), `Table JQ Parameter ori` (10035544), `Table Playbook Step Log ori` (10035543), `Table Playbook ori` (10035539), `Table Recurring Template ori` (10035537), `Table Report Request Preset ori` (10035590), `Table Scheduled Entry ori` (10035535), `TableExtension User Setup Ext ori` (10035584).
- Correct the permission fixture in `Orchestr Secret Tests` (96403) to use the existing Foundation Full role for direct User Setup read, and validate the real debug notification alongside known HTTP/EULA setup notices in `Report Boundary Tests ori` (96454); retain permission-state and response assertions.
- Update `Data Records Hint Tests` (96428) and `Report Msg Tests` (96416) to explicitly request ordinary, non-forced write restrictions in the four existing assertions.
- Align `Data Records Hint Tests` (96428) with Foundation's Job Queue Entry Force-tier refusal: assert the unchanged base error and exact permission, protected-field and change-log guidance while preserving ordinary-write denial and direct companion hints.
- `Test-ContractParameterKeys.ps1` accepts pinned Foundation source for the reached `Message Argument ori` ApplyTableView reader, proving actual JSON reads with dependency regression fixtures; pre-existing contract mismatches remain visible.
- Remove the PR-added subscribers from `Scheduler Events ori` (10035539). The separately owned #62 is not implemented by this PR.
- Remove duplicate `Extensible = false` declarations from the existing `Scheduler Status ori` (10035539), `Entries API ori` (10035538) and `Scheduled Entry API ori` (10035537) pages, retaining one declaration in each.
- `.github/workflows/PullRequestHandler.yaml` runs `IcelandicXlfInSync` against the compiled Default Apps artifact and requires it in `StatusCheck` (#70). `.github/workflows/SourceGuards.yaml` runs the passing source guards, pins checkout to a commit, and links the remaining ContractParameterKeys (#68), MixedLanguageLabels (#71) and external HelpLinks (#69) debt. Architect landed the workflow wiring; full-suite and guard evidence is recorded at the exact candidate in the PR.

### Changed (2026-10-12) - Guard the Bifrost pipeline across AL-Go and Alpaca updates

- `.github/workflows/BifrostPipeline.yaml` runs `tools/Test-BifrostPipeline.ps1` and the isolated `tools/Test-SharedAlpacaContainer.ps1` checks to preserve sequential Default/Test builds, filtered container creation, physical container identity, Test production-app republishing, Default internals stripping, signing requests where applicable, deferred cleanup, merged settings before secrets, and Test-only upgrade skipping. Pull request builds remain unsigned.
- `.AL-Go/settings.json` adds `.github/workflows/**` and `tools/Test-BifrostPipeline.ps1` to `fullBuildPatterns`; `tools/Test-SharedAlpacaContainer.ps1` rejects settings that omit either entry, so workflow and guard changes select a full build.
- `AGENTS.md` requires agents to run both guards before opening pipeline PRs, preserve these Bifrost custom blocks during compatible AL-Go and Alpaca updates, and keep repository app IDs, action versions, dependencies and deployment variables.

### Changed (2026-10-11) - CI compiles against BC 28.5

- Current CI/CD and pull request builds compile against sandbox artifact `/sandbox/28.5.54151.55751/w1/latest` (BC 28.5.54151.55751, w1). `.AL-Go/settings.json` sets `artifact`. AL-Go reads that value as storage/type/version/country/select, so the string has one leading slash. A second slash puts `w1` in `select`, and container creation rejects it.
- The Test Current workflow settings (`.github/Test Current.settings.json`) use the same artifact. That file overrides the project setting, so leaving it at `////latest` would build Test Current against whatever sandbox is newest. `.github/Test Current.settings.json` is also a `fullBuildPatterns` entry, so a pull request that only changes it still builds.
- `.github/AL-Go-Settings.json` does not set `artifact`, so it is unchanged. Next Minor and Next Major keep `////nextminor` and `////nextmajor`.
- `app.json` and `test/app.json` already set runtime `17.0` and application and platform `28.0.0.0`. The app version stays `28.0.0.0`. No AL objects change.

### Fixed (2026-10-10) - UAT dependency installation

- UAT feature-app deployment uses the Foundation app already deployed by its own pipeline in Dev scope, avoiding an unauthorized AppSource Foundation installation. `.github/AL-Go-Settings.json`: `DeployToBifrost.DependencyInstallMode = "ignore"`. AppSource delivery is unchanged; no AL objects or IDs change.

### Fixed (2026-10-07) - Foundation Force argument compatibility

- `Data Records Hint Tests` (96428) and `Report Msg Tests` (96416) pass `Force=false` explicitly to `Message Argument ori.IsTableWriteRestrictedForDataRecords` after core #904 added the required parameter. The four existing restriction assertions remain enabled. The Job Queue test keeps direct companion hints exact and checks the current Force-tier base error, full next-step guidance, PermissionDenied code and expected access.

### Changed (2026-10-04) - CI/CD builds only main; every pull request gets a Pull Request Build

- Build policy only, no app change. `CI/CD` runs on pushes to `main` only, and `Pull Request Build` runs for pull requests into any branch. `.github/AL-Go-Settings.json` sets `CICDPushBranches` to `main` and `CICDPullRequestBranches` to `**`, so Update AL-Go System Files keeps the triggers.

### Changed (2026-10-01) - Committing message types declare effect irreversible (#60)

- `Orchestrator.Playbook.Run`, `Orchestrator.Entry.Run`, `Orchestrator.Entry.Register`, `Orchestrator.Entry.Restart`, `Orchestrator.Entry.Schedule`, `Orchestrator.Status.Restart`, `Orchestrator.Status.RestartIfNeeded` and `Orchestrator.Report.Run` commit while they run, so their contracts now declare effect `irreversible` instead of `write`. The `changes` text names the commit and says that the Orchestrator refuses these types in a playbook chain that must roll back together (Omit Commit). Their selection descriptions say "Irreversible." instead of "Write operation.".
- `Orchestrator.Playbook.Schedule`, `Orchestrator.Playbook.Enqueue`, `Orchestrator.JobQueueEntry.Restart`, `Orchestrator.JobQueueEntry.RestartIfNeeded` and `Orchestrator.ReportLayout.Set` stay `write`; the read types stay `read`. Contract tests check every type's effect.

### Removed (2026-10-01) - Markdown help of the message types (#57)

- The message types no longer have a markdown help procedure (`GetMessageHelpAsMarkdownDocument`); Bifrost Foundation stopped calling it. Each type describes itself only through its contract chapters in `Help.Implementation.Get`. `Help.Orchestrator.Get` still returns the same module overview.
- The Bifrost Foundation dependency is 28.0.0.186, the first build without the procedure.

### Changed (2026-10-01) - Contracts carry everything the old help said (#56)

- Facts that were only in the old per-type help are now in the contracts: allowed values and defaults (`notificationType`, `retryPolicy`, `format`, `layoutFormat`), response fields of nested objects (`Report.List` reports, `Report.Get` layouts and preset, `Status.Get` entries, `Workspace.Preview` `_sys`), how each type finds its record, the Email draft-and-send and report preset workflows, and notes on inline playbook runs, `itemsProcessed`, `Report.Run` safety and the Telegram prerequisites.
- Error chapters describe what callers actually receive: every Orchestrator error comes back with code `BusinessCentralError` and its text; the contracts no longer promise `MissingParameter`, `RecordNotFound` or `InvalidParameterFormat`.
- Corrected contract details that did not match the code: `Entry.Register` takes the Job Queue Entry ID (not its SystemId) and re-registering replaces the orchestrator entry; `Playbook.Enqueue` returns the Job Queue Entry ID; `Playbook.Run` returns the instance ID and answers Success with `playbookStatus` Failed when a step fails; `Status.*` `orchestratorStatus` is a translated sentence, not `Ready`; `Report.SaveAs` has no layout parameter and its answer is marked `application/pdf` for every format.

### Changed (2026-09-29) - Message contracts Batch 1 (#56)

- Added Foundation message contracts and bilingual discovery metadata for Entry, Status, Playbook, Job Queue Entry, Help, Email and Telegram message types.
- Contract chapters now describe the actual request keys, responses, errors, effects, related types and examples; the legacy markdown provider is retained only as a compatibility shim.
- Added Batch 1 contract conformance tests and shared contract parts.
- Review fixes: RestartIfNeeded enum implementations use the RestartIf codeunit names, `Help.Orchestrator.Get` returns the overview, decision tree and playbook guide and documents the version 1.0 error, the Bifrost Foundation dependency is 28.0.0.166, `Orch B1 Contract Parts ori` (10035609) is in `BIFROST Orchestr ori`, and the new discovery labels are in the is-IS translation file.

### Changed (2026-09-29) - Message contracts Batch 2 (#56)

- Added Foundation message contracts and bilingual discovery metadata for Report, Workspace and ReportLayout message types.
- Report rendering, processing-only execution and tenant layout import contracts describe their actual JSON and binary response behavior.
- Added Batch 2 contract conformance tests and shared contract parts.
- Review fixes: `Orchestrator.Report.List` documents a non-boolean `processingOnly` error, `Orch B2 Contract Parts ori` (10035610) is in `BIFROST Orchestr ori`, and the new discovery labels are in the is-IS translation file.
### Changed (2026-09-30) - Help examples use a company-form test kennitala (#49)

- The `_who` context example in the help text uses test values: company kennitala `5501011490` (fictitious, legal-entity form), neutral user and salesperson names, and placeholder VAT number and Telegram chat ID.

### Fixed (2026-09-29) - Entry.Run runs headlessly and uses the entry Record ID (#36)

- `Orchestrator.Entry.Run` runs the scheduled entry with no confirmation dialog. It returns `status: Success` only when the dispatcher completes the job, and `status: Error` with that run's error text when the job fails.
- The one-time Job Queue Entry copies `Record ID to Process` from the scheduled entry, so a playbook entry runs that playbook.
- The interactive Run Now action still asks for confirmation and shows the progress and completion messages.
### Fixed (2026-09-29) - Playbook.Enqueue schedules the Job Queue Entry (#37)

- `Playbook ori.EnqueuePlaybook` schedules the one-off Job Queue Entry through `Job Queue - Enqueue`, so the entry gets a System Task ID and runs at its earliest start. `Orchestrator.Playbook.Enqueue` reports Success only after that call returns.
- Tests cover a non-null System Task ID and that the dispatcher creates a Playbook Instance. The existing minimum-delay and parameter-record tests are unchanged.
### Fixed (2026-09-29) - RestartIfNeeded uses the management entry primary key (#35)

- `Orchestrator.Status.RestartIfNeeded` looks up the management Job Queue Entry with `Get` on its primary-key ID. A Ready or In Process entry stays running (`restarted: false`) instead of being cancelled and rescheduled.
- `RestartIfNeededSkipsWhenAlreadyRunning` and `RestartIfNeededSkipsWhenInProcess` assert a Ready or In Process management entry is left alone (`restarted: false`, same SystemId and status). `RestartIfNeededRestartsWhenInError` asserts an Error entry is rescheduled (`restarted: true`, new SystemId, status no longer Error).
### Changed (2026-09-29) - Telegram Chat ID in General group (#42)

- Telegram Chat ID has moved to the General group on User Setup, and the NoChatIdErr Icelandic comment encoding is fixed (#42).
- Requires Bifrost Foundation 28.0.0.152 or later (User Setup General group, core#159).
### Fixed (2026-09-28) - A failed restart notification no longer aborts the scheduler (#46)

- Setup lookup, body build and each e-mail recipient send for the restart notification now run behind `TryFunction` boundaries inside `Email Notification ori`, so a failure is logged as `O4NJQS-0008` "Error Sending Restart Notification" and the job is still restarted.
- No `Commit()` is introduced in the restart-notification path, so the scheduler keeps its existing lock/transaction behavior while isolating notification failures from the restart flow.
- Test: `RestartNotificationFailure_DoesNotAbortScheduler_JobStillRestarted`.

### Fixed (2026-09-28) - Default build never ships internalsVisibleTo; CI check fails it if it does (core#129)

- **The Default build compiles the app without the `internalsVisibleTo` grant for
  `Bifrost Orchestrator - Tests`, through the standard AL-Go hook.** COSMO Alpaca's `PreCompileApp` override
  keeps `.AL-Go/PreCompileApp.ps1` in `$AlGoPreCompileApp` but never calls it. `.AL-Go/PipelineInitialize.ps1`
  now chains the two (Alpaca's override first, then `$AlGoPreCompileApp` with the same `appType` and
  compilation parameters). All Alpaca logic is unchanged. The new `.AL-Go/PreCompileApp.ps1` strips
  `internalsVisibleTo` and the AS0081 suppression in every build mode except `Test`. It replaces the interim
  strip at the top of `PipelineInitialize.ps1`.
- **New CI check (`.AL-Go/PostCompileApp.ps1`).** After the app compiles, a build in any mode except `Test`
  fails if the `app.json` it compiled from or the compiled `.app` (`NavxManifest.xml`) still grants
  `internalsVisibleTo` to an app outside an explicit allow-list. The allow-list is empty. The `Test` build
  keeps its grant and only logs it. The script then restores the original `app.json`.
- `.AL-Go/settings.json`: `fullBuildPatterns` gains `.AL-Go/*.ps1`, so a change to an AL-Go hook script triggers
  a full build. Before, AL-Go treated such a change as touching no project and skipped the build.
- Build configuration only: no AL code, `app.json` or version change. Same fix as bc-origo-bifrost-core#129.

### Changed (2026-09-27) - Report.Get direction Both (#43)

- `Orchestrator.Report.Get` is registered as direction Both, because it inserts a Report Request Preset row when the caller has none. Behaviour is unchanged. Companion-hint tests and help read the dedicated types from `nextStep`, where Foundation puts them.

### Changed (2026-09-25) - build against latest Foundation CI

- The app builds against the latest Foundation CI build. AL-Go `appDependencyProbingPaths` for bc-origo-bifrost-core keeps `release_status: latestBuild` and sets `version: latest`, so GetArtifacts uses the last successful CICD run.
- Foundation dependency floor is `28.0.0.0` in app and test `app.json`. App version stays `28.0.0.0`.
- `.AL-Go/settings.json` is listed in `fullBuildPatterns` so a probe-only change triggers a full build.
### Security

- Default (release) builds no longer ship the test app's internalsVisibleTo grant; the strip moved to PipelineInitialize.ps1 because Alpaca never ran PreCompileApp.ps1 (core#129).

### Fixed (2026-09-25) - main build AL0132 on GetRequestDebugMode (#33)

- CI/CD run [36066665137](https://github.com/businesscentralal/bc-origo-bifrost-orchestrator/actions/runs/36066665137) on `85d2e3c` failed both builds with AL0132: `Record "Setup ori"` does not contain `GetRequestDebugMode` (ReportMsgHandler, PlaybookStepExecutor).
- Cause: `.AL-Go/settings.json` `appDependencyProbingPaths` for bc-origo-bifrost-core pinned `version: 1.0.0.100`, so builds compiled against core build 1.0.0.100, which predates `GetRequestDebugMode` (added in core build 1.0.0.124).
- Fix: probing version raised to `1.0.0.132`, the core build that is live on the Bifrost sandbox as Foundation 28.0.0.132 (includes core#107 and core#114). App/test app.json unchanged.

### Changed (2026-09-24) - AppSource URLs and Application Insights

- `app.json` `help` and `contextSensitiveHelpUrl` now use the orchestrator docs routes, `privacyStatement` and `EULA` use the Foundation privacy and EULA pages, `url` stays `https://www.origo.is/`, and the Application Insights connection string points at the shared telemetry resource.
### Changed (2026-09-24) - page help links use renamed docs routes

- Page help links (`ContextSensitiveHelpPage`) now use the renamed docs routes (`nornir-setup` → `orchestrator-setup`).

### Changed (2026-09-21) - Bifröst logo refresh

- App logo: new Bifröst wordmark with "Powered by origo." tagline; app-name line unchanged.

### Changed (2026-09-17) - Bifrost Foundation Exact pin 28.0.0.100 (no float)

- App/test Bifrost Foundation dependency set to Exact `28.0.0.100`.
- AL-Go `appDependencyProbingPaths` for bc-origo-bifrost-core: `release_status: latestBuild`, `version: 1.0.0.100`.
- `nuGetFeedSelectMode: Exact` so NuGet does not resolve `[28.0.0.100,)` upward to colliding `.107`.

### Changed (2026-09-15) - permission-tolerant legacy take-over probe (#21)

- **`App Takeover ori` probes legacy tabledata before copy** (`TryProbeTakeOverPermissions` /
  `TryRunTakeOverAtInstall`), mirroring Foundation core#43 / attachments#8. Sources remain only
  Cloud Events tables 10076035–10076040, 10076044, 10076090, 10076099 and field-copy source
  10075509; Access Control write is probed when CE Orchestrator role pairs would move. First
  denial skips the whole take-over with one telemetry event (`ORI-BIF-0003`), never `Error`.
  Ambiguity A1: telemetry only + idempotent re-run (no pending flag on Scheduler Setup ori).
  Ambiguity A2: Telegram Bot Token ID (legacy field 60) stays dropped — no counterpart.
- **`App Takeover State ori` (10035608)** — SingleInstance probe-denial / last-skip seam for
  unit tests (same role as Foundation `Take-Over State ori`).
- **`App Install ori`** calls `TryRunTakeOverAtInstall` instead of bare `TakeOverAll`
  (probe → direct `TakeOverAll`; no nested `Codeunit.Run` isolation on install).
- **Tests** `App Takeover Probe Tests` (96426) cover AC01 probe-denied, AC02 probe-OK, AC03
  legacy absent via the State seam. Existing Access Control mapping tests (96425) unchanged.
  Unused empty permission set `Test No Source Read` (96427) removed.

### Added (2026-09-15) - Data.Records companion hints for Orchestrator-owned tables (#19)

- **`Report Data Restriction ori`** subscribes to Foundation `Message Argument ori` companion
  events (`OnGetDedicatedMessageTypeHintForRead` / `…ForWrite` / `…ForField`) so blocked
  `Data.Records.Get` / `Data.Records.Set` name the dedicated Orchestrator message types:
  - **Job Queue Entry** (write) → `Orchestrator.Entry.Register` / `Orchestrator.Entry.Schedule` /
    `Orchestrator.JobQueueEntry.Restart`
  - **Scheduled Task** (write) → `Orchestrator.Status.Restart` (no generic write)
  - **Report Request Preset ori** (read/write) → `Orchestrator.Report.Get` /
    `Orchestrator.Report.Run` / `Orchestrator.Report.SaveAs`
- **Tests** `Data Records Hint Tests` (96428) — one test per table via Foundation public
  `Message Argument ori` hint APIs + `RespondWithRestrictedTableError` (same shared path as
  Data.Records; Message Task is Foundation-internal / not visible to this test app).
- **Help.Orchestrator.Get** Data Reference documents the restricted-table hint table.
- **Foundation dependency pin** raised to **28.0.0.100** (core#20 / PR #45 APIs; never 28.0.0.87).
  `.AL-Go` core probing `release_status` → **latestBuild**. App version stays **28.0.0.0**.

### Fixed (2026-09-11) - Playbook.Schedule returns SystemId as orchestratorEntryId (#15)

- `Orchestrator.Playbook.Schedule` now returns `orchestratorEntryId` as the Scheduled Entry's
  SystemId so `Entry.Run` / `Entry.Restart` resolve it, plus `orchestratorEntryPkId` carrying
  the primary-key ID for backward reference.
- `FindEntry` falls back to a primary-key lookup when the SystemId lookup fails. Unknown or
  garbage GUIDs still return the existing not-found error; callers already passing a SystemId
  are unchanged.
- Unit tests in `Schedule Playbook Tests` (96415) cover SystemId round-trip, PK fallback, and
  unknown GUID.

### Fixed (2026-09-11) - Access Control take-over grant for customer tenants

- **`App Takeover ori` grants `tabledata "Access Control" = RI`.** Install/upgrade on a tenant
  still running Origo Cloud Events Orchestrator re-grants matching `BIFROST ... ori` roles by
  inserting into Access Control; without the grant the whole publish rolls back. No delete of
  legacy rows, so R+I is sufficient. The grant lives on the codeunit `Permissions` property
  (not a user-assignable permission set).
- **Take-over unit tests TC001–TC003** (`App Takeover Tests`, 96425) seed Access Control via
  `RecordRef.Open(2000000053)` and cover grant, idempotent re-run, and empty-legacy exit.
  `TakeOverAccessControl` is no longer local so the tests can call it directly.

### Fixed (2026-09-11) - `_sys.lastMonthEnd` off-by-one (#11)

- `Playbook Workspace ori.SeedSystemConstants` computed `lastMonthEnd` with `CalcDate('<CM-1M>', Today)`,
  which is "closing of the current month minus one month" (e.g. 2026-09-30 → 2026-08-30) and silently
  missed the last calendar day of 31-day months. It now uses `CalcDate('<-CM-1D>', Today)` via
  `GetLastDayOfPreviousMonth` (start of this month minus one day). `lastMonthStart` / `thisMonthStart`
  formulas are unchanged. Unit tests TC001–TC005 cover September, leap February, January cross-year,
  and May 31 → April 30.

### Setup notifications and wizard (2026-09-07)

Setup notifications are no longer raised by this app. Every setup banner in the Bifröst family now
lives on Foundation's **Bifrost Setup** page, which aggregates the HTTP client status and the
missing credentials of all installed Bifröst applications into one banner per topic, each carrying
the single action *Start setup wizard*.

- **Added** codeunit 10035607 `Orchestrator Registration ori` (`Access = Internal`). Its only
  subscriber answers Foundation's `App Registry ori.OnRegisterApps` and registers this application
  with its module id, its name and page `Scheduler Setup ori` as its setup page. That registration
  is what lets Bifrost Setup name Bifrost Orchestrator in the aggregated banners and what lets the
  Bifrost Setup Wizard enable outbound HTTP and walk through the credentials of this app.
- **Removed** the two notifications on `Scheduler Setup ori`: the HTTP-blocked / job-queue-not-running
  banner with its *Run Setup Wizard* action, and the "secrets missing" banner with its
  *Open App Secrets* action, together with their labels and their `OnOpenPage` calls. The page still
  registers its secrets on open and still reports the Telegram bot token as *Set* / *Not set*.
- **Removed** the "client id and client secret must be entered once" banner on
  `Credentials Card ori`. The two status fields already report the same thing without a banner.
- **Removed** the procedures that existed only to serve those banners:
  `Scheduler Wizard Reg. ori.OpenSetupWizard` and `Secrets ori.OpenAppSecrets`. The assisted-setup
  registration in `Scheduler Wizard Reg. ori` is untouched, so the wizard is still discoverable
  through Assisted Setup and from Bifrost Setup.
- The `Notifications/` feature of this app - Email, Telegram and None notification implementations
  used to report job queue outcomes - is a business feature and is untouched.
- **Added** test codeunit 96423 `Orchestr Registration Tests`, asserting that Bifrost Orchestrator
  appears in `App Registry ori.GetApps` under its own module id and points at page
  `Scheduler Setup ori`. `Orchestr Secret Tests` no longer declares a notification handler for the
  application setup page, which raises none any more.
- **Added** action *Setup Wizard* to `Scheduler Setup ori`, promoted next to *App Secrets*. Unlike the
  removed banners above, this is a plain navigation action to Foundation's `Setup Wizard ori` - always
  available, no notification involved - so an administrator can open the wizard from this app's own
  setup page instead of only from Bifrost Setup or Assisted Setup.

### Changed (2026-09-07) - tests run on Foundation's public API

- The test app no longer depends on Bifröst Foundation's internals: Bifrost Orchestrator - Tests has been removed
  from Foundation's `internalsVisibleTo`, and the test suite compiles and runs against a Foundation
  package that does not grant it. No test code had to change - the suite never touched a Foundation internal.

### App name: Bifrost Nornir -> Bifrost Orchestrator (2026-09-06, before first release)

The app was migrated under the working name *Bifrost Nornir*. Bifröst apps are named after
what they do, not after Norse mythology, so it ships as **Bifrost Orchestrator** - which is
also what the predecessor was called and what the message-type keys already say.

- `app.json` name `Bifrost Nornir` -> **Bifrost Orchestrator**; test app **Bifrost Orchestrator - Tests**.
  Icelandic brand form: **Bifröst stjórnandi** (genitive *Bifröst stjórnanda*).
- Namespace `Origo.Bifrost.Nornir` -> `Origo.Bifrost.Orchestrator` (tests `.Test`).
- Permission sets `BIFROST Nornir ori` -> `BIFROST Orchestr ori`, `BIFROST NrnSetup ori` ->
  `BIFROST OrchSet ori`, `BIFROST NrnMgt ori` -> `BIFROST OrchMgt ori`. The take-over role
  mapping in `App Takeover ori` was updated with them. `BIFROST OrchSetup ori` would have been
  21 characters; permission-set object names are `Code[20]`, hence `BIFROST OrchSet ori`.
- Page caption *Bifrost Nornir Setup* -> *Bifrost Orchestrator Setup*; the `Setup ori` action,
  the Job Queue Entry page actions and every Icelandic caption follow.
- Request-log type enum value `Nornir Playbook` -> `Orchestrator Playbook`.
- Test codeunit `Nornir Secret Tests` -> `Orchestr Secret Tests`.
- **Message-type keys are unchanged** (`Orchestrator.*`, `Help.Orchestrator.Get`) - they never
  carried the working name.
- Repository renamed `bc-origo-bifrost-nornir` -> `bc-origo-bifrost-orchestrator`.
- **The documentation slug stays `nornir`** for now: `help`, `contextSensitiveHelpUrl` and
  `ContextSensitiveHelpPage = 'nornir-setup'` still point at
  `businesscentralal.github.io/bifrost/.../nornir/`. The folders in the site repository are
  renamed in a separate change; moving the slugs first would 404 the published help.

### Review follow-ups (2026-09-06)

- `Locked = true` added to all 20 `Orchestrator.*` message-type enum captions, matching
  Foundation's `Message Type ori`. The keys are the wire contract and must never be translated.
- `BIFROST Orchestr ori` is no longer a four-table read stub: it now grants every table, page
  and codeunit the app owns, so it is a usable assignable role. `BIFROST OrchSet ori` and
  `BIFROST OrchMgt ori` gained the pages and codeunits their data grants imply. All three still
  require a Bifröst Foundation permission set for the message loop, the request log and the
  secret store - documented in README.md and in the permission sets' XML docs.
- The test app no longer deletes and rebuilds the shared `DEFAULT` AL Test Suite (it wiped the
  suites of the ~15 apps co-installed on bc28-is). `Test Install` now owns the `ORCHESTRAT`
  suite over its own range `96400..96499`, and a new `Test Upgrade` (96404) refreshes it on
  republish so a renamed test codeunit is picked up without an uninstall.

### Review follow-ups (2026-09-07)

- **BLOCKER resolved**: `BIFROST PlaybAdm ori` and `BIFROST PlaybVw ori` granted only `tabledata`
  and were not usable roles - opening any playbook page or running a playbook required a
  different permission set entirely. Both now grant the full set of playbook pages (list, card,
  instance card, subpages, FactBoxes, template editor); `BIFROST PlaybAdm ori` additionally
  grants execute on every codeunit that runs or dispatches a playbook (`Playbook Runner ori`,
  `Playbook Step Executor ori`, `Msg Executor ori`, `Playbook JQ Dispatcher ori`) and on
  `Playbook Log Mgt ori` (writes instance/step log records during a run). `BIFROST PlaybVw ori`
  withholds all of those codeunits and also withholds the `Schedule Playbook ori` wizard page
  (a run-only entry point with no "view" use) so scheduling stays blocked at the platform's
  page-permission check. See the XML doc comments on both permission sets for the full reasoning,
  including a documented residual risk around the "Run Now" action on `Playbook Card ori`.
- Fixed four stale/incorrect Icelandic translations found in PR review: the AI overview help text
  still said "Job Queue +" instead of a proper Icelandic phrase; the `Playbook Condition Operator`
  enum caption said *Virkja* (verb, "activate") instead of *Virkni* (noun, "function of"); the
  `BIFROST PlaybAdm ori` and `BIFROST PlaybVw ori` captions used Title Case ("Bifröst Keðja
  Stjórnandi" / "Bifröst Keðja Skoðun") instead of Icelandic sentence case ("Bifröst
  keðjustjórnandi" / "Bifröst keðjuskoðun"). Fixed in the `is-IS=` source comments and hand-aligned
  in `Bifrost Orchestrator.is-IS.xlf`; the gitignored `.g.xlf` regenerates from source on compile.

### Rebrand: Origo Cloud Events Orchestrator -> Bifrost Orchestrator

- New AppSource app identity: app id `7da3f512-5c19-47cd-bbe4-4c2bc713f1db`, test app id `194ecd04-5688-4af6-94bc-732c714251fc`, version reset to 28.0.0.0. The predecessor stays published and installed side by side.
- App name `Origo Cloud Events Orchestrator` -> **Bifrost Orchestrator**; test app `Bifrost Orchestrator - Tests`. Icelandic captions use "Bifröst".
- New object ID range 10035535-10035634 (offset -40500 from the legacy range 10076035-10076134; object numbers keep their relative order). Test app range 96400-96499 so the test app can be installed next to the legacy one; the range originally proposed for this app (96300-96399, offset +3300 from 93000-93099) collided with `Cloud Events Gagnatorg - Tests`, which occupies that exact block on bc28-is/bc28-w1 but was not yet registered in the object range workbook, so every test object was shifted +100 before publishing.
- Namespace `Origo.APP.CloudEvents.Orchestrator` -> `Origo.Bifrost.Orchestrator`; tests `Origo.Bifrost.Orchestrator.Test`.
- Dependency retargeted from *Origo Cloud Events Core* to **Bifrost Foundation** (`7505e808-6e52-4b96-a328-82573391297a`, 28.0.0.0).
- Object names: the `CE` prefix was dropped from every object and every object now carries the mandatory `ori` suffix. The scheduling objects were renamed after what they do rather than after the old product: `CE Orchestrator Entry ori` -> `Scheduled Entry ori`, `CE Orchestrator Setup ori` -> `Scheduler Setup ori`, `CE Orchestrator Handler ori` -> `Scheduler Handler ori`, `CE Orchestrator Mgt ori` -> `Scheduler Mgt ori`, `CE Orchestrator Events ori` -> `Scheduler Events ori`, `CE Orchestrator API Client ori` -> `Scheduler API Client ori`, `CE Orch. Setup Wizard ori` -> `Scheduler Setup Wizard ori`, `CE Playbook ori` -> `Playbook ori`.
- Permission sets renamed: `CE Orchestrator ori` -> `BIFROST Orchestr ori`, `CE Orch. Setup ori` -> `BIFROST OrchSet ori`, `CE Orch. Mgt ori` -> `BIFROST OrchMgt ori`, `CE PlaybookAdmin ori` -> `BIFROST PlaybAdm ori`, `CE Playbook View ori` -> `BIFROST PlaybVw ori`.
- Message type keys are **unchanged**: the 20 types keep their `Orchestrator.*` prefix (and `Help.Orchestrator.Get` as the help directory) because they are the external API contract and contain no brand word.
- New Bifrost logo (`app/assets/Logo250x250.png`) for the app and the test app; the app name was
  later added under the Bifröst wordmark.

  (An earlier step of this migration moved the help to blob storage with HTML sources under
  `app/Help/`. That was superseded before release - see *Changed* below: the documentation now
  lives in `businesscentralal/bifrost` and this repository carries no `Help/` or `docs/` folder.)

### Added

First release of Bifrost Orchestrator as an app in its own right. It succeeds *Origo Cloud Events
Orchestrator*, which stays published and installed side by side until it is deprecated.

- **Scheduling.** `Scheduled Entry ori` wraps a Job Queue Entry with orchestration settings:
  recurrence, allowed time range, time zone, retry policy (Always / Three Times / Never) and a
  notification channel. `Scheduler Handler ori` walks the enabled entries every cycle, restarts
  failed ones within their policy and reports through `Scheduler Status ori`.
  `Recurring Template ori` holds reusable schedules; `Scheduler Setup Wizard ori` gets a new
  tenant from nothing to a running job queue.
- **Playbooks.** A declarative runner that chains Bifrost message types: `Playbook ori` /
  `Playbook Step ori` define the sequence, `Playbook Runner ori` executes it,
  `Playbook Workspace ori` carries a shared JSON document between steps with dot-notation
  bindings, `Playbook Condition ori` gates and branches on response values, and steps can iterate
  over an array returned by an earlier step. `Playbook Instance ori` and `Playbook Step Log ori`
  record every run with request, response and workspace snapshot.
- **20 message types** under the `Orchestrator.*` key space plus `Help.Orchestrator.Get`, each with
  help text served through the Foundation help directory - entry run/restart/register/schedule,
  status get/restart, playbook run/schedule/enqueue, job queue entry restart, report
  list/get/run/save-as, workspace preview, email send and Telegram message.
- **Notifications** by email or Telegram through the `Notification ori` interface, with the Telegram
  chat id kept on `User Setup ori`.
- **Five assignable permission sets**: `BIFROST Orchestr ori` (everything the app owns),
  `BIFROST OrchSet ori` (setup), `BIFROST OrchMgt ori` (operations), `BIFROST PlaybAdm ori` and
  `BIFROST PlaybVw ori` (playbook authoring and read-only).
- **Data take-over** on first install: `App Takeover ori` copies the configuration of the published
  Cloud Events app - execution logs and secret values are deliberately not copied.

### Changed

- **Bifröst Setup is no longer the Orchestrator setup page.** The page extension `Setup JQ ori` (10035537) on
  Foundation's `Setup ori` is reduced to the single entry point every Bifröst application is allowed to
  add: one action **Bifrost Orchestrator Setup** in `group(Apps)` plus its actionref in `Category_Apps`. The
  `Orchestrator` action group with its four actions, the HTTP/job-queue setup notification and the
  `ContextSensitiveHelpPage = 'setup-jq'` override (which wrongly replaced Foundation's own help page)
  were all removed from it.
- **`Scheduler Setup ori` (page 10035536) is now the Bifrost Orchestrator setup page.** It is captioned
  *Bifrost Orchestrator Setup*, uses the help slug `nornir-setup`, and carries what moved off Bifröst Setup:
  the navigation actions *Bifrost Playbooks*, *Client Credentials* and *Playbook Execution Log*, a new
  *App Secrets* action that opens Foundation's `App Secrets ori` list filtered to this application, and
  the HTTP-blocked / job-queue-not-running notification in its own `OnOpenPage`. Actions are promoted
  into three categories (Process, Setup, Playbooks).
- **Secrets moved into the Bifröst Foundation secret store.** Bifrost Orchestrator no longer keeps its own
  GUID-keyed IsolatedStorage entries. The new internal codeunit `Secrets ori` (10035606) composes the
  codes and wraps `Secret Store ori`. All secrets use scope **Company**:
  - `TELEGRAM-BOT-TOKEN` - the Telegram bot token, previously field 60 `Telegram Bot Token ID` on
    `Scheduler Setup ori`.
  - `CREDENTIAL-<Code>-CLIENT-ID` and `CREDENTIAL-<Code>-CLIENT-SECRET` - the OAuth 2.0 client id and
    client secret of a `Client Credentials ori` record, previously fields 30 and 40 of that table.
    `<Code>` is the record code uppercased. The composed code has to fit `Code[50]`, which leaves 25
    characters for the record code; a longer code is shortened deterministically to its first 16
    characters, a hyphen and the first 8 hexadecimal digits of the SHA256 hash of the full uppercased
    code, so two long codes sharing a prefix never collapse onto one secret.
- The secrets are registered by `App Install ori` and by `App Upgrade ori` (`Secrets.RegisterAll()`),
  and again whenever a `Client Credentials ori` record is inserted, renamed or the setup page is opened.
  `Register` is idempotent. Renaming a credential record moves both stored values onto the new codes and
  clears the old ones; deleting a record clears both values but keeps the registrations visible.
- The masked editable fields and the `'***'` sentinel are gone. `Scheduler Setup ori` and
  `Credentials Card ori` now show a non-editable **Set** / **Not set** status with a Favorable or
  Unfavorable style, and offer *Set …* / *Clear …* actions that go through Foundation's shared masked
  dialog (`Secret Store ori.SetFromDialog`). `Credentials List ori` gained the same status as a
  **Secrets** column.
- `Scheduler API Client ori` reads both halves of a credential through `Secrets.TryGetClientId` /
  `TryGetClientSecret` (which stamp `MarkUsed` on the registry row). Because every `OAuth2` overload
  types the client id as `Text` while a stored secret is only available as `SecretText` - and
  `SecretText.Unwrap` is not allowed in Cloud extensions - the client credentials grant is now issued
  directly against the Microsoft Entra token endpoint with a form body composed by `SecretStrSubstNo`,
  so neither the client id nor the client secret is ever materialised as `Text`.
- Help and documentation moved to https://businesscentralal.github.io/bifrost - the shared Bifröst site (repository
  `businesscentralal/bifrost`) now carries the product documentation and the in-product help for every
  Bifröst app. The `app/docs/` and `app/Help/` folders were removed from this repository together with
  the blob-storage sync workflow. `app.json` now points `help` at https://businesscentralal.github.io/bifrost/en-us/nornir/
  and `contextSensitiveHelpUrl` at `https://businesscentralal.github.io/bifrost/{0}/help/nornir/`.
- Context-sensitive help pages are addressed by slug instead of by file name: the `.html` extension was
  dropped from `ContextSensitiveHelpPage` on all 16 pages and page extensions (for example
  `playbooks.html` -> `playbooks`), because the site serves Docusaurus page slugs.
- The playbook step executor no longer calls the MCP Tool Server (that server moved to **Bifrost Bragi**). Steps now dispatch through the new internal codeunit `Msg Executor ori` (10035603), which wraps the Bifrost Foundation `Dispatcher ori` in a `Codeunit.Run` scope so a message type that commits or fails is isolated from the surrounding playbook run. Binary responses (any non-text content type) come back base64-encoded inside a JSON envelope (`contentType`, `size`, `base64`) instead of an in-memory blob reference.

### Fixed

- Renamed the data take-over codeunit from `Nornir Takeover ori` to `App Takeover ori` so no
  object name carries the "Nornir" brand, consistent with `App Install ori` / `App Upgrade ori`
  and with `bc-origo-bifrost-hnitbjorg`'s `Storage Takeover ori`.
- Every `TakeOver<Table>` procedure in `App Takeover ori` now checks `RecordRef.FieldExist`
  before adding a field to the `DataTransfer`, instead of assuming every field number from the
  source app definition exists on every target environment. `Origo Cloud Events Orchestrator`
  reports the same version (28.0.0.0) on bc28-is and bc28-w1 but has a different `packageId` on
  each container, so a hard-coded field list is not safe to assume everywhere.
- `SchedulerMgt.Codeunit.al`'s `GetManagementJobQueueId()` was returning the exact same Guid as
  the predecessor app's management Job Queue Entry. Both apps are installed side by side and
  share the base-application Job Queue Entry table, so Bifrost Orchestrator was finding and reusing
  the legacy app's entry (pointing at the legacy handler codeunit) instead of ever scheduling
  its own - confirmed via two failing unit tests and via `Orchestrator.Status.Get` reporting
  "Job Queue has not been configured". Generated a fresh Guid for this app's own entry.
- Wired `ContextSensitiveHelpPage` on every page and page extension that was missing it, and wrote
  the matching help pages in both languages. (The pages were first written as HTML under
  `app/Help/`; they were moved to `businesscentralal/bifrost` before release - see *Changed*.)
- Renamed field `Orchestrator Enabled ori` to `Scheduler Enabled ori` and action
  `AddToJobQueueOrchestrator ori` to `AddToScheduler ori` on the Job Queue Entry card/list
  extensions, with captions/tooltips referring to Bifrost Orchestrator instead of the legacy
  "Job Queue Orchestrator" name.

### Removed

- **Chat integration.** Bifrost Foundation no longer contains the chat module - it moved to the separate app **Bifrost Bragi** - so the "Bifrost Chat" actions and the chat FactBoxes were removed from `Playbooks ori`, `Playbook Card ori`, `Playbook Instances ori`, `Playbook Instance Card ori` and `Scheduled Entry Card ori`. Bifrost Orchestrator does not depend on Bragi.
- The obsolete field `Max Iterations` (field 71 on `Playbook Step ori`) was not migrated.
- Field 60 `Telegram Bot Token ID` on `Scheduler Setup ori` and fields 30 `Client ID` / 40
  `Client Secret` on `Client Credentials ori` were dropped outright. They only held the IsolatedStorage
  key of a value this application wrote itself, and Bifrost Orchestrator is not released yet, so no
  obsoletion period was needed. The take-over from `Origo Cloud Events Orchestrator` no longer copies
  those three fields either - a key is worthless without the other extension's storage.

### Security (2026-09-07, PR gateway review)

- The recipient email address is no longer a telemetry dimension on the "Error Sending Email"
  message in `Email Notification ori`. It is end-user identifiable information and the message is
  emitted with `TelemetryScope::All`, so it reached Origo's Application Insights as well as the
  customer's. The Telegram chat id was removed from the equivalent message in
  `Telegram Notif. ori` for the same reason.
- `Orchestrator.Report.Run` no longer returns `callstack` in its error response unless the
  administrator has switched on Request Debug Mode. The call stack names objects, procedures and
  line numbers of the base application and of every extension on the stack.
- `App Upgrade ori` no longer sets `"Allow HttpClient Requests"` on upgrade. That flag is the
  administrator's consent switch for outbound HTTP; re-enabling it silently on every upgrade undid
  a deliberate decision with no dialog and no trace. The setup page and the setup wizard both
  detect the disabled state and offer to turn it on, and every outbound caller checks it first.
- Data classification corrected where the table-level `SystemMetadata` did not hold: the payload
  blobs `Playbook Step Log ori`."Request Sent" / "Response Received" / "Iterator Element" /
  "Workspace Snapshot", `Playbook Instance ori`.Context and `JQ Parameter ori`."Request Data" are
  now `CustomerContent`, and `Scheduled Entry ori`."Notification Recipient" - which holds an email
  address and is published on `Scheduled Entry API ori` - is now
  `EndUserIdentifiableInformation`.

### Fixed (2026-09-07, PR gateway review)

- Deleting or renaming a `Client Credentials ori` record left its two secret registrations behind
  in the Bifröst secret store with no value. `Secrets ori.CountMissingSecrets` counts registered
  secrets that have no value, so the Bifrost Orchestrator Setup page raised a "secrets missing"
  notification for a credential nobody could enter a value for, for ever. `Secrets ori` gained
  `UnregisterCredential`, and `OnDelete` and `RenameCredential` now use it - which is what
  Foundation's `Secret Store ori.Unregister` documents as the call belonging in the owning
  record's `OnDelete`.
- `Orchestrator.Playbook.Run` returned the localised caption of the playbook status
  (`"Lokið"` on an is-IS tenant) instead of the invariant enum name, because it used `Format()` on
  an enum. It now uses the `StatusToText` helper the rest of the app already uses. The request log
  written by `Playbook Step Executor ori` had the same problem for the message type name and now
  uses `MessageTypeToText`.
- A playbook path with a non-numeric array index (`items[x]`) raised a hard error out of
  `Playbook JSON Helper ori` instead of failing the path like every other bad segment.

### Changed (2026-09-07, PR gateway review)

- `SetLoadFields` added to nine record reads and `ReadIsolation = ReadCommitted` to five read-only
  scans, across the scheduler, the playbook runner, the secret store facade and the Telegram
  message type.
- XML documentation added to 29 non-local procedures that had none.
- `Notif. Type ori` value `Telegram` marked `Locked = true` - it is a brand name, and its two
  sibling values already declared their translation.
- The dead `AS0084` suppression was removed from `app.json`; only `AS0081` (the
  `internalsVisibleTo` advisory) actually fires.
- Local page procedure `TryPopulateTelegramChatId` renamed to `PopulateTelegramChatId` - the `Try`
  prefix is reserved for `[TryFunction]`.

### Upgrade Notes

- **Secret values do not migrate.** IsolatedStorage belongs to the extension that wrote it, so the
  Telegram bot token, the client ids and the client secrets stored by `Origo Cloud Events Orchestrator`
  cannot be read from Bifrost Orchestrator. After installing, an administrator must enter each value once on
  **Bifrost Orchestrator Setup** (Telegram bot token) and on the **Client Credentials** card (client id and
  client secret). Both pages show a *Not set* status and a notification listing how many secrets are
  still empty; *App Secrets* lists all of them.
- `App Upgrade ori.DropLegacySecretKeys` deletes the values earlier pre-release builds of *this*
  application wrote under a random GUID key, on a best-effort basis: it reads the three removed fields
  through `RecordRef` and skips a field the platform no longer exposes. Once schema synchronisation has
  dropped the columns the keys are unreachable, so a pre-release build's own IsolatedStorage entries may
  survive in a developer container until the app version's data is deleted. No released environment is
  affected.

### Known Issues

- `Orchestrator.Entry.Register` fails via the API/message-type pipeline when registering a
  Job Queue Entry that is not yet an orchestrator entry (`Scheduled Entry ori.
  InsertFromJobQueueEntry` opens a card page unconditionally for new entries, which BC's Data
  Services layer rejects as a client callback). Pre-existing in the predecessor app too - see
  `test/reports/Bifrost_Orchestrator_MessageType_TestReport_2026-09-05.md` for the full analysis and
  suggested fix. Not addressed in this PR; tracked as a follow-up.
- `Orchestrator.Entry.Run` reports success over the API without running anything. It delegates to
  `Scheduler Mgt ori.RunJobQueueEntryOnce`, which opens with
  `ConfirmManagement.GetResponseOrDefault(RunOnceQst, false)`. `Confirm Management` returns the
  default button when the session has no GUI, so in a web-service session the answer is `false`
  and the procedure exits before it creates the throwaway Job Queue Entry - while
  `SE Msg Handler ori.ExecuteRun` still responds with `ExecutedMsg`. The same procedure then calls
  `Window.Open`, a client callback the Data Services layer rejects, so simply defaulting the
  confirm to `true` is not enough. Found by the PR gateway review of 2026-09-07 (the message-type
  test run of 2026-09-05 recorded "Success" because it read the response envelope rather than
  checking that the job had run). Same family as `Orchestrator.Entry.Register` above. Fix needs a
  GUI-free path through `RunJobQueueEntryOnce` - not addressed in this PR.
- The email draft addressed by `Orchestrator.Email.Send` is not checked for ownership, so a caller
  who learns another user's outbox SystemId can have that user's draft sent. The System
  Application exposes no supported way to read the owner (`"Email Outbox"."User Security Id"` and
  query `Outbox Emails` are both `Access = Internal`, and the only public accessors are
  `GetMessageId` / `GetAccountId` / `GetConnector`), so closing it needs a design decision - see
  the PR gateway report of 2026-09-07.
