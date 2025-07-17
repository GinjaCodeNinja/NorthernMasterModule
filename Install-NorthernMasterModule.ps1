# Northern Computer Master Module Installation Script
# This script helps install and configure the Northern Computer Master Module

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$InstallPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$CurrentUser,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to get PowerShell module paths
function Get-PSModulePath {
    if ($CurrentUser) {
        $userModulePath = Join-Path $env:USERPROFILE "Documents\PowerShell\Modules"
        if (!(Test-Path $userModulePath)) {
            $userModulePath = Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\Modules"
        }
        return $userModulePath
    }
    else {
        if (Test-Administrator) {
            return "$env:ProgramFiles\PowerShell\Modules"
        }
        else {
            Write-Warning "System-wide installation requires administrator privileges. Using current user path instead."
            return Get-PSModulePath -CurrentUser
        }
    }
}

try {
    Write-Host "Northern Computer Master Module Installation" -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host ""
    
    # Get the current script location
    $ScriptPath = $PSScriptRoot
    Write-Host "Module source: $ScriptPath" -ForegroundColor Cyan
    
    # Determine installation path
    if (-not $InstallPath) {
        $InstallPath = Get-PSModulePath
    }
    
    $ModuleDestination = Join-Path $InstallPath "NorthernMasterModule"
    Write-Host "Installation destination: $ModuleDestination" -ForegroundColor Cyan
    
    # Check if destination already exists
    if (Test-Path $ModuleDestination) {
        if ($Force) {
            Write-Host "Removing existing module installation..." -ForegroundColor Yellow
            Remove-Item -Path $ModuleDestination -Recurse -Force
        }
        else {
            $response = Read-Host "Module already exists at $ModuleDestination. Overwrite? (Y/N)"
            if ($response.ToUpper() -ne 'Y') {
                Write-Host "Installation cancelled by user." -ForegroundColor Red
                return
            }
            Remove-Item -Path $ModuleDestination -Recurse -Force
        }
    }
    
    # Create destination directory if it doesn't exist
    if (!(Test-Path $InstallPath)) {
        Write-Host "Creating module directory: $InstallPath" -ForegroundColor Yellow
        New-Item -Path $InstallPath -ItemType Directory -Force | Out-Null
    }
    
    # Copy module files
    Write-Host "Copying module files..." -ForegroundColor Yellow
    Copy-Item -Path $ScriptPath -Destination $ModuleDestination -Recurse -Force
    
    # Remove installation script from destination
    $installerPath = Join-Path $ModuleDestination "Install-NorthernMasterModule.ps1"
    if (Test-Path $installerPath) {
        Remove-Item -Path $installerPath -Force
    }
    
    # Test module installation
    Write-Host "Testing module installation..." -ForegroundColor Yellow
    $moduleTest = Test-ModuleManifest -Path (Join-Path $ModuleDestination "NorthernMasterModule.psd1")
    
    if ($moduleTest) {
        Write-Host "Module installation successful!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Module Information:" -ForegroundColor Cyan
        Write-Host "  Name: $($moduleTest.Name)" -ForegroundColor White
        Write-Host "  Version: $($moduleTest.Version)" -ForegroundColor White
        Write-Host "  Author: $($moduleTest.Author)" -ForegroundColor White
        Write-Host "  Functions: $($moduleTest.ExportedFunctions.Keys.Count)" -ForegroundColor White
        Write-Host ""
        
        # Display exported functions
        Write-Host "Available Functions:" -ForegroundColor Cyan
        foreach ($func in $moduleTest.ExportedFunctions.Keys) {
            Write-Host "  - $func" -ForegroundColor White
        }
        
        Write-Host ""
        Write-Host "To use the module, run:" -ForegroundColor Yellow
        Write-Host "  Import-Module NorthernMasterModule" -ForegroundColor Green
        Write-Host ""
        Write-Host "For help with a specific function, run:" -ForegroundColor Yellow
        Write-Host "  Get-Help <FunctionName> -Full" -ForegroundColor Green
        Write-Host ""
        Write-Host "Example:" -ForegroundColor Yellow
        Write-Host "  Get-Help Update-SiteContentTypes -Full" -ForegroundColor Green
        
        # Try to import the module
        Write-Host ""
        $importTest = Read-Host "Would you like to import the module now? (Y/N)"
        if ($importTest.ToUpper() -eq 'Y') {
            Write-Host "Importing module..." -ForegroundColor Yellow
            Import-Module NorthernMasterModule -Force
            Write-Host "Module imported successfully!" -ForegroundColor Green
        }
    }
    else {
        Write-Error "Module installation failed. Please check the installation path and try again."
    }
}
catch {
    Write-Error "An error occurred during installation: $($_.Exception.Message)"
    Write-Error "Please check the installation path and permissions, then try again."
}
