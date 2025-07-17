# Direct test for Export-SiteSharingLinks.ps1 without module loading
param(
    [string]$TenantName = "northerncomputer"
)

Write-Host "=== Direct Test for Export-SiteSharingLinks.ps1 ===" -ForegroundColor Yellow

# Test 1: Check if the script file exists
$scriptPath = "$PSScriptRoot\..\scripts\Export-SiteSharingLinks.ps1"
if (Test-Path $scriptPath) {
    Write-Host "✓ Script file exists at: $scriptPath" -ForegroundColor Green
} else {
    Write-Host "✗ Script file NOT found at: $scriptPath" -ForegroundColor Red
    exit 1
}

# Test 2: Check if tenant.psd1 exists
$tenantConfigPath = "$PSScriptRoot\..\tenant.psd1"
if (Test-Path $tenantConfigPath) {
    Write-Host "✓ Tenant config file exists at: $tenantConfigPath" -ForegroundColor Green
} else {
    Write-Host "✗ Tenant config file NOT found at: $tenantConfigPath" -ForegroundColor Red
    exit 1
}

# Test 3: Check tenant configuration content
try {
    $tenantConfig = Import-PowerShellDataFile -Path $tenantConfigPath
    Write-Host "✓ Tenant config loaded successfully" -ForegroundColor Green
    Write-Host "  Default Tenant: $($tenantConfig.Tenant)" -ForegroundColor White
    Write-Host "  Default ClientId: $($tenantConfig.ClientId)" -ForegroundColor White
    Write-Host "  Available Tenants: $($tenantConfig.Tenants.Keys -join ', ')" -ForegroundColor White
    
    # Check if the requested tenant exists
    if ($tenantConfig.Tenants.ContainsKey($TenantName)) {
        $specificTenant = $tenantConfig.Tenants[$TenantName]
        Write-Host "✓ Tenant '$TenantName' found in configuration" -ForegroundColor Green
        Write-Host "  TenantName: $($specificTenant.TenantName)" -ForegroundColor White
        Write-Host "  ClientId: $($specificTenant.ClientId)" -ForegroundColor White
        
        if ($specificTenant.ClientId -and $specificTenant.ClientId -ne "") {
            Write-Host "✓ ClientId is not empty for tenant '$TenantName'" -ForegroundColor Green
        } else {
            Write-Host "✗ ClientId is empty for tenant '$TenantName'" -ForegroundColor Red
        }
    } else {
        Write-Host "✗ Tenant '$TenantName' NOT found in configuration" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Failed to load tenant config: $_" -ForegroundColor Red
    exit 1
}

# Test 4: Try to run the script with dry-run approach
Write-Host "`n=== Testing Script Execution ===" -ForegroundColor Yellow
try {
    # Since the script doesn't have a -WhatIf parameter, we'll need to modify our approach
    Write-Host "Note: Cannot do a dry run of Export-SiteSharingLinks.ps1 without connecting to SharePoint" -ForegroundColor Yellow
    Write-Host "The script should work with the tenant configuration above." -ForegroundColor Green
    
    Write-Host "`n=== Usage Example ===" -ForegroundColor Cyan
    Write-Host "To run the script:" -ForegroundColor White
    Write-Host "  .\Export-SiteSharingLinks.ps1 -TenantName '$TenantName' -ActiveLinks" -ForegroundColor White
    Write-Host "  .\Export-SiteSharingLinks.ps1 -TenantName '$TenantName' -AllSites" -ForegroundColor White
    
} catch {
    Write-Host "✗ Error during script test: $_" -ForegroundColor Red
}
