break

#Requires -Module AzureRM.Profile
#Requires -Module AzureRM.Storage
#Requires -Module Azure.Storage

$RG = 'rgModule4c'
$Location = 'EastUS2'
$Type = 'Standard_LRS'
$SAN = 'saeastus2module4c'

New-azurermResourceGroup -name $RG -Location $Location

# Check availability of the Storage Account Name before creating
Get-AzureRmStorageAccountNameAvailability -Name $SAN

# If its available create
$SA = New-AzureRmStorageAccount -ResourceGroupName $RG -Name $SAN -Type $Type -Location $Location
# $SA = Get-AzureRmStorageAccount -ResourceGroupName $RG -Name $SAN
# The context is returned
$SA.context

# Set the default context, show F1
Set-AzureRmCurrentStorageAccount -ResourceGroupName $RG -Name $SAN
Get-AzureRmContext

# Create a new Container 
# * Always lower case/Note upper case used here for container name
New-AzureStorageContainer -Name Results

<#
New-AzureStorageContainer : 
    Container name 'Results' is invalid. 
    Valid names start and end with a lower case letter or a number and 
    has in between a lower case letter, number or dash with no consecutive dashes and 
    is 3 through 63 characters long.
#>

New-AzureStorageContainer -Name results
New-AzureStorageContainer -Name templates

# Upload some reports
$Results = 'D:\Azure\ServerUptime'
$Templates = 'D:\Azure\'
$download = 'D:\Azure\downloads'
Get-ChildItem -Path $Results | Set-AzureStorageBlobContent -Container results -ConcurrentTaskCount 5
Get-ChildItem -Path $Templates -Filter *.json | Set-AzureStorageBlobContent -Container templates -ConcurrentTaskCount 5

# Read the contents of the container
Get-AzureStorageContainer -Container results | Get-AzureStorageBlob | select Name

# Download the contents of the container
mkdir $download
Get-ChildItem -Path $download
Get-AzureStorageContainer -Container results | Get-AzureStorageBlob | Get-AzureStorageBlobContent -Destination $download
Get-ChildItem -Path $download

# Try to access outside of PowerShell, does not work?!
$URI = 'https://saeastus2module4c.blob.core.windows.net/results'
Invoke-RestMethod -Uri $URI -UseBasicParsing

# Show this in the Azure Portal now

# Resource group > Storage Account > Container > Blobs > Access Policy = Private
# Resource group > Storage Account > Access Keys = Key1 and Key2
# Resource group > Storage Account > Shared access signature = different settings.

#-------------------------------------------------------------------
# Now create some Share Access Signatures to allow access to a blob.
##1  Keys, SAS

# Blob
# New-AzureStorageBlobSASToken -Container results -Permission rl -Blob Server_Uptime_Report_2011_01_24.xls `

$BlobSASTokenParams = @{
    Container  = 'results'
    Permission = 'rl'
    Blob       = 'HelloWorld.txt'
    Context    = $SA.context
    OutVariable= 'Blob' 
    StartTime  = ((Get-Date).ToUniversalTime().AddHours(-10)) 
    ExpiryTime = ((Get-Date).ToUniversalTime().Adddays(10))
    }

New-AzureStorageBlobSASToken @BlobSASTokenParams
$Blob

<#
?sv=2015-04-05&
sr=b&
sig=9Ga%2FabNASuVgMyXuo8AQ6CYPS2dj48L5q3%2FLaK5DM%2Fo%3D&
st=2016-08-26T16%3A48%3A10Z&
se=2016-09-06T02%3A48%3A10Z&
sp=rl
#>


$OutPath = 'd:\HelloWorld.txt'
$SAS = "https://saeastus2module4c.blob.core.windows.net/results/HelloWorld.txt" + $Blob
Invoke-RestMethod -Uri $SAS
Invoke-RestMethod -Uri $SAS -OutFile $OutPath
Invoke-WebRequest -Uri $SAS -OutFile $OutPath
Get-Item -Path $OutPath
Get-Content -Path $OutPath

#-----------------------
# Now create some Share Access Signatures to allow access to a Container

Get-AzureStorageContainer -Container results |
    New-AzureStorageContainerSASToken -Permission rwdl -Protocol HttpsOnly `
        -ExpiryTime ([datetime]::Today.ToUniversalTime().Adddays(10)) `
     -OV Container 
    #-StartTime ([datetime]::Today.ToUniversalTime().AddHours(-10)) `
$Container

$SAS1 = "https://saeastus2module4c.blob.core.windows.net/results/Server_Uptime_Report_2010_12_02.csv" + $Container
$SAS2 = "https://saeastus2module4c.blob.core.windows.net/results/Server_Uptime_Report_2010_12_06.csv" + $Container
$SAS3 = "https://saeastus2module4c.blob.core.windows.net/results/Server_Uptime_Report_2010_12_08.csv" + $Container

Invoke-WebRequest -Method Get -Uri $SAS1 -OutFile new.txt
Import-Csv -Path .\new.txt | select -first 5 | ft -AutoSize

Invoke-RestMethod -Method Get -Uri $SAS2 | ConvertFrom-Csv | select -first 5 | ft -AutoSize

#-----------------------
# Account - Use a single SAS for all containers and blobs in the account
# Always better to provide SAS than provide the storage account Key.

Get-AzureStorageContainer | select Name,PublicAccess

New-AzureStorageAccountSASToken -Service Blob,File,Table,Queue  -ResourceType Service,Container,Object `
        -Permission racwdlup -Protocol HttpsOnly  -OV Account `
        -ExpiryTime ([datetime]::Today.ToUniversalTime().Adddays(2))
$Account

$URI = 'https://saeastus2module4c.blob.core.windows.net/results/Server_Uptime_Report_2010_12_02.csv' + $Account
Invoke-RestMethod -Uri $URI -Method get | ConvertFrom-Csv | select -first 5 | ft -AutoSize

$URI = 'https://saeastus2module4c.blob.core.windows.net/templates/azuredeploy.json' + $Account
Invoke-RestMethod -Uri $URI -Method get


<# 
  SAS tokens also apply for Files there.

# Share
    New-AzureStorageShareSASToken
# File
    New-AzureStorageFileSASToken
#>


# Cleanup the Resource Group and storage accounts
Remove-AzureRmStorageAccount -ResourceGroupName $RG -Name $SAN -Force
Remove-AzureRmResourceGroup -Name $RG -Force