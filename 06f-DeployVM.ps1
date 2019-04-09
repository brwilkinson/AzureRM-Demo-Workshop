break
# Add-AzureRmAccount

# create the vm configuration object if not already created
<# 
    $MyVM = New-AzureRMVMConfig -VMName VM1_DevJumpBox -VMSize Standard_D2

    Set-AzureRmVMSourceImage -PublisherName WindowsServer -Offer WindowsServer `
        -Skus 2012-R2-Datacenter -Version "latest" -VM $myVM

    Set-AzureRmVMOperatingSystem -VM $myVM `
        -Windows `
        -ComputerName 'VM1-DevJumpBox' `
        -Credential (Get-Credential) `
        -TimeZone "Pacific Standard Time"

    $location = "West US"
    $rg = "rgFirst"
    $stAcctName = "samlwtest51"

    # create the virtual network
    $vnetName = "iaas-net"
    $subnet = New-AzureRmVirtualNetworkSubnetConfig -Name 'frontendSubnet' `
                    -AddressPrefix 10.0.1.0/24
    $vnet = New-AzureRmVirtualNetwork -Name $vnetName `
                    -ResourceGroupName $rg `
                    -Location $location `
                    -AddressPrefix 10.0.0.0/16 `
                    -Subnet $subnet

    # create the NIC
    $nicName = "vm1-nic"
    $pip = New-AzureRmPublicIpAddress -Name $nicName `
                -ResourceGroupName $rg `
                -Location $location `
                -AllocationMethod Dynamic
    $nic = New-AzureRmNetworkInterface -Name $nicName `
                -ResourceGroupName $rg `
                -Location $location `
                -SubnetId $vnet.Subnets[0].Id `
                -PublicIpAddressId $pip.Id

    # location to store VM
    $VHDPath = $StorageAccount.PrimaryEndpoints.Blob + 'vhds/'

    # add OS and Data disk information to $myVM configuration object
    $myVM = $myVM | Add-AzureRmVMNetworkInterface -Id $nic.Id |
        Set-AzureRmVMOSDisk -Name "VM1_DevJumpBox_OSDisk" `
            -VhdUri ($VHDPath + "VM1_DevJumpBox_OSDisk.vhd") `
            -CreateOption FromImage |
        Add-AzureRmVMDataDisk -Name "VM1_DevJumpBox_DataDisk" `
            -VhdUri ($VHDPath + "VM1_DevJumpBox_DataDisk.vhd") `
            -Caching ReadWrite `
            -DiskSizeInGB 127 `
            -Lun 0 `
            -CreateOption empty 
#>

$location = "West US"
$rgName = "rgFirst"


# review the $myVM configuration object for details
$MyVM | select * 

# review the hardware profile
$MyVM.HardwareProfile | select *

# review the network profile 
$MyVM.NetworkProfile | select *

# review the OS profile
$MyVM.OSProfile | select *

# review the configuration
$MyVM.OSProfile.WindowsConfiguration | select *

# review the storage interfaces
$MyVM.StorageProfile | select *

# view the image reference
$MyVM.StorageProfile.ImageReference | select *

# view the OS disk info
$MyVM.StorageProfile.OsDisk | select *

# get the uri of the disk
$MyVM.StorageProfile.OsDisk.Vhd.Uri

# view the data disk(s) info
$MyVM.StorageProfile.DataDisks[0] | select *

# get the uri of the disk
$MyVM.StorageProfile.DataDisks[0].vhd.Uri

$tags = @{'Environment'= 'Development'}
# deploy the machine
New-AzureRmVM -Tags $tags `
    -ResourceGroupName $rgName `
    -Location $location `
    -VM $MyVM 
    
