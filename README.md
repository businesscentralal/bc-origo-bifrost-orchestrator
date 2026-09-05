# Bifrost Nornir

**Publisher:** Origo
**Version:** 28.0.0.0
**Object ID range:** 10035535-10035634
**Namespace:** `Origo.Bifrost.Nornir`

Bifrost Nornir adds scheduling and orchestration on top of [Bifrost Foundation](https://github.com/OrigoSoftwareSolutions/bc-origo-bifrost-core). It manages Job Queue entries (register, run, restart, monitor, notify on failure) and runs **playbooks** - declarative, multi-step sequences of Bifrost message types with a shared workspace, `@path` data flow between steps, forEach iteration, conditional branching and paged execution. Everything the app does is also reachable as message types over the Bifrost queue API (`origo/bifrost/v1.0`), so an external system or an AI agent can drive a playbook the same way a scheduled Job Queue entry does.

This app is the successor of *Origo Cloud Events Orchestrator*. Version 28.0.0.0 is a full rebrand into a new AppSource app with a new object range; see [CHANGELOG.md](CHANGELOG.md) for the migration notes.

## Repository layout

| Folder | Content |
| --- | --- |
| `app/` | The AppSource app (`Bifrost Nornir`) |
| `app/src/JobQueue/` | Scheduled entries, scheduler setup and wizard, recurring templates, notifications, Job Queue extension objects, API pages |
| `app/src/Playbook/` | Playbook, step and condition tables, runner, step executor, workspace and JSON helper |
| `app/src/Log/` | Playbook instance and step log tables, log management |
| `app/src/Pages/` | Playbook, instance and template editor pages |
| `app/src/MessageTypes/` | Message type enum extension, implementations and help codeunits |
| `app/docs/` | AppSource submission material (user scenarios, Partner Center texts) |
| `app/Help/` | HTML help (en-US, is-IS) published to origopublic blob storage |
| `app/assets/playbooks/` | Sample playbook step templates |
| `test/` | Test app (`Bifrost Nornir - Tests`, range 96300-96399) |
| `.AL-Go/`, `.github/` | AL-Go for GitHub / COSMO Alpaca pipeline configuration |

## Message types

All 20 message types are registered in `app/src/MessageTypes/MsgTypeEnumExt.EnumExt.al`. The keys keep the `Orchestrator.*` prefix - they are the external API contract and carry no brand word.

| Area | Keys |
| --- | --- |
| Scheduled entry | `Orchestrator.Entry.Register`, `Orchestrator.Entry.Run`, `Orchestrator.Entry.Restart`, `Orchestrator.Entry.Schedule` |
| Status | `Orchestrator.Status.Get`, `Orchestrator.Status.Restart`, `Orchestrator.Status.RestartIfNeeded` |
| Job Queue entry | `Orchestrator.JobQueueEntry.Restart`, `Orchestrator.JobQueueEntry.RestartIfNeeded` |
| Playbook | `Orchestrator.Playbook.Run`, `Orchestrator.Playbook.Schedule`, `Orchestrator.Playbook.Enqueue`, `Orchestrator.Workspace.Preview` |
| Report | `Orchestrator.Report.List`, `Orchestrator.Report.Get`, `Orchestrator.Report.Run`, `Orchestrator.Report.SaveAs` |
| Delivery | `Orchestrator.Email.Send`, `Orchestrator.Telegram.Message` |
| Help | `Help.Orchestrator.Get` |

`Help.Orchestrator.Get` is the API directory: it returns the markdown contract of every type above, built from the `<Name> Help ori` codeunits.

## Permission sets

| Set | Purpose |
| --- | --- |
| `BIFROST Nornir ori` | Read access to scheduled entries, scheduler setup, recurring templates and credentials |
| `BIFROST NrnSetup ori` | Setup access - maintain scheduler setup, recurring templates and client credentials |
| `BIFROST NrnMgt ori` | Management access - maintain scheduled entries |
| `BIFROST PlaybAdm ori` | Full administration of playbooks, steps, conditions, instances and report presets |
| `BIFROST PlaybVw ori` | Read-only access to playbooks and execution logs |

## Development

- Open `al.code-workspace` in VS Code.
- Development containers: COSMO Alpaca `launch: bc28-is` (CRONUS IS) and `launch: bc28-w1` (W1), both in `app/.vscode/launch.json`.
- Standards: [Origo BC Development Standards](https://github.com/OrigoSoftwareSolutions/bc-dev-standards). Project rules are in `.claude/CLAUDE.md`; agent context is in [AGENTS.md](AGENTS.md).
- Every object carries the mandatory `ori` suffix; the brand name is carried by the namespace, not by object names.

## Documentation

- Help site: https://origopublic.blob.core.windows.net/help/BifrostNornir/bc28/en-US/index.html (Icelandic under `is-IS`), sources in `app/Help/`.
- Message type contracts: `Help.Orchestrator.Get`, or the help codeunits under `app/src/MessageTypes/Help/`.
- AppSource submission material: `app/docs/`.

<!-- AUTO-UPDATE-START -->
# COSMO Alpaca AL-Go AppSource App Template

[![Use this template](https://github.com/microsoft/AL-Go/assets/10775043/ca1ecc85-2fd3-4ab5-a866-bd2e7e80259d)](https://github.com/new?template_name=Alpaca-AppSource-Template&template_owner=cosmoconsult)

This template repository can be used for managing AppSource Apps for Business Central.

It is a customized version of the [AL-Go-AppSource](https://github.com/microsoft/AL-Go-AppSource) template and is designed to be used with [COSMO Alpaca](https://cosmoconsult.com/cosmo-alpaca).

> [!NOTE]
> If you created this repository using the GitHub web UI (for example by clicking **Use this template** on GitHub.com) instead of creating it from the COSMO Alpaca VS Code extension, you must initialize it using the [COSMO Alpaca VS Code extension](https://marketplace.visualstudio.com/items?itemName=cosmoconsult.cosmo-alpaca). To do this, simply right-click on the repository in VS Code and select _Initialize_.

Please go to https://aka.ms/AL-Go and [COSMO Docs](https://docs.cosmoconsult.com/en-us/cloud-service/alpaca) to learn more.
<!-- AUTO-UPDATE-END -->
