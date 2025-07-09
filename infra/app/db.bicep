param accountName string
param location string = resourceGroup().location
param tags object = {}
param vnetName string = ''
param subnetName string = ''
param dnsResourceGroup string
param azurePrivateDnsName string

param collections array = [
  {
    name: 'About'
    id: 'About'
    shardKey: 'Hash'
    indexes: [ { key: { keys: [ '_id' ] } }, { key: { keys: [ 'deploy_datetime' ] } } ]
  }
]


param databaseName string = ''
param keyVaultName string

// Because databaseName is optional in main.bicep, we make sure the database name is set here.
var defaultDatabaseName = 'DEMOFramesDB'
var actualDatabaseName = !empty(databaseName) ? databaseName : defaultDatabaseName

module cosmos '../core/database/cosmos/mongo/cosmos-mongo-db.bicep' = {
  name: 'cosmos-mongo'
  params: {
    accountName: accountName
    databaseName: actualDatabaseName
    location: location
    collections: collections
    keyVaultName: keyVaultName
    tags: tags
    dnsResourceGroup: dnsResourceGroup
    vnetName: vnetName
    subnetName: subnetName
    azurePrivateDnsName: azurePrivateDnsName
  }
}

output connectionStringKey string = cosmos.outputs.connectionStringKey
output databaseName string = cosmos.outputs.databaseName
output endpoint string = cosmos.outputs.endpoint
output aboutcollection string = collections[0].name
