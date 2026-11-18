<#
.SYNOPSIS
    Per-user encrypted personal vault for DSAI (AES-256-CBC + PBKDF2-SHA256 + HMAC-SHA256).
.DESCRIPTION
    Created 7 Nov 2026 (Backlog Item 7).
    Protects personal memory notes in private/ so that when DSAI is locked or copied to
    another PC, zero personal data exists in readable form.
    - Uses built-in Windows/.NET cryptography (no downloads, no external modules).
    - Derives 64 bytes of key material via Rfc2898DeriveBytes (PBKDF2, 100,000 iterations,
      16-byte random salt): 32 bytes for AES-256 encryption + 32 bytes for HMAC-SHA256 authentication.
    - No master key and no back door. A lost passphrase means the vault cannot be recovered.
    - Never prints, logs, or stores the passphrase on disk.
    - Supports -PassphrasePlain ONLY for automated self-testing (tools/test-vault.ps1) with a
      fake test passphrase. Interactive users are prompted securely via Read-Host -AsSecureString.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("init", "unlock", "lock", "status")]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$VaultName = "default",

    [Parameter(Mandatory = $false)]
    [string]$VaultDir = (Join-Path (Split-Path -Parent $PSScriptRoot) "vault"),

    [Parameter(Mandatory = $false)]
    [string]$PrivateDir = (Join-Path (Split-Path -Parent $PSScriptRoot) "private"),

    [Parameter(Mandatory = $false)]
    [string]$PassphrasePlain
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Clean vault name so it is always a safe filename
$safeVaultName = ($VaultName -replace '[^a-zA-Z0-9_\-]', '').ToLowerInvariant()
if ([string]::IsNullOrWhiteSpace($safeVaultName)) {
    throw "VaultName must contain letters or numbers."
}

$vaultFile = Join-Path $VaultDir "$safeVaultName.vault"
$PBKDF2_ITERATIONS = 100000

# Helper: Get files in private/ that belong inside the encrypted vault
# (Excludes permanent documentation/templates: README.md and any *.template.md)
function Get-PrivateUserFiles {
    param([string]$Dir)
    if (-not (Test-Path -LiteralPath $Dir)) {
        return @()
    }
    return @(Get-ChildItem -LiteralPath $Dir -File -Force | Where-Object {
        $_.Name -ne "README.md" -and $_.Name -notmatch '\.template\.md$'
    })
}

# Helper: Securely overwrite a file with zeroes before deleting it
function Remove-FileSecurely {
    param([string]$FilePath)
    if (Test-Path -LiteralPath $FilePath) {
        try {
            $fileInfo = Get-Item -LiteralPath $FilePath -Force
            $length = $fileInfo.Length
            if ($length -gt 0) {
                $zeroBytes = New-Object byte[] $length
                [System.IO.File]::WriteAllBytes($FilePath, $zeroBytes)
            }
        } catch {
            # Continue to Remove-Item if file was empty
        }
        Remove-Item -LiteralPath $FilePath -ErrorAction Stop
    }
}

# Helper: Read passphrase securely from the console (unless automated test passed -PassphrasePlain)
function Get-UserPassphraseBytes {
    param(
        [string]$PromptText,
        [switch]$ConfirmTwice
    )
    if (-not [string]::IsNullOrEmpty($PassphrasePlain)) {
        return [System.Text.Encoding]::UTF8.GetBytes($PassphrasePlain)
    }

    $sec1 = Read-Host -Prompt $PromptText -AsSecureString
    $bstr1 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec1)
    try {
        $plain1 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr1)
    } finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr1)
    }

    if ([string]::IsNullOrEmpty($plain1) -or $plain1.Length -lt 8) {
        throw "Passphrase must be at least 8 characters long."
    }

    if ($ConfirmTwice) {
        $sec2 = Read-Host -Prompt "Confirm passphrase (type it again)" -AsSecureString
        $bstr2 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec2)
        try {
            $plain2 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr2)
        } finally {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr2)
        }
        if ($plain1 -cne $plain2) {
            throw "Passphrases did not match. Nothing was changed."
        }
    }

    return [System.Text.Encoding]::UTF8.GetBytes($plain1)
}

