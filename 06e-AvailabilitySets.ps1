break

# Add-AzureRmAccount


# set some variables that we will use
$location = "WestUS2"
$rgName = "rgFirst"

# get all current availability sets
Get-AzureRmAvailabilitySet -ResourceGroupName $rgName 

# get specific availabilty set
Get-AzureRmAvailabilitySet -ResourceGroupName $rgName `
          -Name "asProd-01"

# create a variable for our new availability set name
$asName = "asDev03"

 # create an new availablity set
$asInternal = New-AzureRmAvailabilitySet -ResourceGroupName $rgName `
          -Name $asName `
          -Location $location

# create a new VM configuration object
$MyVM = New-AzureRMVMConfig -VMName 'VM1_DevJumpBox' `
          -VMSize 'Standard_D2' `
          -AvailabilitySetId $asInternal.Id

# view the VM configuration object
$MyVM | select *

# view details of availablity set
$MyVM.AvailabilitySetReference 
