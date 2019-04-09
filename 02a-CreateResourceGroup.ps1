break
#Requires -Module AzureRM.Resources

# Add-AzureRmAccount

# Query the existing resource groups. At this point, the list may be empty
Get-AzureRmResourceGroup

# Name of the Resource Group
$ResourceGroupName = "rgDemoRG"

# Location for the Resource Group
$Location = "Central US"

# Create the Resource Group
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location

# Query the existing resource groups again
Get-AzureRmResourceGroup

# get a list of cmdlets in the Resources module with a help synopsis
Get-Command -Module AzureRM.Resources | Get-Help | Format-Table Name, Synopsis