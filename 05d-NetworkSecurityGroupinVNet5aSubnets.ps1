break

# requires -Module AzureRM.Profile
# requires -Module AzureRM.Network

$Deployment = 'Module5a1'
$rg = ('rg' + $Deployment)
$location = 'EastUS2'

$DenyRule = @{
    Name                     = 'deny-rule' # Unique per region
    Description              = 'Deny All'  # Description
    Access                   = 'Deny'      # Allow | Deny
    Protocol                 = '*'         # TCP | UDP | *
    Direction                = 'Inbound'   # Inbound | Outbound
    Priority                 = 3000        # 100 - 4096
    SourcePortRange          = '*'         # Integer between 0 - 65535 | Range between 0 and 65535 | *
    SourceAddressPrefix      = '*'         # VirtualNetwork | AzureLoadBalancer | Internet | * | CIDR | IP Range
    DestinationPortRange     = '*'         # Integer between 0 - 65535 | Range between 0 and 65535 | *
    DestinationAddressPrefix = '*'         # VirtualNetwork | AzureLoadBalancer | Internet | * | CIDR | IP Range
   }

$Params = @{
    Location           = $Location 
    Name               = ('nsg_' + $Location + $Deployment) 
    ResourceGroupName  = $rg
    SecurityRules      = @( $DenyRule )
   }

$nsg = New-AzureRmNetworkSecurityGroup @Params
 # $nsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $rg -Name ('nsg_' + $Location + $Deployment)

# *Note we created the rule, however have not applied it to the VNet

# Get the VNet where we want to apply it
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $rg -Name ('vn' + $Deployment)

# Set the NSG on the MidTier Subnet (in memory/variable $vnet)
$MidTierSubnetConfig = @{
     VirtualNetwork = $vnet; Name = 'MidTier'; 
     AddressPrefix = '10.200.2.0/24'; NetworkSecurityGroup = $nsg
    }
Set-AzureRmVirtualNetworkSubnetConfig @MidTierSubnetConfig

# Apply the new subnet config with the nsg attached
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet

<#

Set-AzureRmVirtualNetworkSubnetConfig -Name frontendSubnet -VirtualNetwork $virtualNetwork `
    -AddressPrefix "10.0.1.0/24" -NetworkSecurityGroup $networkSecurityGroup

$virtualNetwork | Set-AzureRmVirtualNetwork
#>

# * Now test connectivity again.

# Now set some allow rules
#----------------------------------------

$Rule1Params = @{
    Name                     = 'WSMAN-rule'
    Description              = 'Allow WSMAN'
    Access                   = 'Allow'
    Protocol                 = 'Tcp'
    Direction                = 'Inbound'
    Priority                 = 200
    SourcePortRange          = '*'
    SourceAddressPrefix      = '10.200.0.0/16'
    DestinationPortRange     = 5985
    DestinationAddressPrefix = '*'
   }

$Rule2Params = @{
    Name                     = 'SMB-rule'
    Description              = 'Allow SMB'
    Access                   = 'Allow'
    Protocol                 = 'Tcp'
    Direction                = 'Inbound'
    Priority                 = 201
    SourcePortRange          = '*'
    SourceAddressPrefix      = '10.200.0.0/16'
    DestinationPortRange     = 445
    DestinationAddressPrefix = '*'
   }

Get-AzureRmNetworkSecurityGroup -ResourceGroupName $rg -Name ('nsg_' + $Location + $Deployment) | 
 Add-AzureRmNetworkSecurityRuleConfig @Rule1Params | 
 Add-AzureRmNetworkSecurityRuleConfig @Rule2Params | 
 Set-AzureRmNetworkSecurityGroup


# Now Cleanup
#----------------------------------------
# Remove the NSG from the Subnet
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $rg -Name ('vn' + $Deployment)
$vnet.Subnets | where Name -eq MidTier | ForEach-Object { $_.NetworkSecurityGroup = $null }
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet

# Remove the NSG
Get-AzureRmNetworkSecurityGroup -ResourceGroupName $rg -Name ('nsg_' + $Location + $Deployment) |
    Remove-AzureRmNetworkSecurityGroup