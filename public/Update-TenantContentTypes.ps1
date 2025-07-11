[array]$tenantConfig = Import-PowerShellDataFile -Path "$PSScriptRoot\..\tenant.psd1"
[string]$tenant = $tenantConfig.Tenant
[string]$clientId = $tenantConfig.ClientId
[string]$scriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition
[string]$privateDirectory = Join-Path $scriptDirectory "..\private"

& $privateDirectory\invokeWithRetry.ps1

$connection = Connect-PnPOnline -ClientId $clientId -Url "https://$($tenant).sharepoint.com/sites/ContentTypeHub" -Interactive -ReturnConnection

# Get the "Document Set" content types
$contentTypes = Get-PnPContentType -Connection $connection | Where-Object { $_.Id.StringValue.StartsWith("0x0120D520") }

foreach ($contentType in $contentTypes) {

    $currentValue = "❌"
    if($contentType.NewFormClientSideComponentId.Length -eq '') {

        $currentValue = "✅"
    }
    Write-Host "[$($contentTypes.IndexOf($contentType)+1)] $($contentType.name) $($currentValue)"
}

$contentTypeIndex = Read-Host -Prompt "Which content type to you wish to modernize"

# Null out the NewFormClientSideComponentId as that seems to bring it to modern UI
$contentTypes[$contentTypeIndex - 1].NewFormClientSideComponentId = $null;
$contentTypes[$contentTypeIndex - 1].Update($false);

Invoke-PnPQuery

$toPublish = Read-Host -Prompt "Content Type $($contentTypes[$contentTypeIndex-1].Name) updated. Would you like to publish the change? (Y/N)"
if ($toPublish.ToUpper() -eq 'Y') {

    # Publish the changed content type
    Write-Host -ForegroundColor Yellow "Publishing content type $($contentTypes[$contentTypeIndex-1].Name) with ID $($contentTypes[$contentTypeIndex-1].Id)"
    Publish-PnPContentType -ContentType $contentTypes[$contentTypeIndex - 1].Id -Connection $connection
}
else {

    Write-Host -ForegroundColor Red "Exiting without publishing changes."
    exit
}

Write-Host -ForegroundColor Green "All done"