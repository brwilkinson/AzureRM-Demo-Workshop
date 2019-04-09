break

# requires -Module AzureRM.Profile
# requires -Module AzureRM.Network

#ClientVPN

$Deployment = 'Module5b'
$rg = ('rg' + $Deployment)
$location = 'eastus2'

#---------------------------------------------------------------------------------------------------

Get-AzureRmVirtualNetworkGateway -Name ('vng' + $Deployment) -ResourceGroupName $rg -OutVariable vng
$vng

# Add VPN Point to Site
Set-AzureRmVirtualNetworkGatewayVpnClientConfig -VirtualNetworkGateway $vng[0] -VpnClientAddressPool "172.10.10.0/24"


#---------------------------------------------------------------------------------------------------
$VPNCert = "D:\Azure\Certs\usercert.cer"
$Point2SitecertName = 'usercert'

$VPNCert = "D:\Azure\Certs\rootcert.cer"
$Point2SitecertName = 'rootcert'

$VPNCert = "D:\Azure\Certs\MFSTRootvpn.cer"
$Point2SitecertName = 'msrootcert'

Test-Path $VPNCert
$cert = new-object System.Security.Cryptography.X509Certificates.X509Certificate2($VPNCert)
$CertBase64 = [system.convert]::ToBase64String($cert.RawData)
$Point2Sitecert = New-AzureRmVpnClientRootCertificate -Name $Point2SitecertName -PublicCertData $CertBase64

$RootCertParams = @{
 VpnClientRootCertificateName = $Point2SitecertName
 VirtualNetworkGatewayname    = $vng[0].name 
 ResourceGroupName            = $RG 
 PublicCertData               = $Point2Sitecert.PublicCertData
}

Add-AzureRmVpnClientRootCertificate @RootCertParams


$URI = Get-AzureRmVpnClientPackage -ResourceGroupName $rg `
    -VirtualNetworkGatewayName $vng[0].Name -ProcessorArchitecture Amd64

Invoke-WebRequest -uri $URI.trim('"') -OutFile D:\Azure\VPN\vpn.exe
ii D:\Azure\VPN\vpn.exe


Get-AzureRmVpnClientRootCertificate -ResourceGroupName $RG -VirtualNetworkGatewayName $vng[0].Name

