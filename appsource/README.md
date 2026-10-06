# AppSource offer: Bifrost Orchestrator

Everything to enter in Partner Center for this offer, page by page, as Microsoft's offer pages ask
for it (Business Central offer, checked 06.10.2026). Built from the app's main branch and the
documentation. No message type names, as on the public site. Review before publishing.

## Files in this folder

| File | Use | Partner Center page |
|---|---|---|
| `logo-216.png` | Large logo, PNG, in the style of Bifrost Foundation's | Offer listing › Logos |
| `screenshots/*.png` | 4 screenshots, 1280 × 720 PNG (3 to 5 required) | Offer listing › Screenshots |
| `description.html` | Description with the allowed HTML tags | Offer listing › Description |
| `description.txt` | The same as plain text | (for review) |
| `product-sheet.pdf` | One-page marketing sheet (1 to 3 PDFs required) | Offer listing › Supporting documents |

## 1. Offer setup

| Field | Value |
|---|---|
| Offer alias | Bifrost Orchestrator |
| Customer leads / listing option | Same as Bifrost Foundation |

## 2. Properties

| Field | Value | Subcategories |
|---|---|---|
| Primary category | Productivity | Workflow Automation |
| Secondary category | IT & Management Tools | Business Applications |
| Industry | (leave empty: not industry-specific) | |
| App version | The version of the `.app` you upload (the pipeline sets it) | |
| Terms and conditions (URL) | https://businesscentralal.github.io/bifrost/en-us/foundation/eula/ | |

## 3. Offer listing

| Field | Value | Length / limit |
|---|---|---|
| Name | Bifrost Orchestrator | 20 / 200 |
| Search results summary | Routines that run themselves: playbooks, schedules and a Job Queue that restarts itself. | 88 / 100 |
| Description | `description.html` | 1732 / 5,000 |
| Search keywords | Job Queue, Workflow automation, Playbook | 3 / 3 |
| Products your app works with | Dynamics 365 Business Central | 1 / 3 |
| Help link | https://businesscentralal.github.io/bifrost/en-us/orchestrator/ | must differ from Support URL |
| Privacy policy link | https://businesscentralal.github.io/bifrost/en-us/foundation/privacy/ | |
| Support contact (name, e-mail, phone, URL) | Same as Bifrost Foundation; Support URL https://www.origo.is/ | not shown to customers |
| Engineering contact | Same as Bifrost Foundation | not shown to customers |
| Supporting documents | `product-sheet.pdf` | 1 to 3 PDFs |
| Logo | `logo-216.png` | PNG |
| Screenshots | see below | 3 to 5, 1280 × 720 PNG |
| Videos | optional; none yet | up to 4 |

Help and privacy links follow the app's `app.json` (`/foundation/...` redirects to `/licensing/...`),
as `bifrost-support/DOCUMENTATION-RULES.md` asks. The app's page on the documentation site only
appears once the app is published there; until then, use Foundation's page or publish the docs at
the same time.

Microsoft's logo guidance says no text on the logo; Bifrost Foundation's logo has text, so this one
follows Foundation for a consistent family.

### Screenshots and captions

| File | Caption |
|---|---|
| `screenshots/01-playbooks.png` | Your routines as playbooks, ready to run or schedule. |
| `screenshots/02-playbook.png` | A playbook is a list of steps; one step's answer feeds the next. |
| `screenshots/03-execution-log.png` | Every run is kept, with status, duration and the items it processed. |
| `screenshots/04-setup.png` | Job Queue supervision and Telegram alerts in one setup page. |

Taken in the Bifrost sandbox (CRONUS demo company, demo data), 06.10.2026. The company name, user
names, e-mail addresses and IDs were replaced before capture.

## 4. Availability

Markets: the same as Bifrost Foundation.

## 5. Technical configuration

Upload the app's `.app` file from the release build. Dependency: Bifrost Foundation.

## 6. Supplemental content

| Field | Value |
|---|---|
| Supported editions | Essentials and Premium |
| Key usage scenario, test accounts, test app | No longer used in validation (Microsoft); leave empty unless Partner Center requires it |

## Description (as in `description.txt`)

```
Routines that run themselves, and a Job Queue that looks after itself.

Bifrost Orchestrator turns a routine into a playbook, runs it when it should, and tells you when something fails. It is an add-on to Bifrost Foundation.

Who it is for
Business Central administrators and finance or operations teams with recurring work, and partners who build automated routines for their customers.

What it does
- Turns a routine into a playbook: a list of steps where one step's answer feeds the next. List the overdue orders, release them, tell the right person. No code.
- Runs it when it should: by hand, on a schedule through the Job Queue, or when an assistant or another system asks.
- Looks after the Job Queue: watches entries, restarts them when they fail and retries by the rules you set.
- Tells you when it matters: an email or a Telegram message when a job fails or restarts.
- Shows what happened: every playbook run is kept step by step, with what each step was sent and what it answered.
- Runs reports on demand: list, run and save reports as PDF, Excel or Word.

Requirements and pricing
- Microsoft Dynamics 365 Business Central 28.0 or later, Essentials or Premium.
- Bifrost Foundation, available separately on AppSource.
- For prices, contact Origo (https://www.origo.is/) or your Business Central partner.
- If you are a partner, contact The App Channel (https://www.theappchannel.com/).

Bifrost Orchestrator does not replace Business Central or its extensions. It makes their data and business logic available to the people, routines and AI platforms your organisation already uses.
```

---
Drafted with the help of Claude (Anthropic); review before publishing. Origo's AI policy (STE-0002):
the person who publishes is responsible for the content.
