class SiteManager {

    # Define the properties of the class
    [string]$tenant
    [string]$tenantId
    [string]$adminUrl
    [string]$rootUrl
    [string]$urlEnding
    [string]$siteName
    [string]$clientId
    [string]$hubSiteUrl
    [string]$hubSiteId
    [array]$owners
    [array]$nodesToRemove
    [hashtable]$documentLibraries
    [hashtable]$features
    [object]$connection 

    #Default constructor
    SiteManager() {
        
        this.Init(@{})
    }

    #Convenience constructor
    SiteManager([hashtable]$properties) {

        $this.Init($properties)
    }

    #Common constructor for Site Url
    SiteManager([string]$rootUrl, [string]$urlEnding) {

        $this.Init(@{
            siteUrl = "$($this.rootUrl)/$($this.urlEnding)"
        })
    }

    # Shared Initializer Method
    <# This method is used to initialize the properties of the class. #>
    [void] Init([hashtable]$properties) {

        # Initialize properties from the hashtable
        foreach ($key in $properties.Keys) {

            if($this.PSObject.Properties.Match($key)) {

                $this.$key = $properties[$key]
            }
            else {
                Write-Warning "Property $key does not exist in SiteManager class and will be ignored."
            }
        }
    }

    # Method to Create a new Site 
    # This method creates a new SharePoint site using the provided site name, URL, and client name.
    # It checks if the site already exists and creates it if not.
    # It returns a custom object containing the site manager instance and the created site object.
    # It also handles retries in case of failure.
    [PSCustomObject] CreateNewSite() {

        # Initialize the variables
        $site = $null

        # Logic to create a new site
        try {
            
            Write-Host "Creating new site: $($this.siteName) at $($this.siteUrl)"

            if($null -eq $this.adminUrl -or $null -eq $this.clientId) {
    
                if($null -eq $this.adminUrl) {
    
                    Throw "Admin URL is not set. Cannot create site."
                    return $null
                }
                if($null -eq $this.clientId) {
    
                    Throw "Client ID is not set. Cannot create site."
                    return $null
                }
            }
            else {
                
                Write-Host "Admin URL is set to: $($this.adminUrl)"
                Write-Host ""   #For Readability

                # Check for site creation
                Write-Host -ForegroundColor Blue "Connecting to SharePoint Admin Center"
                Write-Host "Checking to see if the site has already been created :: " -NoNewline
                $this.connection = Connect-PnpOnline -Url $this.adminUrl -ClientId $this.clientId -Interactive -ReturnConnection
            }
        }
        catch {
           
            Write-Host "Error creating site URL: $_"
            return $null
        }

        # Check if the site already exists       
        try {
            $siteExists = Get-PnPTenantSite -Url $this.siteUrl -Connection $this.connection -ErrorAction SilentlyContinue
        }
        catch {
            Write-Host "Error checking site existence: $_"
            return $null
        }

        if ($siteExists) {

            # Site already exists, return the existing site object
            Write-Host "Site already exists: $($this.siteUrl)"
            return [PSCustomObject]@{

                SiteManagerInstance = $this
                SiteObject = $siteExists
            }
        }
        else {

            [int]$maxAttempts = 5
            [int]$attempt = 0
            $siteCreated = $false

            do {

                try {                                  
                    # Create the site
                    Write-Host -ForegroundColor Yellow "Site not created yet"
                    Start-Sleep -Seconds 1
                    Write-Host -ForegroundColor Yellow "Creating Client's Site...."
                    $site = New-PnPSite -Connection $this.connection -Type TeamSite -Title $this.clientName -Alias $this.siteUrl -IsPublic $true -Lcid 1033 -Owners $this.owners -Wait -ErrorAction Stop
                    Write-Host -ForegroundColor Green "Site created successfully: $($this.siteUrl)"

                    # Pause for effect
                    Start-Sleep -Seconds 6

                    $siteCreated = $true # Set to true if site creation is successful
                } 
                catch {

                    Write-Host -ForegroundColor Red "Error creating site: $_"
                    $attempt++ # Increment the attempt counter
                    Write-Host -ForegroundColor Yellow "Retrying in 5 seconds... Retry #$($attempt) of $($maxAttempts)"
                    Start-Sleep -Seconds 5 # Wait before retrying
                }
                
            }
            until (
                $siteCreated -or $attempt -ge $maxAttempts # Break the loop if site is created or max attempts reached
            )

            return [PSCustomObject]@{
                SiteManagerInstance = $this
                SiteObject = $site
            }
        }

    }

