break

#Requires -Module AzureRM.Profile
#Requires -Module Azure.Storage

# This is an alternate subscription, do this in an alternate ISE session

#1 If a blob is public I can access it by using the URI
$URI = 'https://saeastusmodule4a.blob.core.windows.net/configurations/thisisacontainerforconfigurations.txt'

# Web via browser
Start-Process -FilePath $URI

# WebRequest via cmdlet
Invoke-RestMethod -Uri $URI -UseBasicParsing

#2 Once it's set to private I cannot access it anymore

# Go back and run this in the original session
Set-AzureStorageContainerAcl -Name configurations -Permission Off -PassThru

Invoke-RestMethod -Uri $URI -UseBasicParsing

# -----------------------------------------------------------------
#4 This is an alternate subscription, with the Key I can do anything.
$Key = '+FoSEI0DZwzNjL54NAXuXy1Vb/NlDZkLlgt0RISs3Xk7xDXXcQz0d5UURK3BwXMEQYeogFKfEEu+wmrm+AHCXw=='
$saName = 'saeastusmodule4a'
$Context = New-AzureStorageContext -StorageAccountName $saName -StorageAccountKey $Key
$Context

#5 Now I have the context I have access
Get-AzureStorageContainer -Name configurations -Context $Context

#6 I can download the blob
Get-AzureStorageBlobContent -Context $Context -Container configurations `
     -Blob thisisacontainerforconfigurations.txt -Destination D:\thisisacontainerforconfigurations.txt

dir D:\thisisacontainerforconfigurations.txt

Get-Content -Path D:\thisisacontainerforconfigurations.txt

# Cleanup the Resource Group and storage accounts 

Remove-AzureRmStorageAccount -ResourceGroupName $RG -Name $SAN -Force

Remove-AzureRmResourceGroup -Name $RG -Force