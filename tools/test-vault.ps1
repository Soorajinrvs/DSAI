<#
.SYNOPSIS
    Automated self-test for the DSAI encrypted personal vault (Backlog Item 7).
.DESCRIPTION
    Created 7 Nov 2026.
    Tests creating, editing, locking, rejecting a wrong passphrase, and unlocking
    a dummy vault in an isolated temporary folder using ONLY the clearly fake test
    passphrase "TestVaultPassphrase-DoNotUse".
    Never touches the real vault/ or private/ folders. Cleans up after itself.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$dsaiRoot = Split-Path -Parent $PSScriptRoot
$vaultScript = Join-Path $PSScriptRoot "vault.ps1"
$tempRoot = Join-Path $dsaiRoot "tests\tmp-vault"
$tempVaultDir = Join-Path $tempRoot "vault"
$tempPrivateDir = Join-Path $tempRoot "private"

$fakePassphrase = "TestVaultPassphrase-DoNotUse"
$wrongPassphrase = "WrongPassphrase-DoNotUse"
$dummyNoteText = "Dummy test note for automated vault verification: 42-Alpha-Bravo."

Write-Host "=== DSAI Dummy Vault Automated Test ===" -ForegroundColor Cyan

# Ensure a clean temporary test directory
if (Test-Path -LiteralPath $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $tempVaultDir | Out-Null
New-Item -ItemType Directory -Path $tempPrivateDir | Out-Null
Set-Content -LiteralPath (Join-Path $tempPrivateDir "README.md") -Value "# Temp README" -Encoding UTF8

try {
    # 1. Initialise dummy vault
    Write-Host "[1/6] Initialising dummy vault..."
    & $vaultScript -Action init -VaultName "dummytest" -VaultDir $tempVaultDir -PrivateDir $tempPrivateDir -PassphrasePlain $fakePassphrase

    $memoryFile = Join-Path $tempPrivateDir "MEMORY.md"
    if (-not (Test-Path -LiteralPath $memoryFile)) {
        throw "FAIL: MEMORY.md was not created during init."
    }

    # 2. Write dummy note into MEMORY.md and lock the vault
    Write-Host "[2/6] Writing dummy note and locking vault..."
    Set-Content -LiteralPath $memoryFile -Value $dummyNoteText -Encoding UTF8
    & $vaultScript -Action lock -VaultName "dummytest" -VaultDir $tempVaultDir -PrivateDir $tempPrivateDir -PassphrasePlain $fakePassphrase

    # 3. Verify plaintext file is gone and ciphertext does not contain plaintext
    Write-Host "[3/6] Verifying plaintext is removed and vault is encrypted..."
    if (Test-Path -LiteralPath $memoryFile) {
        throw "FAIL: Plaintext MEMORY.md still exists after locking!"
    }
    $vaultFilePath = Join-Path $tempVaultDir "dummytest.vault"
    if (-not (Test-Path -LiteralPath $vaultFilePath)) {
        throw "FAIL: Encrypted dummytest.vault file was not found!"
    }
    $rawVaultContent = Get-Content -LiteralPath $vaultFilePath -Raw -Encoding UTF8
    if ($rawVaultContent -match "42-Alpha-Bravo") {
        throw "FAIL: Plaintext note leaked inside the .vault file!"
    }
    Write-Host "      [PASS] Plaintext removed from private/ and not visible in .vault file." -ForegroundColor Green

    # 4. Verify unlocking with a wrong passphrase fails cleanly
    Write-Host "[4/6] Verifying wrong passphrase is rejected..."
    $wrongFailed = $false
    try {
        & $vaultScript -Action unlock -VaultName "dummytest" -VaultDir $tempVaultDir -PrivateDir $tempPrivateDir -PassphrasePlain $wrongPassphrase 2>$null
    } catch {
        $wrongFailed = $true
    }
    if (-not $wrongFailed -or (Test-Path -LiteralPath $memoryFile)) {
        throw "FAIL: Vault unlocked with the wrong passphrase!"
    }
    Write-Host "      [PASS] Wrong passphrase was rejected and private/ stayed blank." -ForegroundColor Green

    # 5. Unlock with the correct fake test passphrase and verify exact content matches
    Write-Host "[5/6] Unlocking with correct test passphrase and checking restored content..."
    & $vaultScript -Action unlock -VaultName "dummytest" -VaultDir $tempVaultDir -PrivateDir $tempPrivateDir -PassphrasePlain $fakePassphrase
    if (-not (Test-Path -LiteralPath $memoryFile)) {
        throw "FAIL: MEMORY.md was not restored on unlock."
    }
    $restoredText = (Get-Content -LiteralPath $memoryFile -Raw -Encoding UTF8).Trim()
    if ($restoredText -cne $dummyNoteText) {
        throw "FAIL: Restored text ('$restoredText') did not match expected ('$dummyNoteText')."
    }
    Write-Host "      [PASS] Restored content matches 100%." -ForegroundColor Green

    # 6. Lock again to finish cleanly
    Write-Host "[6/6] Re-locking dummy vault..."
    & $vaultScript -Action lock -VaultName "dummytest" -VaultDir $tempVaultDir -PrivateDir $tempPrivateDir -PassphrasePlain $fakePassphrase

    Write-Host ""
    Write-Host "[SUCCESS] All 6 dummy vault security checks passed!" -ForegroundColor Green
} finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}