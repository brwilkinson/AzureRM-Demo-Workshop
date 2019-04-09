break

get-module -ListAvailable
$env:PSModulePath -split ";"

# install latest ARM modules
Install-module AzureRM # -Force

# if already installed make sure to update
Update-Module Azure* -Force

# Listing Modules
Get-Module -Name Azure* -ListAvailable 

# Finding Cmdlets
Get-Command -Module AzureRM.Resources 

# ARM: 
Get-Module -Name "*Azure*" | % { Get-Command -Module $_.Name } 
get-command -module azure* | Group-object Noun | Sort-Object Name | Format-Table Count, Name

# verify the modules have been installed
Get-Module –ListAvailable –Name AzureRM*

# Import a single AzureRM module 
Import-Module AzureRM.Compute 

# explore some additional tools
Start-Process 'https://azure.microsoft.com/en-us/downloads/'