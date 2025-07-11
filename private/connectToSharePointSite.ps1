function Connect-ToSharePointSite {
    param (
        [Parameter(Mandatory)]
        [string]$SiteUrl
    )

    Invoke-WithRetry -ScriptBlock {
            
        $connection = Connect-PnPOnline -Url $SiteUrl -Interactive -ReturnConnection
        return $connection
    }
}