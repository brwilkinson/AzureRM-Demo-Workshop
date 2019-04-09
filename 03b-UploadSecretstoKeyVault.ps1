break
#Requires -Module AzureRM.Profile
#Requires -Module AzureRM.KeyVault

#
# 03b-UploadSecretstoKeyVault.ps1
#
$RG = 'rgModule3b1'
$kvName = 'kvModule3b1'
$Location = 'EastUS2'
$CertPath = 'D:\Azure\Certs'

New-AzureRmResourceGroup -Name $rg -Location $Location

New-AzureRmKeyVault -ResourceGroupName $rg -VaultName $kvName -Location $Location `
    -Sku premium -EnabledForTemplateDeployment -EnabledForDeployment

#--------------------------------------------------------
# Create Web cert *.contoso.com
$cert = New-SelfSignedCertificate -DnsName *.contoso.com -CertStoreLocation Cert:\LocalMachine\My
$cert
$PW = read-host -AsSecureString -Prompt "Enter Cert PW"

Export-Certificate -FilePath $CertPath\contosowildcardModule3b.cer -Cert $cert

Export-PfxCertificate -Password $PW -FilePath $CertPath\contosowildcardModule3b.pfx -Cert $cert

Get-PfxCertificate -FilePath $CertPath\contosowildcardModule3b.pfx

#--------------------------------------------------------
# Upload certs to KeyVault

# repeat for each file. .

$Name = 'contosowildcardModule3b'

#------------------------------

$FileName = "$CertPath\$Name.pfx"
$certPassword = 'rgModule3b'

$fileContentBytes = Get-Content -Path $fileName -Encoding Byte
$fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)

$jsonObject = @"
 {
 "data"     : "$filecontentencoded",
 "dataType" : "pfx",
 "password" : "$certPassword"
 }
"@

# * Secrets (Certs) are stored as a Binary stream (up to 25K Bytes)

$jsonObjectBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonObject)
$jsonEncoded     = [System.Convert]::ToBase64String($jsonObjectBytes)

$secret = ConvertTo-SecureString -String $jsonEncoded -AsPlainText -Force
Set-AzureKeyVaultSecret -VaultName $KVName -Name $Name -SecretValue $secret

# Now repeat for the other Cert . . .

#--------------------------------------------------------

$contosowildcard = Get-AzureKeyVaultSecret -VaultName $KVName -Name $name
$contosowildcard.Id
# e.g. https://kvcontoso.vault.azure.net:443/secrets/contosowildcard

#--------------------------------------------------------

