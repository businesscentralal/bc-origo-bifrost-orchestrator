# Origo BC — PR Gateway Report

```
╔══════════════════════════════════════════════════════════════════╗
║           Origo BC — PR Gateway Report                           ║
║           Extension : Bifrost Orchestrator v28.0.0.0             ║
║           Customer  : Origo (AppSource, Bifröst portfolio)       ║
║           Date      : 2026-09-07 03:35                           ║
║           Tier      : Standard (AppSourceCop.json, no stories/)  ║
║           Branch    : feature/bifrost-nornir-migration → main    ║
╠══════════════════════════════════════════════════════════════════╣
║  LAYER 1 — Automated Script (23 checks)                          ║
║  Files scanned: 111    Passed: 8/23     Failed: 15               ║
║  After agent triage: 47 real findings — 45 fixed, 2 open,        ║
║                      348 dismissed as false positives            ║
╠══════════════════════════════════════════════════════════════════╣
║  LAYER 2 — Agent Deep Checks         Result                      ║
╠══════════════════════════════════════════════════════════════════╣
║  1.  AL Compiler                     ✅ Pass  (0 err / 0 warn)   ║
║  2.  Object Naming — Affix           ✅ Pass                     ║
║  3.  Object ID Ranges                ✅ Pass                     ║
║  4.  SetLoadFields — Exceptions      ✅ Pass  (9 fixed)          ║
║  5.  Breaking Change Guard           ⏭ Skip (initial phase)      ║
║  6.  app.json — Semantic             ⚠️ Pass w/ 2 deviations     ║
║  7.  CHANGELOG & README Quality      ⚠️ Was ❌ — rebuilt         ║
║  8.  HTML Help Pages                 ⚠️ Deviation + 1 warning    ║
║  9.  Documentation Generation        📝 Done                     ║
║  10. Unit Tests                      ✅ Pass  (154/154 × 2)      ║
║  11. Story-Doc Consistency           ⏭ Skip (no stories/)        ║
║  12. Logic Review                    🔍 5 findings               ║
║  13. What I Couldn't Check           🔍 5 gaps noted             ║
║  14. Role Coverage                   ❌ Fail (2 empty roles)     ║
║  15. Platform Integration            ⏭ Skip (not standards repo) ║
╠══════════════════════════════════════════════════════════════════╣
║  Overall : ✅ 6 passed  ❌ 1 failed  ⚠️ 3 warnings  ⏭ 3 skipped  ║
╚══════════════════════════════════════════════════════════════════╝
```

Target branch `main` detected from `.claude/CLAUDE.md` (`Default branch: main`) and confirmed
against the open PR #1. The branch is the whole migration from *Origo Cloud Events Orchestrator*
(152 files, ~25 600 insertions), so Layer 1's diff mode covers essentially the entire app.

---

## Layer 1 — Automated scan, with agent triage

The script reports 15 failed checks over 395 raw findings. Every finding was read against the
source. The table records what was real and what was dismissed, with the reason.

