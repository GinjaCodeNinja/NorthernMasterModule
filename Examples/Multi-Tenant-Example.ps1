# Example: Using Multi-Tenant Configuration in Scripts
# This script demonstrates how to use the multi-tenant configuration

# Import the module
Import-Module "$PSScriptRoot\..\NorthernMasterModule.psd1"

# Example 1: Using the default tenant
Write-Host "=== Default Tenant Example ===" -ForegroundColor Yellow
$defaultConfig = Get-TenantConfig
Write-Host "Default Tenant: $($defaultConfig.TenantName)" -ForegroundColor Green
Write-Host "Default ClientId: $($defaultConfig.ClientId)" -ForegroundColor Green
Write-Host "Default AdminUrl: $($defaultConfig.AdminUrl)" -ForegroundColor Green

# Example 2: Using a specific tenant
Write-Host "`n=== Specific Tenant Example ===" -ForegroundColor Yellow
$tenantName = "northerncomputer"
$tenantConfig = Get-TenantConfig -TenantName $tenantName
Write-Host "Tenant: $($tenantConfig.TenantName)" -ForegroundColor Green
Write-Host "ClientId: $($tenantConfig.ClientId)" -ForegroundColor Green
Write-Host "AdminUrl: $($tenantConfig.AdminUrl)" -ForegroundColor Green

# Example 3: Dynamic tenant selection
Write-Host "`n=== Dynamic Tenant Selection Example ===" -ForegroundColor Yellow
$availableTenants = $script:Tenants.Keys
Write-Host "Available Tenants: $($availableTenants -join ', ')" -ForegroundColor Cyan

foreach ($tenant in $availableTenants) {
    $config = Get-TenantConfig -TenantName $tenant
    Write-Host "Tenant: $tenant" -ForegroundColor Green
    Write-Host "  ClientId: $($config.ClientId)" -ForegroundColor White
    Write-Host "  AdminUrl: $($config.AdminUrl)" -ForegroundColor White
}

# Example 4: Using in a script with parameter
Write-Host "`n=== Script Parameter Example ===" -ForegroundColor Yellow
function Connect-ToTenant {
    param(
        [string]$TenantName = $script:Tenant
    )
    
    $config = Get-TenantConfig -TenantName $TenantName
    Write-Host "Connecting to tenant: $($config.TenantName)" -ForegroundColor Green
    Write-Host "Using ClientId: $($config.ClientId)" -ForegroundColor Green
    Write-Host "Admin URL: $($config.AdminUrl)" -ForegroundColor Green
    
    # Here you would use the config to connect
    # $connection = Connect-PnPOnline -Url $config.AdminUrl -ClientId $config.ClientId -Interactive
}

# Test with different tenants
Connect-ToTenant -TenantName "northerncomputer"
