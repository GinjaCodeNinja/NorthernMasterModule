# Northern Computer Master Module
# PowerShell module for SharePoint and Teams automation

# Get the module path
$ModulePath = $PSScriptRoot

# Load tenant configuration
$TenantConfigPath = Join-Path $ModulePath 'tenant.psd1'
if (Test-Path $TenantConfigPath) {
    $TenantConfig = Import-PowerShellDataFile -Path $TenantConfigPath
    
    # Make tenant configuration available to all module functions
    $script:Tenant = $TenantConfig.Tenant
    $script:ClientId = $TenantConfig.ClientId
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
Export-ModuleMember -Variable @('Tenant', 'ClientId')

# Module initialization message
Write-Host "Northern Computer Master Module loaded successfully!" -ForegroundColor Green
Write-Host "Tenant: $script:Tenant" -ForegroundColor Cyan
Write-Host "Available functions: $(($PublicFunctions | Measure-Object).Count)" -ForegroundColor Cyan
