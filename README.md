> All code and contents are distributed under the MIT License


[![Open in GitHub Codespaces](https://img.shields.io/static/v1?style=for-the-badge&label=GitHub+Codespaces&message=Open&color=brightgreen&logo=github)](https://codespaces.new/Patrick-Davis-MSFT/demoFrames)
[![Open in Dev Container](https://img.shields.io/static/v1?style=for-the-badge&label=Dev+Containers&message=Open&color=blue&logo=visualstudiocode)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/Patrick-Davis-MSFT/demoFrames)

# Framed Demo UI
This code is a starter pack for coded demos. Add to the readme file as needed

# Install and Setup 
This project uses Azure Developer Command line to install. [Azure Developer CLI Documentation](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/) is publicly available. Normally this can be installed by using `winget install Microsoft.Azd`

## Prerequisites
The following software is helpful for install

* Azure Powershell
* Azure CLI 
* Azure Developer CLI
* Bicep
* Python
* Access to this repo
* npm
* node


## Install Steps

1. `azd auth login` follow the instructions on the screen
1. `az login` follow the instructions on the screen (both are needed)
1. `azd init -t Patrick-Davis-MSFT/AlertingAI` This will download the code but will not initialize a git repository for development. 
1. `azd up` This will provision, hydrate, and deploy the demonstration
1. When finished `azd down` will remove all resources

## Local development
> Local Development will need the commands `azd auth login`, `az login` and `azd provision` run to establish secrets and key vaults

To run locally use `azd provision` to deploy the infrastructure and hydrate the databases. Then in the `app-ui` directory run `.\start.ps1`. 

## Contributing to the repo

1. Direct check-ins are not allowed. Please create a pull request from your own repo
