# PR 167 — retained developer verification

Candidate: `efffcfeb5d36c8ae314e181cad189ba5e91eac1a`  
Owner: Alvíss (`worker-4`)  
PR: https://github.com/businesscentralal/bc-origo-bifrost-orchestrator/pull/167  
Issue: https://github.com/businesscentralal/bc-origo-bifrost-orchestrator/issues/94

| Acceptance | Result at this candidate | Evidence |
|---|---|---|
| AC01: three native-profile send types; number/SystemId; optional override | Verified with the existing candidate send mock. 18 positive MCP scenarios cover number, SystemId and omitted override resolving the self-created vendor/customer profile, across all three types in 1033/1039. Six Web Client actions invoke the shipping handlers through a temporary verification page. | `mcp-current-summary.json`, `ui-current-summary.json`, raw `current-mcp-*` / `current-extra-*` |
| AC02: unknown document → RecordNotFound | Six MCP assertions, one per type/language, verify the coded refusal and nonempty nextStep. | Raw `current-mcp-unknown-document-*` |
| AC03: matching PDF message types | PENDING: issues 91, 92 and 93 remain open and their message types are absent from this candidate. Andvari owns 91; Nyi owns 92; Architect must reconcile 93 routing and Claude/Architect the AC dependency disposition. No foreign source was edited. | `dependency-final-91.json`, `dependency-final-92.json`, `dependency-final-93.json` |
| AC04: coded refusals, bilingual help/resources and coverage | 18 negative MCP assertions check unknown document, malformed identifier and missing identifier. Six help checks verify catalogue and stable machine values. Chapter declarations now have en-US/is-IS Label resources. Three new tests verify all nine declared chapters, overview/notes and stable Request/Vendor/Customer/Default values; they also preserve Foundation #777's deliberate canonical-English structured contract. Public structured help remains English; catalogue/error prose is checked in both locales. | `tests-current-summary.json`, `mcp-current-summary.json`, `current-doc-send-focused.json`, XLF CI check |
| AC05: exactly three dot-separated name parts | Preserved: Purchase.Order.Send, Sales.Quote.Send, Sales.OrderConfirmation.Send. | Candidate enum and compiled contract tests |

## Exact candidate checks

- Product and test app: 0 errors / 0 warnings. Product uses CodeCop/UICop/AppSourceCop; PTE test app uses CodeCop/UICop. Default manifest compilation removes the test internals grant and AS0081 suppression using the repository's existing build behavior.
- Local BC29 tenant `w129-14`: 587 executed, 587 passed, 0 failed, 0 skipped. Existing configured isolation split: 577 under runner 130450 and 10 under runner 130451. No exclusions or assertion suppressions added.
- Paired CI: https://github.com/businesscentralal/bc-origo-bifrost-orchestrator/actions/runs/43295815830 . Default, Test and status check succeeded. Test job 131459073580 reports 587/587/0/0; `ci-current-test-summary.log` retains the actual count lines.
- MCP: 36 behavioral assertions passed plus 6 help checks; 0 failed / 0 skipped. All positive scenarios seed their own profiles, parties and documents. External send is intercepted by the candidate test app's existing mock. Every proof reports emailDelta=0.
- UI: six successful mock-only actions on temporary page 96498, three in 1033 and three in 1039. The original English (United States) user language was restored. Screenshots and DOM/result receipts are retained.
- No external email/provider call, operator consent/credential/metering write, usage sync or guard bypass was performed. Configured unit tests retain their normal isolated fixtures. Existing Foundation 28.0.13.0 and all pre-existing Origo packages were preserved.

## Cleanup and remaining delivery

Business fixture read-back returns zero AV167 customers, vendors, sales/purchase headers and sending profiles. The owned ORCHESTRAT suite was deleted. The three task-owned apps (verification harness, Orchestrator Tests, Orchestrator) were uninstalled with deleteExtensionData and unpublished; read-back confirms absence.

Foundation retains 216 owned test message receipts until usage reporting completes. Every deletion returned HTTP400, so 0 were deleted. The private batch adapter initially checked MCP isError but missed HTTP status in the payload; it attempted all 216 distinct receipt deletions. The adapter now stops on HTTP failures. No further deletion retry, usage sync or metering-state bypass was attempted. Legitimate reporting or explicit retention disposition is owned by Gunnar/Claude Code. Cleanup is recorded PARTIAL, not a pass.

The draft remains draft. Green-pr-handoff is withheld while AC03 and receipt-retention disposition remain unresolved. Current-head independent Claude verification, Grok clearance, eligible approval, Architect merge/deployment and Tester UAT remain delivery work.

## Review learning and gateway

The first locale regression incorrectly called Foundation's intentionally English GetContract API to test localizable resources. It was corrected to inspect declaration interfaces while adding a canonical-English invariant; all three regressions pass. Older 3025df57 and 9cb8041 results are historical and are not claimed for this candidate.

The advisory gateway reports 14/23 passing groups and 9 finding groups. Findings include locked wire-name captions, integer Format(TableId) flagged as GUID formatting, procedure-parameter semicolons flagged as multiple statements, an XML-comment preamble flagged as a namespace gap, example email addresses, and documentation/read-isolation/Try-prefix/Unreleased-heading advisories. They are retained in `gateway-final-current.log`; the scanner is not described as green. Compiler and configured full-suite gates are separately recorded above.
