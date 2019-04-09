$rg = 'rgModule7c-001'
$path = '.\exports'

# -------------------------------------------------------------------------------
# You can export any resource group

Export-AzureRmResourceGroup -ResourceGroupName $rg -IncludeComments -IncludeParameterDefaultValue -Path $path -OV Template1

code $Template1.Path


# -------------------------------------------------------------------------------
# You can export any previous deployment

Get-AzureRmResourceGroupDeployment -ResourceGroupName $rg -OutVariable deployments

$deployments.count

$dpname = $deployments[-1].DeploymentName

Save-AzureRmResourceGroupDeploymentTemplate -ResourceGroupName $rg -DeploymentName $dpname -Path $path -OV Template2

code $Template2.Path

# * Note the differences between the templates, it's a superior experience saving from a Deployment