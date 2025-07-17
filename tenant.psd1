@{
    # Northern Computer Master Module - Multi-Tenant Configuration
    # This file contains tenant-specific settings for multiple companies
    
    # Default tenant (for backward compatibility)
    Tenant = "northerncomputer"
    ClientId = "fe14f9e4-a977-402f-8e3a-3e210974a40b"
    
    # Multi-tenant configuration
    # Access via $script:Tenants.<companyName>.ClientId
    # AdminUrl is dynamically constructed as https://{TenantName}-admin.sharepoint.com
    Tenants = @{
        northerncomputer = @{
            TenantName = "northerncomputer"
            ClientId = "fe14f9e4-a977-402f-8e3a-3e210974a40b"
        }
        
        # Add additional tenants here
        # contoso = @{
        #     TenantName = "contoso"
        #     ClientId = "12345678-90ab-cdef-1234-567890abcdef"
        # }
        
        # fabrikam = @{
        #     TenantName = "fabrikam"
        #     ClientId = "87654321-ba09-fedc-4321-fedcba098765"
        # }
    }
}
