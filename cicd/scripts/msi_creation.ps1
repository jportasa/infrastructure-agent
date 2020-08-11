

$PFX_PASSPHRASE = $env:PFX_PASSPHRASE
$arch = 'amd64'
$tag = 'v1.0.27'

echo "--- Import pfx certificate"
Import-PfxCertificate -FilePath ..\..\mycert.pfx -Password (ConvertTo-SecureString -String $(PFX_PASSPHRASE) -AsPlainText -Force) -CertStoreLocation Cert:\LocalMachine\Root
$file = "newrelic-infra_binaries_windows_1.0.27_$arch.zip"
$url = "https://github.com/jportasa/infrastructure-agent/releases/download/$tag/$file"

echo "--- Download binaries from GH release"
Invoke-WebRequest $url -OutFile $file
Expand-Archive $file -DestinationPath "..\..\target\bin\windows_$arch\"
ls "..\..\target\bin\windows_$arch\

echo "--- Create msi"
$env:path = "$env:path;C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin"
Push-Location -Path ".\..\..\build\package\windows\newrelic-infra-$(arch)-installer\newrelic-infra"
. MSBuild.exe newrelic-infra-installer.wixproj