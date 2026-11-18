# Inbox — Drop Tasks Here for DSAI

The `inbox/` folder is where online assistants (or you) can leave tasks for DSAI to pick up and complete locally.

## How to Drop a Task

Create a Markdown file in `inbox/` following the **TEMPLATE.md** format below. DSAI will:
1. Read the task description
2. Complete all local work
3. Update or create the requested files
4. Mark the task as done when finished

## Task File Format

**Filename:** Use a descriptive name like `inbox/TASK-2026-11-07-summarise-expenses.md` or `inbox/draft-email-to-manager.md`.

**Contents:**

```markdown
# Task: [Your task title here]

**Goal:** [What does success look like? What is the outcome?]

**Files to touch:**
- Filepath 1 (action: read / create / edit)
- Filepath 2 (action: read / create / edit)

**What stays online:**
- [Any step requiring internet, website login, email send, bank sync, etc.]

**Additional context:**
[Optional: any background info, rules, or preferences]
```

## Example Tasks

### Example 1: Summarise Expenses
```markdown
# Task: Export October expenses summary

**Goal:** Read private/EXPENSES.md and create a summary showing:
- Total spent per category
- Budget vs. actual
- Any overspend alerts

**Files to touch:**
- private/EXPENSES.md (read)
- docs/EXPENSE-SUMMARY-OCT2026.md (create)

**What stays online:**
- Emailing the summary to the accountant (DSAI can draft; you send)

**Additional context:**
Period: 14 Oct 2026 – 10 Nov 2026
Standard caps: Groceries $300, Eating Out $400, Allowance Sunny $200, Allowance Drashti $200
```

### Example 2: Draft a Message
```markdown
# Task: Draft email to landlord

**Goal:** Write a professional email explaining that the rent payment will be late this month.

**Files to touch:**
- drafts/2026-11-07-email-to-landlord.md (create)

**What stays online:**
- Sending the email (DSAI drafts; you review and send)

**Additional context:**
Tone: Professional but apologetic
Keep it under 150 words
Mention that payment will arrive by Nov 15
```

### Example 3: Organise Notes
```markdown
# Task: Organise travel planning notes

**Goal:** Read messy travel notes and create a clean checklist with:
- Flights (dates, times, confirmation numbers)
- Accommodation (addresses, check-in times)
- Activities (with booked/to-do status)
- Packing list

**Files to touch:**
- projects/Trip-2026-12/travel-notes-raw.md (read)
- projects/Trip-2026-12/TRAVEL-CHECKLIST.md (create)

**What stays online:**
- None (this is entirely local)

**Additional context:**
Trip is to Perth, 15–20 December
Travelling with family (4 people)
```

## Rules for Tasks

1. **Be specific:** Say exactly what files to read and create.
2. **Define success:** How will DSAI know the task is complete?
3. **Mark online steps clearly:** If the task needs email send, bank login, or web access, list it under "What stays online."
4. **DSAI will not:**
   - Send emails (only draft them)
   - Log into websites or banks
   - Edit the live household Numbers workbook
   - Invent numbers or financial figures
   - Make up meeting attendees or decisions not in local files

## Status and Follow-Up

When a task is done, DSAI will:
- Update or create the requested files
- Leave the original task file in `inbox/` with a note marking it complete
- List any "what stays online" steps for you or an online assistant to finish

To check status:
```powershell
powershell -ExecutionPolicy Bypass -File .\tools\offline-status.ps1
```

This shows whether there are open tasks in `inbox/`.

## Creating Tasks from Terminal

To quickly create a new task file, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\new-task.ps1
```

This opens a template and creates a dated markdown file in `inbox/` that you can fill in.

---

## Quick Links

- **See all offline capabilities:** `docs/OFFLINE-CAPABILITIES.md`
- **Check what stays online:** `docs/OFFLINE-WORK.md` (section "What DSAI CANNOT Do")
- **Drafting emails:** `drafts/README.md`
