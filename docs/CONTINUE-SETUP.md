# DSAI in Continue: File Access, Rules & Memory

This guide explains how DSAI works with Continue, how to give it access to your files, how the global rules work, and how to connect optional features like the calculator and personal memory.

---

## 1. Understanding DSAI's Global Rules

When Continue starts DSAI, it automatically loads a global ruleset from `C:\Users\Tech\.continue\rules\dsai.md`. This ruleset tells DSAI:

1. **File Access:** You run in VS Code. When the user @-mentions files or has a folder open, treat that as readable context and do the work. Never refuse to help with files if the user has provided context.
2. **Internet:** You cannot browse the web, fetch URLs, or retrain yourself. If the user needs something from the internet, ask them to copy and paste it or save it as a file.
3. **Learning:** You CAN save facts to `NOTES.md` (per-project) or `MEMORY.md` (personal, if unlocked) so you improve for future chats. Never say you cannot learn.
4. **Math:** For exact arithmetic, use `tools/calc.ps1` or ask the user to run it. Do not guess numbers.
5. **Secrets:** Never ask for, invent, or repeat vault passphrases. Never put passwords or API keys anywhere.

**These rules are always active** for DSAI, regardless of which project folder you have open.

---

## 2. How to Give DSAI Access to Your Files

The key to working with DSAI is the `@` symbol in the Continue chat box:

1. **Type `@` in the Continue chat area** — a list appears showing:
   - Files you have open in VS Code tabs
   - Folders in your workspace
   - The VS Code terminal
   - Recent files and symbols
2. **Pick a file, folder, or terminal** — Continue attaches it as context to your message.
3. **Type your question or request** and send it.

Once you've attached context, DSAI can:
- Read and understand code or documents
- Explain what it sees
- Suggest changes or improvements
- Create new files or edit existing ones
- Run commands in the terminal (if you @-mentioned it)

**Example:** If you want DSAI to review your Python code, open the `.py` file in VS Code, type `@`, pick the file name, then type "Review this code for bugs" and send.

---

## 3. Project Notes and Personal Memory

DSAI keeps memory strictly separated into two places:

1. **Per-Project Notes (`NOTES.md` and `.continue\rules\project.md`):**
   - Created automatically by `tools\new-project.ps1` inside `Documents\DSAI Projects\<Project Name>`.
   - Because `.continue\rules\project.md` lives inside that project folder, Continue automatically loads those rules only when you have that specific project folder open in VS Code.
   - To load your project notes in a chat, type `@` in the Continue chat box and pick `NOTES.md`.
   - Add new facts or decisions to `NOTES.md` whenever you want DSAI to remember them in future chats.

2. **General Personal Memory (`C:\Users\Tech\DSAI\private\MEMORY.md`):**
   - This file **only exists while your vault is unlocked** via `tools\vault.ps1 -Action unlock`.
   - When your vault is locked, `private\MEMORY.md` is encrypted into your vault and removed from disk, so DSAI starts completely blank.
   - To load your personal memory in a chat after unlocking your vault, type `@` and pick `MEMORY.md` from the file list.
   - When you lock your vault, the file is securely wiped and removed from disk.

---

## 4. How to Unlock/Lock Your Personal Vault

See `docs\USER-GUIDE.md` (Section 3) for complete instructions. Quick reference:

**Create your vault (first time only):**
```powershell
powershell -ExecutionPolicy Bypass -File .\tools\vault.ps1 -Action init -VaultName yourname
```

**Unlock your vault at the start of the day:**
```powershell
powershell -ExecutionPolicy Bypass -File .\tools\vault.ps1 -Action unlock -VaultName yourname
```

**Lock your vault when you're finished:**
```powershell
powershell -ExecutionPolicy Bypass -File .\tools\vault.ps1 -Action lock -VaultName yourname
```

**Check vault status anytime:**
```powershell
powershell -ExecutionPolicy Bypass -File .\tools\vault.ps1 -Action status
```

---

## 5. Using the Exact Calculator (`tools\calc.ps1`) in VS Code

Language models are not calculators. DSAI includes `tools\calc.ps1` to compute exact numbers instead of guessing.

### Option A: Run in the Terminal (Recommended)

In VS Code, open the terminal and run:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\Tech\DSAI\tools\calc.ps1" "(487 * 19) + (1352 / 8) - 412"
```

Then copy the result and paste it (or `@terminal`) into Continue so DSAI uses the exact answer.

### Option B: Run from Continue

Type `@` in Continue, pick the Terminal, and run:

```powershell
python -ExecutionPolicy Bypass -File "C:\Users\Tech\DSAI\tools\calc.ps1" "(487 * 19) + (1352 / 8) - 412" -Json
```

DSAI can then read the terminal output and use the exact result.

---

## 6. Renaming the Server Alias (`cst-qwen3-8b` -> `dsai`) Safely Later

Right now, the live Windows Startup shortcut starts `llama-server.exe` with `--alias cst-qwen3-8b`, and `C:\Users\Tech\.continue\config.yaml` matches that name.

**Do not rename one without the other**, or Continue will get a "model not found" error when talking to port `8081`. Note that `llama.cpp` also accepts whatever model name matches its `--alias` parameter.

When you are ready to change the alias to `dsai` later, follow these exact steps:

1. **Back up `config.yaml`:**
   Save a copy of `C:\Users\Tech\.continue\config.yaml` into `C:\Users\Tech\.continue\_backup\`.
2. **Back up the Windows Startup shortcut:**
   Copy the `.lnk` file from `$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup` into `C:\Users\Tech\.continue\_backup\`.
3. **Update both places together:**
   - In the Startup shortcut target (or when running `tools\start-dsai.ps1 -ServerAlias dsai`), change `--alias cst-qwen3-8b` to `--alias dsai`.
   - In `C:\Users\Tech\.continue\config.yaml`, change `model: cst-qwen3-8b` to `model: dsai`.
4. **Restart the server:**
   Stop the running `llama-server.exe` process and start it again so port `8081` serves the new alias `dsai`.