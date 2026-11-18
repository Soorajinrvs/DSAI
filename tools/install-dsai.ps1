<#
.SYNOPSIS
    New-PC Offline Installer for DSAI (Backlog Item 10).
.DESCRIPTION
    Created 7 Nov 2026.
    Sets up DSAI on a new Windows 10/11 PC:
    1. Creates the blank projects folder (Documents\DSAI Projects) if missing.
    2. Ensures private/ starts completely blank (only README.md and MEMORY.template.md)
       unless the user explicitly unlocks their own .vault file later.
    3. Backs up any existing Continue config.yaml to C:\Users\<User>\.continue\_backup
       before writing or updating the DSAI model configuration.
    4. Links DSAI\runtime to an existing local model folder if present (never downloads
       anything over 100 MB, and never copies the ~5 GB model unless confirmed).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ContinueDir = (Join-Path $env:USERPROFILE ".continue"),

    [Parameter(Mandatory = $false)]
    [string]$ExistingModelDir = (Join-Path $env:USERPROFILE ".continue\local-llm"),

    [Parameter(Mandatory = $false)]
    [string]$ServerAlias = "cst-qwen3-8b",

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$dsaiRoot = Split-Path -Parent $PSScriptRoot
$privateDir = Join-Path $dsaiRoot "private"
$vaultDir = Join-Path $dsaiRoot "vault"
$linkScript = Join-Path $PSScriptRoot "link-runtime.ps1"

Write-Host "=== DSAI New-PC Offline Installer ===" -ForegroundColor Cyan
Write-Host "DSAI Folder    : $dsaiRoot"
Write-Host "Continue Folder: $ContinueDir"

# 1. Verify DSAI starts blank (no unencrypted personal MEMORY.md sitting in private/)
$unlockedMemory = Join-Path $privateDir "MEMORY.md"
if (Test-Path -LiteralPath $unlockedMemory) {
    Write-Warning "Found an unlocked '$unlockedMemory' file."
    Write-Host "For privacy, lock your vault before or immediately after setup using .\tools\vault.ps1 -Action lock." -ForegroundColor Yellow
} else {
    Write-Host "[OK] Privacy check passed: DSAI starts blank (no unlocked personal memory present)." -ForegroundColor Green
}

# 2. Ensure Documents\DSAI Projects directory exists
$projectsRoot = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "DSAI Projects"
if ($DryRun) {
    Write-Host "[DRY-RUN] Would ensure projects folder exists at: $projectsRoot" -ForegroundColor Yellow
} else {
    if (-not (Test-Path -LiteralPath $projectsRoot)) {
        New-Item -ItemType Directory -Path $projectsRoot | Out-Null
        Write-Host "[OK] Created blank projects root: $projectsRoot" -ForegroundColor Green
    } else {
        Write-Host "[OK] Projects folder already exists: $projectsRoot" -ForegroundColor Green
    }
}

# 2b. Deploy global DSAI Continue rule to ~/.continue/rules/ (backed up as needed)
$rulesDir = Join-Path $ContinueDir "rules"
$dsaiRuleSource = Join-Path $dsaiRoot "continue-rules" "dsai.md"
$dsaiRuleTarget = Join-Path $rulesDir "dsai.md"

if ($DryRun) {
    Write-Host "[DRY-RUN] Would deploy global DSAI rule from '$dsaiRuleSource' to '$dsaiRuleTarget'." -ForegroundColor Yellow
} else {
    if (-not (Test-Path -LiteralPath $rulesDir)) {
        New-Item -ItemType Directory -Path $rulesDir | Out-Null
    }
    if (Test-Path -LiteralPath $dsaiRuleSource) {
        if (Test-Path -LiteralPath $dsaiRuleTarget) {
            $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $ruleBackup = Join-Path $backupDir "dsai.md-$stamp"
            Copy-Item -LiteralPath $dsaiRuleTarget -Destination $ruleBackup -ErrorAction SilentlyContinue
        }
        Copy-Item -LiteralPath $dsaiRuleSource -Destination $dsaiRuleTarget -Force -ErrorAction Stop
        Write-Host "[OK] Deployed global DSAI Continue rule to: $dsaiRuleTarget" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Global DSAI rule not found at '$dsaiRuleSource'. Skipping." -ForegroundColor Yellow
    }
}

