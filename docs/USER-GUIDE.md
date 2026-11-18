# DSAI Everyday User Guide

Welcome to **DSAI**—your private, offline AI assistant. Everything runs right here on this computer. It does not need the internet, it never sends your questions to any company, and each person who uses it can keep their own private notes locked behind their own secret passphrase.

---

## 1. What Can DSAI Help With?
You can ask DSAI to:
- Draft emails, letters, checklists, or summaries.
- Brainstorm ideas for a trip, event, recipe, or hobby project.
- Explain complicated terms or documents in plain English.
- Organise notes inside a dedicated project folder.

**One thing to remember:** AI chat models work by predicting words, which means they are **bad at exact mental arithmetic** (like adding up a long receipt or multiplying big numbers). Whenever exact numbers matter, use the built-in DSAI calculator (`tools\calc.ps1`) described in Section 5 below.

---

## 2. Starting DSAI and Opening a Blank Project

### Step A: Make sure DSAI is running
On the main computer, DSAI usually starts automatically when Windows logs in. If you ever need to check or start it manually, open PowerShell in the `DSAI` folder and run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\start-dsai.ps1
```

If it says port `8081` is already listening, the assistant is already awake and ready!

### Step B: Create a fresh project folder
Every new topic gets its own clean folder so your projects never get mixed up. To make a new project folder, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\new-project.ps1
```

- This creates a folder called `New Idea` (or `New Idea 2`, `New Idea 3`, etc.) inside your `Documents\DSAI Projects` folder.
- Open that folder in **VS Code**, click the **Continue** icon on the left sidebar, and start chatting with **DSAI**.
- Anything you write in that folder's `NOTES.md` file stays strictly in that project.

---

## 3. Your Personal Vault (Creating and Using Your Own Key)

By default, DSAI starts **completely blank**—it does not know your name, preferences, or personal reminders. If you want DSAI to remember helpful context about you across projects, you can create your own **Personal Vault**.

Every person (for example, you, your spouse, or a family member) can have their own separate vault file in the `vault\` folder, protected by their own secret passphrase (key).

### Important Rule About Your Passphrase (Key)
> **If you forget or lose your passphrase, your vault cannot be recovered.**
>
> There is no master key, no back door, and no "Forgot Password" reset button. Nobody else—not even the person who built or owns the computer—can unlock your vault without your exact passphrase.
>
> **How to choose and keep your key safe:**
> 1. Pick a memorable passphrase made of 4 or 5 random words or a sentence only you know (at least 12 characters long).
> 2. Write it down on a piece of paper kept in a safe place at home, or store it in your personal password manager on your phone.
> 3. Never type your passphrase into an AI chat window or save it in an unencrypted text file on the computer.

### Step 1: Create your own vault (first time only)
Replace `yourname` with your first name or nickname (for example, `drashti` or `sunny`):

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\vault.ps1 -Action init -VaultName yourname
```
- The script will ask you to type your new passphrase twice (characters are hidden while you type).
- It creates your encrypted file at `vault\yourname.vault` and opens `private\MEMORY.md` so you can write down anything you want your assistant to know when you are working.

### Step 2: Lock your vault when you finish
Whenever you finish using the computer, lock your vault:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\vault.ps1 -Action lock -VaultName yourname
```
- You will enter your passphrase to confirm.
- Your notes in `private\MEMORY.md` are encrypted back into `vault\yourname.vault`, and the readable file in `private\` is securely wiped and removed.
- Once locked, DSAI is completely blank again.

### Step 3: Unlock your vault next time you sit down
When you come back to work:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\vault.ps1 -Action unlock -VaultName yourname
```
- Enter your passphrase, and your `private\MEMORY.md` file is restored until you lock it again.

