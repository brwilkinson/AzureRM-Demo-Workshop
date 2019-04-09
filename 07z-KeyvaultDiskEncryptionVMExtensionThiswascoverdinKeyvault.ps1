break

#------------------------
$Deployment = 'Module8a'
$RG = ('rg' + $Deployment)
$VNet = ('vn' + $Deployment)
$RDPFileDirectory = 'D:\azure\RDP'
$VMName = 'vmFE8a'
$SA = "samod8dev001"
$kvName = 'kvModule8'

New-AzureRmKeyVault -VaultName $kvName -ResourceGroupName $rg -Location $Location -EnabledForDiskEncryption

# 3 main uses for keys, from Module 3 - Credentials and Certificates
<#
Set-AzureRmKeyVaultAccessPolicy -VaultName kvContoso -ResourceGroupName rgGlobal  -EnabledForDiskEncryption
Set-AzureRmKeyVaultAccessPolicy -VaultName kvContoso -ResourceGroupName rgGlobal  -EnabledForDeployment
Set-AzureRmKeyVaultAccessPolicy -VaultName kvContoso -ResourceGroupName rgGlobal  -EnabledForTemplateDeployment
#>

Set-AzureRmKeyVaultAccessPolicy -VaultName $kvName -ResourceGroupName $rg -EnabledForDiskEncryption

$Aadclientsecret = "myaadclientsecret"
$AADapplication = New-AzureRmADApplication -DisplayName AADdiskencryption -HomePage http://diskencryption -IdentifierUris http://identityurl1 -Password $Aadclientsecret

$AADapplication.ApplicationId
$aid = $AADapplication.ApplicationId

$serviceprinciple  = New-AzureRmADServicePrincipal -ApplicationId $aid 
$serviceprincipleName = $serviceprinciple.ServicePrincipalNames[0]

Set-AzureRmKeyVaultAccessPolicy -VaultName $kvName -ResourceGroupName $rg `
    -ServicePrincipalName $serviceprincipleName -PermissionsToKeys all -PermissionsToSecrets all

$KV = Get-AzureRmKeyVault -VaultName $kvName -ResourceGroupName $rg

$KV

$diskencryptionURL = $kv.VaultUri
$resourceid = $kv.ResourceId

# confirm the vm is running

Get-AzureRmVM -ResourceGroupName $rg -Name $VMName -Status -ov VM
$vm[0].Statuses

Set-AzureRmVMDiskEncryptionExtension -ResourceGroupName $rg -VMName $VMName -AadClientID $aid `
    -AadClientSecret $Aadclientsecret -DiskEncryptionKeyVaultUrl $diskencryptionURL -DiskEncryptionKeyVaultId $resourceid


Get-AzureRmVMDiskEncryptionStatus -ResourceGroupName $rg -VMName $VMName -ov Encrypted
$Encrypted[0].OsVolumeEncryptionSettings.DiskEncryptionKey | fl
