#Region function Connect-ToSharePointSite
function Add-LineBreak {

    Write-Host "" # For readability
}

function Set-Output {

    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [String]$Color,
        [Parameter(
            Mandatory = $true,
            Position = 1
        )]
        [String]$Message,
        [Switch]$NoNewLine
    )

    if(-not $noNewLine){
        
        Write-Host -ForegroundColor $Color $Message
    }
    else{

        Write-Host -ForegroundColor $Color $Message -NoNewLine
    }

}

function Connect-ToAdminSharePointSite {
    param (
        [Parameter(
            Mandatory = $true
        )]
        [string]$SiteUrl,
        [Parameter(
            Mandatory = $true
        )]
        [string]$ClientId
    )

    Invoke-WithRetry -ScriptBlock {
            
        $connection = Connect-PnPOnline -Url $SiteUrl -Interactive -ClientId $ClientId-ReturnConnection
        return $connection
    }
}
function Connect-ToSharePointSite {
    param (
        [Parameter(
            Mandatory = $true
        )]
        [string]$SiteUrl,
        [Parameter(
            Mandatory = $true
        )]
        [object]$Connection
    )


    Invoke-WithRetry -ScriptBlock {
            
        $cnx = Connect-PnPOnline -Url $SiteUrl -Connection $connection
        return $cnx
    }
}
#EndRegion

#Region function Invoke-WithRetry
function Invoke-WithRetry{

    param(
        [Parameter(mandatory = $true)]
        [scriptblock]$ScriptBlock,
        [string]$Message,
        [int]$MaxRetries = 5
    )

    [int]$DelaySeconds = (Get-Random -Minimum 3 -Maximum 7)
    $attempt = 1

    while ($attempt -le $MaxRetries){

        try{

            if($attempt -eq 1 -and $message.IsPresent){

                Write-Host -ForegroundColor Yellow "$message" -NoNewline
            }

            return & $ScriptBlock
        }
        catch {

            if ($attempt -eq $MaxRetries) { throw }
            Write-Host -ForegroundColor Red "Attempt $attempt failed: $($_.Exception.Message)"
            Start-Sleep -Seconds $DelaySeconds
            $attempt++
        }
    }
}
#EndRegion

#Region function Test-ModulesAdded
function Test-ModulesAdded {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string[]]$Modules
    )
    Set-Output Blue "Checking if required modules are installed..."    
    foreach($Module in $Modules) {

        Set-Output White "     $($Module) : " -NoNewline
        if((Get-Module -ListAvailable -Name $Module)) {

            Set-Output Green "Already installed!"
            Import-Module -Name $Module -Scope CurrentUser -Force -AllowClobber

            return $true

        }
        else {

            Set-Output Red "Not found."
            Set-Output Yellow "Installing $Module module: " -NoNewline
            
            Invoke-WithRetry -ScriptBlock {

                try{

                    Install-Module -Name $Module -Scope CurrentUser -Force -AllowClobber
                    
                    Set-Output Green "Success!"
                    Import-Module -Name $Module -Force

                    return $true
                }
                catch {

                    Set-Output Red "Failed!"
                    Set-Output Red "Error: $($_.Exception.Message)"
            
                } 
            }
        }
    }
}
#EndRegion

#Region fucntion Start-ExitTimer

function Start-ExitTimer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SiteName
    )

    begin {

        Set-Output Red "Unable to connect to the $SiteName after multiple attempts!"
        Set-Output Red "Please try again!"
    }
    process {
        
        for($i = 10; $i -ge 0; $i--){

            Set-Output Red "$i  " -NoNewLine
            Start-Sleep -Seconds 1
        }
    }
    end {

        exit
    }
}
#EndRegion

#Region function Get-ValidatedDate
function Get-ValidatedDate {
    param (
        [Parameter(Mandatory)]
        [string]$DateString,
        [Parameter(Mandatory)]
        [datetime]$MaxStartDate
    )

    # Check format
    if ($DateString -notmatch '^\d{4}-\d{2}-\d{2}$') {

        throw "Date must be in YYYY-MM-DD format."
    }

    # Try to parse
    $date = [datetime]::ParseExact($DateString, 'yyyy-MM-dd', $null)
    if ($date -lt $MaxStartDate) {

        throw "Date cannot be before $MaxStartDate."
    }
    return $date
}