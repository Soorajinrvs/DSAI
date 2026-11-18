# User-Facing Household Tracker Commands

Quick reference for common household tracking tasks using DSAI tools.

## Leftovers — What is left in each budget?

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\Tech\DSAI\tools\expense-log.ps1 -Action leftovers
```

**Output:**
```
=== Budget Leftovers ===
Period: 14 Oct 2026 to 10 Nov 2026
Source: live snapshot (HH:MM on DD MMM) plus X pending writes

Groceries: cap 300.00 | spent 346.68 | remaining -46.68 (OVER by 46.68)
Eating Out: cap 400.00 | spent 664.41 | remaining -264.41 (OVER by 264.41)
Allowance Sunny: cap 200.00 | spent 93.10 | remaining 106.90 (UNDER by 106.90)
Allowance Drashti: cap 200.00 | spent 137.88 | remaining 62.12 (UNDER by 62.12)
```

- Negative remaining = **OVER budget**. Positive remaining = **UNDER budget**.
- Never describe an overspend as "zero" or fully spent.
- Only say "budget fully used" when remaining is exactly 0.00.

## List Recent Spends

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\Tech\DSAI\tools\expense-log.ps1 -Action list -Lines 5
```

Shows the last 5 expense rows (from snapshot + pending outbox rows). Default is 10.

## Add a Spend

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\Tech\DSAI\tools\expense-log.ps1 -Action add `
  -Date 2026-11-07 `
  -Category Groceries `
  -Merchant Woolworths `
  -Amount -50 `
  -Notes "Weekly shopping"
```

Required parameters:
- `-Date`: YYYY-MM-DD format (e.g., 2026-11-07)
- `-Category`: one of Groceries, Eating Out, Allowance Sunny, Allowance Drashti, or any other category
- `-Merchant`: store or vendor name
- `-Amount`: negative for expenses (e.g., -50), positive for refunds/income (e.g., +10)
- `-Notes`: optional; any text describing the transaction

This queues the spend to `TRACKER-OUTBOX.csv` with `Status=pending`. The online household tracker applies it to the live Numbers workbook later and syncs back the updated snapshot.

## View Budget Caps and Period

Budget caps and the current period dates are read from `private/TRACKER-RULES.md`:

```
Period: 14 Oct 2026 to 10 Nov 2026
Groceries: $300
Eating Out: $400
Allowance Sunny: $200
Allowance Drashti: $200
```

To update, edit that file (if unlocked) or ask the online tracker to update it.

## How the Tracker Stays Offline

- **Live workbook** (Numbers): only the online tracker edits this.
- **Snapshot** (`LIVE-SNAPSHOT.csv`): read-only export from the online tracker; refreshed after each sync.
- **Outbox** (`TRACKER-OUTBOX.csv`): queue of pending spends; online tracker applies them and marks as applied.
- **Local rules** (`TRACKER-RULES.md`): local copy of period and caps.

DSAI never opens or writes the `.numbers` file. All changes go through the outbox queue.

## Troubleshooting

- **Spend does not appear after 24 hours?** Check if the online tracker's sync has run. Look for recent `LIVE-SNAPSHOT.csv` modification time.
- **Cannot add a spend?** Check that `TRACKER-OUTBOX.csv` exists. If vault is locked, ask to unlock it or create `private/TRACKER-OUTBOX.csv` manually.
- **Leftovers seem wrong?** Run `tools/expense-log.ps1 -Action list` to see recent transactions, or ask to validate the snapshot.
