<#
.SYNOPSIS
The Invoke-WithRetry function executes a provided script block and automatically retries execution if an exception occurs. 
It attempts the script up to a specified maximum number of retries (MaxRetries, default is 5).
waiting a random number of seconds (between 3 and 7) between attempts. 
If all attempts fail, the function throws the last exception. 
Each failed attempt is logged to the console in red text.

#>

function Invoke-WithRetry{

    param(
        [Parameter(
            mandatory = $true
        )]
        [scriptblock]$ScriptBlock,
        [int]$MaxRetries = 5
    )

    [int]$DelaySeconds = (Get-Random -Minimum 3 -Maximum 7)

    $attempt = 1
    while ($attempt -le $MaxRetries){

        try{

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