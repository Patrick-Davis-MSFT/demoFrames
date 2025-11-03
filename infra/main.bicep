targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Optional parameters to override the default azd resource naming conventions. Update the main.parameters.json file to provide values. e.g.,:
// "resourceGroupName": {
//      "value": "myGroupName"
// }
param applicationInsightsName string = ''
param appServicePlanName string = ''
param cosmosAccountName string = ''
param cosmosDatabaseName string = ''
param keyVaultName string = ''
param logAnalyticsName string = ''
param resourceGroupName string = ''
param webServiceName string = ''
param functionServiceName string = ''
param storageAccountName string = ''

@description('the name of the application vnet for this demo')
param appDemoVnetName string

@description('The name of deligated subnet for the app demo application for web and function apps')
param appDemoAppServiceDeligatedSubnetName string

@description('The name of the subnet for the private endpoints')
param appDemoPrivateEndpointSubnetName string

@description('The location of the subnet for the private endpoints')
param appDemoPrivateEndpointlocation string = location

@description ('The name of the resource group for the private DNS zone - It is easier to manage the private DNS zones in a separate resource group')
param dnsResourceGroup string
@description('The private DNS zone name for Key Vault private endpoints')
param appServicePrivateEndPointDNSZoneName_Key_Vault string = 'privatelink.vaultcore.azure.net'
@description('The private DNS zone name for Azure Cosmos DB (NoSQL) private endpoints')
param appServicePrivateEndPointDNSZoneName_Cosmos string = 'privatelink.documents.azure.com'


@description('Id of the user or app to assign application roles')
param principalId string = ''

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// Resolved names to simplify repeated conditional expressions
var resolved = {
  rgName: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  appServicePlanName: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.webServerFarms}${resourceToken}'
  webServiceName: !empty(webServiceName) ? webServiceName : '${abbrs.webSitesAppService}web-${resourceToken}'
  functionServiceName: !empty(functionServiceName) ? functionServiceName : '${abbrs.webSitesFunctions}${resourceToken}'
  storageAccountName: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageStorageAccounts}${resourceToken}'
  cosmosAccountName: !empty(cosmosAccountName) ? cosmosAccountName : '${abbrs.documentDBDatabaseAccounts}${resourceToken}'
  keyVaultName: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${resourceToken}'
  logAnalyticsName: !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
  applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
}

// Common app settings shared by web and function apps
var commonCosmosAppSettings = {
  AZURE_COSMOS_ACCOUNT_NAME: cosmos.outputs.accountname
  AZURE_COSMOS_CONNECTION_STRING: '@Microsoft.KeyVault(SecretUri=${cosmos.outputs.connectionStringKey})'
  AZURE_COSMOS_DATABASE_NAME: cosmos.outputs.databaseName
  AZURE_COSMOS_ENDPOINT: cosmos.outputs.endpoint
  AZURE_COSMOS_ABOUT_COLLECTION: cosmos.outputs.aboutcollection
  VITE_APPLICATIONINSIGHTS_CONNECTION_STRING: '@Microsoft.KeyVault(SecretUri=${kvAppIn.outputs.kvSecretId})'
}

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resolved.rgName
  location: location
  tags: tags
}

// The application frontend
module web './app/web.bicep' = {
  name: 'web'
  scope: rg
  params: {
    name: resolved.webServiceName
    location: appDemoPrivateEndpointlocation
    tags: tags
    appServicePlanId: appServicePlan.outputs.id
    keyVaultName: keyVault.outputs.name
    vnetName: appDemoVnetName
    subnetName: appDemoAppServiceDeligatedSubnetName
    dnsResourceGroup: dnsResourceGroup
    appSettings: union(commonCosmosAppSettings, {
      AZURE_FUNCTION_APP_NAME: function.outputs.SERVICE_FUNCT_NAME
      AZURE_FUNCTION_APP_API_KEY: '@Microsoft.KeyVault(SecretUri=${function.outputs.SERVICE_FUNCT_MASTER_KEY_URI})'
      SCM_DO_BUILD_DURING_DEPLOYMENT: '1'
      ENABLE_ORYX_BUILD: 'true'
      APPLICATIONINSIGHTS_CONNECTION_STRING: monitoring.outputs.applicationInsightsConnectionString
      APPINSIGHTS_INSTRUMENTATIONKEY: monitoring.outputs.applicationInsightsInstrumentationKey
      AZURE_KEY_VAULT_ENDPOINT: keyVault.outputs.endpoint
    })
  }
}

module storageAccount './core/storage/storage-account.bicep' = {
  name: 'storageaccount'
  scope: rg
  params: {
  name: resolved.storageAccountName
    location: location
    vnetName: appDemoVnetName
    subnetName: appDemoPrivateEndpointSubnetName
    vnetlocation: appDemoPrivateEndpointlocation
    dnsResourceGroup: dnsResourceGroup
    tags: tags
  }
}

