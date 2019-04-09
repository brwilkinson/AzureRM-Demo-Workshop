#Requires -Module AzureRM.Automation

$AAName = 'IaaSAutomation'
$RgName = 'rgGlobal'

$AAAccount = @{
        AutomationAccountName = $AAName  
        ResourceGroupName     = $RgName
        OutVariable           = 'result'
    }

#region Step 1 Import/Upload any required DSC Resource Modules
# Find the Module we need from the PowerShell Gallery and upload to Azure Automation
$modulename = 'xStorage'
$module = Find-Module -Name $modulename
$Link = $module.RepositorySourceLocation + 'package/' + $module.Name + '/' + $module.Version
New-AzureRmAutomationModule @AAAccount -Name $modulename -ContentLink $Link

Get-AzureRmAutomationModule @AAAccount -Name $modulename
#endregion

#region Step 2 Import/Upload the Configuration (BaseOSTest.ps1 file)
$ConfigurationName = 'BaseOSTest'
$ConfigurationPath = 'd:\azure'
$Configuration = @{
    SourcePath  = "$ConfigurationPath\$ConfigurationName.ps1"
    Description = 'A Test File'
    Published   = $True 
    Force       = $True
    }

Import-AzureRmAutomationDscConfiguration @AAAccount @Configuration
#endregion

#region Step 3 - confirm the configuration has been uploaded
Get-AzureRmAutomationDscNodeConfiguration @AAAccount
#endregion

#region Step 4 - Compile the configuration into the MOF
# * Consider any Params and ConfigurationData here
#$Params = @{FileContent = "Hello world"}
Start-AzureRmAutomationDscCompilationJob @AAAccount -ConfigurationName $ConfigurationName # -Parameters $Params
$Job = $Result.Id.Guid

while ($Result.Status -ne 'Complete')
{
    
    # Review the compilation job, make sure it completed compiling to MOF
    Get-AzureRmAutomationDscCompilationJob @AAAccount -Id $job
    Sleep -Seconds 5
}

# Alternatively you could upload a DSC mof configuration
#Import-AzureRmAutomationDscNodeConfiguration
#endregion