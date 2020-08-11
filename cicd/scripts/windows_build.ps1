<#
    .SYNOPSIS
        This script verifies, tests, builds and packages the New Relic Infrastructure Agent
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
    [switch]$installer=$false,
    # Creates a tar package
    [switch]$tarball=$false,
    # Skip tests
    [switch]$skipTests=$false,
    # nri-flex
    [string]$nriFlexVersion=$(Get-Content ./scripts/nri-integrations | %{if($_ -match "^nri-flex") { $_.Split(',')[1]; }}),
    #fluent-bit
    [string]$nrfbArtifactVersion=$(Get-Content ./scripts/logging/nr_fb_version| %{if($_ -match "^windows") { $_.Split(',')[3]; }}),
    [string]$artifactoryToken,
    # Skip signing
    [switch]$skipSigning=$false,
    # Signing tool
    [string]$signtool='"C:\Program Files (x86)\Windows Kits\10\bin\x64\signtool.exe"'
)
echo "--- Configuring version for artifacts"
# If the build number is numeric
if ([System.Int32]::TryParse($patch, [ref]0)) {
    .\windows_set_version.ps1 -major $major -minor $minor -patch $patch
} else {
    echo " - setting 1.0.0 as development version"
    .\windows_set_version.ps1 -major $major -minor $minor -patch 0
}
echo "--- Checking dependencies"
echo "Checking Go..."
go version
if (-not $?)
{
    echo "Can't find Go"
    exit -1
}
go mod download
echo "Checking MSBuild.exe..."
$msBuild = (Get-ItemProperty hklm:\software\Microsoft\MSBuild\ToolsVersions\4.0).MSBuildToolsPath
if ($msBuild.Length -eq 0) {
    echo "Can't find MSBuild tool. .NET Framework 4.0.x must be installed"
    exit -1
}
echo $msBuild
$env:GOOS="windows"
$env:GOARCH=$arch
echo "--- Collecting files"
$goFiles = go list ./...
## Something no right about `go fmt` on Windows. It is reporting files aren't correct.
# echo "--- Format check"
# $wrongFormat = go fmt $goFiles
# if ($wrongFormat -and ($wrongFormat.Length -gt 0))
# {
#     echo "ERROR: Wrong format for files:"
#     echo $wrongFormat
#     exit -1
# }
if (-Not $skipTests) {
    echo "--- Running tests"
    go test $goFiles
    if (-not $?)
    {
        echo "Failed running tests"
        exit -1
    }
}
echo "--- Running Build"
go build -v $goFiles
if (-not $?)
{
    echo "Failed building files"
    exit -1
}
echo "--- Collecting Go main files"
$packages = go list -f "{{.ImportPath}} {{.Name}}" ./...  | ConvertFrom-String -PropertyNames Path, Name
$goMains = $packages | ? { $_.Name -eq 'main' } | % { $_.Path }
echo "--- Cleaning target..."
Remove-Item -Path "target" -Force -Recurse
Foreach ($pkg in $goMains)
{
    echo "generating $pkg"
    go generate $pkg
}
echo "--- Running Full Build"
Foreach ($pkg in $goMains)
{
    $fileName = ([io.fileinfo]$pkg).BaseName
    echo "creating $fileName"
    $exe = ".\target\bin\windows_$arch\$fileName.exe"
    go build -ldflags "-X main.buildVersion=$major.$minor.$patch" -o $exe $pkg
     if (-Not $skipSigning) {
         iex "& $signtool sign /d 'New Relic Infrastructure Agent' /n 'New Relic, Inc.' $exe"
    }
}
if (-Not $skipSigning) {
    iex "& $signtool sign /d 'New Relic Infrastructure Agent' /n 'New Relic, Inc.'  .\assets\windows\$arch\winpkg\nr-winpkg.exe"
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
If ($tarball) {
    echo "--- Building tarball"
    .\windows_tar.ps1 -major $major -minor $minor -patch $patch -arch $arch
}
If (-Not $installer) {
    exit 0
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