# Helper: Derive 32-byte AES key and 32-byte HMAC key using PBKDF2
function Get-DerivedKeys {
    param(
        [byte[]]$PassBytes,
        [byte[]]$SaltBytes,
        [int]$Iterations
    )
    try {
        $kdf = New-Object System.Security.Cryptography.Rfc2898DeriveBytes(
            $PassBytes,
            $SaltBytes,
            $Iterations,
            [System.Security.Cryptography.HashAlgorithmName]::SHA256
        )
    } catch {
        # Fallback for older .NET Framework 4.6 builds if 4-arg constructor is unavailable
        $kdf = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($PassBytes, $SaltBytes, $Iterations)
    }
    try {
        $aesKey = $kdf.GetBytes(32)
        $hmacKey = $kdf.GetBytes(32)
        return @{
            AesKey  = $aesKey
            HmacKey = $hmacKey
        }
    } finally {
        $kdf.Dispose()
    }
}

# Helper: Encrypt all private user files into the vault file
function Save-EncryptedVault {
    param(
        [byte[]]$PassBytes,
        [string]$TargetVaultFile,
        [string]$SourcePrivateDir
    )
    if (-not (Test-Path -LiteralPath $VaultDir)) {
        New-Item -ItemType Directory -Path $VaultDir | Out-Null
    }

    $userFiles = @(Get-PrivateUserFiles -Dir $SourcePrivateDir)
    if ($userFiles.Count -eq 0) {
        throw "No unlocked files found in '$SourcePrivateDir' to lock."
    }

    $payloadFiles = @()
    foreach ($f in $userFiles) {
        $rawBytes = [System.IO.File]::ReadAllBytes($f.FullName)
        $payloadFiles += @{
            Name          = $f.Name
            ContentBase64 = [Convert]::ToBase64String($rawBytes)
        }
    }

    $payloadObj = @{
        VaultName = $safeVaultName
        LockedAt  = (Get-Date).ToUniversalTime().ToString("o")
        Files     = $payloadFiles
    }
    $payloadJson = $payloadObj | ConvertTo-Json -Depth 5 -Compress
    $plainBytes = [System.Text.Encoding]::UTF8.GetBytes($payloadJson)

    # Generate random 16-byte salt and 16-byte AES IV
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $salt = New-Object byte[] 16
    $iv = New-Object byte[] 16
    $rng.GetBytes($salt)
    $rng.GetBytes($iv)
    $rng.Dispose()

    $keys = Get-DerivedKeys -PassBytes $PassBytes -SaltBytes $salt -Iterations $PBKDF2_ITERATIONS

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.KeySize = 256
    $aes.BlockSize = 128
    $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
    $aes.Key = $keys.AesKey
    $aes.IV = $iv

    $encryptor = $aes.CreateEncryptor()
    $cipherBytes = $encryptor.TransformFinalBlock($plainBytes, 0, $plainBytes.Length)
    $encryptor.Dispose()
    $aes.Dispose()

    # Compute HMAC-SHA256 over (salt + iv + cipherBytes) so tampering or wrong password fails cleanly
    $hmac = New-Object System.Security.Cryptography.HMACSHA256 -ArgumentList (,$keys.HmacKey)
    $dataToMac = New-Object byte[] ($salt.Length + $iv.Length + $cipherBytes.Length)
    [Array]::Copy($salt, 0, $dataToMac, 0, $salt.Length)
    [Array]::Copy($iv, 0, $dataToMac, $salt.Length, $iv.Length)
    [Array]::Copy($cipherBytes, 0, $dataToMac, ($salt.Length + $iv.Length), $cipherBytes.Length)
    $macBytes = $hmac.ComputeHash($dataToMac)
    $hmac.Dispose()

    # Back up existing .vault file to .vault.bak before replacing
    if (Test-Path -LiteralPath $TargetVaultFile) {
        Copy-Item -LiteralPath $TargetVaultFile -Destination "$TargetVaultFile.bak" -ErrorAction Stop
    }

    $envelope = @{
        Format     = "DSAI-VAULT-V1"
        Algorithm  = "AES-256-CBC+PBKDF2-SHA256+HMAC-SHA256"
        Iterations = $PBKDF2_ITERATIONS
        Salt       = [Convert]::ToBase64String($salt)
        IV         = [Convert]::ToBase64String($iv)
        Ciphertext = [Convert]::ToBase64String($cipherBytes)
        Hmac       = [Convert]::ToBase64String($macBytes)
    }

    $envelopeJson = $envelope | ConvertTo-Json -Depth 4
    Set-Content -LiteralPath $TargetVaultFile -Value $envelopeJson -Encoding UTF8

    if (Test-Path -LiteralPath "$TargetVaultFile.bak") {
        Remove-Item -LiteralPath "$TargetVaultFile.bak" -ErrorAction SilentlyContinue
    }
}

