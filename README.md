# Bifrost Orchestrator

**Publisher:** Origo &nbsp;|&nbsp; **Version:** 28.0.0.0 &nbsp;|&nbsp; **Object ID range:** 10035535-10035634 &nbsp;|&nbsp; **Namespace:** `Origo.Bifrost.Orchestrator`

Bifrost Orchestrator adds scheduling and orchestration on top of [Bifrost Foundation](https://github.com/OrigoSoftwareSolutions/bc-origo-bifrost-core). It manages Job Queue entries (register, run, restart, monitor, notify on failure) and runs playbooks - declarative, multi-step sequences of Bifrost message types with a shared workspace, `@path` data flow, forEach iteration, conditional branching and paged execution. Everything the app does is also reachable as a message type over the Bifrost queue API (`origo/bifrost/v1.0`), so an external system or an AI agent can drive a playbook the same way a scheduled Job Queue entry does.

This app is the successor of *Origo Cloud Events Orchestrator*; see [CHANGELOG.md](CHANGELOG.md) for the migration notes.

> The app was migrated under the working name *Bifrost Nornir* and renamed to **Bifrost Orchestrator** before its first release (repository `bc-origo-bifrost-nornir` -> `bc-origo-bifrost-orchestrator`). Message type keys never changed. The documentation slug is still `nornir` until the folders in the site repository are renamed.

## Documentation

All public documentation lives in the [businesscentralal/bifrost](https://github.com/businesscentralal/bifrost) site repository - there are no `docs/` or `Help/` folders here.

- Product documentation: https://businesscentralal.github.io/bifrost/en-us/nornir/
- In-product help (context-sensitive help pages): https://businesscentralal.github.io/bifrost/en-us/help/nornir/
- Building on Bifröst: https://businesscentralal.github.io/bifrost/en-us/extensibility/

(The `nornir` path segment is the current site slug, not the app name.)

Message type contracts are also available at runtime through the `Help.Orchestrator.Get` message type, or in the help codeunits under `app/src/MessageTypes/Help/`.

## Permissions

Five assignable permission sets ship with the app. **Each one has to be combined with a Bifröst Foundation permission set** (`BIFROST Full ori` or `BIFROST Read ori`): the message loop, the request log, `User Setup ori` and the secret store live in Foundation, and job queue scheduling additionally needs the base application's own Job Queue permissions.

| Permission set | Role | Grants |
| --- | --- | --- |
| `BIFROST Orchestr ori` | Full | Every table, page and codeunit the app owns |
| `BIFROST OrchSet ori` | Setup | Scheduler setup, client credentials, recurring templates and the setup wizard |
| `BIFROST OrchMgt ori` | Operations | Monitor, run and restart scheduled entries; read-only on setup and credentials |
| `BIFROST PlaybAdm ori` | Playbook admin | Author and run playbooks |
| `BIFROST PlaybVw ori` | Playbook viewer | Read playbooks and their execution log |

## Known issues

- **`Orchestrator.Entry.Register`** fails when it is called over the message-type API for a Job Queue Entry that is not yet a scheduled entry. `Scheduled Entry ori.InsertFromJobQueueEntry` opens a card page unconditionally for new entries, and Business Central's Data Services layer rejects that as a client callback. The defect is pre-existing - the identical code is in the predecessor app - and is **not** fixed in this release. Workaround: register the entry from the *Job Queue Entries* page (action *Add to Bifrost Orchestrator*), then use `Orchestrator.Entry.Schedule` / `Orchestrator.Entry.Run` over the API. Full analysis and the suggested fix are in `test/reports/Bifrost_Orchestrator_MessageType_TestReport_2026-09-05.md`.

## Repository layout

| Folder | Content |
| --- | --- |
| `app/` | The AppSource app (`Bifrost Orchestrator`) |
| `app/src/JobQueue/` | Scheduled entries, scheduler setup and wizard, recurring templates, notifications, Job Queue extension objects, API pages |
| `app/src/Playbook/` | Playbook, step and condition tables, runner, step executor, workspace and JSON helper |
| `app/src/Log/` | Playbook instance and step log tables, log management |
| `app/src/Pages/` | Playbook, instance and template editor pages |
| `app/src/MessageTypes/` | Message type enum extension, implementations and help codeunits |
| `app/assets/playbooks/` | Sample playbook step templates |
| `test/` | Test app (`Bifrost Orchestrator - Tests`, range 96400-96499) |
| `test/reports/` | Internal test reports (not published) |
| `.AL-Go/`, `.github/` | AL-Go for GitHub / COSMO Alpaca pipeline configuration |

## Development

- Open `al.code-workspace` in VS Code.
- Development containers: COSMO Alpaca `launch: bc28-is` (CRONUS IS) and `launch: bc28-w1` (W1), both in `app/.vscode/launch.json`.
- Build locally with `alc.exe` from the AL extension, using `app/.alpackages` as the package cache and the CodeCop, UICop and AppSourceCop analyzers. Zero errors and zero warnings is the bar.
- Publish and run the tests with `Publish-BifrostApp.ps1` / `Run-BifrostTests.ps1` from `bc-origo-bifrost-core/tools`.
- Standards: [Origo BC Development Standards](https://github.com/OrigoSoftwareSolutions/bc-dev-standards). Project rules are in `.claude/CLAUDE.md`; agent context is in [AGENTS.md](AGENTS.md).
- Every object carries the mandatory `ori` suffix; the brand name is carried by the namespace, not by object names.

<!-- AUTO-UPDATE-START -->
# COSMO Alpaca AL-Go AppSource App Template

[![Use this template](https://github.com/microsoft/AL-Go/assets/10775043/ca1ecc85-2fd3-4ab5-a866-bd2e7e80259d)](https://github.com/new?template_name=Alpaca-AppSource-Template&template_owner=cosmoconsult)

This template repository can be used for managing AppSource Apps for Business Central.

It is a customized version of the [AL-Go-AppSource](https://github.com/microsoft/AL-Go-AppSource) template and is designed to be used with [COSMO Alpaca](https://cosmoconsult.com/cosmo-alpaca).

> [!NOTE]
> If you created this repository using the GitHub web UI (for example by clicking **Use this template** on GitHub.com) instead of creating it from the COSMO Alpaca VS Code extension, you must initialize it using the [COSMO Alpaca VS Code extension](https://marketplace.visualstudio.com/items?itemName=cosmoconsult.cosmo-alpaca). To do this, simply right-click on the repository in VS Code and select _Initialize_.

Please go to https://aka.ms/AL-Go and [COSMO Docs](https://docs.cosmoconsult.com/en-us/cloud-service/alpaca) to learn more.
<!-- AUTO-UPDATE-END -->
