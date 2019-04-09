# RDP to vmFE5a

$CN = 'vmFE5a','vmMT5a','10.201.1.4'

$CN | ForEach-Object {
    Write-warning $_ 
    Test-Wsman -computername $_
    }

#ICMP is disabled by default
$CN | ForEach-Object {
    Write-warning $_ 
    Test-Connection -ComputerName $_ -Count 1
    }

#----------------
# Create a SMB Share on all 3 machines
New-Item -Path c:\networktest -ItemType dir
Set-Content -Path c:\networktest\network.txt -Value $env:COMPUTERNAME
Get-Content -Path C:\networktest\network.txt
New-SmbShare -Name networktest -ReadAccess everyone -Path c:\networktest

Get-NetFirewallRule -Name "WINRM-HTTP-In-TCP*"
Get-NetConnectionProfile

# Set the Firewall to enable WINRM from any address
Set-NetFirewallRule -Name "WINRM-HTTP-In-TCP-PUBLIC" -RemoteAddress Any

#----------------
# Test for SMB
$CN | ForEach-Object {
    Write-warning $_ 
    Test-Path \\$_\networktest 
    }


$CN | ForEach-Object {
    Write-warning $_ 
    Get-Content \\$_\networktest\network.txt
    }


#ICMP is now enabled after creating the share
$CN | ForEach-Object {
    Write-warning $_ 
    Test-Connection -ComputerName $_ -Count 1
    }

# Test RDP/SMB Ports
Test-NetConnection -CommonTCPPort RDP -ComputerName 'vmMT5a'
Test-NetConnection -CommonTCPPort RDP -ComputerName '10.201.1.4'
Test-NetConnection -CommonTCPPort SMB -ComputerName 'vmMT5a'
Test-NetConnection -CommonTCPPort SMB -ComputerName '10.201.1.4'

#----------------
# Now try to connect to the Public IP
$PublicIP = '13.68.103.43'
Test-wsman -ComputerName $PublicIP
$cred = Get-Credential brw
Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value $PublicIP -Concatenate
New-PSSession -ComputerName $PublicIP -Credential $cred -OutVariable s
Invoke-Command -Session $S -ScriptBlock {hostname}

# * So in conculsion we can connect between Subnets, however not between Vnets
# * Although we can connect via the PublicIP