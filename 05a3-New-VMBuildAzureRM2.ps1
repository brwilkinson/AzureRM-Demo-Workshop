
<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
    New-VMBuildAzureRM2 -VMName MS1,MS2
.EXAMPLE
    New-VMBuildAzureRM2 -VMName MS1,MS2 -Environment Prod -Prefix WEB
.EXAMPLE
     New-VMBuildAzureRM2 -VMName MS1,MS2 -Environment Dev -DeployIndex 02
.EXAMPLE
   New-VMBuildAzureRM2 -VMName WorkGroup02 -Environment Test -Prefix BRW -DeployIndex 01 `
    -VNetName vnDev505 -SubnetName FrontEnd -ResourceGroupName rgDev505 -Verbose
.EXAMPLE
   New-VMBuildAzureRM2 -VMName WorkGroup01,WorkGroup02 -Environment Test -Prefix BRW -DeployIndex 01 `
    -VNetName vnDev505 -SubnetName FrontEnd -ResourceGroupName rgDev505 -Verbose
.EXAMPLE
   New-VMBuildAzureRM2 -DeployIndex 2 -VMName MS-01,MS-02 -SNAddressPrefix 10.100.1.0/24 -AddGatway
.EXAMPLE
   New-VMBuildAzureRM2 -DeployIndex 22 -VMName MS1,MS2 -Prefix XYZ -AddLoadBalancer
#>

