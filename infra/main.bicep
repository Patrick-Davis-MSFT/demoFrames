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
param applicationInsightsDashboardName string = ''
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

@description ('The name of the resource group for the private DNS zone - It is easier to manage the private DNS zones in a separate resource group')
param dnsResourceGroup string
@description('The name of the DNS zone for the private endpoint of the storage account')
param appServicePrivateEndPointDNSZoneName_Storage string = 'privatelink.blob.core.windows.net'
@description('The name of the DNS zone for the private endpoint of the storage account')
param appServicePrivateEndPointDNSZoneName_Key_Vault string = 'privatelink.vaultcore.azure.net'
@description('The name of the DNS zone for the private endpoint of the storage account')
param appServicePrivateEndPointDNSZoneName_Cosmos string = 'privatelink.mongo.cosmos.azure.com'


@description('Id of the user or app to assign application roles')
param principalId string = ''

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// The application frontend
module web './app/web.bicep' = {
  name: 'web'
  scope: rg
  params: {
    name: !empty(webServiceName) ? webServiceName : '${abbrs.webSitesAppService}web-${resourceToken}'
    location: location
    tags: tags
    appServicePlanId: appServicePlan.outputs.id
    keyVaultName: keyVault.outputs.name
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    vnetName: appDemoVnetName
    subnetName: appDemoAppServiceDeligatedSubnetName
    dnsResourceGroup: dnsResourceGroup
    appSettings: {
      AZURE_COSMOS_CONNECTION_STRING: '@Microsoft.KeyVault(SecretUri=${cosmos.outputs.connectionStringKey})'
      AZURE_COSMOS_DATABASE_NAME: cosmos.outputs.databaseName
      AZURE_COSMOS_ENDPOINT: cosmos.outputs.endpoint
      AZURE_COSMOS_ABOUT_COLLECTION: cosmos.outputs.aboutcollection
      VITE_APPLICATIONINSIGHTS_CONNECTION_STRING: '@Microsoft.KeyVault(SecretUri=${kvAppIn.outputs.kvSecretId})'
      AZURE_FUNCTION_APP_NAME: function.outputs.SERVICE_FUNCT_NAME
      AZURE_FUNCTION_APP_API_KEY: '@Microsoft.KeyVault(SecretUri=${kvFunctKey.outputs.kvSecretId})'
     }
  }
}

module storageAccount './core/storage/storage-account.bicep' = {
  name: 'storageaccount'
  scope: rg
  params: {
    name: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageStorageAccounts}${resourceToken}'
    location: location
    vnetName: appDemoVnetName
    subnetName: appDemoPrivateEndpointSubnetName
    dnsResourceGroup: dnsResourceGroup
    azurePrivateDnsName: appServicePrivateEndPointDNSZoneName_Storage
    tags: tags
  }
}

// The application frontend
module function './app/function.bicep' = {
  name: 'function'
  scope: rg
  params: {
    name: !empty(functionServiceName) ? functionServiceName : '${abbrs.webSitesFunctions}${resourceToken}'
    location: location
    tags: tags
    appServicePlanId: appServicePlan.outputs.id
    keyVaultName: keyVault.outputs.name
    storageAccountName: storageAccount.outputs.name
    applicationInsightsName: monitoring.outputs.applicationInsightsName
    vnetName: appDemoVnetName
    subnetName: appDemoAppServiceDeligatedSubnetName
    dnsResourceGroup: dnsResourceGroup
    appSettings: {
      AZURE_COSMOS_CONNECTION_STRING: '@Microsoft.KeyVault(SecretUri=${cosmos.outputs.connectionStringKey})'
      AZURE_COSMOS_DATABASE_NAME: cosmos.outputs.databaseName
      AZURE_COSMOS_ENDPOINT: cosmos.outputs.endpoint
      AZURE_COSMOS_ABOUT_COLLECTION: cosmos.outputs.aboutcollection
      VITE_APPLICATIONINSIGHTS_CONNECTION_STRING: '@Microsoft.KeyVault(SecretUri=${kvAppIn.outputs.kvSecretId})'
    }
  }
}

module kvFunctKey './core/security/keyvault-secret.bicep' = { 
  name: 'funct-key'
  scope: rg
  params: {
    name: 'funct-key'
    keyVaultName: keyVault.outputs.name
    secretValue: 'Init-kv-reference'
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
    accountName: !empty(cosmosAccountName) ? cosmosAccountName : '${abbrs.documentDBDatabaseAccounts}${resourceToken}'
    databaseName: cosmosDatabaseName
    location: location
    tags: tags
    keyVaultName: keyVault.outputs.name
    dnsResourceGroup: dnsResourceGroup
    vnetName: appDemoVnetName
    subnetName: appDemoPrivateEndpointSubnetName
    azurePrivateDnsName: appServicePrivateEndPointDNSZoneName_Cosmos
  }
}

// Create an App Service Plan to group applications under the same payment plan and SKU
module appServicePlan './core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: rg
  params: {
    name: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.webServerFarms}${resourceToken}'
    location: location
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
    name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${resourceToken}'
    location: location
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


// Monitor application with Azure Monitor
module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    logAnalyticsName: !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
    applicationInsightsDashboardName: !empty(applicationInsightsDashboardName) ? applicationInsightsDashboardName : '${abbrs.portalDashboards}${resourceToken}'
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

// App outputs
output AZURE_KEY_VAULT_ENDPOINT string = keyVault.outputs.endpoint
output AZURE_KEY_VAULT_NAME string = keyVault.outputs.name
output VITE_APPLICATIONINSIGHTS_CONNECTION_STRING_KEY string = substring(kvAppIn.outputs.kvSecretId, indexOf(kvAppIn.outputs.kvSecretId, 'secrets/')+8)
output VITE_WEB_BASE_URL string = web.outputs.SERVICE_WEB_URI
output REACT_APP_WEB_BASE_URL string = web.outputs.SERVICE_WEB_URI
output AZURE_FUNCTION_APP_API_KEY string = kvFunctKey.name
output AZURE_FUNCTION_APP_API_KEY_URI string = kvFunctKey.outputs.kvSecretId
output AZURE_FUNCTION_APP_NAME string = function.outputs.SERVICE_FUNCT_NAME
