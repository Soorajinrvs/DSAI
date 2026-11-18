<#
.SYNOPSIS
    Exports a clean, portable copy of DSAI to a USB stick or cloud folder (Backlog Item 11).
.DESCRIPTION
    Created 7 Nov 2026.
    Copies only publishable DSAI files plus encrypted vault/*.vault files.
    STRICT PRIVACY & SIZE RULES:
    1. NEVER copies unencrypted files from private/ (only README.md and *.template.md are exported).
    2. If any unlocked personal files exist in private/, warns the user and leaves them behind.
    3. NEVER copies the ~5 GB model/runtime by default. If -IncludeModel is specified, pauses and
       asks the user to type YES before copying the ~5 GB runtime.
    4. Never overwrites an existing destination folder without backing up or creating a dated subfolder.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Destination,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeModel,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$dsaiRoot = Split-Path -Parent $PSScriptRoot
$privateDir = Join-Path $dsaiRoot "private"

Write-Host "=== DSAI Safe Exporter (USB / Cloud) ===" -ForegroundColor Cyan
Write-Host "Source DSAI Root : $dsaiRoot"
Write-Host "Destination      : $Destination"

# 1. Privacy Guardrail: Check if any unlocked personal files are sitting in private/
# (Unlocked = anything except README.md and *.template.md)
$unlockedPrivateFiles = @()
if (Test-Path -LiteralPath $privateDir) {
    $unlockedPrivateFiles = @(Get-ChildItem -LiteralPath $privateDir -File -Force | Where-Object {
        $_.Name -ne "README.md" -and $_.Name -notmatch '\.template\.md$'
    })
}

if ($unlockedPrivateFiles.Count -gt 0) {
    Write-Warning "Detected $($unlockedPrivateFiles.Count) UNLOCKED personal file(s) in '$privateDir'!"
    Write-Host "By rule, export-dsai.ps1 NEVER copies unencrypted private files." -ForegroundColor Yellow
    Write-Host "Tip: Run '.\tools\vault.ps1 -Action lock' first if you want your latest edits saved into your encrypted .vault file." -ForegroundColor Yellow
}

# 2. Prepare destination folder safely (never clobber existing files)
$targetRoot = $Destination
if (Test-Path -LiteralPath $targetRoot) {
    $existingItems = @(Get-ChildItem -LiteralPath $targetRoot -ErrorAction SilentlyContinue)
    if ($existingItems.Count -gt 0) {
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $targetRoot = Join-Path $Destination "DSAI-Export-$stamp"
        Write-Host "[SAFEGUARD] Destination is not empty; exporting into clean subfolder: $targetRoot" -ForegroundColor Cyan
    }
}

# Explicit whitelist of publishable files and folders to export
$topLevelFiles = @(
    "README.md",
    ".gitignore",
    "BACKLOG.md",
    "PROGRESS.md"
)

$foldersToCopy = @(
    "docs",
    "tools",
    "continue-rules",
    ".vscode"
)

if ($DryRun) {
    Write-Host "[DRY-RUN] Would create export folder: $targetRoot" -ForegroundColor Yellow
    Write-Host "[DRY-RUN] Would copy top-level files: $($topLevelFiles -join ', ')"
    Write-Host "[DRY-RUN] Would copy folders        : $($foldersToCopy -join ', '), tests/questions.json"
    Write-Host "[DRY-RUN] Would copy safe docs      : private/README.md, private/*.template.md (NO unlocked personal files)" -ForegroundColor Green
    Write-Host "[DRY-RUN] Would copy encrypted vaults: vault/*.vault" -ForegroundColor Green
    if (-not $IncludeModel) {
        Write-Host "[DRY-RUN] Would skip ~5 GB model/runtime (0 model bytes copied)." -ForegroundColor Green
    }
    exit 0
}

New-Item -ItemType Directory -Path $targetRoot -ErrorAction Stop | Out-Null

# 3. Copy top-level documentation files
foreach ($file in $topLevelFiles) {
    $src = Join-Path $dsaiRoot $file
    if (Test-Path -LiteralPath $src) {
        Copy-Item -LiteralPath $src -Destination (Join-Path $targetRoot $file) -ErrorAction Stop
    }
}

# 4. Copy docs/ and tools/
foreach ($folder in $foldersToCopy) {
    $srcFolder = Join-Path $dsaiRoot $folder
    $dstFolder = Join-Path $targetRoot $folder
    if (Test-Path -LiteralPath $srcFolder) {
        Copy-Item -LiteralPath $srcFolder -Destination $dstFolder -Recurse -ErrorAction Stop
    }
}

# 5. Copy tests/questions.json (excluding any temporary test folders like tests/tmp-vault)
$dstTests = Join-Path $targetRoot "tests"
New-Item -ItemType Directory -Path $dstTests -ErrorAction Stop | Out-Null
$srcQuestions = Join-Path $dsaiRoot "tests\questions.json"
if (Test-Path -LiteralPath $srcQuestions) {
    Copy-Item -LiteralPath $srcQuestions -Destination (Join-Path $dstTests "questions.json") -ErrorAction Stop
}

# 6. Copy ONLY safe documentation/template files into private/
# (Exports README.md and all *.template.md files; NEVER copies unlocked personal files)
$dstPrivate = Join-Path $targetRoot "private"
New-Item -ItemType Directory -Path $dstPrivate -ErrorAction Stop | Out-Null

# Copy README.md
$srcReadme = Join-Path $privateDir "README.md"
if (Test-Path -LiteralPath $srcReadme) {
    Copy-Item -LiteralPath $srcReadme -Destination (Join-Path $dstPrivate "README.md") -ErrorAction Stop
}

# Copy all *.template.md files
if (Test-Path -LiteralPath $privateDir) {
    $templateFiles = @(Get-ChildItem -LiteralPath $privateDir -Filter "*.template.md" -File -ErrorAction SilentlyContinue)
    foreach ($tpl in $templateFiles) {
        Copy-Item -LiteralPath $tpl.FullName -Destination (Join-Path $dstPrivate $tpl.Name) -ErrorAction Stop
    }
}

# 7. Copy ONLY encrypted *.vault files from vault/
$srcVaultDir = Join-Path $dsaiRoot "vault"
$dstVaultDir = Join-Path $targetRoot "vault"
New-Item -ItemType Directory -Path $dstVaultDir -ErrorAction Stop | Out-Null
$vaultFilesCopied = 0
if (Test-Path -LiteralPath $srcVaultDir) {
    $encryptedVaults = @(Get-ChildItem -LiteralPath $srcVaultDir -Filter "*.vault" -File -ErrorAction SilentlyContinue)
    foreach ($vf in $encryptedVaults) {
        Copy-Item -LiteralPath $vf.FullName -Destination (Join-Path $dstVaultDir $vf.Name) -ErrorAction Stop
        $vaultFilesCopied++
    }
}

# 8. Optional ~5 GB model copy ONLY if -IncludeModel was passed AND user confirms with YES
if ($IncludeModel) {
    Write-Host ""
    Write-Host "[WARNING] You passed -IncludeModel. The local GGUF model and server runtime is ~5 GB." -ForegroundColor Yellow
    $confirm = Read-Host "Type YES (in capital letters) to confirm copying ~5 GB of model files to '$targetRoot\runtime'"
    if ($confirm -ceq "YES") {
        $srcRuntime = Join-Path $dsaiRoot "runtime"
        if (-not (Test-Path -LiteralPath $srcRuntime)) {
            $srcRuntime = "C:\Users\Tech\.continue\local-llm"
        }
        if (Test-Path -LiteralPath $srcRuntime) {
            $dstRuntime = Join-Path $targetRoot "runtime"
            New-Item -ItemType Directory -Path $dstRuntime -ErrorAction Stop | Out-Null
            Write-Host "Copying ~5 GB runtime to '$dstRuntime'..." -ForegroundColor Cyan
            Copy-Item -Path (Join-Path $srcRuntime "*") -Destination $dstRuntime -Recurse -ErrorAction Stop
            Write-Host "[OK] Model runtime copied." -ForegroundColor Green
        } else {
            Write-Warning "Could not locate source runtime directory to copy."
        }
    } else {
        Write-Host "[SKIPPED] Model copy was not confirmed. Exported without the 5 GB model." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "[OK] Export complete: $targetRoot" -ForegroundColor Green
Write-Host "     - Unencrypted private files copied : 0 (Strictly blocked)"
Write-Host "     - Encrypted .vault files copied    : $vaultFilesCopied"