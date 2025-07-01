function Get-GroupMembers {
    param (
        [Parameter(Mandatory)]
        [string]$GroupId
    )
    
    $userList = @()
    Invoke-WithRetry -ScriptBlock {

        $members = Get-MGGroupMember -GroupId $GroupId -All

        foreach($member in $members){

            $member = Get-MgUser -UserId $member.Id

            $userList += [PSCustomObject]@{

                DisplayName = $member.DisplayName
                Id          = $member.Id
                Upn         = $member.UserPrincipalName
            } 
        }

        return $userList

    }
}

function Add-GroupMember {
    param (
        [Parameter(Mandatory)]
        [string]$GroupId,

        [Parameter(Mandatory)]
        [string]$UserId
    )

    Invoke-WithRetry -ScriptBlock {

        New-MgGroupMember -GroupId $GroupId -DirectoryObjectId $UserId 
    }

}

function Remove-GroupMember {
    param (
        [Parameter(Mandatory)]
        [string]$GroupId,

        [Parameter(Mandatory)]
        [string]$UserId
    )

    Invoke-WithRetry -ScriptBlock {

        Remove-MgGroupMemberByRef -GroupId $GroupId -DirectoryObjectId $UserId
    }

}