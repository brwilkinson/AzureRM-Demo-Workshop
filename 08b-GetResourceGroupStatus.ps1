$RG = 'rgModule7a-001'
$DeploymentName = 'azuredeploy-0906-1853'

# All deployments in the resource group
Get-AzureRmResourceGroupDeployment  -ResourceGroupName $RG

# A specific deployment
Get-AzureRmResourceGroupDeployment  -ResourceGroupName $RG -Name $DeploymentName | select * 


Get-AzureRmResourceGroupDeploymentOperation -ResourceGroupName $Rg -DeploymentName $DeploymentName -ov DP

$DP[0].properties.Request | ConvertTo-Json -Depth 10

$DP[0].operationId


foreach($operation in $DP)
{
    Write-Host $operation.id
    Write-Host "Request:"
    $operation.Properties.Request | ConvertTo-Json -Depth 10
    Write-Host "Response:"
    $operation.Properties.Response | ConvertTo-Json -Depth 10
}