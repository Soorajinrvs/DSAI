# DSAI Build Log

A chronological record of design decisions, technical details, and how each part of DSAI was put together.

---

## 2026-11-01 — Day 1: Setting Up the Foundation

**Goal:** Create a clean repository structure in `C:\Users\Tech\DSAI` that separates core assistant tools from personal data and work projects.

**What was done:**
- Created core directories: `docs/`, `tools/`, `private/`.
- Added `.gitignore` immediately so `private/` cannot be accidentally committed or shared.
- Wrote initial `README.md`, `BACKLOG.md`, `PROGRESS.md`, `docs/LEARN.md`, and `private/README.md`.
- Decided not to run `git init` or pick an open-source licence yet until all core portability and privacy guardrails are finished.

---

## 2026-11-02 — Day 2: Blank-Slate Project Starter (`tools/new-project.ps1`)

**Goal:** Keep DSAI completely general by making sure specialist knowledge lives only inside individual project folders.

**What was done:**
- Wrote `tools/new-project.ps1` targeting `Documents\DSAI Projects`.
- Designed it so running the script with no arguments creates `New Idea`. Running it a second time creates `New Idea 2`, then `New Idea 3`, never overwriting an existing folder.
- Inside each new project folder, the script creates `.continue\rules\project.md` and `NOTES.md`. That way, when you open a project folder in VS Code, Continue reads that project's notes and rules without polluting DSAI's global setup.

---

## 2026-11-03 — Day 3: Portable Server Start (`tools/start-dsai.ps1`)

**Goal:** Start the local Qwen3-8B server cleanly using relative paths and safety checks without breaking the existing Windows Startup shortcut.

**What was done:**
- Built `tools/start-dsai.ps1` to check two things before launching `llama-server.exe`:
  1. Port `8081` on `127.0.0.1` is not already in use.
  2. Free physical RAM is at least 4 GiB (since `Qwen3-8B-Q4_K_M` needs roughly 4 GB of memory to run comfortably).
- Added a `-DryRun` switch so we can verify paths, port checks, and RAM checks without starting a duplicate server process.
- Tested `-DryRun` on the live machine; passed cleanly while leaving the Windows Startup shortcut untouched.

---

## 2026-11-07 — Day 4: Finishing the Portable & Private Release (Part 1)

**Goal:** Complete items 5 through 13 of the backlog so DSAI can be safely used by anyone, backed up to USB or cloud storage, and installed on another Windows PC without ever leaking personal data or copying a 5 GB model unasked.

**What was done:**