| Check | Raw | Real | Disposition |
| --- | ---: | ---: | --- |
| `set_load_fields` | 107 | 9 | **9 fixed.** The 98 dismissed break down as 41 JSON/Dictionary/List `.Get()` calls that are not record reads at all, 28 whole-record hand-offs (`Page.Run`, base-app APIs, procedures that consume every field), 11 `Get`/`Find` followed by a write, 8 narrow system tables where the gain is nil, 6 `RecordRef` migration reads with dynamic `FieldRef` access, 3 scanner artifacts, and 1 where a partial load would break a later full-record `Get` on the same variable. |
| `xml_doc_comments` | 103 | 29 | **29 fixed.** 66 dismissed are `internal` procedures implementing `Msg Interface ori` (60) or `Notification ori` (6) — the interface carries the contract, and both interfaces are fully documented. The other 8 already had a doc block; the scanner is blinded by a `[NonDebuggable]` attribute sitting between the `///` and the signature. |
| `one_statement_per_line` | 66 | 0 | Every hit is a procedure signature; the scanner counts the parameter separator `;` as a statement separator. |
| `read_isolation` | 43 (20 unique) | 5 | **5 fixed.** Dismissed: 6 `IsEmpty()`/`DeleteAll()`/`ModifyAll()` probes that read no fields, 2 virtual `Time Zone` reads, 2 report-metadata reads, 2 update paths that write inside the loop, 2 probes whose variable is later reused for a full `Get`, and 1 install-time migration that inserts into the same table inside the loop. |
| `caption_translation` | 21 | 1 | **1 fixed** (`Notif. Type ori` value `Telegram`). The other 20 are the `Orchestrator.*` message-type keys, all already `Locked = true` — they are the public wire contract and must not be translated. |
| `page_code_minimal` | 18 | 2 | **2 open** — see Check 12. 15 dismissed are wizard step transitions, single delegating calls with `CurrPage.Update`, confirm-then-delegate actions and standard file up/download plumbing. 1 is a scanner artifact: its trigger-body scan is not bounded by `begin…end`, so it attributed a `Rec.Modify` from a different procedure to `OnAfterGetRecord`. |
| `modernization` | 14 | 0 | Substring matches only: "Timer" inside `TimeRange`, "NAS" inside `OnAssistEdit` / `GetTokenAsText` / the Icelandic caption "Upprunaskref", and `MOD-AUTH-001` matching Bifröst's own `"User Setup ori"` table rather than the legacy base-app auth pattern. |
| `namespace` | 7 | 0 | All seven declare `namespace Origo.Bifrost.Orchestrator;` — the scanner only looks at the first line and these files open with an XML doc header. Verified across all 111 files: none is missing a namespace. |
| `hardcoded_values` | 7 | 0 | Five GUIDs are notification ids (the standard BC pattern, which requires a stable literal), the legacy app id in `App Takeover ori` (which cannot be looked up) and this app's own management job-queue GUID. The two "emails" are `user@company.is` inside Markdown help text. |
| `try_prefix_convention` | 3 | 1 | **1 fixed**: `TryPopulateTelegramChatId` was a `local procedure` returning nothing — the `Try` prefix is reserved for `[TryFunction]`, so it is now `PopulateTelegramChatId`. `Secrets ori.TryGetClientId` / `TryGetClientSecret` are kept: both return `Boolean` and deliberately mirror the Foundation contract they wrap, `Secret Store ori.TryGet`. |
| `format_guid` | 2 | 0 | `App Upgrade ori` deletes the legacy IsolatedStorage key under **both** formats on purpose (the removed code wrote it with braces); the other is `Format()` on a `JsonToken`, not a GUID. |
| `global_variables` | 1 | 0 | `Playbook Runner ori` holds 7 globals because it is the step-walking state machine; the alternative is threading them through every procedure. |
| `commit_in_loop` | 1 | 0 | `Scheduler Handler ori:132` commits once per scheduled entry on purpose, so a failure on one entry does not roll back the scheduling of the ones before it. |
| `format_evaluate_enum` | 1 | 0 | The hit is a comment. **But see Check 12 — reading the code found three real `Format()`-on-enum sites the scanner missed, one of them in a published API response.** |
| `today_vs_workdate` | 1 | 0 | `Playbook Workspace ori.SeedSystemConstants` seeds both `_sys.today` (real today) and `_sys.workDate` (`WorkDate()`) so a playbook author can choose. |

Re-running the script after the fixes: `xml_doc_comments` 103 → 75, `set_load_fields` 107 → 96,
`read_isolation` 43 → 38, `try_prefix_convention` 3 → 2. The remaining counts are the dismissed
false positives listed above.

---

## Check 1 — AL Compiler

Both projects compile with CodeCop + UICop (+ AppSourceCop on the app), **zero errors and zero
warnings**, before and after every change in this review.

| Project | Files | Analyzers | Result |
| --- | ---: | --- | --- |
| `app` | 111 | CodeCop, UICop, AppSourceCop | 0 / 0 |
| `test` | 21 | CodeCop, UICop | 0 / 0 |

---

## Check 2 — Object naming and affix

110 objects in `app/src`, 21 in `test`. Every app object carries the mandatory ` ori` suffix, and
no name exceeds 30 characters. Test-app objects carry no suffix — an approved deviation.
Command-line `alc` does not raise AS0011 here, so the affix was verified by hand across all 110
objects; AL-Go CI remains the real gate.

---

## Check 3 — Object ID ranges

All app objects fall inside 10035535–10035634 and all test objects inside 96400–96499. No
same-type id is used twice.

| | Used blocks | Free |
| --- | --- | --- |
| App | 10035535–556, 559–562, 566–568, 570–572, 574, 576, 579, 581–606 | 10035557–558, 563–565, 569, 573, 575, 577–578, 580, **10035607–634** |
| Tests | 96400–404, 96410–422, 96450–451 | 96405–409, 96423–449, 96452–499 |

