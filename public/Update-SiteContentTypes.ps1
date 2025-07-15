. $PSScriptRoot\..\..\private\ConnectToSharePointSite.ps1
. $PSScriptRoot\..\..\private\InvokeWithRetry.ps1

$siteUrl = Read-Host -Prompt "Enter your site url (e.g https://<tenant>.sharepoint.com/sites/contoso)";
$connection = Connect-ToSharePointSite -SiteUrl $siteUrl
$lists = Get-PnPList -Connection $connection | Where-Object {$_.BaseTemplate -eq 101}

foreach($list in $lists){

    Write-Host "[$($lists.IndexOf($list)+1)] $($list.Title)"
}

$index = Read-Host -Prompt "Which list do you wish to modernize your content type?"

# Get the "Folder" content types on the document library
$contentTypes = Get-PnPContentType -List $($lists[$index-1]) -Connection $connection | Where-Object {$_.Id.StringValue.StartsWith("0x0120")}

foreach($contentType in $contentTypes){
    Write-Host "[$($contentTypes.IndexOf($contentType)+1)] $($contentType.name)"
}

$contentTypesIndex = Read-Host -Prompt "Which content type to you wish to modernize?"

# Null out the NewFormClientSideComponentId as that seems to bring it to modern UI
$contentTypes[$contentTypesIndex-1].NewFormClientSideComponentId = $null;
$contentTypes[$contentTypesIndex-1].Update($false);

Invoke-PnPQuery

Write-Host -ForegroundColor Green "ContentType Updated!"