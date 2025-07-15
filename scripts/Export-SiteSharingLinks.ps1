[CmdletBinding()]
Param(
    
    [Parameter(Mandatory = $true)]
    [string]$PnPSharePointClientId,
    [string]$AdminUrl,
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
    Set-Output Red "Required modules are not installed. Exiting script"
    # Write-Host -ForegroundColor Red "Required modules are not installed. Exiting script."
    Start-ExitTimer
}
#EndRegion

#Region Get Admin Connection$
if(-not $adminUrl){

    Set-Output Blue "Please enter the SharePoint Admin Url for the tenant"
    # Write-Host -ForegroundColor Blue "Please enter the SharePoint admin Url for the tenant"
    $adminUrl = Read-Host 
}

Set-Output Yellow "Connecting to the SharePoint Admin site: " -NoNewLineLine
# Write-Host -ForegroundColor Yellow "Connecting to the SharePoint Admin site: " -NoNewline
$adminConnection = Connect-ToAdminSharePointSite -SiteUrl $AdminUrl -ClientId $PnPSharePointClientId

if($adminConnection){

    Set-Output Green "Success!"
    # Write-Host -ForegroundColor Green "Success!"
}

if(-not $AllSites){

    if(-not $SiteUrl){

        Add-LineBreak
        Set-Output White "Please enter the site URL you would like to build a 'Sharing Links' report on: "
        # Write-Host -ForegroundColor White "Please enter the site URL you would like to build a sharing links report on:"
        Add-LineBreak
        $SiteUrl = Read-Host
    }

    Set-Output Blue "Processing site at URL: $SiteUrl"
    Set-Output Blue "----------------------------------------------------"
    # Write-Host -ForegroundColor Blue "Processing site at URL: $SiteUrl"
    # Write-Host -ForegroundColor Blue "-------------------------------------------"

    Invoke-WithRetry -ScriptBlock {

        Add-LineBreak
        Set-Output White "Status: " -NoNewLine
        $siteConnection = Connect-ToSharePointSite -SiteUrl $SiteUrl -Connection $adminConnection

        if($siteConnection){

            Set-Output Green "Success!"
            $fileSharingSplat.connection = $siteConnection
        }

        Get-FileSharingLinks @fileSharingSplat

        Add-LineBreak
    }
} 
else {

    Set-Output Blue "Processing all SharePoint Sites for 'Sharing Links'"
    Set-Output Blue "-------------------------------------------------------"
    # Write-Host -ForegroundColor Blue "Processing all SharePoint Sites for Sharing Links"
    # Write-Host -ForegroundColor Blue "-------------------------------------------"

    Add-LineBreak
    if(-not $ExcludeSites){

        $siteCollections = Get-PnPTenantSite

        foreach($site in $siteCollections){

            [object]$siteConnection = $null

            Invoke-WithRetry -Message "Connecting to $($site.Title): "
            $siteConnection = Connect-ToSharePointSite -SiteUrl $site.Url -Connection $adminConnection

            $fileSharingSplat.connection = $siteConnection

            Get-FileSharingLinks @fileSharingSplat
        }
    }
}