⚠️ `.claude/CLAUDE.md` had drifted: it listed the test block as "96400-96403 and 96410-96422" and
declared 96404 and 96450–96451 free, but codeunit `Test Upgrade` (96404), table `Test Run Marker`
and report `Test Process Report` (both 96450) and report `Test Failing Report` (96451) are in use.
It also flattened the eleven interior gaps in the app range. **Corrected.**

---

## Check 5 — Breaking Change Guard

⏭ **Skipped.** Profile `appsource` (`AppSourceCop.json` carries `mandatoryAffixes` and
`supportedCountries`), phase **initial** — the file has no `version` baseline because the app has
never been released. There is nothing to break against. No ruleset file exists, so AppSourceCop
runs with its default actions; that is consistent with the rest of the portfolio.

---

## Check 6 — app.json: two deviations

Everything mandatory is present and semantically correct: `id` matches `.claude/CLAUDE.md`,
publisher `Origo`, version `28.0.0.0`, `target: Cloud`, application/platform `28.0.0.0`, runtime
`17.0`, `idRanges` `10035535–10035634` matching both the registry and every object in the app,
`internalsVisibleTo` pointing at the test app, and `applicationInsightsConnectionString` set (the
modern replacement for `applicationInsightsKey`).

- ⚠️ **`EULA` points at `https://www.origo.is/skilmalar-og-oryggismal`** — Origo's general terms
  and security page rather than an app-specific or Bifröst-specific EULA. (Note: this is *not* the
  Cloud Events Terms of Use PDF that `bc-origo-bifrost-attachments` still carries; this app already
  moved off it.) **Needs a decision before AppSource submission.**
- ✅ **`help` and `contextSensitiveHelpUrl` use `businesscentralal.github.io`** instead of
  `bifrost.origo.is`. Approved: the DNS record does not exist yet, and the URLs move with it.
- ✅ **Fixed:** `suppressWarnings` listed `AS0084` alongside `AS0081`. Compiling with the
  suppressions removed shows only AS0081 firing (the `internalsVisibleTo` advisory) — `AS0084` was
  a dead suppression carried over from the test app's `app.json`, where the rest of the portfolio
  keeps it. Removed.

---

## Check 7 — CHANGELOG and README

**README was the worst result in this review.** Eight of the ten mandatory sections were missing
outright, including the entire Objects table. It has been rebuilt against the template.

| | Before | After |
| --- | --- | --- |
| Mandatory sections | 2 of 10 | 10 of 10, in order |
| Objects table | absent | **111 rows, reconciled both directions against `app/src`** |
| Dependencies table | absent | present, matches `app.json` |
| Header facts | App ID and Environments missing | complete |
| Copyright | absent | © 2026 Origo ehf. |
| Doc links | ✅ already external | unchanged |

Objects reconciliation: every one of the 111 objects in `app/src` appears exactly once in the
table, and no table row names an object that does not exist — 11 tables, 2 table extensions, 26
pages, 4 page extensions, 6 enums, 3 enum extensions, 1 interface, 53 codeunits, 5 permission sets.
The stale prose note about the working name *Bifrost Nornir* was removed (that history belongs in
the CHANGELOG, which already carries it); every `nornir` **slug** in a URL was deliberately kept.

CHANGELOG:

- Version heading was `## [28.0.0.0] - 2026-09-05` while its own content was dated 09-06 and the
  last commit was 09-06 18:22 — moved to `2026-09-07`.
- The Keep a Changelog preamble was missing; added.
- `### Added` was missing entirely, on the first release of an app introducing 111 objects, 20
  message types and the playbook engine. Added.
- Two entries were **factually wrong**: one still asserted the old
  `origopublic.blob.core.windows.net` help URL and `app/Help/en-US/` sources, contradicted by a
  later entry in the same file, by `app.json` and by the absence of those folders on disk; another
  described HTML help files that were subsequently removed. Both rewritten as superseded history.
- No `[DRAFT]` markers; heading levels were already consistent.
- New `### Security` and `### Fixed` / `### Changed` sections record this review's changes, and
  two new entries were added to `### Known Issues` (see Check 12).

---

## Check 8 — Help pages: approved deviation, one open dependency

