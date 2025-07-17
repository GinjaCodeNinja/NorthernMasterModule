[CmdletBinding()]
Param(
    
    [Parameter(Mandatory = $true)]
    [string]$PnPSharePointClientId,
    [string]$AdminUrl,
    [string]$siteUrl,
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

. "$PSScriptRoot\..\private\HelperFunctions.ps1"
. "$PSScriptRoot\..\public\Get-FileSharingLinks.ps1"

#Region Variables
[datetime]$CurrentDateTime = (Get-Date).DateTime
[string]$TimeStamp = Get-Date -Format "yyyy-MM-dd"
[string]$ReportOutput = "$PSScriptRoot\SharingLinks_Report_$TimeStamp.csv"
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
    CurrentDateTime        = $CurrentDateTIme
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

#Region Get Admin Connection$
if(-not $adminUrl){

    while(-not $adminUrl){

        Write-Host -ForegroundColor  Blue "Please enter the SharePoint Admin Url for the tenant"
        # Write-Host -ForegroundColor Blue "Please enter the SharePoint admin Url for the tenant"
        $adminUrl = Read-Host 
    }
}

Write-Host -ForegroundColor  Yellow "Connecting to the SharePoint Admin site: " -NoNewLine
# Write-Host -ForegroundColor Yellow "Connecting to the SharePoint Admin site: " -NoNewline
$adminConnection = Connect-ToAdminSharePointSite -SiteUrl $AdminUrl -ClientId $PnPSharePointClientId

if($adminConnection){

    Write-Host -ForegroundColor  Green "Success!"
    $fileSharingSplat.adminConnection = $adminConnection
    # Write-Host -ForegroundColor Green "Success!"
}

if(-not $AllSites){

    if(-not $SiteUrl){

        Add-LineBreak
        Write-Host -ForegroundColor  White "Please enter the site URL you would like to build a 'Sharing Links' report on: "
        # Write-Host -ForegroundColor White "Please enter the site URL you would like to build a sharing links report on:"
        Add-LineBreak
        $SiteUrl = Read-Host

        $fileSharingSplat.Add("SiteUrl", $SiteUrl)
    }

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
