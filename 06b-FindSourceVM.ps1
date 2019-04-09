break

# Add-AzureRmAccount

# create the vm configuration object if not already created
<# 
    $MyVM = New-AzureRMVMConfig -VMName VM1_DevJumpBox -VMSize Standard_D2
#>

# retrieve the list of publisher names of images in Azure
$Location="West US"
Get-AzureRMVMImagePublisher -Location $location | Select PublisherName

# get a non-Microsoft publisher
Get-AzureRmVMImagePublisher -Location $location | 
    where PublisherName -like '*red*' | 
    Select PublisherName

# obtain offerings from the publisher
$pubName="MicrosoftWindowsServer"
Get-AzureRMVMImageOffer -Location $location -Publisher $pubName | Select Offer

# get offerings from another publisher
Get-AzureRmVMImageOffer -Location $location -PublisherName redhat | Select Offer

# obtain skus from different publisher offer
Get-AzureRmVMImageSku -Location $location -PublisherName redhat `
     -Offer RHEL | 
     select Skus

# retrieve the SKUs of the offering
$offerName="WindowsServer"
Get-AzureRMVMImageSku -Location $location `
    -Publisher $pubName `
    -Offer $offerName | 
    Select Skus

# retrieve versions for another publisher's Sku
Get-AzureRmVMImage -Location $location -Offer RHEL `
    -PublisherName redhat -Skus 7.2 

# retrieve versions for the SKU
$skuName = "2012-R2-Datacenter"
Get-AzureRmVMImage -Location $location -Offer $offerName `
    -PublisherName MicrosoftWindowsServer -Skus $skuName 

# From this list, copy the chosen SKU name for the Set-AzureRmVMSourceImage cmdlet, 
$MyVM = Set-AzureRmVMSourceImage -VM $MyVM -PublisherName $pubName `
    -Offer $offerName -Skus $skuName `
    -Version "latest" # or version number, i.e., "4.0.20160915"

# view the properties of the VM object
$myVM | select *

# view the storage profile of the VM object
$myVM.StorageProfile.ImageReference

