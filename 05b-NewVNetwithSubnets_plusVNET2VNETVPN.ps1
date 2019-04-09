break
# requires -Module AzureRM.Network

$Deployment = 'Module5b1'
$rg = ('rg' + $Deployment)
$location = 'eastus2'
$AddressSpace = '201'

$Deployment5a = 'Module5a1'
$rg5a = ('rg' + $Deployment5a)

# Create Resource Group
New-AzureRmResourceGroup -Name $rg -Location $location

# Create VNet
New-AzureRmVirtualNetwork -ResourceGroupName $rg -Name ('vn' + $Deployment) `
    -AddressPrefix "10.$AddressSpace.0.0/16" -Location $location

$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $rg -Name ('vn' + $Deployment)

# only exist in local variable.
Add-AzureRmVirtualNetworkSubnetConfig -Name FrontEnd -VirtualNetwork $vnet -AddressPrefix "10.$AddressSpace.1.0/24"
Add-AzureRmVirtualNetworkSubnetConfig -Name MidTier -VirtualNetwork $vnet -AddressPrefix "10.$AddressSpace.2.0/24"
Add-AzureRmVirtualNetworkSubnetConfig -Name BackEnd -VirtualNetwork $vnet -AddressPrefix "10.$AddressSpace.3.0/24"
Add-AzureRmVirtualNetworkSubnetConfig -Name GatewaySubnet -VirtualNetwork $vnet -AddressPrefix "10.$AddressSpace.255.0/24"

# write the changes to Azure
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet

# Read the updated Vnet information
$vnet = get-AzureRmVirtualNetwork -Name ('vn' + $Deployment) -ResourceGroupName $rg

# Create a Public IP dynamically assigned, for the Gateway Connection IP
$gwip = New-AzureRmPublicIpAddress -Name ('PublicIP_vng' + $Deployment) -ResourceGroupName $rg `
            -Location $location -AllocationMethod Dynamic

# Get the reference to the Gateway Subnet
$gwsubnet   = Get-AzureRmVirtualNetworkSubnetConfig -Name GatewaySubnet -VirtualNetwork $vnet

# set the relationship between the PublicIP and the Gateway
$gwipconf = New-AzureRmVirtualNetworkGatewayIpConfig -Name ('vngip' + $Deployment) -Subnet $gwsubnet -PublicIpAddress $gwip

# Create the Gateway, this operation creates a highly available gateway, takes around 25 minutes
New-AzureRmVirtualNetworkGateway -Name ('vng' + $Deployment) -ResourceGroupName $rg -Location $location `
    -IpConfigurations $gwipconf -GatewayType Vpn -VpnType RouteBased -GatewaySku Standard

Get-AzureRmVirtualNetworkGateway -Name ('vng' + $Deployment) -ResourceGroupName $rg -OutVariable vng

# Execute up to here in 5A
# Then create the Virtual Machines

#---------------------------------------------------------------------------------------------------

Get-AzureRmVirtualNetworkGateway -Name ('vng' + 'Module5a1') -ResourceGroupName $rg5a -OutVariable vngremote
Get-AzureRmVirtualNetworkGateway -Name ('vng' + $Deployment) -ResourceGroupName $rg -OutVariable vng

# Create the new gateway connection
New-AzureRmVirtualNetworkGatewayConnection -ConnectionType Vnet2Vnet -Location $location `
-Name ('vngc' + $Deployment5a + "--$Deployment") -ResourceGroupName $rg5a -VirtualNetworkGateway1 $vngremote[0] `
-VirtualNetworkGateway2 $vng[0] -SharedKey 'honeyoatsforlunch'

Get-AzureRmVirtualNetworkGatewayConnection -Name ('vngc' + $Deployment5a + "--$Deployment") -ResourceGroupName $rg5a

# in both directions (on both ends)
New-AzureRmVirtualNetworkGatewayConnection -ConnectionType Vnet2Vnet -Location $location `
-Name ('vngc' + $Deployment + "--$Deployment5a") -ResourceGroupName $rg -VirtualNetworkGateway1 $vng[0] `
-VirtualNetworkGateway2 $vngremote[0] -SharedKey 'honeyoatsforlunch'

Get-AzureRmVirtualNetworkGatewayConnection -Name ('vngc' + $Deployment + "--$Deployment5a") -ResourceGroupName $rg

# Confirm the connection is up.
# Now the gateway connections are up, perform connectivity tests again.


#--------------------------------------------------------------------------------------------------

# Cleanup the Connections, Later we will connect these two VNETS a different way.

Remove-AzureRmVirtualNetworkGatewayConnection -Name ('vngc' + $Deployment5a + "--$Deployment") -ResourceGroupName $rg5a -Force

Remove-AzureRmVirtualNetworkGatewayConnection -Name ('vngc' + $Deployment + "--$Deployment5a") -ResourceGroupName $rg -Force