The repository holds no `Help/` or `docs/` folder — approved deviation, all public documentation
lives in `businesscentralal/bifrost`. All 15 `ContextSensitiveHelpPage` slugs were resolved
against that site repository, in both languages, with the front-matter `id` checked on each of the
30 files.

| Slug | Page(s) | en-US | is-IS | Site branch |
| --- | --- | :---: | :---: | --- |
| `nornir-setup` | Scheduler Setup ori | ✅ | ✅ | ⚠️ `setup-pattern-help` only |
| `credentials-card`, `credentials-list` | Credentials Card/List ori | ✅ | ✅ | `main` |
| `job-queue-entries`, `job-queue-entry-card` | the two Job Queue page extensions | ✅ | ✅ | `main` |
| `playbooks`, `playbook-card`, `playbook-instances`, `playbook-instance-card` | the playbook pages | ✅ | ✅ | `main` |
| `recurring-template`, `recurring-templates` | Recurring Template(s) ori | ✅ | ✅ | `main` |
| `report-preset-card`, `schedule-playbook`, `scheduled-entry-card`, `scheduler-setup-wizard` | the remaining cards | ✅ | ✅ | `main` |

⚠️ **`nornir-setup` is not on the site's `main` branch yet.** Both language versions exist and
declare `id: nornir-setup`, but only on branch `setup-pattern-help` in `bifrost-setup-help`. On
`main` the nearest pages are `scheduler-setup.md` and `setup-jq.md`, neither of which resolves the
route. Until that branch merges and the site rebuilds, the Help button on the Bifrost Orchestrator
Setup page 404s. **Merge the site branch with — or before — this PR.**

✅ The page extension on Foundation's Setup page declares no `ContextSensitiveHelpPage`, as the
project rules require. The 15 pages without one are all legitimately exempt: 5 API pages, 8
ListParts/CardParts that inherit help from their host, and 2 extensions of Foundation pages.

ℹ️ Three pages on the site's `main` (`scheduler-setup`, `setup-jq`, `scheduled-entry-api`, each in
both languages) are referenced by no AL object and become dead routes once the branch merges.

---

## Check 9 — Documentation

- **XML docs** — 29 non-local procedures had none. All 29 documented, matching the surrounding
  house style, with `<param>` and `<returns>` throughout. Compiles 0/0.
- **README** — rebuilt; see Check 7.
- **CHANGELOG** — corrected and extended; see Check 7.
- **`.claude/CLAUDE.md`** — object-id inventory corrected; see Check 3.

---

## Check 10 — Unit tests

| Container | Company | Codeunits | Tests | Passed | Failed |
| --- | --- | ---: | ---: | ---: | ---: |
| `bc28-is` (`f068155f0c39dev`) | CRONUS IS | 13 | 154 | **154** | 0 |
| `bc28-w1` (`f089d7daffb9dev`) | CRONUS International Ltd. | 13 | 154 | **154** | 0 |

App and test app were rebuilt and published to both containers with `SchemaUpdateMode=Synchronize`
before the runs. Baseline was 153; this review took it to 154.

**Coverage added:**

- `DeletingACredentialLeavesNoMissingSecretsBehind` — creates a credential with no values, deletes
  it, and asserts `CountMissingSecrets()` is back where it started. This is the regression test for
  the secret-registration leak below.
- `DeletingACredentialClearsItsSecrets` — **stale test, corrected.** It asserted
  `'The client id registration must survive the delete'`, encoding the very bug that was fixed. It
  now asserts both registry rows are removed along with the values.
- `RenamingACredentialMovesItsSecrets` — extended to assert the old registrations are unregistered,
  not merely emptied.
- `RunReturnsErrorObjectWhenReportFails` — **stale test, corrected.** It asserted the call stack was
  returned; it now asserts the opposite, which is the point of the security fix in Check 12.

ℹ️ The mirror case — Request Debug Mode **on**, call stack present — is deliberately not a unit
test. Switching the flag on makes Foundation's `Request Logger ori` write inside the test
transaction, which is exactly the isolation breakage that `Test Install.DisableRequestDebugMode`
exists to prevent; the run aborts with *"An error occurred and the transaction is stopped."* That
branch needs an MCP message-type run instead. This was verified empirically, not assumed.

---

## Check 12 — Logic review

```
╭──────────────────────────────────────────────────────────────╮
│  What this branch does:                                      │
│  Migrates Origo Cloud Events Orchestrator to Bifrost         │
│  Orchestrator — new identity and object range, the ` ori`    │
│  affix, the chat integration dropped, and the app's secrets  │
│  moved into the Bifröst Foundation secret store.             │
╰──────────────────────────────────────────────────────────────╯
```

