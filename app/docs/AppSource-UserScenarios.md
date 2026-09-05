# User Scenarios — Bifrost Nornir

**Publisher:** Origo
**Version:** 28.0.0.0
**Submission Date:** 2026-09-05
**Test Environment:** Requires a configured Telegram Bot Token for notification scenarios. See "Test Credentials" section below.

---

## Test Credentials

This extension uses the Telegram Bot API for notification delivery.

**Provide:** A Telegram Bot Token (from @BotFather) and a Telegram Chat ID for a test user.
The Bot Token is stored in the "Job Queue Orchestrator Setup" page via Isolated Storage (encrypted at rest).
The Chat ID is stored per user in "Bifrost User Setup" (Bifrost Foundation).

For email notification scenarios, a BC email account must be configured.

---

## Scenario 1: Extension Installation and Setup Wizard

**Area:** Installation & Activation

### Setup
1. Start with a clean BC sandbox (Cronus company)
2. Install the "Bifrost Foundation" extension (dependency)
3. Install the "Bifrost Nornir" extension

### Steps
1. Open the "Bifrost Setup" page from the BC search bar
2. Observe the notification banner, for example "HTTP client requests are not enabled for this extension. Run the setup wizard to enable."
3. Click "Run Setup Wizard" on the notification
4. Verify Step 1 (Welcome to Bifrost Nornir) displays, click "Next"
5. Verify Step 2 (Enable HTTP Client Requests) shows the current status
6. If not enabled, click "Enable HTTP Client Requests" and then "Verify"
7. Click "Next" to Step 3 (Job Queue Orchestrator), which shows the job queue status
8. Click "Start Job Queue" to start the management job queue
9. Click "Next" to Step 4 (Setup Complete), click "Finish"
10. Re-open "Bifrost Setup" — the notification should no longer appear

### Expected Results
- The "Bifrost Nornir Setup" wizard opens and guides through 4 steps
- HTTP client requests can be enabled from within the wizard
- The management job queue starts successfully
- After completing the wizard, the notification does not appear again

---

## Scenario 2: Register and Run a Scheduled Entry

**Area:** Core Functionality — Entry Management

