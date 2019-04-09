# Import a key from a .pfx file on your computer to hardware security modules (HSMs) in the Azure Key Vault service

$RG = 'rgModule3d'
$kvName = 'kvModule3d'
$Location = 'EastUS2'
$SoftKeyName = 'ContosoSoftKey'
$HSMKeyName = 'ContosoHSMKey'

New-AzureRmResourceGroup -Name $RG -Location $Location

New-AzureRmKeyVault -VaultName $kvName -ResourceGroupName $RG -Location $Location -SKU 'Premium'
# Get-AzureRmKeyVault -VaultName 'vkModule3c' -ResourceGroupName $RG

# Create Key in Software KeyVault
$keysw = Add-AzureKeyVaultKey -VaultName $kvName -Name $SoftKeyName -Destination Software
$keysw

# Create Key in HSM (Hardware Security Module)
$keyhsm = Add-AzureKeyVaultKey -VaultName $kvName -Name $HSMKeyName -Destination HSM
$keyhsm

Get-AzureKeyVaultKey -VaultName $kvName -Name $HSMKeyName

#----------------------------------------------------------------

# If you have an existing 2048-bit RSA software-protected key, you can upload the key to Azure Key Vault

# We will demo with the Certificate we created in 3b
$PFXPath = 'D:\Azure\Certs\contosoDecryptModule3b.pfx'
Get-item -Path $PFXPath
Get-PfxCertificate -FilePath $PFXPath
$PW = (Read-Host -AsSecureString -Prompt 'EnterPW')

$KeyVaultKeyHSM = @{
    VaultName   = $kvName 
    Name        = 'ITPFX'
    Destination = 'HSM'
    KeyFilePath = $PFXPath 
    KeyFilePassword = $PW
    Expires         = (Get-Date).AddYears(2).ToUniversalTime()  
    }

$key = Add-AzureKeyVaultKey @KeyVaultKeyHSM

Get-AzureKeyVaultKey -VaultName $kvName -Name ITPFX

#----------------------------------------------------------------

# Register the new AD Application for SQL EKM 
$Aadclientsecret = $RG
$AADapplication = New-AzureRmADApplication -DisplayName SQLEKM2 -HomePage http://SQLEKM2 `
                     -IdentifierUris http://SQLEKM2 -Password $Aadclientsecret

# Register the new AD Service Principal that will be used for SQL EKM
$serviceprinciple  = New-AzureRmADServicePrincipal -ApplicationId $AADapplication.ApplicationID
$serviceprinciple | select *

Set-AzureRmKeyVaultAccessPolicy -VaultName $kvName `
  -ServicePrincipalName $serviceprinciple.ApplicationId `
  -PermissionsToKeys get, list, wrapKey, unwrapKey

# KeyVault is not ready, the next step would be to 
# Install the SQL Server Connector.

# Review the New Keys in the Portal.

