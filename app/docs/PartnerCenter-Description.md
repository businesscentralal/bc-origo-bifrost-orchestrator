# Description Text (for Partner Center rich editor)

**Bifrost Nornir** adds Job Queue scheduling, monitoring, restart and error handling to Business Central through the Bifrost platform — a message-based integration layer that gives external systems, AI agents, and automation tools structured access to Business Central data and procedures. It includes a declarative message playbook runner that executes sequences of Bifrost message types with data flow, forEach iteration, conditional branching, paged execution, and delivery via Email or Telegram.

### Who is this for?

**IT teams, integration developers, and Business Central administrators** who need reliable, automated Job Queue management and multi-step workflow orchestration. Ideal for organizations running scheduled integrations, recurring data synchronization, or automated document processing pipelines where monitoring, restart policies, and notification on failure are critical.

**Target industries:** Professional services, manufacturing, distribution, retail — any business that runs scheduled background jobs in Business Central.

### What it does

- **Job Queue scheduling and supervision** — Monitors, restarts, and manages Job Queue entries. Configurable retry policies, recurring templates, scheduling, and automatic restart on failure
- **Telegram & Email Notifications** — Sends alerts when jobs fail or restart. Telegram messages go to the user's configured chat ID; email uses BC's built-in email system
- **Message Playbooks** — Declarative, multi-step workflows that chain Bifrost message types. Each step calls one message type, with data flowing through a shared workspace using `@path` references
- **ForEach Iteration** — Playbook steps can iterate over arrays from prior steps, processing each element with its own message type call
- **Conditional branching** — Separate next steps on success and failure, skip-if-failed, and per-step start conditions
- **Paged Execution** — Playbook steps can auto-paginate through large datasets
- **Scheduled Playbooks** — Run playbooks on a recurring schedule via the Job Queue, or enqueue for one-time execution with custom parameters
- **Reports on demand** — List, inspect, render (PDF, Excel, Word, XML) and run processing-only reports, with reusable request presets
- **Execution log** — Every playbook run is recorded as an instance with a per-step log holding the request, the response and a workspace snapshot
- **Setup Wizard** — Guided setup for HTTP client requests, Job Queue configuration, and the Telegram bot token

### How it works

1. Register Job Queue entries as **scheduled entries** — Bifrost Nornir monitors and restarts them automatically
2. Configure **notification type** (None, Email, Telegram) per entry to get alerts on failure
3. Build **playbooks** by creating steps that call Bifrost message types in sequence, with request templates using `@` workspace references to pass data between steps
4. Run playbooks manually, on a schedule, or enqueue them for deferred execution

### Message Types (20)

| Category | Types |
|---|---|
| **Scheduled entries** | `Orchestrator.Entry.Register`, `Orchestrator.Entry.Run`, `Orchestrator.Entry.Restart`, `Orchestrator.Entry.Schedule` |
| **Status** | `Orchestrator.Status.Get`, `Orchestrator.Status.Restart`, `Orchestrator.Status.RestartIfNeeded` |
| **Job Queue** | `Orchestrator.JobQueueEntry.Restart`, `Orchestrator.JobQueueEntry.RestartIfNeeded` |
| **Playbook** | `Orchestrator.Playbook.Run`, `Orchestrator.Playbook.Schedule`, `Orchestrator.Playbook.Enqueue`, `Orchestrator.Workspace.Preview` |
| **Reports** | `Orchestrator.Report.List`, `Orchestrator.Report.Get`, `Orchestrator.Report.Run`, `Orchestrator.Report.SaveAs` |
| **Delivery** | `Orchestrator.Email.Send`, `Orchestrator.Telegram.Message` |
| **Help** | `Help.Orchestrator.Get` |

### Supported editions and countries

- **Editions:** Business Central Essentials and Premium
- **Countries:** Iceland, United Kingdom, Denmark, Norway, Sweden, Finland, Germany, France, Netherlands, Austria, Switzerland, Ireland, Portugal, Spain

### Requirements and prerequisites

- Microsoft Dynamics 365 Business Central 28.0 or later
- Bifrost Foundation extension (available separately on AppSource)
- For Telegram notifications: a Telegram Bot Token (created via @BotFather) and user Telegram Chat IDs configured in Bifrost User Setup
- For Email notifications: BC email account configured with an email scenario

### Help and documentation

https://origopublic.blob.core.windows.net/help/BifrostNornir/bc28/en-US/index.html (Icelandic help is available under `is-IS`).
