# Northern Computer Master Module

PowerShell master module for Northern Computer, consolidating SharePoint and Teams automation tasks using PnP.PowerShell, MSGraph, and Exchange.

## Overview

The Northern Computer Master Module provides a comprehensive set of PowerShell functions for managing SharePoint Online, Teams, and Exchange Online environments. This module is designed for technical staff to automate common administrative tasks across Microsoft 365 services.

## Features

- **SharePoint Content Type Management**: Modernize content types at site and tenant levels
- **Anonymous Link Reporting**: Generate reports on anonymous link activity
- **Group Membership Management**: Synchronize group memberships between source and target groups
- **File Sharing Links**: Retrieve and manage sharing links across SharePoint sites
- **Helper Functions**: Robust retry logic, connection management, and error handling

## Prerequisites

- PowerShell 5.1 or later
- The following PowerShell modules (automatically installed if missing):
  - PnP.PowerShell
  - Microsoft.Graph
  - ExchangeOnlineManagement

## Installation

### Option 1: Import from Local Path
1. Clone or download this repository
2. Open PowerShell as Administrator
3. Navigate to the module directory
4. Import the module:
   ```powershell
   Import-Module .\NorthernMasterModule.psd1
   ```

### Option 2: Install to PowerShell Modules Path
1. Copy the entire module folder to one of your PowerShell module paths:
   - User modules: `$env:USERPROFILE\Documents\PowerShell\Modules\`
   - System modules: `$env:ProgramFiles\PowerShell\Modules\`
2. Import the module:
   ```powershell
   Import-Module NorthernMasterModule
   ```

## Configuration

The module uses a configuration file (`tenant.psd1`) to store tenant-specific settings:

```powershell
$script:Tenant = "northerncomputer"
$script:ClientId = "fe14f9e4-a977-402f-8e3a-3e210974a40b"
```

Update these values to match your environment before using the module.

## Available Functions

### Content Type Management

#### `Update-SiteContentTypes`
Modernizes SharePoint content types at the site level.

```powershell
# Interactive mode - prompts for site URL and selections
Update-SiteContentTypes -SiteUrl "https://tenant.sharepoint.com/sites/contoso"

# Using existing connection
$connection = Connect-ToSharePointSite -SiteUrl "https://tenant.sharepoint.com/sites/contoso"
Update-SiteContentTypes -Connection $connection
```

#### `Update-TenantContentTypes`
Modernizes SharePoint content types at the tenant level (Content Type Hub).

```powershell
# Interactive mode
Update-TenantContentTypes

# Auto-publish changes
Update-TenantContentTypes -AutoPublish

# Specify custom tenant and client ID
Update-TenantContentTypes -Tenant "contoso" -ClientId "12345678-90ab-cdef-1234-567890abcdef"
```

### Reporting

#### `Get-AnonymouslinkActivityReport`
Generates reports on anonymous link activity from Exchange Online audit logs.

```powershell
# Generate default 90-day report
Get-AnonymouslinkActivityReport -DefaultReport

# Custom date range
Get-AnonymouslinkActivityReport -StartDate "2025-01-01" -EndDate "2025-01-31"

# Filter for specific activity types
Get-AnonymouslinkActivityReport -StartDate "2025-01-01" -EndDate "2025-01-31" -AnonymousSharing

# Custom output path
Get-AnonymouslinkActivityReport -DefaultReport -OutputPath "C:\Reports\AnonymousLinks.csv"
```

#### `Get-SharedLinks`
Retrieves sharing links from SharePoint sites.

```powershell
# Get all sharing links for a site
Get-SharedLinks -SiteUrl "https://tenant.sharepoint.com/sites/contoso" -adminConnection $connection

# Filter for specific link types
Get-SharedLinks -SiteUrl "https://tenant.sharepoint.com/sites/contoso" -GetAnyoneLinks -adminConnection $connection
Get-SharedLinks -SiteUrl "https://tenant.sharepoint.com/sites/contoso" -ActiveLinks -adminConnection $connection
```

### Group Management

#### `Update-GroupMembership`
Synchronizes membership between source and target groups.

```powershell
# Synchronize group memberships
$sourceGroup = [PSCustomObject]@{ Id = "source-group-id"; DisplayName = "Source Group" }
$targetGroup = [PSCustomObject]@{ Id = "target-group-id"; DisplayName = "Target Group" }

Update-GroupMembership -SourceGroup $sourceGroup -TargetGroup $targetGroup
```

## Helper Functions

The module includes several helper functions for common operations:

- `Connect-ToSharePointSite`: Establishes SharePoint connections
- `Connect-ToAdminSharePointSite`: Connects to admin sites
- `Invoke-WithRetry`: Provides retry logic for operations
- `Test-ModulesAdded`: Checks and installs required modules
- `Get-ValidatedDate`: Validates date inputs
- `Set-Output`: Standardized output formatting

## Error Handling

The module includes comprehensive error handling with:
- Automatic retry logic for transient failures
- Descriptive error messages
- Graceful degradation for connection issues
- Proper cleanup of resources

## Examples

### Complete Site Content Type Modernization Workflow

```powershell
# Import the module
Import-Module NorthernMasterModule

# Connect to a site and modernize content types
$siteUrl = "https://northerncomputer.sharepoint.com/sites/projectsite"
Update-SiteContentTypes -SiteUrl $siteUrl

# Update tenant-level content types and publish changes
Update-TenantContentTypes -AutoPublish
```

### Generate Comprehensive Anonymous Link Report

```powershell
# Generate a 90-day report
$report = Get-AnonymouslinkActivityReport -DefaultReport

# View report summary
Write-Host "Generated report with $($report.TotalEvents) events"
Write-Host "Report saved to: $($report.OutputPath)"
```

## Contributing

This module is designed for ongoing evolution. When adding new functions:

1. Place user-facing functions in the `public/` directory
2. Place helper functions in the `private/` directory
3. Place PowerShell classes in the `classes/` directory
4. Update the module manifest (`NorthernMasterModule.psd1`) to export new functions
5. Follow the existing patterns for error handling and retry logic

## Support

For issues or questions, please refer to the module documentation or contact the Northern Computer technical team.

## Notes

**Author**: Brenden Salter, Business Systems Manager, Northern Computer  
**Date Created**: April 22, 2025  
**Components**: MSGraph Module, PnP.PowerShell Module, Microsoft Visual Basic, PowerShell Classes

## License

Copyright (c) 2025 Northern Computer. All rights reserved.
