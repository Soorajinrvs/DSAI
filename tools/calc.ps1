<#
.SYNOPSIS
    Exact calculation helper for DSAI (Backlog Item 8).
.DESCRIPTION
    Created 7 Nov 2026.
    Language models (like Qwen3-8B-Q4_K_M) predict tokens rather than computing exact arithmetic.
    This script evaluates mathematical expressions safely in PowerShell so DSAI or the user
    gets exact numeric answers instead of guesses.
    Supports: +, -, *, /, %, parentheses, decimals, and common math functions:
    sqrt(x), abs(x), round(x, n), pow(x, y), floor(x), ceiling(x), sin(x), cos(x), tan(x), pi.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Expression,

    [Parameter(Mandatory = $false)]
    [int]$RoundDecimals = 6,

    [Parameter(Mandatory = $false)]
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$rawExpr = $Expression.Trim()
if ([string]::IsNullOrWhiteSpace($rawExpr)) {
    throw "Expression cannot be empty."
}

# 1. Strict security validation: allow ONLY numbers, arithmetic operators, parentheses, commas, whitespace,
# and a strict whitelist of safe math function names. Never allow arbitrary PowerShell commands or variables ($).
$workExpr = $rawExpr

# Replace safe named constants and functions (case-insensitive) with [System.Math] calls
$safeReplacements = @(
    @{ Pattern = '\bpi\b';      Replacement = '([System.Math]::PI)' },
    @{ Pattern = '\bsqrt\s*\('; Replacement = '[System.Math]::Sqrt(' },
    @{ Pattern = '\babs\s*\(';  Replacement = '[System.Math]::Abs(' },
    @{ Pattern = '\bround\s*\(';Replacement = '[System.Math]::Round(' },
    @{ Pattern = '\bpow\s*\(';  Replacement = '[System.Math]::Pow(' },
    @{ Pattern = '\bfloor\s*\(';Replacement = '[System.Math]::Floor(' },
    @{ Pattern = '\bceil(?:ing)?\s*\('; Replacement = '[System.Math]::Ceiling(' },
    @{ Pattern = '\bsin\s*\(';  Replacement = '[System.Math]::Sin(' },
    @{ Pattern = '\bcos\s*\(';  Replacement = '[System.Math]::Cos(' },
    @{ Pattern = '\btan\s*\(';  Replacement = '[System.Math]::Tan(' }
)

# Check that removing valid math tokens leaves only digits, operators, decimals, commas, and brackets
$validationCopy = $rawExpr
foreach ($fn in @('pi', 'sqrt', 'abs', 'round', 'pow', 'floor', 'ceiling', 'ceil', 'sin', 'cos', 'tan')) {
    $validationCopy = $validationCopy -ireplace "\b$fn\b", ""
}

if ($validationCopy -match '[^0-9\+\-\*\/\%\(\)\.\,\s\^]') {
    throw "Unsafe or unsupported characters in expression: '$rawExpr'. Allowed: numbers, + - * / % ^ ( ) and sqrt, abs, round, pow, floor, ceiling, pi."
}

# Convert caret exponent (a ^ b) if present when not using functions
while ($workExpr -match '([0-9\.]+)\s*\^\s*([0-9\.]+)') {
    $workExpr = $workExpr -replace '([0-9\.]+)\s*\^\s*([0-9\.]+)', '[System.Math]::Pow($1, $2)'
}

foreach ($item in $safeReplacements) {
    $workExpr = $workExpr -ireplace $item.Pattern, $item.Replacement
}

# 2. Force floating-point division in PowerShell by casting numeric literals cleanly via Invoke-Expression on our strictly validated math string
try {
    $scriptBlock = [scriptblock]::Create("double")
    $rawResult = Invoke-Expression $workExpr
    $numericResult = [double]$rawResult
} catch {
    throw "Could not evaluate math expression '$rawExpr': $($_.Exception.Message)"
}

$roundedResult = [System.Math]::Round($numericResult, $RoundDecimals)

# Format cleanly (strip trailing .0 if it is an exact integer)
if ($roundedResult -eq [System.Math]::Floor($roundedResult)) {
    $formatted = ([int64]$roundedResult).ToString()
} else {
    $formatted = $roundedResult.ToString([System.Globalization.CultureInfo]::InvariantCulture)
}

if ($Json) {
    $outObj = @{
        expression = $rawExpr
        result     = $roundedResult
        formatted  = $formatted
    }
    Write-Output ($outObj | ConvertTo-Json -Compress)
} else {
    Write-Output $formatted
}