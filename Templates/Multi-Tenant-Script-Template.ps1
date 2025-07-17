# Template: Multi-Tenant Script with Option 3 Approach
# This template shows how to implement Option 3 (script parameter approach) in your scripts

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $false)]
    [string]$TenantName,
    
    # Add your script-specific parameters here
    [string]$SiteUrl,
    [switch]$SomeSwitch
)

# Import required helper functions
. "$PSScriptRoot\..\private\HelperFunctions.ps1"

# Get tenant configuration using the helper function
$tenantConfig = Get-TenantConfig -TenantName $TenantName

if (-not $tenantConfig) {
    Write-Error "Failed to retrieve tenant configuration for '$TenantName'"
    exit 1
}

# Display configuration being used
Write-Host "Using tenant configuration:" -ForegroundColor Cyan
Write-Host "  Tenant: $($tenantConfig.TenantName)" -ForegroundColor White
Write-Host "  ClientId: $($tenantConfig.ClientId)" -ForegroundColor White
Write-Host "  AdminUrl: $($tenantConfig.AdminUrl)" -ForegroundColor White

# Use the configuration in your script
try {
    # Example: Connect to SharePoint Admin
    $adminConnection = Connect-PnPOnline -Url $tenantConfig.AdminUrl -ClientId $tenantConfig.ClientId -Interactive -ReturnConnection
    
    # Example: Connect to a specific site
    if ($SiteUrl) {
        $siteConnection = Connect-PnPOnline -Url $SiteUrl -ClientId $tenantConfig.ClientId -Interactive -ReturnConnection
    }
    
    # Your script logic here
    Write-Host "Script execution completed successfully for tenant: $($tenantConfig.TenantName)" -ForegroundColor Green
    
}
catch {
    Write-Error "Script failed: $_"
    exit 1
}
finally {
    # Cleanup connections if needed
    if ($adminConnection) {
        Disconnect-PnPOnline -Connection $adminConnection
    }
    if ($siteConnection) {
        Disconnect-PnPOnline -Connection $siteConnection
    }
}

# Usage Examples:
# .\Your-Script.ps1                                    # Uses default tenant
# .\Your-Script.ps1 -TenantName "northerncomputer"     # Uses specific tenant
# .\Your-Script.ps1 -TenantName "contoso"              # Uses different tenant
