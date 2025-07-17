# Debug script to test tenant configuration
param(
    [string]$TenantName = "northerncomputer"
)

# Import the module
Import-Module "$PSScriptRoot\..\NorthernMasterModule.psd1" -Force -Verbose

Write-Host "=== Module Variables ===" -ForegroundColor Yellow
Write-Host "script:Tenant: '$script:Tenant'" -ForegroundColor White
Write-Host "script:ClientId: '$script:ClientId'" -ForegroundColor White
Write-Host "script:Tenants: $($script:Tenants.Keys -join ', ')" -ForegroundColor White

Write-Host "`n=== Testing Get-TenantConfig ===" -ForegroundColor Yellow
$config = Get-TenantConfig -TenantName $TenantName -Verbose

Write-Host "`n=== Configuration Result ===" -ForegroundColor Yellow
Write-Host "TenantName: '$($config.TenantName)'" -ForegroundColor White
Write-Host "ClientId: '$($config.ClientId)'" -ForegroundColor White
Write-Host "AdminUrl: '$($config.AdminUrl)'" -ForegroundColor White

Write-Host "`n=== Checking ClientId ===" -ForegroundColor Yellow
if (-not $config.ClientId -or $config.ClientId -eq "") {
    Write-Host "ERROR: ClientId is empty!" -ForegroundColor Red
} else {
    Write-Host "SUCCESS: ClientId is not empty" -ForegroundColor Green
}
