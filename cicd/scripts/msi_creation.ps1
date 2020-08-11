param (
    # Target architecture: amd64 (default) or 386
    [ValidateSet("amd64", "386")]
    [string]$arch="amd64",
    [string]$tag="0.0.0",
    # Creates a signed installer
    [string]$pfx_passphrase='none'
)

echo "--- Import pfx certificate"
Import-PfxCertificate -FilePath ..\..\mycert.pfx -Password (ConvertTo-SecureString -String $pfx_passphrase -AsPlainText -Force) -CertStoreLocation Cert:\LocalMachine\Root
$file = "newrelic-infra_binaries_windows_1.0.27_$arch.zip"
$url = "https://github.com/jportasa/infrastructure-agent/releases/download/$tag/$file"

echo "--- Download binaries from GH release"
Invoke-WebRequest $url -OutFile $file
Expand-Archive $file -DestinationPath "..\..\target\bin\windows_$arch\"
ls "..\..\target\bin\windows_$arch\"

echo "--- Create msi"
$env:path = "$env:path;C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin"
Push-Location -Path "..\..\build\package\windows\newrelic-infra-$arch-installer\newrelic-infra"
. MSBuild.exe newrelic-infra-installer.wixproj
