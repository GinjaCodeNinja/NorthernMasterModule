function Get-SharedLinks {

    [CmdletBinding()]
    param (

        [switch]$ActiveLinks,
        [switch]$ExpiredLinks,
        [switch]$LinksWithExpiration,
        [switch]$NeverExpiresLinks,
        [switch]$GetAnyoneLinks,
        [switch]$GetCompanyLinks,
        [switch]$GetSpecificPeopleLinks,
        [int]$SoonToExpireInDays,
        [string]$ReportOutput,
        [datetime]$CurrentDateTIme,
        [object]$adminConnection,
        [Parameter(Mandatory)]
        [string]$SiteUrl
        
    )
    [array]$ExcludedLists = @(
        "Form Templates", 
        "Style Library",
        "Site Assets",
        "Site Pages", 
        "Preservation Hold Library", 
        "Pages", 
        "Images", 
        "Site Collection Documents",
        "Site Collection Images"
        "_catalogs/hubsite"
    )
    # [array]$TotalResults = @()
    # [array]$MethodResults = @()
    [array]$PnPResults = @()
    [string]$CurrentDateTIme = (Get-Date).Date
        
    $Connection = Invoke-WithRetry -ScriptBlock {

        $cnx = Connect-ToSharePointSite -SiteUrl $SiteUrl -Connection $adminConnection

        return $cnx
    }

    # $context = Get-PnPContext -Connection $Connection

    # Get Document Libraries
    $documentLibraries = Get-PnPList -Connection $Connection | Where-Object { $_.BaseTemplate -eq 101 -and $_.Hidden -eq $false -and $_.Title -notin $ExcludedLists }

    Write-Host -ForegroundColor Blue "DOCUMENT LIBRARIES"
    Write-Host -ForegroundColor Blue "--------------------------------"


    foreach ($list in $documentLibraries) {

        # $currentListIndex = $ListItems.IndexOf($list)
        # Write-Progress -Activity ("Library: $($list.Title)") -Status ("Processing Item : "+ $list.Title) -PercentComplete (($currentListIndex / $documentLibraries.Count) * 100)
        
        # Write-Host -ForegroundColor White "     [$($DocumentLibraries.IndexOf($list)+1)] $($list.Title)"
        $listItems = Get-PnpListItem -List $list -PageSize 200 -Connection $Connection

        foreach ($item in $ListItems) {

            $currentItemIndex = $ListItems.IndexOf($item)
            Write-Progress -Activity ("Site Name: $Site") -Status ("Processing Item : "+ $fileUrl) -PercentComplete (($currentItemIndex / $listItems.Count) * 100)

            $fileName = $item.FieldValues.FileLeafRef
            $fileUrl = $item.FieldValues.FileRef
            $fileType = $item.FieldValues.File_x0020_Type
            $objectType = $item.FileSystemObjectType

            $hasUniquePermissions = (Get-PnpProperty -ClientObject $item -Property "HasUniqueRoleAssignments" -Connection $Connection)

            if ($hasUniquePermissions) {

                # $SharingDetails = [Microsoft.SharePoint.Client.ObjectSharingInformation]::GetObjectSharingInformation(
                #     $context, 
                #     $item, 
                #     $false, # excludeCurrentUser
                #     $false, # excludeSiteAdmin
                #     $false, # excludeSecurityGroups
                #     $true,  # retrieveAnonymousLinks
                #     $true,  # retrieveUserInfoDetails
                #     $true,  # checkForAccessRequests
                #     $true   # retrievePermissionLevels
                # )
                # $context.Load($SharingDetails)
                # $context.ExecuteQuery()

                # foreach ($methodFileSharingLink in $SharingDetails.SharingLinks) {

                #     if($methodFileSharingLink.Url){

                #         $AccessType = "Edit"
                #     }
                #     elseif($methodFileSharingLink.IsReviewLink){

                #         $AccessType = "Review"
                #     }
                #     else {

                #         $AccessType ="ViewOnly"
                #     }

                #     $MethodResults += [PSCustomObject]@{
                #         Name = $fileName
                #         RelativeUrl = $fileUrl
                #         FileType = $fileType
                #         ShareLink = $methodFileSharingLink.Url
                #         ShareLinkAccess = $AccessType
                #         ShareLinkType = $methodFileSharingLink.LinkKind
                #         AllowsAnonymousAccess = $methodFileSharingLink.AllowsAnonymousAccess
                #         IsActive = $methodFileSharingLink.IsActive
                #         Expiration = $methodFileSharingLink.Expiration
                #         PasswordProtected = $methodFileSharingLink.HasPassword
                #     }
                # }

                if($objectType -eq "File"){

                    $pnpFileSharingLinks = Get-PnPFileSharingLink -Url $fileUrl
                }
                elseif($bojectType -eq "Folder"){

                    $pnpFileSharingLinks = Get-PnPFolderSharingLink -Url $fileUrl
                }
                else {
                    Write-Host -ForegroundColor  Red "Unsupported object type: $objectType for file: $fileName"
                    continue
                }
                foreach ($pnpFileSharingLink in $pnpFileSharingLinks) {

                    $link = $pnpFileSharingLink.Link
                    $scope = $link.Scope

                    if( $GetAnyoneLinks -and ( $scope -ne "Anonymous" )) { continue }
                    elseif ($GetCompanyLinks -and ( $scope -ne "Organization" )) { continue }
                    elseif ($GetSpecificPeopleLinks -and ( $scope -ne "Users" )) { continue }

                    
                    if(( $ActiveLinks ) -and ( $linkStatus -ne "Active" )){ continue }
                    elseif(( $ExpiredLinks ) -and ( $linkStatus -ne "Expired" )){ continue }
                    elseif(( $LinksWithExpiration ) -and ($null -eq $expirationDate )) { continue }
                    elseif(( $NeverExpiresLinks ) -and ( $friendlyExpiryTime -ne "Never Expires" )) { continue }
                    elseif(( $SoonToExpireInDays ) -and ( $null -eq $expirationDate) -or ($SoonToExpireInDays -lt $expiryDays) -or ($expiryDays -lt 0 )) { continue }

                    Write-Host "File: $($item.FieldValues.FileLeafRef), Link: $($fileSharingLink.LinkKind), Expiration: $($fileSharingLink.ExpirationDate)"

                    $permission = $Link.Type
                    $sharedLink = $link.WebUrl
                    $passwordProtected = $pnpFileSharingLink.HasPassword
                    $blockDownload = $link.PreventsDownload
                    $RoleList = $pnpFileSharingLink.Roles -join ", "
                    $expirationDate = $pnpFileSharingLink.ExpirationDateTime
                    $users = $pnpFileSharingLink.GrantedToIdentitiesV2.User.Email
                    $directUsers = $users -join ", "
                    if(-not $expirationDate){

                        $expiryDate = ([datetime]$expirationDate).ToLocalTime()
                        $expiryDays = (New-TimeSpan -Start $currentDateTime -End $expiryDate).Days
                        if($expiryDate -lt $currentDateTime) {

                            $linkStatus = "Expired"
                            $expiryDateCalculation = $expiryDays * (-1)
                            $friendlyExpiryTime = "Expried $expiryDateCalculation days ago"
                        }
                        else {

                            $linkStatus = "Active"
                            $friendlyExpiryTime = "Expires in $expiryDays days"
                        }
                    }
                    else {

                        $linkStatus = "Active"
                        $expiryDays = "-"
                        $expiryDate = "-"
                        $friendlyExpiryTime = "Never Expires"
                    }

                    $PnPResults += [PSCustomObject]@{
        
                        "SiteName"             = $siteTitle
                        "Library"              = $list.Title
                        "ObjectType"           = $objectType
                        "File/Folder Name"     = $fileName
                        "File/Folder Url"      = $fileUrl
                        "Link Type"            = $scope
                        "Access Type"          = $permission
                        "Roles"                = $roleList
                        "Users"                = $directUsers
                        "File Type"            = $fileType
                        "Link Status"          = $linkStatus
                        "Link Expiry Date"     = $expiryDate
                        "Days Since/To Expiry" = $expiryDays
                        "Friendly Expiry Time" = $friendlyExpiryTime
                        "Password Protected"   = $passwordProtected
                        "Block Download"       = $BlockDownload
                        "Shared Link"          = $sharedLink
                        "CreatedBy"            = $CreatedBy
                    }

                    $PnPResults | Export-Csv -Path $ReportOutput -NoTypeInformation -Append -Force
                    # $TotalResults | Export-Csv -path $reportOutput -NoTypeInformation -Append -Force
                    $Script:ItemCount++
              }
            }
        }
    }
}  