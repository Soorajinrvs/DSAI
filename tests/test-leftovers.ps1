<#
.SYNOPSIS
    Test for Show-Leftovers function against a known snapshot fixture.
    PowerShell 5.1 compatible.
.DESCRIPTION
    Validates that the leftovers output matches expected budget values:
    - Groceries: cap 300.00 | spent 346.68 | remaining -46.68
    - Eating Out: cap 400.00 | spent 664.41 | remaining -264.41
    - Allowance Sunny: cap 200.00 | spent 93.10 | remaining 106.90
    - Allowance Drashti: cap 200.00 | spent 137.88 | remaining 62.12
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$dsaiRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$testsDir = Split-Path -Parent $PSScriptRoot

# Create a temporary fixture CSV for testing
$fixtureFile = Join-Path $env:TEMP "test-snapshot.csv"

# Copy of verified data from LIVE-SNAPSHOT.csv (2026-10-14 to 2026-11-10)
$fixtureContent = @'
Date,Category,Merchant,Amount,Notes
2026-10-16,Groceries,Woolworths Bentley Plaza,-5.70,
2026-10-16,Groceries,Woolworths Bentley Plaza,-25.75,
2026-10-22,Groceries,India Grocer Cannington,-32.43,
2026-10-20,Groceries,"Dominos Bentley (Drashti allowance overspend, from Groceries)",-11.78,
2026-10-23,Groceries,"LS Kensington Cafe (Drashti allowance overspend, from Groceries)",-7.00,
2026-10-23,Groceries,"Zambrero Karawara (Drashti eating out, allowance used, from Groceries)",-12.20,
2026-10-24,Groceries,Spud Shed Bentley,-6.95,
2026-10-25,Groceries,Woolworths Bentley,-13.45,
2026-10-26,Groceries,"LS Kensington Cafe (Drashti coffee, allowance overspend, from Groceries)",-5.70,
2026-10-26,Groceries,"Hungry Jack's, Drashti eating out (Eating Out budget used up)",-5.00,
2026-10-27,Groceries,"Mercato Cafe Bentley, Drashti allowance overspend, from Groceries",-13.50,
2026-10-28,Groceries,Woolworths Cannington (gift card + V9636),-63.97,
2026-10-28,Groceries,Local Fresh Gourmet Market,-3.87,
2026-11-02,Groceries,Vale IGA Aveley,-21.73,
2026-11-03,Groceries,"Uber Eats (takeaway together 3 Nov night, shared 50/50, pending)",-67.65,
2026-11-03,Groceries,"Mercato Cafe Bentley (Drashti allowance overspend, from Groceries, pending)",-3.02,
2026-11-03,Groceries,Woolworths Carousel Cannington (pending),-13.08,
2026-11-04,Groceries,"LS Kensington Cafe (Drashti allowance overspend, from Groceries, pending)",-12.70,
2026-11-03,Groceries,Prime Ind Grocery,-75.65,
2026-11-06,Groceries,LS Kensington Cafe Kensington,-13.20,"Drashti allowance overspend, from Groceries"
2026-10-15,Eating Out,La Mint Events & Catering,-6.80,
2026-10-15,Eating Out,Drashti - eating out drinks,-65.49,
2026-10-15,Eating Out,Ramen Samurai Albany,-128.50,
2026-10-28,Eating Out,"Om Sweet & Curry House (27/10, from next fortnight)",-41.98,
2026-10-28,Eating Out,"Imperial Tavern (27/10, from next fortnight)",-32.00,
2026-10-28,Eating Out,Criniti's Carousel,-139.00,
2026-10-30,Eating Out,"Uber Eats (Drashti, from bank balance; not yet in Frollo)",-22.44,
2026-10-30,Eating Out,"Zambrero Waterford Karawara (Drashti, pending)",-19.80,
2026-11-01,Eating Out,McDonald's Cannington,-0.50,
2026-11-01,Eating Out,The Imperial Lounge Cannington,-32.00,
2026-11-02,Eating Out,Cheol's 66 Sgt Perth,-19.60,
2026-11-03,Eating Out,Gemini Cafe Perth,-35.80,
2026-11-03,Eating Out,"Uber Eats (takeaway together 3 Nov night, shared 50/50, pending)",-67.65,
2026-11-04,Eating Out,Domino's Bentley,-31.95,Posted 2026-11-06; Purchase night of 4 Nov
2026-11-06,Eating Out,Hungry Jack's Bentley Plaza,-16.90,Sunny away; Drashti's meal
2026-11-06,Eating Out,Hungry Jack's Bentley Plaza,-4.00,Sunny away; Drashti's meal
2026-10-16,Allowance Sunny,Compass Group Packsaddle Newman,-5.70,
2026-10-17,Allowance Sunny,Compass Group Packsaddle Newman,-5.70,
2026-10-18,Allowance Sunny,Compass Group Packsaddle Newman,-5.70,
2026-10-19,Allowance Sunny,Compass Group Packsaddle Newman,-5.70,
2026-10-20,Allowance Sunny,Compass Group Packsaddle Newman,-5.70,
2026-10-21,Allowance Sunny,Compass Group Packsaddle Newman,-5.70,
2026-10-22,Allowance Sunny,Compass Group Packsaddle Newman,-5.70,
2026-10-23,Allowance Sunny,Compass Group Packsaddle Newman,-5.70,
2026-10-24,Allowance Sunny,Compass Packsaddle Newman,-5.70,
2026-10-25,Allowance Sunny,Compass Packsaddle Newman,-5.70,
2026-10-26,Allowance Sunny,Compass Packsaddle Newman (camp coffee),-5.70,
2026-10-28,Allowance Sunny,Modus Coffee,-11.40,
2026-10-31,Allowance Sunny,Compass Mulla Mulla (camp coffee),-5.70,
2026-11-05,Allowance Sunny,McDonald's South Hedland Square,-6.65,
2026-11-06,Allowance Sunny,McDonald's South Hedland Square,-6.65,
2026-10-15,Allowance Drashti,Hungry Jack's Bentley Plaza,-5.40,
2026-10-15,Allowance Drashti,Just Coconut Cannington,-9.90,
2026-10-17,Allowance Drashti,McDonald's Ascot,-15.60,
2026-10-19,Allowance Drashti,Uber Eats,-18.89,
2026-10-22,Allowance Drashti,Modus Coffee Victoria Park,-26.10,
2026-10-22,Allowance Drashti,Hungry Jack's Karawara,-5.00,
2026-10-28,Allowance Drashti,LS Kensington Cafe,-8.50,
2026-10-29,Allowance Drashti,LS Kensington Cafe,-12.70,
2026-11-02,Allowance Drashti,LS Kensington Cafe,-13.20,
2026-11-03,Allowance Drashti,Mercato Cafe Bentley (pending),-3.48,
'@

