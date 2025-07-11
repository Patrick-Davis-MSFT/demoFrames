metadata description = 'Creates an Azure Cosmos DB account.'
param name string
param location string = resourceGroup().location
param tags object = {}

param connectionStringKey string = 'AZURE_COSMOS_CONNECTION_STRING'
param keyVaultName string

@allowed([ 'GlobalDocumentDB', 'MongoDB', 'Parse' ])
param kind string

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' = {
  name: name
  kind: kind
  location: location
  tags: tags
  properties: {
    consistencyPolicy: { defaultConsistencyLevel: 'Session' }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
    apiProperties: (kind == 'MongoDB') ? { serverVersion: '4.2' } : {}
    capabilities: [ { name: 'EnableServerless' } ]
    // Configure network access to "Selected Networks" without specifying any VNets
    publicNetworkAccess: 'Enabled'
    isVirtualNetworkFilterEnabled: true
    virtualNetworkRules: []
    ipRules: [
      {
        ipAddressOrRange: '0.0.0.0'
      }
      {
        ipAddressOrRange: '4.210.172.107'
      }
      {
        ipAddressOrRange: '13.88.56.148'
      }
      {
        ipAddressOrRange: '13.91.105.215'
      }
      {
        ipAddressOrRange: '13.95.130.121'
      }
      {
        ipAddressOrRange: '20.245.81.54'
      }
      {
        ipAddressOrRange: '40.80.152.199'
      }
      {
        ipAddressOrRange: '40.91.218.243'
      }
      {
        ipAddressOrRange: '40.118.23.126'
      }
    ]
  }
}

resource cosmosConnectionString 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: connectionStringKey
  properties: {
    value: cosmos.listConnectionStrings().connectionStrings[0].connectionString
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

output connectionStringKey string = cosmosConnectionString.properties.secretUri
output endpoint string = cosmos.properties.documentEndpoint
output id string = cosmos.id
output name string = cosmos.name
