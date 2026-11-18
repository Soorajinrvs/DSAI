# DSAI — Portable Offline AI Assistant

DSAI is a clean, private, general-purpose offline AI assistant for Windows. It runs entirely on your own computer with zero internet required, powered by the local model `Qwen3-8B-Q4_K_M` running through `llama.cpp` on `127.0.0.1:8081` and connected to the **Continue** extension in VS Code.

Every new project starts with a clean slate. DSAI keeps core assistant tools completely separate from your personal notes and specialist projects, so you can share or copy the assistant to another PC or USB stick without ever leaking private information.

## Key Features

- **100% Offline & Private:** Everything runs locally on your machine at roughly 14 tokens per second. No cloud accounts, no subscriptions, no data leaving your PC.
- **Blank-Slate Projects:** Use `tools/new-project.ps1` to spin up isolated folders in `Documents\DSAI Projects` with their own project rules and `NOTES.md`.
- **Encrypted Personal Vault:** Keep your personal memory notes locked with AES-256 encryption (`tools/vault.ps1`). When locked or copied to another PC, DSAI starts completely blank. Only your personal passphrase can unlock your memory.
- **Exact Calculation Helper:** Language models guess at arithmetic. DSAI includes `tools/calc.ps1` so exact calculations are computed by Windows PowerShell instead of guessed.
- **Portable by Design:** Link to an existing local model without duplicating the 5 GB file, export a clean copy to USB or cloud drive (`tools/export-dsai.ps1`), and set up a new PC in minutes (`tools/install-dsai.ps1`).

## Folder Structure

- `docs/USER-GUIDE.md` — Simple, plain-English guide for everyday use, unlocking your vault, and creating your own key.
- `docs/LEARN.md` — Plain-English explanations of AI and security concepts (tokens, GGUF, quantisation, encryption, and how DSAI fits together).
- `docs/CONTINUE-SETUP.md` — How to connect your unlocked memory and exact calculator to Continue safely.
- `docs/BUILD-LOG.md` — Step-by-step history of how DSAI was built.
- `tools/` — PowerShell scripts for starting DSAI, managing projects, locking/unlocking vaults, calculating math, testing, installing, and exporting.
- `vault/` — Holds encrypted `.vault` files that are safe to back up or carry on a USB stick.
- `private/` — Local-only workspace for unlocked personal memory (`MEMORY.md`). Never exported, never tracked by Git.
- `tests/` — Generic benchmark questions and automated scoring script.

## Quick Start

1. **New to DSAI?** Read `docs/USER-GUIDE.md` for a simple walkthrough.
2. **Link & Start the Server:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\tools\link-runtime.ps1
   powershell -ExecutionPolicy Bypass -File .\tools\start-dsai.ps1
   ```
3. **Create a Blank Project:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\tools\new-project.ps1
   ```
4. **Create or Unlock Your Personal Vault:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\tools\vault.ps1 -Action status
   ```

## Credits & Acknowledgements

- **Model:** Qwen3-8B-Q4_K_M by the Alibaba Qwen team (Apache 2.0 Licence).
- **Inference Server:** `llama.cpp` by Georgi Gerganov and contributors (MIT Licence).
- **Editor Integration:** Continue extension for Visual Studio Code (Apache 2.0 Licence).

## Licence

Licence not chosen yet. All original scripts and documentation in this repository are currently kept for personal and household use prior to selecting an open-source licence for GitHub publication.