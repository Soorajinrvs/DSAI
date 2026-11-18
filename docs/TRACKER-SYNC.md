# Live tracker snapshot and write queue

DSAI cannot open or edit the live Apple Numbers workbook, even when this PC is online. That file is an iCloud Numbers document. The online household tracker remains the only editor of the live workbook.

Instead, the two sides share plain files in `private/`:

## Read: `private/LIVE-SNAPSHOT.csv`

The online tracker overwrites this file after it updates the live workbook. It is a read-only snapshot for DSAI.

Columns:

```text
Date,Category,Merchant,Amount,Notes
```

- `Date` is the purchase date in `YYYY-MM-DD`.
- `Amount` is negative for expenses and positive for refunds or income.
- Do not include account numbers, passwords, salary or net-pay figures, account balances, or debt balances.

Until this file exists, `tools/expense-log.ps1` uses `private/EXPENSES.md`.

## Write: `private/TRACKER-OUTBOX.csv`

When you add a spend in DSAI, it is appended here with `Status=pending`. The online tracker applies pending rows to the live workbook, then refreshes `LIVE-SNAPSHOT.csv` and marks those rows `applied` (or removes them).

Columns:

```text
Date,Category,Merchant,Amount,Notes,Status,QueuedAt
```

DSAI never writes to any `.numbers` file.

## Checking Leftovers (Budget Remaining)

To see how much is left in a budget category, just ask DSAI: **"What's left for eating out?"** or **"How much budget is remaining for Groceries?"**

DSAI will show you a command block. **Click Run (the play triangle at the top right of the block), then press Enter in the terminal.** Do **not** click Apply: Apply edits a file, and with no file open Continue shows "Could not resolve filepath to apply changes". Continue only shows Run on blocks tagged `bash`/`sh`, so DSAI's rules always tag commands as `bash`. No need to @-mention any files: the paths are built into `tools/expense-log.ps1` (it reads `private/TRACKER-RULES.md` for caps and `private/LIVE-SNAPSHOT.csv` for spending).

Other ways to see the same numbers: Ctrl+Shift+P, **Tasks: Run Task**, **DSAI: Show leftovers** (from `.vscode/tasks.json`), or double-click `tools\show-leftovers.cmd`.

## Commands

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\expense-log.ps1 -Action leftovers
powershell -ExecutionPolicy Bypass -File .\tools\expense-log.ps1 -Action list
powershell -ExecutionPolicy Bypass -File .\tools\expense-log.ps1 -Action add -Date 2026-11-07 -Category Groceries -Merchant Woolworths -Amount -50
```