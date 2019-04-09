break
# requires -Module AzureRM.Network
# requires -Module AzureRM.Compute

#------------------------
$Deployment = 'Module7a'
$RG = ('rg' + $Deployment)
$VNet = ('vn' + $Deployment)
$VMName = 'vmFE7a'
$SA = "samodule7a"
$Location = 'EastUS2'

#region Part 1 - Define DSC Configuration document
@'
configuration BaseOS {
param (
    [String]$ComputerName = 'localhost'
)

Import-DSCResource -ModuleName xStorage,PSDesiredStateConfiguration

Node $ComputerName
{

    xDisk FDrive
    {
        DiskNumber  = 3
        DriveLetter = 'F'
    }

    File TestDir
    {
        Type = 'Directory'
        DestinationPath = 'F:\source'
        DependsOn = '[xDisk]FDrive'
    }

}#Node
}#BaseOS
'@ | set-content -Path D:\azure\DSC\BaseOS.ps1 -Force

psedit D:\azure\DSC\BaseOS.ps1
#endregion
#region Part 2 - Compress to zip         
$Params = @{
    ConfigurationPath = 'D:\azure\DSC\BaseOS.ps1'
    OutputArchivePath = 'D:\azure\DSC\BaseOS.ps1.zip'
    Force             = $true
    Verbose           = $true 
}
#Publish-AzureRmVMDscConfiguration -ConfigurationPath -ConfigurationDataPath -OutputArchivePath -SkipDependencyDetection -Force -Verbose
Publish-AzureRmVMDscConfiguration @Params
Invoke-Item 'D:\azure\DSC\BaseOS.ps1.zip'
#endregion
#region Part 3 - upload to azure blob
$DSCConfiguration = @{
    ResourceGroupName     = $rg 
    StorageAccountName    = $sa
    #ContainerName         = 'windows-powershell-dsc'
    #StorageEndpointSuffix = ''
    ConfigurationPath     = 'D:\azure\DSC\BaseOS.ps1.zip'
    Force                 = $true
    Verbose               = $true
}

#Publish-AzureRmVMDscConfiguration -ResourceGroupName -ConfigurationPath -ContainerName -StorageAccountName -StorageEndpointSuffix -ConfigurationDataPath
Publish-AzureRmVMDscConfiguration @DSCConfiguration
#endregion
#region Part 4 - Set the extension on the VM
$DSCExtensionVersion = (Get-AzureVMAvailableExtension -ExtensionName DSC -Publisher Microsoft.Powershell | Foreach Version)

$DSCExtension = @{
        # ConfigurationArgument: supported types for values include: primitive types, string, array and PSCredential
        ConfigurationArgument= @{
                ComputerName = 'localhost'
                }           
        ArchiveStorageAccountName = $sa 
        ArchiveResourceGroupName  = $rg 
        # --- Info above about the DSC Resource

        # --- Info Below about the Virtual Machine                  
        ResourceGroupName    = $rg
        VMName               = $VMName
        Location             = $Location
        ConfigurationName    = 'BaseOS'
        ConfigurationArchive = 'BaseOS.ps1.zip'
        Version              = $DSCExtensionVersion
        WmfVersion           = 'latest'
        AutoUpdate           = $true
        Force                = $True
        Verbose              = $True
      }

#Set-AzureRmVMDscExtension -ResourceGroupName -VMName -Name -ConfigurationArgument -ConfigurationData -Version -Force -Location -AutoUpdate -WmfVersion latest `
#-ArchiveBlobName -ArchiveStorageAccountName -ArchiveResourceGroupName -ArchiveStorageEndpointSuffix -ArchiveContainerName -ConfigurationName -Verbose

Set-AzureRmVMDscExtension @DSCExtension

# The plugin will be installed on the VM, the VM will be updated
# DSC files copited into the VM and will be executed from the following directory:
# C:\Packages\Plugins\Microsoft.Powershell.DSC\2.10.0.0

$a = Get-AzureRmVM -ResourceGroupName $rg -Name $VMName
$a.Extensions | select Publisher,VirtualMachineExtensionType,ProvisioningState

# Find the Status of the DSC Extension
$b = Get-AzureRmVM -ResourceGroupName $rg -Name $VMName -Status
$b.Extensions | where Name -eq Microsoft.Powershell.DSC | foreach Statuses

# View the Verbose output from the LCM
Get-AzureRmVMDscExtensionStatus -ResourceGroupName $rg -VMName $VMName | foreach DscConfigurationLog
Get-AzureRmVMDscExtensionStatus -ResourceGroupName $rg -VMName $VMName | foreach statusmessage
#endregion