Deep-reviewed the post-migration work, which is where the genuinely new logic is: `Secrets ori`,
`App Takeover ori`, `App Upgrade ori`, `Scheduler Setup ori`, `Credentials Card ori`,
`Client Credentials ori` and `Scheduler API Client ori`. Inferred acceptance criteria, since the
project uses no `stories/` folder.

| AC | Criterion | Result |
| --- | --- | --- |
| 1 | A secret value never reaches a table, log, error or telemetry dimension | ✅ |
| 2 | Composed secret codes always fit `Code[50]` and stay distinct | ✅ |
| 3 | Secrets follow their credential record through insert, rename and delete | ⚠️ Bug |
| 4 | The take-over survives schema drift between environments | ✅ |
| 5 | Pre-release IsolatedStorage keys are cleaned up on upgrade | ✅ |
| 6 | Message-type responses carry invariant values, not localised captions | ⚠️ Bug |
| 7 | An upgrade does not silently widen the tenant's attack surface | ⚠️ Bug |

**Findings (5):**

- ⚠️ **AC-3 — Logic. Deleting or renaming a credential leaked a permanent false alarm. Fixed.**
  `Client Credentials ori.OnDelete` and `Secrets ori.RenameCredential` both called
  `ClearCredential`, which wipes the values but deliberately keeps the registry rows. Since
  `CountMissingSecrets()` counts registered secrets that have no value, and
  `Scheduler Setup ori.OnOpenPage` raises a "secrets missing" notification from that count, every
  deleted or renamed credential left two rows that would be reported as missing for ever — for a
  credential nobody can enter a value for, because the record is gone. Foundation already provides
  the right call and its own documentation says so: *"Call it from the OnDelete trigger of the
  record that owns the secret registration, so the registry does not accumulate rows for secrets
  nobody uses any more."* Added `Secrets ori.UnregisterCredential` and wired both call sites to it.
  Corroborating evidence that this was a real leak: the test suite already carried a
  `DeleteRegistration` helper to clean up after itself.

- ⚠️ **AC-6 — Logic. A published API response returned a localised caption. Fixed.**
  `Orchestrator.Playbook.Run` returned `playbookStatus` via `Format(Instance.Status)`, which yields
  the enum's *caption* — `"Lokið"` on an is-IS tenant instead of `"Completed"`. The app already has
  the correct helper, `Playbook Workspace ori.StatusToText`, whose own doc comment warns about
  exactly this. `Playbook Step Executor ori` had the same problem writing the message type into the
  request log; both now use the helpers. Layer 1's `format_evaluate_enum` check missed both — its
  only hit was a comment.

- ⚠️ **AC-7 — Security. An upgrade silently re-enabled outbound HTTP. Fixed.**
  `App Upgrade ori.OnUpgradePerCompany` set `NAV App Setting."Allow HttpClient Requests" := true`.
  That flag is the administrator's consent switch; an admin who turned it off had it turned back on
  by the next upgrade, with no dialog and no trace. The setup wizard already does this the right
  way — user-initiated and gated. Removed; the setup page and wizard both detect the disabled state
  and offer to enable it, and every outbound caller checks it first.

- 👁 **Blindspot — Trust. `Orchestrator.Entry.Run` reports success without running anything.**
  Not fixed; needs a design decision. `SE Msg Handler ori.ExecuteRun` delegates to
  `Scheduler Mgt ori.RunJobQueueEntryOnce`, whose first statement is
  `if not ConfirmManagement.GetResponseOrDefault(RunOnceQst, false) then exit;`. Microsoft's
  implementation is `if not IsGuiAllowed() then exit(DefaultButton);` — verified in the System
  Application symbols — so in a web-service session the answer is the default, `false`, and the
  procedure returns before creating the throwaway Job Queue Entry. `ExecuteRun` then responds with
  `ExecutedMsg` regardless. Even if the confirm defaulted to `true`, the next statement is
  `Window.Open`, a client callback the Data Services layer rejects — the same failure mode as the
  documented `Orchestrator.Entry.Register` defect. **The message-type test run of 2026-09-05
  recorded this type as "✅ Success" because it read the response envelope rather than checking
  that the job had run.** Recorded as a Known Issue. The fix is a GUI-free path through
  `RunJobQueueEntryOnce`, which is shared with the pages, so it needs a signature change and its
  own test.

