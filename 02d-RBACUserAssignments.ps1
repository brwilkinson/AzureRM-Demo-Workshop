break

# Login-AzureRmAccount

$rgName = 'rgMyFirstRG'
# get all the active assignments for a resource group
Get-AzureRmRoleAssignment -ResourceGroupName $rgName | 
    FL DisplayName, RoleDefinitionName, Scope

# query for user
Get-AzureRmADUser -UserPrincipalName "$user@microsoft.com"

# get all roles assigned to specific user
Get-AzureRmRoleAssignment -SignInName "$user@microsoft.com" | 
    FL DisplayName, RoleDefinitionName, Scope

# grant access to user at the resource group scope
New-AzureRmRoleAssignment -SignInName "$user@microsoft.com" `
    -RoleDefinitionName 'Virtual Machine Contributor' `
    -ResourceGroupName $rgname 

# get all roles assigned to specific user
Get-AzureRmRoleAssignment -SignInName "$user@microsoft.com" | 
    select DisplayName, RoleDefinitionName, Scope

# get scope into a variable
Get-AzureRmRoleAssignment -SignInName "$user@microsoft.com" | 
    select Scope -OutVariable UserScope

# remove user
Remove-AzureRmRoleAssignment  -SignInName "$user@microsoft.com"  `
    -RoleDefinitionName 'Virtual Machine Contributor' `
    -Scope $UserScope[0].scope

