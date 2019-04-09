break
# Add-AzureRmAccount

# create the vm configuration object if not already created
<# 
    $MyVM = New-AzureRMVMConfig -VMName VM1_DevJumpBox -VMSize Standard_D2

    Set-AzureRmVMSourceImage -PublisherName WindowsServer -Offer WindowsServer `
        -Skus 2012-R2-Datacenter -Version 4.0.20160915 -VM $myVM

    Set-AzureRmVMOperatingSystem -VM $myVM `
        -Windows `
        -ComputerName 'VM1_DevJumpBox' `
        -Credential (Get-Credential) `
        -TimeZone = [System.TimeZoneInfo]::Local.Id
#>

# Create variables that will be used these throughout script
$location = "WestUS2"
$rgName = "rgFirst"
$stAcctName = "samlwtest51"

# create the virtual network
$vnetName = "iaas-net"
$subnet = New-AzureRmVirtualNetworkSubnetConfig -Name 'frontendSubnet' `
                -AddressPrefix 10.0.1.0/24
$vnet = New-AzureRmVirtualNetwork -Name $vnetName `
                -ResourceGroupName $rgName `
                -Location $location `
                -AddressPrefix 10.0.0.0/16 `
                -Subnet $subnet

# create the NIC
$nicName = "vm1-nic"
$pip = New-AzureRmPublicIpAddress -Name $nicName `
            -ResourceGroupName $rgName `
            -Location $location `
            -AllocationMethod Dynamic
$nic = New-AzureRmNetworkInterface -Name $nicName `
            -ResourceGroupName $rgName `
            -Location $location `
            -SubnetId $vnet.Subnets[0].Id `
            -PublicIpAddressId $pip.Id

# get the storage account
$stAcct = Get-AzureRmStorageAccount -ResourceGroupName $rgName -Name $stAcctName

# location to store VM
$VHDPath = $stAcct.PrimaryEndpoints.Blob + 'vhds/'

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

# view properties
$myVM | select *

