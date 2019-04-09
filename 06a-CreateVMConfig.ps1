break

# Add-AzureRmAccount

# Virtual Machine sizes are dependent on the region they are deployed
$Location = 'WestUS2'

# Different hardware sizes and VM offerings are available at different Data Centers
Get-AzureRmVMSize -Location $Location 

# narrow to specific number of cores
Get-AzureRmVMSize -Location $Location | Where-Object { $_.NumberofCores -eq 2}

# sort by memory
Get-AzureRmVMSize -Location $Location | where NumberofCores -eq 2 |
    Sort -Property MemoryInMB | 
    Select -Property MaxDataDiskCount, MemoryInMB,Name,NumberOfCores, OSDiskSizeInMB

# create a configurable local virtual machine object for Azure in memory
$MyVM = New-AzureRMVMConfig -VMName VM1_DevJumpBox -VMSize Standard_D2

# view the properties of the VM object
$myVM | select *

# view the hardware profile of the VM object
$myVM.HardwareProfile