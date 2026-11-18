# DSAI portable start script (backlog item 5, fully merged).
# Finds the model and llama.cpp runtime by RELATIVE path, so the whole DSAI
# folder can be copied to another Windows PC or a USB stick.
# Search order: -LlmRoot parameter, DSAI\runtime, DSAI\models + DSAI\runtime,
# then the default install in %USERPROFILE%\.continue\local-llm.
# Calls tools/link-runtime.ps1 to safely link the runtime if needed.
# Never stops another program. Use -DryRun to just print what it would do.
param(
    [string]$LlmRoot = '',
    [string]$ModelFile = 'Qwen3-8B-Q4_K_M.gguf',
    [string]$Alias = 'cst-qwen3-8b',
    [int]$Port = 8081,
    [int]$MinFreeGiB = 4,
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$candidates = @()
if ($LlmRoot) { $candidates += $LlmRoot }
$candidates += (Join-Path $repo 'runtime')
$candidates += $repo
$candidates += (Join-Path $env:USERPROFILE '.continue\local-llm')
$model = $null; $server = $null; $root = $null
foreach ($c in $candidates) {
    $m = Join-Path $c (Join-Path 'models' $ModelFile)
    if (!(Test-Path -LiteralPath $m)) { continue }
    $s = @(Get-ChildItem -LiteralPath $c -Recurse -File -Filter 'llama-server.exe' -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '\\private\\' })
    if ($s.Count -ge 1) { $model = $m; $server = $s[0].FullName; $root = $c; break }
}
if (!$model) {
    Write-Host "Model '$ModelFile' or llama-server.exe not found in primary search paths." -ForegroundColor Yellow
    Write-Host "Attempting to link runtime via tools\link-runtime.ps1..." -ForegroundColor Cyan
    $linkScript = Join-Path $PSScriptRoot "link-runtime.ps1"
    if (Test-Path -LiteralPath $linkScript) {
        if ($DryRun) {
            & $linkScript -DryRun
        } else {
            & $linkScript
        }
        $m = Join-Path (Join-Path $repo 'runtime') (Join-Path 'models' $ModelFile)
        if (Test-Path -LiteralPath $m) {
            $s = @(Get-ChildItem -LiteralPath (Join-Path $repo 'runtime') -Recurse -File -Filter 'llama-server.exe' -ErrorAction SilentlyContinue)
            if ($s.Count -ge 1) { $model = $m; $server = $s[0].FullName; $root = (Join-Path $repo 'runtime') }
        }
    }
    if (!$model) { throw "Model '$ModelFile' or llama-server.exe not found. Looked in: $($candidates -join '; ')" }
}
Write-Output "Model:  $model"
Write-Output "Server: $server"
$existing = $null
try { $existing = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/v1/models" -TimeoutSec 3 } catch {}
if ($null -ne $existing) {
    if (@($existing.data.id) -contains $Alias) { Write-Output "DSAI is already running on port $Port."; return }
    throw "Port $Port is used by another server. Nothing was stopped."
}
$os = Get-CimInstance Win32_OperatingSystem
$freeGiB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
Write-Output "Free RAM: $freeGiB GiB (need $MinFreeGiB)"
if ($freeGiB -lt $MinFreeGiB) { throw "Not enough free RAM. Close other apps and try again." }
$logs = Join-Path $repo 'private\logs'
$args2 = @('-m', ('"' + $model + '"'), '--alias', $Alias, '--host', '127.0.0.1', '--port', "$Port", '--ctx-size', '8192', '--parallel', '1', '--threads', '8', '--cache-type-k', 'q8_0', '--cache-type-v', 'q8_0', '--flash-attn', 'on', '--jinja', '--reasoning', 'off', '--gpu-layers', , '--offline', '--no-webui')
if ($DryRun) { Write-Output "DryRun: would start $server $($args2 -join ' ')"; return }
if (!(Test-Path -LiteralPath $logs)) { New-Item -ItemType Directory -Path $logs | Out-Null }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$p = Start-Process -FilePath $server -ArgumentList $args2 -WorkingDirectory $root -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $logs "server-$stamp.out.log") -RedirectStandardError (Join-Path $logs "server-$stamp.err.log")
Write-Output "Started DSAI server, PID $($p.Id). Give it about a minute to load."

