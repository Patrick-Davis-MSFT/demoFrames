metadata description = 'Creates a simplified Azure Cosmos DB NoSQL account with optimal cost and security settings.'

param name string
param location string = resourceGroup().location
param tags object = {}
param keyVaultName string
param databaseName string
param containers array = []
param vnetName string = ''
param subnetName string = ''
param vnetlocation string = location
param dnsResourceGroup string = ''
param azurePrivateDnsName string = 'privatelink.documents.azure.com'

// Cosmos DB Account with optimal settings
resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: name
  kind: 'GlobalDocumentDB'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    consistencyPolicy: { defaultConsistencyLevel: 'Session' }
    locations: [{ locationName: location, failoverPriority: 0, isZoneRedundant: false }]
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
    capabilities: [{ name: 'EnableServerless' }] // Serverless is the cheapest paid option
    publicNetworkAccess: 'Disabled' // Security
    enableFreeTier: false // Use cheapest paid tier instead of free tier
    minimalTlsVersion: 'Tls12'
  }
}

// Database and containers in one place
resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-05-15' = {
  parent: cosmos
  name: databaseName
  properties: {
    resource: { id: databaseName }
  }

  resource containerResources 'containers' = [for container in containers: {
    name: container.name
    properties: {
      resource: {
        id: container.id
        partitionKey: { paths: [container.partitionKey] }
      }
    }
  }]
}

// Private endpoint (conditional)
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = if (!empty(vnetName) && !empty(subnetName)) {
  name: '${name}-pe'
  location: vnetlocation
  tags: tags
  properties: {
    subnet: {
      id: resourceId(dnsResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
    }
    privateLinkServiceConnections: [{
      name: '${name}-plsc'
      properties: {
        privateLinkServiceId: cosmos.id
        groupIds: ['Sql']
      }
    }]
  }
}

// DNS zone group (conditional)
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (!empty(vnetName) && !empty(subnetName)) {
  scope: resourceGroup(dnsResourceGroup)
  name: azurePrivateDnsName
}

resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = if (!empty(vnetName) && !empty(subnetName)) {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [{
      name: 'cosmos-config'
      properties: { privateDnsZoneId: privateDnsZone.id }
    }]
  }
}

// Role definition for Entra ID access
resource roleDefinition 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2024-05-15' = {
  parent: cosmos
  name: guid(cosmos.id, name, 'reader-writer')
  properties: {
    assignableScopes: [cosmos.id]
    permissions: [{
      dataActions: [
        'Microsoft.DocumentDB/databaseAccounts/readMetadata'
        'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*'
        'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*'
      ]
    }]
    roleName: 'Cosmos DB Reader Writer'
    type: 'CustomRole'
  }
}

// Connection string in Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource connectionString 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'AZURE-COSMOS-CONNECTION-STRING'
  properties: {
    value: cosmos.listConnectionStrings().connectionStrings[0].connectionString
  }
}

// Outputs
output connectionStringKey string = connectionString.properties.secretUri
output endpoint string = cosmos.properties.documentEndpoint
output id string = cosmos.id
output name string = cosmos.name
output databaseName string = databaseName
output roleDefinitionId string = roleDefinition.id
