# Leftover Display Wording

When displaying budget leftovers, use this exact format so overspend and underspend are never misread:

```
Groceries: cap 300.00 | spent 346.68 | remaining -46.68 (OVER by 46.68)
Allowance Sunny: cap 200.00 | spent 93.10 | remaining 106.90 (UNDER by 106.90)
```

## Rules

- Always show `cap`, `spent`, and `remaining` with two decimal places.
- For `remaining`:
  - If `remaining < 0`: show as negative number, add `(OVER by X.XX)` where X is the absolute value.
  - If `remaining > 0`: show as positive number, add `(UNDER by X.XX)`.
  - If `remaining == 0`: show as `0.00` and say `(budget fully used)` — never say "zero" or "empty".
- Never describe a negative remaining as "zero" or "fully spent".
- Never subtract the overspend from the cap again or rewrite "OVER" as a positive number.
- Do not restate these figures from memory or earlier chat text.
- When the user asks what is left or spent, run `tools/expense-log.ps1 -Action leftovers` and quote the script output verbatim.

## Source

Updated 2026-11-07 in `tools/expense-log.ps1` function `Show-Leftovers`. Local model cannot retrain; keep improving the script itself in later chats.
