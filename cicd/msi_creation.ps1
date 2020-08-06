<#
    .SYNOPSIS
        This script packages the New Relic Infrastructure Agent
#>
param (
    # Target architecture: amd64 (default) or 386
    [ValidateSet("amd64", "386")]
    [string]$arch="amd64",
    # Build number (to be attached to the agent version)
    [int]$major = 1,
    [int]$minor = 0,
    [string]$patch="dev",
    # Creates a signed installer
    [string]$nriFlexVersion=$(Get-Content ./scripts/nri-integrations | %{if($_ -match "^nri-flex") { $_.Split(',')[1]; }}),
    #fluent-bit
    [string]$nrfbArtifactVersion=$(Get-Content ./scripts/logging/nr_fb_version| %{if($_ -match "^windows") { $_.Split(',')[3]; }}),
    [string]$artifactoryToken,
    # Signing tool
    [string]$signtool='"C:\Program Files (x86)\Windows Kits\10\bin\x64\signtool.exe"'
)

echo "Checking MSBuild.exe..."
$msBuild = (Get-ItemProperty hklm:\software\Microsoft\MSBuild\ToolsVersions\4.0).MSBuildToolsPath
if ($msBuild.Length -eq 0) {
    echo "Can't find MSBuild tool. .NET Framework 4.0.x must be installed"
    exit -1
}

echo "--- Embedding external components"
# embded flex
if (-Not [string]::IsNullOrWhitespace($nriFlexVersion)) {
    # download
    [string]$release="v${nriFlexVersion}"
    [string]$file="nri-flex_${nriFlexVersion}_Windows_x86_64.zip"
    $ProgressPreference = 'SilentlyContinue'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest "https://github.com/newrelic/nri-flex/releases/download/${release}/${file}" -OutFile "target\nri-flex.zip"
    # embed:
    $flexPath = "target\nri-flex"
    $nraPath = "target\bin\windows_$arch"
    # extract
    New-Item -path $flexPath -type directory -Force
    expand-archive -path 'target\nri-flex.zip' -destinationpath $flexPath
    Remove-Item 'target\nri-flex.zip'
    # flex binaries
    Copy-Item -Path "$flexPath\nri-flex.exe" -Destination "$nraPath" -Force
    # nrjmx
    #Copy-Item -Path "$flexPath\nrjmx" -Destination "$nraPath\" -Recurse -Force
    # clean
    Remove-Item -Path $flexPath -Force -Recurse
}
# embded fluent-bit
$includeFluentBit = (
    -Not [string]::IsNullOrWhitespace($artifactoryToken))
if ($includeFluentBit) {
    $fbArch = "win64"
    if($arch -eq "386") {
        $fbArch = "win32"
    }
    # Download fluent-bit artifacts.
    $ProgressPreference = 'SilentlyContinue'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest "https://artifacts.datanerd.us/ohai-repo/logging/windows/nrfb-$nrfbArtifactVersion-$fbArch.zip" -Headers @{"X-JFrog-Art-Api"="$artifactoryToken"} -OutFile nrfb.zip
    expand-archive -path '.\nrfb.zip' -destinationpath '.\'
    Remove-Item -Force .\nrfb.zip
    if (-Not $skipSigning) {
        iex "& $signtool sign /d 'New Relic Infrastructure Agent' /n 'New Relic, Inc.'  .\nrfb\fluent-bit.exe"
    }
    # Move the files to packaging.
    $nraPath = "target\bin\windows_$arch\"
    New-Item -path "$nraPath\logging" -type directory -Force
    Copy-Item -Path ".\nrfb\*" -Destination "$nraPath\logging" -Recurse -Force
    Remove-Item -Path ".\nrfb" -Force -Recurse
}

echo "--- Building Installer"
Push-Location -Path "build\package\windows\newrelic-infra-$arch-installer\newrelic-infra"
. $msBuild/MSBuild.exe newrelic-infra-installer.wixproj /p:IncludeFluentBit=$includeFluentBit
if (-not $?)
{
    echo "Failed building installer"
    Pop-Location
    exit -1
}
echo "Making versioned installed copy"
cd bin\Release
cp newrelic-infra-$arch.msi newrelic-infra-$arch.$major.$minor.$patch.msi
cp newrelic-infra-$arch.msi newrelic-infra.msi
Pop-Location