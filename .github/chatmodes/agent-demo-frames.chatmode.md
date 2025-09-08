---
description: 'Description of the custom chat mode.'
tools: ['extensions', 'codebase', 'usages', 'vscodeAPI', 'problems', 'changes', 'testFailure', 'terminalSelection', 'terminalLastCommand', 'openSimpleBrowser', 'fetch', 'findTestFiles', 'searchResults', 'githubRepo', 'runCommands', 'runTasks', 'editFiles', 'runNotebooks', 'search', 'new']
---
---
description: 'Description of the custom chat mode.'
tools: ['extensions', 'runTests', 'codebase', 'usages', 'vscodeAPI', 'problems', 'changes', 'testFailure', 'terminalSelection', 'terminalLastCommand', 'openSimpleBrowser', 'fetch', 'findTestFiles', 'searchResults', 'githubRepo', 'runCommands', 'runTasks', 'editFiles', 'runNotebooks', 'search', 'new']
---
This software is a demonstration of a chat app using Azure OpenAI and other LLMs to demonstrate semantic kernel with various settings using multi agent chat, mcp, prompty, and other features

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

The MongoDB has the following collections defined in an enviromental variable 

* AZURE_COSMOS_ABOUT_COLLECTION - collection for storing app information

the Azure Development CLI creates the following enviromental variables from the bicep

//AZD Required Outputs
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = rg.name

// Data outputs
output AZURE_COSMOS_DATABASE_NAME string = cosmos.outputs.databaseName
output AZURE_COSMOS_ENDPOINT string = cosmos.outputs.endpoint
output AZURE_COSMOS_ABOUT_COLLECTION string = cosmos.outputs.aboutcollection
output AZURE_COSMOS_CONNECTION_STRING_KEY string = substring(cosmos.outputs.connectionStringKey, indexOf(cosmos.outputs.connectionStringKey, 'secrets/')+8)
output AZURE_COSMOS_ACCOUNT_NAME string = cosmos.outputs.accountname
output AZURE_COSMOS_ACCOUNT_ID string = cosmos.outputs.accountid

// App outputs
output AZURE_KEY_VAULT_ENDPOINT string = keyVault.outputs.endpoint
output AZURE_KEY_VAULT_NAME string = keyVault.outputs.name
output VITE_APPLICATIONINSIGHTS_CONNECTION_STRING_KEY string = substring(kvAppIn.outputs.kvSecretId, indexOf(kvAppIn.outputs.kvSecretId, 'secrets/')+8)
output VITE_WEB_BASE_URL string = web.outputs.SERVICE_WEB_URI
output AZURE_WEB_APP_NAME string = web.outputs.SERVICE_WEB_NAME
output AZURE_WEB_APP_IDENTITY_PRINCIPAL_ID string = web.outputs.SERVICE_WEB_IDENTITY_PRINCIPAL_ID

output REACT_APP_WEB_BASE_URL string = web.outputs.SERVICE_WEB_URI
output AZURE_FUNCTION_APP_API_KEY string = function.outputs.SERVICE_FUNCT_MASTER_KEY
output AZURE_FUNCTION_APP_API_KEY_URI string = function.outputs.SERVICE_FUNCT_MASTER_KEY_URI
output AZURE_FUNCTION_APP_HOST_KEY string = function.outputs.SERVICE_FUNCT_HOST_KEY
output AZURE_FUNCTION_APP_HOST_KEY_URI string = function.outputs.SERVICE_FUNCT_HOST_KEY_URI
output AZURE_FUNCTION_APP_URI string = function.outputs.SERVICE_FUNCT_URI
output AZURE_FUNCTION_APP_NAME string = function.outputs.SERVICE_FUNCT_NAME
output AZURE_FUNCTION_APP_IDENTITY_PRINCIPAL_ID string = function.outputs.SERVICE_FUNCT_IDENTITY_PRINCIPAL_ID

output AZURE_STORAGE_ACCOUNT_NAME string = storageAccount.outputs.name


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
* The primary database is a cosmos DB with a MongoDB API The environmental variables to connect to this are AZURE_COSMOS_CONNECTION_STRING_KEY, AZURE_COSMOS_ACCOUNT_NAME, AZURE_COSMOS_DATABASE_NAME, AZURE_COSMOS_ENDPOINT
* The primary blob storage is in Azure Storage with the account name in the environmental variable AZURE_STORAGE_ACCOUNT_NAME
* You do not need to run the website to test the changes the user will do that, just build the solution is sufficient to test changes.


Complete the User Request as instructed.