# Test script for Export-SiteSharingLinks.ps1
param(
    [string]$TenantName = "northerncomputer"
)

Write-Host "=== Testing Export-SiteSharingLinks.ps1 ===" -ForegroundColor Yellow

# Test the script directly
try {
    Write-Host "Running Export-SiteSharingLinks.ps1 with TenantName: $TenantName" -ForegroundColor Cyan
    
    # Run the script with minimal parameters to test tenant configuration loading
    & "$PSScriptRoot\..\scripts\Export-SiteSharingLinks.ps1" -TenantName $TenantName -ActiveLinks
    
    Write-Host "SUCCESS: Script ran without errors" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Script failed with error: $_" -ForegroundColor Red
    Write-Host "Full error details:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}
