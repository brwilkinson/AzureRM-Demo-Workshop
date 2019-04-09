break
# 'https://saeastusmodule4f.blob.core.windows.net/templates/Nano-WindowsServerTechnicalPreview5.vhd'
$SourceRG   = 'rgModule4f'
$SourceSAN  = 'saeastus2module4f'
$Location   = 'EastUS2'

$RG  = 'rgModule4g'
$SAN = 'saeastus2module4g'

Get-Command -Name Start-AzureStorageBlobCopy -Syntax
Show-Command -Name Start-AzureStorageBlobCopy

#Source
$Keys = Get-AzureRmStorageAccountKey -ResourceGroupName $SourceRG -Name $SourceSAN
$CXT = New-AzureStorageContext -StorageAccountName $SourceSAN -StorageAccountKey $Keys[0].value
$sourceblob = Get-AzureStorageBlob -Blob Nano-WindowsServerTechnicalPreview5.vhd -Container templates -Context $CXT
$sourceblob
$sourceblob | Get-Member
# Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageBlob
$sourceblob.ICloudBlob | ft -AutoSize
$sourceblob.ICloudBlob.GetType().fullname
$sourceblob.ICloudBlob | gm
# This is really useful for programatic capablities on Blobs
# E.g.
$sourceblob.ICloudBlob.CreateSnapshot()

#DestinationContainer
New-AzureRmResourceGroup -Name $RG -Location $Location
$SA = New-AzureRmStorageAccount -ResourceGroupName $RG -Name $SAN -Location $Location -SkuName Standard_LRS
# $SA = Get-AzureRmStorageAccount -ResourceGroupName $RG -Name $SAN
$Container = New-AzureStorageContainer -Name templates -Context $SA.Context
# $Container = Get-AzureStorageContainer -Name templates -Context $SA.Context
$Container
$Container | Get-Member
# Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageContainer
$Container.PublicAccess
$Container.CloudBlobContainer
$Container.CloudBlobContainer.GetType().fullname
$Container.CloudBlobContainer | gm
# This is really useful for programatic capablities on the Container

#DestinationBlob
$destblob = $Container.CloudBlobContainer.GetBlobReference('Nano-WindowsServerTechnicalPreview5.vhd')
$destblob
$destblob.GetType().fullname

# The command does have many aliases for the CloudBlob and the DestCloudBlob
Get-Command -Name Start-AzureStorageBlobCopy | ForEach-Object {
    $_.parameters.values | Where { $_.aliases } | Select name, aliases}

# Doing the copy
Start-AzureStorageBlobCopy -CloudBlob $sourceblob.ICloudBlob -DestCloudBlob $destblob -Force

Get-AzureStorageBlob -Container templates -Context $SA.Context

$Container.CloudBlobContainer.ListBlobs() | fl

$destblob.StorageUri
# This download takes 15 minutes
$destblob.DownloadToFileAsync('d:\new.vhd',[System.IO.FileMode]::Create)
$destblob.Delete()


# Cleanup the Resource Group and storage accounts
Remove-AzureRmStorageAccount -ResourceGroupName $RG -Name $SAN -Force
Remove-AzureRmResourceGroup -Name $RG -Force