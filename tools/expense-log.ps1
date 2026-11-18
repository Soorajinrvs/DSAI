<#
.SYNOPSIS
    Household expense logger with budget tracking (PowerShell 5.1+).
.DESCRIPTION
    Add a row (queued to TRACKER-OUTBOX.csv), list recent rows, or show leftovers for
    Groceries, Eating Out, Allowance Sunny, and Allowance Drashti.

    Reads period dates and caps from private/TRACKER-RULES.md if present,
    else defaults to 14 Oct 2026 - 10 Nov 2026 with the standard caps.

    Prints a caution if Eating Out remaining is 0 or negative.
    Never opens or writes any .numbers file.
.PARAMETER Action
    add, list, or leftovers
.PARAMETER Date
    Purchase date in YYYY-MM-DD format (for add)
.PARAMETER Category
    Category name (for add)
.PARAMETER Merchant
    Merchant/store name (for add)
.PARAMETER Amount
    Amount in dollars, negative for expenses (for add)
.PARAMETER Notes
    Optional notes (for add)
.PARAMETER Lines
    Number of recent rows to show (for list, default 10)
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("add", "list", "leftovers")]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$Date,

    [Parameter(Mandatory = $false)]
    [string]$Category,

    [Parameter(Mandatory = $false)]
    [string]$Merchant,

    [Parameter(Mandatory = $false)]
    [decimal]$Amount = 0,

    [Parameter(Mandatory = $false)]
    [string]$Notes = "",

    [Parameter(Mandatory = $false)]
    [int]$Lines = 10
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$dsaiRoot = Split-Path -Parent $PSScriptRoot
$expenseFile = Join-Path $dsaiRoot "private\EXPENSES.md"
$rulesFile = Join-Path $dsaiRoot "private\TRACKER-RULES.md"
$snapshotFile = Join-Path $dsaiRoot "private\LIVE-SNAPSHOT.csv"
$outboxFile = Join-Path $dsaiRoot "private\TRACKER-OUTBOX.csv"

$defaultPeriodStart = [datetime]::ParseExact("2026-10-14", "yyyy-MM-dd", [System.Globalization.CultureInfo]::InvariantCulture)
$defaultPeriodEnd = [datetime]::ParseExact("2026-11-10", "yyyy-MM-dd", [System.Globalization.CultureInfo]::InvariantCulture)

$defaultCaps = @{
    "Groceries"         = [decimal]300
    "Eating Out"        = [decimal]400
    "Allowance Sunny"   = [decimal]200
    "Allowance Drashti" = [decimal]200
}

function Get-PeriodDates {
    $periodStart = $defaultPeriodStart
    $periodEnd = $defaultPeriodEnd

    if (Test-Path -LiteralPath $rulesFile) {
        $content = Get-Content -LiteralPath $rulesFile -Raw
        if ($content -match 'Period[:\*\s]+(\d{1,2})\s+(\w+)\s+(\d{4})\s+to\s+(\d{1,2})\s+(\w+)\s+(\d{4})') {
            try {
                $culture = [System.Globalization.CultureInfo]::InvariantCulture
                $startStr = "{0} {1} {2}" -f $matches[1], $matches[2], $matches[3]
                $endStr = "{0} {1} {2}" -f $matches[4], $matches[5], $matches[6]
                $periodStart = [datetime]::ParseExact($startStr, "d MMM yyyy", $culture)
                $periodEnd = [datetime]::ParseExact($endStr, "d MMM yyyy", $culture)
            }
            catch {
            }
        }
    }

    return @($periodStart, $periodEnd)
}

