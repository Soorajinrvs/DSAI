# Private Workspace (Unencrypted Local Only)

This folder (`private/`) is **strictly ignored by Git** (`.gitignore`) and **strictly blocked from export** by `tools/export-dsai.ps1` (except for `README.md` and `*.template.md` files).

## How This Folder Works with Your Vault

1. **When Locked (Default):**
   - Only `README.md` and `*.template.md` files exist in this folder (they are templates, not personal data).
   - Personal files like `TRACKER-RULES.md`, `EXPENSES.md`, `MEMORY.md`, etc. do **not** exist on disk.
   - Your encrypted personal data sits safely inside `vault/<yourname>.vault` (AES-256 encrypted).
   - DSAI starts completely blank with zero personal information.

2. **When Unlocked (`tools/vault.ps1 -Action unlock`):**
   - Your encrypted `.vault` file is decrypted using your passphrase and restores personal files (e.g., `MEMORY.md`, `TRACKER-RULES.md`, `EXPENSES.md`).
   - You can read or edit these files while you work.
   - Templates (`.template.md` files) remain available for reference.

3. **When Locking Again (`tools/vault.ps1 -Action lock`):**
   - All personal files in `private/` (except `README.md` and `*.template.md`) are encrypted back into `vault/<yourname>.vault` using AES-256.
   - The unencrypted files are overwritten with random data and deleted from disk for security.

## Template Files in This Folder

Template files are **permanent templates** that stay readable even when locked:
- `MEMORY.template.md` — template for personal memory notes
- `TRACKER-RULES.template.md` — generic template for household tracker rules (no personal data)
- `EXPENSES.template.md` — blank expense log template

These files are included when you export DSAI, so they are available on new computers.

## Personal Files (Encrypted When Locked)

When you unlock your vault, you may edit personal files in this folder:
- `MEMORY.md` — your personal notes and preferences (encrypted at rest)
- `TRACKER-RULES.md` — your household budget rules and caps (encrypted)
- `EXPENSES.md` — your household expense log (encrypted)

These files **never leave your computer unencrypted**.

## Exporting This Folder

When you run `tools/export-dsai.ps1`:
- ✓ Copies `README.md` (this file)
- ✓ Copies all `*.template.md` template files
- ✓ Copies all encrypted `*.vault` files from `vault/`
- ✗ **Never** copies unlocked personal files (`MEMORY.md`, `TRACKER-RULES.md`, `EXPENSES.md`, etc.)
- ✗ **Warns you** if unlocked personal files are sitting on disk

**Privacy Rule:** Unlocked personal files are never exported. If you want to preserve them on another computer, lock your vault first (`tools/vault.ps1 -Action lock`) so they are encrypted into your `.vault` file, then export.

## Security Notes

- **No master key and no back door.** Your vault passphrase is your private key. A lost passphrase means the vault cannot be recovered.
- **Never store your vault passphrase** inside any file in this folder or anywhere else on the computer.
- **Secure file deletion:** When you lock your vault, readable personal files are overwritten with random data before deletion (no recovery possible).

---

See `docs/USER-GUIDE.md` (Section 3) for how to create and use your vault.
