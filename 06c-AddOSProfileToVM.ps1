break
# Add-AzureRmAccount

# create the vm configuration object if not already created
<# 
    $MyVM = New-AzureRMVMConfig -VMName VM1_DevJumpBox -VMSize Standard_D2

    Set-AzureRmVMSourceImage -PublisherName WindowsServer -Offer WindowsServer `
        -Skus 2012-R2-Datacenter -Version 4.0.20160915 -VM $myVM
#>

# Set the Operating System attributes, we still reference the $MyVM object

Set-AzureRmVMOperatingSystem -VM $myVM `
    -Windows `
    -ComputerName 'VM1_DevJumpBox' `
    -Credential (Get-Credential) `
    -TimeZone = [System.TimeZoneInfo]::Local.Id

# view the VM configuration object
$myVM | select *

# view the OS Profile
$myVM.OSProfile

# view the Windows Configuration
$myVM.OSProfile.WindowsConfiguration