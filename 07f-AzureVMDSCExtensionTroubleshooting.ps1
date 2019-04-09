break
# requires -Module AzureRM.Profile
# requires -Module AzureRM.Compute

#------------------------ 

# Check the status of the DSC extension after the next deployment 8b

$Deployment = 'Module7b'
$RG = ('rg' + $Deployment)
$VMName = 'vmFE7b'

Get-AzureRmVM -ResourceGroupName $RG -Name $vmName | 
    Select Name,resourcegroupname,location, 
        @{n='extensions';e={$_.extensions.name -join "`n"}} | fl

$params = @{
    ResourceGroupName = $rg 
    VMName            = $VMName 
    Name              = 'Microsoft.Powershell.DSC' 
    Status            = $true
   }

Get-AzureRmVMDscExtension @params

# View the Verbose output from the LCM
Get-AzureRmVMDscExtensionStatus -ResourceGroupName $rg -VMName $VMName | 
    foreach DscConfigurationLog

Get-AzureRmVMDscExtensionStatus -ResourceGroupName $rg -VMName $VMName | 
    foreach statusmessage

[string]$IP = Get-AzureRmPublicIpAddress -ResourceGroupName $rg | 
                foreach IPaddress

Set-Item -path WSMan:\localhost\Client\TrustedHosts -Value $ip -Concatenate

$cred = Get-Credential brw
$s = New-PSSession -ComputerName $IP -Credential $cred
 Enter-PSSession -Session $s
 
 mstsc.exe /v:$IP