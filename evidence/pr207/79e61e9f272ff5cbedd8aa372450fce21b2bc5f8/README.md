# PR #207 amendment verification

Candidate: `79e61e9f272ff5cbedd8aa372450fce21b2bc5f8`.
Worker: Alvíss (worker-4). Environment: own BC 29 tenant `w129-14`, CRONUS International Ltd. Verified 2026-11-17.

The candidate is pushed on `codex/hanarr-orchestrator203-is-translation-review`. Commit `cd1576d3c4c84ce5188c2c436bf811597b14f05b` merges main without AL conflicts and unions CHANGELOG. Commit `79e61e9f272ff5cbedd8aa372450fce21b2bc5f8` repairs only the restricted navigation test fixture. Product AL differences against main remain Icelandic comments.

## Finding 1: affected tests

The original `96465 / AC35_UncoveredDestinationFailsVisibly` failure was caused by the own tenant's ChangeLog Write Guard being **Open**. Setting it to **Blocked** through Foundation Tests `Test.Setup.Set` restored the negative fixture's documented prerequisite. No coverage, bypass or assertion was weakened. The whole codeunit passed **14/14** at the candidate.

Merging current main introduced a separate failing fixture in `96448 / Scenario_AC03_NoToolRole_HidesBothTools`: LOGIN cannot read the parent Playbook table on BC 29, so the page closed before the negative action assertions. The new test-only permission set `96448 / Orch NoTools ori` grants only Playbook-table read and Playbooks-page execute. The fixture still lowers permissions, asserts that Copy Plans data is unreadable, and asserts that both tool actions cannot be invoked. Neither tool nor any product role gains a permission. The whole changed codeunit passed **12/12**.

The full affected-object selection ran at the candidate through `bc_dev_run_tests`, `mode=local`: **192 executed, 192 passed, 0 failed, 0 skipped**, across 14 codeunits. Counts per codeunit are in [targeted-summary.json](targeted-summary.json). Both apps were compiled from this candidate and tenant-published; both builds have **0 errors and 0 warnings** ([product](build-product.log), [tests](build-tests.log)).

## Finding 2: Web Client UI

All four affected surfaces passed in both supported languages, at the candidate. Browser login used only the own tenant's approved test login, held in memory. The fixture `XUI207` had one Transform step, one Exists condition and one mapping; it was never executed.

| Surface | 1033 | 1039 |
|---|---|---|
| Playbook Card, Transform Fields part caption | PASS: Transform Fields | PASS: Reitaumbreytingar |
| Playbook Transforms page caption/grid | PASS: Transform Fields | PASS: Reitaumbreytingar |
| Step Conditions, actual Operator tooltip via column menu | PASS: not an empty text | PASS: ekki tómur texti |
| Table Data, Import JSON with an invalid file | PASS: The file is not valid JSON. | PASS: Skráin er ekki gild JSON-skrá. |

Screenshots: [English card/parts/tooltip](ui-final-1033-playbook.png), [Icelandic card/parts/tooltip](ui-final-1039-playbook.png), [English JSON error](ui-final-1033-import.png), [Icelandic JSON error](ui-final-1039-import.png). Matching text snapshots and machine-readable summaries are alongside them. No valid-data import or external-provider request occurred.

## Other evidence

[The XLF audit](audit-final.json) compares the candidate with main `ae3150bae545dad21b6c3fcf5aab91162e90dfc5`: 1,278 units, exactly 28 targets changed, IDs and English sources unchanged, placeholder multisets preserved, and changed developer notes matching targets. Untouched-part MCP evidence carries forward: the amendment changes no message implementation or contract. Licence-path checks are **NOT_RUN**, per standing ruling.

Paired CI at this exact head supplies the full-suite proof: [Pull Request Build 44021401003](https://github.com/businesscentralal/bc-origo-bifrost-orchestrator/actions/runs/44021401003), [Source Guards 44021401006](https://github.com/businesscentralal/bc-origo-bifrost-orchestrator/actions/runs/44021401006). Both runs completed successfully. The paired Test job reports **687 executed, 687 passed, 0 failed, 0 skipped** in its Analyze Test Results step. Compiled Icelandic XLF synchronization and required PR status also passed. [CI summary with artifact identifier and digest](ci-test-summary-final.json), [complete handover evidence](evidence.json).

[Cleanup](cleanup.json): both own-built Orchestrator apps uninstalled with extension data and unpublished; all fixture rows removed. Original write guard, chat-provider ordinal and English UI language restored. The temporary None chat provider avoided the stale provider ordinal that otherwise prevented the card from opening. No credentials or browser sign-in state are included here.
