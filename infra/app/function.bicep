param name string
param location string = resourceGroup().location
param tags object = {}
param serviceName string = 'app-funct'
param appCommandLine string = ''
param appServicePlanId string
param appSettings object = {}
param keyVaultName string = ''
param storageAccountName string
param applicationInsightsName string = ''
param vnetName string = ''
param subnetName string = ''
param dnsResourceGroup string


module function '../core/host/functions.bicep' = {
  name: '${name}'
  params: {
    name: name
    location: location
    tags: union(tags, { 'azd-service-name': serviceName })
    appCommandLine: appCommandLine
    appServicePlanId: appServicePlanId
    scmDoBuildDuringDeployment: false
    managedIdentity: true
    runtimeName: 'dotnet-isolated'
    runtimeVersion: '8.0'
    runtimeNameAndVersion: 'DOTNET-ISOLATED|8.0'
    appSettings: appSettings
    keyVaultName: keyVaultName
    storageAccountName: storageAccountName
    applicationInsightsName: applicationInsightsName
    vnetName: vnetName
    subnetName: subnetName
    dnsResourceGroup: dnsResourceGroup
  }
}



output SERVICE_FUNCT_IDENTITY_PRINCIPAL_ID string = function.outputs.identityPrincipalId
output SERVICE_FUNCT_NAME string = function.outputs.name
output SERVICE_FUNCT_URI string = function.outputs.uri
output SERVICE_FUNCT_KV_KEY string = 'funct-key-${serviceName}'
output SERVICE_FUNCT_MASTER_KEY string = function.outputs.masterKeySecretName
output SERVICE_FUNCT_MASTER_KEY_URI string = function.outputs.masterKeySecretUri
output SERVICE_FUNCT_HOST_KEY string = function.outputs.defaultHostKeySecretName
output SERVICE_FUNCT_HOST_KEY_URI string = function.outputs.defaultHostKeySecretUri
