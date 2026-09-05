# Extension: Bifrost Nornir

## Prefix
(none - objects use raw names with the mandatory `ori` suffix inside the `Origo.Bifrost.Nornir` namespace)

## Namespace
Origo.Bifrost.Nornir (tests: Origo.Bifrost.Nornir.Test)

## Object ID Range
App:   10035535-10035634 (migrated from the legacy Orchestrator range 10076035-10076134, offset -40500)
Tests: 96400-96499 (moved 2026-09-05 from the originally proposed 96300-96399: that block
  collides with the still-unregistered `Cloud Events Gagnatorg - Tests` app, which also occupies
  96300-96399 on bc28-is/bc28-w1. Legacy Orchestrator test range was 93000-93099.)

## Target BC Version
28.x (application/platform 28.0.0.0, runtime 17.0)

## Source Control
Platform: GitHub
Organization: businesscentralal
Repository: bc-origo-bifrost-nornir
Default branch: main

## Dependencies
- Bifrost Foundation (`7505e808-6e52-4b96-a328-82573391297a`, 28.0.0.0) - the only AL dependency.
  Nornir does **not** depend on Bifrost Bragi (chat, language models, MCP Tool Server).

## Naming Rules
- Every object carries the `ori` suffix (AppSource mandatory affix), max 30 characters.
- The brand name "Bifrost" lives in the namespace, the app name, the permission sets
  (`BIFROST Nornir ori`, `BIFROST NrnSetup ori`, `BIFROST NrnMgt ori`, `BIFROST PlaybAdm ori`,
  `BIFROST PlaybVw ori`) and in user-facing captions - never as an object-name prefix.
- The legacy `CE ` prefix is gone. Scheduling objects are named after what they do:
  `Scheduled Entry ori`, `Scheduler Setup ori`, `Scheduler Handler ori`, `Scheduler Mgt ori`,
  `Scheduler Events ori`, `Scheduler API Client ori`, `Scheduler Setup Wizard ori`, `Playbook ori`.
- Icelandic captions use "Bifröst".

## Development Standards

