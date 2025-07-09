metadata description = 'Creates an Azure Cosmos DB for MongoDB account with a database.'
param accountName string
param databaseName string
param location string = resourceGroup().location
param tags object = {}

param collections array = []
param connectionStringKey string = 'AZURE-COSMOS-CONNECTION-STRING'
param keyVaultName string
param vnetName string = ''
param subnetName string = ''
param dnsResourceGroup string
param azurePrivateDnsName string = 'privatelink.mongo.cosmos.azure.com'

module cosmos 'cosmos-mongo-account.bicep' = {
  name: 'cosmos-mongo-account'
  params: {
    name: accountName
    location: location
    keyVaultName: keyVaultName
    tags: tags
    connectionStringKey: connectionStringKey
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/mongodbDatabases@2022-08-15' = {
  name: '${accountName}/${databaseName}'
  tags: tags
  properties: {
    resource: { id: databaseName }
  }

  resource list 'collections' = [for collection in collections: {
    name: collection.name
    properties: {
      resource: {
        id: collection.id
        shardKey: { _id: collection.shardKey }
        indexes: collection.indexes 
        
      }
    }
  }]

  dependsOn: [
    cosmos
  ]
}

/*// Private DNS Zone for Cosmos DB MongoDB API
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (!empty(vnetName) && !empty(subnetName)) {
  name: 'privatelink.mongo.cosmos.azure.com'
  location: 'global'
  tags: tags
}

// Link the Private DNS Zone to the VNet
resource privateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (!empty(vnetName) && !empty(subnetName)) {
  parent: privateDnsZone
  name: '${vnetName}-link'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', vnetName)
    }
  }
}
*/
// Create Private Endpoint for Cosmos DB Account
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = if (!empty(vnetName) && !empty(subnetName)) {
  name: '${accountName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: '${resourceId(dnsResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)}/subnets/${subnetName}'
    }
    privateLinkServiceConnections: [
      {
        name: '${accountName}-plsc'
        properties: {
          privateLinkServiceId: cosmos.outputs.id
          groupIds: [
            'MongoDB'
          ]
        }
      }
    ]
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  scope: resourceGroup(dnsResourceGroup)
  name: azurePrivateDnsName
}

// Create DNS Zone Group for the private endpoint
resource privateEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = if (!empty(vnetName) && !empty(subnetName)) {
  parent: privateEndpoint
  name: 'dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}


output connectionStringKey string = cosmos.outputs.connectionStringKey
output databaseName string = databaseName
output endpoint string = cosmos.outputs.endpoint