function Get-BudgetCaps {
    $caps = @{
        "Groceries"         = $defaultCaps["Groceries"]
        "Eating Out"        = $defaultCaps["Eating Out"]
        "Allowance Sunny"   = $defaultCaps["Allowance Sunny"]
        "Allowance Drashti" = $defaultCaps["Allowance Drashti"]
    }

    if (Test-Path -LiteralPath $rulesFile) {
        $content = Get-Content -LiteralPath $rulesFile -Raw
        if ($content -match 'Groceries[:\*\s]+\$([0-9]+)') {
            $caps["Groceries"] = [decimal]$matches[1]
        }
        if ($content -match 'Eating Out[:\*\s]+\$([0-9]+)') {
            $caps["Eating Out"] = [decimal]$matches[1]
        }
        if ($content -match 'Allowance Sunny[:\*\s]+\$([0-9]+)') {
            $caps["Allowance Sunny"] = [decimal]$matches[1]
        }
        if ($content -match 'Allowance Drashti[:\*\s]+\$([0-9]+)') {
            $caps["Allowance Drashti"] = [decimal]$matches[1]
        }
    }

    return $caps
}
function Get-MarkdownExpenses {
    if (-not (Test-Path -LiteralPath $expenseFile)) {
        return @()
    }

    $fileLines = Get-Content -LiteralPath $expenseFile
    $expenses = @()

    foreach ($line in $fileLines) {
        if ($line -notmatch '^\|') { continue }
        if ($line -match '^\|\s*-+') { continue }

        $cells = @($line.Trim() -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
        if ($cells.Count -lt 4) { continue }
        if ($cells[0] -eq "Date") { continue }

        $amountRaw = $cells[3] -replace '[^\d\.\-\+]', ''
        $parsedAmount = 0
        if (-not [decimal]::TryParse($amountRaw, [ref]$parsedAmount)) { continue }

        $noteText = ""
        if ($cells.Count -ge 5) { $noteText = $cells[4] }

        $expenses += [pscustomobject]@{
            Date     = $cells[0]
            Category = $cells[1]
            Merchant = $cells[2]
            Amount   = $parsedAmount
            Notes    = $noteText
        }
    }

    return $expenses
}

function Get-CsvExpenseRows {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return @() }

    $rows = @(Import-Csv -LiteralPath $Path)
    $expenses = @()
    foreach ($row in $rows) {
        $amountRaw = [string]$row.Amount
        $amountRaw = $amountRaw -replace '[^\d\.\-\+]', ''
        $parsedAmount = 0
        if (-not [decimal]::TryParse($amountRaw, [ref]$parsedAmount)) { continue }
        $expenses += [pscustomobject]@{
            Date     = [string]$row.Date
            Category = [string]$row.Category
            Merchant = [string]$row.Merchant
            Amount   = $parsedAmount
            Notes    = [string]$row.Notes
        }
    }
    return $expenses
}

function Get-PendingOutbox {
    if (-not (Test-Path -LiteralPath $outboxFile)) { return @() }
    $rows = @(Import-Csv -LiteralPath $outboxFile)
    $pending = @()
    foreach ($row in $rows) {
        $status = ([string]$row.Status).ToLower()
        if ($status -eq "applied") { continue }
        $amountRaw = ([string]$row.Amount) -replace '[^\d\.\-\+]', ''
        $parsedAmount = 0
        if (-not [decimal]::TryParse($amountRaw, [ref]$parsedAmount)) { continue }
        $pending += [pscustomobject]@{
            Date     = [string]$row.Date
            Category = [string]$row.Category
            Merchant = [string]$row.Merchant
            Amount   = $parsedAmount
            Notes    = [string]$row.Notes
        }
    }
    return $pending
}

function Test-HasLiveSnapshot {
    return (Test-Path -LiteralPath $snapshotFile)
}

function Get-ExpenseSourceLabel {
    if (Test-HasLiveSnapshot) {
        $stamp = (Get-Item -LiteralPath $snapshotFile).LastWriteTime.ToString("dd MMM yyyy HH:mm")
        $pendingCount = @(Get-PendingOutbox).Count
        $label = "Source: live snapshot ($stamp)"
        if ($pendingCount -gt 0) {
            $label = "$label plus $pendingCount pending write(s)"
        }
        return $label
    }
    return "Source: local EXPENSES.md (no live snapshot yet)"
}

