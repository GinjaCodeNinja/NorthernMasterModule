function Get-TenantConfig {
    <#
    .SYNOPSIS
        Retrieves tenant configuration for the specified tenant.
    
    .DESCRIPTION
        Helper function to retrieve tenant configuration from the multi-tenant configuration.
        Falls back to default tenant configuration if specific tenant is not found.
        Dynamically constructs AdminUrl based on TenantName.
    
    .PARAMETER TenantName
        The name of the tenant to retrieve configuration for.
    
    .EXAMPLE
        $config = Get-TenantConfig -TenantName "contoso"
        $clientId = $config.ClientId
        $adminUrl = $config.AdminUrl
    
    .EXAMPLE
        # Use default tenant
        $config = Get-TenantConfig
        $clientId = $config.ClientId
    #>
    [CmdletBinding()]
    param(
        [string]$TenantName
    )
    
    try {
        # Debug: Check if script variables are available
        Write-Verbose "Script variables - Tenant: '$script:Tenant', ClientId: '$script:ClientId'"
        Write-Verbose "Available tenants: $($script:Tenants.Keys -join ', ')"
        
        # If no tenant name specified, use default
        if (-not $TenantName) {
            Write-Verbose "Using default tenant configuration"
            return @{
                TenantName = $script:Tenant
                ClientId = $script:ClientId
                AdminUrl = "https://$script:Tenant-admin.sharepoint.com"
            }
        }
        
        # Check if multi-tenant configuration exists
        if ($script:Tenants -and $script:Tenants.ContainsKey($TenantName)) {
            Write-Verbose "Found tenant '$TenantName' in multi-tenant configuration"
            $tenantConfig = $script:Tenants[$TenantName]
            Write-Verbose "Tenant config - TenantName: '$($tenantConfig.TenantName)', ClientId: '$($tenantConfig.ClientId)'"
            return @{
                TenantName = $tenantConfig.TenantName
                ClientId = $tenantConfig.ClientId
                AdminUrl = "https://$($tenantConfig.TenantName)-admin.sharepoint.com"
            }
        }
        
        # If tenant not found in multi-tenant config, check if it matches default
        if ($TenantName -eq $script:Tenant) {
            return @{
                TenantName = $script:Tenant
                ClientId = $script:ClientId
                AdminUrl = "https://$script:Tenant-admin.sharepoint.com"
            }
        }
        
        # Tenant not found
        throw "Tenant '$TenantName' not found in configuration. Available tenants: $($script:Tenants.Keys -join ', ')"
    }
    catch {
        Write-Error "Failed to retrieve tenant configuration for '$TenantName': $_"
        return $null
    }
}
