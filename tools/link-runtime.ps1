<#
.SYNOPSIS
    Links DSAI\runtime to the existing local model and llama.cpp server folder without copying the ~5 GB model.
.DESCRIPTION
    Created 7 Nov 2026 (Backlog Item 5).
    Creates a Windows directory junction at <DSAI>\runtime pointing to the existing runtime
    folder (by default C:\Users\Tech\.continue\local-llm).
    Directory junctions work on Windows 10/11 without Administrator privileges and take 0 bytes
    of extra disk space.
    Never copies the ~5 GB model by default. If linking is not possible (for example across
    a filesystem that does not support junctions) and -CopyIfNeeded is specified, it stops
    and asks the user to type YES before copying anything.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$SourceRuntimeDir = "C:\Users\Tech\.continue\local-llm",

    [Parameter(Mandatory = $false)]
    [string]$LinkPath = (Join-Path (Split-Path -Parent $PSScriptRoot) "runtime"),

    [Parameter(Mandatory = $false)]
    [switch]$CopyIfNeeded,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "=== DSAI Runtime Linker ===" -ForegroundColor Cyan
Write-Host "Source runtime : $SourceRuntimeDir"
Write-Host "Target link    : $LinkPath"

# 1. Check if the target link path already exists
if (Test-Path -LiteralPath $LinkPath) {
    $existingItem = Get-Item -LiteralPath $LinkPath -Force
    $isReparsePoint = ($existingItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0
    if ($isReparsePoint) {
        Write-Host "[OK] '$LinkPath' already exists as a directory link/junction." -ForegroundColor Green
        exit 0
    } else {
        # Check if it already contains a GGUF file or server binary
        $hasFiles = Get-ChildItem -LiteralPath $LinkPath -ErrorAction SilentlyContinue
        if ($hasFiles) {
            Write-Host "[OK] '$LinkPath' already exists as a populated directory. Leaving it untouched." -ForegroundColor Green
            exit 0
        }
    }
}

# 2. Verify the source runtime directory exists
if (-not (Test-Path -LiteralPath $SourceRuntimeDir)) {
    Write-Warning "Source runtime folder not found at: $SourceRuntimeDir"
    Write-Host "Please specify -SourceRuntimeDir <path-to-llama.cpp-and-gguf> when running this script." -ForegroundColor Yellow
    exit 1
}

if ($DryRun) {
    Write-Host "[DRY-RUN] Would create directory junction '$LinkPath' -> '$SourceRuntimeDir'." -ForegroundColor Yellow
    Write-Host "[DRY-RUN] 0 bytes of the ~5 GB model would be copied." -ForegroundColor Green
    exit 0
}

# 3. Attempt to create a Windows Directory Junction (requires no Admin rights on NTFS/ReFS)
$junctionCreated = $false
try {
    $null = New-Item -ItemType Junction -Path $LinkPath -Target $SourceRuntimeDir -ErrorAction Stop
    $junctionCreated = $true
    Write-Host "[OK] Created directory junction:" -ForegroundColor Green
    Write-Host "     $LinkPath -> $SourceRuntimeDir"
    Write-Host "     No model files were duplicated (0 bytes copied)." -ForegroundColor Green
    exit 0
} catch {
    Write-Warning "Could not create a directory junction automatically: $($_.Exception.Message)"
}

# 4. If junction creation failed (e.g. target is a FAT32/exFAT USB stick), NEVER copy silently
if (-not $junctionCreated) {
    Write-Host ""
    Write-Host "[IMPORTANT] Linking was not possible on this drive/filesystem." -ForegroundColor Yellow
    Write-Host "The local model and runtime in '$SourceRuntimeDir' is approximately 5 GB." -ForegroundColor Yellow

    if (-not $CopyIfNeeded) {
        Write-Host "By rule, DSAI never copies the ~5 GB model automatically." -ForegroundColor Cyan
        Write-Host "If you really want to copy the ~5 GB model to '$LinkPath', re-run with:" -ForegroundColor Cyan
        Write-Host "  powershell -ExecutionPolicy Bypass -File .\tools\link-runtime.ps1 -CopyIfNeeded"
        exit 2
    }

    $confirmation = Read-Host "Type YES (in capital letters) to confirm copying ~5 GB from '$SourceRuntimeDir' to '$LinkPath'"
    if ($confirmation -ceq "YES") {
        New-Item -ItemType Directory -Path $LinkPath -ErrorAction Stop | Out-Null
        Write-Host "Copying runtime files to '$LinkPath' (this may take several minutes)..." -ForegroundColor Cyan
        Copy-Item -Path (Join-Path $SourceRuntimeDir "*") -Destination $LinkPath -Recurse -ErrorAction Stop
        Write-Host "[OK] Runtime copied to '$LinkPath'." -ForegroundColor Green
        exit 0
    } else {
        Write-Host "[CANCELLED] Model copy was not confirmed. Nothing was copied." -ForegroundColor Yellow
        exit 3
    }
}