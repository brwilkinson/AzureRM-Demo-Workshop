#Requires -Module AzureRM.Automation

# Pull Server Automation Account
$AAName = 'IaaSAutomation'
$RgName = 'rgGlobal'
$ConfigurationName = 'BaseOSTest'

$AAAccount = @{
        AutomationAccountName = $AAName  
        ResourceGroupName     = $RgName
        OutVariable           = 'result'
    }

Get-AzureRmAutomationDscCompilationJob @AAAccount

# VM to apply configuration in Pull Mode
$vmrgName = 'rgModule7a'
$vmName = 'vmFE7a'
$Location = 'EastUS2'

Get-AzureRmVM -ResourceGroupName $vmrgName -Name $vmName | 
    Select Name,resourcegroupname,location, 
        @{n='extensions';e={$_.extensions.name -join "`n"}} | fl

Get-AzureRmVMDscExtension -ResourceGroupName $vmrgName -VMName $vmName
# Get-AzureRmVMDscExtension -ResourceGroupName $vmrgName -VMName $vmName | Remove-AzureRmVMDscExtension -VMName $vmName

Get-AzureRmAutomationDscNodeConfiguration @AAAccount

$params = @{
 # Pull Server Automation details
 NodeConfigurationName = 'BaseOSTest.LocalHost'

 # VM Information to set to Pull
 AzureVMResourceGroup  = $vmrgName
 AzureVMName           = $vmName
 AzureVMLocation       = $Location

 # DSC LCM settings
 RebootNodeIfNeeded    = $true
 AllowModuleOverwrite  = $true
 verbose               = $true
 RefreshFrequencyMins  = 120
 ConfigurationModeFrequencyMins = 60
 }

 Register-AzureRmAutomationDscNode @AAAccount @Params

 Get-AzureRmAutomationDscNode @AAAccount -Name $vmName

$IP =  Get-AzureRmPublicIpAddress -ResourceGroupName $rg -Name PublicIP_vmFE7b_Module7b | foreach IPAddress

 Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value 104.46.109.93 -Concatenate -Force

 $cred = Get-Credential brw
 icm -ComputerName 104.46.109.93 -ScriptBlock {Get-DscLocalConfigurationManager} -Credential $cred
 icm -ComputerName 104.46.109.93 -ScriptBlock {dir F:\ -Recurse} -Credential $cred 
  icm -ComputerName 104.46.109.93 -ScriptBlock {Update-DscConfiguration -Wait -Verbose} -Credential $cred


  (Get-AzureRmVM -ResourceGroupName $rg -Name $vmName).NetworkInterfaceIDs[0]
  Get-AzureRmVM