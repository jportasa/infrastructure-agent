param (
    # Target architecture: amd64 (default) or 386
    [ValidateSet("amd64", "386")]
    [string]$arch="amd64",
    [string]$version="0.0.0",
    [string]$pfx_passphrase="none",
    # nri-flex
    [string]$nriFlexVersion,
    #fluent-bit
    #[string]$nrfbArtifactVersion,
    # Signing tool
    [string]$signtool='"C:\Program Files (x86)\Windows Kits\10\bin\x64\signtool.exe"'
)

echo "===> Import .pfx certificate from GH Secrets"
Import-PfxCertificate -FilePath ..\..\mycert.pfx -Password (ConvertTo-SecureString -String $pfx_passphrase -AsPlainText -Force) -CertStoreLocation Cert:\CurrentUser\My

echo "===> Show certificate installed"
Get-ChildItem -Path cert:\CurrentUser\My\

echo "===> Download main infra agent binaries from GH release"
$file = "newrelic-infra_binaries_windows_${version}_${arch}.zip"
write-host "URL to download:" "https://github.com/jportasa/infrastructure-agent/releases/download/v${version}/${file}"
$url = "https://github.com/jportasa/infrastructure-agent/releases/download/v${version}/${file}"

Invoke-WebRequest $url -OutFile $file
Expand-Archive $file -DestinationPath "..\..\target\bin\windows_$arch\"
ls "..\..\target\bin\windows_$arch\"

echo "===> Embedding external components"
echo "===> Embeding Flex"
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

echo "===> Embeding Fluentbit"
${repo_root_path}='D:\a\infrastructure-agent\infrastructure-agent\'
$fbArch = "win64"
if($arch -eq "386") {
   $fbArch = "win32"
}
# Download fluent-bit artifacts.
#$ProgressPreference = 'SilentlyContinue'
#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#Invoke-WebRequest "https://artifacts.datanerd.us/ohai-repo/logging/windows/nrfb-$nrfbArtifactVersion-$fbArch.zip" -Headers @{"X-JFrog-Art-Api"="$artifactoryToken"} -OutFile nrfb.zip

#expand-archive -path '.\nrfb.zip' -destinationpath '.\'
#Remove-Item -Force .\nrfb.zip
$fluentbitPath = "${repo_root_path}\target\nri-flex"

iex "& $signtool sign /d 'New Relic Infrastructure Agent' /n 'Contoso'  ${repo_root_path}\external_content\windows\amd64\fluentbit\fluent-bit.exe"

#Move the files to packaging.
#$nraPath = "$root_path\external_content\windows\amd64\fluentbit\target\bin\windows_$arch\"
#New-Item -path "$nraPath\logging" -type directory -Force
#Copy-Item -Path ".\nrfb\*" -Destination "$nraPath\logging" -Recurse -Force
#Remove-Item -Path ".\nrfb" -Force -Recurse

#Move the files to packaging.
New-Item -path  "${repo_root_path}\logging.d" -type directory -Force
New-Item -path  "${repo_root_path}\target\newrelic-integrations\logging" -type directory -Force
Copy-Item -Path "${repo_root_path}\external_content\windows\amd64\fluentbit\file.yml.example" -Destination "${repo_root_path}\target\logging.d" -Force
Copy-Item -Path "${repo_root_path}\external_content\windows\amd64\fluentbit\fluentbit.yml.example" -Destination "${repo_root_path}\target\logging.d" -Force
Copy-Item -Path "${repo_root_path}\external_content\windows\amd64\fluentbit\fluent-bit.dll" -Destination "${repo_root_path}\target\newrelic-integrations\logging" -Force
Copy-Item -Path "${repo_root_path}\external_content\windows\amd64\fluentbit\fluent-bit.exe" -Destination "${repo_root_path}\target\newrelic-integrations\logging" -Force

$msBuild = (Get-ItemProperty hklm:\software\Microsoft\MSBuild\ToolsVersions\4.0).MSBuildToolsPath
if ($msBuild.Length -eq 0) {
    echo "Can't find MSBuild tool. .NET Framework 4.0.x must be installed"
    exit -1
}
echo $msBuild

echo "===> Create msi"
$env:path = "$env:path;C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin"
Push-Location -Path "..\..\build\package\windows\newrelic-infra-$arch-installer\newrelic-infra"
. $msBuild/MSBuild.exe newrelic-infra-installer.wixproj /p:AgentVersion=${version} /p:IncludeFluentBit=true


echo "===>Making versioned installed copy"
cd bin\Release
cp newrelic-infra-$arch.msi newrelic-infra-${arch}.${version}.msi
Pop-Location