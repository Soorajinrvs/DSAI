# LIVE-SNAPSHOT.csv Validation

The household tracker maintains a live Apple Numbers workbook. After each sync, it exports a snapshot to `private/LIVE-SNAPSHOT.csv` for offline analysis. This file is read-only and must not be edited locally.

## Task

Validate the snapshot columns and row counts:

1. **Check structure**:
   - Columns: `Date`, `Category`, `Merchant`, `Amount`, `Notes` (exact order, all lowercase headers).
   - Each row must have a date in `YYYY-MM-DD` format.
   - Each row must have a valid amount (negative for expenses, positive for refunds/income).
   - Do not invent or guess amounts.

2. **Count bad rows**:
   - Empty rows (no date or amount).
   - Malformed dates (not `YYYY-MM-DD`).
   - Invalid amounts (text, blanks, unparseable).
   - Print count of each issue type.

3. **Never invent amounts**:
   - If a row is missing an amount, report it as bad, do not fill it in.
   - If a date is malformed, report it, do not correct it.
   - If a category or merchant is missing, report it as a gap but do not fabricate values.

4. **Report summary**:
   - Total rows read.
   - Valid rows.
   - Bad rows (by type).
   - Sample of first bad row (if any) to help trace the sync issue.

## Notes

- The online tracker is the single source of truth.
- This validation runs locally to catch sync issues early.
- Local model cannot edit the Numbers workbook; report findings and let the online tracker fix them.

## Implementation

Write this as a small PowerShell script that reads `private/LIVE-SNAPSHOT.csv` and outputs a report.
