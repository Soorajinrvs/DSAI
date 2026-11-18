<#
.SYNOPSIS
    Runs the generic DSAI test suite and scores the answers (Backlog Item 9).
.DESCRIPTION
    Created 7 Nov 2026.
    Reads generic questions from tests\questions.json.
    - For arithmetic questions that specify calcExpression, runs tools\calc.ps1 first to show
      exact calculation vs LLM guessing.
    - If http://127.0.0.1:8081 is reachable (and -OfflineSelfTest is not passed), sends each
      question to the local llama.cpp server and scores the reply.
    - If -OfflineSelfTest is passed (or the server is not running), runs a deterministic
      self-test using calc.ps1 and the reference answers so you can verify the test runner anytime.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ApiUrl = "http://127.0.0.1:8081/v1/chat/completions",

    [Parameter(Mandatory = $false)]
    [string]$ModelAlias = "cst-qwen3-8b",

    [Parameter(Mandatory = $false)]
    [string]$QuestionsFile = (Join-Path (Split-Path -Parent $PSScriptRoot) "tests\questions.json"),

    [Parameter(Mandatory = $false)]
    [switch]$OfflineSelfTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$calcScript = Join-Path $PSScriptRoot "calc.ps1"
if (-not (Test-Path -LiteralPath $QuestionsFile)) {
    throw "Questions file not found at: $QuestionsFile"
}

$questions = Get-Content -LiteralPath $QuestionsFile -Raw -Encoding UTF8 | ConvertFrom-Json

# Check if local server on port 8081 is online when not forcing -OfflineSelfTest
$useLiveServer = $false
if (-not $OfflineSelfTest) {
    try {
        $uri = [System.Uri]$ApiUrl
        $tcp = New-Object System.Net.Sockets.TcpClient
        $wait = $tcp.BeginConnect($uri.Host, $uri.Port, $null, $null).AsyncWaitHandle.WaitOne(400, $false)
        if ($wait -and $tcp.Connected) {
            $useLiveServer = $true
        }
        $tcp.Close()
    } catch {
        $useLiveServer = $false
    }
}

Write-Host "=== DSAI Benchmark & Scorer ===" -ForegroundColor Cyan
if ($useLiveServer) {
    Write-Host "Mode : LIVE SERVER ($ApiUrl, model: $ModelAlias)" -ForegroundColor Green
} else {
    Write-Host "Mode : OFFLINE SELF-TEST (Calculator + Reference Scorer)" -ForegroundColor Yellow
}
Write-Host ""

$passed = 0
$total = $questions.Count
$resultsLog = @()

foreach ($q in $questions) {
    Write-Host "[$($q.id)] $($q.category)" -ForegroundColor Cyan
    Write-Host "  Prompt : $($q.prompt)"

    $calcOutput = $null
    if (-not [string]::IsNullOrWhiteSpace($q.calcExpression)) {
        $calcOutput = (& $calcScript $q.calcExpression).Trim()
        Write-Host "  Calc   : $($q.calcExpression) = $calcOutput (via tools\calc.ps1)" -ForegroundColor DarkCyan
    }

    $answerText = ""
    if ($useLiveServer) {
        $systemMsg = "You are DSAI, a concise offline assistant. Reply directly and concisely."
        if ($calcOutput) {
            $systemMsg += " Exact calculator helper result for $($q.calcExpression) is $calcOutput."
        }
        $reqBody = @{
            model       = $ModelAlias
            temperature = 0.1
            max_tokens  = 150
            messages    = @(
                @{ role = "system"; content = $systemMsg },
                @{ role = "user";   content = $q.prompt }
            )
        } | ConvertTo-Json -Depth 5

        try {
            $resp = Invoke-RestMethod -Uri $ApiUrl -Method Post -ContentType "application/json" -Body $reqBody -TimeoutSec 60
            $answerText = $resp.choices[0].message.content
            # Strip <think>...</think> blocks if Qwen3 emits reasoning tags
            $answerText = ($answerText -replace '(?s)<think>.*?</think>', '').Trim()
        } catch {
            $answerText = "[ERROR querying local server: $($_.Exception.Message)]"
        }
    } else {
        if ($calcOutput) {
            $answerText = "Computed via calc.ps1: $calcOutput. $($q.mockOfflineAnswer)"
        } else {
            $answerText = $q.mockOfflineAnswer
        }
    }

    Write-Host "  Answer : $answerText"

    # Score the answer against all expected substrings (case-insensitive)
    $allMatched = $true
    foreach ($expected in $q.expectedSubstrings) {
        if ($answerText -notmatch [regex]::Escape($expected)) {
            $allMatched = $false
        }
    }

    if ($allMatched) {
        $passed++
        Write-Host "  Result : PASS" -ForegroundColor Green
    } else {
        Write-Host "  Result : FAIL (Expected to find: $($q.expectedSubstrings -join ', '))" -ForegroundColor Red
    }
    Write-Host ""

    $resultsLog += @{
        id       = $q.id
        category = $q.category
        passed   = $allMatched
        calcUsed = [bool]$calcOutput
        answer   = $answerText
    }
}

Write-Host "=== Final Score: $passed / $total Passed ===" -ForegroundColor $(if ($passed -eq $total) { "Green" } else { "Yellow" })

if ($passed -lt $total) {
    exit 1
}
exit 0