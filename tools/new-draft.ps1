<#
.SYNOPSIS
    Create a dated draft email file in drafts/ (PowerShell 5.1+).
.DESCRIPTION
    Creates a Markdown draft with To, Subject, and Body sections.
    DSAI never sends the message.
.PARAMETER Title
    Short description used in the filename.
.PARAMETER To
    Optional recipient (can be edited in the file later).
.PARAMETER Subject
    Optional subject line (can be edited in the file later).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Title = "",

    [Parameter(Mandatory = $false)]
    [string]$To = "",

    [Parameter(Mandatory = $false)]
    [string]$Subject = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$dsaiRoot = Split-Path -Parent $PSScriptRoot
$draftsDir = Join-Path $dsaiRoot "drafts"

if (-not (Test-Path -LiteralPath $draftsDir)) {
    New-Item -ItemType Directory -Path $draftsDir -Force | Out-Null
}

if ([string]::IsNullOrWhiteSpace($Title)) {
    $Title = Read-Host "Draft description (e.g., thank-you-email)"
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
$filepath = Join-Path $draftsDir $filename

$counter = 1
while (Test-Path -LiteralPath $filepath) {
    $filename = "${timestamp}-${safeTitle}-${counter}.md"
    $filepath = Join-Path $draftsDir $filename
    $counter++
}

$toLine = if ([string]::IsNullOrWhiteSpace($To)) { "[To]" } else { $To }
$subjectLine = if ([string]::IsNullOrWhiteSpace($Subject)) { "[Subject]" } else { $Subject }

$content = @"
To: $toLine
Subject: $subjectLine

---

[Write your message body here]

---

Created: $timestamp
Ready to send: [ ] (check when reviewed)
"@

Set-Content -LiteralPath $filepath -Value $content -Encoding UTF8
Write-Host "[OK] Draft file created: $filepath"
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Open $filename in VS Code"
Write-Host "2. Fill in To, Subject, and message body"
Write-Host "3. Review and edit as needed"
Write-Host "4. Copy and send manually (DSAI never sends)"