<#CmdletBinding()]
param(

    [Parameter(Mandatory = $false)]
    [switch]$defaultReport,
    [Nullable[DateTime]]$StartDate,
    [Nullable[DateTime]]$EndDate,
    [switch]$SharePointOnline,
    [switch]$OneDrive,
    [switch]$AnonymousSharing,
    [switch]$AnonymousAccess,
    [string]$AdminName,
    [string]$Password
)

#Region static variables

$MaxStartDate = ((Get-Date).AddDays(-89)).Date
$Modules = @("PnP.PowerShell", "ExchangeOnlineManagement")
$OutputCSV = ".\AnonymousLinkActivityReport_$((Get-Date -format yyyy-MM-dd::hh-mm).ToString()).csv"
$IntervalTimeInMinutes = 1440
$AggregateResults = @()
$CurrentResult= @()
$CurrentResultCount=0
$AggregateResultCount=0
$ProcessedAuditCount=0
$OutputEvents=0
$ExportResult=""   
$ExportResults=@()  
#EndRegion

$modulesInstalled = Invoke-WithRetry -Message "Checking for required modules" -ScriptBlock {

    $isInstalled = Test-ModulesAdded -Modules $Modules
    if( -not $isInstalled ) {

        Write-Host -ForegroundColor Red "Required modules are not installed. Exiting script."
        Start-ExitTimer
    }
}

#Region Get 90 Day Anonymous Activity Report
if ($defaultReport) {

    $EndDate = (Get-Date).Date
    $StartDate = $MaxStartDate

    Write-Host -ForegroundColor Blue "Start Date: $StartDate"
    Write-Host -ForegroundColor Blue "End Date: $EndDate"
}
if ( -not $StartDate ){

    $startEntered = $false
    while ( -not $startEntered ) {

        $StartDate = Read-Host -Prompt "Please enter the start date (yyyy-MM-dd) for the report that you want to run"
        Invoke-WithRetry -Message "Validating start date" -ScriptBlock {

            $validatedDate = Get-ValidatedDate -DateString $StartDate -MaxStartDate $MaxStartDate
            if ($validatedDate) {

                $StartDate = $validatedDate
                $startEntered = $true
            } 
            else {

                Write-Host -ForegroundColor Red "Invalid start date. Please try again."
            }
        }
    }
}
if(-not $EndDate){

    $endEntered = $false
    while ( -not $endEntered ) {

        $EndDate = Read-Host -Prompt "Please enter the end date (yyyy-MM-dd) for the report that you want to run"
        Invoke-WithRetry -Message "Validating end date" -ScriptBlock {

            $validatedDate = Get-ValidatedDate -DateString $EndDate -MaxStartDate $StartDate
            if ($validatedDate) {

                $EndDate = $validatedDate
                $endEntered = $true
            } 
            else {

                Write-Host -ForegroundColor Red "Invalid end date. Please try again."
            }
        }
    }
}

Write-Host ""
Write-Host -ForegroundColor Yellow "Retrieving anonymous link events from $StartDate to $EndDate"
Connect-ExchangeOnline

if($AnonymousSharing.IsPresent){

    $RetriveOperation = "AnonymousLinkCreated"
}
elseif($AnonymousAccess.IsPresent){

    $RetriveOperation = "AnonymousLinkUsed"
}
else {

    $RetrieveOperation = "AnonymousLinkRemoved,AnonymousLinkCreated,AnonymousLinkUpdated,AnonymousLinkUsed"
}

while($true) {

    $CurrentStart = $StartDate
    $CurrentEnd = $CurrentStart.AddMinutes($IntervalTimeInMinutes)

    # Check whether CurrentEnd exceeds EndDate
    if ($CurrentEnd -gt $EndDate) {

        $CurrentEnd = $EndDate
    }

    if ($CurrentStart -eq $CurrentEnd) {

        Write-Host -ForegroundColor Red "Start and end time are the same. Please enter a different time range."
        Exit
    }

    Write-Host "Retrieving events from $CurrentStart to $CurrentEnd"
    
    # Retrieve events
    $events = Get-EXOAuditLogSearch -StartDate $CurrentStart -EndDate $CurrentEnd -Operations $RetriveOperation

    if ($events.Count -eq 0) {

        Write-Host "No events found for the specified time range."
        break
    }

    # Process events
    foreach ($event in $events) {

        # Process each event as needed
        # Example: Add to results array
        $AggregateResults += $event
        $OutputEvents++
    }

    # Update current start for next iteration
    $StartDate = $CurrentEnd

    if ($CurrentEnd -eq $EndDate) {

        break
    }
}





#>