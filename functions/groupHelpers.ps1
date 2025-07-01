function Get-GroupMembers {
    param (
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [string]$GroupId
    )
    
    process {
        Invoke-WithRetry -ScriptBlock {
            $members = Get-MgGroupMember -GroupId $GroupId -All
            foreach ($member in $members) {
                if ($member.AdditionalProperties['userPrincipalName']) {
                    [PSCustomObject]@{
                        DisplayName = $member.AdditionalProperties['displayName']
                        Id          = $member.Id
                        Upn         = $member.AdditionalProperties['userPrincipalName']
                    }
                }
            }
        }
    }
}

function Add-GroupMember {
    param (
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [string]$GroupId,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [string]$UserId
    )

    Invoke-WithRetry -ScriptBlock {

        New-MgGroupMember -GroupId $GroupId -DirectoryObjectId $UserId 
    }

}

function Remove-GroupMember {
    param (
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [string]$GroupId,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )]
        [string]$UserId
    )

    Invoke-WithRetry -ScriptBlock {

        Remove-MgGroupMemberByRef -GroupId $GroupId -DirectoryObjectId $UserId
    }

}