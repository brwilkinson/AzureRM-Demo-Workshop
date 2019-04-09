break
# requires -Module AzureRM.Network
# requires -Module AzureRM.Compute

# Create 2 Virtual Machines for adding to bitlocker.
# Only need 1 VM, however deploy 2 just in case

$Deployment = 'Module3c'
$RG = ('rg' + $Deployment)
$VNet = ('vn' + $Deployment)

New-VMBuildAzureRM2 -VMName vmBitlocker1,vmBitlocker2 -VNetName $VNet -SubnetName FrontEnd -ResourceGroupName $RG

