break
#Requires -Module AzureRM.Profile
#Requires -Module AzureRM.KeyVault
#Requires -Module AzureRM.Resources

$RG = 'rgModule3b'
$kvName = 'kvModule3b'
$Location = 'EastUS2'
$CertPath = 'D:\Azure\Certs'


# 3 main uses for keys in Deployments and using PowerShell Scripting
# The resource provider acts on your behalf and you grant it access to do so.

Get-AzureRmKeyVault -VaultName $kvName

Set-AzureRmKeyVaultAccessPolicy -VaultName $kvName -ResourceGroupName $RG  -EnabledForDeployment
Set-AzureRmKeyVaultAccessPolicy -VaultName $kvName -ResourceGroupName $RG  -EnabledForTemplateDeployment
Set-AzureRmKeyVaultAccessPolicy -VaultName $kvName -ResourceGroupName $RG  -EnabledForDiskEncryption -PassThru

Remove-AzureRmKeyVaultAccessPolicy -VaultName $kvName -ResourceGroupName $RG -EnabledForDiskEncryption -EnabledForDeployment -EnabledForTemplateDeployment -PassThru

#----------------------------------------------------------------

# We now consider Appplications and Users who need access

# Grant permissions to a user for a Key Vault and modify the permissions

# userPrincipal
# ServicePrincipalName
# ObjectId

Get-Command -Module AzureRM.Resources -name *AD* | Format-Wide -AutoSize

#----------------------------------------------------------------
# Find a *userPrincipal*
# - Then Set the Vault Access Policy for that *userPrincipal*

Get-AzureRmADUser -SearchString benwilk-automationB -OV automationb
Get-AzureRmADUser -UserPrincipalName benwilk@microsoft.com -Ov std
$automationb | Select *

$userprinciple = $automationb.UserPrincipalName
$userprinciple = $std.UserPrincipalName

# Grant Access to Secrets
Set-AzureRmKeyVaultAccessPolicy -VaultName $kvName -UserPrincipalName $userprinciple `
    -PermissionsToSecrets 'All' -PassThru -PermissionsToCertificates all

# Remove Access to Keys, Leave Secrets
Set-AzureRmKeyVaultAccessPolicy -VaultName $kvName -UserPrincipalName $userprinciple `
     -PermissionsToKeys @() -PermissionsToSecrets @() -PassThru

Get-AzureRmKeyVault -VaultName $kvName

#----------------------------------------------------------------
#  Create an AD Application and *ServicePrincipal*, for Disk Encryption
#  - Then Set the Vault access Policy for that *ServicePrincipal*

$RG = 'rgModule3c'
$kvName = 'kvModule3c'
$Location = 'EastUS2'

New-AzureRmResourceGroup -Name $rg -Location $Location

New-AzureRmKeyVault -ResourceGroupName $rg -VaultName $kvName -Location $Location -Sku premium

# Register the new AD Application for Disk Encryption
$Aadclientsecret = $RG
$AADapplication = New-AzureRmADApplication -DisplayName AADdiskencryption2 -HomePage http://diskencryption2 `
                     -IdentifierUris http://AADdiskencryption2 -Password $Aadclientsecret

Get-AzureRmADApplication -DisplayNameStartWith AADdiskencryption2
# Get-AzureRmADApplication -DisplayNameStartWith AADdiskencryption | Remove-AzureRmADApplication

$AADapplication
# ApplicationID GUID
$ApplicationID = $AADapplication.ApplicationId

# Register the new AD Service Principal that will be used for the Disk Encryption
$serviceprinciple  = New-AzureRmADServicePrincipal -ApplicationId $ApplicationID 
$serviceprinciple | select *

# Grant permissions for an application service principal to read and write secrets to the KeyVault
Set-AzureRmKeyVaultAccessPolicy -VaultName $kvName -ServicePrincipalName $serviceprinciple.ApplicationID `
    -PermissionsToKeys all -PermissionsToSecrets set

# Enable the Vault for Disk Encryption
Set-AzureRmKeyVaultAccessPolicy -VaultName $kvName -ResourceGroupName $RG  -EnabledForDiskEncryption

Get-AzureRmKeyVault -VaultName $kvName -OutVariable KV

# confirm the vm is running
$VMName = 'vmBitlocker2'
Get-AzureRmVM -ResourceGroupName $RG -Name $VMName -Status | 
    select Name, @{n='DisplayStatus';e={ $_.Statuses[-1].DisplayStatus }}

$DiskEncryption = @{
    VMName                    = $VMName
    ResourceGroupName         = $RG 
    AadClientID               = $ApplicationID
    AadClientSecret           = $Aadclientsecret
    DiskEncryptionKeyVaultUrl = $kv.VaultUri
    DiskEncryptionKeyVaultId  = $kv.ResourceId
}

Set-AzureRmVMDiskEncryptionExtension @DiskEncryption

Get-AzureRmVMDiskEncryptionStatus -ResourceGroupName $rg -VMName $VMName -ov Encryption

$Encryption.OsVolumeEncryptionSettings.DiskEncryptionKey | fl