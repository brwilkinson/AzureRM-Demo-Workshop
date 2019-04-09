break
# requires -Module AzureRM.Network
# requires -Module AzureRM.Compute

Get-Command -Name *et-azureRMVm*Extension* | Select Name | Format-Wide -AutoSize

$Deployment = 'Module7a'
$RG = ('rg' + $Deployment)
$VNet = ('vn' + $Deployment)
$RDPFileDirectory = 'D:\azure\RDP'
$VMName = 'vmFE7a'
$SA = "samodule7a"

#------------------------
#region deployVM
# custom function for creating a Virtual Machine
. "$Source/05a3-New-VMBuildAzureRM2.ps1"
New-VMBuildAzureRM2 -VMName $VMName -VNetName $VNet -SubnetName FrontEnd -ResourceGroupName $RG -AddPublicIP 


Get-AzureRmVM -ResourceGroupName $RG | ForEach-Object {
    
    Get-AzureRmRemoteDesktopFile -LocalPath ($RDPFileDirectory + '/' + $_.Name + '.RDP') `
        -ResourceGroupName $RG -Name $_.Name
}
#endregion
#------------------------

# BGInfo is provisioned by default unless you use the switch to disable it.
New-AzureRmVM -DisableBginfoExtension

# Review the Extension that has been installed
Get-AzureRmVMExtension -ResourceGroupName $rg -VMName $VMName -Name bginfo

# Review the Extension Status (Instance View)
Get-AzureRmVMExtension -ResourceGroupName $rg -VMName $VMName -Name bginfo -Status -ov status
$status.statuses 

#------------------------

# Now add the VM Access Extension (for resetting passwords and RDP components to default)
Set-AzureRmVMAccessExtension -ResourceGroupName $rg -VMName $VMName `
    -Name VMAccess -UserName BRW -Password mys3cretpassword!

Get-AzureRmVMAccessExtension -ResourceGroupName $rg -VMName $VMName `
    -Name VMAccess -Status -OV VMAccessStatus

$VMAccessStatus.Statuses

#------------------------

# Other extensions not listed with the cmdlets ?

# Step 1 find the extension
$Search = 'Microsoft.Azure'
$Location = 'eastus2'

Get-AzureRmVMImagePublisher -Location $Location -ov Publishers | 
    Where PublisherName -notlike *microsoft*  | 
        Format-Wide -Property PublisherName -Column 6

Get-AzureRmVMImagePublisher -Location $Location -ov Publishers | 
    Where PublisherName -like *$Search*

$Publisher = 'Microsoft.Azure.Security'
Get-AzureRmVMExtensionImageType -Location $Location -PublisherName $Publisher |
    Select PublisherName,Type

$Type = 'IaaSAntimalware'
Get-AzureRmVMExtensionImage -Location $Location -PublisherName $Publisher -Type $Type |
    select Location,PublisherName,Type,Version | select -Last 1 -OutVariable IaaSAntimalware

# Open the web page to check the documentation for the specific settings
Start-Process -FilePath https://azure.microsoft.com/en-us/documentation/articles/azure-security-antimalware/#architecture

# The settings takes a hashtable format string
$IaaSAntimalwareSettings = @{ 
    "AntimalwareEnabled" = "true" 
    "Monitoring"         = "ON"
    "StorageAccountName" = $SAName
}

# Step 2 Set the extension on the VM
$IaaSAntimalwareParams = @{
    ResourceGroupName = $rg
    VMName            = $VMName
    Location          = $Location
    Publisher         = $Publisher
    Name              = $Type
    ExtensionType     = $Type
    TypeHandlerVersion= "1.5"
    Settings          = $IaaSAntimalwareSettings
   }

Set-AzureRmVMExtension @IaaSAntimalwareParams

Get-AzureRmVMExtension -ResourceGroupName $rg -VMName $VMName -Name $Type -Status -ov status
$status.Statuses