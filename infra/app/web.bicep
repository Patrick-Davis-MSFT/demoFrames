param name string
param location string = resourceGroup().location
param tags object = {}
param serviceName string = 'app-ui'
param appCommandLine string = ''
param appServicePlanId string
param appSettings object = {}
param keyVaultName string = ''
param vnetName string = ''
param subnetName string = ''
param dnsResourceGroup string

module web '../core/host/appservice.bicep' = {
  name: '${name}-deployment'
  params: {
    name: name
    location: location
    tags: union(tags, { 'azd-service-name': serviceName })
    appCommandLine: appCommandLine
    appServicePlanId: appServicePlanId
    scmDoBuildDuringDeployment: true
    managedIdentity: true
    runtimeName: 'python'
    runtimeVersion: '3.13'
    appSettings: appSettings
    keyVaultName: keyVaultName
    vnetName: vnetName
    subnetName: subnetName
    dnsResourceGroup: dnsResourceGroup
  }
}

output SERVICE_WEB_IDENTITY_PRINCIPAL_ID string = web.outputs.identityPrincipalId
output SERVICE_WEB_NAME string = web.outputs.name
output SERVICE_WEB_URI string = web.outputs.uri
