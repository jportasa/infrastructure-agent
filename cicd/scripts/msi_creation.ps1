param (
    # Target architecture: amd64 (default) or 386
    [ValidateSet("amd64", "386")]
    [string]$arch="amd64",
    [string]$tag="0.0.0",
    [string]$pfx_passphrase='none',
    # nri-flex
    [string]$nriFlexVersion,
    #fluent-bit
    #[string]$nrfbArtifactVersion,
    # Signing tool
    [string]$signtool='"C:\Program Files (x86)\Windows Kits\10\bin\x64\signtool.exe"'
)

echo "===> Import .pfx certificate"
Import-PfxCertificate -FilePath ..\..\mycert.pfx -Password (ConvertTo-SecureString -String $pfx_passphrase -AsPlainText -Force) -CertStoreLocation Cert:\LocalMachine\My
$file = "newrelic-infra_binaries_windows_1.0.27_$arch.zip"
$url = "https://github.com/jportasa/infrastructure-agent/releases/download/$tag/$file"

echo "===> Download main infra agent binaries from GH release"
Invoke-WebRequest $url -OutFile $file
Expand-Archive $file -DestinationPath "..\..\target\bin\windows_$arch\"
ls "..\..\target\bin\windows_$arch\"

echo "===> Embedding external components"
# embded flex
# download
[string]$release="v${nriFlexVersion}"
[string]$file="nri-flex_${nriFlexVersion}_Windows_x86_64.zip"
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
write-host "https://github.com/newrelic/nri-flex/releases/download/$release/$file"
Invoke-WebRequest "https://github.com/newrelic/nri-flex/releases/download/$release/$file" -OutFile "..\..\target\nri-flex.zip"
# embed:
$flexPath = "..\..\target\nri-flex"
$nraPath = "..\..\target\bin\windows_$arch"
# extract
New-Item -path $flexPath -type directory -Force
expand-archive -path '..\..\target\nri-flex.zip' -destinationpath $flexPath
Remove-Item '..\..\target\nri-flex.zip'
# flex binaries
Copy-Item -Path "$flexPath\nri-flex.exe" -Destination "$nraPath" -Force
# nrjmx
#Copy-Item -Path "$flexPath\nrjmx" -Destination "$nraPath\" -Recurse -Force
# clean
Remove-Item -Path $flexPath -Force -Recurse

# # embded fluent-bit
# $fbArch = "win64"
# if($arch -eq "386") {
#    $fbArch = "win32"
# }
# # Download fluent-bit artifacts.
# $ProgressPreference = 'SilentlyContinue'
# [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Invoke-WebRequest "https://artifacts.datanerd.us/ohai-repo/logging/windows/nrfb-$nrfbArtifactVersion-$fbArch.zip" -Headers @{"X-JFrog-Art-Api"="$artifactoryToken"} -OutFile nrfb.zip
# expand-archive -path '.\nrfb.zip' -destinationpath '.\'
# Remove-Item -Force .\nrfb.zip
# iex "& $signtool sign /d 'New Relic Infrastructure Agent' /n 'New Relic, Inc.'  .\nrfb\fluent-bit.exe"

# Move the files to packaging.
# $nraPath = "..\..\target\bin\windows_$arch\"
# New-Item -path "$nraPath\logging" -type directory -Force
# Copy-Item -Path ".\nrfb\*" -Destination "$nraPath\logging" -Recurse -Force
# Remove-Item -Path ".\nrfb" -Force -Recurse

echo "===> Binaries to embed:"
ls ..\..\target\bin\windows_$arch

$msBuild = (Get-ItemProperty hklm:\software\Microsoft\MSBuild\ToolsVersions\4.0).MSBuildToolsPath
if ($msBuild.Length -eq 0) {
    echo "Can't find MSBuild tool. .NET Framework 4.0.x must be installed"
    exit -1
}
echo $msBuild

echo "===> Create msi"
$env:path = "$env:path;C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin"
Push-Location -Path "..\..\build\package\windows\newrelic-infra-$arch-installer\newrelic-infra"
. $msBuild/MSBuild.exe newrelic-infra-installer.wixproj /p:AgentVersion=1.2.3 /p:IncludeFluentBit=false
