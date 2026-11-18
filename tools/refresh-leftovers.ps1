<#
.SYNOPSIS
    Writes the current budget leftovers into a Continue rule so DSAI can quote them in chat.
.DESCRIPTION
    Continue's chat model cannot run commands. This runs tools/expense-log.ps1 -Action leftovers
    and saves the exact output (with a timestamp) to .continue/rules/leftovers-now.md in the DSAI
    folder. Continue loads that file as an always-on rule, so DSAI can answer "how much is left"
    without anyone clicking Run. Re-run it (or add an expense) to refresh the figures.
    Works from any folder: paths are relative to this script. PowerShell 5.1+.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$dsaiRoot = Split-Path -Parent $PSScriptRoot
$expenseScript = Join-Path $PSScriptRoot "expense-log.ps1"
$ruleDir = Join-Path $dsaiRoot ".continue\rules"
$ruleFile = Join-Path $ruleDir "leftovers-now.md"

$output = (& $expenseScript -Action leftovers *>&1 | Out-String).TrimEnd()
if ($output -notmatch "Budget Leftovers") {
    throw "expense-log.ps1 did not produce a leftovers table: $output"
}

$stamp = Get-Date -Format "dd MMM yyyy HH:mm"
$body = @(
    "---",
    "name: DSAI Current Leftovers",
    "alwaysApply: true",
    "---",
    "",
    "# DSAI Current Leftovers",
    "",
    "Whenever the user asks how much money is left, remaining, spent, or budget (Groceries, Eating Out, allowances), reply with exactly the text below and nothing else. Do not say you will check. Do not change any number. Negative remaining means OVER budget.",
    "",
    "Budget leftovers, refreshed ${stamp}:",
    "",
    '```text',
    $output,
    '```'
) -join "`r`n"

if (-not (Test-Path -LiteralPath $ruleDir)) {
    New-Item -ItemType Directory -Path $ruleDir -Force | Out-Null
}
[System.IO.File]::WriteAllText($ruleFile, $body + "`r`n", (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Updated $ruleFile ($stamp)"
Write-Host $output
