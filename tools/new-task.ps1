<#
.SYNOPSIS
    Create a dated task file in inbox/ (PowerShell 5.1+).
.DESCRIPTION
    Creates a new Markdown task file: inbox/YYYY-MM-DD-title.md
.PARAMETER Title
    Task title. Spaces become hyphens.
.PARAMETER Notes
    Optional notes to include in the task file.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Title = "",

    [Parameter(Mandatory = $false)]
    [string]$Notes = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$dsaiRoot = Split-Path -Parent $PSScriptRoot
$inboxDir = Join-Path $dsaiRoot "inbox"

if (-not (Test-Path -LiteralPath $inboxDir)) {
    New-Item -ItemType Directory -Path $inboxDir -Force | Out-Null
}

if ([string]::IsNullOrWhiteSpace($Title)) {
    $Title = Read-Host "Task title"
}

if ([string]::IsNullOrWhiteSpace($Title)) {
    Write-Error "Title cannot be empty."
    exit 1
}

$safeTitle = $Title -replace '[^a-zA-Z0-9\s\-]', '' -replace '\s+', '-' -replace '-+', '-'
$safeTitle = $safeTitle.Trim('-').ToLower()

if ([string]::IsNullOrWhiteSpace($safeTitle)) {
    Write-Error "Title must contain at least one letter or number."
    exit 1
}

$timestamp = Get-Date -Format "yyyy-MM-dd"
$filename = "${timestamp}-${safeTitle}.md"
$filepath = Join-Path $inboxDir $filename

$counter = 1
while (Test-Path -LiteralPath $filepath) {
    $filename = "${timestamp}-${safeTitle}-${counter}.md"
    $filepath = Join-Path $inboxDir $filename
    $counter++
}

$notesSection = ""
if (-not [string]::IsNullOrWhiteSpace($Notes)) {
    $notesSection = "`r`n**Additional context:**`r`n$Notes"
}

$content = @"
# Task: $Title

**Goal:** [What does success look like? Describe the expected outcome.]

**Files to touch:**
- Path/To/File1.md (action: read / create / edit)
- Path/To/File2.md (action: read / create / edit)

**What stays online:**
- [List any steps requiring internet, website login, email send, bank sync, or cloud upload]
$notesSection

---

Created: $timestamp
"@

Set-Content -LiteralPath $filepath -Value $content -Encoding UTF8
Write-Host "[OK] Task file created: $filepath"
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Open $filename in VS Code"
Write-Host "2. Fill in Goal, Files to touch, and What stays online"
Write-Host "3. DSAI will read it and complete the local work"