// The services layer
module function './app/function.bicep' = {
  name: 'function'
  scope: rg
  params: {
    name: resolved.functionServiceName
    location: appDemoPrivateEndpointlocation
    tags: tags
    appServicePlanId: appServicePlan.outputs.id
    keyVaultName: keyVault.outputs.name
    storageAccountName: storageAccount.outputs.name
    vnetName: appDemoVnetName
    subnetName: appDemoAppServiceDeligatedSubnetName
    dnsResourceGroup: dnsResourceGroup
    appSettings: union(commonCosmosAppSettings, {
      WEBSITE_RUN_FROM_PACKAGE: '1'
      ENABLE_ORYX_BUILD: 'true'
      AzureWebJobsStorage__accountname: storageAccount.outputs.name
      SCM_DO_BUILD_DURING_DEPLOYMENT: '0'
      APPLICATIONINSIGHTS_CONNECTION_STRING: monitoring.outputs.applicationInsightsConnectionString
      APPINSIGHTS_INSTRUMENTATIONKEY: monitoring.outputs.applicationInsightsInstrumentationKey
      AZURE_KEY_VAULT_ENDPOINT: keyVault.outputs.endpoint
    })
  }
}

// Give the API access to KeyVault
module apiKeyVaultAccess './core/security/keyvault-access.bicep' = {
  name: 'api-keyvault-access'
  scope: rg
  params: {
    keyVaultName: keyVault.outputs.name
    principalId: web.outputs.SERVICE_WEB_IDENTITY_PRINCIPAL_ID
  }
}

module apiKeyVaultAccessFunc './core/security/keyvault-access.bicep' = {
  name: 'api-keyvault-access-func'
  scope: rg
  params: {
    keyVaultName: keyVault.outputs.name
    principalId: function.outputs.SERVICE_FUNCT_IDENTITY_PRINCIPAL_ID
  }
}

// The application database
module cosmos './app/db.bicep' = {
  name: 'cosmos'
  scope: rg
  params: {
    accountName: resolved.cosmosAccountName
    databaseName: cosmosDatabaseName
    vnetlocation: appDemoPrivateEndpointlocation
    location: location
    tags: tags
    keyVaultName: keyVault.outputs.name
    dnsResourceGroup: dnsResourceGroup
    vnetName: appDemoVnetName
    subnetName: appDemoPrivateEndpointSubnetName
    azurePrivateDnsName: appServicePrivateEndPointDNSZoneName_Cosmos
    principalIds: [] // Will be set up separately to avoid circular dependency
  }
}

// Create an App Service Plan to group applications under the same payment plan and SKU
module appServicePlan './core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: rg
  params: {
  name: resolved.appServicePlanName
    location: appDemoPrivateEndpointlocation
    tags: tags
    sku: {
      name: 'B3'
    }
  }
}

// Store secrets in a keyvault
module keyVault './core/security/keyvault.bicep' = {
  name: 'keyvault'
  scope: rg
  params: {
  name: resolved.keyVaultName
    location: location
    vnetlocation: appDemoPrivateEndpointlocation
    tags: tags
    principalId: principalId
    vnetName: appDemoVnetName
    subnetName: appDemoPrivateEndpointSubnetName
    dnsResourceGroup: dnsResourceGroup
    azurePrivateDnsName: appServicePrivateEndPointDNSZoneName_Key_Vault
    privateAccess: false
  }
}

module kvAppIn 'core/security/keyvault-secret.bicep' ={ 
  name: 'appinsights-key'
  scope: rg
  params: {
    name: 'app-insights-key'
    keyVaultName: keyVault.outputs.name
    secretValue: monitoring.outputs.applicationInsightsConnectionString
  }
}

// Cosmos DB Role Assignments for Entra ID authentication (added after apps are created)
module cosmosWebRoleAssignment 'core/database/cosmos/sql/cosmos-sql-role-assign.bicep' = {
  name: 'cosmos-web-role-assignment'
  scope: rg
  params: {
    accountName: resolved.cosmosAccountName
    roleDefinitionId: cosmos.outputs.roleDefinitionId
    principalId: web.outputs.SERVICE_WEB_IDENTITY_PRINCIPAL_ID
  }
}

module cosmosFunctionRoleAssignment 'core/database/cosmos/sql/cosmos-sql-role-assign.bicep' = {
  name: 'cosmos-function-role-assignment'
  scope: rg
  params: {
    accountName: resolved.cosmosAccountName
    roleDefinitionId: cosmos.outputs.roleDefinitionId
    principalId: function.outputs.SERVICE_FUNCT_IDENTITY_PRINCIPAL_ID
  }
}


// Monitor application with Azure Monitor
module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
  logAnalyticsName: resolved.logAnalyticsName
  applicationInsightsName: resolved.applicationInsightsName
  }
}

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
