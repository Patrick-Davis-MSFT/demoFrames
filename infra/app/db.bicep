param accountName string
param location string = resourceGroup().location
param tags object = {}

param collections array = [
  {
    name: 'About'
    id: 'About'
    shardKey: 'Hash'
    indexes: [ { key: { keys: [ '_id' ] } }, { key: { keys: [ 'deploy_datetime' ] } } ]
  }
  {
    name: 'Alerts'
    id: 'Alerts'
    shardKey: 'Hash'
    indexes:  [ { key: { keys: [ '_id' ] } } ]
  }
]


param databaseName string = ''
param keyVaultName string

// Because databaseName is optional in main.bicep, we make sure the database name is set here.
var defaultDatabaseName = 'CISAAlerts'
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
  }
}

output connectionStringKey string = cosmos.outputs.connectionStringKey
output databaseName string = cosmos.outputs.databaseName
output endpoint string = cosmos.outputs.endpoint
output alertcollection string = collections[1].name
output aboutcollection string = collections[0].name