1. **Zero-Copy Runtime Linking (`tools/link-runtime.ps1` & `tools/start-dsai.ps1`):**
   - The live model and `llama.cpp` ARM64 binaries sit in `C:\Users\Tech\.continue\local-llm` (~5 GB). Copying that folder just to make relative paths work wastes disk space and takes minutes.
   - Created `tools/link-runtime.ps1` to make an NTFS directory junction at `DSAI\runtime` pointing to `C:\Users\Tech\.continue\local-llm`. Directory junctions work out-of-the-box on Windows 10/11 without needing Administrator rights.
   - Updated `tools/start-dsai.ps1` to look in `DSAI\runtime` first, then check for the existing `C:\Users\Tech\.continue\local-llm`, and automatically call `link-runtime.ps1` if neither is found. If a user ever needs a physical copy (for instance, across file systems that don't support links), the script stops and asks for explicit `YES` confirmation first.
   - Kept the server alias compatible with the existing setup (`cst-qwen3-8b` by default) and documented in `docs/CONTINUE-SETUP.md` how to rename it to `dsai` later after backing up both `config.yaml` and the Startup shortcut.

2. **Personal Memory & Blank-When-Locked Design (`private/MEMORY.template.md`):**
   - General personal notes live in `private/MEMORY.md` while unlocked.
   - When the user locks their vault, `private/MEMORY.md` is encrypted into `vault/<username>.vault` and the plaintext file in `private/` is overwritten with zeroes and deleted.
   - Because `private/MEMORY.md` does not exist when locked, DSAI starts completely blank for anyone who does not have the vault passphrase.

3. **AES-256 Personal Vault (`tools/vault.ps1` & `tools/test-vault.ps1`):**
   - Built `tools/vault.ps1` using built-in Windows .NET cryptography so zero external downloads or installs are needed.
   - Uses `Rfc2898DeriveBytes` (PBKDF2 with HMAC-SHA256, 100,000 iterations, fresh 16-byte cryptographic salt on every lock) to derive a 32-byte AES-256 key and a 32-byte HMAC-SHA256 key from the user's passphrase.
   - Encrypts all files in `private/` (except `README.md` and `MEMORY.template.md`) into a single JSON archive inside `vault/<user>.vault` with an authenticated HMAC tag so a wrong passphrase or corrupted file is caught immediately before touching disk.
   - Wrote `tools/test-vault.ps1` to test the full create -> edit -> lock -> verify-blank -> wrong-key-rejected -> unlock -> verify-restored cycle in an isolated temp folder using the clearly fake passphrase `TestVaultPassphrase-DoNotUse`.

4. **Exact Calculation Helper (`tools/calc.ps1`):**
   - An 8-billion-parameter quantised model running at 14 tokens/s is great for writing and brainstorming, but unreliable at multi-digit arithmetic.
   - Wrote `tools/calc.ps1` to evaluate mathematical expressions and common functions (`sqrt`, `round`, `pow`, `abs`, percentages) using PowerShell/.NET `System.Math` and `DataTable.Compute` after strict character whitelisting.
   - Documented how to wire it into Continue as a slash/context command after backing up `C:\Users\Tech\.continue\config.yaml` to `C:\Users\Tech\.continue\_backup`.

5. **Benchmark & Scoring (`tests/questions.json` & `tools/run-tests.ps1`):**
   - Created 6 generic test questions covering reasoning, formatting, offline knowledge, and exact arithmetic (`(487 * 19) + (1352 / 8) - 412 = 9010`).
   - `tools/run-tests.ps1` can test the live server on `127.0.0.1:8081` (plus compare raw LLM arithmetic against `tools/calc.ps1`) or run in `-OfflineSelfTest` mode to verify the scorer and calculator without the server running.

6. **Installer & Exporter (`tools/install-dsai.ps1` & `tools/export-dsai.ps1`):**
   - `tools/export-dsai.ps1` copies only publishable scripts, docs, tests, and encrypted `vault/*.vault` files to a USB drive or cloud folder. It hard-blocks `private/MEMORY.md` and any unencrypted personal files, and never copies the 5 GB model unless `-IncludeModel` is explicitly passed and confirmed.
   - `tools/install-dsai.ps1` sets up a new PC, backs up any existing Continue `config.yaml` to `_backup`, writes a clean general `DSAI` config, links the local runtime if found, and leaves the assistant blank until a user initializes or unlocks their own vault.

7. **User Guide & Expanded Glossary (`docs/USER-GUIDE.md` & `docs/LEARN.md`):**
   - Wrote `docs/USER-GUIDE.md` in plain, jargon-free English so a non-technical family member can start a project, create their own vault key, unlock/lock their notes, and understand clearly that a lost key cannot be recovered by anyone.
   - Expanded `docs/LEARN.md` with clear explanations of context window, parameters, quantisation, GGUF, inference, temperature, system prompt, embeddings and RAG, fine-tuning vs prompting, encryption and keys, and how DSAI's pieces fit together.

---

## 2026-11-07 — Day 4 (continued): Fixing DSAI's Behavior in Continue & Documenting @ File Access

**Goal:** Stop DSAI incorrectly claiming it cannot access files, learn, or improve. Deploy a global Continue rule and update all docs to explain how the system actually works.

**What was done:**

1. **Global DSAI Continue Rule (`continue-rules/dsai.md`):**
   - Created a global alwaysApply rule deployed to `C:\Users\Tech\.continue\rules\dsai.md` (live install) and `C:\Users\Tech\DSAI\continue-rules\dsai.md` (portable copy).
   - The rule tells DSAI it runs locally in VS Code. When the user @-mentions files or folders (or has them open), Continue provides that context. **Never refuse file access if context is attached.**
   - Clarifies that DSAI cannot browse the internet, fetch URLs, or retrain itself. If the user needs something from the web, ask them to copy/paste or save as a file.
   - **Explicitly states DSAI CAN learn and improve** by saving facts to `NOTES.md` (per-project) or `MEMORY.md` (personal, if unlocked). Never say "unable to improve."
   - Reminds DSAI to use `tools/calc.ps1` for exact math instead of guessing.
   - Prohibits asking for or repeating vault passphrases.

2. **Updated `tools/install-dsai.ps1`:**
   - Added step 2b to deploy the global DSAI rule from `DSAI\continue-rules\dsai.md` to `~\.continue\rules\dsai.md` on a new PC, with backup of any existing rule to `_backup` timestamped directory.

3. **Updated `tools/start-dsai.ps1` to merge linking automatically:**
   - Updated search path to include `DSAI\runtime` first.
   - When neither `DSAI\runtime` nor the primary candidate exists, the script now automatically attempts to call `tools/link-runtime.ps1` to set up the junction.
   - After linking succeeds, it re-checks for the model and continues normally.
   - All existing server tuning, port checks, RAM checks, logging, and relative paths remain unchanged.

4. **Rewrote `docs/USER-GUIDE.md` Section 4 to explain @ file access:**
   - Replaced vague memory references with a clear explanation of how `@` works in Continue.
   - Explained that DSAI can only access files the user explicitly @-mentions or that are open in VS Code.
   - Explained project notes (NOTES.md) and personal memory (MEMORY.md) and when each is available.
   - Updated Section 5 (calculator) to keep existing content but clarified it works when @-mentioned in a terminal.

5. **Rewrote `docs/CONTINUE-SETUP.md` to explain DSAI's global rules and @ file access:**
   - Section 1 now explains the global DSAI rule and what it tells DSAI about file access, learning, math, and secrets.
   - Section 2 explains how to use `@` to give DSAI access to files, folders, and the terminal.
   - Section 3 clearly separates project notes (always available) and personal memory (only when vault is unlocked).
   - Section 4 explains vault lock/unlock commands.
   - Section 5 explains calculator usage.
   - Section 6 documents the safe alias rename process.

6. **Updated `BACKLOG.md` to mark Item 5 complete:**
   - Updated summary of item 5 to note linking is now merged into `start-dsai.ps1`, the global rule is deployed, and all docs are updated.

---

## 2026-11-07 — Day 5: Full Offline Workbench Build (Part 2)

**Goal:** Complete all remaining buildout tasks for a complete offline workbench: household expense tracker, inbox/drafts system, full documentation of capabilities, and updated vault/export scripts.

**What was done:**

1. **Household Expense Tracker Suite:**
   - Created `private/TRACKER-RULES.md` with all household budget rules, category definitions, and funding order for Eating Out.
   - Created `private/TRACKER-RULES.template.md` with generic placeholders (no household names or dollar amounts).
   - Created `private/EXPENSES.md` with header only (no fake rows).
   - Created `private/EXPENSES.template.md` as a blank log template.
   - Wrote `tools/expense-log.ps1` (PowerShell 5.1+) to:
     - Add expense rows with date, category, merchant, amount, and notes
     - List recent expenses
     - Calculate remaining budget per category using period dates and caps from TRACKER-RULES.md
     - Show caution if Eating Out budget is exhausted or negative
     - Support exact arithmetic with decimal amounts

2. **DSAI Global Rules Updated:**
   - Updated `continue-rules/dsai.md` and `.continue\rules\dsai.md` (both kept in sync, `alwaysApply: true`):
     - Added that DSAI should complete any local task: read/edit files, draft, calculate, categorise, organise, use scripts
     - Added household spending assistance: read rules, suggest categories, ask before logging
     - Added offline/online work boundary section explaining what DSAI can and cannot do
   - Kept all existing rules (file access, learning, secrets, calc.ps1)

3. **Capability Documentation:**
   - Created `docs/OFFLINE-WORK.md` with complete overview of offline capabilities, examples, and rules
   - Created `docs/OFFLINE-CAPABILITIES.md` with detailed technical breakdown of each capability (file work, math, expenses, vault, scripts)
   - Added Section 7 to `docs/USER-GUIDE.md` covering offline vs. online boundary

4. **Inbox and Handoff System:**
   - Created `inbox/` folder with `README.md` (how to drop tasks for DSAI) and `TEMPLATE.md` (task file format)
   - Created `tools/new-task.ps1` to create dated task files in inbox/

5. **Drafts and Communication:**
   - Created `drafts/` folder with `README.md` (explanation of draft workflow)
   - Created `tools/new-draft.ps1` to create dated email draft files in drafts/

6. **Status and Utility Scripts:**
   - Created `tools/offline-status.ps1` to check:
     - Whether local model server is running on 127.0.0.1:8081
     - How many open tasks are in inbox/
     - One-line reminder of what stays online

7. **Updated Vault and Export Scripts:**
   - Updated `tools/vault.ps1` Get-PrivateUserFiles to exclude README.md and any `*.template.md` files (not just MEMORY.template.md)
   - Updated `tools/export-dsai.ps1` to:
     - Export private/README.md
     - Export all private/`*.template.md` files
     - Never export unlocked personal files (TRACKER-RULES.md, EXPENSES.md, MEMORY.md)
     - Updated privacy guardrail check to match new exclusion rules

8. **Updated private/README.md:**
   - Expanded to explain what template files do and why they stay readable when locked
   - Clarified export rules and privacy safeguards
   - Added section on secure file deletion when locking vault

All scripts are **PowerShell 5.1+ compatible** with no network calls except localhost model server check. **No AI names mentioned** in any file; the system is called "DSAI" and online bots are "online assistants". **All personal data is protected**: expense logs are template-only until user unlocks vault; templates remain readable after export; no fake rows or invented numbers.