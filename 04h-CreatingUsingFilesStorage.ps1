break

#requires -module AzureRM.Profile
#requires -module AzureRM.Storage
#requires -module Azure.Storage

$RG       = 'rgModule4h1'
$SAN      = 'sawest2module4h1'
$Location = 'WestUS2'

New-AzureRmResourceGroup -Name $rg -Location $Location

New-AzureRmStorageAccount -Location $Location -Name $SAN -ResourceGroupName $rg -SkuName Standard_LRS

# Set the context for the current Storage Account
Set-AzureRmCurrentStorageAccount -ResourceGroupName $RG -Name $SAN
Get-AzureRmContext

# -----------------------------
# Create the new Shares in File Storage
New-AzureStorageShare -Name photos
New-AzureStorageShare -Name configurations
New-AzureStorageShare -Name users

# -----------------------------
# Set and Get the Quota
Get-AzureStorageShare -Name users | Set-AzureStorageShareQuota -Quota 2

$users = Get-AzureStorageShare -Name users
$users.Properties.Quota

$photos = Get-AzureStorageShare -Name photos
$photos.Properties.Quota

# -----------------------------
# Get a reference to the Share
$Configurations = Get-AzureStorageShare -Name configurations

# Create a new Directory
$Configurations | New-AzureStorageDirectory -Path ARM

# Upload a file
Set-AzureStorageFileContent -Share $Configurations -Path ARM -Source D:\azure\AD_armTemplate.json

# Download a file
Get-AzureStorageFileContent -Share $Configurations -Path ARM\AD_armTemplate.json -Destination d:\temp2.txt -PassThru -Force


$photos | New-AzureStorageDirectory -Path 2016 -OutVariable Directory
#$photos | New-AzureStorageDirectory -Path 2015 -OutVariable Directory

$photos | Set-AzureStorageFileContent -Path '2016\Azure SDK.png' -Source 'D:\Azure\Azure_ICONS\Azure SDK.png' -PassThru
$photos | Set-AzureStorageFileContent -Path '2016\Azure automation.png' -Source 'D:\Azure\Azure_ICONS\Azure automation.png' -PassThru

Get-AzureStorageShare -Name photos | Get-AzureStorageFile -Path '2016\Azure SDK.png' -OutVariable File

#----------
# A Share
$photos.GetType().fullname
# Microsoft.WindowsAzure.Storage.File.CloudFileShare
$photos | Get-Member
#Find the Directories in the Share
$photos.GetRootDirectoryReference().ListFilesAndDirectories()
#Find the Directories in the Share and the Files within
$photos.GetRootDirectoryReference().ListFilesAndDirectories().ListFilesAndDirectories()
# Get the URI of the Share
$a = $photos.Uri.AbsoluteUri

#----------
# A Directory
$Directory[0].gettype().fullname
# Microsoft.WindowsAzure.Storage.File.CloudFileDirectory
$Directory | Get-Member
$Directory[0].ListFilesAndDirectories() | ft -AutoSize

#----------
# A File
$File[0].gettype().fullname
# Microsoft.WindowsAzure.Storage.File.CloudFile
$File | Get-Member

$File.uri.AbsoluteUri


# -----------------------------
# Copy a file from one share to another, just put in the root of the users share
Start-AzureStorageFileCopy -SrcShare $Configurations -SrcFilePath ARM\AD_armTemplate.json `
                            -DestShareName users -DestFilePath AD_armTemplate.json 

#------------------------------------------------
# From Windows via SMB

# Get the storage account Key and create a credential
$SAKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $RG -Name $SAN)[0].Value
$SecureString = ConvertTo-SecureString -String $SAKey -AsPlainText -Force
$credential = [PSCredential]::new( $SAN, $SecureString )

# Map a drive using the credential
 $PSDriveParams = @{
    Name = 'Photos'; Root =  "\\$SAN.file.core.windows.net\photos" 
    Credential = $credential; PSProvider = 'FileSystem'
   }

New-PSDrive @PSDriveParams

# List the contents of the Share
Get-ChildItem -Path Photos:\

# Make a new directory
mkdir -Path Photos:\2017

# Copy file from the local machine to the Share
Get-ChildItem -Path D:\Azure\Azure_ICONS -Filter *storage* | 
    Copy-Item -Destination Photos:\2017 -PassThru

# List the contents of the Directory
Get-ChildItem -Path Photos:\2017

# Confirm the Cmdlets can also work, list the file
Get-AzureStorageShare -Name photos | Get-AzureStorageFile -Path '2017/Storage (Azure).png'

# Download the File using the cmdlets
Get-AzureStorageShare -Name photos | Get-AzureStorageFileContent -Path '2017/Storage (Azure).png' -Destination d:\temp3.png -PassThru