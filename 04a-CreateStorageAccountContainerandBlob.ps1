break

#Requires -Module AzureRM.Profile
#Requires -Module AzureRM.Storage
#Requires -Module Azure.Storage

$RG = 'rgModule4a'
$Location = 'EastUS2'
$Type = 'Standard_LRS'
$SAN = 'saeastusmodule4a'

New-azurermResourceGroup -name $RG -Location $Location

# Check availability of the Storage Account Name before creating
Get-AzureRmStorageAccountNameAvailability -Name $SAN

# If its available create
$SA = New-AzureRmStorageAccount -ResourceGroupName $RG -Name $SAN -Type $Type -Location $Location
$SA

# The context is returned
$SA.context

# if you already have a storage account you can still get the context
$SA = Get-AzureRmStorageAccount -ResourceGroupName $RG -Name $SAN
$SA.Context

# You can also pull the master keys, however this is not a good thing to share
Get-AzureRmStorageAccountKey -ResourceGroupName $RG -Name $SAN

# ----- Note these commands are generic, not RM specific
# when working with these you need to have the context

# Create a new Container (always lower case), we'll cover permission later
New-AzureStorageContainer -Name configurations -Context $SA.Context -Permission Container

Get-AzureStorageContainer -Context $SA.Context -Name configurations

# You can also set the default context to work with
Get-AzureRmContext
Set-AzureRmCurrentStorageAccount -ResourceGroupName $RG -Name $SAN
Get-AzureRmContext

# Upload a text file for testing (using context or using the default context if it has been set)
'this is a container for configurations' | Set-Content -Path D:\Azure\thisisacontainerforconfigurations.txt

Set-AzureStorageBlobContent -Container configurations `
    -File D:\Azure\thisisacontainerforconfigurations.txt -Context $SA.Context

Set-AzureStorageBlobContent -Container configurations -File D:\Azure\BaseOSTest.ps1 

# Download the Blob
Get-AzureStorageBlob -Container configurations -Blob BaseOSTest.ps1 -OutVariable Blob
$Blob | Get-AzureStorageBlobContent -Destination d:\temp.txt
Get-Item -Path d:\temp.txt
Get-Content -Path d:\temp.txt

# Access the Blob by the Public?
## What is the URL?
Get-AzureStorageBlob -Container configurations -Blob thisisacontainerforconfigurations.txt -OutVariable Blob2
$Blob2.ICloudBlob | Format-List
$Blob2.ICloudBlob | Get-Member
$Blob2.ICloudBlob.Uri
$URI = $Blob2.ICloudBlob.Uri.AbsoluteUri

## What are the permissions?
Get-AzureStorageContainerAcl -Name configurations | select Name,PublicAccess
## Read the contents of the file
Invoke-RestMethod -Uri $URI -UseBasicParsing

## Update the permissions
Set-AzureStorageContainerAcl -Name configurations -Permission Off -PassThru

## Try and access it again
Invoke-RestMethod -Uri $URI -UseBasicParsing

## Reset this for the next lesson
Set-AzureStorageContainerAcl -Name configurations -Permission Container -PassThru

# You can also set on Blob
Set-AzureStorageContainerAcl -Name configurations -Permission Blob -PassThru
Get-AzureStorageContainerAcl -Name configurations

# We will continue to use this storage account in the next Lesson.