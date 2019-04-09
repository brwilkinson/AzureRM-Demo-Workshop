break

# requires -Module AzureRM.Profile
# requires -Module AzureRM.Network

# IPSEC VPN

$Deployment = 'Module5b1'
$rg = ('rg' + $Deployment)
$location = 'eastus2'

# Create the LocalSite, which defines the Remote Network 
#   (Corporate Network or DataCenter or Other Cloud)
$LocalGatewayParams = @{
     Name              = 'CorpEastUS2NYCDowntown' 
     ResourceGroupName = $rg
     Location          = $location 
     GatewayIpAddress  = '74.68.156.120' 
     AddressPrefix     = @('10.1.10.0/24','10.2.10.0/24','10.3.10.0/24','192.168.1.0/24')
    }
$LocalNetworkGateway = New-AzureRmLocalNetworkGateway @LocalGatewayParams

Get-AzureRmVirtualNetworkGateway -Name ('vng' + $Deployment) -ResourceGroupName $rg -OutVariable vng

# Create the IPSec Connection
$GatewayConnectionParams = @{
     Name                   = 'AzEast2--EastUSNYCDowntown2'
     ResourceGroupName      = $rg
     Location               = $location 
     VirtualNetworkGateway1 = $vng[0] 
     LocalNetworkGateway2   = $LocalNetworkGateway
     ConnectionType         = 'IPsec' 
     #RoutingWeight          = 10
     SharedKey              = 'abc123'
    }
New-AzureRmVirtualNetworkGatewayConnection @GatewayConnectionParams

Get-AzureRmVirtualNetworkGatewayConnection -Name 'AzEast2--EastUSNYCDowntown2' -ResourceGroupName $rg 

# Download the rference Configuration to setup the remote End
# Configurations are available for a large range of VPN Devices

Get-AzureRmVirtualNetworkGatewayConnection -Name 'vngcPSOBJECT--Home' -ResourceGroupName psobject |
    Select ConnectionType,ConnectionStatus,EgressBytesTransferred,IngressBytesTransferred

