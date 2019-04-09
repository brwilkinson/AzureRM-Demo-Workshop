break
#Requires -Module AzureRM.Profile

# List the Commands available for ARM Subscriptions by using the following command:
Get-Command –Module AzureRM.Profile –Noun AzureRMSubscription

# explore Login-AzureRmAccount alias
get-command Login-AzureRmAccount 
(get-command Login-AzureRmAccount).Definition

# login to account with alias for Add-AzureRmAccount
Login-AzureRmAccount
# the credentials are valid for 12 hours

# if not multifactor authentication
$cred = Get-Credential
Add-AzureRmAccount -Credential $cred

# if not multifactor authentication
$cred = Get-Credential
Add-AzureRmAccount -Credential $cred

# List the subscriptions available in the account by running the Get-AzureRmSubscription cmdlet:
Get-AzureRmSubscription
<# 
   Take note of the information displayed in screen, particularly the subscription name and ID since we will 
   use it in the next steps.
#>

# Determine the default (selected) subscription by running the Get-AzureRmContext
Get-AzureRmContext

# When two or more subscriptions are associated to one Microsoft account, you can use the Select-AzureRmSubscription 
# cmdlet to indicate which subscription to use. If you only have one subscription, this cmdlet is innocuous. Run:
Select-AzureRmSubscription -SubscriptionName "<Your Subscription Name>"
# or
Select-AzureRmSubscription -SubscriptionId "<Your Subscription Id>"
<# 
  If you have two or more subscriptions under the same name, instead of using the SubscriptionName parameter, 
  you should use the SubcriptionId parameter. After you execute the above command, from this point on all Azure 
  cmdlets will execute against the currently selected subscription.
#>