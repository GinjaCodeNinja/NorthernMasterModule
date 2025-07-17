function Update-SiteContentTypes {
    <#
    .SYNOPSIS
    Modernizes SharePoint content types by updating NewFormClientSideComponentId
    
    .DESCRIPTION
    This function connects to a SharePoint site and allows you to select a document library
    and content type to modernize by nulling out the NewFormClientSideComponentId property.
    
    .PARAMETER SiteUrl
    The URL of the SharePoint site to connect to
    
    .PARAMETER Connection
    An existing PnP connection object to use
    
    .EXAMPLE
    Update-SiteContentTypes -SiteUrl "https://tenant.sharepoint.com/sites/contoso"
    
    .EXAMPLE
    $connection = Connect-ToSharePointSite -SiteUrl "https://tenant.sharepoint.com/sites/contoso"
    Update-SiteContentTypes -Connection $connection
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "SiteUrl")]
        [string]$SiteUrl,
        
        [Parameter(Mandatory = $true, ParameterSetName = "Connection")]
        [object]$Connection
    )
    
    try {
        # Connect to SharePoint if SiteUrl is provided
        if ($PSCmdlet.ParameterSetName -eq "SiteUrl") {
            Write-Host -ForegroundColor Yellow "Connecting to SharePoint site: $SiteUrl"
            $Connection = Connect-ToSharePointSite -SiteUrl $SiteUrl
        }
        
        # Get document libraries (BaseTemplate 101)
        Write-Host -ForegroundColor Cyan "Retrieving document libraries..."
        $lists = Get-PnPList -Connection $Connection | Where-Object {$_.BaseTemplate -eq 101}
        
        if ($lists.Count -eq 0) {
            Write-Host -ForegroundColor Red "No document libraries found on this site."
            return
        }
        
        # Display available lists
        Write-Host -ForegroundColor White "Available document libraries:"
        for ($i = 0; $i -lt $lists.Count; $i++) {
            Write-Host "[$($i + 1)] $($lists[$i].Title)"
        }
        
        # Get user selection for list
        do {
            $index = Read-Host -Prompt "Which list do you wish to modernize your content type? (1-$($lists.Count))"
            $indexNum = $index -as [int]
        } while ($indexNum -lt 1 -or $indexNum -gt $lists.Count)
        
        $selectedList = $lists[$indexNum - 1]
        Write-Host -ForegroundColor Green "Selected list: $($selectedList.Title)"
        
        # Get the "Folder" content types on the document library (starting with 0x0120)
        Write-Host -ForegroundColor Cyan "Retrieving content types..."
        $contentTypes = Get-PnPContentType -List $selectedList -Connection $Connection | Where-Object {$_.Id.StringValue.StartsWith("0x0120")}
        
        if ($contentTypes.Count -eq 0) {
            Write-Host -ForegroundColor Red "No folder content types found in this library."
            return
        }
        
        # Display available content types
        Write-Host -ForegroundColor White "Available content types:"
        for ($i = 0; $i -lt $contentTypes.Count; $i++) {
            Write-Host "[$($i + 1)] $($contentTypes[$i].Name)"
        }
        
        # Get user selection for content type
        do {
            $contentTypesIndex = Read-Host -Prompt "Which content type do you wish to modernize? (1-$($contentTypes.Count))"
            $contentTypeIndexNum = $contentTypesIndex -as [int]
        } while ($contentTypeIndexNum -lt 1 -or $contentTypeIndexNum -gt $contentTypes.Count)
        
        $selectedContentType = $contentTypes[$contentTypeIndexNum - 1]
        Write-Host -ForegroundColor Green "Selected content type: $($selectedContentType.Name)"
        
        # Null out the NewFormClientSideComponentId to bring it to modern UI
        Write-Host -ForegroundColor Yellow "Modernizing content type..."
        $selectedContentType.NewFormClientSideComponentId = $null
        $selectedContentType.Update($false)
        
        Invoke-PnPQuery -Connection $Connection
        
        Write-Host -ForegroundColor Green "Content type '$($selectedContentType.Name)' has been successfully modernized!"
        
    }
    catch {
        Write-Error "An error occurred while updating site content types: $($_.Exception.Message)"
        throw
    }
}