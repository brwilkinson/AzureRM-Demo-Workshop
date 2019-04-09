break
# requires -Module AzureRM.Network
# requires -Module AzureRM.Compute

$Deployment = 'Module5a1'
$RG = ('rg' + $Deployment)
$VNet = ('vn' + $Deployment)
$RDPFileDirectory = 'D:\azure\RDP'

New-VMBuildAzureRM2 -VMName vmFE5a -VNetName $VNet -SubnetName FrontEnd -ResourceGroupName $RG -AddPublicIP

New-VMBuildAzureRM2 -VMName vmMT5a -VNetName $VNet -SubnetName MidTier -ResourceGroupName $RG -AddPublicIP


Get-AzureRmVM -ResourceGroupName $RG | ForEach-Object {
    
    Get-AzureRmRemoteDesktopFile -LocalPath ($RDPFileDirectory + '/' + $_.Name + '.RDP') `
        -ResourceGroupName $RG -Name $_.Name
}
