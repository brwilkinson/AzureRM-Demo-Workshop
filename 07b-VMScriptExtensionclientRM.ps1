break
# requires -Module AzureRM.Network
# requires -Module AzureRM.Compute

Get-Command -Name *et-azureRMVm*Extension* | Select Name | Format-Wide -AutoSize

#------------------------
$Deployment = 'Module7a'
$RG = ('rg' + $Deployment)
$VNet = ('vn' + $Deployment)
$RDPFileDirectory = 'D:\azure\RDP'
$VMName = 'vmFE7a'
$SA = "samodule7a"


$ScriptPath = 'D:\Azure\Extensions\Scripts'
$ScriptName = 'SetNetworkProfilePrivate.ps1'
$ScriptFilePath = (Join-Path -Path $ScriptPath -ChildPath $ScriptName)

# The script
@'
$Profile = Get-NetConnectionProfile -InterfaceAlias 'Ethernet'
$Profile.NetworkCategory = 'Private'
Set-NetConnectionProfile -InputObject $Profile
'@ | Out-File -FilePath $ScriptFilePath

# Check the file
psedit $ScriptFilePath 

# The storage already exists from when we deployed the VM, we want to keep everything in the same RG and SA

$StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $RG -Name $SA)[0].VAlue
$StorageAccountContext = (Get-AzureRmStorageAccount -ResourceGroupName $RG -Name $SA).Context

# currently there is only the vhds container from the virtual machine
Azure.Storage\Get-AzureStorageContainer -Context $StorageAccountContext | select Name

# We will create a new container for the scripts
Azure.Storage\New-AzureStorageContainer -Context $StorageAccountContext -Name scripts 

# check it again
Azure.Storage\Get-AzureStorageContainer -Context $StorageAccountContext


# Upload the Script file 
Get-ChildItem -Path $ScriptPath -Filter $ScriptName |
Set-AzureStorageBlobContent -Container scripts -Context $StorageAccountContext -Force


Azure.Storage\Get-AzureStorageBlob -Context $StorageAccountContext -Container scripts

$ScriptExtension = @{
 ResourceGroupName = $RG
 Location          = $Location 
 VMName            = $VMName 
 Name              = "SetNetProfile" 
 TypeHandlerVersion= "1.8" 
 StorageAccountName= $SA
 StorageAccountKey = $StorageAccountKey 
 FileName          = "SetNetworkProfilePrivate.ps1" 
 ContainerName     = "scripts"
 }

 Set-AzureRmVMCustomScriptExtension @ScriptExtension

 Get-AzureRmVMCustomScriptExtension -ResourceGroupName $RG -VMName $VMName -Name setnetprofile

 Get-AzureRmVMCustomScriptExtension -ResourceGroupName $RG -VMName $VMName -Name setnetprofile -Status -ov Status
 $Status.statuses 


