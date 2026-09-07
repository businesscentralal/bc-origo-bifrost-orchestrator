# Changelog

All notable changes to Bifrost Orchestrator are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this app uses
Business Central release versioning (`major.minor.build.revision`).

## [28.0.0.0] - 2026-09-07

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