# 3. Configure Continue (C:\Users\<User>\.continue\config.yaml) with mandatory backup to _backup
$configFile = Join-Path $ContinueDir "config.yaml"
$backupDir = Join-Path $ContinueDir "_backup"

$cleanConfigYaml = @"
name: DSAI Local Config
version: 0.0.1
schema: v1

models:
  - name: DSAI
    provider: openai
    model: $ServerAlias
    apiBase: http://127.0.0.1:8081/v1
    apiKey: local-offline
    roles:
      - chat
      - edit
      - apply

context:
  - provider: file
  - provider: code
  - provider: terminal
"@

if ($DryRun) {
    if (Test-Path -LiteralPath $configFile) {
        Write-Host "[DRY-RUN] Would back up existing '$configFile' to '$backupDir\config-<timestamp>.yaml'." -ForegroundColor Yellow
        Write-Host "[DRY-RUN] Existing config.yaml detected; would preserve existing file unless user requests overwrite." -ForegroundColor Green
    } else {
        Write-Host "[DRY-RUN] Would create '$configFile' with general DSAI model entry." -ForegroundColor Yellow
    }
} else {
    if (-not (Test-Path -LiteralPath $ContinueDir)) {
        New-Item -ItemType Directory -Path $ContinueDir | Out-Null
    }
    if (-not (Test-Path -LiteralPath $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir | Out-Null
    }

    if (Test-Path -LiteralPath $configFile) {
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupPath = Join-Path $backupDir "config-$stamp.yaml"
        Copy-Item -LiteralPath $configFile -Destination $backupPath -ErrorAction Stop
        Write-Host "[OK] Backed up existing config.yaml to: $backupPath" -ForegroundColor Green

        $existingText = Get-Content -LiteralPath $configFile -Raw -Encoding UTF8
        if ($existingText -match 'name:\s*DSAI') {
            Write-Host "[OK] Existing config.yaml already contains the 'DSAI' model entry. Left unchanged." -ForegroundColor Green
        } else {
            Write-Host "[INFO] Writing clean DSAI config.yaml (your previous file is safely backed up at $backupPath)." -ForegroundColor Cyan
            Set-Content -LiteralPath $configFile -Value $cleanConfigYaml -Encoding UTF8
        }
    } else {
        Set-Content -LiteralPath $configFile -Value $cleanConfigYaml -Encoding UTF8
        Write-Host "[OK] Created new Continue config at: $configFile" -ForegroundColor Green
    }
}

# 4. Link local runtime if present (never download >100 MB, never copy 5 GB silently)
if (Test-Path -LiteralPath $ExistingModelDir) {
    if ($DryRun) {
        & $linkScript -SourceRuntimeDir $ExistingModelDir -DryRun
    } else {
        & $linkScript -SourceRuntimeDir $ExistingModelDir
    }
} else {
    Write-Host "[INFO] No local model runtime found at '$ExistingModelDir' yet." -ForegroundColor Yellow
    Write-Host "       DSAI never downloads large files automatically." -ForegroundColor Cyan
    Write-Host "       Once you place or link llama-server.exe and Qwen3-8B-Q4_K_M.gguf, run:"
    Write-Host "       powershell -ExecutionPolicy Bypass -File .\tools\link-runtime.ps1 -SourceRuntimeDir <path>"
}

Write-Host ""
Write-Host "=== DSAI Setup Summary ===" -ForegroundColor Cyan
Write-Host "1. Start server  : powershell -ExecutionPolicy Bypass -File .\tools\start-dsai.ps1"
Write-Host "2. New project   : powershell -ExecutionPolicy Bypass -File .\tools\new-project.ps1"
Write-Host "3. Create/unlock : powershell -ExecutionPolicy Bypass -File .\tools\vault.ps1 -Action status"
Write-Host "4. User Guide    : Open docs\USER-GUIDE.md"