### Step 4: Check if the vault is currently locked or unlocked
Not sure if someone left the vault unlocked? Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\vault.ps1 -Action status
```

---

## 4. Using Your Personal Memory & Project Notes in Chat

## Attaching Files or Folders with @

The most important thing: **Continue shows DSAI your files when you ask it to.** This is how DSAI can actually help you with your work.

To give DSAI access to a file, folder, or your VS Code terminal:

1. **Open the file or project folder in VS Code.**
2. **In the Continue chat box, type `@` and a list will appear** showing files, folders, the terminal, and more.
3. **Pick the file or folder you want DSAI to read and work with.**
4. **Type your question or task, then send the message.**

Once you've attached the context, DSAI can:
- Read and understand the code or document
- Suggest changes or improvements
- Create new files or edit existing ones
- Run commands in the terminal (if you @-mentioned it)

**Important:** DSAI can only work on files you explicitly attach. If you forget to @-mention a file, DSAI will ask you to do so. This is a safety feature—DSAI never reads files on your computer without your permission.

## Project Notes (`NOTES.md`)

Inside any project folder in `Documents\DSAI Projects`:

- Type `@NOTES.md` in the Continue chat box to attach your project's notes.
- DSAI reads them and keeps them in mind for the rest of that chat.
- Add new facts or decisions to `NOTES.md` whenever you want DSAI to remember them in future chats (just open the file and type).

## Personal Memory (`private/MEMORY.md`)

**Only available when your vault is unlocked.**

Your personal memory lives at `C:\Users\Tech\DSAI\private\MEMORY.md`. It stays locked and encrypted in your vault when you are finished.

- After you unlock your vault with `tools/vault.ps1 -Action unlock`, the file appears in `private/`.
- Open it in VS Code and type `@` then pick `MEMORY.md` to attach it to a chat.
- DSAI can then use your personal preferences and reminders in any conversation.
- When you lock your vault, the file is encrypted and removed from disk, so DSAI starts completely blank again.

### Why Memory Works This Way

- **Personal memory is private.** It only exists while your vault is unlocked on your computer.
- **Project notes are always available.** They live in each project folder, so they travel with the project.
- **DSAI never remembers on its own.** Every chat starts fresh unless you @-mention a notes file.

---

## 5. Exact Calculator (Never Let the AI Guess Math)

Whenever you need an exact sum, percentage, or measurement conversion, run `tools\calc.ps1`:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\calc.ps1 "(487 * 19) + (1352 / 8) - 412"
```

You can also use common math helpers like `sqrt(144)`, `round(19.95 * 1.10, 2)`, or `pow(2, 10)`. See `docs\CONTINUE-SETUP.md` for how to trigger the calculator directly from inside the Continue chat box.

---

## 6. Copying DSAI to a USB Stick or Another PC

If you want to take DSAI to another Windows computer or save a backup on a USB stick:

1. **First, make sure your vault is locked:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\tools\vault.ps1 -Action status
   ```
2. **Run the export script:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\tools\export-dsai.ps1 -Destination "E:\DSAI-Backup"
   ```
   *(Replace `E:\DSAI-Backup` with your USB drive or folder path.)*
   - This copies all DSAI tools, guides, and your encrypted `.vault` files.
   - It **never** copies your unencrypted `private\` folder, and it **never** copies the huge 5 GB model file unless you specifically ask it to.
3. **On the new computer:** Open PowerShell inside the copied `DSAI` folder and run:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\tools\install-dsai.ps1
   ```

---

## 7. What DSAI Can and Cannot Do (Offline vs. Online)

DSAI is a **completely offline** assistant. It works on this computer without the internet and never sends your questions or personal data to any company.

### CAN do offline (all on this computer):
- ✅ Read and edit local files
- ✅ Draft emails, messages, and notes (save them, but never send)
- ✅ Exact math via `tools\calc.ps1` (receipts, budgets, percentages, conversions)
- ✅ Categorise and log household expenses (read `private/TRACKER-RULES.md`, suggest categories, add to `EXPENSES.md`)
- ✅ Show remaining budget for Groceries, Eating Out, and Allowances — just ask "what's left for eating out?" and DSAI will run the expense tracker automatically. No file @-mention needed.
- ✅ Write personal vault notes (when unlocked)
- ✅ Create project folders and NOTES.md files
- ✅ Checklists and meeting summaries
- ✅ Rewrite, summarise, or reorganise text
- ✅ Run any PowerShell script in the `tools/` folder
- ✅ Pick up tasks from the `inbox/` folder (dropped by another assistant)

### CANNOT do (stays with online assistants):
- ❌ Browse the internet or access websites
- ❌ Log into banks or any account
- ❌ Edit the live household Numbers workbook (that's in iCloud)
- ❌ Send emails or instant messages (can only draft locally)
- ❌ Sync with cloud services (Dropbox, Google Drive, etc.)
- ❌ Retrain its own model or learn from the internet
- ❌ Make up numbers, balances, or financial figures

**The Rule:** If something needs the internet, a website login, or a live sync with a bank/cloud service, DSAI will draft, calculate, or note-take offline—and tell you the online assistant should do the live step. DSAI will never pretend it did an online task when it didn't.

For complete details, see:
- `docs/OFFLINE-WORK.md` — What you can do offline with DSAI
- `docs/OFFLINE-CAPABILITIES.md` — How to use each offline capability