$fixtureContent | Set-Content -LiteralPath $fixtureFile -Encoding UTF8

# Import expense-log functions
. (Join-Path $dsaiRoot "tools\expense-log.ps1")

# Setup: capture leftovers output
$output = @()
$periodStart = [datetime]::ParseExact("2026-10-14", "yyyy-MM-dd", [System.Globalization.CultureInfo]::InvariantCulture)
$periodEnd = [datetime]::ParseExact("2026-11-10", "yyyy-MM-dd", [System.Globalization.CultureInfo]::InvariantCulture)
$budgetCaps = @{
    "Groceries"         = [decimal]300
    "Eating Out"        = [decimal]400
    "Allowance Sunny"   = [decimal]200
    "Allowance Drashti" = [decimal]200
}

# Override snapshot to use fixture for this test
$OriginalTestHasLiveSnapshot = $function:Test-HasLiveSnapshot
function Test-HasLiveSnapshot { $false }

function Get-Expenses {
    @(Get-CsvExpenseRows -Path $fixtureFile)
}

# Capture output
$output = Show-Leftovers -PeriodStart $periodStart -PeriodEnd $periodEnd -Caps $budgetCaps 6>&1

# Parse output and validate
$passed = $true
$summary = @()

# Expected values from prompt
$expectations = @{
    "Groceries"         = @{ spent = 346.68; remaining = -46.68 }
    "Eating Out"        = @{ spent = 664.41; remaining = -264.41 }
    "Allowance Sunny"   = @{ spent = 93.10; remaining = 106.90 }
    "Allowance Drashti" = @{ spent = 137.88; remaining = 62.12 }
}

foreach ($category in $expectations.Keys) {
    $expected = $expectations[$category]
    
    # Find the line with this category in the output
    $line = $output | Where-Object { $_ -match "^$category:" }
    
    if ($line) {
        # Extract spent and remaining values
        if ($line -match "spent\s+([\d\.]+).*remaining\s+([-\d\.]+)") {
            $spent = [decimal]$matches[1]
            $remaining = [decimal]$matches[2]
            
            $spentOk = [Math]::Abs($spent - $expected.spent) -lt 0.01
            $remainingOk = [Math]::Abs($remaining - $expected.remaining) -lt 0.01
            
            if ($spentOk -and $remainingOk) {
                $summary += "✓ $category"
            }
            else {
                $summary += "✗ $category - Expected: spent $($expected.spent), remaining $($expected.remaining); Got: spent $spent, remaining $remaining"
                $passed = $false
            }
        }
        else {
            $summary += "✗ $category - Could not parse output: $line"
            $passed = $false
        }
    }
    else {
        $summary += "✗ $category - Not found in output"
        $passed = $false
    }
}

# Clean up
Remove-Item -LiteralPath $fixtureFile -Force

# Report results
Write-Host ""
Write-Host "=== Leftovers Test Results ==="
$summary | ForEach-Object { Write-Host $_ }
Write-Host ""

if ($passed) {
    Write-Host "✓ All tests passed"
    exit 0
}
else {
    Write-Host "✗ Some tests failed"
    exit 1
}
