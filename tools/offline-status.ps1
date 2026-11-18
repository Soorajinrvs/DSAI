<#
.SYNOPSIS
    Check DSAI offline status (PowerShell 5.1+).
.DESCRIPTION
    Reports whether the local model server is reachable on 127.0.0.1:8081,
    whether inbox/ has open tasks, and a reminder of what stays online.
    No network calls except the localhost check.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

$dsaiRoot = Split-Path -Parent $PSScriptRoot
$inboxDir = Join-Path $dsaiRoot "inbox"

Write-Host "=== DSAI Offline Status ==="
Write-Host ""

Write-Host "1. Local Model Server:" -NoNewline
$modelRunning = $false
$client = New-Object System.Net.Sockets.TcpClient
try {
    $iar = $client.BeginConnect("127.0.0.1", 8081, $null, $null)
    $waited = $iar.AsyncWaitHandle.WaitOne(1000, $false)
    if ($waited -and $client.Connected) {
        Write-Host " Running (127.0.0.1 port 8081)"
        $modelRunning = $true
    }
    else {
        Write-Host " Not reachable"
    }
}
catch {
    Write-Host " Not reachable"
}
finally {
    $client.Close()
}

Write-Host "2. Inbox Tasks:" -NoNewline
$taskFiles = @()
if (Test-Path -LiteralPath $inboxDir) {
    $taskFiles = @(Get-ChildItem -LiteralPath $inboxDir -Filter "*.md" -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "README.md" -and $_.Name -ne "TEMPLATE.md" })
}
$taskCount = $taskFiles.Count

if ($taskCount -gt 0) {
    Write-Host " $taskCount open task(s)"
    foreach ($task in $taskFiles) {
        Write-Host "   - $($task.Name)"
    }
}
else {
    Write-Host " None"
}

Write-Host ""
Write-Host "3. What Stays Online:"
Write-Host "   Web browsing, bank login, live Numbers workbook, email send, cloud sync"

Write-Host ""
Write-Host "Status: " -NoNewline
if ($modelRunning) {
    Write-Host "Ready for work offline"
}
else {
    Write-Host "Model server not running; start with tools/start-dsai.ps1"
}