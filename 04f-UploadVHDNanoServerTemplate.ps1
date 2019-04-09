break

#requires -module AzureRM.Profile
#requires -module AzureRM.Storage
#requires -module Azure.Storage

$LocalPathtoVHD = 'D:\Source\Nano-WindowsServerTechnicalPreview5.vhd'
$RG             = 'rgModule4f'
$SAN             = 'saeastus2module4f'
$Location       = 'EastUS2'

if (-not (Test-path -Path $LocalPathtoVHD))
{
    Invoke-WebRequest -Uri http://aka.ms/nanoevalvhd -OutFile $LocalPathtoVHD
}
else {Write-Warning -Message "Nano Image is already downloaded"}

New-AzureRmResourceGroup -Name $RG -Location $Location -Tag @{Name='Workshop';Value='Module4'}

$SA = New-AzureRmStorageAccount -ResourceGroupName $RG -Name $SAN -Type Standard_LRS -Location $Location

#$StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $RG -Name $SAN)[0].Value
$StorageAccountContext = $SA.Context
$StorageAccountContext

# new context, no containers
Azure.Storage\Get-AzureStorageContainer -Context $StorageAccountContext

# We will create a new container for the Images
Azure.Storage\New-AzureStorageContainer -Context $StorageAccountContext -Name templates

# new container, no blobs
Get-AzureStorageBlob -Context $StorageAccountContext -Container templates

# Revions on how we upload files normally
#
# Create a new file and upload to the new images container
New-Item D:\Azure\thisisacontainerfortemplates.txt -ItemType file -Force
Set-Content -Path D:\azure\thisisacontainerfortemplates.txt -Value thisisacontainerfortemplates
Set-AzureStorageBlobContent -Context $StorageAccountContext -Container templates -File D:\azure\thisisacontainerfortemplates.txt

# container with file
Get-AzureStorageBlob -Context $StorageAccountContext -Container templates -OutVariable MyBlob
$MyBlob | Get-AzureStorageBlobContent -Destination D:\azure\newfile.txt -Force
Get-Content -Path D:\azure\newfile.txt

# We upload templates using a dedicated cmdlet Add-AzureRmVhd

# upload the VHD to the newly created images container.
$templatevhdName = (Split-Path -Path $LocalPathtoVHD -Leaf)
$templatevhdName 
$templatevhdLocation = $StorageAccountContext.BlobEndPoint + 'templates/' + $templatevhdName
$templatevhdLocation
Add-AzureRmVhd -ResourceGroupName $RG -Destination $templatevhdLocation `
    -LocalFilePath $LocalPathtoVHD -NumberOfUploaderThreads 5 -Verbose -ov uploadvhd -OverWrite

# The above upload takes around 15 minutes

#region
#------------------------------------------------------------------------------------------
# In order to create a VM from a template, the template must be in the same Storage Account
# Next demo 4g
Start-AzureStorageBlobCopy

# We will cover creating Virtual machines in Module/s 6/7  
Set-AzureRmVMOSDisk -CreateOption fromImage -SourceImageUri $urlOfUploadedImageVhd -Windows
#endregion
#------------------------------------------------------------------------------------------


# Cleanup the Resource Group and storage accounts
Remove-AzureRmStorageAccount -ResourceGroupName $RG -Name $SAN -Force
Remove-AzureRmResourceGroup -Name $RG -Force