This project follows the **Origo BC Development Standards** (https://github.com/OrigoSoftwareSolutions/bc-dev-standards).

Before writing any AL code, load the relevant skills:
- **`bc-al-coding-standards`** - namespaces, XML docs, naming, formatting, performance, enums, Format/Evaluate, events, error handling, JSON, security
- **`bc-test-writer`** - test structure, AAA pattern, coverage checklists, mock patterns
- **`bc-documentation-writer`** - XML doc comments, markdown reference docs, help codeunits, sync rules

Agent context for this repository is in [AGENTS.md](../AGENTS.md).

Key rules always in effect:
- Namespace: `Origo.Bifrost.Nornir` at the top of every file
- XML documentation on every object and non-local procedure
- Bilingual captions (en-US + is-IS) on all user-facing text
- `SetLoadFields` on all record reads
- `Format(guid, 0, 4)` for GUIDs, `Format(value, 0, 9)` / `Evaluate(var, text, 9)` for culture-invariant serialization
- Never use `Format()` / `Evaluate()` on enum values - use `.Names()`, `.Ordinals()`, `.AsInteger()`, `.FromInteger()`
- Implementation = code + tests + documentation (help codeunit, HTML help)

## Development Environment
- Two COSMO Alpaca containers, both defined in `app/.vscode/launch.json` (git-ignored, the authority for
  instance ids): `launch: bc28-is` (Icelandic CRONUS IS, the legacy Cloud Events apps installed side by
  side, used for the MCP message-type tests) and `launch: bc28-w1` (W1, unit tests).
  Publish and run the unit tests on **both**; select the target with `-LaunchConfiguration 'launch: bc28-w1'`.
- Compile locally with alc.exe + CodeCop/UICop/AppSourceCop (symbols in `app/.alpackages`, test symbols in
  `test/.alpackages` including the freshly built Bifrost Foundation and Nornir .app files).
- Publish and test without VS Code (pwsh 7, credential from the user-level env vars `BC28IS_USER` /
  `BC28IS_PASSWORD`, never from files - never write them into files, commands or chat), using the shared
  tooling in the Foundation repo:
  `..\..\OrigoSoftwareSolutions\bc-origo-bifrost-core\tools\Publish-BifrostApp.ps1 -AppFile <.app>` and
  `..\..\OrigoSoftwareSolutions\bc-origo-bifrost-core\tools\Run-BifrostTests.ps1`.
  Both read the instance from `app/.vscode/launch.json`; check it matches the MCP server's baseUrl before
  publishing.
- `AppSourceCop.json` sets `mandatoryAffixes`/`mandatorySuffix` to `ori` and the supported countries
  (IS, GB, DK, NO, SE, FI, DE, FR, NL, AT, CH, IE, PT, ES). Command-line alc does not raise AS0011 here -
  AL-Go CI is the gate, so check affixes yourself.

## Message Type Conventions
- Enum extension `MsgType.EnumExt ori` (10035536) extends Foundation's `Message Type ori` with 20 values.
  Keys keep the `Orchestrator.*` prefix (and `Help.Orchestrator.Get` as the help directory) - they are the
  published external API contract and must never be renamed or removed.
- Each type has an `<Area> <Verb> Msg ori` impl codeunit implementing `Msg Interface ori`, usually
  delegating to a shared `<Area> Msg Handler ori` under `app/src/MessageTypes/<Area>/`, plus help text
  registered in `Help ori` and served through `Help.Orchestrator.Get`.
- Errors must be returned as `status = Error` with a helpful message through the Foundation argument;
  never let an unhandled exception reach the API.

## Playbook Conventions
- `Playbook Runner ori` walks the steps and creates a `Playbook Instance ori`;
  `Playbook Step Executor ori` resolves the request template against `Playbook Workspace ori` and calls
  `Msg Executor ori`.
- `Msg Executor ori` (10035603, `Access = Internal`, `SingleInstance`) is the **only** path from playbook
  code to Foundation's `Dispatcher ori`. It wraps the dispatch in a `Codeunit.Run` scope so a message type
  that commits or fails cannot abort the playbook run. Non-text responses are base64-encoded into a JSON
  envelope (`contentType`, `size`, `base64`).
- `Playbook Log Mgt ori` writes a `Playbook Step Log ori` per step with request, response and workspace
  snapshot. Retention policies for `Playbook Instance ori` and `Playbook Step Log ori` are registered by
  `App Install ori` / `App Upgrade ori`.
- The legacy field `Max Iterations` (field 71 on `Playbook Step ori`) was dropped on purpose - do not
  reintroduce it.

## Migration Notes
- Migrated 2026-09-05 from `Origo Cloud Events Orchestrator`
  (`D:\Git\Origo\OrigoSoftwareSolutions\bc-cloudevents-orchestrator`, still published and installed side by
  side) with the parameterised migration tooling in `bc-origo-bifrost-core/tools/migration/`.
- The chat integration was dropped: Foundation no longer contains the chat module (it moved to **Bifrost
  Bragi**), so the "Bifrost Chat" actions and chat FactBoxes were removed from `Playbooks ori`,
  `Playbook Card ori`, `Playbook Instances ori`, `Playbook Instance Card ori` and
  `Scheduled Entry Card ori`. Do not reintroduce chat or MCP Tool Server references.
- See [CHANGELOG.md](../CHANGELOG.md) for the full migration record.

## Testing Through the MCP Server
- `invoke_message_type` / `get_message_type_help` / `get_records` / `set_records` on the `origo-bc-bc28-is`
  server reach this app through Foundation (route `origo/bifrost/v1.0`). Keep calls serial - parallel
  bursts crash the server. Test data uses the `BIFT-<letter>` prefix in CRONUS IS.
- Telegram and Email message types need a configured Bot Token (Isolated Storage, `Scheduler Setup ori`),
  a Telegram Chat ID on `Bifrost User Setup`, and enabled HTTP client requests.

## Help
- Published help: https://origopublic.blob.core.windows.net/help/BifrostNornir/bc28/en-US/index.html
  (Icelandic under `is-IS`), context-sensitive help `.../BifrostNornir/bc28/{0}/`.
- HTML sources in `app/Help/en-US/` and `app/Help/is-IS/`, synced to blob storage by
  `.github/workflows/SyncHelpToBlob.yaml`.
