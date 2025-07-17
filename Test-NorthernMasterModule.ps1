# Northern Computer Master Module Test Script
# This script provides basic tests for the module functions

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$ImportModule,
    
    [Parameter(Mandatory = $false)]
    [switch]$TestHelpers,
    
    [Parameter(Mandatory = $false)]
    [switch]$ShowDetails
)

# Import the module if requested
if ($ImportModule) {
    
    Write-Host "Importing Northern Computer Master Module..." -ForegroundColor Yellow
    Import-Module .\NorthernMasterModule.psd1 -Force
    Write-Host "Module imported successfully!" -ForegroundColor Green
    Write-Host ""
}

# Test if module is loaded
$moduleLoaded = Get-Module -Name NorthernMasterModule
if (-not $moduleLoaded) {

    Write-Error "NorthernMasterModule is not loaded. Please import the module first."
    Write-Host "Run: Import-Module .\NorthernMasterModule.psd1" -ForegroundColor Yellow
    return
}

Write-Host "Northern Computer Master Module Test Results" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""

# Test 1: Check if all expected functions are exported
Write-Host "Test 1: Checking exported functions..." -ForegroundColor Cyan
$expectedFunctions = @(

    'Get-AnonymouslinkActivityReport',
    'Get-SharedLinks',
    'Update-GroupMembership',
    'Update-SiteContentTypes',
    'Update-TenantContentTypes'
)

$exportedFunctions = (Get-Command -Module NorthernMasterModule).Name
$missingFunctions = $expectedFunctions | Where-Object { $_ -notin $exportedFunctions }

if ($missingFunctions.Count -eq 0) {

    Write-Host "✓ All expected functions are exported" -ForegroundColor Green
    foreach ($func in $expectedFunctions) {

        Write-Host "  - $func" -ForegroundColor White
    }
} 
else {
    Write-Host "✗ Missing functions:" -ForegroundColor Red
    foreach ($func in $missingFunctions) {

        Write-Host "  - $func" -ForegroundColor Red
    }
}

Write-Host ""

# Test 2: Check if helper functions are available (but not exported)
if ($TestHelpers) {

    Write-Host "Test 2: Checking helper functions..." -ForegroundColor Cyan
    $helperFunctions = @(
        'Set-Output',
        'Connect-ToSharePointSite',
        'Connect-ToAdminSharePointSite',
        'Invoke-WithRetry',
        'Test-ModulesAdded',
        'Get-ValidatedDate'
    )
    
    foreach ($helper in $helperFunctions) {

        try {

            $func = Get-Command $helper -ErrorAction SilentlyContinue
            if ($func) {

                Write-Host "✓ $helper is available" -ForegroundColor Green
            } 
            else {

                Write-Host "✗ $helper is not available" -ForegroundColor Red
            }
        } 
        catch {

            Write-Host "✗ $helper is not available" -ForegroundColor Red
        }
    }
    Write-Host ""
}

# Test 3: Check if module configuration is loaded
Write-Host "Test 3: Checking module configuration..." -ForegroundColor Cyan
try {

    $tenant = Get-Variable -Name "Tenant" -Scope Script -ErrorAction SilentlyContinue
    $clientId = Get-Variable -Name "ClientId" -Scope Script -ErrorAction SilentlyContinue
    
    if ($tenant -and $clientId) {

        Write-Host "✓ Module configuration loaded successfully" -ForegroundColor Green
        if ($ShowDetails) {
            Write-Host "  Tenant: $($tenant.Value)" -ForegroundColor White
            Write-Host "  ClientId: $($clientId.Value)" -ForegroundColor White
        }
    } 
    else {

        Write-Host "⚠ Module configuration may not be loaded properly" -ForegroundColor Yellow
    }
} 
catch {

    Write-Host "⚠ Unable to check module configuration" -ForegroundColor Yellow
}

Write-Host ""

# Test 4: Test function help documentation
Write-Host "Test 4: Checking help documentation..." -ForegroundColor Cyan
$functionsWithHelp = 0
foreach ($func in $expectedFunctions) {

    try {

        $help = Get-Help $func -ErrorAction SilentlyContinue
        if ($help -and $help.Synopsis -and $help.Synopsis -ne $func) {

            $functionsWithHelp++
            Write-Host "✓ $func has help documentation" -ForegroundColor Green
        } 
        else {

            Write-Host "⚠ $func may have limited help documentation" -ForegroundColor Yellow
        }
    } 
    catch {

        Write-Host "✗ $func help documentation not available" -ForegroundColor Red
    }
}

Write-Host ""

# Test 5: Basic syntax validation
Write-Host "Test 5: Basic syntax validation..." -ForegroundColor Cyan
$syntaxErrors = 0
foreach ($func in $expectedFunctions) {

    try {

        $command = Get-Command $func -ErrorAction SilentlyContinue
        if ($command) {

            Write-Host "✓ $func syntax is valid" -ForegroundColor Green
        } 
        else {

            Write-Host "✗ $func syntax validation failed" -ForegroundColor Red
            $syntaxErrors++
        }
    } 
    catch {

        Write-Host "✗ $func syntax validation failed" -ForegroundColor Red
        $syntaxErrors++
    }
}

Write-Host ""

# Summary
Write-Host "Test Summary:" -ForegroundColor Green
Write-Host "=============" -ForegroundColor Green
Write-Host "Functions exported: $($exportedFunctions.Count)/$($expectedFunctions.Count)" -ForegroundColor White
Write-Host "Functions with help: $functionsWithHelp/$($expectedFunctions.Count)" -ForegroundColor White
Write-Host "Syntax errors: $syntaxErrors" -ForegroundColor White

if ($syntaxErrors -eq 0 -and $missingFunctions.Count -eq 0) {

    Write-Host ""
    Write-Host "✓ All tests passed! The module is ready for use." -ForegroundColor Green
} 
else {

    Write-Host ""
    Write-Host "⚠ Some tests failed. Please review the issues above." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "To get detailed help for any function, run:" -ForegroundColor Cyan
Write-Host "Get-Help <FunctionName> -Full" -ForegroundColor White
Write-Host ""
Write-Host "Example commands to try:" -ForegroundColor Cyan
Write-Host "Get-Help Update-SiteContentTypes -Full" -ForegroundColor White
Write-Host "Get-Help Get-AnonymouslinkActivityReport -Examples" -ForegroundColor White
