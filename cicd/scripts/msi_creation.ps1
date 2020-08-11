## This is a sample GitHub Action script written in PowerShell Core.
## You can write your logic in PWSH to perform GitHub Actions.
##


## You interface with the Actions/Workflow system by interacting
## with the environment.  The `GitHubActions` module makes this
## easier and more natural by wrapping up access to the Workflow
## environment in PowerShell-friendly constructions and idioms
if (-not (Get-Module -ListAvailable GitHubActions)) {
    ## Make sure the GH Actions module is installed from the Gallery
    Install-Module GitHubActions -Force
}

## Load up some common functionality for interacting
## with the GitHub Actions/Workflow environment
Import-Module GitHubActions

#$PFX_PASSPHRASE = $env:PFX_PASSPHRASE
Import-PfxCertificate -FilePath .\mycert.pfx -Password (ConvertTo-SecureString -String $PFX_PASSPHRASE -AsPlainText -Force) -CertStoreLocation Cert:\LocalMachine\Root