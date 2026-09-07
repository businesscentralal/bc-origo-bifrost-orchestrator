# Extension: Bifrost Orchestrator

> Renamed 2026-09-06 from **Bifrost Nornir** (repository `bc-origo-bifrost-nornir`) to the
> descriptive name **Bifrost Orchestrator** (repository `bc-origo-bifrost-orchestrator`).
> Message-type keys (`Orchestrator.*`, `Help.Orchestrator.Get`) were already descriptive and
> did not change.

## Prefix
(none - objects use raw names with the mandatory `ori` suffix inside the `Origo.Bifrost.Orchestrator` namespace)

## Namespace
Origo.Bifrost.Orchestrator (tests: Origo.Bifrost.Orchestrator.Test)

## Object ID Range
App:   10035535-10035634 (migrated from the legacy Orchestrator range 10076035-10076134, offset -40500)
Tests: 96400-96499 (moved 2026-09-05 from the originally proposed 96300-96399: that block
  collides with the still-unregistered `Cloud Events Gagnatorg - Tests` app, which also occupies
  96300-96399 on bc28-is/bc28-w1. Legacy Orchestrator test range was 93000-93099.)

### Object IDs in use / free
- Used app ids: 10035535-10035556, 10035559-10035562, 10035566-10035568, 10035570-10035572,
  10035574, 10035576, 10035579, 10035581-10035606.
  **Free: 10035557-10035558, 10035563-10035565, 10035569, 10035573, 10035575, 10035577-10035578,
  10035580, 10035607-10035634.**
  (10035606 = codeunit `Secrets ori`, added 2026-09-06 for the secret store migration.)
- Used test ids: 96400-96404, 96410-96422, 96450-96451.
  **Free: 96405-96409, 96423-96449, 96452-96499.**
  (96403 = codeunit `Orchestr Secret Tests`, added 2026-09-06; 96404 = codeunit `Test Upgrade`;
  96450 = table `Test Run Marker` and report `Test Process Report`; 96451 = report
  `Test Failing Report`.)
- Nothing was freed by the secret store migration: only table fields were removed
  (`Scheduler Setup ori` field 60, `Client Credentials ori` fields 30 and 40), no objects.

## Setup Page and Secrets (Bifröst platform rules)
- The page extension on Foundation's `Setup ori` (`Setup JQ ori`, 10035537) contains **one action
  only** - `addlast(Apps)` opening page `Scheduler Setup ori`, plus its actionref in
  `addlast(Category_Apps)`. No layout changes, no other action group, no notification and **no
  `ContextSensitiveHelpPage` override** - that property belongs to Foundation's own page.
- `Scheduler Setup ori` (page 10035536, caption *Bifrost Orchestrator Setup*, help slug `nornir-setup`) is
  the application setup page. It hosts the navigation to Playbooks, Client Credentials, the Playbook
  Execution Log and `App Secrets ori` (filtered with `SetAppFilter(GetAppId())`), and it carries the
  HTTP/job-queue setup notification in its own `OnOpenPage`.
- **Secrets live in the Foundation secret store**, never in app-private IsolatedStorage. Codeunit
  `Secrets ori` (10035606, `Access = Internal`) is the only place that composes secret codes and calls
  `Secret Store ori`. Codes, all scope `Company`:

  | Code | Value |
  |---|---|
  | `TELEGRAM-BOT-TOKEN` | Telegram bot token |
  | `CREDENTIAL-<CODE>-CLIENT-ID` | OAuth 2.0 client id of a `Client Credentials ori` record |
  | `CREDENTIAL-<CODE>-CLIENT-SECRET` | OAuth 2.0 client secret of that record |

  `<CODE>` is the record code uppercased. The composed code must fit `Code[50]`, which leaves 25
  characters; a longer record code is shortened to its first 16 characters + `-` + the first 8 hex
  digits of its SHA256 hash, so long codes sharing a prefix stay distinct.
- `RegisterAll()` runs from `App Install ori`, `App Upgrade ori` and `Scheduler Setup ori.OnOpenPage`;
  `Register` is idempotent. `Client Credentials ori` registers on insert, moves both values on rename
  and clears both on delete.
- Pages never show or edit a secret. They show a non-editable **Set** / **Not set** status and offer
  *Set …* / *Clear …* actions calling `SetFromDialog`. The old masked fields and the `'***'` sentinel
  are gone.

### Deviations from the shared secret contract
- `Scheduler API Client ori` does **not** use codeunit `OAuth2`: every overload types the client id as
  `Text`, a stored secret is only available as `SecretText`, and `SecretText.Unwrap` is `OnPrem` only.
  The client credentials grant is therefore posted directly to the Entra token endpoint with a form
  body built by `SecretStrSubstNo`. Trade-off: Microsoft's MSAL token handling is not used (the app
  keeps its own 3500-second cache) and the access token from the JSON response is briefly a `Text`
  inside the `[NonDebuggable]` parsing procedure.

## Target BC Version
28.x (application/platform 28.0.0.0, runtime 17.0)

## Source Control
Platform: GitHub
Organization: businesscentralal
Repository: bc-origo-bifrost-orchestrator
Default branch: main

## Dependencies
- Bifrost Foundation (`7505e808-6e52-4b96-a328-82573391297a`, 28.0.0.0) - the only AL dependency.
  Bifrost Orchestrator does **not** depend on Bifrost Bragi (chat, language models, MCP Tool Server).

## Naming Rules
- Every object carries the `ori` suffix (AppSource mandatory affix), max 30 characters.
- The brand name "Bifrost" lives in the namespace, the app name, the permission sets
  (`BIFROST Orchestr ori`, `BIFROST OrchSet ori`, `BIFROST OrchMgt ori`, `BIFROST PlaybAdm ori`,
  `BIFROST PlaybVw ori`) and in user-facing captions - never as an object-name prefix.
- Permission-set object names have a hard 20-character ceiling (the `Role ID` is `Code[20]`).
  `BIFROST OrchSetup ori` would be 21, so the setup role is `BIFROST OrchSet ori`.
- Icelandic brand form: the app is **Bifröst stjórnandi** (genitive *Bifröst stjórnanda*,
  accusative *Bifröst stjórnandann*). English: **Bifrost Orchestrator**.
- The documentation slug stays `nornir` (`help`, `contextSensitiveHelpUrl`,
  `ContextSensitiveHelpPage = 'nornir-setup'`) until the folders under
  `businesscentralal/bifrost` are renamed. Do not change the slugs before the site is renamed -
  the published help pages would 404.
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
- Namespace: `Origo.Bifrost.Orchestrator` at the top of every file
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
  `test/.alpackages` including the freshly built Bifrost Foundation and Bifrost Orchestrator .app files).
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
- Telegram and Email message types need the `TELEGRAM-BOT-TOKEN` secret (Bifröst secret store, entered
  on Bifrost Orchestrator Setup), a Telegram Chat ID on `Bifrost User Setup`, and enabled HTTP client requests.

## Documentation
- Documentation lives in businesscentralal/bifrost (site bifrost.origo.is); no Help/ or docs/ folders in
  this repo - deviation from the Origo PR gateway check 8 approved by the user 2026-09-06.
- `app.json` points at `https://businesscentralal.github.io/bifrost/en-us/nornir/` (help) and
  `https://businesscentralal.github.io/bifrost/{0}/help/nornir/` (context-sensitive help).
- `ContextSensitiveHelpPage` values are Docusaurus slugs without the `.html` extension - each one must
  match a page under `help/nornir/` in the site repo.
