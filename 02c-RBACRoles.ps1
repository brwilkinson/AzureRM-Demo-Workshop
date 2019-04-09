break
#Requires -Module AzureRM.Resources

# Add-AzureRmAccount

# get a list of AzureRM roles
Get-AzureRmRoleDefinition

# get a list of AzureRM role names
(Get-AzureRmRoleDefinition).Name

# get a list of actions for a role
(Get-AzureRmRoleDefinition "Virtual Machine Contributor").Actions

# get properties for a role
(Get-AzureRmRoleDefinition "Virtual Machine Contributor") | select *

# get a list of non-actions for a role
(Get-AzureRmRoleDefinition "SQL Server Contributor").NotActions

# list operations of Azure resource provider
Get-AzureRMProviderOperation Microsoft.Compute/virtualMachines/*/action | FT Operation, OperationName

# verify an operation string is valid, and to expand wildcard operation strings
Get-AzureRMProviderOperation Microsoft.Compute/virtualMachines/* | select operationname

Get-AzureRMProvider Microsoft.Authorization*