    #Method to get the site collection features
    # This method retrieves the site collection features for a given site URL.
    # It takes the site URL and an optional collection of existing features.
    # It returns a custom object containing the site manager instance and the collection of features.
    # It also handles retries in case of failure.
    [PSCustomObject] GetSiteCollectionFeatures() {

        # Initialize connection variable and connect to the SharePoint site
        $enabledFeatures = $null
        Connect-PnpOnline -Connection $this.connection -Url $this.siteUrl

        # Logic to get site collection features
        Write-Host -ForegroundColor Yellow "Getting site collection features for: $($this.siteUrl)"
        Start-Sleep -Seconds 1

        $enabledFeatures = Get-PnPFeature -Connection $this.connection -Url $($this.siteUrl) -Scope Site 

        return [PSCustomObject]@{
            SiteManagerInstance = $this
            collectionFeatures = $enabledFeatures | Select-Object -Property @{Name='FeatureId';Expression={$_.Id}}, @{Name='FeatureName';Expression={$_.DisplayName}}, @{Name='Enabled';Expression={$_.IsEnabled}}, @{Name='Scope';Expression={$_.Scope}}, @{Name='Url';Expression={$_.Url}}
        }
    }

    # Method to set turn on Site Collection Features
    # This method enables the specified site collection features for a given site URL.
    # It takes the site URL, a hashtable of features to enable, and an optional collection of existing features.
    # It returns a custom object containing the site manager instance.
    # It also handles retries in case of failure.
    [PSCustomObject] SetSiteCollectionFeatures([object]$collectionFeatures = $null) {

        # Initialize connection variable and connect to the SharePoint site
        Connect-PnpOnline -Connection $this.connection -Url $this.siteUrl
 
        # If collection features are not provided, call GetSiteCollectionFeatures
        if ($null -eq $collectionFeatures) {

            $result = $this.GetSiteCollectionFeatures()
            $collectionFeatures = $result.CollectionFeatures
        }
        
        # Logic to set site collection features
        Write-Host -ForegroundColor Yellow "Setting site collection features for: $($this.siteUrl)"
        Start-Sleep -Seconds 
        foreach($feature in $this.features){
            
            $featureEnabled = $collectionFeatures | Where-Object { $_.FeatureId -eq $feature.ident } | Select-Object -First 1
            if( $featureEnabled.Enabled){

                Write-Host -ForegroundColor Green "Feature already enabled: $($feature.name)"
                return $null

            }
            else{

                #Initialiaze the attempt counter
                [int]$maxAttempts = 5
                [int]$attempts = 0
                [bool]$isEnabled = $false

                # Enable the feature
                Write-Host -ForegroundColor Yellow "Enabling feature: $($feature.name)"
                Start-Sleep -Seconds 1
                
                while (($isEnabled -eq $false) -and ($attempts -lt $maxAttempts)){

                    try {
                        
                        # Attempt to enable the feature
                        Enable-PnPFeature -Connection $this.connection  -Identity $feature.ident -Scope Site -Confirm:$false
                        Write-Host -ForegroundColor Green "Feature $($feature.name) enabled successfully!"
                        $isEnabled = $true # Set to true if feature enabling is successful
                    }
                    catch {

                        Write-Host -ForegroundColor Red "Error enabling feature: $_"
                        $attempts++ # Increment the attempt counter
                        Write-Host -ForegroundColor Yellow "Retrying in 5 seconds... Retry #$($attempts) of $($maxAttempts)"
                        Start-Sleep -Seconds 5 # Wait before retrying
                    }
                }
            }

        }

        return [object]$this
    }

    # Method to get the Quick Launch nodes
    # This method retrieves the Quick Launch nodes for a given site URL.
    # It takes the site URL and an optional collection of existing Quick Launch nodes.
    # It returns a custom object containing the Quick Launch nodes.
    # It also handles retries in case of failure.
    [PSCustomObject] GetQuickLaunchItems(){

        # Initialize connection variable and connect to the SharePoint site
        $quickLaunchNodes = $null
        Connect-PnpOnline -Connection $this.connection -Url $this.siteUrl

        # Logic to get Quick Launch items
        Write-Host -ForegroundColor Yellow "Getting Quick Launch items for: $($this.siteUrl)"
        Start-Sleep -Seconds 1

        #Initialiaze the attempt counter
        [int]$maxAttempts = 5
        [int]$attempts = 0
        [bool]$isEnabled = $false
        
        while ($attempts -lt $maxAttempts) {

            try {
                
                # Attempt to get the Quick Launch nodes
                Write-Host -ForegroundColor Yellow "Getting Quick Launch items..."
                Start-Sleep -Seconds 1
                $quickLaunchNodes = Get-PnPQuickLaunchNode -Connection $this.connection 
                Write-Host -ForegroundColor Green "Quick Launch items retrieved successfully!"
                $isEnabled = $true # Set to true if retrieval is successful
            }
            catch {
                
                Write-Host -ForegroundColor Red "Error getting Quick Launch items: $_"
                $attempts++ # Increment the attempt counter
                Write-Host -ForegroundColor Yellow "Retrying in 5 seconds... Retry #$($attempts) of $($maxAttempts)"
                Start-Sleep -Seconds 5 # Wait before retrying
            }   
        }    

        return [PSCustomObject]@{
            SiteManagerInstance = $this
            QuickLaunchNodes = $quickLaunchNodes
        }
    }

