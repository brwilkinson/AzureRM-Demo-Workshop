break
#Requires -Module AzureRM.Resources

# Add-AzureRmAccount


# discover which resourceTypes are available in each region
Get-AzureRMLocation 

# Get the resource providers for a specific location
(Get-AzureRMLocation | Where DisplayName -eq "West US").Providers 

# list which resource providers and apiVersions are available in each region.
Get-AzureRMResourceProvider 

# list regions where resource provider is available
(Get-AzureRMResourceProvider -ProviderNamespace Microsoft.OperationalInsights).Locations

# list the API versions of a resource
(Get-AzureRMResourceProvider -ProviderNamespace Microsoft.Storage).ResourceTypes |
     Where { $_.ResourceTypeName -eq 'storageAccounts' } | 
     Select –ExpandProperty ApiVersions 
 
# list the regions where a particular resource is located
(Get-AzureRMResourceProvider -ProviderNamespace Microsoft.Storage).ResourceTypes | 
    Where { $_.ResourceTypeName -eq 'storageAccounts' } | 
    Select -ExpandProperty Locations 

