param accountName string
param location string = resourceGroup().location
param tags object = {}
param vnetName string = ''
param subnetName string = ''
param vnetlocation string
param dnsResourceGroup string
param azurePrivateDnsName string
param databaseName string = ''
param keyVaultName string
param principalIds array = []

// Define containers (simplified from MongoDB collections)
var containers = [
  {
    name: 'About'
    id: 'About'
    partitionKey: '/id'
  }
]

// Set default database name if not provided
var actualDatabaseName = !empty(databaseName) ? databaseName : 'DEMOFramesDB'

// Use simplified Cosmos DB module
module cosmos '../core/database/cosmos/sql/cosmos-nosql-account.bicep' = {
  name: 'cosmos-nosql'
  params: {
    name: accountName
    location: location
    tags: tags
    keyVaultName: keyVaultName
    databaseName: actualDatabaseName
    containers: containers
    vnetName: vnetName
    subnetName: subnetName
    vnetlocation: vnetlocation
    dnsResourceGroup: dnsResourceGroup
    azurePrivateDnsName: azurePrivateDnsName
  }
}

// Role assignments for application identities (done separately to avoid cycles)
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' existing = {
  name: accountName
}

@batchSize(1)
resource roleAssignments 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-05-15' = [for (principalId, i) in principalIds: if (!empty(principalId)) {
  parent: cosmosAccount
  name: guid(accountName, principalId, string(i))
  properties: {
    principalId: principalId
    roleDefinitionId: cosmos.outputs.roleDefinitionId
    scope: cosmosAccount.id
  }
}]

// Outputs (maintain compatibility)
output connectionStringKey string = cosmos.outputs.connectionStringKey
output databaseName string = cosmos.outputs.databaseName
output endpoint string = cosmos.outputs.endpoint
output aboutcollection string = containers[0].name
output accountname string = cosmos.outputs.name
output accountid string = cosmos.outputs.id
output roleDefinitionId string = cosmos.outputs.roleDefinitionId
