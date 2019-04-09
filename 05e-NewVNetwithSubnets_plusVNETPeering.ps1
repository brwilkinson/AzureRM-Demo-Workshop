break

# requires -Module AzureRM.Profile
# requires -Module AzureRM.Network

# from 5a
$Deployment5a = 'Module5a1'
$rg5a = ('rg' + $Deployment5a)
$location = 'eastus2'
#$AddressSpace = '200'

# from 5b
$Deployment5b = 'Module5b1'
$rg5b = ('rg' + $Deployment5b)
$location = 'eastus2'
#$AddressSpace = '201'

# New resourcegroup and VNet 5e
$Deployment5e = 'Module5e1'
$rg5e = ('rg' + $Deployment5e)
$location = 'eastus2'
$AddressSpace5e = '203'

#---------------------------------------------------------------------------------------
# Create Resource Group
New-AzureRmResourceGroup -Name $rg5e -Location $location

# Create VNet
New-AzureRmVirtualNetwork -ResourceGroupName $rg5e -Name ('vn' + $Deployment5e) `
    -AddressPrefix "10.$AddressSpace5e.0.0/16" -Location $location

$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $rg5e -Name ('vn' + $Deployment5e)

# only exist in local variable.
Add-AzureRmVirtualNetworkSubnetConfig -Name FrontEnd -VirtualNetwork $vnet -AddressPrefix "10.$AddressSpace5e.1.0/24"
Add-AzureRmVirtualNetworkSubnetConfig -Name MidTier -VirtualNetwork $vnet -AddressPrefix "10.$AddressSpace5e.2.0/24"
Add-AzureRmVirtualNetworkSubnetConfig -Name BackEnd -VirtualNetwork $vnet -AddressPrefix "10.$AddressSpace5e.3.0/24"


# write the changes to Azure
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet

# Read the updated Vnet information
$vnet = get-AzureRmVirtualNetwork -Name ('vn' + $Deployment5e) -ResourceGroupName $rg5e
$vnet

# This takes about 15 minues to deploy the Virtual Machine, this is a custom function
New-VMBuildAzureRM2 -VMName vmFE5e -VNetName $VNet.Name -SubnetName FrontEnd -ResourceGroupName $RG5e

#---------------------------------------------------------------------------------------

# all commands to interact with VNetPeering.
Get-command -Noun AzureRmVirtualNetworkPeering

# Here are the some of the preview features of the providers, that are available
Get-AzureRmProviderFeature -ListAvailable

# Here are those available to Network
Get-AzureRmProviderFeature -ListAvailable -ProviderNamespace Microsoft.Network

# Since this is in preview it will not be registered by default
Register-AzureRmProviderFeature -FeatureName AllowVnetPeering -ProviderNamespace Microsoft.Network
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Network

#---------------------------------------------------------------------------------------

# Get the two VNETS from the Previous demo 5a and 5b
$vneta = Get-AzureRmVirtualNetwork -ResourceGroupName $rg5a -Name ('vn' + $Deployment5a)
$vnete = Get-AzureRmVirtualNetwork -ResourceGroupName $rg5e -Name ('vn' + $Deployment5e)
$vneta
$vnete

# Peerings go in two directions

# Setup Peering from A to E
Add-AzureRmVirtualNetworkPeering -name "$Deployment5a--$Deployment5e" -VirtualNetwork $vneta `
    -RemoteVirtualNetworkId $vnete.id

# Setup Peering from E to A
$LinktoVNet1 = Add-AzureRmVirtualNetworkPeering -name "$Deployment5e--$Deployment5a" -VirtualNetwork $vnete `
    -RemoteVirtualNetworkId $vneta.id

    <#
    $LinktoVNet1 = Get-AzureRmVirtualNetworkPeering -VirtualNetworkName ('vn' + $Deployment5e) `
                     -ResourceGroupName $rg5e -Name "$Deployment5e--$Deployment5a"
    #>

# Notice the Connection/Peering state and various other settings on the Peerings
$LinktoVNet2 = Get-AzureRmVirtualNetworkPeering -VirtualNetworkName ('vn' + $Deployment5a) `
                     -ResourceGroupName $rg5a -Name "$Deployment5a--$Deployment5e"
$LinktoVNet2


$LinktoVNet2.AllowForwardedTraffic       # Default False
$LinktoVNet2.AllowGatewayTransit         # Default False
$LinktoVNet2.AllowVirtualNetworkAccess   # Default True
$LinktoVNet2.UseRemoteGateways           # Default False

$LinktoVNet2.AllowGatewayTransit   = $true
$LinktoVNet1.UseRemoteGateways     = $true
$LinktoVNet1.AllowForwardedTraffic = $true

Set-AzureRmVirtualNetworkPeering -VirtualNetworkPeering $LinktoVNet2
Set-AzureRmVirtualNetworkPeering -VirtualNetworkPeering $LinktoVNet1

#Cleanup
Remove-AzureRmVirtualNetworkPeering -VirtualNetworkName ('vn' + $Deployment5a) `
    -Name "$Deployment5a--$Deployment5e" -ResourceGroupName $rg5a

Remove-AzureRmVirtualNetworkPeering -VirtualNetworkName ('vn' + $Deployment5e) `
    -Name "$Deployment5e--$Deployment5a" -ResourceGroupName $rg5e

Remove-AzureRmResourceGroup -Name $rg5a

Remove-AzureRmResourceGroup -Name $rg5e