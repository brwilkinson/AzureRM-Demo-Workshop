break
#Requires -Module AzureRM.Profile
#Requires -Module AzureRM.KeyVault

#
# 03a-CreateKeyVault.ps1
#

$RG = 'rgModule3a'
$kvName = 'kvModule3a'
$Location = 'EastUS2'

$AdminUserName = 'EricLang'

New-AzureRmResourceGroup -Name $rg -Location $Location
Get-AzureRmResourceGroup -Name $rg -Location $Location 

New-AzureRmKeyVault -ResourceGroupName $rg -VaultName $kvName -Location $Location -Sku premium
# Get-AzureRmKeyVault -VaultName $kvName -ResourceGroupName $rg | Remove-AzureRmKeyVault

$Secret = Read-Host -AsSecureString -Prompt "Enter the Password for $AdminUserName"

Set-AzureKeyVaultSecret -VaultName $kvName -Name $AdminUserName -SecretValue $Secret -ContentType txt

# Set-AzureKeyVaultSecret -VaultName "Contoso" -Name "ITSecret" -SecretValue $Secret -Expires $Expires 
#    -NotBefore $NBF -ContentType $ContentType -Enable $True -Tags $Tags -PassThru

$contosokey = Get-AzureKeyVaultSecret -VaultName $kvName -Name $AdminUserName
$contosokey
$contosokey.Id
$contosokey.SecretValue      # SecureString
$contosokey.SecretValueText  # Text
$contosokey | gm
$contosokey | select *

# most recent key
# E.g. https://kvcontoso.vault.azure.net:443/secrets/ericlang

# specific version of key
# E.g. https://kvcontoso.vault.azure.net:443/secrets/ericlang/afa351084bba48449cc5deb984c7c4a1

$NewSecret = Read-Host -AsSecureString -Prompt "Enter the Password for $AdminUserName"

Set-AzureKeyVaultSecret -VaultName $kvName -Name $AdminUserName -SecretValue $NewSecret -ContentType txt

$contosokeyV2 = Get-AzureKeyVaultSecret -VaultName $kvName -Name $AdminUserName
$contosokeyV2.SecretValueText

$contosoOriginal = Get-AzureKeyVaultSecret -VaultName $kvName -Name $AdminUserName -Version 46ec944d6c3744f8a4b17b30f15d383e
$contosoOriginal.SecretValueText

# Include (All) Versions
Get-AzureKeyVaultSecret -VaultName $kvName -Name $AdminUserName -IncludeVersions

# Review the KeyVault and Access Policies in https://resources.azure.com
Start-Process -FilePath https://resources.azure.com

# Cleanup the KeyVault Key
Remove-AzureKeyVaultKey -VaultName $kvName -Name $AdminUserName

# Cleanup the KeyVault
Remove-AzureRmKeyVault -ResourceGroupName $rg -VaultName $kvName