- 👁 **Blindspot — Impact Radius. Two page actions carry business logic.** Not fixed; these are the
  two surviving `page_code_minimal` findings and both are pre-existing migrated code.
  `Sched. Entry Subform ori:211` (`ScheduleNow`) chooses between two different reschedule
  strategies in UI code depending on whether `ApiClient.Initialize` succeeds; `Playbook Card
  ori:108` (`RunNow`) runs the playbook and then writes `Last Run Instance ID` / `Last Run At` /
  `Last Run Status` straight from the page. Moving either into `Scheduler Mgt ori` / `Playbook ori`
  is mechanical but changes where responsibility lives, so it is called out rather than done here.

---

## Check 13 — What I couldn't check

- **Skipped:** Check 5 (no published baseline — `AppSourceCop.json` has no `version`, the app is
  unreleased), Check 11 (no `stories/` folder), Check 15 (not the standards repository).
- **Limited:** command-line `alc` does not raise AS0011 (mandatory affix), so the ` ori` suffix was
  verified by hand across all 110 app objects instead — AL-Go CI remains the real gate. No
  AppSourceCop ruleset file exists, so it ran with default actions.
- **Not exercised:** the data take-over (`App Takeover ori`) — it fires only on a first install
  beside the published Cloud Events app, and the unit suite cannot reach it in either container.
  The `Orchestrator.Entry.Run` defect above was established from the code and from Microsoft's own
  `Confirm Management` implementation, not from a live call: CRONUS IS currently holds no
  `Scheduled Entry ori` records to run against, and creating one requires `Entry.Register`, which
  is the other known-broken type.
- **Not re-run:** the full MCP message-type suite. The report of 2026-09-05 stands, but this review
  shows at least one of its "Success" verdicts checked the envelope rather than the effect — the
  same doubt applies to the other types whose effect was not read back.
- **Needs a human:** the four open decisions listed in the verdict.

---

## Check 14 — Role coverage ❌

`BIFROST Orchestr ori` is complete — machine-diffed against the source, it grants all 11 tables at
`RIMD`, all 26 pages at `X` and all 53 codeunits at `X`, with nothing missing and nothing named
that does not exist. `BIFROST OrchSet ori` and `BIFROST OrchMgt ori` are real, well-separated roles
with sensible least privilege (setup gets `RIMD` on the setup and credential tables, operations
gets `R`).

**But the two playbook roles grant nothing usable:**

| Permission set | tabledata | page | codeunit |
| --- | ---: | ---: | ---: |
| `BIFROST Orchestr ori` | 11 | 26 | 53 |
| `BIFROST OrchSet ori` | 5 | 9 | 13 |
| `BIFROST OrchMgt ori` | 5 | 9 | 10 |
| **`BIFROST PlaybAdm ori`** | 7 | **0** | **0** |
| **`BIFROST PlaybVw ori`** | 7 | **0** | **0** |

Both are `Assignable = true`, and `BIFROST OrchMgt ori`'s own XML documentation directs the reader
to them: *"playbook execution is granted separately by `BIFROST PlaybVw ori`."* A user holding
`BIFROST OrchMgt ori` + `BIFROST PlaybVw ori` cannot open `Playbooks ori`, `Playbook Card ori` or
any playbook page, and cannot execute `Playbook Runner ori` — the role grants table data and
nothing to reach it with.

Not fixed here: deciding which of the 13 playbook pages and which playbook codeunits belong to the
authoring role versus the read-only role is a design decision, not a mechanical gap. **Decision
needed.** The straightforward reading is that both sets take `X` on the playbook pages
(`Playbooks`, `Playbook Card`, `Playbook Instances`, `Playbook Instance Card`, the four subpages
and FactBoxes, `Playbook Template Editor`, `Playbook Cond. Subpage`, `Schedule Playbook`,
`Report Preset Card`) and on the playbook codeunits (`Playbook Runner`, `Playbook Step Executor`,
`Playbook Workspace`, `Playbook JSON Helper`, `Playbook Log Mgt`, `Msg Executor`, the four
`Playbook * Msg` types) — page and codeunit permissions are execution rights, and the read/write
distinction is already carried by the `R` versus `RIMD` on the tabledata.

This is pre-existing: the sets were carried over from `CE PlaybookAdmin ori` / `CE Playbook View
ori` under new names.