    # Method to remove default Quick Launch nodes
    # This method removes the default Quick Launch nodes for a given site URL.
    # It takes the site URL and an optional collection of existing Quick Launch nodes.
    # It also handles retries in case of failure.
    [PSCustomObject] RemoveDefaultQuickLaunchNodes([object]$quickLaunchNodes = $null){
            
        # Initialize connection variable and connect to the SharePoint site
        [string]$notebookUrl = $null
        [string]$notebookTitle = $null
        Connect-PnpOnline -Connection $this.connection -Url $this.siteUrl

        # Logic to set Quick Launch items
        Write-Host -ForegroundColor Yellow "Setting Quick Launch items for: $($this.siteUrl)"
        Start-Sleep -Seconds 1

        # If collection features are not provided, call GetSiteCollectionFeatures
        if ($null -eq $quickLaunchNodes) {

            $result = $this.GetQUickLaunchItems()
            $quickLaunchNodes = $result.QuickLaunchItems
        }
    
            foreach($node in $quickLaunchNodes){

                #Initialiaze the attempt counter
                [int]$maxAttempts = 5
                [int]$attempts = 0
                [bool]$isEnabled = $false
        
                if($this.nodesToRemove -contains $node.Title){

                    if ("Notebook" -eq $Node.Title) {

                        $notebookUrl = $Node.Url
                        $notebookTitle = $Node.Title
                    }

                    while ($attempts -lt $maxAttempts) {

                        try {
                            
                            # Attempt to get the Quick Launch nodes
                            Write-Host -ForegroundColor Yellow "Getting Quick Launch items..."
                            Start-Sleep -Seconds 1

                            Remove-PnPNavigationNode -Connection $this.connection -Identity $node.Id -ErrorAction Stop

                            Write-Host -ForegroundColor Green "Quick Launch items retrieved successfully!"
                            $isEnabled = $true # Set to true if retrieval is successful
                        }
                        catch {
                            
                            Write-Host -ForegroundColor Red "Error getting Quick Launch items: $_"
                            $attempts++ # Increment the attempt counter

                            Write-Host -ForegroundColor Yellow "Retrying in 5 seconds... Retry #$($attempts) of $($maxAttempts)"
                            Start-Sleep -Seconds 5 # Wait before retrying
                        }   
                    }

                }            
            }
    
            return [object]$this
    }

    [PSCustomObject] AddQuickLaunchNodes([object]$nodesToAdd = $null){

        # Initialize connection variable and connect to the SharePoint site
        Connect-PnpOnline -Connection $this.connection -Url $this.siteUrl

        # Logic to set Quick Launch items
        Write-Host -ForegroundColor Yellow "Setting Quick Launch items for: $($this.siteUrl)"
        Start-Sleep -Seconds 1

        # If collection features are not provided, call GetSiteCollectionFeatures
        if ($null -eq $nodesToAdd) {

            $result = $this.GetQuickLaunchItems()
            $nodesToAdd = $result.QuickLaunchItems
        }

        foreach($node in $nodesToAdd){

            #Initialiaze the attempt counter
            [int]$maxAttempts = 5
            [int]$attempts = 0
            [bool]$isEnabled = $false

            while ($attempts -lt $maxAttempts) {

                try {
                    
                    # Attempt to get the Quick Launch nodes
                    Write-Host -ForegroundColor Yellow "Getting Quick Launch items..."
                    Start-Sleep -Seconds 1

                    Add-PnPNavigationNode -Connection $this.connection -Title $node.Title -Url $node.Url -ParentNodeId $node.ParentNodeId -ErrorAction Stop

                    Write-Host -ForegroundColor Green "Quick Launch items retrieved successfully!"
                    $isEnabled = $true # Set to true if retrieval is successful
                }
                catch {
                    
                    Write-Host -ForegroundColor Red "Error getting Quick Launch items: $_"
                    $attempts++ # Increment the attempt counter

                    Write-Host -ForegroundColor Yellow "Retrying in 5 seconds... Retry #$($attempts) of $($maxAttempts)"
                    Start-Sleep -Seconds 5 # Wait before retrying
                }   
            }

        }

        return [object]$this
    }

