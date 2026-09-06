# Changelog

All notable changes to Bifrost Nornir are documented here.

## [28.0.0.0] - 2026-09-05

### Rebrand: Origo Cloud Events Orchestrator -> Bifrost Nornir

- New AppSource app identity: app id `7da3f512-5c19-47cd-bbe4-4c2bc713f1db`, test app id `194ecd04-5688-4af6-94bc-732c714251fc`, version reset to 28.0.0.0. The predecessor stays published and installed side by side.
- App name `Origo Cloud Events Orchestrator` -> **Bifrost Nornir**; test app `Bifrost Nornir - Tests`. Icelandic captions use "Bifröst".
- New object ID range 10035535-10035634 (offset -40500 from the legacy range 10076035-10076134; object numbers keep their relative order). Test app range 96400-96499 so the test app can be installed next to the legacy one; the range originally proposed for this app (96300-96399, offset +3300 from 93000-93099) collided with `Cloud Events Gagnatorg - Tests`, which occupies that exact block on bc28-is/bc28-w1 but was not yet registered in the object range workbook, so every test object was shifted +100 before publishing.
- Namespace `Origo.APP.CloudEvents.Orchestrator` -> `Origo.Bifrost.Nornir`; tests `Origo.Bifrost.Nornir.Test`.
- Dependency retargeted from *Origo Cloud Events Core* to **Bifrost Foundation** (`7505e808-6e52-4b96-a328-82573391297a`, 28.0.0.0).
- Object names: the `CE` prefix was dropped from every object and every object now carries the mandatory `ori` suffix. The scheduling objects were renamed after what they do rather than after the old product: `CE Orchestrator Entry ori` -> `Scheduled Entry ori`, `CE Orchestrator Setup ori` -> `Scheduler Setup ori`, `CE Orchestrator Handler ori` -> `Scheduler Handler ori`, `CE Orchestrator Mgt ori` -> `Scheduler Mgt ori`, `CE Orchestrator Events ori` -> `Scheduler Events ori`, `CE Orchestrator API Client ori` -> `Scheduler API Client ori`, `CE Orch. Setup Wizard ori` -> `Scheduler Setup Wizard ori`, `CE Playbook ori` -> `Playbook ori`.
- Permission sets renamed: `CE Orchestrator ori` -> `BIFROST Nornir ori`, `CE Orch. Setup ori` -> `BIFROST NrnSetup ori`, `CE Orch. Mgt ori` -> `BIFROST NrnMgt ori`, `CE PlaybookAdmin ori` -> `BIFROST PlaybAdm ori`, `CE Playbook View ori` -> `BIFROST PlaybVw ori`.
- Message type keys are **unchanged**: the 20 types keep their `Orchestrator.*` prefix (and `Help.Orchestrator.Get` as the help directory) because they are the external API contract and contain no brand word.
- Help moved to https://origopublic.blob.core.windows.net/help/BifrostNornir/bc28/en-US/index.html, context-sensitive help to `.../BifrostNornir/bc28/{0}/`; HTML help sources in `app/Help/en-US/` and `app/Help/is-IS/`.
- New Bifrost logo (`app/assets/Logo250x250.png`) for the app and the test app.

### Changed

- **Bifröst Setup is no longer the Nornir setup page.** The page extension `Setup JQ ori` (10035537) on
  Foundation's `Setup ori` is reduced to the single entry point every Bifröst application is allowed to
  add: one action **Bifrost Nornir Setup** in `group(Apps)` plus its actionref in `Category_Apps`. The
  `Orchestrator` action group with its four actions, the HTTP/job-queue setup notification and the
  `ContextSensitiveHelpPage = 'setup-jq'` override (which wrongly replaced Foundation's own help page)
  were all removed from it.
- **`Scheduler Setup ori` (page 10035536) is now the Bifrost Nornir setup page.** It is captioned
  *Bifrost Nornir Setup*, uses the help slug `nornir-setup`, and carries what moved off Bifröst Setup:
  the navigation actions *Bifrost Playbooks*, *Client Credentials* and *Playbook Execution Log*, a new
  *App Secrets* action that opens Foundation's `App Secrets ori` list filtered to this application, and
  the HTTP-blocked / job-queue-not-running notification in its own `OnOpenPage`. Actions are promoted
  into three categories (Process, Setup, Playbooks).
- **Secrets moved into the Bifröst Foundation secret store.** Bifrost Nornir no longer keeps its own
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
- Help and documentation moved to https://bifrost.origo.is - the shared Bifröst site (repository
  `businesscentralal/bifrost`) now carries the product documentation and the in-product help for every
  Bifröst app. The `app/docs/` and `app/Help/` folders were removed from this repository together with
  the blob-storage sync workflow. `app.json` now points `help` at https://bifrost.origo.is/en-us/nornir/
  and `contextSensitiveHelpUrl` at `https://bifrost.origo.is/{0}/help/nornir/`.
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
  share the base-application Job Queue Entry table, so Bifrost Nornir was finding and reusing
  the legacy app's entry (pointing at the legacy handler codeunit) instead of ever scheduling
  its own - confirmed via two failing unit tests and via `Orchestrator.Status.Get` reporting
  "Job Queue has not been configured". Generated a fresh Guid for Nornir's own entry.
- Added HTML help (en-US + is-IS) for all 18 user-facing pages plus the bilingual index, and
  wired `ContextSensitiveHelpPage` on every page/page extension that was missing it.
- Renamed field `Orchestrator Enabled ori` to `Scheduler Enabled ori` and action
  `AddToJobQueueOrchestrator ori` to `AddToScheduler ori` on the Job Queue Entry card/list
  extensions, with captions/tooltips referring to Bifrost Nornir instead of the legacy
  "Job Queue Orchestrator" name.

### Removed

- **Chat integration.** Bifrost Foundation no longer contains the chat module - it moved to the separate app **Bifrost Bragi** - so the "Bifrost Chat" actions and the chat FactBoxes were removed from `Playbooks ori`, `Playbook Card ori`, `Playbook Instances ori`, `Playbook Instance Card ori` and `Scheduled Entry Card ori`. Nornir does not depend on Bragi.
- The obsolete field `Max Iterations` (field 71 on `Playbook Step ori`) was not migrated.
- Field 60 `Telegram Bot Token ID` on `Scheduler Setup ori` and fields 30 `Client ID` / 40
  `Client Secret` on `Client Credentials ori` were dropped outright. They only held the IsolatedStorage
  key of a value this application wrote itself, and Bifrost Nornir is not released yet, so no
  obsoletion period was needed. The take-over from `Origo Cloud Events Orchestrator` no longer copies
  those three fields either - a key is worthless without the other extension's storage.

### Upgrade Notes

- **Secret values do not migrate.** IsolatedStorage belongs to the extension that wrote it, so the
  Telegram bot token, the client ids and the client secrets stored by `Origo Cloud Events Orchestrator`
  cannot be read from Bifrost Nornir. After installing, an administrator must enter each value once on
  **Bifrost Nornir Setup** (Telegram bot token) and on the **Client Credentials** card (client id and
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
  `app/docs/Bifrost_Nornir_MessageType_TestReport_2026-09-05.md` for the full analysis and
  suggested fix. Not addressed in this PR; tracked as a follow-up.