---

## Security audit (workflow, 8 phases)

Run alongside the gateway. Phases 2 (secrets), 3 (permissions), 7 (event exposure) and 8 (temp
tables) came back clean; nine findings across phases 4, 5 and 6.

**Fixed in this PR:**

| Sev | File | What | Fix |
| --- | --- | --- | --- |
| Medium | `EmailNotification.Codeunit.al:192` | Recipient email address emitted as a telemetry dimension with `TelemetryScope::All` and labelled `SystemMetadata` — EUII reaching Origo's App Insights as well as the customer's | Dimension removed |
| Medium | `ScheduledEntry.Table.al:202` | `"Notification Recipient"` holds an email address and is published as `notificationRecipient` on an OData API page, but inherited the table's `SystemMetadata` | `DataClassification = EndUserIdentifiableInformation` |
| Medium | `PlaybookStepLog.Table.al`, `PlaybookInstance.Table.al`, `JQParameter.Table.al` | Six Blob fields persist whole message-type request/response payloads under table-level `SystemMetadata` | `DataClassification = CustomerContent` on each |
| Medium | `AppUpgrade.Codeunit.al:25` | Silent re-enable of `Allow HttpClient Requests` (Check 12, AC-7) | Removed |
| Low | `ReportMsgHandler.Codeunit.al:254` | `Orchestrator.Report.Run` returned `GetLastErrorCallStack()` to the caller — base-app and extension object names, procedures and line numbers | Gated on `Request Debug Mode`, the same gate the request log uses |
| Low | `TelegramNotif.Codeunit.al:142` | Telegram chat id (a per-person identifier, `CustomerContent` at rest) written to telemetry as `SystemMetadata` | Dimension removed |
| Low | `PlaybookJSONHelper.Codeunit.al:266` | Unguarded `Evaluate` on a playbook path index — `items[x]` raised a hard error where every other bad segment returns `false` | Guarded |

**Open — needs a decision:**

- ⚠️ **Medium (IDOR, CWE-639) — `Orchestrator.Email.Send` does not check draft ownership.**
  The codeunit elevates itself with `Permissions = tabledata "Email Outbox" = RIMD` and then sends
  whatever `EmailOutbox.GetBySystemId(<caller GUID>)` resolves to. A caller who learns another
  user's outbox SystemId can have that user's draft sent, without holding any Email Outbox
  permission themselves.
  **I attempted the obvious fix and backed it out:** the System Application deliberately exposes no
  owner accessor. `"Email Outbox"."User Security Id"` is `Access = Internal` (the compiler rejects
  it — AL0161), the only public accessors are `GetMessageId` / `GetAccountId` / `GetConnector`, and
  query `Outbox Emails`, which does expose the column, is `Access = Internal` too. The two viable
  designs are (a) have `Email.Draft.Set` record the outbox SystemId it created against the calling
  user in an app-owned table and let `Email.Send` accept only those, or (b) drop the `Permissions`
  elevation so the caller needs their own Email Outbox rights — which narrows the exposure without
  closing it. A comment marking the gap was left at the call site, and it is recorded as a Known
  Issue.

- ⚠️ **Low — unescaped markup in notification bodies.** `Scheduled Entry.Description` and
  `JobQueueEntry."Error Message"` are concatenated into HTML email bodies and into Telegram
  messages sent with `parse_mode: HTML`, unescaped. Anyone who can set an entry description can
  inject markup or a link into the notification; on Telegram, unbalanced tags make the API reject
  the message outright. The fix is a small escaping helper — left out because it changes how every
  existing notification renders, which deserves a deliberate call.

**Cleared:** no hardcoded secret, no `SecretText.Unwrap`, no secret in a table, log, error or
telemetry dimension. Both outbound hosts are `Locked = true` HTTPS literals, and the Telegram bot
token travels through `SetSecretRequestUri(SecretStrSubstNo(...))` — the platform's masked-URI API
— never through a plain URL. Zero `SetFilter` calls in the app, so filter injection does not apply.
All 30 integration events are `[IntegrationEvent(false, false)]` with no credential in any
signature. The documented `Scheduler API Client ori` deviation from codeunit `OAuth2` was
re-examined and no leak beyond the approved trade-off was found.

---

## Performance audit (workflow, 8 phases)