### Setup
1. Complete Scenario 1 (setup wizard finished)
2. Ensure at least one Job Queue Entry exists (for example the app's own management entry)

### Steps
1. Open the "Job Queue Orchestrator Setup" page
2. Observe the "Orchestrator Entries" subpage
3. Navigate to "Job Queue Entries" via the action menu
4. Note the ID of any Job Queue Entry
5. Invoke the `Orchestrator.Entry.Register` message type via the Bifrost API:
   - `type`: `Orchestrator.Entry.Register`
   - `data`: `{"jobQueueEntryId": "<ID from step 4>"}`
6. Invoke `Orchestrator.Entry.Run` with the returned SystemId:
   - `type`: `Orchestrator.Entry.Run`
   - `subject`: `<id from step 5 response>`

### Expected Results
- Step 5: Returns `{"status": "Success", "id": "<guid>", "blocked": false, "message": "..."}`
- Step 6: The entry executes successfully and returns a success response
- The scheduled entry appears in the "Orchestrator Entries" subpage of the setup page

---

## Scenario 3: Telegram Notification on a Scheduled Entry

**Area:** Notifications — Telegram

### Setup
1. Complete Scenario 1
2. Open "Job Queue Orchestrator Setup" and enter a Telegram Bot Token
3. Open "Bifrost User Setup" and enter a Telegram Chat ID for the current user
4. Create or use an existing scheduled entry

### Steps
1. Open the "Job Queue Orchestrator Entry Card" for the entry
2. Set "Notification Type" to "Telegram"
3. Set "Notification Recipient" to the test Telegram Chat ID
4. Click the "Send Test Notification" action
5. Check the Telegram chat for the received message

### Expected Results
- Step 4: No error — the test notification is sent
- Step 5: A message appears in the Telegram chat with the entry description
- If HTTP client requests are not enabled, a clear error message is shown

---

## Scenario 4: Send Telegram Message via Message Type

**Area:** Delivery — Telegram Message Type

### Setup
1. Complete Scenario 3 setup (Bot Token configured, Chat ID on Bifrost User Setup)

### Steps
1. Invoke the `Orchestrator.Telegram.Message` message type:
   - `type`: `Orchestrator.Telegram.Message`
   - `data`: `{"message": "Hello from Business Central!"}`
2. Check the Telegram chat for the received message

### Expected Results
- Step 1: Returns `{"status": "Success", "chatId": "<chat-id>"}`
- Step 2: The message "Hello from Business Central!" appears in the user's Telegram chat
- The chat ID is resolved automatically from the calling user's Bifrost User Setup

### Error Cases
- If no Bot Token: error "Telegram Bot Token is not configured in Orchestrator Setup."
- If no Chat ID on user: error "No Telegram Chat ID configured for the current user. Set it in Bifrost User Setup."
- If `message` is missing from the request: error "\"message\" is required in the request data."
- If HTTP is not enabled: error "HTTP client requests are not enabled for this extension. …"

---

## Scenario 5: Create and Run a Playbook

**Area:** Core Functionality — Playbook Engine

### Setup
1. Complete Scenario 1

### Steps
1. Open the "Bifrost Playbooks" list page
2. Create a new playbook with Code = "TEST-SCENARIO" and Description = "AppSource Test Playbook"
3. Add Step 10: Message Type = "Orchestrator.Status.Get", Next Step No. (Success) = 20
4. Add Step 20: Message Type = "Orchestrator.Telegram.Message" (if Telegram is configured) or leave empty
5. Set Step 20's request template to `{"message": "Orchestrator status check complete"}` (the Request Template FactBox or the "Playbook Template Editor" page)
6. Invoke the `Orchestrator.Playbook.Run` message type:
   - `type`: `Orchestrator.Playbook.Run`
   - `subject`: `TEST-SCENARIO`

### Expected Results
- Step 6: Returns `{"status": "Success", "instanceId": "<guid>", "playbookCode": "TEST-SCENARIO", "playbookStatus": "Completed", "stepsExecuted": 2, "stepsFailed": 0, "itemsProcessed": 0}`
- The playbook executes both steps sequentially
- An execution instance record is created and visible on the "Playbook Execution Log" page

---

## Scenario 6: Schedule a Playbook

**Area:** Core Functionality — Playbook Scheduling

### Setup
1. Complete Scenario 5 (playbook "TEST-SCENARIO" exists)

### Steps
1. Open the "Bifrost Playbook" card for "TEST-SCENARIO"
2. Click the "Schedule" action — the "Schedule Playbook" page opens
3. Set a recurring template or a "No. of Minutes between Runs" value, choose a Notification Type, and confirm with OK
4. Verify "Scheduled" on the playbook card is now Yes
5. Click the "Orchestrator Entry" action to open the scheduled entry that was created
6. Delete the scheduled entry and verify "Scheduled" on the playbook card returns to No

### Expected Results
- Step 3: The playbook is scheduled through a scheduled entry with a recurring Job Queue Entry
- Step 5: The "Job Queue Orchestrator Entry Card" opens on the entry created for the playbook
- Step 6: Removing the entry clears the schedule

---

## Scenario 7: Playbook with ForEach Iteration

**Area:** Core Functionality — Playbook Engine (Advanced)

### Setup
1. Complete Scenario 1
2. Ensure the Customer table has at least 2 records

### Steps
1. Create a playbook "TEST-FOREACH" with:
   - Step 10: `Data.Records.Get` — query Customers (template: `{"tableName":"Customer","fieldNumbers":[1,2],"take":5}`)
   - Step 20: `Orchestrator.Status.Get` — forEach over Step 10's result array (Iterate Array Path = "result", Iterate Source Step No. = 10)
   - Step 30: `Orchestrator.Telegram.Message` — send completion message
2. Run the playbook via `Orchestrator.Playbook.Run` with subject = "TEST-FOREACH"

### Expected Results
- Step 20 executes once per customer record returned by Step 10
- Step 30 sends a Telegram message after all iterations complete
- The playbook completes with `stepsExecuted` > 2 and `itemsProcessed` matching the customer count

---

## Scenario 8: Orchestrator Status and Health Check

**Area:** Status & Monitoring

### Setup
1. Complete Scenario 1

### Steps
1. Invoke `Orchestrator.Status.Get`:
   - `type`: `Orchestrator.Status.Get`
2. Invoke `Orchestrator.Status.RestartIfNeeded`:
   - `type`: `Orchestrator.Status.RestartIfNeeded`
3. Invoke `Orchestrator.Status.Get` again

### Expected Results
- Step 1: Returns `orchestratorStatus`, `jobQueueCategoryCode`, `logJobQueueActivity` and an `entries` object with `total`, `blocked` and `active` counts
- Step 2: Returns `{"status": "Success", "message": "...", "restarted": true|false}`
- Step 3: Shows updated status reflecting any restart

---

## Scenario 9: Run a Report through a Message Type

**Area:** Reporting

### Setup
1. Complete Scenario 1

### Steps
1. Invoke `Orchestrator.Report.List` to list the available reports with their metadata
2. Invoke `Orchestrator.Report.Get` with the ID of one report from step 1
3. Invoke `Orchestrator.Report.SaveAs` for that report, with a saved request preset or inline parameters

### Expected Results
- Step 1: Returns the available reports with metadata, excluding obsolete reports
- Step 2: Returns the report metadata, its available layouts and the saved request page preset
- Step 3: Returns the report output (PDF, Excel, Word or XML). When a playbook step calls it, binary output is base64-encoded in a JSON envelope with `contentType`, `size` and `base64`

---

## Permission Sets

The scenarios above require one or more of the following assignable permission sets, in addition to the Bifrost Foundation sets:

| Permission set | Grants |
| --- | --- |
| `BIFROST Nornir ori` | Read access to scheduled entries, scheduler setup, recurring templates and client credentials |
| `BIFROST NrnSetup ori` | Setup access — scheduler setup, recurring templates, client credentials |
| `BIFROST NrnMgt ori` | Management access — maintain scheduled entries |
| `BIFROST PlaybAdm ori` | Full administration of playbooks, steps, conditions, instances and report presets |
| `BIFROST PlaybVw ori` | Read-only access to playbooks and execution logs |
