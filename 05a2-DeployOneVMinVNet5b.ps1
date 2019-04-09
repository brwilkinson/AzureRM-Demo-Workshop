#break
# requires -Module AzureRM.Network
# requires -Module AzureRM.Compute

$Deployment = 'Module5b1'
$RG = ('rg' + $Deployment)
$VNet = ('vn' + $Deployment)
$RDPFileDirectory = 'D:\azure\RDP'

New-VMBuildAzureRM2 -VMName vmFE5b -VNetName $VNet -SubnetName FrontEnd -ResourceGroupName $RG -AddPublicIP


Get-AzureRmVM -ResourceGroupName $RG | ForEach-Object {
    
    Write-Warning $_.Name
    Get-AzureRmRemoteDesktopFile -ResourceGroupName $RG -Name $_.Name -LocalPath ($RDPFileDirectory + '/' + $_.Name + '.RDP')
        
}


