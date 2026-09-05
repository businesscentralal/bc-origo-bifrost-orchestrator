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

### Known Issues

- `Orchestrator.Entry.Register` fails via the API/message-type pipeline when registering a
  Job Queue Entry that is not yet an orchestrator entry (`Scheduled Entry ori.
  InsertFromJobQueueEntry` opens a card page unconditionally for new entries, which BC's Data
  Services layer rejects as a client callback). Pre-existing in the predecessor app too - see
  `app/docs/Bifrost_Nornir_MessageType_TestReport_2026-09-05.md` for the full analysis and
  suggested fix. Not addressed in this PR; tracked as a follow-up.
