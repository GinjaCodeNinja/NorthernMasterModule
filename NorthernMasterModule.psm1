# Northern Computer Master Module
# PowerShell module for SharePoint and Teams automation

# Get the module path
$ModulePath = $PSScriptRoot

# Load tenant configuration
$TenantConfigPath = Join-Path $ModulePath 'tenant.psd1'
Write-Verbose "Looking for tenant configuration at: $TenantConfigPath"
if (Test-Path $TenantConfigPath) {
    Write-Verbose "Found tenant configuration file, loading..."
    $TenantConfig = Import-PowerShellDataFile -Path $TenantConfigPath
    
    # Make tenant configuration available to all module functions
    $script:Tenant = $TenantConfig.Tenant
    $script:ClientId = $TenantConfig.ClientId
    
    # Multi-tenant configuration support
    # Access via $script:Tenants.<companyName>.ClientId
    $script:Tenants = $TenantConfig.Tenants
    
    Write-Verbose "Loaded tenant configuration: Tenant='$script:Tenant', ClientId='$script:ClientId'"
    Write-Verbose "Available tenants: $($script:Tenants.Keys -join ', ')"
} else {
    Write-Warning "Tenant configuration file not found at: $TenantConfigPath"
}

# Load private functions (helpers)
$PrivateFunctions = Get-ChildItem -Path (Join-Path $ModulePath 'private') -Filter '*.ps1' -ErrorAction SilentlyContinue
foreach ($Function in $PrivateFunctions) {
    try {
        . $Function.FullName
        Write-Verbose "Loaded private function: $($Function.BaseName)"
    }
    catch {
        Write-Error "Failed to load private function $($Function.BaseName): $_"
    }
}

# Load classes
$Classes = Get-ChildItem -Path (Join-Path $ModulePath 'classes') -Filter '*.ps1' -ErrorAction SilentlyContinue
foreach ($Class in $Classes) {
    try {
        . $Class.FullName
        Write-Verbose "Loaded class: $($Class.BaseName)"
    }
    catch {
        Write-Error "Failed to load class $($Class.BaseName): $_"
    }
}

# Load public functions
$PublicFunctions = Get-ChildItem -Path (Join-Path $ModulePath 'public') -Filter '*.ps1' -ErrorAction SilentlyContinue
foreach ($Function in $PublicFunctions) {
    try {
        . $Function.FullName
        Write-Verbose "Loaded public function: $($Function.BaseName)"
    }
    catch {
        Write-Error "Failed to load public function $($Function.BaseName): $_"
    }
}

# Export module variables for backward compatibility
Export-ModuleMember -Variable @('Tenant', 'ClientId', 'Tenants')

# Module initialization message
Write-Host "Northern Computer Master Module loaded successfully!" -ForegroundColor Green
Write-Host "Default Tenant: $script:Tenant" -ForegroundColor Cyan
Write-Host "Available Tenants: $($script:Tenants.Keys -join ', ')" -ForegroundColor Cyan
Write-Host "Available functions: $(($PublicFunctions | Measure-Object).Count)" -ForegroundColor Cyan
