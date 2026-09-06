# Bifrost Nornir

**Publisher:** Origo &nbsp;|&nbsp; **Version:** 28.0.0.0 &nbsp;|&nbsp; **Object ID range:** 10035535-10035634 &nbsp;|&nbsp; **Namespace:** `Origo.Bifrost.Nornir`

Bifrost Nornir adds scheduling and orchestration on top of [Bifrost Foundation](https://github.com/OrigoSoftwareSolutions/bc-origo-bifrost-core). It manages Job Queue entries (register, run, restart, monitor, notify on failure) and runs playbooks - declarative, multi-step sequences of Bifrost message types with a shared workspace, `@path` data flow, forEach iteration, conditional branching and paged execution. Everything the app does is also reachable as a message type over the Bifrost queue API (`origo/bifrost/v1.0`), so an external system or an AI agent can drive a playbook the same way a scheduled Job Queue entry does.

This app is the successor of *Origo Cloud Events Orchestrator*; see [CHANGELOG.md](CHANGELOG.md) for the migration notes.

## Documentation

All public documentation lives in the [businesscentralal/bifrost](https://github.com/businesscentralal/bifrost) site repository - there are no `docs/` or `Help/` folders here.

- Product documentation: https://bifrost.origo.is/en-us/nornir/
- In-product help (context-sensitive help pages): https://bifrost.origo.is/en-us/help/nornir/
- Building on Bifröst: https://bifrost.origo.is/en-us/extensibility/

Message type contracts are also available at runtime through the `Help.Orchestrator.Get` message type, or in the help codeunits under `app/src/MessageTypes/Help/`.

## Repository layout

| Folder | Content |
| --- | --- |
| `app/` | The AppSource app (`Bifrost Nornir`) |
| `app/src/JobQueue/` | Scheduled entries, scheduler setup and wizard, recurring templates, notifications, Job Queue extension objects, API pages |
| `app/src/Playbook/` | Playbook, step and condition tables, runner, step executor, workspace and JSON helper |
| `app/src/Log/` | Playbook instance and step log tables, log management |
| `app/src/Pages/` | Playbook, instance and template editor pages |
| `app/src/MessageTypes/` | Message type enum extension, implementations and help codeunits |
| `app/assets/playbooks/` | Sample playbook step templates |
| `test/` | Test app (`Bifrost Nornir - Tests`, range 96400-96499) |
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