# ==================== ACTIONS ====================

if ($Action -eq "status") {
    $unlockedFiles = @(Get-PrivateUserFiles -Dir $PrivateDir)
    $vaultFiles = @()
    if (Test-Path -LiteralPath $VaultDir) {
        $vaultFiles = @(Get-ChildItem -LiteralPath $VaultDir -Filter "*.vault" -File -ErrorAction SilentlyContinue)
    }

    Write-Host "=== DSAI Personal Vault Status ===" -ForegroundColor Cyan
    if ($unlockedFiles.Count -gt 0) {
        Write-Host "State          : UNLOCKED ($($unlockedFiles.Count) personal file(s) active in private/)" -ForegroundColor Yellow
        foreach ($uf in $unlockedFiles) {
            Write-Host "                 - $($uf.Name)"
        }
        Write-Host "Reminder       : Run '.\tools\vault.ps1 -Action lock -VaultName <name>' when finished." -ForegroundColor Yellow
    } else {
        Write-Host "State          : LOCKED (DSAI sees zero personal memory; starts blank)" -ForegroundColor Green
    }

    if ($vaultFiles.Count -gt 0) {
        Write-Host "Encrypted vaults in '$VaultDir':"
        foreach ($vf in $vaultFiles) {
            Write-Host "  - $($vf.Name) ($($vf.Length) bytes)"
        }
    } else {
        Write-Host "Encrypted vaults: None created yet. Run '.\tools\vault.ps1 -Action init -VaultName <yourname>'."
    }
    exit 0
}

if ($Action -eq "init") {
    if (Test-Path -LiteralPath $vaultFile) {
        throw "Vault '$vaultFile' already exists. Choose a different -VaultName or use -Action unlock / -Action lock."
    }
    $existingUnlocked = @(Get-PrivateUserFiles -Dir $PrivateDir)
    if ($existingUnlocked.Count -gt 0) {
        throw "There are already unlocked personal files in '$PrivateDir'. Lock them first before initialising a new vault."
    }

    Write-Host "=== Initialise New DSAI Personal Vault ($safeVaultName) ===" -ForegroundColor Cyan
    Write-Host "IMPORTANT: Only your passphrase can unlock this vault. There is no master key." -ForegroundColor Yellow
    Write-Host "If you forget your passphrase, the data inside cannot be recovered." -ForegroundColor Yellow

    $passBytes = Get-UserPassphraseBytes -PromptText "Create a strong passphrase for vault '$safeVaultName'" -ConfirmTwice
    try {
        if (-not (Test-Path -LiteralPath $PrivateDir)) {
            New-Item -ItemType Directory -Path $PrivateDir | Out-Null
        }

        $templatePath = Join-Path $PrivateDir "MEMORY.template.md"
        $memoryPath = Join-Path $PrivateDir "MEMORY.md"
        if (Test-Path -LiteralPath $templatePath) {
            Copy-Item -LiteralPath $templatePath -Destination $memoryPath -ErrorAction Stop
        } else {
            Set-Content -LiteralPath $memoryPath -Value "# Personal Memory Notes ($safeVaultName)`r`n`r`n- Add your personal notes here.`r`n" -Encoding UTF8
        }

        Save-EncryptedVault -PassBytes $passBytes -TargetVaultFile $vaultFile -SourcePrivateDir $PrivateDir
        Write-Host "[OK] Created encrypted vault: $vaultFile" -ForegroundColor Green
        Write-Host "[OK] Unlocked workspace ready at: $memoryPath" -ForegroundColor Green
        Write-Host "     Edit '$memoryPath' while working, then run:"
        Write-Host "     powershell -ExecutionPolicy Bypass -File .\tools\vault.ps1 -Action lock -VaultName $safeVaultName"
    } finally {
        [Array]::Clear($passBytes, 0, $passBytes.Length)
    }
    exit 0
}

