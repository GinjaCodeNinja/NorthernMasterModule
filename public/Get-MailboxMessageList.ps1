<#
.Description
This PowerShell script installs and imports the Microsoft Graph module if not already installed, 
prompts the user for necessary inputs, connects to Microsoft Graph, and searches for email messages 
in a specified user's mailbox based on Internet Message IDs provided in a CSV file. 
The script then exports the found message details to a CSV file.

.Author
Brenden Salter - Business Systems Manager - bsalter@northerncomputer.ca

.Published
April 17, 2025
#>

# Set the maximum function count to avoid exceeding the limit
#$maximumfunctioncount=32768

# Install the Microsoft.Graph module if not already installed
if (-NOT (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Install-Module -Name Microsoft.Graph -Scope AllUsers -Force -AllowClobber
}
    
# Import the Microsoft.Graph module
Import-Module Microsoft.Graph -Force

# Inform the user about necessary preparations
#Write-Host -ForegroundColor Blue "Please make sure you have turned on TAP for the user's mailbox before running this script"
Write-Host -ForegroundColor Blue "You will also need to login to the users profile using for this tenant browser session"
Write-Host -ForegroundColor Blue "You will also need to have the last active web browser window be the guest browser session"

# Wait for the user to be ready
Read-Host -Prompt "Press Enter when ready"

# Prompt the user for the CSV file location and the user ID
$csvLocation = Read-Host "Enter the full path to the CSV file"
$userId = Read-Host "Enter the user ID (userPrincipalName) of the mailbox you want to search"
$exportPath = Read-Host "Enter the full path to the export CSV file (e.g., C:\OutlookMessageData.csv)"
$failedPath = Read-host "Enter the full path to the export CSV file (e.g., C:\FailedMessages.csv)"

# Connect to Microsoft Graph with the required scope
Connect-MgGraph -Scopes "Mail.ReadWrite" 

# Import the CSV data
$csvData = Import-Csv -Path $csvLocation
# Initialize an empty hashtable to store the export data
$importedData = @()
$exportData = @()
$failedIMIDData = @()

# Iterate through each row in the CSV data
$csvData | ForEach-Object {

    $IMID = $_ | Select-Object -Property Column1.Folders.FolderItems.InternetMessageId 
    $FID = $_ | Select-Object -Property Column1.Folders.Path
    $IP = $_ | Select-Object -Property Column1.ClientIPAddress
    $importedObject = [PSCustomObject]@{
        IMID = $IMID
        FID = $FID
        IP = $IP
    }
    $importedData += $importedObject
}

foreach ($row in $importedData){

    $imidString = $row.IMID -split "<", 2
    $messageId = "<" + $imidString[1]
    $internetMessageId =  $messageId.Replace("}","")
    
    $ipString = $row.IP -split "=", 2
    $ipAddress = $ipString[1].Replace("}","")

    $fldrString = $row.FID -split "=", 2
    $folder = $fldrString[1].Replace("}","")

    #Search for the message in the user's mailbox using the Internet Message ID
    try{

        $message = Get-MgUserMessage -UserId $userId -Filter "InternetMessageId eq '$internetMessageId'"
                
        # If the message is found, extract and store the details
        if ($message) {
            $messageDetails = $message | Select-Object -Property Id, Subject, Sender, ReceivedDateTime
            $exportData += [PSCustomObject]@{
                InternetMessageId = $internetMessageId
                FolderPath = $folder
                IP_Address = $ipAddress
                Subject = $messageDetails.Subject
                Sender = $messageDetails.Sender.EmailAddress.Address
                ReceivedDateTime = $messageDetails.ReceivedDateTime
            }
            Write-Host -ForegroundColor Green "Message with InternetMessageId $internetMessageid found for user $userId"
        }
        # If the message is not found, log the information
        else {

            Write-Host -ForegroundColor Red "Message with InternetMessageId $internetMessageId not found for user $userId"
            $failedIMIDData += [pscustomobject]@{
                InternetMessageId = $internetMessageId
                FolderPath = $folder
                IPAddres = $ipAddress
            }
        }
    }
    catch {
    Column1.ClientIPAddress

        Write-Host -ForegroundColor Red "Error retrieving message with InternetMessageId $InternetMessageId"
        return
    }
}
#Output the collected data
$exportData | Format-List


# Export the collected data to a CSV file
$exportData | Export-Csv -Path $exportPath -NoTypeInformation -Force
$failedIMIDData | export-Csv -Path $failedPath -NoTypeInformation -Force