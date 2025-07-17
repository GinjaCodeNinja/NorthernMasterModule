[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [string]$TenantName,
    [string]$SiteUrl,
    [switch]$AllSites,
    [switch]$ExcludeSites,
    [switch]$ActiveLinks,
    [switch]$ExpiredLinks,
    [switch]$LinksWithExpiration,
    [switch]$NeverExpiresLinks,
    [switch]$GetAnyoneLinks,
    [switch]$GetCompanyLinks,
    [switch]$GetSpecificPeopleLinks,
    [int]$SoonToExpireInDays
)

# Load tenant configuration manually
$TenantConfigPath = "$PSScriptRoot\..\tenant.psd1"
if (Test-Path $TenantConfigPath) {
    $TenantConfig = Import-PowerShellDataFile -Path $TenantConfigPath
    $script:Tenant = $TenantConfig.Tenant
    $script:ClientId = $TenantConfig.ClientId
    $script:Tenants = $TenantConfig.Tenants
} else {
    Write-Error "Tenant configuration file not found at: $TenantConfigPath"
    exit 1
}

# Dot-source required functions
. "$PSScriptRoot\..\private\Get-TenantConfig.ps1"
. "$PSScriptRoot\..\private\HelperFunctions.ps1"
. "$PSScriptRoot\..\public\Get-FileSharingLinks.ps1"


#Region Get Tenant Configuration
# Get tenant configuration using the helper function
$tenantConfig = Get-TenantConfig -TenantName $TenantName

if (-not $tenantConfig) {
    Write-Error "Failed to retrieve tenant configuration for '$TenantName'"
    exit 1
}

# Debug: Check if ClientId is empty
if (-not $tenantConfig.ClientId -or $tenantConfig.ClientId -eq "") {
    Write-Error "ClientId is empty or null for tenant '$TenantName'. Please check your tenant.psd1 configuration."
    Write-Host "Available tenants: $($script:Tenants.Keys -join ', ')" -ForegroundColor Yellow
    exit 1
}

Write-Host "Using tenant configuration:" -ForegroundColor Cyan
Write-Host "  Tenant: $($tenantConfig.TenantName)" -ForegroundColor White
Write-Host "  ClientId: $($tenantConfig.ClientId)" -ForegroundColor White
Write-Host "  AdminUrl: $($tenantConfig.AdminUrl)" -ForegroundColor White
#EndRegion

#Region Variables
[datetime]$CurrentDateTime = (Get-Date).DateTime
[string]$TimeStamp = Get-Date -Format "yyyy-MM-dd"
[string]$ReportOutput = "C:\Temp\SharingLinksReport_$($tenantConfig.TenantName)_$TimeStamp.csv"
[array]$Modules = @("PnP.PowerShell")
[hashtable]$fileSharingSplat = @{

    ActiveLinks            = $ActiveLinks
    ExpiredLinks           = $ExpiredLinks
    LinksWithExpiration    = $LinksWithExpiration
    NeverExpiresLinks      = $NeverExpiresLinks
    GetAnyoneLinks         = $GetAnyoneLinks
    GetCompanyLinks        = $GetCompanyLinks
    GetSpecificPeopleLinks = $GetSpecificPeopleLinks
    ReportOutput           = $ReportOutput
    CurrentDateTime        = $CurrentDateTime
}
#EndRegion

#Region Check for Required Modules
$isInstalled = Invoke-WithRetry -Message "Checking for required modules" -ScriptBlock {

    Test-ModulesAdded -Modules $Modules
    Return $true

}
if(-not $isInstalled) {
    Write-Host -ForegroundColor  Red "Required modules are not installed. Exiting script"
    # Write-Host -ForegroundColor Red "Required modules are not installed. Exiting script."
    Start-ExitTimer
}
#EndRegion

#Region Get Admin Connection
Write-Host -ForegroundColor Yellow "Connecting to the SharePoint Admin site: $($tenantConfig.AdminUrl)" -NoNewLine
$adminConnection = Connect-ToAdminSharePointSite -SiteUrl $tenantConfig.AdminUrl -ClientId $tenantConfig.ClientId

if($adminConnection){
    Write-Host -ForegroundColor Green "Success!"
    $fileSharingSplat.adminConnection = $adminConnection
}
else {
    Write-Host -ForegroundColor Red "Failed to connect to admin site"
    exit 1
}
#EndRegion

if(-not $AllSites){

    if(-not $SiteUrl){

        Add-LineBreak
        Write-Host -ForegroundColor  White "Please enter the site URL you would like to build a 'Sharing Links' report on: "
        # Write-Host -ForegroundColor White "Please enter the site URL you would like to build a sharing links report on:"
        Add-LineBreak
        $SiteUrl = Read-Host
    }

    # Add the SiteUrl to the splat (whether provided as parameter or entered manually)
    $fileSharingSplat.Add("SiteUrl", $SiteUrl)

    Write-Host -ForegroundColor  Blue "Processing site at URL: $SiteUrl"
    Write-Host -ForegroundColor  Blue "----------------------------------------------------"
    # Write-Host -ForegroundColor Blue "Processing site at URL: $SiteUrl"
    # Write-Host -ForegroundColor Blue "-------------------------------------------"

    # Invoke-WithRetry -ScriptBlock {

    #         Add-LineBreak
    #     # Write-Host -ForegroundColor  White "Status: " -NoNewLine
    #     # $siteConnection = Connect-ToSharePointSite -SiteUrl $SiteUrl -Connection $adminConnection

    #     # if($siteConnection){

    #     #     Write-Host -ForegroundColor  Green "Success!"
    #         $fileSharingSplat.Connection = $siteConnection
    #     }

        Get-SharedLinks @fileSharingSplat

        Add-LineBreak
} 
else {

    Write-Host -ForegroundColor  Blue "Processing all SharePoint Sites for 'Sharing Links'"
    Write-Host -ForegroundColor  Blue "-------------------------------------------------------"
    # Write-Host -ForegroundColor Blue "Processing all SharePoint Sites for Sharing Links"
    # Write-Host -ForegroundColor Blue "-------------------------------------------"

    Add-LineBreak
    if(-not $ExcludeSites){

        $siteCollections = Get-PnPTenantSite

        foreach($site in $siteCollections){

            $fileSharingSplat.Remove("SiteUrl") | Out-Null

            # Invoke-WithRetry -Message "Connecting to $($site.Title): "
            # $siteConnection = Connect-ToSharePointSite -SiteUrl $site.Url -Connection $adminConnection

            $fileSharingSplat.Add("SiteUrl", $site.Url)

            Get-SharedLinks @fileSharingSplat
        }
    }
}
