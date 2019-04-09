break

#Requires -Module AzureRM.Profile
#Requires -Module AzureRM.Storage
#Requires -Module Azure.Storage

# Using the context from the last Lesson.
Get-AzureRmContext

# Create the SAS Token on the whole storage account
New-AzureStorageAccountSASToken -Service Blob,File,Table,Queue  -ResourceType Service,Container,Object `
        -Permission racwdlup -Protocol HttpsOnly -OutVariable AccountSAS `
        -ExpiryTime ([datetime]::Today.ToUniversalTime().Adddays(2))
$AccountSAS

# Create new context using the SAS token for the Container
$Context = New-AzureStorageContext -Protocol Https -StorageAccountName saeastus2module4c -SasToken $AccountSAS[0]

Get-AzureStorageBlob -Container results -context $Context | select Name,LastModified

$Name = 'Server_Uptime_Report_2010_12_02.csv'
$Path = "d:\$Name"
Get-AzureStorageBlobContent -Context $Context -Container results -Blob $Name -Destination $Path
Import-Csv -Path $Path | select -First 5 | ft -AutoSize


# Now demo Azure Storage Explorer

# Get the container URI
$Container = Get-AzureStorageBlob -Container results -context $Context -Blob $Name  | 
    foreach { $_.ICloudBlob.Container.URI.AbsoluteUri }

# Plus the SAS token
$Container + $AccountSAS | Set-Clipboard

# https://saeastus2module4c.blob.core.windows.net/results?sv=2015-04-05&sig=KZgIAtTz%2BPyuhOKW4U6h4GSDG9qcGHfQznyaCcUJ5nQ%3D&spr=https&se=2016-09-20T04%3A00%3A00Z&srt=sco&ss=bfqt&sp=racupwdl
# https://saeastus2module4c.blob.core.windows.net/results?sv=2015-04-05&sig=2JGRFwiOrj%2FErA%2FpLCbI1YDQ8abQr%2BDW182v1FLxmh8%3D&spr=https&se=2016-09-29T07%3A00%3A00Z&srt=sco&ss=bfqt&sp=racupwdl
Get-AzureStorageBlob -context $Context