function Get-Expenses {
    if (Test-HasLiveSnapshot) {
        $base = @(Get-CsvExpenseRows -Path $snapshotFile)
        $pending = @(Get-PendingOutbox)
        return @($base + $pending)
    }
    return @(Get-MarkdownExpenses)
}
function Test-DateFormat {
    param([string]$DateStr)
    $parsed = [datetime]::MinValue
    return [datetime]::TryParseExact($DateStr, "yyyy-MM-dd", [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$parsed)
}

function Add-Expense {
    if (-not $Date -or -not (Test-DateFormat $Date)) {
        Write-Error "Date must be in YYYY-MM-DD format (e.g., 2026-11-07)"
        return
    }
    if (-not $Category) {
        Write-Error "Category is required."
        return
    }
    if (-not $Merchant) {
        Write-Error "Merchant is required."
        return
    }
    if ($Amount -eq 0) {
        Write-Error "Amount must be non-zero."
        return
    }

    $outboxDir = Split-Path -Parent $outboxFile
    if (-not (Test-Path -LiteralPath $outboxDir)) {
        New-Item -ItemType Directory -Path $outboxDir -Force | Out-Null
    }

    $existing = @()
    if (Test-Path -LiteralPath $outboxFile) {
        $existing = @(Import-Csv -LiteralPath $outboxFile)
    }
    $newItem = [pscustomobject]@{
        Date     = $Date
        Category = $Category
        Merchant = $Merchant
        Amount   = $Amount
        Notes    = $Notes
        Status   = "pending"
        QueuedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }
    @($existing + $newItem) | Export-Csv -LiteralPath $outboxFile -NoTypeInformation -Encoding UTF8

    if (-not (Test-HasLiveSnapshot)) {
        if (-not (Test-Path -LiteralPath $expenseFile)) {
            Write-Error "EXPENSES.md not found at $expenseFile. Unlock the vault or create private/EXPENSES.md first."
            return
        }
        $newRow = "| {0} | {1} | {2} | {3} | {4} |" -f $Date, $Category, $Merchant, $Amount, $Notes
        Add-Content -LiteralPath $expenseFile -Value $newRow -Encoding UTF8
    }

    Write-Host ("[OK] Queued expense: {0} | {1} | {2} | {3}" -f $Date, $Category, $Merchant, $Amount)
    if ($Notes) {
        Write-Host "  Notes: $Notes"
    }
    Write-Host "  This does not edit the live Numbers workbook. It waits in TRACKER-OUTBOX.csv for the online tracker to apply."

    $refreshScript = Join-Path $PSScriptRoot "refresh-leftovers.ps1"
    if (Test-Path -LiteralPath $refreshScript) {
        try {
            & $refreshScript | Out-Null
        }
        catch {
            Write-Warning "Could not refresh the chat leftovers rule: $_"
        }
    }
}
function Show-Expenses {
    $expenses = @(Get-Expenses)

    if ($expenses.Count -eq 0) {
        Write-Host "No expenses logged yet."
        return
    }

    $count = [Math]::Min($Lines, $expenses.Count)
    Write-Host "=== Last $count expense(s) ==="
    Write-Host (Get-ExpenseSourceLabel)
    for ($i = $expenses.Count - $count; $i -lt $expenses.Count; $i++) {
        $e = $expenses[$i]
        Write-Host ("{0} | {1} | {2} | {3} | {4}" -f $e.Date, $e.Category, $e.Merchant, $e.Amount, $e.Notes)
    }
}

function Show-Leftovers {
    param(
        [datetime]$PeriodStart,
        [datetime]$PeriodEnd,
        [hashtable]$Caps
    )

    $expenses = @(Get-Expenses)
    $inPeriod = @()
    foreach ($e in $expenses) {
        $parsed = [datetime]::MinValue
        if ([datetime]::TryParseExact($e.Date, "yyyy-MM-dd", [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$parsed)) {
            if ($parsed -ge $PeriodStart -and $parsed -le $PeriodEnd) {
                $inPeriod += $e
            }
        }
    }

    $totals = @{}
    foreach ($e in $inPeriod) {
        if (-not $totals.ContainsKey($e.Category)) {
            $totals[$e.Category] = [decimal]0
        }
        $totals[$e.Category] += $e.Amount
    }

    $trackedCategories = @("Groceries", "Eating Out", "Allowance Sunny", "Allowance Drashti")

    Write-Host "=== Budget Leftovers ==="
    Write-Host ("Period: {0} to {1}" -f $PeriodStart.ToString("dd MMM yyyy"), $PeriodEnd.ToString("dd MMM yyyy"))
    Write-Host (Get-ExpenseSourceLabel)
    Write-Host ""

    foreach ($category in $trackedCategories) {
        $cap = $Caps[$category]
        $signedSum = [decimal]0
        if ($totals.ContainsKey($category)) {
            $signedSum = $totals[$category]
        }
        # Expense rows are negative, so remaining = cap + signed sum
        $remaining = $cap + $signedSum
        $spentOut = -$signedSum

        if ($remaining -eq 0) {
            $status = "budget fully used"
        }
        elseif ($remaining -lt 0) {
            $overBy = -$remaining
            $status = "OVER by {0:F2}" -f $overBy
        }
        else {
            $underBy = $remaining
            $status = "UNDER by {0:F2}" -f $underBy
        }

        Write-Host ("{0}: cap {1:F2} | spent {2:F2} | remaining {3:F2} ({4})" -f $category, $cap, $spentOut, $remaining, $status)
    }

    $eatingSigned = [decimal]0
    if ($totals.ContainsKey("Eating Out")) {
        $eatingSigned = $totals["Eating Out"]
    }
    $eatingOutRemaining = $Caps["Eating Out"] + $eatingSigned
    if ($eatingOutRemaining -lt 0) {
        Write-Host ""
        Write-Host ("[CAUTION] Eating Out budget is exhausted or negative ({0:F2} remaining)." -f $eatingOutRemaining)
        Write-Host "Apply the Eating Out funding order in TRACKER-RULES.md (allowances next, then Groceries)."
    }
}

try {
    $periodDates = Get-PeriodDates
    $periodStart = $periodDates[0]
    $periodEnd = $periodDates[1]
    $budgetCaps = Get-BudgetCaps

    switch ($Action) {
        "add" { Add-Expense }
        "list" { Show-Expenses }
        "leftovers" { Show-Leftovers -PeriodStart $periodStart -PeriodEnd $periodEnd -Caps $budgetCaps }
    }
}
catch {
    Write-Error "Error: $_"
    exit 1
}