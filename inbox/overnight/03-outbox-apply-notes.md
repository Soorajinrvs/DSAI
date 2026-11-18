# TRACKER-OUTBOX Apply Notes

When a user adds a spend via `tools/expense-log.ps1 -Action add`, it is queued to `private/TRACKER-OUTBOX.csv` with `Status=pending`. The outbox waits for the online household tracker to apply these rows to the live Numbers workbook.

## How Pending Rows Are Applied

The online tracker:

1. **Reads** `private/TRACKER-OUTBOX.csv` looking for `Status=pending` rows.
2. **Validates** each row (date format, amount is a number, category exists).
3. **Applies** each row to the live Numbers workbook in order of `QueuedAt` timestamp.
4. **Syncs** by exporting a new `private/LIVE-SNAPSHOT.csv` with the updated transactions.
5. **Updates** the outbox, marking applied rows as `Status=applied` or removing them entirely.

## Local (DSAI) Responsibilities

- **Add**: Queue new spends to outbox using `tools/expense-log.ps1 -Action add`.
- **Never edit** `TRACKER-OUTBOX.csv` manually; let the script manage the queue.
- **Never edit** `LIVE-SNAPSHOT.csv`; it is read-only (overwritten by the online tracker after sync).
- **Report**: If a spend does not appear in the snapshot after 24 hours, ask the user to check the online tracker for sync errors.

## Online Tracker Responsibilities

- **Apply** pending outbox rows to the live Numbers workbook.
- **Sync** and refresh the snapshot with new transactions.
- **Resolve** conflicts (e.g., duplicate category names, malformed dates).
- **Notify** if outbox rows are rejected (bad format or validation error).

## Example Flow

1. User: "Add $50 groceries at Woolworths on 2026-11-07."
2. DSAI: Runs `tools/expense-log.ps1 -Action add -Date 2026-11-07 -Category Groceries -Merchant Woolworths -Amount -50`.
3. Script: Writes to `TRACKER-OUTBOX.csv` with `Status=pending`, `QueuedAt=2026-11-07 HH:MM:SS`.
4. Online tracker (later): Reads outbox, applies row to Numbers workbook, syncs.
5. Online tracker: Updates `LIVE-SNAPSHOT.csv` and marks outbox row as `Status=applied`.
6. Next time user asks leftovers: `tools/expense-log.ps1 -Action leftovers` includes the new spend in the total.

## Notes

- The local model cannot write to the live Numbers workbook directly.
- Outbox is the **only** queue; do not queue spends to any other file.
- Do not assume a spend is applied; wait for it to appear in the snapshot.
