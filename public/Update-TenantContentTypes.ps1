function Update-TenantContentTypes {
    <#
    .SYNOPSIS
    Modernizes SharePoint tenant content types at the Content Type Hub
    
    .DESCRIPTION
    This function connects to the SharePoint Content Type Hub and allows you to select
    Document Set content types to modernize by nulling out the NewFormClientSideComponentId property.
    Optionally publishes the changes to make them available across the tenant.
    
    .PARAMETER Tenant
    The tenant name (without .sharepoint.com). If not provided, uses the tenant from configuration.
    
    .PARAMETER ClientId
    The client ID for authentication. If not provided, uses the client ID from configuration.
    
    .PARAMETER Connection
    An existing PnP connection object to use instead of creating a new one
    
    .PARAMETER AutoPublish
    Automatically publish changes without prompting
    
    .EXAMPLE
    Update-TenantContentTypes
    
    .EXAMPLE
    Update-TenantContentTypes -AutoPublish
    
    .EXAMPLE
    Update-TenantContentTypes -Tenant "contoso" -ClientId "12345678-90ab-cdef-1234-567890abcdef"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Tenant,
        
        [Parameter(Mandatory = $false)]
        [string]$ClientId,
        
        [Parameter(Mandatory = $false)]
        [object]$Connection,
        
        [Parameter(Mandatory = $false)]
        [switch]$AutoPublish
    )
    
    try {
        # Use configured values if not provided
        if (-not $Tenant) {
            $Tenant = $script:Tenant
        }
        if (-not $ClientId) {
            $ClientId = $script:ClientId
        }
        
        # Connect to Content Type Hub if connection not provided
        if (-not $Connection) {
            $contentTypeHubUrl = "https://$Tenant.sharepoint.com/sites/ContentTypeHub"
            Write-Host -ForegroundColor Yellow "Connecting to Content Type Hub: $contentTypeHubUrl"
            $Connection = Connect-PnPOnline -ClientId $ClientId -Url $contentTypeHubUrl -Interactive -ReturnConnection
        }
        
        # Get the "Document Set" content types (starting with 0x0120D520)
        Write-Host -ForegroundColor Cyan "Retrieving Document Set content types..."
        $contentTypes = Get-PnPContentType -Connection $Connection | Where-Object { $_.Id.StringValue.StartsWith("0x0120D520") }
        
        if ($contentTypes.Count -eq 0) {
            Write-Host -ForegroundColor Red "No Document Set content types found in the Content Type Hub."
            return
        }
        
        # Display available content types with their current modernization status
        Write-Host -ForegroundColor White "Available Document Set content types:"
        for ($i = 0; $i -lt $contentTypes.Count; $i++) {
            $currentValue = "❌"  # Not modernized
            if ($contentTypes[$i].NewFormClientSideComponentId.Length -eq 0) {
                $currentValue = "✅"  # Already modernized
            }
            Write-Host "[$($i + 1)] $($contentTypes[$i].Name) $currentValue"
        }
        
        # Get user selection for content type
        do {
            $contentTypeIndex = Read-Host -Prompt "Which content type do you wish to modernize? (1-$($contentTypes.Count))"
            $contentTypeIndexNum = $contentTypeIndex -as [int]
        } while ($contentTypeIndexNum -lt 1 -or $contentTypeIndexNum -gt $contentTypes.Count)
        
        $selectedContentType = $contentTypes[$contentTypeIndexNum - 1]
        Write-Host -ForegroundColor Green "Selected content type: $($selectedContentType.Name)"
        
        # Null out the NewFormClientSideComponentId to bring it to modern UI
        Write-Host -ForegroundColor Yellow "Modernizing content type..."
        $selectedContentType.NewFormClientSideComponentId = $null
        $selectedContentType.Update($false)
        
        Invoke-PnPQuery -Connection $Connection
        
        Write-Host -ForegroundColor Green "Content type '$($selectedContentType.Name)' has been updated successfully!"
        
        # Determine whether to publish
        $shouldPublish = $false
        if ($AutoPublish) {
            $shouldPublish = $true
            Write-Host -ForegroundColor Yellow "Auto-publishing enabled..."
        }
        else {
            $toPublish = Read-Host -Prompt "Content type '$($selectedContentType.Name)' updated. Would you like to publish the change? (Y/N)"
            $shouldPublish = $toPublish.ToUpper() -eq 'Y'
        }
        
        if ($shouldPublish) {
            # Publish the changed content type
            Write-Host -ForegroundColor Yellow "Publishing content type '$($selectedContentType.Name)' with ID '$($selectedContentType.Id)'..."
            Publish-PnPContentType -ContentType $selectedContentType.Id -Connection $Connection
            Write-Host -ForegroundColor Green "Content type published successfully!"
        }
        else {
            Write-Host -ForegroundColor Yellow "Content type updated but not published. Changes are saved locally."
        }
        
        Write-Host -ForegroundColor Green "All done!"
        
    }
    catch {
        Write-Error "An error occurred while updating tenant content types: $($_.Exception.Message)"
        throw
    }
}