# DSAI Offline Capabilities

This document lists exactly what DSAI can do offline and how to use each capability.

---

## 📂 File and Text Work

### Read Any Local File
- DSAI can open and read any file in the `DSAI` folder structure.
- Use this to summarise documents, extract data, or understand project context.

**Example:** "Read EXPENSES.md and tell me which categories spent the most this month."

### Create and Edit Files
- DSAI can create new Markdown files, text files, or project documents.
- DSAI can update existing files directly (no manual copy-paste needed).

**Example:** "@-mention a file in the chat, ask DSAI to fix typos, reorganise sections, or add new content."

### Draft Emails and Messages
- DSAI can write a complete draft email with To, Subject, and Body ready to send.
- Drafts are saved in `drafts/` with a timestamp.
- You review them before sending (DSAI never sends automatically).

**Example:** "Draft an email to my manager explaining why the project needs an extension."

**How to use:**
```powershell
# Run the helper script
powershell -ExecutionPolicy Bypass -File .\tools\new-draft.ps1

# Then ask DSAI to help refine it
```

### Summarise and Rewrite Text
- Take a long document and extract the key points.
- Rewrite in a different tone (casual, formal, brief, detailed).
- Split paragraphs or combine related ideas.

**Example:** "Take this meeting transcript and create a one-page summary with decisions and action items."

---

## 🧮 Math and Numbers

### Exact Arithmetic
- Use `tools/calc.ps1` for any calculation that needs precision.
- Examples: receipts, percentages, unit conversions, financial calculations.

**Why?** AI language models predict tokens, not perfect arithmetic. Let PowerShell do the math.

**How to use:**
```powershell
# Run the calculator directly
powershell -ExecutionPolicy Bypass -File C:\Users\Tech\DSAI\tools\calc.ps1 "(487 * 19) + (1352 / 8) - 412"

# Output: 9281
```

### Household Expense Tracking
- Log daily spends from credit card statements or receipts.
- DSAI reads category rules from `private/TRACKER-RULES.md` and suggests the right category.
- Logs go into `private/EXPENSES.md` in a Markdown table.

**Budget categories (per 4-week period):**
- Groceries: $300
- Eating Out: $400
- Allowance Sunny: $200
- Allowance Drashti: $200

