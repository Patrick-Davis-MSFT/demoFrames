> All code and contents are distributed under the MIT License


[![Open in GitHub Codespaces](https://img.shields.io/static/v1?style=for-the-badge&label=GitHub+Codespaces&message=Open&color=brightgreen&logo=github)](https://codespaces.new/Patrick-Davis-MSFT/demoFrames)
[![Open in Dev Container](https://img.shields.io/static/v1?style=for-the-badge&label=Dev+Containers&message=Open&color=blue&logo=visualstudiocode)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/Patrick-Davis-MSFT/demoFrames)

# Framed Demo UI
This code is a starter pack for coded demos. Add to the readme file as needed.

![Default Screen](./assets/Ui-Screen.png)

## HAPPY CODING

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

> These steps work in cloud shell. Be sure to grant execution on the ./scripts folder before executing `chmod 777 ./scripts`

1. `azd auth login` follow the instructions on the screen
1. `az login` follow the instructions on the screen (both are needed)
1. `azd init` This will download the code but will not initialize a git repository for development. 
1. `azd up` This will provision, hydrate, and deploy the demonstration
1. When finished `azd down` will remove all resources
1. There is a bug that requires `azd provision --no-state` to be run afterwards to fully set the app enviroment variables

## Local development
> Local Development will need the commands `azd auth login`, `az login` and `azd provision` run to establish services, secrets and key vaults

To run locally use `azd provision` to deploy the infrastructure and hydrate the databases. Then in the `app-ui` directory run `.\start.ps1`. 

The Application is built with a vite frontend using fluent-ui react components hosting an python API in the background. 

When coding be sure to... 
* Copy this code to a new repo
* Update the Screens to make sense
* Include all infrastructure in the bicep code
* All initialization code in the `./scripts/initialize.ps1 script` which runs post `azd provision`
* Any run requirements for local runs needs to be included in `.\app-ui\start.ps1`. 
* Do NOT include sensitive information in bicep output. This is a high level security risk. Put sensitive in Key Vault and reference appropriately with `.\app-ui\start.ps1` and the application secrets. Examples are included.
* Update the `.\data\appinfo.json` to update the about page. The version can be updated here to check for updates. 
* Do not enable App Insights locally (this is setup by default)

### When using GitHub Copilot Agent

This is a good start for a copilot Agent Prompt

``` text
The architecture of this software is as follows

* Presentation Layer /app-ui/web hosts a react vite app written in TypeScript
	* Pages are in the /app-ui/web/src/pages folder
	* Connection to the Flask Backend are in /app-ui/web/src/api
	* React Components are in /app-ui/web/src/components
* Presentation Backend /app-ui/api hosts a python 3.14 flask API
	* the App.py is located at /app-ui/api/app.py
	* generic http calls are in the /app-ui/api/approaches/httpCall.py
* Services Connection /functions/web-function hosts C# functions to interact with Azure services
	* the project is at /functions/web-functions/web-functions.csproj
* Cloud Services are always located in Microsoft Azure are built in the bicep files located at /infra/*

With few exceptions the Presentation layer calls the Presentation Backend and then calls the services functions. This is done so that the functions can serve as an entry API for other systems than they UI. 

The Presentation Layer should always talk to the flask API using the components in /app-ui/web/src/api.

For Example when uploading a file. 

The flow of operations should be: 
1. Upload the file in the /app-ui/web a react vite app page
2. Data would be passed to the /app-ui/api a python flask API uri endpoint
3. the file would be uploaded though the /functions/web-function C# function to Azure Blob Storage container

You should always 
* Minimize code by using existing functions
* Minimize code by creating reusable react components in the /app-ui/web/src/components folder 
* Minimize code by using or updating generic http calls in the /app-ui/api/approaches/httpCall.py folder 
* Any new Presentation Backend endpoints created in /app-ui/api/app.py need to be added to the vite config file (/app-ui/web/vite.config.ts)
* Any new Python requirements need to be added to the app-ui/api/requirements.txt file 
* Use python 3.14
* Avoid creating new pages, the user will do that for you. if this is not done request the user to do it.
* prevent service keys on the presentation layer
* use Managed identity to connect to Azure services
* use Fluent UI 9 for the presentation and styling where possible
* Create new services and changes to the services in the /infra in bicep
* When streaming responses are required use HTTP 
* Use environmental variables for service names and endpoints
* Make the UI visually pleasant and user friendly. 
* Create try catch and show users errors in module boxes
* Use non blocking Asynchronous calls where possible
* place any newly used C# environmental variables in the local.settings.json file
* DO NOT make changes directly to Azure Services
* ALL Keys and secrets need to be stored and pulled from key vault as environmental variables
* Use the latest libraries and packages
* Azure Role assignments should use the Azure default roles. 

The user is requesting you to complete the below:

```

## Contributing to the repo

1. Direct check-ins are not allowed. Please create a pull request from your own repo