Phase 5 (SIFT/FlowFields) and phase 6 (query patterns) are clean: no SIFT keys and no `Sum`
FlowFields are needed — this app aggregates in JSON, not in the database — and every filter has a
supporting key, verified against the table definitions including the base-app ones. There are 23
`IsEmpty()` call sites and zero `Count() > 0` existence checks.

Eleven findings, **none fixed in this PR** — they change runtime behaviour of the playbook engine
and the scheduler, which is more than this migration should absorb. In recommended order:

| # | Sev | Where | What scales badly |
| --- | --- | --- | --- |
| F1 | High | `PlaybookRunner.Codeunit.al:488` (+5 more) | `Workspace.ToText()` is passed as an *argument*, so the whole workspace JSON is serialised on every iteration — but the log only stores it when the step failed. The document grows with each item, making the wasted serialisation O(n²). Fix: a `SnapshotIfFailed(Status)` helper. Behaviour-preserving; the value is already discarded on the success path. |
| F2 | High | `PlaybookRunner.Codeunit.al:476,479` | `HasConditions()` and `EvaluateConditionSet()` run per item, though the condition set belongs to the step. 2 DB round-trips × n. Hoist above the loop. |
| F3 | High | `SchedulerAPIClient.Codeunit.al:33` | `Initialize()` clears the 3500-second token cache, and it is called once per scheduled entry — so the cache can effectively never hit and every entry pays a fresh OAuth2 POST to Entra before its actual call, every cycle. Clear only when the credentials code actually changes. |
| F5 | Medium | `PlaybookInstance.Table.al` | No `OnDelete`, so purging instances does not cascade to `Playbook Step Log ori` — the app's largest table, four Blob fields, one row per item. `AddAllowedTable` only makes a table *eligible* for retention; no `Retention Policy Setup` record is created, so out of the box both log tables grow without limit. |
| F4 | Medium | `SchedulerHandler.Codeunit.al:47` | The error branch writes an Activity Log row unconditionally, unlike the two neighbouring calls which honour `Log Job Queue Activity`. One permanently-failing entry writes 288 rows a day for ever. |
| F6 | Medium | `ScheduledEntry.Table.al:856` | Nine consecutive `ModifyAll` statements against the *same single* Job Queue Entry row, reached from nine `OnValidate` triggers: ticking one weekday costs 9 UPDATEs and 9 trigger runs. |
| F7–F10 | Low | scheduler, step executor, report and status handlers | A duplicated `Get` per entry per cycle; a `Setup.Get()` per step *and* per item; `Report Metadata` filtered in AL rather than with `SetRange`; three `Count()` queries where two suffice. |
| F11 | — | `AppTakeover.Codeunit.al` | N+1 plus `CalcFields` per row — **do not fix**, install-only, one shot, on configuration tables. |

Noted rather than flagged: the `Commit()` in `Playbook Runner ori:526` runs per step *and* per item
and is the structural reason a large foreach is slow, but it guards the `Codeunit.Run` isolation
that `Msg Executor ori` is documented to depend on. Removing it would break the isolation model.
The `Commit()` in `Scheduler Handler ori:132` is deliberate per-entry isolation.

---

## Verdict

```
❌  One check fails and four decisions are open. Nothing here blocks the code
    from working, but Check 14 ships two assignable roles that grant nothing
    usable, and that is a defect a customer will hit.

    1. Check 14 — BIFROST PlaybAdm ori and BIFROST PlaybVw ori grant tabledata
       only: no page, no codeunit. Decide the page/codeunit membership of each.
    2. Orchestrator.Entry.Run reports success over the API without running
       anything. Needs a GUI-free path through RunJobQueueEntryOnce.
    3. Orchestrator.Email.Send has no draft-ownership check, and the platform
       exposes no supported way to add one. Pick design (a) or (b).
    4. app.json EULA points at Origo's general terms page, not a Bifröst EULA.

    Plus one external dependency: the `nornir-setup` help page lives on the site
    branch `setup-pattern-help` and must reach businesscentralal/bifrost `main`
    or the Setup page's Help button 404s.
```

Fixed in this PR: 45 Layer 1 findings, 3 logic bugs, 7 security findings, 2 stale tests, the README
rebuild, the CHANGELOG corrections and the `.claude/CLAUDE.md` id drift. Both apps compile 0/0 and
154 of 154 tests pass on both containers.

*AI-assisted review. It cannot catch domain rules that are not written down anywhere, and the
acceptance criteria in Check 12 are a reading of the code, not a specification.*
