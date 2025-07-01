<#
    .SYNOPSIS
    Synchronizes membership between a source and target group.
    Adds missing members to the target group and removes extra members.

#>

function Update-GroupMembership {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Object]$SourceGroup,

        [Parameter(Mandatory)]
        [System.Object]$TargetGroup
    )
    
    begin {

        Write-Host -foregroundcolor Yellow "Starting group membership update process..."
    }
    
    process {

        try {

            Write-Host -ForegroundColor White "     Retrieving members from source group: $($SourceGroup.DisplayName)"
            $sourceMembers = Invoke-WithRetry -ScriptBlock {

                Get-GroupMembers -GroupId $SourceGroup.Id
            }

            Write-Host -ForegroundColor White "     Retrieving members from target group: $($TargetGroup.DisplayName)"
            $targetMembers = Invoke-WithRetry -ScriptBlock {

                Get-GroupMembers -GroupId $TargetGroup.Id
            }

            $toAdd = $sourceMembers | Where-Object { $_.Id -notin $targetMembers }
            $toRemove = $targetMembers | Where-Object { $_.Id -notin $sourceMembers }

            if($toAdd.Count -gt 0){

                Write-Host -ForegroundColor Yellow "          Adding $($toAdd.Count) member(s) to $($TargetGroup.DisplayName)..."
                foreach($member in $toAdd){

                    try {
                        
                        Invoke-WithRetry -ScriptBlock {

                            $userDetails = Get-MgUser -UserId $member.Id
                            Write-Host -ForegroundColor White "               $($userDetails.DisplayName): " -NoNewline
                            Add-GroupMember -GroupId $TargetGroup.Id -UserId $userDetails.Id
                            Write-Host -ForegroundColor Green "Success!"
                        }
                    }
                    catch {
                        
                        Write-Host -ForegroundColor Red "Failed!"
                    }
                }
            }
            else {

                Write-Host "          No members to add"
            }

            if($toRemove.Count -gt 0){

                Write-Host -ForegroundColor Yellow "          Removing $($toRemove.Count) member(s) from $($TargetGroup.DisplayName)..."
                foreach( $member in $toRemove){

                    try {
                        
                        Invoke-WithRetry -ScriptBlock {

                            $userDetails = Get-MgUser -UserId $member.Id
                            Write-Host -ForegroundColor White "               $($userDetails.DisplayName): " -NoNewline
                            Remove-GroupMember -GroupId $TargetGroup.Id -UserId $userDetails.Id
                            Write-Host -ForegroundColor Green "Success!"
                        }
                    }
                    catch {

                        Write-Host -ForegroundColor Red "Failed!"
                    }
                }
            }

            Write-Host -ForegroundColor Green "Group membership update complete!"

        }
        catch {

            Write-Error "An error occured during group membership update: $_"
        }

    }
    
    end {
        
        Write-Host -ForegroundColor Green "Finished processing group memebership update!"
    }
}