    [PSCustomObject] CreateDocumentLibraries(){

        [hashtable]$libraryDetailsHash = $null
        
        # Initialize connection variable and connect to the SharePoint site
        Connect-PnpOnline -Connection $this.connection -Url $this.siteUrl

        # Logic to set Quick Launch items
        Write-Host -ForegroundColor Yellow "Setting Quick Launch items for: $($this.siteUrl)"
        Start-Sleep -Seconds 1

        foreach($library in $this.documentLibraries){

            [string]$libraryName = $library.Name
            [string]$libraryUrl = $library.Url
            [string]$licensingServerRelativeUrl = $null
            [object]$newLibrary = $null
            [pscustomobject]$libraryDetails = $null
            

            #Initialiaze the attempt counter
            [int]$maxAttempts = 5
            [int]$attempts = 0
            [bool]$isCreated = $false

            while ($attempts -lt $maxAttempts) {

                try {
                    
                    # Attempt to get the Quick Launch nodes
                    Write-Host -ForegroundColor Yellow "Getting Quick Launch items..."
                    Start-Sleep -Seconds 1

                    $newLibrary = New-PnPList -Connection $this.connection -Title $libraryName -Url $libraryUrl -Template DocumentLibrary -OnQuickLaunch -EnableContentTypes 
                    $licensingServerRelativeUrl = "$($this.LibraryRootUrl)$($newLibrary.RootFolder.ServerRelativeUrl)"

                    # Add the library details to the hashtable
                    if ($null -eq $libraryDetailsHash -or $libraryDetailsHash.Count -eq 0) {

                        $libraryDetailsHash = @{} # Initialize the hashtable if it's null
                    }

                    $libraryDetails = [pscustomobject]@{

                        LibraryName = $libraryName
                        LibraryUrl = $libraryUrl
                        LicensingServerRelativeUrl = $licensingServerRelativeUrl
                    }
                    $libraryDetailsHash.Add($libraryName, $libraryDetails)

                    Write-Host -ForegroundColor Green "Document library created successfully: $($libraryName)"
                    Write-Host -ForegroundColor Green "Document library URL: $($libraryUrl)"
                    Write-Host -ForegroundColor Green "Document library Licensing Server Relative URL: $($licensingServerRelativeUrl)"
                    $isCreated = $true # Set to true if retrieval is successful

                }
                catch {
                    
                    Write-Host -ForegroundColor Red "Error getting Quick Launch items: $_"
                    $attempts++ # Increment the attempt counter

                    Write-Host -ForegroundColor Yellow "Retrying in 5 seconds... Retry #$($attempts) of $($maxAttempts)"
                    Start-Sleep -Seconds 5 # Wait before retrying
                }   
            }

        }

        return [psCustomObject]@{
            SiteManagerInstance = $this
            DocumentLibraryDetails = $libraryDetailsHash
        }
    }

    [pscustomobject] AddDocumentLibraryTaxonomy([string]$libraryName, [string]$displayName, [string]$termPath){

        # Initialize connection variable and connect to the SharePoint site
        Connect-PnpOnline -Connection $this.connection -Url $this.siteUrl

        $libraryDetailsHash = $null
        Write-Host -ForegroundColor Yellow "Setting Quick Launch items for: $($this.siteUrl)"
        Start-Sleep -Seconds 1

        #Initialiaze the attempt counter
        [int]$maxAttempts = 5
        [int]$attempts = 0
        [bool]$isAdded = $false

        while ($attempts -lt $maxAttempts -or $isAdded -eq $false) {

            try {
                
                # Attempt to get the Quick Launch nodes
                Write-Host -ForegroundColor Yellow "Adding field..."
                Start-Sleep -Seconds 1

                Add-PnPTaxonomyField -Connection $this.connection -List $libraryName -DisplayName $displayName -InternalName "$($Libraryname)$($displayName)" -TermSetPath "$($libraryName)|$($termPath)" -AddToDefaultView | Out-Null
                Write-Host -ForegroundColor Green "_Term"
                Write-Host "" #For Readability
        
                $isAdded = $true # Set to true if retrieval is successful

            }
            catch {
                
                Write-Host -ForegroundColor Red "Error getting Quick Launch items: $_"
                $attempts++ # Increment the attempt counter

                Write-Host -ForegroundColor Yellow "Retrying in 5 seconds... Retry #$($attempts) of $($maxAttempts)"
                Start-Sleep -Seconds 5 # Wait before retrying
            }   
        }

        return [psCustomObject]@{
            SiteManagerInstance = $this
            DocumentLibraryDetails = $libraryDetailsHash
        }

    }



}