**Special rules:**
- Fast food (McDonald's, Hungry Jack's, KFC, Subway, Domino's, Uber Eats) = Eating Out by default
- Woolworths, Indian grocers = Groceries (unless purpose is different)
- Mining-camp meals (Sodexo, ISS, Dixons, Compass, Mia Mia) = Allowance Sunny
- Pharmacy = Medical

**How to use:**

1. **Paste a spend in chat:**
   ```
   "Log this: Woolworths 2026-11-07 $42.50 for weekly groceries"
   ```

2. **DSAI suggests category:**
   ```
   Category: Groceries
   Reason: Woolworths is a supermarket, and this looks like staples.
   Confirm? [Y/n]
   ```

3. **DSAI logs it:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\tools\expense-log.ps1 `
     -Action add `
     -Date 2026-11-07 `
     -Category Groceries `
     -Merchant Woolworths `
     -Amount -42.50 `
     -Notes "Weekly groceries"
   ```

### Budget Leftovers
- See how much budget remains for each category this period.
- Warning if Eating Out is exhausted or negative.

**How to use:**
```powershell
powershell -ExecutionPolicy Bypass -File .\tools\expense-log.ps1 -Action leftovers
```

**Output example:**
```
=== Budget Leftovers ===
Period: 14 Oct 2026 to 10 Nov 2026

Groceries     : Cap $300 | Spent $156.50 | Remaining $143.50
Eating Out    : Cap $400 | Spent $280.00 | Remaining $120.00
Allowance Sunny    : Cap $200 | Spent $150.00 | Remaining $50.00
Allowance Drashti  : Cap $200 | Spent $120.00 | Remaining $80.00
```

---

## 🗂️ Organisation and Projects

### Create a New Project Folder
- Set up a clean project folder with standard structure (NOTES.md, README.md, etc.).

**How to use:**
```powershell
powershell -ExecutionPolicy Bypass -File .\tools\new-project.ps1
```

This creates a folder called `New Project` (or `New Project 2`, etc.) with:
- NOTES.md (for project notes)
- README.md (project overview)
- /data (for local files or references)

### Create a Task Checklist
- DSAI writes a Markdown checklist for any project.
- You check off items as you complete them.

**Example:** "Create a checklist for organising the spare bedroom."

### Write Meeting Notes
- DSAI formats meeting summaries with attendees, decisions, and action items.
- Saves in NOTES.md so the whole team (or just you) can refer back.

---

## 🔒 Personal Vault and Memory

### Unlock Your Personal Vault (First Time)
- Create an encrypted vault file protected by your own passphrase.

**How to use:**
```powershell
powershell -ExecutionPolicy Bypass -File .\tools\vault.ps1 -Action init -VaultName yourname
```

- Type your passphrase twice (hidden input).
- DSAI creates `vault\yourname.vault` (encrypted) and opens `private\MEMORY.md` for editing.

### Unlock Your Vault When You Return
- Decrypt and load your personal memory.

**How to use:**
```powershell
powershell -ExecutionPolicy Bypass -File .\tools\vault.ps1 -Action unlock -VaultName yourname
```

- Type your passphrase once.
- DSAI loads `private\MEMORY.md` with your saved notes.

### Lock Your Vault When Finished
- Encrypt everything back and wipe the readable files from disk.

**How to use:**
```powershell
powershell -ExecutionPolicy Bypass -File .\tools\vault.ps1 -Action lock -VaultName yourname
```

- Type your passphrase to confirm.
- DSAI securely overwrites and deletes `private/` files, leaving only encrypted `vault\yourname.vault`.

### Save Lessons Learned
- Ask DSAI to remember a fact, preference, or lesson for next time.
- DSAI writes it to personal vault memory (`private/MEMORY.md` when unlocked).

**Example:** "Remember: always ask for purchase receipts before logging expenses."

DSAI will record this, and next session when you unlock your vault, it will know this preference.

---

## ✉️ Drafts and Handoffs

### Create an Email Draft
- Write a complete draft email with To, Subject, and Body.
- Save it in `drafts/` so you or an assistant can send it later.

**How to use:**
```powershell
powershell -ExecutionPolicy Bypass -File .\tools\new-draft.ps1
```

- DSAI opens a template and asks for details.
- Creates a file like `drafts/2026-11-07-email-to-landlord.md`.

### Pick Up a Task from Inbox
- An online assistant can drop a task file in `inbox/` with instructions.
- DSAI reads the task and completes the local parts.
- Any online-only steps (like sending an email) are drafted and left for you/the assistant.

**Task file format:**

```markdown
# Task: Export monthly expenses summary

**Goal:** Create a summary of household spending for November.

**Files to touch:**
- private/EXPENSES.md (read)
- docs/EXPENSE-SUMMARY-NOV2026.md (create)

**What stays online:**
- Emailing the summary to the accountant
```

---

## 📊 Scripts and Utilities

### Check Offline Status
```powershell
powershell -ExecutionPolicy Bypass -File .\tools\offline-status.ps1
```

Shows:
- Is the local model server running? (checking 127.0.0.1:8081)
- Are there open tasks in inbox/?
- One-line reminder of what stays online

### List Recent Expenses
```powershell
powershell -ExecutionPolicy Bypass -File .\tools\expense-log.ps1 -Action list -Lines 20
```

Shows the last N expense rows from EXPENSES.md.

### Full Calculator
```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\Tech\DSAI\tools\calc.ps1 "((500 + 250) * 1.1) - 30"
```

Supports all PowerShell arithmetic, percentages, string lengths, and more.

---

## 🚫 What Stays Online

An online assistant (or you via a website) must handle:
- **Bank syncing** (reading live account balances)
- **Editing the live Numbers workbook** (household budget that lives in iCloud)
- **Sending emails** (only drafting locally)
- **Logging into websites** (banks, email, Dropbox, etc.)
- **Cloud sync** (Dropbox, Google Drive, OneDrive)
- **Live payments** (Stripe, PayPal, bank transfers)

DSAI will draft, calculate, organise, and note-take for all of these, but will not pretend it did the online part.

---

## 🎯 Quick Start Example

**You want to log today's groceries spend and check remaining budget:**

```powershell
# Step 1: Ask DSAI to categorise
# (Paste the receipt in chat)

# Step 2: DSAI suggests category and reason, you confirm

# Step 3: DSAI runs the logging command
powershell -ExecutionPolicy Bypass -File .\tools\expense-log.ps1 `
  -Action add `
  -Date 2026-11-07 `
  -Category Groceries `
  -Merchant Woolworths `
  -Amount -78.45

# Step 4: DSAI shows leftovers
powershell -ExecutionPolicy Bypass -File .\tools\expense-log.ps1 -Action leftovers
```

**Result:**
```
✓ Added expense: 2026-11-07 | Groceries | Woolworths | $-78.45

=== Budget Leftovers ===
Groceries    : Cap $300 | Spent $234.95 | Remaining $65.05
Eating Out   : Cap $400 | Spent $280.00 | Remaining $120.00
...
```

Done in 2 minutes, no internet needed, and your spending is logged and private.
