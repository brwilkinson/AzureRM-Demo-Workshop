break
#Requires -Module AzureRM.Resources

# Add-AzureRmAccount

$rgName = 'vnettovnetpeering-02'

# get a resource group
Get-AzureRmResourceGroup -Name $rgName -Location "EastUS"

# get a list of resources
(Get-AzureRmResource).name

# get resource name
$resourceName = 'vnBRWDev02-2' 

# retrieve the resource metadata including tags
Get-AzureRmResource -ResourceName $resourceName -ResourceGroupName $rgName

# Use the Tags property to get tag names and values
(Get-AzureRmResource -ResourceName $resourceName -ResourceGroupName $rgName).Tags

# add a tag to a resource group that has no existing tags
Set-AzureRmResourceGroup -Name $rgname -Tag @{ Dept="IT"; Environment="Test" }

# add tags to a resource that has no existing tags 
Set-AzureRmResource -Tag @{ Dept="IT"; Environment="Test" } -ResourceId '/subscriptions/b8f402aa-20f7-4888-b45c-3cf086dad9c3/resourceGroups/VnetToVnetPeering-02'

# get a list of all tags within a subscription
Get-AzureRmTag