function New-VMBuildAzureRM2
{
    [CmdletBinding()]
    Param
    (
        # Choose the VirtualMachine Name
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [String[]]$VMName,

        # Local Admin user *See note inline about using KeyVault for password
        [String]$LocalAdminUser = 'BRW',

        # Choose the Environment Name
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [validateSet('Dev','QA','Prod','Test')]
        [String]$Environment = 'Dev',

        # Choose the Prefix name
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [String]$Prefix = 'BRW',

        # Choose the Index for the Deployment
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=3)]
        [ValidateRange(01,999)]
        [Int]$DeployIndex = '10',

        # Choose the VNET name for the Virtual Machine
        [Parameter(Mandatory=$false)]
        [String]$VNetName,

        [String]$AvailabilitySetName,

        # Choose the VNET Address Prefix
        [String]$VNetAddressPrefix = '10.100.0.0/16',
        
        # Choose the VNET Subnet Address Prefix
        #[Parameter(Mandatory=$true)]
        [String]$SNAddressPrefix = '10.100.100.0/24',

        # Choose the Subnet name for the Virtual Machine
        [Parameter(Mandatory=$false)]
        [validateset('FrontEnd','MidTier','BackEnd','GatewaySubnet')]
        [String]$SubnetName = 'FrontEnd',

        # Choose to add a gateway for the VNet
        [Parameter()]
        [Switch]$AddGatway,

        # Choose to add a LoadBalancer for the VNet
        [Parameter()]
        [Switch]$AddLoadBalancer,

        # When using a LoadBalancer a NAT Rule is automatically generated to 
        # Forward the RDP port to all VM's behind the load balancer
        [Int32]$RDPStartPort = 50000,

        # Choose to add a PublicIP for the VM
        [Parameter()]
        [Switch]$AddPublicIP,

        # Choose the StorageAccount Name that you wish to add the VirtualMachine
        # Should be all lower case
        [Parameter(Mandatory=$false)]
        [String]$StorageAccountName,

        # Choose the ResourceGroup Name that you wish to add the VirtualMachine
        [Parameter(Mandatory=$false)]
        [String]$ResourceGroupName,

        # Choose the Instance Size of the Virtual Machine
        [ValidateSet('ExtraSmall','Small','Medium','Large')]
        [String]$VMInstanceSize = 'Small',

        # Choose the Subscription that you wish to add the VirtualMachine
        [ValidateSet('MSFT','MSDN')]
        [String]$Subscription = 'MSFT',

        # Choose the Location that you wish to add the VirtualMachine
        [ValidateSet('EASTUS2','EASTUS')]
        [String]$Location = 'EastUS2',

        # Choose the StorageType Name that you wish to add the VirtualMachine
        [ValidateSet('Standard_GRS','Standard_LRS')]
        [String]$StorageType = 'Standard_LRS',

        # Choose the Windows Image for the VirtualMachine
        [ValidateSet('2008-R2-SP1','2012-Datacenter','2012-R2-Datacenter','2016-Nano-Docker-Test',
                        '2016-Nano-Server-Technical-Preview','2016-Nano-Server-Technical-Preview-with-Containers',
                        '2016-Technical-Preview-with-Containers','Windows-Server-Technical-Preview')]
        [String]$WindowsImage = '2012-R2-Datacenter',
        [String]$TimeZone = [System.TimeZoneInfo]::Local.Id,

        [Switch]$BootStrapDSCPull,

        [Switch]$BootStrapDSCPushConfigName
    )

    Begin
    {   
        $PSBoundParameters
        
        $Deployment = $Prefix.toUpper() + $Environment.toUpper() + $DeployIndex.ToString().PadLeft(3,'0')
        Write-Verbose -Message "Deployment: $Deployment"
        
        #region Subscription
        Try {
            Set-Azure -Account $Subscription -ErrorAction Stop
        }
        Catch {

            Write-Warning -Message "You must login to your Azure Subscription first, try Login-AzureRMAccount"
        }
        #endregion
        #region Resource Group
        try {
            if (! $PSBoundParameters['ResourceGroupName'])
            {
                $ResourceGroupName =  'rg' + $Deployment
            }
            else
            {
                $Deployment = $ResourceGroupName.Trim('rg')
            }

            $ResourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction Stop
        }
        Catch {
            Write-Warning $_
            Write-Warning "Creating resource group: $ResourceGroupName"
            $ResourceGroup = New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location
        }#Catch
        #endregion
        #region StorageAccount
        Try {
            if (! $PSBoundParameters['StorageAccountName'])
            {
                $StorageAccountName = ( 'sa' + $Deployment ).ToLower()
                Write-Verbose "New Storage Account Name: $StorageAccountName"
            }

            $StorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name ($StorageAccountName).tolower() -ErrorAction Stop
        }
        Catch {   
            Write-Warning $_
            Write-Warning "Creating storage account: $StorageAccountName"
            $StorageAccountParams = @{
                ResourceGroupName = $ResourceGroupName 
                Name              = ( $StorageAccountName ).ToLower()
                Type              = $StorageType 
                Location          = $Location
                }
            $StorageAccount = New-AzureRmStorageAccount @StorageAccountParams
        }#Catch

        $VHDPath = $StorageAccount.PrimaryEndpoints.Blob + 'vhds/'

        #endregion
        #region VM Windows Image
        $Publisher = Get-AzureRmVMImagePublisher -Location $Location | where PublisherName -EQ MicrosoftWindowsServer
        
        $Offer = Get-AzureRmVMImageOffer -Location $Location -PublisherName $Publisher.PublisherName
        
        $MySKU = Get-AzureRmVMImageSku  -Location $Location -PublisherName $Publisher.PublisherName -Offer $Offer.Offer | 
                   Where Skus -EQ $WindowsImage | Foreach Skus

        #endregion
        #region OS Configuration settings
        try {
            $kvName = 'kv' + $Subscription
            $SS= Get-AzureKeyVaultSecret -VaultName $kvName -Name $LocalAdminUser -ErrorAction Stop
            $Cred = [PSCredential]::new($LocalAdminUser, $SS.SecretValue)
        }
        Catch {

            $message = @'            
### Set up the Keyvault first, you have created a VM with default password  Holid@ys96! ###

$rgName = 'myRgName'
$kvName = 'myKVName'

New-AzureRmKeyVault -ResourceGroupName $rgName -VaultName $KVName -Location eastus -Sku premium -EnabledForTemplateDeployment -EnabledForDeployment

$Secret = Read-Host -AsSecureString -Prompt Entercred

Set-AzureKeyVaultSecret -VaultName $KVName -Name ADmin -SecretValue $Secret -ContentType txt

Get-AzureKeyVaultSecret -VaultName $KVName  -Name Admin
'@
            Write-Warning -Message $message
            
            Write-Warning -Message "UserName is $LocalAdminUser, Password is default Holid@ys96!"
            $PW = ConvertTo-SecureString -String 'Holid@ys96!' -AsPlainText -Force
            $Cred = [PSCredential]::new($LocalAdminUser, $PW)

        }

        #$WinRMCertUrl = 'https://kvpsobject.vault.azure.net:443/secrets/PSObjectRootCert/1d281b5e7a77456d843e9213393c9acf'
        
        $OSConfiguration = @{
            Windows             = $true
            Credential          = $Cred
            TimeZone            = $TimeZone
            #WinRMCertificateUrl = $WinRMCertUrl
            #WinRMHttps          = $true
            #WinRMHttp           = $true
            }
        #endregion
        #region Virtual Network
        Try {
            if (! $PSBoundParameters['VNetName'])
            {
                $VNetName =  'vn' + $Prefix.toUpper() + $Environment.toUpper() + $DeployIndex.ToString().PadLeft(3,'0')
            }

            $VNET = Get-AzureRmVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName -ErrorAction Stop
        }
        Catch {
            Write-Warning $_
            Write-Warning "Creating VNET: $VNetName"            
                        
            $VNetParam = @{
                Name              = $VNetName 
                ResourceGroupName = $ResourceGroupName 
                Location          = $Location 
                AddressPrefix     = $VNetAddressPrefix
                }

            $VNet = New-AzureRmVirtualNetwork @VNetParam
        }
        #endregion
        #region Virtual Network
        $VNetSN = Get-AzureRmVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName -ErrorAction Stop |
                foreach Subnets | where Name -EQ $SubnetName
        if (-not $VNetSN)
        {
            Write-Warning "Creating Subnet: $SubnetName in VNet: $VNetName"
            
            Add-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $VNet -AddressPrefix $SNAddressPrefix
            $VNetSN = Set-AzureRmVirtualNetwork -VirtualNetwork $VNet |
                foreach Subnets | where Name -EQ $SubnetName
        }
        #endregion        
        #region Gateway Subnet
        if ($AddGatway)
        {
            Try {
                $VNETSNGW = Get-AzureRmVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName -ErrorAction Stop |
                    foreach Subnets | where Name -EQ 'GatewaySubnet'
            }
            Catch {
                Write-Warning $_
                Write-Warning "Creating Subnet: GatewaySubnet in VNet: $VNetName"
            
                # Set the GatewaySubnet to always be x.x.254.x/24
                $GWPrefix = ($SNAddressPrefix -split '\.')
                $GWPrefix[2] = 254
                $GWPrefix = $GWPrefix -join "."

                $GWPrefix = $SNAddressPrefix
                Add-AzureRmVirtualNetworkSubnetConfig -Name GatewaySubnet -VirtualNetwork $VNet -AddressPrefix $GWPrefix 
                $VNetSNGW = Set-AzureRmVirtualNetwork -VirtualNetwork $VNet
            }
        }
        #endregion
        #region LoadBalancer
        if ($AddLoadBalancer)
        {
            
            #region Public IP       
            Try {
                $PublicIPIFLB = Get-AzureRmPublicIpAddress -ResourceGroupName $ResourceGroupName -Name ('PublicIP_IFLB_' + $Deployment) -ErrorAction Stop
            }
            Catch {
                Write-Warning $_
                Write-Warning "Creating PublicIP for Internet Facing LoadBalancer: $VM"            
                $PublicIPIFLBParam = @{
                    Name              = ('PublicIP_IFLB_' + $Deployment) 
                    ResourceGroupName = $ResourceGroupName 
                    Location          = $Location 
                    AllocationMethod  = 'Static'
                    }
                $PublicIPIFLB = New-AzureRmPublicIpAddress @PublicIPIFLBParam
            }
            #endregion            
            
            $LoadBalancerName = 'IFLB_vn' + $Deployment
            Try {
                $VNETLoadBalancer = Get-AzureRmLoadBalancer -ResourceGroupName $ResourceGroupName -Name $LoadBalancerName -ErrorAction Stop
            }
            Catch {
                Write-Warning $_
                Write-Warning "Creating Internet Facing Loadbalancer: in VNet: $VNetName"
                
                $FEIPCFG = New-AzureRmLoadBalancerFrontendIpConfig -Name FEIPCFG -PublicIpAddress $PublicIPIFLB

                $VNETLoadBalancer = New-AzureRmLoadBalancer -Name $LoadBalancerName -ResourceGroupName $ResourceGroupName `
                     -Location $Location -FrontendIpConfiguration $FEIPCFG
            }
        }
        #endregion
        #region Instance Size
        $VMSize = Switch ($VMInstanceSize)
        {
            ExtraSmall {'Standard_A0'}
            Small      {'Standard_A1'}
            Medium     {'Standard_A2'}
            Large      {'Standard_A3'}
        }

        #endregion

    }#Begin
    Process
    {
        $VMName | ForEach-Object {
            $VM = $_
            $OSConfiguration['ComputerName'] = $VM
            #region Public IP       
            if ($AddPublicIP)
            {
                Try {
                    $PublicIP = Get-AzureRmPublicIpAddress -ResourceGroupName $ResourceGroupName -Name ('PublicIP_' + $VM + "_" + $Deployment) -ErrorAction Stop
                }
                Catch {
                    Write-Warning $_
                    Write-Warning "Creating PublicIP for VM: $VM"            
                    $PublicIPParam = @{
                        Name              = ('PublicIP_' + $VM + "_" + $Deployment) 
                        ResourceGroupName = $ResourceGroupName 
                        Location          = $Location 
                        AllocationMethod  = 'Dynamic'
                        }
                    $PublicIP = New-AzureRmPublicIpAddress @PublicIPParam
                }
            }
            #endregion
            #region ADD NAT Rule per VM behind the LoadBalancer
            if ($AddLoadBalancer)
            {
                $FEPort = $RDPStartPort
                $RDPRulesPorts = Get-AzureRmLoadBalancerInboundNatRuleConfig -LoadBalancer $VNETLoadBalancer |
                    Where BackEndPort -eq 3389 | Foreach FrontEndPort
                
                while ($FEPort -in $RDPRulesPorts)
                {
                    Write-Verbose "$FEPort is taken" -Verbose
                    $FEPort++
                }
                Write-Verbose "$FEPort is available" -Verbose

                $FEIPCFG = Get-AzureRmLoadBalancerFrontendIpConfig -LoadBalancer $VNETLoadBalancer

                $NATParams = @{
                    Name        = "NatRule_${FEPort}_${VM}"
                    BackendPort = 3389
                    FrontendPort= $FEPort
                    Protocol    = 'Tcp'
                    FrontendIpConfiguration = $FEIPCFG
                   }
                
                $VNETLoadBalancer | Add-AzureRmLoadBalancerInboundNatRuleConfig @NATParams |
                    Set-AzureRmLoadBalancer

                $rule = Get-AzureRmLoadBalancerInboundNatRuleConfig -LoadBalancer $VNETLoadBalancer | 
                    where Name -eq "NatRule_${FEPort}_${VM}"
            }
            #endregion
            #region Network Interface
            Try {
                $Interface = Get-AzureRmNetworkInterface -Name ('NIC_' + $VM + "_" + $Deployment) -ResourceGroupName $ResourceGroupName -ErrorAction Stop

            }
            Catch {

                Write-Warning -Message "Creating Interface $('NIC_' + $VM + "_" + $Deployment)"
                $NetworkInterfaceParams = @{
                    Name              = ('NIC_' + $VM + "_" + $Deployment) 
                    ResourceGroupName = $ResourceGroupName 
                    Location          = $Location 
                    SubnetId          = $VNETSN.Id
                    }
                
                if ($AddLoadBalancer)
                {
                    $NetworkInterfaceParams['LoadBalancerInboundNatRuleId'] = $rule.Id
                }

                if ($AddPublicIP)
                {
                    $NetworkInterfaceParams['PublicIpAddressId'] =  $PublicIP.Id
                }

                $Interface = New-AzureRmNetworkInterface @NetworkInterfaceParams
                
                # More stuff here to consider
                # New-AzureRmNetworkInterface -Name -ResourceGroupName -Location `
                # -PrivateIpAddress -LoadBalancerBackendAddressPoolId `
                # -NetworkSecurityGroupId -IpConfigurationName -DnsServer -InternalDnsNameLabel -EnableIPForwarding
            }
            #endregion
            #region VMConfig
            $VMConfig = @{
                Name   = $VM 
                VMSize = $VMSize
                }
            #endregion
            #region Availability Set
            if ($AvailabilitySetName)
            {
                try {
                    $AvailabilitySet = Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AvailabilitySetName -ErrorAction Stop
                }
                Catch {
                    $AvailabilitySet = New-AzureRmAvailabilitySet -PlatformUpdateDomainCount $VMName.count `
                             -ResourceGroupName $ResourceGroupName -Name $AvailabilitySetName -Location $Location `
                             -PlatformFaultDomainCount $VMName.count
                }

                $VMConfig['AvailabilitySetId'] = $AvailabilitySet.ID 
            }
            #endregion

            $MyVM = New-AzureRMVMConfig @VMConfig  | 
                Set-AzureRmVMSourceImage -PublisherName $publisher.PublisherName -Offer $offer.Offer -Skus  $MySKU -Version latest |
                Set-AzureRmVMOperatingSystem @OSConfiguration |
                Set-AzureRmVMOSDisk -Name ($VM + "_OSDisk") `
                    -VhdUri ($VHDPath + $VM + "_" + $Deployment + "_OSDisk.vhd") -CreateOption FromImage |
                Add-AzureRmVMNetworkInterface -Id $Interface.Id |
                # Add-AzureRmVMSecret
                # Set-AzureRmVMDiagnosticsExtension
                # Set-AzureRmVMBootDiagnostics
                # Set-AzureRmVMAccessExtension
                Add-AzureRmVMDataDisk -Name ($VM + "_DataDisk") `
                    -VhdUri ($VHDPath + $VM + "_" + $Deployment + "_DataDisk.vhd") -Caching ReadWrite `
                    -DiskSizeInGB 127 -Lun 0 -CreateOption empty

            #region DSC Agent
            if ($BootStrapDSCPull)
            {
                $DSCExtension = @{
                        # ConfigurationArgument: supported types for values include: primitive types, string, array and PSCredential
                        ConfigurationArgument= @{
                                ComputerName = 'localhost'
                                }           
                        ArchiveStorageAccountName = 'saeastus01'
                        ArchiveResourceGroupName  = 'rgGlobal'
                        # --- Info above about the DSC Resource

                        # --- Info Below about the Virtual Machine                  
                        ResourceGroupName    = $ResourceGroupName
                        VMName               = $VM
                        Location             = $Location
                        ConfigurationName    = 'BaseOS'
                        ConfigurationArchive = 'BaseOS.ps1.zip'
                        Version              = (Get-AzureVMAvailableExtension -ExtensionName DSC -Publisher Microsoft.Powershell | Foreach Version)
                        WmfVersion           = 'latest'
                        AutoUpdate           = $true
                        Force                = $True
                        Verbose              = $True
                      }
            
                $MyVM = $MyVM | Set-AzureRmVMDscExtension @DSCExtension
               
            }#BootStrapDSC
            #endregion

            #region DSC Agent Pull
            if ($BootStrapDSCPushConfigName)
            {
                
               
            }#BootStrapDSCPull
            #endregion

            Write-Verbose -Message "Adding VM $VM to $ResourceGroupName" -Verbose
            try {
                $MyVM.ConfigurationSets
                $MyVM.ResourceExtensionReferences

                $VMParams = @{
                    ResourceGroupName = $ResourceGroupName 
                    Location          = $Location 
                    VM                = $MyVM 
                    ErrorAction       = 'Stop' 
                    Tags              = @{Name='Environment';Value=$Environment}
                 }
                 New-AzureRmVM @VMParams

                if (-not $Wait)
                {
                    $New = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VM
                    $New | Select Name,ResourceGroupName, Location, ProvisioningState
                    $message = @"
Provisioning $VM this will take some time
         Run the following to get status update:`n
         Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VM | 
          select Name,ResourceGroupName, Location, ProvisioningState `n
"@                  
                    Write-Verbose -Message $message -Verbose
                    [console]::Beep(15kb,400)
                    #Continue
                }
                else{
            
                    do { 
                        $New = Get-AzureVM -Name $VM -ServiceName $ServiceName
                        $New
                        If ($BootStrapDSC)
                        {
                            $New.ResourceExtensionStatusList.Where{$_.HandlerName -eq 'Microsoft.Powershell.DSC'}.ExtensionSettingStatus.FormattedMessage
                        }
                        Write-Verbose -Message "Waiting for $VM : $(Get-Date)" -verbose
                        Start-Sleep -Seconds 20
                    } 
                    while ($New.Status -in 'Provisioning','RoleStateUnknown')
                }#Else
            }
            Catch {
                Write-Warning $_
            }
            [console]::Beep(15kb,400)
        }
    }#Process
}#New-VMBuildAzure