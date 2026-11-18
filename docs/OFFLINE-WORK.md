# What DSAI Can Do Offline

DSAI is a private, local-only assistant. It runs entirely on this computer without an internet connection. Use it for everyday reading, drafting, calculating, categorising, organising, and note-keeping in VS Code.

---

## ✅ What DSAI CAN Do Offline

### Reading and Writing
- **Read local files:** DSAI can open and summarise any file in your project folders.
- **Edit local files:** DSAI can create, update, or reorganise files directly in VS Code.
- **Draft emails and messages:** Write complete drafts with To, Subject, and Body ready to send later (never sends automatically).
- **Write personal notes:** Create and update NOTES.md in any project folder or personal vault notes in private/MEMORY.md (when unlocked).

### Calculation and Numbers
- **Exact arithmetic:** Run `tools/calc.ps1` for multi-digit sums, percentages, unit conversions, and financial calculations.
- **Budget tracking:** Log household expenses in EXPENSES.md, read budget caps from TRACKER-RULES.md, and report remaining budget for Groceries, Eating Out, and Allowances.
- **Categorisation help:** When you paste a spend, DSAI suggests a category (Groceries, Eating Out, Medical, etc.) based on your household rules.

### Organisation and Project Work
- **Create folders:** DSAI can set up new project directories with standard structure.
- **Checklists and meeting notes:** Write and update task lists, meeting summaries, and project checklists in Markdown.
- **Summarise and rewrite:** DSAI can take existing text, summarise it, rewrite it in a different style, or reorganise sections.
- **Text processing:** Fix spelling, adjust tone, split long paragraphs, or combine related ideas.

### Using Scripts and Tools
- **Run local scripts:** DSAI can execute any PowerShell script in the `tools/` folder:
  - `tools/calc.ps1` — exact calculations
  - `tools/expense-log.ps1` — add/list expenses or check budget leftovers
  - `tools/vault.ps1` — lock/unlock personal vault (you enter the passphrase)
  - `tools/new-task.ps1` — create a task file in inbox/
  - `tools/new-draft.ps1` — create an email draft in drafts/
  - `tools/offline-status.ps1` — check if the local model server is running

### Handling Tasks and Handoffs
- **Read inbox tasks:** DSAI can check the inbox/ folder and pick up tasks dropped by online assistants.
- **Work on local projects:** Any project folder opened in VS Code can have its own NOTES.md and custom instructions (`.continue/rules/project.md`).
- **Save work for later:** DSAI can prepare files (draughts, checklists, summaries) for you to review and approve before sending or publishing.

---

## ❌ What DSAI CANNOT Do (Stays Online)

### Internet and Web
- **No browsing:** DSAI cannot access websites, fetch URLs, or download files.
- **No login:** Cannot log into any website, email account, bank, or cloud service.
- **No live sync:** Cannot connect to Dropbox, Google Drive, OneDrive, iCloud, or any cloud service.

### Banking and Finances (Live)
- **No bank sync:** Cannot connect to or read from online banking.
- **No workbook edits:** Cannot edit the live household Numbers workbook (that lives in iCloud or on a shared account).
- **No money transfers:** Cannot move money, set up payments, or approve transactions.

### Communication (Live)
- **No email send:** DSAI can draft an email, but **never sends it**. You or an online assistant must press Send.
- **No messages:** Cannot send text, WhatsApp, Teams, or any instant message.
- **No notifications:** Cannot send alerts or push notifications.

### Training and Customisation
- **No model updates:** DSAI's knowledge comes from its pre-trained model, built in 2026. It cannot learn from the internet or retrain itself.
- **No API calls:** Cannot call external APIs, webhooks, or services (except the localhost model server).

### Accuracy Guarantees
- **No invented numbers:** DSAI will never make up expense amounts, account balances, salary figures, or debt numbers. It will ask you to provide exact values or run `calc.ps1` for arithmetic.
- **No invented details:** Will not fabricate meeting attendees, decision makers, or quotes. It will work only with information in local files.

---

## 🤝 How Assistants Can Hand Off Work to DSAI

An online assistant can prepare work and drop it into the `inbox/` folder for DSAI to complete locally. The format is simple:

**inbox/TASK-NAME.md** should include:
1. **Title** — What is this task?
2. **Goal** — What does success look like?
3. **Files to touch** — Which files should DSAI read or edit?
4. **What stays online** — Any steps that need a website, email send, or live sync?

Example:

```markdown
# Task: Summarise Q3 expenses

**Goal:** Read EXPENSES.md and create a one-page summary showing:
- Total spent per category
- Spending trends vs. previous quarters
- Any alerts (budget overruns)

**Files to touch:**
- private/EXPENSES.md (read)
- docs/EXPENSE-SUMMARY.md (create)

**What stays online:**
- Emailing the summary to the accountant (DSAI drafts it; you send it)
```

DSAI will then:
1. Read the task from inbox/
2. Complete the local work
3. Update or create the requested files
4. Mark the task as done
5. Leave any "online" steps in a draft for you to complete

---

## 📝 Examples of Offline Work Sessions

### Session 1: Expense Categorisation
1. You paste a credit card statement into a chat with DSAI.
2. DSAI reads private/TRACKER-RULES.md to understand category rules.
3. DSAI suggests a category for each purchase (e.g., "Woolworths $45.30 → Groceries").
4. You confirm or correct each one.
5. DSAI runs `tools/expense-log.ps1 -Action add` to log each expense into EXPENSES.md.
6. DSAI runs `tools/expense-log.ps1 -Action leftovers` to show remaining budget.

### Session 2: Drafting a Work Email
1. You tell DSAI: "Draft an email to my manager about the Q3 report."
2. DSAI creates `drafts/2026-11-07-email-to-manager.md` with To, Subject, and Body.
3. You review it, ask for changes (tone, length, details).
4. DSAI updates the draft.
5. When you're happy, you copy it and send it yourself (or an online assistant sends it).

### Session 3: Project Planning
1. You open a new project folder in VS Code.
2. You ask DSAI to help plan a home renovation.
3. DSAI creates NOTES.md with sections for budget, timeline, contractors, and checklist.
4. You and DSAI iterate, filling in details and making decisions.
5. The plan stays in NOTES.md for you to review or share with contractors (manually).

---

## 🔐 Your Personal Vault

Your personal memory (vault) is completely private and encrypted.

- **When Locked (default):** DSAI starts completely blank. Your vault file exists but is encrypted.
- **When Unlocked:** You can run `tools/vault.ps1 -Action unlock` (you enter your passphrase), and your personal notes from `private/MEMORY.md` are loaded.
- **When you Lock:** Run `tools/vault.ps1 -Action lock`, DSAI encrypts everything back into your .vault file, and the readable files are securely wiped.

Your passphrase is **your private key**. Nobody else can open your vault without it, and there is no back door or "Forgot Password" reset.

---

## Questions?

For more details on vault setup, see `docs/USER-GUIDE.md` (Section 3). For a quick status check, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\offline-status.ps1
```

This shows:
- Whether the local model server is running
- Whether inbox/ has open tasks
- A one-line reminder of what stays online
