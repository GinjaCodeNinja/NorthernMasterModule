function Get-AnonymouslinkActivityReport {
    <#
    .SYNOPSIS
    Retrieves anonymous link activity report from Exchange Online audit logs
    
    .DESCRIPTION
    This function connects to Exchange Online and retrieves anonymous link activity
    for SharePoint Online and OneDrive for Business for a specified date range.
    
    .PARAMETER DefaultReport
    Use default settings to generate a 90-day report
    
    .PARAMETER StartDate
    The start date for the report (YYYY-MM-DD format)
    
    .PARAMETER EndDate
    The end date for the report (YYYY-MM-DD format)
    
    .PARAMETER SharePointOnline
    Include SharePoint Online events
    
    .PARAMETER OneDrive
    Include OneDrive for Business events
    
    .PARAMETER AnonymousSharing
    Filter for anonymous sharing events only
    
    .PARAMETER AnonymousAccess
    Filter for anonymous access events only
    
    .PARAMETER AdminName
    Administrator account name for authentication
    
    .PARAMETER Password
    Password for authentication
    
    .PARAMETER OutputPath
    Custom output path for the CSV report
    
    .EXAMPLE
    Get-AnonymouslinkActivityReport -DefaultReport
    
    .EXAMPLE
    Get-AnonymouslinkActivityReport -StartDate "2025-01-01" -EndDate "2025-01-31" -AnonymousSharing
    
    .EXAMPLE
    Get-AnonymouslinkActivityReport -StartDate "2025-01-01" -EndDate "2025-01-31" -OutputPath "C:\Reports\AnonymousLinks.csv"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$DefaultReport,
        
        [Parameter(Mandatory = $false)]
        [Nullable[DateTime]]$StartDate,
        
        [Parameter(Mandatory = $false)]
        [Nullable[DateTime]]$EndDate,
        
        [Parameter(Mandatory = $false)]
        [switch]$SharePointOnline,
        
        [Parameter(Mandatory = $false)]
        [switch]$OneDrive,
        
        [Parameter(Mandatory = $false)]
        [switch]$AnonymousSharing,
        
        [Parameter(Mandatory = $false)]
        [switch]$AnonymousAccess,
        
        [Parameter(Mandatory = $false)]
        [string]$AdminName,
        
        [Parameter(Mandatory = $false)]
        [string]$Password,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )
    
    try {
        # Initialize variables
        $MaxStartDate = ((Get-Date).AddDays(-89)).Date
        $Modules = @("PnP.PowerShell", "ExchangeOnlineManagement")
        
        if (-not $OutputPath) {
            $OutputPath = ".\AnonymousLinkActivityReport_$((Get-Date -format yyyy-MM-dd_HH-mm).ToString()).csv"
        }
        
        $IntervalTimeInMinutes = 1440
        $AggregateResults = @()
        $CurrentResult = @()
        $CurrentResultCount = 0
        $AggregateResultCount = 0
        $ProcessedAuditCount = 0
        $OutputEvents = 0
        $ExportResult = ""
        $ExportResults = @()
        
        # Check and install required modules
        Write-Host -ForegroundColor Yellow "Checking for required modules..."
        $modulesInstalled = Invoke-WithRetry -Message "Checking for required modules" -ScriptBlock {
            $isInstalled = Test-ModulesAdded -Modules $Modules
            if (-not $isInstalled) {
                Write-Host -ForegroundColor Red "Required modules are not installed. Exiting script."
                Start-ExitTimer
            }
            return $isInstalled
        }
        
        # Handle date parameters
        if ($DefaultReport) {
            $EndDate = (Get-Date).Date
            $StartDate = $MaxStartDate
            Write-Host -ForegroundColor Blue "Start Date: $StartDate"
            Write-Host -ForegroundColor Blue "End Date: $EndDate"
        }
        
        if (-not $StartDate) {
            $startEntered = $false
            while (-not $startEntered) {
                $startInput = Read-Host -Prompt "Please enter the start date (yyyy-MM-dd) for the report"
                try {
                    $validatedDate = Get-ValidatedDate -DateString $startInput -MaxStartDate $MaxStartDate
                    if ($validatedDate) {
                        $StartDate = $validatedDate
                        $startEntered = $true
                    }
                }
                catch {
                    Write-Host -ForegroundColor Red "Invalid start date: $($_.Exception.Message). Please try again."
                }
            }
        }
        
        if (-not $EndDate) {
            $endEntered = $false
            while (-not $endEntered) {
                $endInput = Read-Host -Prompt "Please enter the end date (yyyy-MM-dd) for the report"
                try {
                    $validatedDate = Get-ValidatedDate -DateString $endInput -MaxStartDate $StartDate
                    if ($validatedDate) {
                        $EndDate = $validatedDate
                        $endEntered = $true
                    }
                }
                catch {
                    Write-Host -ForegroundColor Red "Invalid end date: $($_.Exception.Message). Please try again."
                }
            }
        }
        
        Write-Host ""
        Write-Host -ForegroundColor Yellow "Retrieving anonymous link events from $StartDate to $EndDate"
        
        # Connect to Exchange Online
        Connect-ExchangeOnline
        
        # Determine operation type
        if ($AnonymousSharing.IsPresent) {
            $RetrieveOperation = "AnonymousLinkCreated"
        }
        elseif ($AnonymousAccess.IsPresent) {
            $RetrieveOperation = "AnonymousLinkUsed"
        }
        else {
            $RetrieveOperation = "AnonymousLinkRemoved,AnonymousLinkCreated,AnonymousLinkUpdated,AnonymousLinkUsed"
        }
        
        # Process events in intervals
        $currentStart = $StartDate
        while ($currentStart -lt $EndDate) {
            $currentEnd = $currentStart.AddMinutes($IntervalTimeInMinutes)
            
            # Check whether CurrentEnd exceeds EndDate
            if ($currentEnd -gt $EndDate) {
                $currentEnd = $EndDate
            }
            
            if ($currentStart -eq $currentEnd) {
                Write-Host -ForegroundColor Red "Start and end time are the same. Please enter a different time range."
                return
            }
            
            Write-Host "Retrieving events from $currentStart to $currentEnd"
            
            # Retrieve events
            $events = Get-EXOAuditLogSearch -StartDate $currentStart -EndDate $currentEnd -Operations $RetrieveOperation
            
            if ($events.Count -eq 0) {
                Write-Host "No events found for the specified time range."
            }
            else {
                # Process events
                foreach ($event in $events) {
                    $AggregateResults += $event
                    $OutputEvents++
                }
                Write-Host "Found $($events.Count) events in this interval"
            }
            
            # Update current start for next iteration
            $currentStart = $currentEnd
        }
        
        # Export results
        if ($AggregateResults.Count -gt 0) {
            Write-Host -ForegroundColor Green "Exporting $($AggregateResults.Count) events to $OutputPath"
            $AggregateResults | Export-Csv -Path $OutputPath -NoTypeInformation
            Write-Host -ForegroundColor Green "Report exported successfully to: $OutputPath"
        }
        else {
            Write-Host -ForegroundColor Yellow "No events found for the specified criteria and date range."
        }
        
        # Return summary
        return @{
            TotalEvents = $AggregateResults.Count
            StartDate = $StartDate
            EndDate = $EndDate
            OutputPath = $OutputPath
            Operations = $RetrieveOperation
        }
        
    }
    catch {
        Write-Error "An error occurred while generating the anonymous link activity report: $($_.Exception.Message)"
        throw
    }
    finally {
        # Disconnect from Exchange Online
        try {
            Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
        }
        catch {
            # Ignore disconnect errors
        }
    }
}