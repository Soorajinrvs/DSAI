# DSAI Progress Log

## 2026-11-01 — Repo Skeleton & Core Docs
- Created `C:\Users\Tech\DSAI` folder structure (`docs/`, `tools/`, `private/`).
- Wrote initial `README.md`, `.gitignore`, `BACKLOG.md`, `PROGRESS.md`, `docs/LEARN.md`, `docs/BUILD-LOG.md`, and `private/README.md`.
- Confirmed `private/` is ignored by Git so personal notes stay out of version control.

## 2026-11-02 — Blank Project Starter (`tools/new-project.ps1`)
- Built `tools/new-project.ps1` to create a fresh project inside `Documents\DSAI Projects`.
- Configured automatic numbering (`New Idea`, `New Idea 2`, `New Idea 3`) so existing folders are never overwritten.
- Added per-project `.continue\rules` and `NOTES.md` templates so specialist knowledge lives strictly inside each project folder.

## 2026-11-03 — Portable Start Script (`tools/start-dsai.ps1`)
- Built `tools/start-dsai.ps1` using relative paths.
- Added pre-flight checks for TCP port `8081` availability and at least 4 GiB of free system RAM.
- Added `-DryRun` flag and verified dry-run output without disturbing the existing Windows Startup shortcut.

## 2026-11-07 — Full Portable Release: Runtime Link, Vault, Calculator, Tests, Installer, Export & User Guide
- **Portable Runtime Linking (`tools/link-runtime.ps1` & `tools/start-dsai.ps1`):** Added safe directory-junction linking from `DSAI\runtime` to `C:\Users\Tech\.continue\local-llm` so the ~5 GB GGUF model is never copied by default. If linking fails or `-CopyIfNeeded` is required, the script stops and asks the user for explicit confirmation first. Preserved all existing `start-dsai.ps1` behaviour and kept the Windows Startup shortcut untouched.
- **Memory Architecture (`private/MEMORY.template.md` & `docs/CONTINUE-SETUP.md`):** Set up the two-tier memory system: general user preferences in `private/MEMORY.md` (present only while the vault is unlocked) and project-specific context in each project's `NOTES.md`.
- **Encrypted Personal Vault (`tools/vault.ps1` & `tools/test-vault.ps1`):** Built a per-user offline vault using .NET `Rfc2898DeriveBytes` (PBKDF2-SHA256, 100,000 iterations, random 16-byte salt) and `AesManaged`/`Aes` (AES-256-CBC, random 16-byte IV, plus HMAC-SHA256 integrity verification). Added `init`, `unlock`, `lock`, and `status` actions, plus `tools/test-vault.ps1` using `TestVaultPassphrase-DoNotUse`.
- **Exact Calculation Helper (`tools/calc.ps1`):** Built a safe arithmetic evaluator so DSAI can delegate exact calculations to PowerShell instead of guessing. Documented how to register it in Continue after backing up `C:\Users\Tech\.continue\config.yaml` to `C:\Users\Tech\.continue\_backup`.
- **Benchmark Suite (`tests/questions.json` & `tools/run-tests.ps1`):** Created a generic 6-question benchmark (including exact arithmetic) and a scorer script supporting both live server testing (`127.0.0.1:8081`) and offline self-test verification.
- **New-PC Installer & Exporter (`tools/install-dsai.ps1` & `tools/export-dsai.ps1`):** Created an offline installer for setting up another Windows PC and an export script for copying DSAI + encrypted `.vault` files to USB or iCloud without ever copying `private/` plaintext or silently duplicating the 5 GB model.
- **Documentation & Glossary (`docs/USER-GUIDE.md`, `docs/LEARN.md`, `docs/CONTINUE-SETUP.md`):** Wrote a plain-English family user guide, expanded `docs/LEARN.md` to cover every core AI and encryption term, and updated `BACKLOG.md` with future ideas.