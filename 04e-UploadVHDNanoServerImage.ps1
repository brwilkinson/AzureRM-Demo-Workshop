break

#requires -module AzureRM.Profile
#requires -module AzureRM.Storage
#requires -module Azure.Storage

$LocalPathtoVHD = 'D:\Source\Nano-WindowsServerTechnicalPreview5.vhd'
$RG             = 'rgModule4e'
$SAN             = 'saeastus2module4e'
$Location       = 'EastUS2'

if (-not (Test-path -Path $LocalPathtoVHD))
{
    Invoke-WebRequest -Uri http://aka.ms/nanoevalvhd -OutFile $LocalPathtoVHD
}
else {Write-Warning -Message "Nano Image is already downloaded"}

# --------------------------------------
#create VM for Nano locally
$VMName = 'NanoTest'
$Path = "D:\VMs"
$VHDPath = "$Path\$VMName\$VMName.vhd"
New-Item -Path $Path\$VMName -ItemType Directory
Copy-Item -Path $LocalPathtoVHD -Destination $VHDPath -PassThru
New-VM -Name $VMName -Path $Path -BootDevice VHD -MemoryStartupBytes (1GB) -VHDPath $VHDPath
Start-VM -Name $VMName
Get-VM -Name $VMName
# Log on via gui and set Administrator Password, Can shutdown from within VM as well.
Stop-VM -Name $VMName
# --------------------------------------

New-AzureRmResourceGroup -Name $RG -Location $Location

$SA = New-AzureRmStorageAccount -ResourceGroupName $RG -Name $SAN -Type Standard_LRS -Location $Location

Set-AzureRmCurrentStorageAccount -ResourceGroupName $RG -Name $SAN
Get-AzureRmContext

# new context, no containers
Azure.Storage\Get-AzureStorageContainer

# We will create a new container for the Images
Azure.Storage\New-AzureStorageContainer -Name vhds
#Azure.Storage\Remove-AzureStorageContainer -Context $StorageAccountContext -Name vhds 
Azure.Storage\Get-AzureStorageContainer

# new container, no blobs
Get-AzureStorageBlob -Container vhds

# Note if we were going to upload the template we would use Add-AzureRmVhd
# This is just a custom image that we want to reuse (no sysprep)

# currently this is not working, it's timing out I opened a bug
# Lower ConcurrentTaskCount for large files, use azcopy instead

#File to upload
$File = Get-ChildItem -Path $VHDPath -File

<#
# This is what we used to copy up files before, this fails with large files 

Set-AzureStorageBlobContent -File $File -Container vhds -BlobType Page `
     -Context $StorageAccountContext -ConcurrentTaskCount 1
#>
# Storage account Key to allow the upload
$StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $RG -Name $SAN)[0].Value

# the azcopy executable path
$AzCopyPath = 'C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe'

# The upload location
$UploadLocation = $SA.Context.BlobEndPoint + 'vhds'

# azcopy help
& $AzCopyPath /?

# Start time
$s = Get-Date

# The full PowerShell command to run azcopy with its arguments
& $AzCopyPath "/Source:$($File.Directory)", "/Pattern:$($File.Name)" , "/Dest:$UploadLocation", 
"/DestKey:$StorageAccountKey", "/Y", "/NC:1", "/BlobType:Page", "/Z:$env:LocalAppData\Microsoft\Azure\AzCopy\$RG"

# End timespan for the upload
New-TimeSpan -Start $s -End (Get-Date) | select TotalMinutes

# This takes about 15 mins to upload
# We will cover how to create a new VM from an Image in Modules 6 and 7

# Take a look in the Portal or with Storage Explorer

# Cleanup the Resource Group and storage accounts
Remove-AzureRmStorageAccount -ResourceGroupName $RG -Name $SAN -Force
Remove-AzureRmResourceGroup -Name $RG -Force