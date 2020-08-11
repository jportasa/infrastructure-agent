## This is a sample GitHub Action script written in PowerShell Core.
## You can write your logic in PWSH to perform GitHub Actions.
##

$arch = amd64
$msBuild = (Get-ItemProperty hklm:\software\Microsoft\MSBuild\ToolsVersions\4.0).MSBuildToolsPath

echo "--- Building Installer"
Push-Location -Path "build\package\windows\newrelic-infra-$arch-installer\newrelic-infra"
#. $msBuild/MSBuild.exe newrelic-infra-installer.wixproj /p:IncludeFluentBit=$
. $msBuild/MSBuild.exe newrelic-infra-installer.wixproj
#if (-not $?)
#{
#    echo "Failed building installer"
#    Pop-Location
#    exit -1
#}
#echo "Making versioned installed copy"
#cd bin\Release
#cp newrelic-infra-$arch.msi newrelic-infra-$arch.$major.$minor.$patch.msi
#cp newrelic-infra-$arch.msi newrelic-infra.msi
#Pop-Location