# DSAI Backlog

Track every piece of work needed to make DSAI a clean, portable, offline assistant that anyone in the house can use safely.

## Core Items

- [x] **1. Repository skeleton & core docs** — Create folder structure, `README.md`, `.gitignore`, `BACKLOG.md`, `PROGRESS.md`, `docs/LEARN.md`, `docs/BUILD-LOG.md`, and `private/README.md`. *(Done 1 Nov 2026)*
- [x] **2. Blank project starter (`tools/new-project.ps1`)** — Create a clean "New Idea" folder in `Documents\DSAI Projects` with `.continue\rules` and `NOTES.md`, incrementing to "New Idea 2", etc. so it never overwrites existing work. *(Done 2 Nov 2026)*
- [x] **3. Portable start script (`tools/start-dsai.ps1`)** — Start `llama-server.exe` on `127.0.0.1:8081` using relative paths, check port 8081 is free, check at least 4 GiB free RAM, support `-DryRun`, and leave existing Windows Startup shortcut untouched. *(Done 3 Nov 2026)*
- [x] **4. Core AI glossary (`docs/LEARN.md`)** — Start plain-English guide covering LLMs, tokens, context window, and inference. *(Started 1–3 Nov 2026, completed 7 Nov 2026)*
- [x] **5. Finish portable start story & Fix docs (`tools/link-runtime.ps1` & `tools/start-dsai.ps1`)** — Safely link `DSAI\runtime` to `C:\Users\Tech\.continue\local-llm` using a directory junction so the ~5 GB model is never copied by default. Updated `start-dsai.ps1` to call `link-runtime.ps1` automatically. Stop and ask for confirmation if copying is the only option. Deployed global DSAI Continue rule. Updated all docs to explain file access (@-mention), project notes, personal memory, and vault lifecycle. *(Done 7 Nov 2026)*
- [x] **6. Memory notes (`private/MEMORY.template.md` & `docs/CONTINUE-SETUP.md`)** — Define general personal memory kept under `private/` (gitignored) plus per-project `NOTES.md`. Ensure DSAI sees zero personal memory when the vault is locked. *(Done 7 Nov 2026)*
- [x] **7. Personal encrypted vault (`tools/vault.ps1` & `tools/test-vault.ps1`)** — Per-user AES-256 + PBKDF2 encrypted vault (`vault/<user>.vault`). Create, unlock, lock, and status commands. Automated dummy-vault test using `TestVaultPassphrase-DoNotUse`. No master key, no back door, never stores or logs keys. *(Done 7 Nov 2026)*
- [x] **8. Exact-calculation helper (`tools/calc.ps1`)** — Safe PowerShell math evaluator so DSAI computes exact numbers instead of guessing. Document how to register it in Continue after backing up `config.yaml` to `C:\Users\Tech\.continue\_backup`. *(Done 7 Nov 2026)*
- [x] **9. General test set & scorer (`tests/questions.json` & `tools/run-tests.ps1`)** — Generic benchmark questions (including exact arithmetic) and an automated scoring script that works offline or against the live local server. *(Done 7 Nov 2026)*
- [x] **10. New-PC installer (`tools/install-dsai.ps1`)** — Set up DSAI on another Windows PC, configure Continue safely with backups, link or locate the local model without silent 5 GB copies or >100 MB downloads, and start blank unless a vault is unlocked. *(Done 7 Nov 2026)*
- [x] **11. Export to USB or cloud drive (`tools/export-dsai.ps1`)** — Copy publishable DSAI files and encrypted `.vault` files to a destination folder/USB stick. Strictly block `private/` plaintext, work/personal data, and raw 5 GB models unless explicitly confirmed. *(Done 7 Nov 2026)*
- [x] **12. Non-technical user guide (`docs/USER-GUIDE.md`)** — Plain-English guide for family members or new users covering daily use, creating and protecting their own vault key, and why a lost key cannot be reset by anyone. *(Done 7 Nov 2026)*
- [x] **13. Further ideas** — Documented below as future possibilities only (not built yet). *(Done 7 Nov 2026)*
- [x] **14. Offline DS Tracker helper** — Created `private/TRACKER-RULES.md`, `private/TRACKER-RULES.template.md`, `private/EXPENSES.md`, `private/EXPENSES.template.md`, and `tools/expense-log.ps1` for household budget tracking with category rules, funding order, and leftover calculation. *(Done 7 Nov 2026)*
- [x] **15. Offline workbench documentation** — Created `docs/OFFLINE-WORK.md` and `docs/OFFLINE-CAPABILITIES.md` explaining what DSAI can do offline (file work, math, expenses, vault, scripts) and what stays online (web, banks, email send, workbook edits). Added Section 7 to `USER-GUIDE.md`. *(Done 7 Nov 2026)*
- [x] **16. Inbox and handoff system** — Created `inbox/README.md`, `inbox/TEMPLATE.md`, and `tools/new-task.ps1` so online assistants can drop tasks for DSAI to complete locally. *(Done 7 Nov 2026)*
- [x] **17. Drafts and messaging** — Created `drafts/README.md` and `tools/new-draft.ps1` so DSAI can draft emails/messages that users review and send manually (never sends automatically). *(Done 7 Nov 2026)*
- [x] **18. Status and utility scripts** — Created `tools/offline-status.ps1` to check model server, open tasks, and reminders. *(Done 7 Nov 2026)*
- [x] **19. Updated vault and export** — Modified `tools/vault.ps1` to exclude all `*.template.md` files from encryption. Updated `tools/export-dsai.ps1` to export all `private/*.template.md` files and `private/README.md` while strictly blocking unlocked personal files. *(Done 7 Nov 2026)*

---

## 13. Further Ideas (Future Possibilities Only — Not Built Yet)

These ideas are recorded for future consideration once we have used DSAI across a few machines and projects:

1. **One-Click System Tray Toggle:** A tiny Windows tray icon showing green when `llama-server` is running on port 8081 and a padlock icon showing whether a personal vault is currently unlocked, with an auto-lock timer after 30 minutes of inactivity.
2. **Local Document Search (Offline RAG):** A lightweight folder watcher that indexes PDFs or Word documents inside a single project's folder using a tiny local embedding model, keeping each project's search index strictly inside that project.
3. **Voice Note Dictation:** An optional offline speech-to-text helper (`whisper.cpp`) to dictate ideas directly into a project's `NOTES.md` without internet access.
4. **Friendly Server Alias Migration Tool:** Once all projects are settled, a tiny interactive helper that backs up `config.yaml` and the Windows Startup shortcut together and switches the model alias from `cst-qwen3-8b` to `dsai` in one step.
5. **Read-Only USB Mode:** Allowing `start-dsai.ps1` to run directly off a fast USB 3.2 SSD stick on a guest PC without writing anything to the host PC's hard drive.