. "$PSScriptRoot\..\private\GroupHelpers.ps1"
. "$PSScriptRoot\..\private\invokeWithRetry.ps1"
. "$PSScriptRoot\..\private\updateGroupMembers.ps1"

$requiredScopes = @("Group.ReadWrite.All", "User.Read.All")
$connected = Get-MgContext
If($connected){
    
    Disconnect-MgGraph
}
Connect-MgGraph -Scopes $requiredScopes

$Source = Read-Host -Prompt "What is the source group's Name or Id?"
$Target = Read-Host -Prompt "What is the target group's Name or Id?"

function Get-GroupObject {
    param (
        [string]$InputValue
    )
    # Regex for GUID
    if ($InputValue -match '^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$') {
        # Input is a GUID
        return Get-MgGroup -GroupId $InputValue
    } 
    else {
        # Input is a name
        return Get-MgGroup -Filter "displayName eq '$InputValue'"
    }
}

$SourceGroup = Get-GroupObject -InputValue $Source | Select-Object -First 1
$TargetGroup = Get-GroupObject -InputValue $Target | Select-Object -First 1

if (-not $SourceGroup) {

    Write-Host -ForegroundColor Red "Source group not found!"
    exit 1
}
if (-not $TargetGroup) {

    Write-Host -ForegroundColor Red "Target group not found!"
    exit 1
}

$SourceGroup | Update-GroupMembership -TargetGroup $TargetGroup
