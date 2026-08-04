# Create a self-signed code-signing cert for local MSIX installs.
#
# The Subject MUST equal the Publisher in AppxManifest.xml ("CN=Quartz Dev"),
# or Windows rejects the package. Run once; commit nothing (the .pfx is a
# secret). For production use a real / Azure Trusted Signing certificate instead.
#
#   powershell -ExecutionPolicy Bypass -File packaging\windows\make-cert.ps1

param(
    [string]$Subject  = "CN=Quartz Dev",
    [string]$PfxPath  = "packaging\windows\quartz-dev.pfx",
    [string]$Password = "quartz"
)

$ErrorActionPreference = "Stop"

$cert = New-SelfSignedCertificate `
    -Type CodeSigningCert `
    -Subject $Subject `
    -KeyUsage DigitalSignature `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}")

$securePwd = ConvertTo-SecureString -String $Password -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath $PfxPath -Password $securePwd | Out-Null

Write-Host "Wrote $PfxPath (subject $Subject)."
Write-Host "To let this machine install the signed MSIX, trust the cert:"
Write-Host "  Import-PfxCertificate -FilePath $PfxPath -CertStoreLocation Cert:\LocalMachine\TrustedPeople -Password (ConvertTo-SecureString $Password -AsPlainText -Force)"