if ($Action -eq "lock") {
    $unlockedFiles = @(Get-PrivateUserFiles -Dir $PrivateDir)
    if ($unlockedFiles.Count -eq 0) {
        Write-Host "[OK] Vault is already locked (no personal files present in '$PrivateDir')." -ForegroundColor Green
        exit 0
    }

    Write-Host "=== Locking DSAI Personal Vault ($safeVaultName) ===" -ForegroundColor Cyan
    $confirmTwice = -not (Test-Path -LiteralPath $vaultFile)
    $passBytes = Get-UserPassphraseBytes -PromptText "Enter passphrase to lock vault '$safeVaultName'" -ConfirmTwice:$confirmTwice

    try {
        # If the vault file already exists, verify that the passphrase matches the existing vault first
        # so a typo when locking doesn't accidentally change the user's passphrase without warning
        if (Test-Path -LiteralPath $vaultFile) {
            $existingEnvelope = Get-Content -LiteralPath $vaultFile -Raw -Encoding UTF8 | ConvertFrom-Json
            $oldSalt = [Convert]::FromBase64String($existingEnvelope.Salt)
            $oldIv = [Convert]::FromBase64String($existingEnvelope.IV)
            $oldCipher = [Convert]::FromBase64String($existingEnvelope.Ciphertext)
            $oldMac = [Convert]::FromBase64String($existingEnvelope.Hmac)
            $oldKeys = Get-DerivedKeys -PassBytes $passBytes -SaltBytes $oldSalt -Iterations ([int]$existingEnvelope.Iterations)

            $hmacCheck = New-Object System.Security.Cryptography.HMACSHA256 -ArgumentList (,$oldKeys.HmacKey)
            $checkBuf = New-Object byte[] ($oldSalt.Length + $oldIv.Length + $oldCipher.Length)
            [Array]::Copy($oldSalt, 0, $checkBuf, 0, $oldSalt.Length)
            [Array]::Copy($oldIv, 0, $checkBuf, $oldSalt.Length, $oldIv.Length)
            [Array]::Copy($oldCipher, 0, $checkBuf, ($oldSalt.Length + $oldIv.Length), $oldCipher.Length)
            $computedMac = $hmacCheck.ComputeHash($checkBuf)
            $hmacCheck.Dispose()

            $macMatch = ([Convert]::ToBase64String($computedMac) -ceq [Convert]::ToBase64String($oldMac))
            if (-not $macMatch) {
                throw "Incorrect passphrase for existing vault '$safeVaultName'. Files were left untouched."
            }
        }

        Save-EncryptedVault -PassBytes $passBytes -TargetVaultFile $vaultFile -SourcePrivateDir $PrivateDir

        foreach ($f in $unlockedFiles) {
            Remove-FileSecurely -FilePath $f.FullName
        }

        Write-Host "[OK] Encrypted $($unlockedFiles.Count) file(s) into '$vaultFile'." -ForegroundColor Green
        Write-Host "[OK] Securely wiped plaintext files from '$PrivateDir'. DSAI is now blank." -ForegroundColor Green
    } finally {
        [Array]::Clear($passBytes, 0, $passBytes.Length)
    }
    exit 0
}

