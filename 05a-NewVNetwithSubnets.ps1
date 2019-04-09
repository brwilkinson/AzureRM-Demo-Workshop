break

# requires -Module AzureRM.Profile
# requires -Module AzureRM.Network

$Deployment = 'Module5a1'
$rg = ('rg' + $Deployment)
$location = 'eastus2'
$AddressSpace = '200'

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
$gwipconf = New-AzureRmVirtualNetworkGatewayIpConfig -Name ('vngip' + $Deployment) `
                -Subnet $gwsubnet -PublicIpAddress $gwip

# Kick off the 2nd VNet, including the VNG
# Kick off the Virtual Machine build in a
# Kick off the Virtual Machine build in b
# Kick of the Gateway Creation in both a and b

# Create the Gateway, this operation creates a highly available gateway, takes around 25 minutes
New-AzureRmVirtualNetworkGateway -Name ('vng' + $Deployment) -ResourceGroupName $rg -Location $location `
    -IpConfigurations $gwipconf -GatewayType Vpn -VpnType RouteBased -GatewaySku Standard

Get-AzureRmVirtualNetworkGateway -Name ('vng' + $Deployment) -ResourceGroupName $rg -OutVariable vng

#---------------------------------------------------------------------------------------------------