if ($Action -eq "unlock") {
    if (-not (Test-Path -LiteralPath $vaultFile)) {
        throw "Vault file not found: '$vaultFile'. Check -VaultName or run -Action init first."
    }

    $existingUnlocked = @(Get-PrivateUserFiles -Dir $PrivateDir)
    if ($existingUnlocked.Count -gt 0) {
        throw "Personal files are already unlocked in '$PrivateDir'. Lock them first before unlocking another vault."
    }

    Write-Host "=== Unlocking DSAI Personal Vault ($safeVaultName) ===" -ForegroundColor Cyan
    $passBytes = Get-UserPassphraseBytes -PromptText "Enter passphrase to unlock '$safeVaultName'"

    try {
        $envelope = Get-Content -LiteralPath $vaultFile -Raw -Encoding UTF8 | ConvertFrom-Json
        $salt = [Convert]::FromBase64String($envelope.Salt)
        $iv = [Convert]::FromBase64String($envelope.IV)
        $cipherBytes = [Convert]::FromBase64String($envelope.Ciphertext)
        $expectedMac = [Convert]::FromBase64String($envelope.Hmac)
        $iterations = [int]$envelope.Iterations

        $keys = Get-DerivedKeys -PassBytes $passBytes -SaltBytes $salt -Iterations $iterations

        # Verify HMAC before attempting decryption
        $hmac = New-Object System.Security.Cryptography.HMACSHA256 -ArgumentList (,$keys.HmacKey)
        $dataToMac = New-Object byte[] ($salt.Length + $iv.Length + $cipherBytes.Length)
        [Array]::Copy($salt, 0, $dataToMac, 0, $salt.Length)
        [Array]::Copy($iv, 0, $dataToMac, $salt.Length, $iv.Length)
        [Array]::Copy($cipherBytes, 0, $dataToMac, ($salt.Length + $iv.Length), $cipherBytes.Length)
        $actualMac = $hmac.ComputeHash($dataToMac)
        $hmac.Dispose()

        if ([Convert]::ToBase64String($actualMac) -cne [Convert]::ToBase64String($expectedMac)) {
            throw "Invalid passphrase or corrupted vault file. Cannot unlock '$safeVaultName'."
        }

        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.KeySize = 256
        $aes.BlockSize = 128
        $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
        $aes.Key = $keys.AesKey
        $aes.IV = $iv

        $decryptor = $aes.CreateDecryptor()
        $plainBytes = $decryptor.TransformFinalBlock($cipherBytes, 0, $cipherBytes.Length)
        $decryptor.Dispose()
        $aes.Dispose()

        $payloadJson = [System.Text.Encoding]::UTF8.GetString($plainBytes)
        $payload = $payloadJson | ConvertFrom-Json

        if (-not (Test-Path -LiteralPath $PrivateDir)) {
            New-Item -ItemType Directory -Path $PrivateDir | Out-Null
        }

        $restoredCount = 0
        foreach ($fileEntry in $payload.Files) {
            $safeFileName = [System.IO.Path]::GetFileName($fileEntry.Name)
            $destPath = Join-Path $PrivateDir $safeFileName
            $fileBytes = [Convert]::FromBase64String($fileEntry.ContentBase64)
            [System.IO.File]::WriteAllBytes($destPath, $fileBytes)
            $restoredCount++
        }

        Write-Host "[OK] Unlocked $restoredCount file(s) into '$PrivateDir'." -ForegroundColor Green
        Write-Host "     Remember to lock your vault when finished:"
        Write-Host "     powershell -ExecutionPolicy Bypass -File .\tools\vault.ps1 -Action lock -VaultName $safeVaultName"
    } finally {
        [Array]::Clear($passBytes, 0, $passBytes.Length)
    }
    exit 0
}